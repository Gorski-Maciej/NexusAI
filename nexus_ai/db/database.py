"""SQLAlchemy setup for SQLCipher (encrypted SQLite) + aiosqlite (async).

Zgodnie z aa3fvcx.txt:
- SQLCipher: szyfrowanie AES-256 bazy danych w spoczynku (at-rest encryption).
  Wymaga ``LD_PRELOAD`` z ``libsqlcipher.so`` przed uruchomieniem interpretera
  (patrz ``probe_sqlcipher()`` w tym module).
- aiosqlite: async dostęp do SQLite przez ``create_async_engine``.
  Python 3.13t (free-threaded): brak GIL — zarówno sync jak i async API
  są bezpieczne z wielu wątków jednocześnie.

Usage:
    # Sync (np. background workers):
    engine = create_oltp_engine(config)
    session = sessionmaker(bind=engine)

    # Async (np. Litestar endpoints):
    engine = create_async_oltp_engine(config)
    session = async_sessionmaker(bind=engine)

    # Uruchomienie z SQLCipher:
    LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libsqlcipher.so \\
        NEXUS_SQLCIPHER_KEY=my-secret-key \\
        python -m nexus_ai.api.app
"""

from __future__ import annotations

import ctypes
import os
import sys
from collections.abc import AsyncGenerator, Generator
from pathlib import Path

from sqlalchemy import create_engine, event, text
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.db")


# ── SQLCipher detection ──────────────────────────────────────────────────

SQLCIPHER_AVAILABLE: bool | None = None
"""Czy sqlite3 ma wsparcie SQLCipher (PRAGMA cipher_version działa)."""


def probe_sqlcipher() -> bool:
    """Sprawdź czy sqlite3 jest skompilowany z SQLCipher.

    Strategia:
    1. Bezpośrednie ``PRAGMA cipher_version`` na ``:memory:``.
    2. Jeśli nie działa, próbuje załadować ``libsqlcipher.so`` przez ``ctypes.CDLL``
       z flagą ``RTLD_GLOBAL`` (działa na systemach Linux gdzie biblioteka jest
       dostępna ale nie jest domyślnym sqlite3).

    Returns:
        ``True`` jeśli SQLCipher jest dostępny.
    """
    global SQLCIPHER_AVAILABLE

    import sqlite3

    # 1. Bezpośredni test
    try:
        conn = sqlite3.connect(":memory:")
        cur = conn.cursor()
        cur.execute("PRAGMA cipher_version")
        row = cur.fetchone()
        conn.close()
        if row is not None:
            ver = row[0]
            logger.info("[DB] SQLCipher detected: %s", ver)
            SQLCIPHER_AVAILABLE = True
            return True
    except Exception:
        pass

    # 2. Próba preloadu przez ctypes (Linux)
    if sys.platform == "linux":
        for lib_name in ["libsqlcipher.so", "libsqlcipher.so.1"]:
            try:
                ctypes.CDLL(lib_name, mode=ctypes.RTLD_GLOBAL)
                conn = sqlite3.connect(":memory:")
                cur = conn.cursor()
                cur.execute("PRAGMA cipher_version")
                row = cur.fetchone()
                conn.close()
                if row is not None:
                    ver = row[0]
                    logger.info("[DB] SQLCipher loaded via ctypes: %s", ver)
                    SQLCIPHER_AVAILABLE = True
                    return True
            except Exception:
                continue

    SQLCIPHER_AVAILABLE = False
    logger.warning(
        "[DB] SQLCipher NOT available — database will be unencrypted! "
        "Set LD_PRELOAD=/usr/lib/.../libsqlcipher.so or install libsqlcipher."
    )
    return False


# Uruchom probe przy imporcie modułu — loguje ostrzeżenie jeśli SQLCipher niedostępny
probe_sqlcipher()


# ── URL builders ──────────────────────────────────────────────────────────


def _sqlite_url(config: AppConfig, sqlite_path: Path | None = None) -> str:
    """Build sync SQLite URL from configuration."""
    path = sqlite_path or config.sqlite_path
    return f"sqlite:///{path.as_posix()}"


