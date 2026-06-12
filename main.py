"""
NexusAI — CLI entry point (delegates to mise)
===============================================

All commands are delegated to ``mise run <task>``.

Quick start:
    python main.py --mode api     ->  mise run api
    python main.py --mode worker  ->  mise run worker
    python main.py --mode all     ->  mise run dev
    python main.py --migrate      ->  mise run migrate
    python main.py --fetch-models ->  mise run download-models

See ``mise run --list`` for all available tasks.

Nuitka Build Configuration
--------------------------
This file is the Nuitka entry point. Build with:
    python -m nuitka main.py
"""

# ═══════════════════════════════════════════════════════════════════════════════
# Nuitka Project Options (build-time only, ignored at runtime)
# ═══════════════════════════════════════════════════════════════════════════════

# ── Output mode ───────────────────────────────────────────────────────────────
# nuitka-project: --mode=onefile
# nuitka-project: --standalone

# ── Output naming ─────────────────────────────────────────────────────────────
# nuitka-project: --output-dir={MAIN_DIRECTORY}/dist
# nuitka-project: --output-filename=nexus-ai
# nuitka-project: --project-name=nexus-ai

# ── Plugins ───────────────────────────────────────────────────────────────────
# nuitka-project: --enable-plugin=pydantic
# nuitka-project: --enable-plugin=numpy
# nuitka-project: --enable-plugin=anti-bloat
# nuitka-project: --enable-plugin=mimalloc
# nuitka-project: --enable-plugin=multiprocessing
# nuitka-project: --enable-plugin=trio

# ── Included packages ─────────────────────────────────────────────────────────
# nuitka-project: --include-package=nexus_ai
# nuitka-project: --include-package=nexus_crypto
# nuitka-project: --include-package=granian
# nuitka-project: --include-package=litestar
# nuitka-project: --include-package=sqlmodel
# nuitka-project: --include-package=duckdb
# nuitka-project: --include-package=polars
# nuitka-project: --include-package=pyarrow
# nuitka-project: --include-package=llama_cpp
# nuitka-project: --include-package=huggingface_hub
# nuitka-project: --include-package=msgspec
# nuitka-project: --include-package=stamina
# nuitka-project: --include-package=httpx
# nuitka-project: --include-package=hishel
# nuitka-project: --include-package=nats
# nuitka-project: --include-package=taskiq
# nuitka-project: --include-package=taskiq_nats
# nuitka-project: --include-package=loguru
# nuitka-project: --include-package=structlog
# nuitka-project: --include-package=pendulum
# nuitka-project: --include-package=opentelemetry
# nuitka-project: --include-package=fsspec
# nuitka-project: --include-package=sqlite_vec
# nuitka-project: --include-package=alembic
# nuitka-project: --include-package=anyio
# nuitka-project: --include-package=lxml
# nuitka-project: --include-package=PIL

# ── Data directories ──────────────────────────────────────────────────────────
# nuitka-project: --include-data-dir={MAIN_DIRECTORY}/nexus_ai/config=nexus_ai/config
# nuitka-project: --include-data-dir={MAIN_DIRECTORY}/nexus_ai/db/migrations=nexus_ai/db/migrations

# ── Specific data files ───────────────────────────────────────────────────────
# nuitka-project: --include-data-files={MAIN_DIRECTORY}/pyproject.toml=pyproject.toml

# ── Excluded modules ──────────────────────────────────────────────────────────
# nuitka-project: --exclude-module=tkinter
# nuitka-project: --exclude-module=unittest
# nuitka-project: --exclude-module=distutils
# nuitka-project: --exclude-module=setuptools
# nuitka-project: --exclude-module=pip
# nuitka-project: --exclude-module=pdb
# nuitka-project: --exclude-module=test

# ── Performance ───────────────────────────────────────────────────────────────
# nuitka-project: --jobs=0
# nuitka-project: --assume-yes-for-downloads
# nuitka-project: --show-progress

# ═══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def main() -> int:
    """Delegate CLI arguments to mise run (~15 lines of logic).

    Usage:
        python main.py --mode api     ->  mise run api
        python main.py --migrate      ->  mise run migrate
        python main.py --host 0.0.0.0 --port 8000 --mode worker
                                    ->  NEXUS_HOST=0.0.0.0 NEXUS_PORT=8000 mise run worker
    """
    args = sys.argv[1:] if len(sys.argv) > 1 else ["--mode", "api"]

    # Zawsze przetwarzaj --host/--port/--watch (jeszcze przed mapowaniem mode)
    for i, a in enumerate(args):
        if a == "--host" and i + 1 < len(args):
            os.environ["NEXUS_HOST"] = args[i + 1]
        elif a == "--port" and i + 1 < len(args):
            os.environ["NEXUS_PORT"] = args[i + 1]
    if "--watch" in args:
        os.environ["NEXUS_WATCH_MODE"] = "1"

    MODES = {"api": "api", "worker": "worker", "all": "dev",
             "bootstrap": "bootstrap", "doctor": "doctor"}
    FLAGS = {"--migrate": "migrate", "--load-fixtures": "seed",
             "--fetch-models": "download-models", "--check-models": "check-models",
             "--check-updates": "check-updates", "--compute-checksums": "compute-checksums"}

    for flag, task in FLAGS.items():
        if flag in args:
            return _run_mise(task)
    for i, a in enumerate(args):
        if a == "--mode" and i + 1 < len(args):
            if args[i + 1] in MODES:
                return _run_mise(MODES[args[i + 1]])
            print(f"Unknown mode: {args[i+1]}, available: {', '.join(MODES)}")
            return 1
    return _run_mise("api")


def _run_mise(task: str) -> int:
    """Run a mise task and return its exit code."""
    project_root = Path(__file__).resolve().parent
    cmd = ["mise", "run", task]
    try:
        result = subprocess.run(cmd, cwd=project_root)
        return result.returncode
    except FileNotFoundError:
        print("❌ mise not found. Install: curl https://mise.run | sh", file=sys.stderr)
        print("   Then run: mise install", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
