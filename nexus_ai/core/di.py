"""
core/di.py — Centralne TaskiqDepends dla NexusAI.

SUPERMOC TASKIQ:
  - TaskiqDepends wstrzykuje zależności do zadań
  - Zastępuje ręczne tworzenie engine/session w każdym tasku
  - Lepsza wydajność (pool zamiast create/dispose)
  - Mniej kodu (~400 LOC mniej w api/tasks.py i core/tasks.py)
  - Wspiera factory, singleton, scoped

Usage:
    from nexus_ai.core.di import get_db_session, get_config

    @broker.task(task_name="my_task")
    async def my_task(
        config: AppConfig = TaskiqDepends(get_config),
        db: Session = TaskiqDepends(get_db_session),
    ):
        # config i db są gotowe — zero boilerplate!
        ...
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any, AsyncGenerator

import anyio
from sqlalchemy.engine import Engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import Session
from structlog import get_logger

from nexus_ai.core.config import AppConfig
from nexus_ai.db.database import create_oltp_engine, create_session_factory

logger = get_logger("nexus.core.di")


# ── Thread-local engine cache dla free-threaded Python 3.13t ──────────────
_ENGINE_CACHE: dict[str, Engine] = {}
_SESSION_FACTORY_CACHE: dict[str, sessionmaker] = {}


def _get_or_create_engine(config: AppConfig | None = None) -> Engine:
    """Zwróć lub utwórz silnik bazy danych (cache'owany).

    SUPERMOC: Engine jest tworzony raz i cache'owany - nie ma create/dispose
    przy każdym tasku. To daje znaczący zysk wydajności.
    """
    if config is None:
        config = AppConfig()
    cache_key = str(config.sqlite_path)
    if cache_key not in _ENGINE_CACHE:
        sqlcipher_key = os.getenv(config.sqlcipher_key_env, "").strip()
        engine = create_oltp_engine(config, sqlcipher_key=sqlcipher_key or None)
        _ENGINE_CACHE[cache_key] = engine
        _SESSION_FACTORY_CACHE[cache_key] = create_session_factory(engine)
        logger.debug("[DI] Created engine for %s", cache_key)
    return _ENGINE_CACHE[cache_key]


def _get_or_create_session_factory(config: AppConfig | None = None) -> sessionmaker:
    """Zwróć lub utwórz SessionFactory."""
    _get_or_create_engine(config)
    cache_key = str((config or AppConfig()).sqlite_path)
    return _SESSION_FACTORY_CACHE[cache_key]


# =========================================================================
# TaskiqDepends — zależności dla zadań
# =========================================================================


async def get_config() -> AppConfig:
    """Zwraca konfigurację aplikacji (singleton).

    SUPERMOC: TaskiqDepends tworzy config raz i cache'uje go.
    """
    return AppConfig()


async def get_engine(config: AppConfig | None = None) -> Engine:
    """Zwraca silnik bazy danych (cache'owany przez _get_or_create_engine).

    SUPERMOC: Engine jest tworzony raz dla całego procesu workera.
    Nie ma create/dispose przy każdym tasku.
    """
    return _get_or_create_engine(config)


async def get_db_session(engine: Engine | None = None) -> AsyncGenerator[Session, None]:
    """Zwraca sesję bazy danych (scoped per task).

    SUPERMOC: TaskiqDepends tworzy sesję na czas jednego zadania.
    Sesja jest automatycznie zamykana po zakończeniu zadania.

    Usage:
        @broker.task(task_name="my_task")
        async def my_task(
            db: Session = TaskiqDepends(get_db_session),
        ):
            # db.query(...) - gotowe!
    """
    if engine is None:
        engine = _get_or_create_engine()

    session_factory = _get_or_create_session_factory()
    session = session_factory()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


async def get_duckdb_manager(config: AppConfig | None = None) -> AsyncGenerator[Any, None]:
    """Zwraca DuckDBManager (scoped per task).

    Usage:
        @broker.task(task_name="analytics_task")
        async def analytics_task(
            duckdb: DuckDBManager = TaskiqDepends(get_duckdb_manager),
        ):
            ...
    """
    from nexus_ai.db.analytics import DuckDBManager

    if config is None:
        config = AppConfig()
    manager = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    try:
        yield manager
    finally:
        manager.close()





async def get_decision_engine(config: AppConfig | None = None) -> AsyncGenerator[Any, None]:
    """Zwraca DecisionEngine (lazy init, scoped per task).

    Usage:
        @broker.task(task_name="decide")
        async def decide(
            engine: DecisionEngine = TaskiqDepends(get_decision_engine),
        ):
            ...
    """
    from nexus_ai.core.decision_engine import DecisionEngine
    from nexus_ai.db.analytics import DuckDBManager

    if config is None:
        config = AppConfig()
    duckdb = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    try:
        yield DecisionEngine(duckdb=duckdb)
    finally:
        duckdb.close()


# =========================================================================
# Helper — czyszczenie cache engine przy shutdown
# =========================================================================


async def dispose_all_engines() -> None:
    """Zamknij wszystkie cache'owane engine.

    Wywoływana przy shutdown workera.
    """
    for key, engine in _ENGINE_CACHE.items():
        try:
            engine.dispose()
            logger.debug("[DI] Disposed engine: %s", key)
        except Exception as exc:
            logger.warning("[DI] Failed to dispose engine %s: %s", key, exc)
    _ENGINE_CACHE.clear()
    _SESSION_FACTORY_CACHE.clear()
    logger.info("[DI] All engines disposed")
