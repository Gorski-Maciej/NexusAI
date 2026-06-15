"""
NexusAI — Alembic migration environment (sync).

Handles both offline (SQL script) and online (live DB) migrations.
Uses NexusAI's AppConfig to resolve the database URL at runtime.

Zgodnie z aa3fvcx.txt (Punkt 25):
- Konfiguracja Alembic w pyproject.toml [tool.alembic], nie w osobnym alembic.ini
- env.py odczytuje ustawienia z pyproject.toml przez msgspec

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

# ── Read Alembic config from pyproject.toml [tool.alembic] ────────────────
# Zgodnie z aa3fvcx.txt: konfiguracja w pyproject.toml zamiast osobnego pliku.
# msgspec (już w projekcie) parsuje TOML szybciej niż standardowy tomllib.
from msgspec import toml

_pyproject_path = _PROJECT_ROOT / "pyproject.toml"
_tool_alembic: dict = {}
if _pyproject_path.exists():
    try:
        with open(_pyproject_path, "rb") as _f:
            _data = toml.decode(_f.read())
        _tool_alembic = _data.get("tool", {}).get("alembic", {})
    except Exception:
        _tool_alembic = {}

_script_location = _tool_alembic.get("script_location", "nexus_ai/db/migrations")
_script_location_full = str(_PROJECT_ROOT / _script_location)

# ── Alembic Config object ────────────────────────────────────────────────
# Instead of reading alembic.ini, we set options programmatically from
# pyproject.toml [tool.alembic]. This eliminates the need for a separate
# alembic.ini file.
config = context.config

# Override script_location from pyproject.toml
config.set_main_option("script_location", _script_location_full)
config.set_main_option("file_template", _tool_alembic.get("file_template", "%(rev)s_%(slug)s"))
config.set_main_option("timezone", _tool_alembic.get("timezone", "UTC"))

# Logging setup — try reading from config, or use basic logging as fallback
if config.config_file_name is not None:
    try:
        fileConfig(config.config_file_name)
    except Exception:
        pass

logger = logging.getLogger("alembic.env")

# ── SUPERMOC: Zbiór tabel DuckDB-only (pomijane w autogenerate) ──────
_DUCKDB_ONLY_TABLES = frozenset({
    "telemetry_spans",
    "telemetry_metrics",
    "analytics_events",
    "analytics_summaries",
    "zpk_accounts",
    "zpk_mapping_history",
    "zpk_subaccounts",
    "decision_traces",
    "decision_analytics",
    "fallback_events",
    "context_enricher_cache",
})

# ── Target metadata: collect all Base.metadata used in the project ──
# Wszystkie modele zdefiniowane w nexus_ai.db.models (SQLModel)
from nexus_ai.db.models import (
    Base as DbModelsBase,  # Invoice, AuditLog, OutboxEvent, SecurityAlert, UserAccount, Contractor, ActiveLearningPattern
)

# TigerBeetle models (SQLite-compatible, zgodnie z aa3fvcx.txt)
from nexus_ai.services.tigerbeetle.models import Base as RobotonBase

# Target metadata: SQLModel > DeclarativeBase, bo wszystkie modele są w SQLModel.
# SQLModel automatycznie rejestruje tabele w swojej metadata.
target_metadata = DbModelsBase.metadata

# Merge tables from Roboton_Reflekton models
for table_name, table in RobotonBase.metadata.tables.items():
    if table_name not in target_metadata.tables:
        target_metadata.tables[table_name] = table


# ── SUPERMOC: include_object — filtr tabel DuckDB-only z autogenerate ─

def _include_object(obj, name: str, type_: str, reflected: bool, compare_to) -> bool:
    """Filtruj obiekty schematu dla Alembic autogenerate.

    Pomija:
    - Tabele DuckDB-only (analytics, zpk, telemetry)
    - Wewnętrzne tabele sqlite_*
    - Indeksy sqlite_autoindex*
    """
    if type_ == "table":
        if name.startswith("sqlite_"):
            return False
        if name in _DUCKDB_ONLY_TABLES:
            return False
        return True
    if type_ == "index":
        if name.startswith("sqlite_autoindex"):
            return False
        return True
    return True


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
        # Fallback: use a default path
        _default_db = _PROJECT_ROOT / "app_data" / "databases" / "nexus_oltp.db"
        return f"sqlite:///{_default_db.as_posix()}"


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode (generate SQL script)."""
    url = get_database_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        render_as_batch=True,  # Required for SQLite ALTER TABLE support
        # SUPERMOC: include_object — filtr DuckDB-only tables dla offline
        include_object=_include_object,
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
            # ════════════════════════════════════════════════════════════
            # SUPERMOCE Alembic (Faza 1 + 2):
            # ════════════════════════════════════════════════════════════
            compare_type=True,              # Wykrywa zmiany typów kolumn
            compare_server_default=True,    # Wykrywa zmiany wartości domyślnych
            transaction_per_migration=True, # Każda migracja = osobna transakcja (SQLite-safe)
            include_object=_include_object, # Filtr DuckDB-only tables
        )
        with context.begin_transaction():
            context.run_migrations()

        # ════════════════════════════════════════════════════════════════
        # SUPERMOC: user_version sync — po migracji aktualizuj PRAGMA
        # user_version. To pozwala zewnętrznym narzędziom szybko odczytać
        # wersję schematu bez analizowania tabel Alembic.
        # ════════════════════════════════════════════════════════════════
        try:
            from alembic.runtime.migration import MigrationContext as _MCtx
            _mctx = _MCtx.configure(connection)
            _current_rev = _mctx.get_current_revision()
            if _current_rev:
                # Weź pierwszą część rewizji (np. "0001" z "0001_initial_schema")
                _rev_part = _current_rev.split("_")[0] if "_" in _current_rev else _current_rev
                _digits = "".join(c for c in _rev_part if c.isdigit())
                if _digits:
                    _version = int(_digits) % (2**32)  # 32-bit unsigned
                    connection.execute(text(f"PRAGMA user_version = {_version}"))
                    logger.info(
                        "[ALEMBIC-LIFECYCLE] user_version synced: %d (rev %s)",
                        _version, _current_rev,
                    )
        except Exception as _exc:
            logger.warning("[ALEMBIC-LIFECYCLE] user_version sync failed: %s", _exc)

    connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
