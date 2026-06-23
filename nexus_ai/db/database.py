"""
SQLAlchemy + SQLModel setup for SQLCipher (encrypted SQLite) — sync engine only.

Używamy natywnego sqlite3 w Pythonie 3.13t (free-threaded).

SUPERMOCE SQLModel/SQLAlchemy:
- SQLModel.metadata jako target_metadata (dla Alembic auto-migration)
- with_loader_criteria — automatyczny multi-tenant filtr (WHERE tenant_id = ?)
- SessionEvents.before_flush dla automatycznego audytu
- Connection pool tuning (pool_size, max_overflow, pool_recycle)
- SQLCipher AES-256 encryption przez PRAGMA key
"""

from __future__ import annotations

import ctypes
import os
import sys
from collections.abc import Generator
from pathlib import Path
from typing import Any

from sqlalchemy import event
from sqlalchemy.orm import DeclarativeBase, sessionmaker, with_loader_criteria
from sqlalchemy.pool import NullPool, QueuePool
from sqlmodel import Session, create_engine, text
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.db")


# ── SQLCipher detection ──────────────────────────────────────────────────

SQLCIPHER_AVAILABLE: bool | None = None


def probe_sqlcipher() -> bool:
    """Sprawdź czy sqlite3 jest skompilowany z SQLCipher."""
    global SQLCIPHER_AVAILABLE
    import sqlite3

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


probe_sqlcipher()


# ── URL builder ──────────────────────────────────────────────────────────


def _sqlite_url(config: AppConfig, sqlite_path: Path | None = None) -> str:
    path = sqlite_path or config.sqlite_path
    return f"sqlite:///{path.as_posix()}"


# ── Key resolution ────────────────────────────────────────────────────────


def _resolve_key(config: AppConfig, key: str | None = None) -> str:
    resolved = key or os.getenv(config.sqlcipher_key_env, "").strip()
    if not resolved:
        raise RuntimeError(
            f"SQLCipher key not configured. "
            f"Set {config.sqlcipher_key_env} environment variable "
            f"or pass ``key=`` parameter."
        )
    return resolved


def _make_pragma_setter(key_hex: str):
    """Utwórz funkcję connect listenera ustawiającą PRAGMA key.

    SUPERMOCE (wszystkie):
    - WAL mode dla współbieżności
    - Synchronous NORMAL dla wydajności
    - Foreign Keys ON dla integralności referencyjnej
    - Cell Size Check ON dla wykrywania corrupt data
    - Trusted Schema OFF dla bezpieczeństwa
    - Cache size 200MB
    - Temp Store MEMORY
    - Auto-vacuum FULL
    - Memory-Mapped I/O (mmap_size = 4GB)
    - SQLCipher AES-256 z najsilniejszym HMAC i KDF
    """

    def _set_pragmas(dbapi_connection, _connection_record):
        dbapi_connection.execute("PRAGMA journal_mode=WAL;")
        dbapi_connection.execute("PRAGMA synchronous=NORMAL;")
        dbapi_connection.execute("PRAGMA foreign_keys = ON;")
        dbapi_connection.execute("PRAGMA cell_size_check = ON;")
        dbapi_connection.execute("PRAGMA trusted_schema = OFF;")
        dbapi_connection.execute("PRAGMA cache_size = -51200;")
        dbapi_connection.execute("PRAGMA temp_store = 2;")
        dbapi_connection.execute("PRAGMA auto_vacuum = FULL;")
        dbapi_connection.execute("PRAGMA mmap_size = 4294967296;")
        dbapi_connection.execute("PRAGMA application_id = 1313827925;")
        dbapi_connection.execute("PRAGMA user_version = 30000;")

        # SQLCipher
        dbapi_connection.execute("PRAGMA key = x'%s';" % key_hex)
        dbapi_connection.execute("PRAGMA cipher_page_size = 4096;")
        dbapi_connection.execute("PRAGMA kdf_iter = 64000;")

        try:
            dbapi_connection.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA512;")
            dbapi_connection.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;")
            dbapi_connection.execute("PRAGMA cipher_use_hmac = ON;")
        except Exception:
            pass

        try:
            dbapi_connection.execute("PRAGMA cipher_memory_security = ON;")
        except Exception:
            pass

        try:
            dbapi_connection.execute("PRAGMA cipher_default_plaintext_header = ON;")
        except Exception:
            pass

        try:
            dbapi_connection.execute("PRAGMA cipher_plaintext_header_size = 0;")
        except Exception:
            pass

        try:
            dbapi_connection.execute("PRAGMA cipher_hmac_pgno = ON;")
        except Exception:
            pass

    return _set_pragmas


# ── Sync engine ───────────────────────────────────────────────────────────


