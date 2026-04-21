# core/analytics/forecaster.py
import pandas as pd
from sklearn.linear_model import LinearRegression
import numpy as np
from datetime import datetime, timedelta
from db.analytics import DuckDBManager

class CashflowForecaster:
    """Przewiduje saldo firmy na podstawie trendów historycznych z DuckDB."""

    def __init__(self, db_manager: DuckDBManager):
        self.db = db_manager

    async def predict_liquidity_gap(self, days_ahead: int = 30) -> dict:
        """Oblicza prognozowane saldo końcowe i identyfikuje ryzyko luki."""
        # 1. Pobieranie danych historycznych z DuckDB
        query = """
        SELECT
            CAST(issue_date AS DATE) as date,
            SUM(amount_gross) as daily_sum
        FROM invoices_replica
        WHERE status = 'APPROVED'
        GROUP BY 1 ORDER BY 1
        """
        data = self.db.execute_query(query)
        df = pd.DataFrame(data)

        if df.empty or len(df) < 5:
            return {"status": "INSUFFICIENT_DATA"}

        # Zastępcze uproszczenie logiki predykcyjnej dla Cashflow
        projected_total = df['daily_sum'].sum() # Przykładowe zwrócenie sumy

        return {
            "projected_delta": float(projected_total),
            "forecast_date": (datetime.now() + timedelta(days=days_ahead)).strftime("%Y-%m-%d"),
            "risk_level": "HIGH" if projected_total < 0 else "LOW"
        }
