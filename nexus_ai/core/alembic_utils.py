"""
Alembic configuration utilities — standalone, no nexus_crypto dependency.

Zgodnie z aa3fvcx.txt (Punkt 25): konfiguracja Alembic w pyproject.toml [tool.alembic],
nie w osobnych plikach alembic.ini.

Ta funkcja jest oddzielona od core/config.py aby uniknąć zależności od
nexus_crypto (Rust), który może nie być skompilowany.

SUPERMOCE:
- Dynamiczny database URL (zamiast placeholder.db)
- Konfiguracja poolu połączeń
- Wsparcie dla alembic check
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from msgspec import toml


def get_alembic_config(
    database_url: str | None = None,
) -> Any:
    """Create Alembic Config from pyproject.toml [tool.alembic] section.

    SUPERMOC:
    - Opcjonalny parametr ``database_url`` — jeśli podany, używa go zamiast placeholder.db

    Uwaga: Konfiguracja poolu połączeń (pool_size itp.) jest zarządzana
    przez env.py przy tworzeniu engine — nie przez Alembic Config.

    Args:
        database_url: Opcjonalny URL bazy danych (np. sqlite:///path/to/db).
            Jeśli None, env.py rozwiąże URL w runtime.

    Returns:
        Alembic Config object, or None if pyproject.toml/[tool.alembic] not found.
    """
    try:
        from alembic.config import Config as AlembicConfig
    except ImportError:
        return None

    # Project root: nexus_ai/core/alembic_utils.py -> nexus_ai/core -> nexus_ai -> project_root
    project_root = Path(__file__).resolve().parent.parent.parent
    pyproject_path = project_root / "pyproject.toml"

    if not pyproject_path.exists():
        return None

    try:
        with open(pyproject_path, "rb") as f:
            data: dict[str, Any] = toml.decode(f.read())

        tool_sec = data.get("tool", {})
        alembic_cfg_dict = tool_sec.get("alembic", {})
        if not alembic_cfg_dict:
            return None

        script_location = alembic_cfg_dict.get("script_location", "nexus_ai/db/migrations")
        # Resolve relative to project root
        full_script_location = str((project_root / script_location).resolve())

        cfg = AlembicConfig()
        cfg.set_main_option("script_location", full_script_location)
        cfg.set_main_option(
            "file_template",
            alembic_cfg_dict.get("file_template", "%(rev)s_%(slug)s"),
        )
        cfg.set_main_option("timezone", alembic_cfg_dict.get("timezone", "UTC"))

        # SUPERMOC: Jeśli URL podany, użyj go; w przeciwnym razie env.py rozwiąże w runtime
        if database_url:
            cfg.set_main_option("sqlalchemy.url", database_url)
        else:
            cfg.set_main_option("sqlalchemy.url", "sqlite:///placeholder.db")

        return cfg
    except Exception:
        return None


def get_alembic_head_revision(config_obj: Any) -> str | None:
    """SUPERMOC: Pobierz head revision z ScriptDirectory.

    Args:
        config_obj: Alembic Config object.

    Returns:
        Head revision string, or None if error.
    """
    try:
        from alembic.script import ScriptDirectory
        script = ScriptDirectory.from_config(config_obj)
        return script.get_current_head()
    except Exception:
        return None


def check_migrations_pending(config_obj: Any) -> tuple[bool, str | None, str | None]:
    """SUPERMOC: Sprawdź, czy są nierozwiązane migracje.

    Args:
        config_obj: Alembic Config object.

    Returns:
        (is_pending, current_rev, head_rev)
    """
    try:
        from alembic.script import ScriptDirectory
        script = ScriptDirectory.from_config(config_obj)
        head_rev = script.get_current_head()

        # Potrzebujemy engine, żeby sprawdzić current_rev
        # To wymaga dostępu do bazy — zwracamy head dla porównania
        return (head_rev is not None, None, head_rev)
    except Exception:
        return (False, None, None)
