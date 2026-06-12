from __future__ import annotations

from msgspec import Struct
from decimal import Decimal
from typing import TYPE_CHECKING

import pendulum

from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

if TYPE_CHECKING:
    from db.analytics import DuckDBManager


class LiquidityPoint(Struct, frozen=True):
    date: str
    optimistic_balance: str
    likely_balance: str
    pessimistic_balance: str


def ensure_liquidity_schema(duckdb: DuckDBManager) -> None:
    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS recurring_commitments (
            id UUID PRIMARY KEY,
            commitment_name VARCHAR NOT NULL,
            amount DECIMAL(18,2) NOT NULL,
            currency VARCHAR NOT NULL DEFAULT 'PLN',
            day_of_month INTEGER NOT NULL,
            is_active BOOLEAN NOT NULL DEFAULT TRUE
        )
        """
    )

    duckdb.execute(
        """
        CREATE OR REPLACE VIEW v_payor_reliability_stats AS
        WITH ranked AS (
            SELECT
                contractor_nip AS vendor_id,
                date_diff('day', due_date, payment_date) AS delta_days,
                ROW_NUMBER() OVER (PARTITION BY contractor_nip ORDER BY payment_date DESC) AS rn
            FROM invoices_replica
            WHERE status = 'PAID'
              AND payment_date IS NOT NULL
              AND due_date IS NOT NULL
        ),
        limited AS (
            SELECT * FROM ranked WHERE rn <= 10
        ),
        weighted AS (
            SELECT
                vendor_id,
                delta_days,
                CASE
                    WHEN rn <= 3 THEN 0.20
                    WHEN rn <= 6 THEN 0.12
                    ELSE 0.08
                END AS weight
            FROM limited
        )
        SELECT
            vendor_id,
            SUM(delta_days * weight) / NULLIF(SUM(weight), 0) AS weighted_average_delay,
            stddev_samp(delta_days) AS payment_volatility,
            CAST(GREATEST(0, LEAST(100, 100 - (AVG(ABS(delta_days)) * 8))) AS INTEGER) AS reliability_score
        FROM weighted
        GROUP BY vendor_id
        """
    )


def _vat_buffer_today(duckdb: DuckDBManager) -> Decimal:
    rows = duckdb.execute(
        """
        SELECT
            COALESCE(SUM(CASE WHEN type = 'SALE' THEN vat_amount ELSE 0 END), 0)
            - COALESCE(SUM(CASE WHEN type = 'PURCHASE' THEN vat_amount ELSE 0 END), 0) AS vat_liability
        FROM invoices_replica
        WHERE date_trunc('month', issue_date) = date_trunc('month', current_date)
        """
    )
    return Decimal(str(rows[0][0] if rows else 0)).quantize(Decimal("0.01"))


def calculate_liquidity_timeline(
    duckdb: DuckDBManager,
    tigerbeetle: TigerBeetleClient,
    *,
    account_bank_id: int,
    days_ahead: int = 90,
) -> list[LiquidityPoint]:
    """Forecast timeline with optimistic/likely/pessimistic balances."""

    cleared = Decimal(tigerbeetle._account_credits_posted.get(account_bank_id, 0)) / Decimal(100)
    pending = Decimal(
        sum(
            t.amount_minor
            for t in tigerbeetle._pending_transfers.values()
            if t.credit_account == account_bank_id
        )
    ) / Decimal(100)
    start_balance = (cleared + pending).quantize(Decimal("0.01"))

    inflows = duckdb.execute(
        """
        SELECT
            COALESCE(i.contractor_nip, 'UNKNOWN') AS vendor_id,
            i.amount_gross,
            i.due_date,
            COALESCE(s.weighted_average_delay, 0) AS delay,
            COALESCE(s.payment_volatility, 0) AS volatility,
            COALESCE(s.reliability_score, 50) AS reliability
        FROM invoices_replica i
        LEFT JOIN v_payor_reliability_stats s ON s.vendor_id = i.contractor_nip
        WHERE i.status = 'UNPAID' AND i.type = 'SALE' AND i.due_date IS NOT NULL
        """
    )

    outflows = duckdb.execute(
        """
        SELECT amount_gross, due_date
        FROM invoices_replica
        WHERE status IN ('UNPAID', 'PARTIAL') AND type = 'PURCHASE' AND due_date IS NOT NULL
        """
    )

    recurring = duckdb.execute(
        """
        SELECT amount, day_of_month
        FROM recurring_commitments
        WHERE is_active = TRUE
        """
    )

    vat_buffer = _vat_buffer_today(duckdb)
    today = pendulum.now().date()

    opt = start_balance
    likely = start_balance
    pess = start_balance
    timeline: list[LiquidityPoint] = []

    for step in range(days_ahead + 1):
        d = today + pendulum.duration(days=step)

        for amount, due_date in outflows:
            if due_date == d:
                amt = Decimal(str(amount))
                opt -= amt
                likely -= amt
                pess -= amt

        for amount, day_of_month in recurring:
            if int(day_of_month) == d.day:
                amt = Decimal(str(amount))
                opt -= amt
                likely -= amt
                pess -= amt

        for vendor_id, amount, due_date, delay, volatility, reliability in inflows:
            amt = Decimal(str(amount))
            adjusted = due_date + pendulum.duration(days=int(float(delay)))
            if d == adjusted:
                opt += amt
            likely_day = adjusted + pendulum.duration(days=int(float(volatility)))
            if d == likely_day:
                likely += amt
            pess_day = adjusted + pendulum.duration(days=int(float(volatility) * 2))
            if d == pess_day:
                mult = Decimal("0.7") if int(reliability) < 50 else Decimal("1.0")
                pess += (amt * mult).quantize(Decimal("0.01"))

        next_month_25 = (today.replace(day=1) + pendulum.duration(days=32)).replace(day=25)
        if d == next_month_25:
            opt -= vat_buffer
            likely -= vat_buffer
            pess -= vat_buffer

        timeline.append(
            LiquidityPoint(
                date=d.isoformat(),
                optimistic_balance=str(opt.quantize(Decimal("0.01"))),
                likely_balance=str(likely.quantize(Decimal("0.01"))),
                pessimistic_balance=str(pess.quantize(Decimal("0.01"))),
            )
        )

    return timeline
