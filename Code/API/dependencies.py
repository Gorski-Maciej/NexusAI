from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession
from db.database import create_oltp_engine, create_session_factory
from db.analytics import DuckDBManager
from core.config import AppConfig

# Singletony inicjalizowane przy starcie
_config = AppConfig()
_engine = create_oltp_engine(_config)
_session_factory = create_session_factory(_engine)
_duckdb_mgr = DuckDBManager(_config)

async def provide_db_session() -> AsyncGenerator[AsyncSession, None]:
    """Dostarcza asynchroniczną sesję SQLite (OLTP) dla każdego requestu."""
    async with _session_factory() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise

async def provide_duckdb() -> DuckDBManager:
    """Dostarcza managera DuckDB (OLAP) do zapytań analitycznych."""
    return _duckdb_mgr
