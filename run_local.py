"""Local launcher for NexusAI backend.

Examples:
    python run_local.py
    python run_local.py --bootstrap
    python run_local.py --host 0.0.0.0 --port 8080
"""

from __future__ import annotations

import importlib
import os
import subprocess
import sys
from argparse import ArgumentParser, Namespace
from pathlib import Path

# ── Dodaj katalog Code/ do sys.path, aby importy pokroju `api.server` działały ──
_PROJECT_ROOT = Path(__file__).resolve().parent
_CODE_DIR = str(_PROJECT_ROOT / "Code")
if _CODE_DIR not in sys.path:
    sys.path.insert(0, _CODE_DIR)

REQUIRED_PACKAGES = ("uvicorn", "litestar", "sqlalchemy", "pydantic")
PACKAGE_TO_PIP_NAME = {
    "uvicorn": "uvicorn",
    "litestar": "litestar",
    "sqlalchemy": "sqlalchemy",
    "pydantic": "pydantic",
}


def _check_dependencies() -> list[str]:
    missing: list[str] = []
    for package in REQUIRED_PACKAGES:
        try:
            importlib.import_module(package)
        except ModuleNotFoundError:
            missing.append(package)
    return missing


def _install_dependencies(requirements_file: str = "requirements.txt") -> int:
    command = [sys.executable, "-m", "pip", "install", "-r", requirements_file]
    print("Instalowanie zależności:", " ".join(command))
    return subprocess.call(command)


def _build_parser() -> ArgumentParser:
    parser = ArgumentParser(description="Uruchamia lokalny backend NexusAI.")
    parser.add_argument(
        "--bootstrap",
        action="store_true",
        help="Automatycznie doinstaluj brakujące zależności z requirements.txt.",
    )
    parser.add_argument("--host", default="127.0.0.1", help="Host backendu (domyślnie: 127.0.0.1).")
    parser.add_argument("--port", default="8000", help="Port backendu (domyślnie: 8000).")
    return parser


def main(argv: list[str] | None = None) -> int:
    args: Namespace = _build_parser().parse_args(argv)
    os.environ["NEXUS_HOST"] = args.host
    os.environ["NEXUS_PORT"] = str(args.port)

    missing = _check_dependencies()
    if missing:
        print("Brakujące zależności:", ", ".join(missing))
        if not args.bootstrap:
            package_list = " ".join(PACKAGE_TO_PIP_NAME[pkg] for pkg in missing if pkg in PACKAGE_TO_PIP_NAME)
            print("Uruchom jedną z komend:")
            print("  1) pip install -r requirements.txt")
            print(f"  2) pip install {package_list}")
            print("Albo użyj: python run_local.py --bootstrap")
            return 1

        rc = _install_dependencies()
        if rc != 0:
            print("Nie udało się zainstalować zależności.")
            return rc

        missing = _check_dependencies()
        if missing:
            print("Po instalacji nadal brakuje pakietów:", ", ".join(missing))
            return 1

    from api.server import run_backend

    run_backend()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
