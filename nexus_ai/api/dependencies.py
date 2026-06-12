from __future__ import annotations

from collections.abc import Generator

from litestar.connection import Request
from sqlalchemy.orm import Session

from nexus_ai.api.shared_image_buffer import SharedImageBuffer
from nexus_ai.core.config import AppConfig
from nexus_ai.core.tenant import TenantManager
from nexus_ai.db.analytics import DuckDBLimits, DuckDBManager

_config = AppConfig.from_toml()
_tenant_manager = TenantManager(_config)
_duckdb_limits = DuckDBLimits(memory_limit=_config.duckdb_memory_limit, threads=_config.duckdb_threads)


def provide_config() -> AppConfig:
    return _config


def provide_tenant_manager() -> TenantManager:
    return _tenant_manager


def provide_db_session(request: Request) -> Generator[Session, None, None]:
    session_factory = request.app.state.db_session_factory

    with session_factory() as session:
        with session.begin():
            yield session


def provide_duckdb() -> DuckDBManager:
    return DuckDBManager(
        db_path=_tenant_manager.duckdb_path(),
        limits=_duckdb_limits,
        read_only=True,
        sqlite_path=_tenant_manager.sqlite_path(),
    )


def provide_shared_image_buffer(request: Request) -> SharedImageBuffer:
    return request.app.state.shared_image_buffer
