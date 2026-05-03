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
        """Pobiera błyskawiczne raporty finansowe z DuckDB."""
        # DuckDB limits and threads are already configured in DuckDBManager
        manager = DuckDBManager(db_path="nexus_olap.duckdb", sqlite_path="app_data/nexus_oltp.db", read_only=True)

        query = f"""
        SELECT date_trunc('{data.dimension}', issue_date) as period,
               SUM(amount_gross) as total_gross
        FROM oltp.invoices
        WHERE issue_date BETWEEN ? AND ?
        GROUP BY period ORDER BY period;
        """
        try:
            results = manager.execute(query, (data.start_date, data.end_date))
            if not results:
                return {"rows": [], "total_gross": 0.0}
            rows = [{"period": str(r[0]), "total_gross": float(r[1] or 0.0)} for r in results]
            return {"rows": rows, "total_gross": sum(x["total_gross"] for x in rows)}
        except Exception as e:
            # W logach systemowych warto by to zapisać
            return {"error": str(e), "rows": [], "total_gross": 0.0}
        finally:
            manager.close()

    @get("/monthly-trend")
    @ttl_cache(seconds=60)
    async def get_monthly_trend(self, state: Any) -> list[dict[str, Any]]:
        """Opcjonalny endpoint pod wykresy (np. trend wydatków)."""
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
