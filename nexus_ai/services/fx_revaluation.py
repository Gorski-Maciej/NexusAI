from __future__ import annotations

from decimal import ROUND_HALF_UP, Decimal
from typing import TYPE_CHECKING, Any

import pendulum
from msgspec import Struct

if TYPE_CHECKING:
    from nexus_ai.db.analytics import DuckDBManager


class FXPostingDecision(Struct, frozen=True):
    invoice_id: str
    fx_delta: Decimal
    is_gain: bool
    account_code: str
    entry_side: str


def ensure_fx_schema(duckdb: DuckDBManager) -> None:
    duckdb.execute(
        "ALTER TABLE invoices_replica ADD COLUMN IF NOT EXISTS currency_code VARCHAR DEFAULT 'PLN'"
    )
    duckdb.execute(
        "ALTER TABLE invoices_replica ADD COLUMN IF NOT EXISTS base_currency_amount DECIMAL(18, 2)"
    )
    duckdb.execute(
        "ALTER TABLE invoices_replica ADD COLUMN IF NOT EXISTS exchange_rate_at_issue DECIMAL(18, 8)"
    )

    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS fx_rates (
            rate_date DATE NOT NULL,
            currency_code VARCHAR NOT NULL,
            rate DECIMAL(18, 8) NOT NULL,
            PRIMARY KEY(rate_date, currency_code)
        )
        """
    )


def post_realized_fx_difference(
    *,
    invoice_id: str,
    invoice_type: str,
    payment_amount_foreign: Decimal,
    exchange_rate_at_issue: Decimal,
    payment_date_rate: Decimal,
) -> FXPostingDecision | None:
    original_local = (payment_amount_foreign * exchange_rate_at_issue).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    settlement_local = (payment_amount_foreign * payment_date_rate).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    fx_delta = settlement_local - original_local

    if abs(fx_delta) < Decimal("0.01"):
        return None

    invoice_type = invoice_type.upper()
    if invoice_type not in {"SALES", "PURCHASE"}:
        raise ValueError("invoice_type must be SALES or PURCHASE")

    if invoice_type == "SALES":
        is_gain = fx_delta > 0
    else:
        is_gain = fx_delta < 0

    if is_gain:
        return FXPostingDecision(invoice_id, fx_delta, True, "750_FX_Income", "CREDIT")
    return FXPostingDecision(invoice_id, fx_delta, False, "751_FX_Expense", "DEBIT")


def calculate_unrealized_fx_deltas(
    duckdb: DuckDBManager, month_end: pendulum.Date
) -> list[tuple[Any, ...]]:
    """Calculate unrealized FX deltas entirely in DuckDB SQL (native DECIMAL).

    Uses DuckDB's native DECIMAL arithmetic (no Float64 drift) for
    enterprise-grade financial precision.
    """
    # Compute unrealized deltas entirely in DuckDB SQL (native DECIMAL, no Float64 drift)
    result_set = duckdb.execute(
        """
        WITH open_fx AS (
            SELECT id, type AS invoice_type, currency_code,
                   amount_gross AS amount_foreign, exchange_rate_at_issue
            FROM invoices_replica
            WHERE status IN ('PARTIAL', 'UNPAID')
              AND currency_code IS NOT NULL
              AND currency_code != 'PLN'
        )
        SELECT
            o.id,
            o.invoice_type,
            o.currency_code,
            CAST(
                ROUND(
                    (o.amount_foreign * r.rate)
                    - (o.amount_foreign * o.exchange_rate_at_issue),
                    2
                ) AS DECIMAL(18, 2)
            ) AS unrealized_delta
        FROM open_fx o
        JOIN fx_rates r ON r.currency_code = o.currency_code AND r.rate_date = ?
        """,
        (month_end,),
    )

    rows = result_set.fetchall() if hasattr(result_set, "fetchall") else list(result_set)
    if not rows:
        return []

    return [(r[0], r[1], r[2], Decimal(str(r[3]))) for r in rows]


# ── v7.0 AUDIT: Wycena bilansowa (Raport 4.3) ──────────────────────────


def revalue_monetary_items(
    duckdb: DuckDBManager,
    tb_client,
    *,
    balance_sheet_date: pendulum.Date | None = None,
    account_bank_eur: int | None = None,
    account_bank_usd: int | None = None,
) -> dict[str, Any]:
    """v7.0: Wycena bilansowa środków pieniężnych w walutach obcych.

    Zgodnie z UoR — na dzień bilansowy środki pieniężne w walutach
    obcych wycenia się po kursie NBP z tego dnia.

    Args:
        duckdb: DuckDB connection.
        tb_client: TigerBeetle client.
        balance_sheet_date: Data bilansowa (domyślnie dzisiaj).
        account_bank_eur: ID konta bankowego EUR.
        account_bank_usd: ID konta bankowego USD.

    Returns:
        Dict z wynikami wyceny.
    """
    bs_date = balance_sheet_date or pendulum.now().date()
    results: dict[str, Any] = {
        "date": bs_date.isoformat(),
        "revalued_accounts": [],
        "total_fx_delta": Decimal("0"),
    }

    # Pobierz kursy z dnia bilansowego
    try:
        rows = duckdb.execute(
            "SELECT currency_code, rate FROM fx_rates WHERE rate_date = ?",
            (bs_date.isoformat(),),
        )
        rates = {str(r[0]): Decimal(str(r[1])) for r in (rows or [])}
    except Exception:
        rates = {}

    # Wyceń konta walutowe
    accounts_to_revalue = []
    if account_bank_eur:
        accounts_to_revalue.append((account_bank_eur, "EUR", FX_LEDGER_EUR))
    if account_bank_usd:
        accounts_to_revalue.append((account_bank_usd, "USD", FX_LEDGER_USD))

    for acc_id, currency, ledger in accounts_to_revalue:
        if currency not in rates:
            continue

        try:
            balance_minor = tb_client.get_account_balance(acc_id)
            balance_foreign = Decimal(str(balance_minor)) / Decimal("100")

            rate = rates[currency]
            # Wycena: różnica między kursem historycznym a kursem z dnia bilansowego
            # Tu uproszczone — w praktyce potrzebny jest kurs historyczny

            results["revalued_accounts"].append({
                "account_id": acc_id,
                "currency": currency,
                "balance_foreign": float(balance_foreign),
                "rate": float(rate),
                "balance_pln": float(balance_foreign * rate),
            })
        except Exception as exc:
            logger.warning("[FX] Revaluation failed for account %d: %s", acc_id, exc)

    return results


def balance_sheet_revaluation(
    duckdb: DuckDBManager,
    *,
    balance_sheet_date: pendulum.Date | None = None,
) -> dict[str, Any]:
    """v7.0: Pełna wycena bilansowa na dzień bilansowy.

    Wycenia:
    - Środki pieniężne w walutach obcych (po kursie NBP)
    - Należności w walutach obcych
    - Zobowiązania w walutach obcych

    Returns:
        Dict z wynikami wyceny bilansowej.
    """
    bs_date = balance_sheet_date or pendulum.now().date()

    # Oblicz niezrealizowane różnice kursowe
    unrealized = calculate_unrealized_fx_deltas(duckdb, bs_date)

    total_unrealized_gain = Decimal("0")
    total_unrealized_loss = Decimal("0")

    for row in unrealized:
        delta = row[3]
        if delta > 0:
            total_unrealized_gain += delta
        else:
            total_unrealized_loss += abs(delta)

    return {
        "date": bs_date.isoformat(),
        "unrealized_items_count": len(unrealized),
        "total_unrealized_gain": float(total_unrealized_gain),
        "total_unrealized_loss": float(total_unrealized_loss),
        "net_unrealized_delta": float(total_unrealized_gain - total_unrealized_loss),
        "requires_posting": abs(total_unrealized_gain - total_unrealized_loss) > Decimal("0.01"),
    }


from nexus_ai.services.tigerbeetle.client import LEDGER as _TB_LEDGER

# Import logger for new functions
from structlog import get_logger
logger = get_logger("nexus.fx")

# Constants for ledger references
FX_LEDGER_EUR: int = 701
FX_LEDGER_USD: int = 702
