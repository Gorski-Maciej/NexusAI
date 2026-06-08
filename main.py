"""
NexusAI — Central Application Entry Point
==========================================

Simply imports and runs the main application from the ``nexus_ai`` package.
Use ``python main.py`` from the project root, or install via pip:
    pip install -e .
    nexus-api   # starts the Granian server

Nuitka Build Configuration
--------------------------
This file is the Nuitka entry point. Build with:
    python -m nuitka main.py                         # uses nuitka-project: directives below
    python -m nuitka --project-name=nexus-ai main.py # OR explicit CLI args

Quick build (Linux/macOS):
    python -m nuitka main.py

Quick build (Windows):
    python -m nuitka main.py --windows-icon-from-ico=assets/nexus.ico
"""

# ═══════════════════════════════════════════════════════════════════════════════
# Nuitka Project Options
# Zgodnie z dokumentacją Nuitki, konfiguracja odbywa się przez komentarze
# # nuitka-project: w głównym pliku .py, a NIE przez [tool.nuitka] w pyproject.toml.
#
# Te dyrektywy są równoważne opcjom CLI:
#   python -m nuitka --onefile --standalone --enable-plugin=pydantic ... main.py
# ═══════════════════════════════════════════════════════════════════════════════

# ── Output mode: single-file executable ───────────────────────────────────────
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
# nuitka-project: --enable-plugin=upx   # wymaga: apt install upx (opcjonalny kompresor)

# ── Included packages (wszystkie zależności) ──────────────────────────────────
# nuitka-project: --include-package=nexus_ai
# nuitka-project: --include-package=nexus_crypto  # budowany przez maturin z nexus_ai/rust/
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
# nuitka-project: --include-data-files={MAIN_DIRECTORY}/alembic.ini=alembic.ini
# nuitka-project: --include-data-files={MAIN_DIRECTORY}/pyproject.toml=pyproject.toml

# ── Excluded modules (oszczędność miejsca) ────────────────────────────────────
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
# nuitka-project: --show-scons

# ═══════════════════════════════════════════════════════════════════════════════

from nexus_ai.main import main

if __name__ == "__main__":
    raise SystemExit(main())