def _async_sqlite_url(config: AppConfig, sqlite_path: Path | None = None) -> str:
    """Build async SQLite URL (aiosqlite) from configuration."""
    path = sqlite_path or config.sqlite_path
    return f"sqlite+aiosqlite:///{path.as_posix()}"


# ── Key resolution ────────────────────────────────────────────────────────


def _resolve_key(config: AppConfig, key: str | None = None) -> str:
    """Resolve SQLCipher encryption key.

    Kolejność: argument ``key`` > env var ``NEXUS_SQLCIPHER_KEY`` > błąd.

    Raises:
        RuntimeError: jeśli klucz nie jest skonfigurowany.
    """
    resolved = key or os.getenv(config.sqlcipher_key_env, "").strip()
    if not resolved:
        raise RuntimeError(
            f"SQLCipher key not configured. "
            f"Set {config.sqlcipher_key_env} environment variable "
            f"or pass ``key=`` parameter."
        )
    return resolved


def _make_pragma_setter(key_hex: str):
    """Utwórz funkcję ``connect`` listenera ustawiającą PRAGMA key.

    Używa ``dbapi_connection.execute()`` zamiast ``cursor.execute()`` dla
    kompatybilności z aiosqlite (gdzie cursor wymaga ``await``, ale
    ``connection.execute()`` ma synchroniczny interfejs w SQLAlchemy).

    Args:
        key_hex: Klucz szyfrowania w formacie hex.
    """

    def _set_pragmas(dbapi_connection, _connection_record):
        dbapi_connection.execute("PRAGMA cache_size = -20000;")
        dbapi_connection.execute("PRAGMA temp_store = 2;")
        dbapi_connection.execute("PRAGMA auto_vacuum = FULL;")
        dbapi_connection.execute("PRAGMA key = x'%s';" % key_hex)
        dbapi_connection.execute("PRAGMA cipher_page_size = 4096;")
        dbapi_connection.execute("PRAGMA kdf_iter = 64000;")

    return _set_pragmas


# ── Sync engine ───────────────────────────────────────────────────────────


def create_oltp_engine(
    config: AppConfig,
    *,
    sqlcipher_key: str | None = None,
    sqlite_path: Path | None = None,
):
    """Create a sync SQLAlchemy engine with SQLCipher encryption.

    Ustawia PRAGMA key na każdym nowym połączeniu (SQLCipher).
    Klucz jest wymagany — jeśli nie jest skonfigurowany, rzuca ``RuntimeError``.

    Python 3.13t (free-threaded): brak GIL — synchroniczne wywołania sqlite3
    z wielu wątków są bezpieczne bez dodatkowej warstwy async.

    Args:
        config: Aplikacyjna konfiguracja (AppConfig).
        sqlcipher_key: Opcjonalny klucz AES-256 (zastepuje env var).
        sqlite_path: Opcjonalna ścieżka do pliku DB (zastepuje config).

    Raises:
        RuntimeError: Jeśli SQLCipher nie jest dostępny (brak LD_PRELOAD).

    Returns:
        SQLAlchemy Engine.
    """
    if not SQLCIPHER_AVAILABLE:
        raise RuntimeError(
            "SQLCipher not available. Run with: "
            "LD_PRELOAD=/usr/lib/.../libsqlcipher.so"
        )

    url = _sqlite_url(config, sqlite_path)
    resolved_key = _resolve_key(config, sqlcipher_key)
    key_hex = resolved_key.encode("utf-8").hex()

    engine = create_engine(url, echo=False)

    event.listen(engine, "connect", _make_pragma_setter(key_hex))

    logger.info("[DB] Created sync SQLCipher engine: %s", url)
    return engine


# ── Async engine (aiosqlite) ──────────────────────────────────────────────


