# REMOVAL REPORT — uv Purge

## Summary

**Date:** 2026-06-23
**Project:** NexusAI
**Action:** Removal of `uv` (Python package manager) from the repository.
**Channel policy:** `conda-forge` retained as system dependency channel (required for free-threaded Python 3.13t, Tesseract, mimalloc, etc.)

## Files Modified: 12

| # | File | Changes | Lines Removed/Changed |
|---|---|---|---|
| 1 | `pixi.toml` | Removed entire `# ── uv Package Manager` section (command equivalents table ~10 lines); removed `verify-migration` task (~40 lines); cleaned uv references from task descriptions | ~55 |
| 2 | `pyproject.toml` | Removed comments about uv being built into pixi | 3 |
| 3 | `.github/dependabot.yml` | Removed "uv jest wbudowany w pixi" and "pip/uv" comments | 2 |
| 4 | `.github/workflows/ci.yml` | Removed uv comment in test section; removed entire `verify-migration` job (~30 lines) | ~33 |
| 5 | `scripts/aliases.sh` | Removed all uv comments (2 sections) | 9 |
| 6 | `README.md` | Updated uv table row: removed "uv wbudowany" → "Zastąpiony przez pixi" | 1 |
| 7 | `nexus_ai/architecture/perfect_accounting_architecture.py` | Removed `"uv"` from `REQUIRED_TECHNOLOGIES`; removed `Technology(name="uv", ...)` | 2 |
| 8 | `nexus_ai/scripts/profiler.py` | Changed "pixi/uv" → "pixi" in comment | 1 |
| 9 | `nexus_ai/installer/build_scripts/build_exe.sh` | Removed "uv jest wbudowany w pixi" comment | 1 |
| 10 | `nexus_ai/build/hooks.py` | Removed "zamiast uv run" from docstring | 1 |
| 11 | `RAPORT_TECHNOLOGII_NEXUSAI.txt` | Removed uv entry (#3) | 1 |
| 12 | `docs/aa3fvcx.txt` | Removed entire "uv – Najszybszy menadżer pakietów PyPI" section; cleaned uv references in hatchling, Granian, and ruff descriptions | ~10 |

## Total Lines Removed: ~119

## What Changed

### Removed: `uv` (Python package manager)
- All references to `uv` as a tool/technology across 12 files
- uv command equivalents table in pixi.toml
- uv verify-migration job in CI (now redundant)
- uv tech stack entries in code and documentation

### Kept: `conda-forge` (system dependency channel)
- `channels = ["conda-forge"]` in pixi.toml — required for free-threaded Python 3.13t (`*_cp313t`)
- System dependencies (Tesseract, mimalloc, OpenCV, libxml2, etc.)
- Conda-Forge entry in RAPORT_TECHNOLOGII_NEXUSAI.txt (#11)

## Not Modified (Different Technologies)
- **libuv** (system C library for async I/O — used by Node.js, Julia)
- **uvicorn** (ASGI server — already replaced by Granian)
- **uvloop** (event loop implementation)
- **tox-uv** (tox plugin)
- **`depends_on` → `depends-on`** (noted: pixi 0.70.2 deprecation warning, outside scope)

## Notes
- `pixi.lock` was NOT regenerated — paddlepaddle has no `cp313t` wheel, causing resolution failure on `linux-64`. This is a pre-existing issue unrelated to uv removal. Lockfile remains valid as generated with original `conda-forge` channel.
- To regenerate: run `pixi update` on a machine with full `linux-64` environment.
