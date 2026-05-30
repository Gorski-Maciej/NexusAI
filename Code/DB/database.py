"""Async SQLAlchemy setup for SQLite/SQLCipher (OLTP)."""

from __future__ import annotations

import os
import logging
from pathlib import Path
from collections.abc import AsyncGenerator

from sqlalchemy import event, text, create_engine
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from core.config import AppConfig

logger = logging.getLogger("nexus.db.cleanup")

class Base(DeclarativeBase):
    """Declarative base for OLTP SQLAlchemy models."""
    pass

def _sqlite_url(config: AppConfig, sqlite_path: Path | None = None) -> str:
    """Build async SQLite URL from configuration."""
    path = sqlite_path or config.sqlite_path
    return f"sqlite+aiosqlite:///{path.as_posix()}"

def create_oltp_engine(
    config: AppConfig,
    *,
    sqlcipher_key: str | None = None,
    sqlite_path: Path | None = None,
) -> AsyncEngine:
    """
    Create an async SQLAlchemy engine with mandatory PRAGMA settings.
    The same hook can bootstrap SQLCipher key when provided either directly
    or via `NEXUS_SQLCIPHER_KEY` environment variable.

    Rozwiązanie 18: Jeśli sqlcipher_key jest podany (lub NEXUS_SQLCIPHER_KEY env),
    użyj SQLCipher do szyfrowania bazy danych w spoczynku (at-rest encryption).
    """
    url = _sqlite_url(config, sqlite_path)

    # Sprawdź, czy klucz SQLCipher jest skonfigurowany
    resolved_key = sqlcipher_key or os.getenv(config.sqlcipher_key_env, "").strip()

    engine = create_async_engine(
        url,
        echo=False,
    )

    @event.listens_for(engine.sync_engine, "connect")
    def _set_sqlite_pragmas(dbapi_connection, _connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA cache_size = -20000;")
        cursor.execute("PRAGMA temp_store = 2;")
        cursor.execute("PRAGMA auto_vacuum = FULL;")

        # Jeśli klucz SQLCipher jest dostępny, włącz szyfrowanie (Rozwiązanie 18)
        if resolved_key:
            try:
                # Użyj hex-encoded klucza zamiast f-string, aby uniknąć SQL injection (Rozwiązanie 20)
                # Konwertuj klucz na hex, co jest bezpieczne dla PRAGMA
                key_hex = resolved_key.encode("utf-8").hex()
                cursor.execute(f"PRAGMA key = \"x'{key_hex}'\";")
                # Wymuś szyfrowanie dla nowych baz
                cursor.execute("PRAGMA cipher_page_size = 4096;")
                cursor.execute("PRAGMA kdf_iter = 64000;")
                logger.info("[DB] SQLCipher encryption enabled for database")
            except Exception as e:
                logger.warning("[DB] Failed to enable SQLCipher: %s", e)
        cursor.close()
    return engine

def create_session_factory(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)

async def init_schema(engine: AsyncEngine) -> None:
    """Create all SQLAlchemy tables for first application start."""
    from models.outbox import OutboxEvent # noqa: F401
    from models.invoice import ActiveLearningPattern, Invoice # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

async def consolidate_database(engine: AsyncEngine) -> None:
    """
    Zamyka sesje i wykonuje TRUNCATE checkpoint.
    Usuwa pliki WAL i przenosi dane do głównego pliku .sqlite.
    Powinno być wywołane w pętli zamykającej aplikację (main.py).
    """
    try:
        # Najpierw sprawdzamy, czy są aktywne połączenia
        async with engine.connect() as conn:
            # Sprawdź stan WAL przed checkpointem
            result = await conn.execute(text("PRAGMA wal_checkpoint;"))
            checkpoint_info = result.fetchone()
            logger.info("WAL checkpoint status before TRUNCATE: %s", checkpoint_info)

            # PRAGMA wal_checkpoint(TRUNCATE) czyści logi i resetuje plik WAL do zera.
            # PASSIVE (0) - nie czeka na aktywne czytelników
            # FULL (1) - czeka, ale może blokować
            # RESTART (2) - jak FULL + przygotowuje do TRUNCATE
            # TRUNCATE (3) - czyści WAL i resetuje rozmiar pliku do minimum
            await conn.execute(text("PRAGMA wal_checkpoint(TRUNCATE);"))
            await conn.execute(text("VACUUM;"))

            # Potwierdź, że WAL został wyczyszczony
            result2 = await conn.execute(text("PRAGMA wal_checkpoint;"))
            logger.info("WAL checkpoint status after TRUNCATE: %s", result2.fetchone())
    except Exception as e:
        logger.error("Failed to consolidate database: %s", e)

async def get_session(session_factory: async_sessionmaker[AsyncSession]) -> AsyncGenerator[AsyncSession, None]:
    """Context-manager yielding an AsyncSession from the given factory."""
    async with session_factory() as session:
        try:
            yield session
        finally:
            await session.close()


def get_encrypted_engine():
    """Przykład synchronicznego silnika SQLCipher (jeśli potrzebne)."""
    config = AppConfig()
    db_path = config.base_dir / "app_data" / "nexus_oltp.db"

    db_password = os.getenv(config.sqlcipher_key_env, "")
    if not db_password:
        raise RuntimeError(f"{config.sqlcipher_key_env} environment variable is not set")

    # URL połączenia wykorzystuje dialekt sqlite+pysqlcipher i przekazuje hasło
    db_url = f"sqlite+pysqlcipher://:{db_password}@/{db_path.as_posix()}"
    engine = create_engine(db_url)
    return engine