def create_async_oltp_engine(
    config: AppConfig,
    *,
    sqlcipher_key: str | None = None,
    sqlite_path: Path | None = None,
):
    """Create an async SQLAlchemy engine using aiosqlite + SQLCipher.

    Używa ``create_async_engine("sqlite+aiosqlite:///...")`` i ustawia
    PRAGMA key na każdym nowym połączeniu przez ``engine.sync_engine``.

    Args:
        config: Aplikacyjna konfiguracja (AppConfig).
        sqlcipher_key: Opcjonalny klucz AES-256 (zastepuje env var).
        sqlite_path: Opcjonalna ścieżka do pliku DB (zastepuje config).

    Raises:
        RuntimeError: Jeśli SQLCipher nie jest dostępny (brak LD_PRELOAD).

    Returns:
        SQLAlchemy AsyncEngine.
    """
    if not SQLCIPHER_AVAILABLE:
        raise RuntimeError(
            "SQLCipher not available. Run with: "
            "LD_PRELOAD=/usr/lib/.../libsqlcipher.so"
        )

    url = _async_sqlite_url(config, sqlite_path)
    resolved_key = _resolve_key(config, sqlcipher_key)
    key_hex = resolved_key.encode("utf-8").hex()

    engine = create_async_engine(url, echo=False)

    # aiosqlite: PRAGMA key ustawiamy przez sync_engine.connect
    # SQLAlchemy zarządza async→sync bridging pod spodem.
    # Używamy dbapi_connection.execute() zamiast cursor.execute()
    # dla kompatybilności z aiosqlite.
    event.listen(engine.sync_engine, "connect", _make_pragma_setter(key_hex))

    logger.info("[DB] Created async aiosqlite engine: %s", url)
    return engine


# ── Session factories ─────────────────────────────────────────────────────


def create_session_factory(engine):
    """Create a sync ``sessionmaker`` for the given engine."""
    return sessionmaker(bind=engine, class_=Session, expire_on_commit=False)


def create_async_session_factory(engine):
    """Create an async ``async_sessionmaker`` for the given engine."""
    return async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)


# ── Schema ────────────────────────────────────────────────────────────────


def init_schema(engine) -> None:
    """Create all SQLAlchemy tables for first application start."""
    from nexus_ai.db.models import (  # noqa: F401
        ActiveLearningPattern,
        Invoice,
        OutboxEvent,
    )

    Base.metadata.create_all(engine)


# ── Maintenance ───────────────────────────────────────────────────────────


def consolidate_database(engine) -> None:
    """Zamyka sesje i wykonuje TRUNCATE checkpoint.

    Usuwa pliki WAL i przenosi dane do głównego pliku .sqlite.
    Powinno być wywołane w pętli zamykającej aplikację (main.py).
    """
    try:
        with engine.connect() as conn:
            result = conn.execute(text("PRAGMA wal_checkpoint;"))
            checkpoint_info = result.fetchone()
            logger.info("WAL checkpoint status before TRUNCATE: %s", checkpoint_info)

            conn.execute(text("PRAGMA wal_checkpoint(TRUNCATE);"))
            conn.execute(text("VACUUM;"))

            result2 = conn.execute(text("PRAGMA wal_checkpoint;"))
            logger.info(
                "WAL checkpoint status after TRUNCATE: %s", result2.fetchone()
            )
    except Exception as e:
        logger.error("Failed to consolidate database: %s", e)


# ── Session helpers ───────────────────────────────────────────────────────


def get_session(session_factory) -> Generator[Session, None, None]:
    """Context manager yielding a sync Session from the given factory."""
    session = session_factory()
    try:
        yield session
    finally:
        session.close()


async def get_async_session(
    session_factory,
) -> AsyncGenerator[AsyncSession, None]:
    """Context manager yielding an async AsyncSession from the given factory."""
    async with session_factory() as session:
        yield session


# ── Declarative base ─────────────────────────────────────────────────────


class Base(DeclarativeBase):
    """Declarative base for OLTP SQLAlchemy models."""
    pass


# ── Lazy default session factories ────────────────────────────────────────

_SessionLocal: sessionmaker | None = None
_AsyncSessionLocal: async_sessionmaker | None = None


def __getattr__(name: str):
    """Lazy import of session factories to avoid circular imports."""
    if name == "SessionLocal":
        global _SessionLocal
        if _SessionLocal is None:
            config = AppConfig()
            engine = create_oltp_engine(config)
            _SessionLocal = create_session_factory(engine)
        return _SessionLocal

    if name == "AsyncSessionLocal":
        global _AsyncSessionLocal
        if _AsyncSessionLocal is None:
            config = AppConfig()
            engine = create_async_oltp_engine(config)
            _AsyncSessionLocal = create_async_session_factory(engine)
        return _AsyncSessionLocal

    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
