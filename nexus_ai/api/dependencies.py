from __future__ import annotations

from collections.abc import Generator
from functools import lru_cache

from litestar.connection import Request
from sqlalchemy.ext.asyncio import AsyncEngine
from sqlalchemy.orm import Session

from nexus_ai.api.shared_image_buffer import SharedImageBuffer
from nexus_ai.core.config import AppConfig
from nexus_ai.core.tenant import TenantManager
from nexus_ai.db.analytics import DuckDBLimits, DuckDBManager


@lru_cache(maxsize=1)
def _get_config() -> AppConfig:
    """Lazy-loaded singleton — pierwsze wywołanie ładuje z TOML."""
    return AppConfig.from_toml()


@lru_cache(maxsize=1)
def _get_tenant_manager() -> TenantManager:
    """Lazy-loaded singleton — zależny od config."""
    return TenantManager(_get_config())


@lru_cache(maxsize=1)
def _get_duckdb_limits() -> DuckDBLimits:
    """Lazy-loaded singleton — zależny od config."""
    config = _get_config()
    return DuckDBLimits(memory_limit=config.duckdb_memory_limit, threads=config.duckdb_threads)


def provide_config() -> AppConfig:
    return _get_config()


def provide_tenant_manager() -> TenantManager:
    return _get_tenant_manager()


def provide_db_session(request: Request) -> Generator[Session, None, None]:
    session_factory = request.app.state.db_session_factory

    with session_factory() as session:
        with session.begin():
            yield session


def provide_db_engine(request: Request) -> AsyncEngine:
    """Provide the async SQLAlchemy engine from application state.

    Umożliwia kontrolerom wstrzykiwanie ``db_engine`` przez DI
    zamiast bezpośredniego ``request.app.state.db_engine``.
    """
    return request.app.state.db_engine


def provide_duckdb() -> DuckDBManager:
    tm = _get_tenant_manager()
    return DuckDBManager(
        db_path=tm.duckdb_path(),
        limits=_get_duckdb_limits(),
        read_only=True,
        sqlite_path=tm.sqlite_path(),
    )


def provide_shared_image_buffer(request: Request) -> SharedImageBuffer:
    return request.app.state.shared_image_buffer
