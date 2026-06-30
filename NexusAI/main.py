"""
NexusAI — CLI entry point (delegates to pixi)
================================================

All commands are delegated to ``pixi run <task>``.

Quick start:
    python main.py --mode api     ->  pixi run api
    python main.py --mode worker  ->  pixi run worker
    python main.py --mode all     ->  pixi run dev
    python main.py --migrate      ->  pixi run migrate
    python main.py --fetch-models ->  pixi run download-models

See ``pixi run --list`` for all available tasks.

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

# ═══════════════════════════════════════════════════════════════════════════
# TRYB KOMPILACJI
# ═══════════════════════════════════════════════════════════════════════════
# nuitka-project: --onefile
# nuitka-project: --standalone

# ═══════════════════════════════════════════════════════════════════════════
# PLUGINY — wszystkie niezbędne dla stacku NexusAI
# ═══════════════════════════════════════════════════════════════════════════
# nuitka-project: --enable-plugin=anti-bloat,mimalloc,multiprocessing,trio
# nuitka-project: --user-plugin=nexus_ai/build/nuitka_plugins.py

# ═══════════════════════════════════════════════════════════════════════════
# OPTYMALIZACJE WYDAJNOŚCI (LTO + Python flags)
# ═══════════════════════════════════════════════════════════════════════════
# LTO (Link Time Optimization) — 5-15% szybszy kod, mniejszy binary
# nuitka-project: --lto=yes

# Python flags dla release build (wyłączone w debug)
# Ustaw NEXUS_DEBUG=1 przed `python -m nuitka main.py` aby wyłączyć te optymalizacje
# nuitka-project-if: os.environ.get("NEXUS_DEBUG", "0") != "1":
# nuitka-project: --python-flag=no_asserts
# nuitka-project: --python-flag=no_docstrings
# nuitka-project: --python-flag=isolated

# (Uwaga: [tool.nuitka] w pyproject.toml również definiuje python-flag —
#  jeśli obie konfiguracje są aktywne, ta w main.py ma wyższy priorytet
#  dla warunkowych flag. Dla spójności, pyproject.toml definiuje te same
#  flagi, co zapewnia działanie nawet gdy main.py nie jest używany.)

# ═══════════════════════════════════════════════════════════════════════════
# PACKAGE INCLUDE — wszystkie pakiety aplikacji + zależności
# ═══════════════════════════════════════════════════════════════════════════
# nuitka-project: --include-package=nexus_ai
# nuitka-project: --include-package=nexus_crypto
# nuitka-project: --include-package=granian
# nuitka-project: --include-package=litestar
# nuitka-project: --include-package=msgspec
# nuitka-project: --include-package=anyio
# nuitka-project: --include-package=stamina
# nuitka-project: --include-package=loguru
# nuitka-project: --include-package=pendulum
# nuitka-project: --include-package=duckdb
# nuitka-project: --include-package=polars
# nuitka-project: --include-package=httpx
# nuitka-project: --include-package=nats
# nuitka-project: --include-package=taskiq
# nuitka-project: --include-package=llama_cpp

# ═══════════════════════════════════════════════════════════════════════════
# NOFOLLOW — wykluczenie zbędnych modułów (oszczędność 5-10 MB)
# ═══════════════════════════════════════════════════════════════════════════
# nuitka-project: --nofollow-import-to=tkinter,unittest,distutils,setuptools,pip,pdb,test,ensurepip,lib2to3,idlelib,turtle,venv,http.server,socketserver,xmlrpc,cgi,dbm,msilib,smtpd,telnetlib,uu,xdrlib

# ═══════════════════════════════════════════════════════════════════════════
# METADATA APLIKACJI — wersja, copyright, nazwa produktu
# ═══════════════════════════════════════════════════════════════════════════
# nuitka-project-set: VERSION = __import__("json").load(open("{MAIN_DIRECTORY}/config/version.json"))["version"]
# nuitka-project: --product-name=NexusAI
# nuitka-project: --file-version={VERSION}
# nuitka-project: --copyright="© 2026 NexusAI Team"
# nuitka-project: --file-description="NexusAI — AI-Powered Accounting System"

# ═══════════════════════════════════════════════════════════════════════════
# ONEFILE CACHE — szybki start (unikanie wielokrotnego rozpakowywania)
# ═══════════════════════════════════════════════════════════════════════════
# nuitka-project: --onefile-tempdir-spec={CACHE_DIR}/NexusAI/{PRODUCT}/{VERSION}

# ═══════════════════════════════════════════════════════════════════════════
# RAPORT KOMPILACJI — debugowanie i compliance
# ═══════════════════════════════════════════════════════════════════════════
# nuitka-project-if: os.environ.get("NEXUS_BUILD_REPORT", "0") == "1":
# nuitka-project: --report=build/compilation-report.xml

# ═══════════════════════════════════════════════════════════════════════════
# PLATFORM-SPECIFIC
# ═══════════════════════════════════════════════════════════════════════════
# nuitka-project-if: os.name == "nt":
# nuitka-project: --windows-icon-from-ico=assets/nexus.ico
# nuitka-project: --windows-console-mode=disable
# nuitka-project: --windows-splash-screen=assets/splash.png
# nuitka-project-else:
# nuitka-project: --linux-onefile-icon=assets/nexus.png

# ═══════════════════════════════════════════════════════════════════════════
# INFRASTRUKTURA KOMPILACJI
# ═══════════════════════════════════════════════════════════════════════════
# nuitka-project: --jobs=0
# nuitka-project: --assume-yes-for-downloads

from __future__ import annotations

import os
import sys
from pathlib import Path

import anyio


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


async def main() -> int:
    _setup_mimalloc()
    """Delegate CLI arguments to pixi run (~15 lines of logic).

    Usage:
        python main.py --mode api     ->  pixi run api
        python main.py --migrate      ->  pixi run migrate
        python main.py --host 0.0.0.0 --port 8000 --mode worker
                                    ->  NEXUS_HOST=0.0.0.0 NEXUS_PORT=8000 pixi run worker
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
            return await _run_pixi(task)
    for i, a in enumerate(args):
        if a == "--mode" and i + 1 < len(args):
            if args[i + 1] in MODES:
                return await _run_pixi(MODES[args[i + 1]])
            print(f"Unknown mode: {args[i+1]}, available: {', '.join(MODES)}")
            return 1
    return await _run_pixi("api")


async def _run_pixi(task: str) -> int:
    """Run a pixi task and return its exit code via anyio.run_process."""
    project_root = Path(__file__).resolve().parent
    cmd = ["pixi", "run", task]
    try:
        result = await anyio.run_process(cmd, cwd=project_root)
        return result.returncode
    except FileNotFoundError:
        print("❌ pixi not found. Install: curl -fsSL https://pixi.sh/install.sh | sh", file=sys.stderr)
        print("   Then run: pixi install", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(anyio.run(main))
