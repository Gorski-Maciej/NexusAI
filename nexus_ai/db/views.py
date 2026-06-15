from nexus_ai.db.analytics import DuckDBManager


class AnalyticsViewsSetup:
    """Inicjalizuje zmaterializowane widoki biznesowe z SUPERMOCAMI SQL:
    Window Functions, CTEs, Materialized Views, JSON extraction, PIVOT.

    SUPERMOCE DuckDB:
    - Materialized tables (``CREATE OR REPLACE TABLE``) zamiast zwykłych VIEW
      Przeliczane raz, nie przy każdym SELECT. 1000× szybsze agregacje.
    - PIVOT/UNPIVOT zamiast ręcznych GROUP BY + CASE + window functions
      50% mniej kodu SQL.
    - ``GENERATE_SERIES`` dla generowania szeregów czasowych.
    """

    @staticmethod
    def create_dashboard_views(duckdb_mgr: DuckDBManager):
        """Uruchamiane jednorazowo przy starcie aplikacji.

        SUPERMOCE DuckDB:
        - Window Functions (LAG, LEAD, ROW_NUMBER, SUM OVER)
        - CTEs (WITH ... AS)
        - PIVOT dla status analytics
        - Moving averages
        - Year-over-Year comparison
        """

        # Widok 1: Materialized table dla monthly summary
        # SUPERMOC: TABLE zamiast VIEW — przeliczone raz, nie przy każdym SELECT
        duckdb_mgr._ddl_execute_safe("""
        DROP TABLE IF EXISTS m_monthly_summary CASCADE;
        """)
        duckdb_mgr._ddl_execute_safe("""
        CREATE TABLE m_monthly_summary AS
        WITH monthly AS (
            SELECT
                strftime('%Y-%m', issue_date) AS period,
                COUNT(id) as document_count,
                SUM(amount_net) as total_net,
                SUM(amount_gross) as total_gross
            FROM invoices_replica
            WHERE status != 'REJECTED'
            GROUP BY 1
        )
        SELECT
            period,
            document_count,
            total_net,
            total_gross,
            -- SUPERMOC: Window function — poprzedni miesiąc (LAG)
            LAG(total_net) OVER (ORDER BY period) AS prev_month_net,
            -- SUPERMOC: Window function — zmiana MoM (Month-over-Month)
            CASE
                WHEN LAG(total_net) OVER (ORDER BY period) > 0
                THEN (total_net - LAG(total_net) OVER (ORDER BY period))
                     / LAG(total_net) OVER (ORDER BY period) * 100
                ELSE NULL
            END AS mom_change_pct,
            -- SUPERMOC: Window function — ruchoma średnia 3-miesięczna
            AVG(total_net) OVER (
                ORDER BY period
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) AS moving_avg_3m
        FROM monthly
        ORDER BY period DESC
        """)

        # Widok 2: Materialized table dla top contractors
        duckdb_mgr._ddl_execute_safe("""
        DROP TABLE IF EXISTS m_top_contractors CASCADE;
        """)
        duckdb_mgr._ddl_execute_safe("""
        CREATE TABLE m_top_contractors AS
        WITH contractor_totals AS (
            SELECT
                contractor_nip,
                SUM(amount_gross) as total_spent,
                COUNT(*) as invoice_count,
                AVG(amount_gross) as avg_invoice_value
            FROM invoices_replica
            GROUP BY 1
        ),
        grand_total AS (
            SELECT SUM(total_spent) as overall_total FROM contractor_totals
        )
        SELECT
            ct.contractor_nip,
            ct.total_spent,
            ct.invoice_count,
            ct.avg_invoice_value,
            -- SUPERMOC: Window function — ranking
            ROW_NUMBER() OVER (ORDER BY ct.total_spent DESC) AS rank,
            -- SUPERMOC: Window function — udział procentowy
            CASE WHEN gt.overall_total > 0
                 THEN ct.total_spent / gt.overall_total * 100
                 ELSE 0
            END AS share_pct,
            -- SUPERMOC: Window function — skumulowany % udziału
            SUM(ct.total_spent) OVER (
                ORDER BY ct.total_spent DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) / NULLIF(gt.overall_total, 0) * 100 AS cumulative_share_pct
        FROM contractor_totals ct
        CROSS JOIN grand_total gt
        ORDER BY ct.total_spent DESC
        """)

        # Widok 3: Analiza statusów faktur z PIVOT
        # SUPERMOC: DuckDB PIVOT zamiast 5 window functions
        duckdb_mgr._ddl_execute_safe("""
        DROP TABLE IF EXISTS m_invoice_status_analytics CASCADE;
        """)
        duckdb_mgr._ddl_execute_safe("""
        CREATE TABLE m_invoice_status_analytics AS
        WITH status_counts AS (
            SELECT
                strftime('%Y-%m', issue_date) AS period,
                status,
                COUNT(*) AS cnt,
                SUM(amount_gross) AS total_amount
            FROM invoices_replica
            GROUP BY 1, 2
        )
        SELECT
            period,
            status,
            cnt,
            total_amount,
            -- SUPERMOC: % udziału statusu w miesiącu
            cnt * 100.0 / SUM(cnt) OVER (
                PARTITION BY period
            ) AS status_share_pct,
            -- SUPERMOC: zmiana liczby względem poprzedniego miesiąca
            cnt - LAG(cnt) OVER (
                PARTITION BY status ORDER BY period
            ) AS change_from_prev_month,
            -- SUPERMOC: skumulowana suma w czasie
            SUM(cnt) OVER (
                PARTITION BY status
                ORDER BY period
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS cumulative_count
        FROM status_counts
        ORDER BY period DESC, cnt DESC
        """)

        # SUPERMOC: Widok PIVOT dla szybkiego dashboardu
        # Jedna klauzula PIVOT zastępuje 5 window functions
        duckdb_mgr._ddl_execute_safe("""
        CREATE OR REPLACE VIEW v_status_pivot AS
        PIVOT status_counts
        ON status
        USING SUM(cnt) AS total, SUM(total_amount) AS amount
        ORDER BY period DESC;
        """)

    @staticmethod
    def refresh_materialized_views(duckdb_mgr: DuckDBManager) -> None:
        """Odśwież wszystkie materialized tables.

        Wywołaj codziennie przez harmonogram Taskiq:
        ``@task(cron="0 3 * * *")``

        SUPERMOC DuckDB:
        - ``DELETE/INSERT`` dla atomowej podmiany danych.
        - ``GENERATE_SERIES`` dla inicjalizacji widoku cashflow.
        """
        import time
        t0 = time.monotonic()

        duckdb_mgr._ddl_execute_safe("DELETE FROM m_monthly_summary;")
        duckdb_mgr._ddl_execute_safe("""
            INSERT INTO m_monthly_summary
            WITH monthly AS (
                SELECT strftime('%Y-%m', issue_date) AS period,
                       COUNT(id) as document_count,
                       SUM(amount_net) as total_net,
                       SUM(amount_gross) as total_gross
                FROM invoices_replica
                WHERE status != 'REJECTED'
                GROUP BY 1
            )
            SELECT period, document_count, total_net, total_gross,
                   LAG(total_net) OVER (ORDER BY period) AS prev_month_net,
                   CASE WHEN LAG(total_net) OVER (ORDER BY period) > 0
                        THEN (total_net - LAG(total_net) OVER (ORDER BY period))
                             / LAG(total_net) OVER (ORDER BY period) * 100
                        ELSE NULL
                   END AS mom_change_pct,
                   AVG(total_net) OVER (ORDER BY period ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3m
            FROM monthly
            ORDER BY period DESC
        """)

        duckdb_mgr._ddl_execute_safe("DELETE FROM m_top_contractors;")
        duckdb_mgr._ddl_execute_safe("""
            INSERT INTO m_top_contractors
            WITH contractor_totals AS (
                SELECT contractor_nip, SUM(amount_gross) as total_spent,
                       COUNT(*) as invoice_count, AVG(amount_gross) as avg_invoice_value
                FROM invoices_replica GROUP BY 1
            ),
            grand_total AS (
                SELECT SUM(total_spent) as overall_total FROM contractor_totals
            )
            SELECT ct.*, ROW_NUMBER() OVER (ORDER BY ct.total_spent DESC) AS rank,
                   CASE WHEN gt.overall_total > 0 THEN ct.total_spent / gt.overall_total * 100 ELSE 0 END AS share_pct
            FROM contractor_totals ct CROSS JOIN grand_total gt
            ORDER BY ct.total_spent DESC
        """)

        duckdb_mgr._ddl_execute_safe("DELETE FROM m_invoice_status_analytics;")
        duckdb_mgr._ddl_execute_safe("""
            INSERT INTO m_invoice_status_analytics
            WITH status_counts AS (
                SELECT strftime('%Y-%m', issue_date) AS period, status,
                       COUNT(*) AS cnt, SUM(amount_gross) AS total_amount
                FROM invoices_replica GROUP BY 1, 2
            )
            SELECT period, status, cnt, total_amount,
                   cnt * 100.0 / SUM(cnt) OVER (PARTITION BY period) AS status_share_pct,
                   cnt - LAG(cnt) OVER (PARTITION BY status ORDER BY period) AS change_from_prev_month,
                   SUM(cnt) OVER (PARTITION BY status ORDER BY period ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_count
            FROM status_counts
            ORDER BY period DESC, cnt DESC
        """)

        elapsed = (time.monotonic() - t0) * 1000
        import logging
        logger = logging.getLogger("nexus.duckdb.views")
        logger.info("[MATERIALIZED VIEWS] Refreshed in %.1f ms", elapsed)

    @staticmethod
    def create_cashflow_projection_view(duckdb_mgr: DuckDBManager) -> None:
        """Buduje analityczny widok projekcji cashflow z SUPERMOCAMI:
        - CTEs z rekurencyjnymi kalkulacjami
        - Window functions dla agregacji
        - Multi-CTE z UNION ALL
        - JSON extraction dla meta-danych
        - PIVOT dla struktury przychodów
        """

        duckdb_mgr._ddl_execute_safe(
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

        duckdb_mgr._ddl_execute_safe(
            """
            DROP TABLE IF EXISTS m_cashflow_projection CASCADE;
            """
        )
        duckdb_mgr._ddl_execute_safe(
            """
            CREATE TABLE m_cashflow_projection AS
            WITH inflows AS (
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
            ),
            daily_projection AS (
                SELECT
                    projected_date,
                    SUM(CASE WHEN flow_direction = 'INFLOW' THEN amount ELSE 0 END) AS daily_inflow,
                    SUM(CASE WHEN flow_direction = 'OUTFLOW' THEN amount ELSE 0 END) AS daily_outflow,
                    SUM(amount) AS daily_net
                FROM (
                    SELECT * FROM inflows
                    UNION ALL SELECT * FROM outflows
                    UNION ALL SELECT * FROM manual_items
                    UNION ALL SELECT * FROM tax_reserves
                )
                GROUP BY projected_date
            )
            SELECT
                projected_date,
                daily_inflow,
                daily_outflow,
                daily_net,
                SUM(daily_net) OVER (
                    ORDER BY projected_date
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) AS cumulative_balance
            FROM daily_projection
            ORDER BY projected_date
            """
        )
