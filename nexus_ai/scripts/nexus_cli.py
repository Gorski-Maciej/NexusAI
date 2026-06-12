"""
nexus_cli.py — Thin CLI wrapper for the nexus entry point.

This module is the console_scripts entry point for ``nexus``.
It delegates to ``nexus_ai.main:main``, which is the central application entry point.

Usage (after pip install or Nuitka build):
    nexus --help
    nexus --mode api
    nexus --mode doctor
    nexus --mode api --watch              # Auto-reload protocols/config
    nexus --mode all --watch --watch-interval 10  # Custom poll interval
"""

from __future__ import annotations

import argparse
import sys


def _build_cli_parser() -> argparse.ArgumentParser:
    """Zbuduj parser dla nexus CLI z flagą --watch.

    Przekazuje wszystkie argumenty do nexus_ai.main:main z dodanym --watch.
    """
    parser = argparse.ArgumentParser(
        description="NexusAI — AI-Powered Accounting System",
        add_help=False,  # help obsługiwany przez main.py
    )
    parser.add_argument(
        "--watch",
        action="store_true",
        help="Watch config files for changes and auto-reload (development use)",
    )
    parser.add_argument(
        "--watch-interval",
        type=int,
        default=5,
        help="Poll interval in seconds for --watch (default: 5)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    """Import and delegate to the real main() in nexus_ai/main.py.

    Parsuje flagę --watch przed delegacją, aby ustawić odpowiednie
    zmienne środowiskowe przed załadowaniem reszty aplikacji.
    """
    # Parsuj tylko znane flagi — resztę przekaż do main.py
    cli_parser = _build_cli_parser()
    cli_args, remaining_argv = cli_parser.parse_known_args(argv)

    # Ustaw zmienne środowiskowe dla watch mode
    # Muszą być ustawione PRZED importem nexus_ai.main (który ładuje config)
    if cli_args.watch:
        import os

        os.environ["NEXUS_WATCH_MODE"] = "1"
        os.environ["NEXUS_WATCH_INTERVAL"] = str(cli_args.watch_interval)

    from nexus_ai.main import main as _main  # type: ignore[import-untyped]

    # Przekaż pozostałe argumenty do main.py
    return _main(remaining_argv if remaining_argv else None)


if __name__ == "__main__":
    raise SystemExit(main())
