from litestar import Controller, post, get
from typing import Any
from api.schemas import AnalyticsQuery
from db.analytics import DuckDBManager
from api.cache import ttl_cache


class AnalyticsController(Controller):
    path = "/api/analytics"

    @post("/cashflow")
    @ttl_cache(seconds=60)
    async def get_cashflow_report(self, data: AnalyticsQuery) -> dict:
        """Pobiera raport cashflow z kumulacją i opcjonalną konwersją walut (ASOF JOIN)."""
        manager = DuckDBManager(db_path="nexus_olap.duckdb", sqlite_path="app_data/nexus_oltp.db", read_only=True)

        has_fx_rates = bool(
            manager.execute(
                """
                SELECT COUNT(*)
                FROM information_schema.tables
                WHERE lower(table_name) = 'fx_rates'
                """
            )[0][0]
        )

        if has_fx_rates:
            query = f"""
            WITH converted AS (
                SELECT
                    date_trunc('{data.dimension}', i.issue_date) AS period,
                    i.amount_gross * COALESCE(r.rate_to_pln, 1) /
                        CASE WHEN upper('{data.report_currency}') = 'PLN' THEN 1 ELSE COALESCE(r_target.rate_to_pln, 1) END
                        AS amount_converted
                FROM oltp.invoices i
                ASOF LEFT JOIN oltp.fx_rates r
                    ON upper(i.currency) = upper(r.currency)
                   AND r.effective_at <= i.issue_date
                ASOF LEFT JOIN oltp.fx_rates r_target
                    ON upper(r_target.currency) = upper('{data.report_currency}')
                   AND r_target.effective_at <= i.issue_date
                WHERE i.issue_date BETWEEN ? AND ?
            ),
            base AS (
                SELECT period, SUM(amount_converted) AS total_gross
                FROM converted
                GROUP BY period
            )
            SELECT
                period,
                total_gross,
                SUM(total_gross) OVER (ORDER BY period ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_gross
            FROM base
            ORDER BY period
            """
        else:
            query = f"""
            WITH base AS (
                SELECT
                    date_trunc('{data.dimension}', issue_date) AS period,
                    SUM(amount_gross) AS total_gross
                FROM oltp.invoices
                WHERE issue_date BETWEEN ? AND ?
                GROUP BY period
            )
            SELECT
                period,
                total_gross,
                SUM(total_gross) OVER (ORDER BY period ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_gross
            FROM base
            ORDER BY period
            """
        try:
            results = manager.execute(query, (data.start_date, data.end_date))
            if not results:
                return {"rows": [], "total_gross": 0.0, "cumulative_gross": 0.0, "report_currency": data.report_currency}
            rows = [
                {"period": str(r[0]), "total_gross": float(r[1] or 0.0), "cumulative_gross": float(r[2] or 0.0)}
                for r in results
            ]
            return {
                "rows": rows,
                "total_gross": sum(x["total_gross"] for x in rows),
                "cumulative_gross": rows[-1]["cumulative_gross"],
                "report_currency": data.report_currency,
            }
        except Exception as e:
            return {"error": str(e), "rows": [], "total_gross": 0.0}
        finally:
            manager.close()

    @get("/monthly-trend")
    @ttl_cache(seconds=60)
    async def get_monthly_trend(self, state: Any) -> list[dict[str, Any]]:
        manager: DuckDBManager = state.olap_manager
        query = """
        SELECT
            strftime(issue_date, '%Y-%m') as month,
            SUM(amount_gross) as total
        FROM oltp.invoices
        WHERE issue_date IS NOT NULL
        GROUP BY 1
        ORDER BY 1 DESC
        """
        results = manager.execute(query)
        return [{"month": str(row[0]), "total": float(row[1] or 0.0)} for row in results]
