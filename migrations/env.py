"""
NexusAI — Alembic migration environment.

Handles both offline (SQL script) and online (live DB) migrations.
Uses NexusAI's AppConfig to resolve the database URL at runtime.
"""

from __future__ import annotations

import asyncio
import logging
import os
import sys
from logging.config import fileConfig
from pathlib import Path

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

# ── Ensure Code/ is on sys.path so models can be imported ──
_PROJECT_ROOT = Path(__file__).resolve().parents[1]
_CODE_DIR = str(_PROJECT_ROOT / "Code")
if _CODE_DIR not in sys.path:
    sys.path.insert(0, _CODE_DIR)
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

# Alembic Config object
config = context.config

# Logging setup
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

logger = logging.getLogger("alembic.env")

# ── Target metadata: collect all Base.metadata used in the project ──
# Core DB models
from db.database import Base as DbBase

# Domain models (each registers its tables with its own Base)
from db.models import Base as DbModelsBase  # AuditLog, OutboxEvent, SecurityAlert, UserAccount
from models.outbox import Base as OutboxBase
from models.invoice import Base as InvoiceBase
from models.audit import Base as AuditBase
from models.contractor import Base as ContractorBase

# Roboton_Reflekton models (PostgreSQL-compatible)
from Roboton_Reflekton.models import Base as RobotonBase

# Combine all metadata for autogenerate support
# Alembic uses the first target_metadata for autogenerate diffing.
# We merge all metadata into one by iterating all tables.
target_metadata = DbBase.metadata

# Merge tables from other bases
for base in [DbModelsBase, OutboxBase, InvoiceBase, AuditBase, ContractorBase, RobotonBase]:
    for table_name, table in base.metadata.tables.items():
        if table_name not in target_metadata.tables:
            target_metadata.tables[table_name] = table


def get_database_url() -> str:
    """Resolve the database URL from NexusAI config or environment."""
    try:
        from core.config import AppConfig
        config_obj = AppConfig()
        url = f"sqlite+aiosqlite:///{config_obj.sqlite_path.as_posix()}"
        # Check for a user-provided override
        env_url = os.getenv("NEXUS_DATABASE_URL", "")
        if env_url:
            url = env_url
        return url
    except Exception:
        # Fallback: use alembic.ini setting
        return config.get_main_option("sqlalchemy.url")


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode (generate SQL script)."""
    url = get_database_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        render_as_batch=True,  # Required for SQLite ALTER TABLE support
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    """Run migrations on a given connection."""
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        render_as_batch=True,  # Required for SQLite
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Run migrations in 'online' mode using async engine."""
    url = get_database_url()
    config_section = config.get_section(config.config_ini_section, {})
    config_section["sqlalchemy.url"] = url

    connectable = async_engine_from_config(
        config_section,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    try:
        asyncio.run(run_async_migrations())
    except Exception as exc:
        logger.error("Migration failed: %s", exc)
        raise


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
