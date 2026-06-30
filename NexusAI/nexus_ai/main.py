"""
NexusAI — CLI entry point (thin wrapper, delegates to pixi)
==============================================================

Backwards-compatibility shim. All CLI commands are delegated to ``pixi run``.

Usage:
    python -m nexus_ai.main --mode api     ->  pixi run api
    python -m nexus_ai.main --migrate      ->  pixi run migrate
    python -m nexus_ai.main --load-fixtures ->  pixi run seed
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import anyio


async def main(argv: list[str] | None = None) -> int:
    """Delegate CLI arguments to pixi run (backwards-compat shim).

    Args:
        argv: CLI arguments (defaults to sys.argv[1:]).

    Returns:
        Exit code from pixi task.
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

    MODES = {
        "api": "api",
        "worker": "worker",
        "all": "dev",
        "bootstrap": "bootstrap",
        "doctor": "doctor",
    }
    FLAGS = {
        "--migrate": "migrate",
        "--load-fixtures": "seed",
        "--fetch-models": "download-models",
        "--check-models": "check-models",
        "--check-updates": "check-updates",
        "--compute-checksums": "compute-checksums",
    }

    for flag, task in FLAGS.items():
        if flag in args:
            return await _run_pixi(task)
    for i, a in enumerate(args):
        if a == "--mode" and i + 1 < len(args) and args[i + 1] in MODES:
            return await _run_pixi(MODES[args[i + 1]])
        if a == "--mode" and i + 1 < len(args):
            print(f"Unknown mode: {args[i + 1]}, available: {', '.join(MODES)}")
            return 1
    return await _run_pixi("api")


async def _run_pixi(task: str) -> int:
    """Run a pixi task and return its exit code via anyio.run_process."""
    project_root = Path(__file__).resolve().parent.parent
    cmd = ["pixi", "run", task]
    try:
        result = await anyio.run_process(cmd, cwd=project_root)
        return result.returncode
    except FileNotFoundError:
        print(
            "❌ pixi not found. Install: curl -fsSL https://pixi.sh/install.sh | sh",
            file=sys.stderr,
        )
        print("   Then run: pixi install", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(anyio.run(main))
