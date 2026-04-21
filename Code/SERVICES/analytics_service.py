from db.analytics import DuckDBManager


class AnalyticsService:
    def __init__(self, duckdb: DuckDBManager):
        self.duckdb = duckdb

    def get_monthly_spending_trend(self) -> list[dict]:
        """Zwraca sumy wydatków pogrupowane po miesiącach dla wykresów."""
        query = """
        SELECT
            strftime('%Y-%m', issue_date) as month,
            SUM(amount_gross) as total_gross,
            COUNT(id) as invoice_count
        FROM invoices_replica
        WHERE status = 'APPROVED'
        GROUP BY 1
        ORDER BY 1 DESC
        LIMIT 12
        """
        return self.duckdb.execute_query(query)

    def get_top_suppliers(self, limit: int = 5) -> list[dict]:
        """Analizuje, u których kontrahentów zostawiamy najwięcej pieniędzy."""
        query = f"""
        SELECT
            contractor_nip,
            SUM(amount_gross) as total_spent
        FROM invoices_replica
        WHERE status = 'APPROVED'
        GROUP BY 1
        ORDER BY 2 DESC
        LIMIT {limit}
        """
        return self.duckdb.execute_query(query)