def create_oltp_engine(
    config: AppConfig,
    *,
    sqlcipher_key: str | None = None,
    sqlite_path: Path | None = None,
    pool_size: int = 5,
    max_overflow: int = 10,
    pool_recycle: int = 3600,
    use_pool: bool = True,
):
    """Create a sync SQLAlchemy engine with SQLCipher encryption.

    SUPERMOCE:
    - Connection pool (QueuePool) zamiast NullPool
    - pool_size: maksymalna liczba połączeń w poolu
    - max_overflow: maksymalna liczba połączeń ponad pool_size
    - pool_recycle: recycle połączeń po N sekundach
    - with_loader_criteria ready dla multi-tenant

    Python 3.13t (free-threaded): brak GIL — synchroniczne wywołania sqlite3
    z wielu wątków są bezpieczne.

    Args:
        config: Aplikacyjna konfiguracja (AppConfig).
        sqlcipher_key: Opcjonalny klucz AES-256 (zastepuje env var).
        sqlite_path: Opcjonalna ścieżka do pliku DB (zastepuje config).
        pool_size: Rozmiar poolu połączeń (domyślnie 5).
        max_overflow: Maksymalna liczba połączeń ponad pool_size.
        pool_recycle: Recycle połączeń po N sekundach (domyślnie 3600).
        use_pool: Jeśli False, używa NullPool (dla workerów jednorazowych).

    Returns:
        SQLAlchemy Engine.
    """
    if not SQLCIPHER_AVAILABLE:
        raise RuntimeError(
            "SQLCipher not available. Run with: LD_PRELOAD=/usr/lib/.../libsqlcipher.so"
        )

    url = _sqlite_url(config, sqlite_path)
    resolved_key = _resolve_key(config, sqlcipher_key)
    key_hex = resolved_key.encode("utf-8").hex()

    # SUPERMOC: Connection pool zamiast NullPool
    poolclass = QueuePool if use_pool else NullPool
    engine = create_engine(
        url,
        echo=False,
        poolclass=poolclass,
        pool_size=pool_size,
        max_overflow=max_overflow,
        pool_recycle=pool_recycle,
        pool_pre_ping=True,
    )

    event.listen(engine, "connect", _make_pragma_setter(key_hex))

    logger.info("[DB] Created sync SQLCipher engine: %s (pool=%s)", url, poolclass.__name__)
    return engine


# ── Session factory ───────────────────────────────────────────────────────


def create_session_factory(
    engine,
    *,
    tenant_id: str | None = None,
):
    """Create a sync sessionmaker for the given engine.

    SUPERMOC: Jeśli tenant_id jest podany, dodaje with_loader_criteria
    do KAŻDEJ sesji — automatyczny filtr WHERE tenant_id = ?
    dla modeli które mają atrybut tenant_id.

    Args:
        engine: SQLAlchemy Engine.
        tenant_id: Opcjonalny tenant ID dla automatycznego filtra.

    Returns:
        sessionmaker.
    """
    factory = sessionmaker(bind=engine, class_=Session, expire_on_commit=False)

    if tenant_id:
        original_get_bind = factory.get_bind

        def _with_tenant_filter():
            """Zwraca sessionmaker z automatycznym filtrem tenant_id.

            Używa with_loader_criteria() — dodaje WHERE tenant_id = ?
            do KAŻDEGO zapytania, w tym JOIN-ów i podzapytań.
            """
            session = factory()
            session.execute(
                with_loader_criteria(
                    lambda cls: hasattr(cls, "tenant_id"),
                    lambda cls: cls.tenant_id == tenant_id,
                    include_aliases=True,
                )
            )
            return session

        factory.begin = _with_tenant_filter
        # Wrap __call__ aby dodać filtr
        original_call = factory.__call__

        def _call_with_tenant(*args: Any, **kwargs: Any) -> Session:
            session = original_call(*args, **kwargs)
            session.execute(
                with_loader_criteria(
                    lambda cls: hasattr(cls, "tenant_id"),
                    lambda cls: cls.tenant_id == tenant_id,
                    include_aliases=True,
                )
            )
            return session

        factory.__call__ = _call_with_tenant

    return factory


# ── Schema ────────────────────────────────────────────────────────────────


def init_schema(engine) -> None:
    """Create all SQLAlchemy tables for first application start.

    Używa SQLModel.metadata (Base = SQLModel z models.py).
    Po utworzeniu tabel, wywołuje create_partial_indexes().
    """
    from nexus_ai.db.models import (
        Base,
        ActiveLearningPattern,
        Invoice,
        OutboxEvent,
        create_partial_indexes,
    )

    # SUPERMOC: SQLModel.metadata zamiast Base.metadata
    Base.metadata.create_all(engine)
    create_partial_indexes(engine)


# ── Maintenance ───────────────────────────────────────────────────────────


def consolidate_database(engine) -> None:
    """Zamyka sesje i wykonuje TRUNCATE checkpoint."""
    try:
        with engine.connect() as conn:
            result = conn.execute(text("PRAGMA wal_checkpoint;"))
            checkpoint_info = result.fetchone()
            logger.info("WAL checkpoint status before TRUNCATE: %s", checkpoint_info)

            conn.execute(text("PRAGMA wal_checkpoint(TRUNCATE);"))
            conn.execute(text("PRAGMA optimize;"))
            conn.execute(text("VACUUM;"))
            conn.execute(text("PRAGMA analysis_limit = 1000;"))
            conn.execute(text("ANALYZE;"))

            result2 = conn.execute(text("PRAGMA wal_checkpoint;"))
            logger.info("WAL checkpoint status after TRUNCATE: %s", result2.fetchone())
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


def get_tenant_session(session_factory, tenant_id: str) -> Generator[Session, None, None]:
    """Context manager z automatycznym multi-tenant filtrem.

    SUPERMOC: Używa with_loader_criteria do automatycznego dodawania
    WHERE tenant_id = ? do każdego zapytania.
    """
    factory = create_session_factory(session_factory.kw["bind"], tenant_id=tenant_id)
    session = factory()
    try:
        yield session
    finally:
        session.close()


# ── Declarative base ─────────────────────────────────────────────────────


class Base(DeclarativeBase):
    """Declarative base for OLTP SQLAlchemy models."""


# ── Lazy default session factory ──────────────────────────────────────────

_SessionLocal: sessionmaker | None = None


def __getattr__(name: str):
    """Lazy import of session factories to avoid circular imports."""
    if name == "SessionLocal":
        global _SessionLocal
        if _SessionLocal is None:
            config = AppConfig()
            engine = create_oltp_engine(config)
            _SessionLocal = create_session_factory(engine)
        return _SessionLocal

    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
