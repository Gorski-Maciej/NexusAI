from __future__ import annotations

from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession

from core.config import AppConfig
from core.tenant import TenantManager
from db.analytics import DuckDBLimits, DuckDBManager
from db.database import create_oltp_engine, create_session_factory

_config = AppConfig()
_tenant_manager = TenantManager(_config)
_duckdb_limits = DuckDBLimits(memory_limit=_config.duckdb_memory_limit, threads=_config.duckdb_threads)


def provide_config() -> AppConfig:
    return _config


def provide_tenant_manager() -> TenantManager:
    return _tenant_manager


async def provide_db_session() -> AsyncGenerator[AsyncSession, None]:
    engine = create_oltp_engine(_config, sqlite_path=_tenant_manager.sqlite_path())
    session_factory = create_session_factory(engine)

    async with session_factory() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await engine.dispose()


async def provide_duckdb() -> DuckDBManager:
    return DuckDBManager(db_path=_tenant_manager.duckdb_path(), limits=_duckdb_limits)
