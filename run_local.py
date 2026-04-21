"""Simple local bootstrap for NexusAI backend.

Usage:
    python run_local.py
"""

from __future__ import annotations

import importlib
import sys

REQUIRED_PACKAGES = ("uvicorn", "litestar", "sqlalchemy", "pydantic")


def _check_dependencies() -> list[str]:
    missing: list[str] = []
    for package in REQUIRED_PACKAGES:
        try:
            importlib.import_module(package)
        except ModuleNotFoundError:
            missing.append(package)
    return missing


def main() -> int:
    missing = _check_dependencies()
    if missing:
        print("Brakujące zależności:", ", ".join(missing))
        print("Uruchom: pip install -r requirements.txt")
        return 1

    from api.server import run_backend

    run_backend()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
