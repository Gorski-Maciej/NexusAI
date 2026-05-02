import polars as pl
from datetime import datetime, timedelta
from db.analytics import DuckDBManager


class CashflowForecaster:
    """Przewiduje saldo firmy na podstawie trendów historycznych z DuckDB (Polars)."""

    def __init__(self, db_manager: DuckDBManager):
        self.db = db_manager

    async def predict_liquidity_gap(self, days_ahead: int = 30) -> dict:
        query = """
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
        """
        rows = self.db.execute(query)
        if not rows or len(rows) < 5:
            return {"status": "INSUFFICIENT_DATA"}

        df = pl.DataFrame(rows, schema=["date", "daily_delta", "cumulative_delta"], orient="row")
        avg_daily = float(df["daily_delta"].tail(min(14, df.height)).mean())
        projected_total = float(df["cumulative_delta"][-1] + avg_daily * days_ahead)

        return {
            "projected_delta": projected_total,
            "forecast_date": (datetime.now() + timedelta(days=days_ahead)).strftime("%Y-%m-%d"),
            "risk_level": "HIGH" if projected_total < 0 else "LOW",
            "average_daily_delta": avg_daily,
        }
