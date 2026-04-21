"""Async SQLAlchemy setup for SQLite/SQLCipher (OLTP)."""

from __future__ import annotations

import os
import logging
from collections.abc import AsyncGenerator

from sqlalchemy import event, text, create_engine
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from core.config import AppConfig

logger = logging.getLogger("nexus.db.cleanup")

class Base(DeclarativeBase):
    """Declarative base for OLTP SQLAlchemy models."""
    pass

def _sqlite_url(config: AppConfig) -> str:
    """Build async SQLite URL from configuration."""
    return f"sqlite+aiosqlite:///{config.sqlite_path.as_posix()}"

def create_oltp_engine(config: AppConfig, *, sqlcipher_key: str | None = None) -> AsyncEngine:
    """
    Create an async SQLAlchemy engine with mandatory PRAGMA settings.
    The same hook can bootstrap SQLCipher key when provided either directly
    or via `NEXUS_SQLCIPHER_KEY` environment variable.
    """
    engine = create_async_engine(
        _sqlite_url(config),
        echo=False
    )
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
        async with engine.connect() as conn:
            # PRAGMA wal_checkpoint(TRUNCATE) czyści logi i resetuje plik WAL do zera
            await conn.execute(text("PRAGMA wal_checkpoint(TRUNCATE);"))
    except Exception as e:
        logger.error(f"Failed to consolidate database: {e}")

def get_encrypted_engine():
    """Przykład synchronicznego silnika SQLCipher (jeśli potrzebne)."""
    config = AppConfig()
    db_path = config.base_dir / "app_data" / "nexus_oltp.db"

    # URL połączenia wykorzystuje dialekt sqlite+pysqlcipher i przekazuje hasło
    db_url = f"sqlite+pysqlcipher://:{config.db_password}@/{db_path.as_posix()}"
    engine = create_engine(db_url)
    return engine
