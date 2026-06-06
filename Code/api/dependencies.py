from __future__ import annotations

from collections.abc import AsyncGenerator

from litestar.connection import Request
from sqlalchemy.ext.asyncio import AsyncSession

from api.shared_image_buffer import SharedImageBuffer
from core.config import AppConfig
from core.tenant import TenantManager
from db.analytics import DuckDBLimits, DuckDBManager

_config = AppConfig()
_tenant_manager = TenantManager(_config)
_duckdb_limits = DuckDBLimits(memory_limit=_config.duckdb_memory_limit, threads=_config.duckdb_threads)


def provide_config() -> AppConfig:
    return _config


def provide_tenant_manager() -> TenantManager:
    return _tenant_manager


async def provide_db_session(request: Request) -> AsyncGenerator[AsyncSession]:
    session_factory = request.app.state.db_session_factory

    async with session_factory() as session:
        # Transakcja jest automatycznie zatwierdzana po wyjściu z bloku begin(),
        # a przy wyjątku automatycznie wycofywana (rollback).
        async with session.begin():
            yield session


async def provide_duckdb() -> DuckDBManager:
    return DuckDBManager(
        db_path=_tenant_manager.duckdb_path(),
        limits=_duckdb_limits,
        read_only=True,
        sqlite_path=_tenant_manager.sqlite_path(),
    )


def provide_shared_image_buffer(request: Request) -> SharedImageBuffer:
    return request.app.state.shared_image_buffer
