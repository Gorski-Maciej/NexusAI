from db.analytics import DuckDBManager

class AnalyticsViewsSetup:
    """Inicjalizuje zmaterializowane widoki biznesowe w DuckDB dla maksymalnej wydajności."""

    @staticmethod
    def create_dashboard_views(duckdb_mgr: DuckDBManager):
        """Uruchamiane jednorazowo przy starcie aplikacji."""

        # Widok 1: Agregacja miesięczna kosztów i przychodów
        duckdb_mgr.execute("""
        CREATE VIEW IF NOT EXISTS v_monthly_summary AS
        SELECT
            strftime('%Y-%m', issue_date) AS period,
            COUNT(id) as document_count,
            SUM(amount_net) as total_net,
            SUM(amount_gross) as total_gross
        FROM invoices_replica
        WHERE status != 'REJECTED'
        GROUP BY 1
        """)

        # Widok 2: Top Kontrahenci (gdzie idzie najwięcej pieniędzy)
        duckdb_mgr.execute("""
        CREATE VIEW IF NOT EXISTS v_top_contractors AS
        SELECT
            contractor_nip,
            SUM(amount_gross) as total_spent
        FROM invoices_replica
        GROUP BY 1
        ORDER BY total_spent DESC
        """)
