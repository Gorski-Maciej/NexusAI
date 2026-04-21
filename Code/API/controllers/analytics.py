from litestar import Controller, post, get
from typing import Any
from api.schemas import AnalyticsQuery
from db.analytics import DuckDBManager # Twój manager DuckDB z poprzednich plików

class AnalyticsController(Controller):
    path = "/api/analytics"

    @post("/cashflow")
    async def get_cashflow_report(self, data: AnalyticsQuery) -> dict:
        """Pobiera błyskawiczne raporty finansowe z DuckDB."""
        # DuckDB limits and threads are already configured in DuckDBManager
        manager = DuckDBManager(db_path="nexus_olap.duckdb")

        query = f"""
        SELECT date_trunc('{data.dimension}', issue_date) as period,
               SUM(amount_gross) as total_gross
        FROM invoices_replica
        WHERE issue_date BETWEEN ? AND ?
        GROUP BY period ORDER BY period;
        """
        results = manager.execute(query, (data.start_date, data.end_date))
        manager.close()

        try:
            if not results:
                return {"total_gross": 0.0, "count": 0, "avg_net": 0.0}
            row = results[0]
            return {
                "total_gross": row[0] or 0.0,
                "count": row[1] or 0,
                "avg_net": row[2] or 0.0
            }
        except Exception as e:
            # W logach systemowych warto by to zapisać
            return {"error": str(e), "total_gross": 0.0, "count": 0, "avg_net": 0.0}

    @get("/monthly-trend")
    async def get_monthly_trend(self, state: Any) -> list[dict[str, Any]]:
        """Opcjonalny endpoint pod wykresy (np. trend wydatków)."""
        manager: DuckDBManager = state.olap_manager
        query = """
        SELECT
            strftime(updated_at, '%Y-%m') as month,
            SUM(amount_gross) as total
        FROM invoices_replica
        GROUP BY 1
        ORDER BY 1 DESC
        """
        results = manager.execute(query)
        return [{"month": row[0], "total": row[1]} for row in results]
