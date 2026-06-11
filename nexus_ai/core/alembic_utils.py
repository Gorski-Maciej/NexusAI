"""
Alembic configuration utilities — standalone, no nexus_crypto dependency.

Zgodnie z aa3fvcx.txt (Punkt 25): konfiguracja Alembic w pyproject.toml [tool.alembic],
nie w osobnych plikach alembic.ini.

Ta funkcja jest oddzielona od core/config.py aby uniknąć zależności od
nexus_crypto (Rust), który może nie być skompilowany.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from msgspec import toml


def get_alembic_config() -> Any:
    """Create Alembic Config from pyproject.toml [tool.alembic] section.

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

        script_location = alembic_cfg_dict.get(
            "script_location", "nexus_ai/db/migrations"
        )
        # Resolve relative to project root
        full_script_location = str((project_root / script_location).resolve())

        cfg = AlembicConfig()
        cfg.set_main_option("script_location", full_script_location)
        cfg.set_main_option(
            "file_template",
            alembic_cfg_dict.get("file_template", "%(rev)s_%(slug)s"),
        )
        cfg.set_main_option("timezone", alembic_cfg_dict.get("timezone", "UTC"))
        # sqlalchemy.url is resolved at runtime by env.py
        cfg.set_main_option("sqlalchemy.url", "sqlite:///placeholder.db")

        return cfg
    except Exception:
        return None
