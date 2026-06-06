from datetime import datetime, timedelta

import polars as pl

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
        lookback = min(30, df.height)
        tail = df.tail(lookback)
        avg_daily = float(tail["daily_delta"].mean())
        std_daily = float(tail["daily_delta"].std() or 0.0)
        projected_total = float(df["cumulative_delta"][-1] + avg_daily * days_ahead)
        # 95% confidence approximation for accumulated random walk variance
        volatility_buffer = 1.96 * std_daily * (days_ahead ** 0.5)
        projected_low = projected_total - volatility_buffer
        projected_high = projected_total + volatility_buffer

        return {
            "projected_delta": projected_total,
            "forecast_date": (datetime.now() + timedelta(days=days_ahead)).strftime("%Y-%m-%d"),
            "risk_level": "HIGH" if projected_low < 0 else "LOW",
            "average_daily_delta": avg_daily,
            "std_daily_delta": std_daily,
            "projection_range": {"low": projected_low, "high": projected_high},
        }
