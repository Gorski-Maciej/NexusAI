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
Nuitka configuration is in [tool.nuitka] in pyproject.toml (canonical source).
Build command:
    python -m nuitka main.py
"""

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
