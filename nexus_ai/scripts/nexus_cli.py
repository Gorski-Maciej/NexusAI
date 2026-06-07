"""
nexus_cli.py — Thin CLI wrapper for the nexus entry point.

This module is the console_scripts entry point for ``nexus``.
It delegates to ``nexus_ai.main:main``, which is the central application entry point.

Usage (after pip install or Nuitka build):
    nexus --help
    nexus --mode api
    nexus --mode doctor
"""

from __future__ import annotations


def main(argv: list[str] | None = None) -> int:
    """Import and delegate to the real main() in nexus_ai/main.py."""
    from nexus_ai.main import main as _main  # type: ignore[import-untyped]

    return _main(argv)


if __name__ == "__main__":
    raise SystemExit(main())
