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

    @staticmethod
    def create_cashflow_projection_view(duckdb_mgr: DuckDBManager) -> None:
        """Buduje analityczny widok projekcji cashflow z korektą ryzyka kontrahenta."""

        duckdb_mgr.execute(
            """
            CREATE TABLE IF NOT EXISTS manual_cashflow_items (
                id UUID,
                type VARCHAR,
                expected_date DATE,
                amount DECIMAL(18,2),
                description VARCHAR,
                is_active BOOLEAN DEFAULT TRUE
            )
            """
        )

        duckdb_mgr.execute(
            """
            CREATE OR REPLACE VIEW v_cashflow_projection AS
            WITH
            inflows AS (
                SELECT
                    i.id AS source_id,
                    'INVOICE_INFLOW' AS source_type,
                    (CAST(i.due_date AS DATE) + COALESCE(vs.avg_delay_days, 0) * INTERVAL 1 DAY)::DATE AS projected_date,
                    CAST(
                        CASE
                            WHEN COALESCE(vs.vendor_score, 1.0) < 0.4 THEN i.amount_gross * 0.5
                            ELSE i.amount_gross
                        END AS DECIMAL(18,2)
                    ) AS amount,
                    'INFLOW' AS flow_direction,
                    i.number AS description
                FROM invoices_replica i
                LEFT JOIN vendor_scorecards vs ON vs.contractor_nip = i.contractor_nip
                WHERE i.status = 'UNPAID' AND COALESCE(i.amount_gross, 0) > 0
            ),
            outflows AS (
                SELECT
                    i.id AS source_id,
                    'INVOICE_OUTFLOW' AS source_type,
                    CAST(i.due_date AS DATE) AS projected_date,
                    CAST(ABS(i.amount_gross) AS DECIMAL(18,2)) AS amount,
                    'OUTFLOW' AS flow_direction,
                    i.number AS description
                FROM invoices_replica i
                WHERE i.status = 'UNPAID' AND COALESCE(i.amount_gross, 0) < 0
            ),
            manual_items AS (
                SELECT
                    id AS source_id,
                    'MANUAL_ITEM' AS source_type,
                    expected_date AS projected_date,
                    CAST(amount AS DECIMAL(18,2)) AS amount,
                    CAST(type AS VARCHAR) AS flow_direction,
                    description
                FROM manual_cashflow_items
                WHERE is_active = TRUE
            ),
            tax_reserves AS (
                SELECT
                    uuid() AS source_id,
                    'VAT_RESERVE' AS source_type,
                    (date_trunc('month', CURRENT_DATE) + INTERVAL 1 MONTH + INTERVAL 19 DAY)::DATE AS projected_date,
                    CAST(GREATEST(SUM(amount_gross - amount_net), 0) AS DECIMAL(18,2)) AS amount,
                    'OUTFLOW' AS flow_direction,
                    'VAT reserve payment' AS description
                FROM invoices_replica
                WHERE date_trunc('month', CAST(issue_date AS DATE)) = date_trunc('month', CURRENT_DATE)

                UNION ALL

                SELECT
                    uuid() AS source_id,
                    'INCOME_TAX_RESERVE' AS source_type,
                    (date_trunc('month', CURRENT_DATE) + INTERVAL 1 MONTH + INTERVAL 24 DAY)::DATE AS projected_date,
                    CAST(GREATEST(SUM(amount_net) * 0.19, 0) AS DECIMAL(18,2)) AS amount,
                    'OUTFLOW' AS flow_direction,
                    'Income tax reserve payment' AS description
                FROM invoices_replica
                WHERE date_trunc('month', CAST(issue_date AS DATE)) = date_trunc('month', CURRENT_DATE)
            )
            SELECT * FROM inflows
            UNION ALL SELECT * FROM outflows
            UNION ALL SELECT * FROM manual_items
            UNION ALL SELECT * FROM tax_reserves
            """
        )
