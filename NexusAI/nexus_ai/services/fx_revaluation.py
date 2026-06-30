from __future__ import annotations

from msgspec import Struct

import pendulum
from decimal import ROUND_HALF_UP, Decimal
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from db.analytics import DuckDBManager


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
    else:  # PURCHASE
        is_gain = fx_delta < 0

    if is_gain:
        return FXPostingDecision(invoice_id, fx_delta, True, "750_FX_Income", "CREDIT")
    return FXPostingDecision(invoice_id, fx_delta, False, "751_FX_Expense", "DEBIT")


def calculate_unrealized_fx_deltas(
    duckdb: DuckDBManager, month_end: pendulum.Date
) -> list[tuple[Any, ...]]:
    ``execute_arrow()`` + ``pl.from_arrow()`` + ``pl.DataFrame.with_columns()``
    zamiast czystego DuckDB SQL.

    Polars pozwala na:
    - Łatwiejsze rozszerzanie o dodatkowe obliczenia (np. weighted deltas)
    - ``shrink_dtype()`` dla redukcji RAM
    - ``filter()`` z wyrażeniami dla dalszego przetwarzania
    - ``sink_parquet()" jeśli wynik ma być zapisany
    """
    import polars as pl

    # DuckDB produkuje Arrow Table, Polars konsumuje bez kopiowania.
    arrow_table = duckdb.execute_arrow(
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
            o.amount_foreign,
            o.exchange_rate_at_issue,
            r.rate AS month_end_rate
        FROM open_fx o
        JOIN fx_rates r ON r.currency_code = o.currency_code AND r.rate_date = ?
        """,
        (month_end,),
    )

    if arrow_table is None or arrow_table.num_rows == 0:
        return []

    # ``pl.col().sub().round(2)`` zamiast SQL ROUND().
    df = pl.from_arrow(arrow_table).with_columns(
        [
            (
                pl.col("amount_foreign") * pl.col("month_end_rate")
                - pl.col("amount_foreign") * pl.col("exchange_rate_at_issue")
            )
            .round(2)
            .alias("unrealized_delta")
        ]
    )

    df = df.shrink_dtype()

    return df.select(["id", "invoice_type", "currency_code", "unrealized_delta"]).rows()
