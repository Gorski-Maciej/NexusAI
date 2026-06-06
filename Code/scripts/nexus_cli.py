"""
nexus_cli.py — Thin CLI wrapper for the nexus entry point.

This module is the console_scripts entry point for ``nexus``.
It delegates to ``Code.main:main``, which is the central application entry point.

Why this wrapper exists:
    ``main.py`` lives at the project root (outside ``Code/``) and therefore
    is not included in a regular ``pip install nexus-ai`` (non-editable).
    This wrapper lives inside the ``SKRIPTS`` package, which IS installed,
    so the ``nexus`` CLI command works in all installation modes.

Usage (after pip install):
    nexus --help
    nexus --mode api
    nexus --mode doctor
"""

from __future__ import annotations

import sys
from pathlib import Path


def main(argv: list[str] | None = None) -> int:
    """Import and delegate to the real main() in Code/main.py."""
    # Ensure project root is on sys.path so Code/main.py and subpackages can be found
    # __file__ = Code/scripts/nexus_cli.py -> parent = Code/scripts/ -> parent = Code/ -> parent = project root
    _project_root = Path(__file__).resolve().parent.parent.parent
    _root_dir = str(_project_root)
    if _root_dir not in sys.path:
        sys.path.insert(0, _root_dir)

    # Now import and run the real entry point
    from main import main as _main  # type: ignore[import-untyped]

    return _main(argv)


if __name__ == "__main__":
    raise SystemExit(main())
