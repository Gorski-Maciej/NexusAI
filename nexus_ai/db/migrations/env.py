"""
NexusAI — Alembic migration environment (sync).

Handles both offline (SQL script) and online (live DB) migrations.
Uses NexusAI's AppConfig to resolve the database URL at runtime.

Zgodnie z aa3fvcx.txt (Punkt 5): Python 3.13t (free-threaded) — brak GIL —
używamy synchronicznego API sqlite3 (create_engine zamiast create_async_engine).
"""

from __future__ import annotations

import logging
import os
import sys
from logging.config import fileConfig
from pathlib import Path

from alembic import context
from sqlalchemy import engine_from_config, pool

# ── Ensure project root is on sys.path so modules can be imported ──
# migrations/env.py is now at nexus_ai/db/migrations/env.py
# Project root is parent's parent's parent (db -> nexus_ai -> project_root)
_PROJECT_ROOT = Path(__file__).resolve().parents[3]
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

# Alembic Config object
config = context.config

# Logging setup
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

logger = logging.getLogger("alembic.env")

# ── Target metadata: collect all Base.metadata used in the project ──
# Wszystkie modele zdefiniowane w nexus_ai.db.models (SQLModel)
from nexus_ai.db.models import (
    Base as DbModelsBase,  # Invoice, AuditLog, OutboxEvent, SecurityAlert, UserAccount, Contractor, ActiveLearningPattern
)

# Roboton_Reflekton models (SQLite-compatible, zgodnie z aa3fvcx.txt)
from nexus_ai.roboton_reflekton.models import Base as RobotonBase

# Target metadata: SQLModel > DeclarativeBase, bo wszystkie modele są w SQLModel.
# SQLModel automatycznie rejestruje tabele w swojej metadata.
target_metadata = DbModelsBase.metadata

# Merge tables from Roboton_Reflekton models
for table_name, table in RobotonBase.metadata.tables.items():
    if table_name not in target_metadata.tables:
        target_metadata.tables[table_name] = table


def get_database_url() -> str:
    """Resolve the database URL from NexusAI config or environment."""
    try:
        from nexus_ai.core.config import AppConfig
        config_obj = AppConfig()
        url = f"sqlite:///{config_obj.sqlite_path.as_posix()}"
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


def run_migrations_online() -> None:
    """Run migrations in 'online' mode using sync engine."""
    url = get_database_url()
    config_section = config.get_section(config.config_ini_section, {})
    config_section["sqlalchemy.url"] = url

    connectable = engine_from_config(
        config_section,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            render_as_batch=True,
        )
        with context.begin_transaction():
            context.run_migrations()

    connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
