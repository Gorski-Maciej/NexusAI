from litestar import Controller, get
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from db.analytics import DuckDBManager

class HealthController(Controller):
    """Zapasowy punkt diagnostyczny dla Watchdoga i Load Balancerów."""
    path = "/api/v1/health"

    @get("/")
    async def check_health(self, db_session: AsyncSession, duckdb: DuckDBManager) -> dict:
        status = {"api": "OK", "sqlite": "FAIL", "duckdb": "FAIL", "nats": "FAIL"}

        # 1. Test SQLite (OLTP)
        try:
            await db_session.execute(text("SELECT 1"))
            status["sqlite"] = "OK"
        except Exception:
            pass

        # 2. Test DuckDB (OLAP)
        try:
            duckdb.execute("SELECT 1")
            status["duckdb"] = "OK"
        except Exception:
            pass

        return status
