"""
NexusAI — CLI entry point (thin wrapper, delegates to mise)
============================================================

Backwards-compatibility shim. All CLI commands are delegated to ``mise run``.

Usage:
    python -m nexus_ai.main --mode api     ->  mise run api
    python -m nexus_ai.main --migrate      ->  mise run migrate
    python -m nexus_ai.main --load-fixtures ->  mise run seed
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def main(argv: list[str] | None = None) -> int:
    """Delegate CLI arguments to mise run (backwards-compat shim).

    Args:
        argv: CLI arguments (defaults to sys.argv[1:]).

    Returns:
        Exit code from mise task.
    """
    args = argv or sys.argv[1:]

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
        if a == "--mode" and i + 1 < len(args) and args[i + 1] in MODES:
            return _run_mise(MODES[args[i + 1]])
        if a == "--mode" and i + 1 < len(args):
            print(f"Unknown mode: {args[i+1]}, available: {', '.join(MODES)}")
            return 1
    return _run_mise("api")


def _run_mise(task: str) -> int:
    """Run a mise task and return its exit code."""
    project_root = Path(__file__).resolve().parent.parent
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
