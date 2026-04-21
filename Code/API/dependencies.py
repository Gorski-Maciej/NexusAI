from __future__ import annotations

from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession

from core.config import AppConfig
from db.database import create_oltp_engine, create_session_factory
from db.analytics import DuckDBLimits, DuckDBManager

_config = AppConfig()
_engine = create_oltp_engine(_config)
_session_factory = create_session_factory(_engine)
_duckdb_mgr = DuckDBManager(
    db_path=_config.duckdb_path,
    limits=DuckDBLimits(memory_limit=_config.duckdb_memory_limit, threads=_config.duckdb_threads),
)


def provide_config() -> AppConfig:
    return _config


async def provide_db_session() -> AsyncGenerator[AsyncSession, None]:
    async with _session_factory() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


async def provide_duckdb() -> DuckDBManager:
    return _duckdb_mgr
