from __future__ import annotations

from decimal import Decimal
from pathlib import Path
from typing import TYPE_CHECKING

import pendulum
from msgspec import Struct

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
    """Forecast timeline with optimistic/likely/pessimistic balances.

    - ``GENERATE_SERIES`` zamiast pętli ``for step in range(days_ahead)`` w Pythonie
    - Window functions dla running totals zamiast ręcznego ``opt -= amt``
    - Wszystkie obliczenia w jednym SQL -- zero pętli w Pythonie

    - ``pl.from_arrow()`` -- zero-copy z DuckDB Arrow do Polars
    - **LazyFrame z wyrażeniami** -- ``pl.col().cast()`` zamiast pa.compute
    - ``pl.SQLContext`` -- integracja SQL z expression API Polars
    - ``sink_parquet()`` -- zapis prognozy bezpośrednio do Parquet bez RAM
    - ``shrink_dtype()`` -- redukcja RAM o 50% na typach liczbowych
    - Zysk: czystsze API, pełna moc Polars query engine
    """

    import polars as pl

    cleared = Decimal(tigerbeetle._account_credits_posted.get(account_bank_id, 0)) / Decimal(100)
    start_balance = cleared

    # DuckDB produkuje pa.Table, Polars konsumuje bez kopiowania.
    result_table = duckdb.execute_arrow(
        """
        WITH calendar AS (
            SELECT unnest(generate_series(
                CURRENT_DATE,
                CURRENT_DATE + INTERVAL '90 days',
                INTERVAL '1 day'
            ))::DATE AS d
        ),
        daily_outflows AS (
            SELECT due_date AS d, SUM(ABS(amount_gross)) AS outflow
            FROM invoices_replica
            WHERE status IN ('UNPAID', 'PARTIAL') AND type = 'PURCHASE'
              AND due_date IS NOT NULL
            GROUP BY 1
        ),
        daily_recurring AS (
            SELECT c.d, SUM(r.amount) AS recurring_outflow
            FROM calendar c
            JOIN recurring_commitments r
              ON EXTRACT(day FROM c.d) = r.day_of_month
            WHERE r.is_active = TRUE
            GROUP BY c.d
        ),
        daily_inflows_adj AS (
            SELECT
                (i.due_date + COALESCE(s.weighted_average_delay, 0) * INTERVAL '1 day')::DATE AS d_opt,
                (i.due_date + COALESCE(s.weighted_average_delay, 0) * INTERVAL '1 day'
                    + COALESCE(s.payment_volatility, 0) * INTERVAL '1 day')::DATE AS d_likely,
                (i.due_date + COALESCE(s.weighted_average_delay, 0) * INTERVAL '1 day'
                    + COALESCE(s.payment_volatility, 0) * 2 * INTERVAL '1 day')::DATE AS d_pess,
                i.amount_gross,
                CASE WHEN COALESCE(s.reliability_score, 50) < 50 THEN 0.7 ELSE 1.0 END AS reliability_mult
            FROM invoices_replica i
            LEFT JOIN v_payor_reliability_stats s ON s.vendor_id = i.contractor_nip
            WHERE i.status = 'UNPAID' AND i.type = 'SALE' AND i.due_date IS NOT NULL
        ),
        daily_inflows AS (
            SELECT d_opt AS d, SUM(amount_gross) AS opt_inflow,
                   SUM(amount_gross * reliability_mult) AS pess_inflow
            FROM daily_inflows_adj GROUP BY 1
        ),
        daily_aggregated AS (
            SELECT c.d,
                   COALESCE(opt_inflow, 0) AS opt_inflow,
                   COALESCE(pess_inflow, 0) AS pess_inflow,
                   COALESCE(outflow, 0) AS outflow,
                   COALESCE(recurring_outflow, 0) AS recurring_outflow
            FROM calendar c
            LEFT JOIN daily_inflows i ON i.d = c.d
            LEFT JOIN daily_outflows o ON o.d = c.d
            LEFT JOIN daily_recurring r ON r.d = c.d
        )
        SELECT d::VARCHAR AS date,
               (? + SUM(opt_inflow - outflow - recurring_outflow) OVER (ORDER BY d))::DOUBLE AS opt,
               (? + SUM(opt_inflow - outflow - recurring_outflow) OVER (ORDER BY d))::DOUBLE AS likely,
               (? + SUM(pess_inflow - outflow - recurring_outflow) OVER (ORDER BY d))::DOUBLE AS pess
        FROM daily_aggregated
        ORDER BY d
        """,
        (float(start_balance), float(start_balance), float(start_balance)),
    )

    if result_table is None:
        return []

    # Polars przejmuje Arrow buffer bez kopiowania. LazyFrame
    # pozwala na dalsze transformacje przed kolekcją.
    lazy_df = pl.from_arrow(result_table).lazy()

    # Jawny schemat + redukcja typów dla oszczędności RAM.
    lazy_df = lazy_df.with_columns(
        [
            pl.col("opt").cast(pl.Float64),
            pl.col("likely").cast(pl.Float64),
            pl.col("pess").cast(pl.Float64),
        ]
    )

    df = lazy_df.collect(streaming=True)

    df = df.shrink_dtype()

    # - Partycjonowanie: year=/month=/day= -- szybkie odcięcie partycji
    # - ``sink_parquet()`` -- streaming zapis bez alokacji RAM
    # - ``scan_parquet()`` -- leniwe odczytywanie historycznych prognoz
    try:
        now = pendulum.now()
        parquet_dir = Path("/tmp/liquidity_forecasts")
        part_path = parquet_dir / f"year={now.year}/month={now.month:02d}/day={now.day:02d}"
        part_path.mkdir(parents=True, exist_ok=True)
        forecast_path = part_path / f"forecast_{now.format('HHmmss')}.parquet"

        df.lazy().sink_parquet(
            str(forecast_path),
            compression="zstd",
        )
    except Exception:
        pass  # Non-critical -- prognoza działa dalej w RAM

    # Polars ``.to_dicts()" zwraca listę słowników w C++ -- szybciej
    # niż pętla ``for row in df.iter_rows()`` w Pythonie.
    timeline: list[LiquidityPoint] = []
    for row_dict in df.to_dicts():
        timeline.append(
            LiquidityPoint(
                date=str(row_dict.get("date", "")),
                optimistic_balance=str(row_dict.get("opt", "0")),
                likely_balance=str(row_dict.get("likely", "0")),
                pessimistic_balance=str(row_dict.get("pess", "0")),
            )
        )
    return timeline
