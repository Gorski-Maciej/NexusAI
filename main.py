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
Primary configuration is in [tool.nuitka] in pyproject.toml (canonical source).
Directives below enable `python -m nuitka main.py` without pyproject.toml.
Build command:
    python -m nuitka main.py
"""

# ═══════════════════════════════════════════════════════════════════════════
# Nuitka build directives (source-level config)
# ═══════════════════════════════════════════════════════════════════════════
# These directives make `python -m nuitka main.py` work standalone.
# pyproject.toml [tool.nuitka] remains canonical for all builds.

# nuitka-project: --onefile
# nuitka-project: --standalone
# nuitka-project: --enable-plugin=pydantic,numpy,anti-bloat,mimalloc,multiprocessing,trio
# nuitka-project: --include-package=nexus_ai
# nuitka-project: --include-package=nexus_crypto
# nuitka-project: --include-package=granian
# nuitka-project: --include-package=litestar
# nuitka-project: --include-package=msgspec
# nuitka-project: --include-package=anyio
# nuitka-project: --include-package=stamina
# nuitka-project: --include-package=loguru
# nuitka-project: --include-package=pendulum
# nuitka-project: --nofollow-import-to=tkinter,unittest,distutils,setuptools,pip,pdb,test,ensurepip,lib2to3,idlelib,turtle,venv
# nuitka-project-if: os.name == "nt":
# nuitka-project: --windows-icon-from-ico=assets/nexus.ico
# nuitka-project: --windows-console-mode=disable
# nuitka-project-else:
# nuitka-project: --linux-onefile-icon=assets/nexus.png

# nuitka-project: --jobs=0
# nuitka-project: --assume-yes-for-downloads

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def _setup_mimalloc() -> None:
    """Skonfiguruj mimalloc environment variables przed startem.

    Zgodnie z aa3fvcx.txt: mimalloc jako domyślny alokator pamięci.
    Ustawia zmienne środowiskowe dla optymalnej wydajności:
    - huge OS pages dla modeli AI
    - show stats w trybie debug
    - eager commit dla niskich opóźnień
    """
    # huge OS pages — redukcja TLB misses dla dużych obiektów (LightOnOCR-1B ~800MB)
    os.environ.setdefault("MIMALLOC_LARGE_OS_PAGES", "1")
    # rezerwacja huge pages dla modeli GGUF
    os.environ.setdefault("MIMALLOC_RESERVE_HUGE_OS_PAGES", "1")
    # eager commit — niższe opóźnienia alokacji dla API
    os.environ.setdefault("MIMALLOC_EAGER_COMMIT_DELAY", "0")
    # page reset wyłączony dla long-running procesów
    os.environ.setdefault("MIMALLOC_PAGE_RESET", "0")

    if "--debug" in sys.argv or os.environ.get("NEXUS_DEBUG") == "1":
        os.environ.setdefault("MIMALLOC_SHOW_STATS", "1")
        os.environ.setdefault("MIMALLOC_VERBOSE", "1")

    if "--mimalloc-stats" in sys.argv:
        os.environ["MIMALLOC_SHOW_STATS"] = "1"
        import atexit

        def _dump_mimalloc_stats() -> None:
            """Zapisz statystyki mimalloc do pliku przy zakończeniu procesu."""
            try:
                from nexus_ai.core.mimalloc_bridge import save_stats_to_file

                path = save_stats_to_file("mimalloc_stats.json")
                if path:
                    print(f"[MIMALLOC] Stats saved to {path}")
            except Exception:
                pass

        atexit.register(_dump_mimalloc_stats)


def main() -> int:
    _setup_mimalloc()
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
