# core/analytics.py
import duckdb
import polars as pl


def get_cashflow_forecast(db_path: str = "data/nexus_analytics.duckdb") -> pl.DataFrame:
    conn = duckdb.connect(db_path)
    # Zapytanie: sumujemy przychody i koszty po dacie płatności (due_date) i obliczamy skumulowane saldo (CASHFLOW)
    query = """
    WITH DailyFlows AS (
        SELECT
            due_date,
            SUM(CASE WHEN type = 'SALE' THEN amount_gross ELSE 0 END) as daily_in,
            SUM(CASE WHEN type = 'COST' THEN amount_gross ELSE 0 END) as daily_out
        FROM invoices
        WHERE due_date >= CURRENT_DATE
          AND due_date <= CURRENT_DATE + INTERVAL 30 DAY
        GROUP BY due_date
    )
    SELECT
        due_date,
        daily_in,
        daily_out,
        SUM(daily_in - daily_out) OVER (ORDER BY due_date ASC) as projected_balance
    FROM DailyFlows
    ORDER BY due_date;
    """
    df = conn.execute(query).pl()  # DuckDB natywnie zwraca Polars DataFrame
    conn.close()
    return df
