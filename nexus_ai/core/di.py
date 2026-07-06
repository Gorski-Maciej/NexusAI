"""core/di -- Centralny DI container (TaskiqDepends + AppServices) dla NexusAI."""

from __future__ import annotations

import importlib
import os
import warnings
from collections.abc import AsyncGenerator
from dataclasses import dataclass, field
from collections.abc import Callable
from typing import Any, Protocol, cast

from sqlalchemy.engine import Engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import Session
from structlog import get_logger

from nexus_ai.core.broker import broker
from nexus_ai.core.config import AppConfig
from nexus_ai.core.decision_engine import DecisionEngine
from nexus_ai.core.inference import ModelManager
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.database import create_oltp_engine, create_session_factory
from nexus_ai.events import EventStore, JetStreamEventBus

logger = get_logger("nexus.core.di")


# ── Protocol for lazy-loaded modules ──────────────────────────────────────
class _SupportsGetAttr(Protocol):
    def __getattr__(self, name: str) -> object: ...


class _TaskiqBroker(Protocol):
    def task(self, *args: Any, **kwargs: Any) -> Any: ...


# ── Thread-local engine cache dla free-threaded Python 3.13t ──────────────
_ENGINE_CACHE: dict[str, Engine] = {}
_SESSION_FACTORY_CACHE: dict[str, sessionmaker] = {}


def _get_or_create_engine(config: AppConfig | None = None) -> Engine:
    """Zwróć lub utwórz silnik bazy danych (cache'owany).

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
# TaskiqDepends -- zależności dla zadań
# =========================================================================


async def get_config() -> AppConfig:
    """Zwraca konfigurację aplikacji (singleton).

    """
    return AppConfig()


async def get_engine(config: AppConfig | None = None) -> Engine:
    """Zwraca silnik bazy danych (cache'owany przez _get_or_create_engine).

    Nie ma create/dispose przy każdym tasku.
    """
    return _get_or_create_engine(config)


async def get_db_session(engine: Engine | None = None) -> AsyncGenerator[Session]:
    """Zwraca sesję bazy danych (scoped per task).

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


async def get_duckdb_manager(config: AppConfig | None = None) -> AsyncGenerator[object]:
    """Zwraca DuckDBManager (scoped per task).

    Usage:
        @broker.task(task_name="analytics_task")
        async def analytics_task(
            duckdb: DuckDBManager = TaskiqDepends(get_duckdb_manager),
        ):
            ...
    """
    if config is None:
        config = AppConfig()
    manager = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    try:
        yield manager
    finally:
        manager.close()


# =========================================================================
# Helper -- czyszczenie cache engine przy shutdown
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


# =========================================================================
# AppServices -- centralny DI container dla Litestar
# =========================================================================

class LazyImport:
    """Lazy import z opóźnionym ładowaniem i poprawnymi typami."""
    __slots__ = ("_module", "_name", "_mod")

    def __init__(self, module: str, name: str | None = None) -> None:
        self._module = module
        self._name = name
        self._mod: _SupportsGetAttr | None = None

    def __getattr__(self, attr: str) -> object:
        if self._mod is None:
            self._mod = cast(_SupportsGetAttr, importlib.import_module(self._module))
        if self._name:
            return getattr(importlib.import_module(self._module), self._name)
        return getattr(self._mod, attr)

    def __call__(self, *args: object, **kwargs: object) -> object:
        mod = importlib.import_module(self._module)
        if self._name:
            return cast(Callable[..., object], getattr(mod, self._name))(*args, **kwargs)
        return cast(Callable[..., object], mod)(*args, **kwargs)


@dataclass
class AppServices:
    """Centralny rejestr serwisów dla NexusaAI."""
    __slots__ = ()
    config: AppConfig = field(default_factory=AppConfig)
    engine: Engine | None = None
    session_factory: sessionmaker[Session] | None = None
    _services: dict[str, object] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if self.engine is None:
            self.engine = create_oltp_engine(self.config)
        if self.session_factory is None:
            self.session_factory = create_session_factory(self.engine)

    def get(self, name: str) -> object:
        if name not in self._services:
            self._services[name] = self._create(name)
        return self._services[name]

    def _create(self, name: str) -> object:
        match name:
            case "decision_engine":
                return DecisionEngine(self.config)
            case "duckdb_manager":
                return DuckDBManager(db_path=self.config.duckdb_path, sqlite_path=self.config.sqlite_path)
            case "event_store":
                return EventStore(sqlite_path=self.config.sqlite_path)
            case "jetstream_bus":
                return JetStreamEventBus(nats_servers=self.config.nats_url)
            case "model_manager":
                return ModelManager(config=self.config)
            case "broker":
                return broker
            case _:
                raise KeyError(f"Unknown service: {name}")

    @property
    def decision_engine(self) -> object:
        return self.get("decision_engine")

    @property
    def duckdb_manager(self) -> object:
        return self.get("duckdb_manager")

    @property
    def event_store(self) -> object:
        return self.get("event_store")

    @property
    def jetstream_bus(self) -> object:
        return self.get("jetstream_bus")

    @property
    def model_manager(self) -> object:
        return self.get("model_manager")

    @property
    def broker(self) -> _TaskiqBroker:
        return cast(_TaskiqBroker, self.get("broker"))


def create_app_services(config: AppConfig | None = None) -> AppServices:
    cfg = config or AppConfig()
    return AppServices(config=cfg)


_default_services: AppServices | None = None


def get_services() -> AppServices:
    warnings.warn("get_services() is deprecated. Use create_app_services() with DI injection instead.", DeprecationWarning, stacklevel=2)
    global _default_services
    if _default_services is None:
        _default_services = create_app_services()
    return _default_services
