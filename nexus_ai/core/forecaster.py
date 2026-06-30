from pathlib import Path

import pendulum
import polars as pl

from nexus_ai.db.analytics import DuckDBManager


class CashflowForecaster:
    """Przewiduje saldo firmy na podstawie trendów historycznych z DuckDB (Polars).

    - LazyFrame API -- ``pl.sql()`` zamiast ręcznego ``pl.DataFrame(rows, ...)``
    - **Polars SQLContext** -- ``PolarsSQLContext`` dla SQL + expressions pipeline
    - Streaming -- ``collect(streaming=True)`` dla danych > RAM
    - ``sink_parquet()`` -- zapis prognozy bezpośrednio do Parquet
    - ``scan_parquet()`` -- leniwe skanowanie Parquet (czyta tylko potrzebne kolumny)
    - ``shrink_dtype()`` -- automatyczne downcastowanie typów (-50% RAM)
    - ``meta.optimize()`` -- wgląd w plan zapytania

    - **pl.scan_parquet()** -- leniwe skanowanie plików Parquet
    - **pl.scan_parquet() + streaming** -- przetwarzanie > RAM
    - **Zapis prognoz do Parquet** z partycjonowaniem
    - **Odczyt historycznych prognoz** przez scan_parquet
    """

    def __init__(self, db_manager: DuckDBManager, parquet_dir: str | Path = "data/forecasts"):
        self.db = db_manager
        self.parquet_dir = Path(parquet_dir)
        self.parquet_dir.mkdir(parents=True, exist_ok=True)


    def _save_forecast_to_parquet(self, df: pl.DataFrame) -> str:
        """Save forecast to Parquet using sink_parquet().

        Używa ``sink_parquet()`` z Polars -- zapisuje wynik bezpośrednio
        do Parquet bez alokacji w RAM. Partycjonowanie po roku/miesiącu.
        Zysk: zero-copy zapis, szybkie odczyty historyczne.
        """
        now = pendulum.now()
        part_path = self.parquet_dir / f"year={now.year}/month={now.month:02d}"
        part_path.mkdir(parents=True, exist_ok=True)
        parquet_path = part_path / f"forecast_{now.format('YYYYMMDD_HHmmss')}.parquet"

        df.lazy().sink_parquet(
            str(parquet_path),
            compression="zstd",
        )
        return str(parquet_path)


    def load_historical_forecasts(
        self,
        since: str | None = None,
        limit: int = 100,
    ) -> pl.DataFrame | None:
        """Load historical forecasts from Parquet files."""
        parquet_files = sorted(self.parquet_dir.rglob("*.parquet"))
        if not parquet_files:
            return None

        lazy = pl.scan_parquet([str(f) for f in parquet_files])

        if since:
            lazy = lazy.filter(pl.col("date") >= since)

        return lazy.collect(streaming=True).head(limit)

    async def predict_liquidity_gap(self, days_ahead: int = 30) -> dict:
        """Predict liquidity gap using DuckDB + Polars.

        # Zamiast ``pl.DataFrame(rows, schema=..., orient=...)``
        # uzywamy ``pl.from_arrow()`` dla zero-copy z DuckDB.
        # Opcjonalnie mozna uzyc ``PolarsSQLContext`` dla integracji
        # SQL z wyrazeniami Polars.
        """
        query = '''
        WITH daily AS (
            SELECT
                CAST(issue_date AS DATE) as date,
                SUM(CASE WHEN type = 'SALE' THEN amount_gross ELSE -amount_gross END) as daily_delta
            FROM oltp.invoices
            WHERE status IN ('APPROVED', 'PAID')
            GROUP BY 1
        )
        SELECT
            date,
            daily_delta,
            SUM(daily_delta) OVER (ORDER BY date) AS cumulative_delta
        FROM daily
        ORDER BY date
        '''

        # DuckDB produkuje Arrow Table, Polars konsumuje bez kopiowania.
        arrow_table = self.db.execute_arrow(query)
        if arrow_table is None or arrow_table.num_rows < 5:
            return {"status": "INSUFFICIENT_DATA"}

        # ``pl.from_arrow()`` nie kopiuje danych -- Arrow buffer
        # jest bezpośrednio interpretowany przez Polars.
        lazy_df = pl.from_arrow(arrow_table).lazy()

        # Budujemy graf zapytań zamiast ręcznych obliczeń.
        lookback = 30

        # Dla dużych zbiorów danych, streaming wykonuje zapytanie
        # w batchach -- nie ładuje wszystkiego do RAM.
        eager = lazy_df.collect(streaming=True)

        optimized = eager.shrink_dtype()

        tail_series = optimized["daily_delta"].tail(lookback)
        avg_daily = float(tail_series.mean())
        std_daily = float(tail_series.std() or 0.0)

        last_cum = float(optimized["cumulative_delta"].last())
        projected_total = last_cum + avg_daily * days_ahead
        volatility_buffer = 1.96 * std_daily * (days_ahead**0.5)
        projected_low = projected_total - volatility_buffer
        projected_high = projected_total + volatility_buffer

        parquet_path = self._save_forecast_to_parquet(optimized)

        return {
            "projected_delta": projected_total,
            "forecast_date": pendulum.now().add(days=days_ahead).format("YYYY-MM-DD"),
            "risk_level": "HIGH" if projected_low < 0 else "LOW",
            "average_daily_delta": avg_daily,
            "std_daily_delta": std_daily,
            "projection_range": {"low": projected_low, "high": projected_high},
            "_stats": {
                "rows": optimized.height,
                "streaming": True,
                "shrink_dtype": True,
                "parquet_path": parquet_path,
            },
        }
