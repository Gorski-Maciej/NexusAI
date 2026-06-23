# REMOVAL REPORT — uv & Conda-Forge Purge

## Summary

**Date:** 2026-06-23
**Project:** NexusAI
**Action:** Complete removal of `uv` (Python package manager) and `conda-forge` (conda channel) from the repository.

## Files Modified: 12

| # | File | Changes | Lines Removed |
|---|---|---|---|
| 1 | `pixi.toml` | Changed `channels = ["conda-forge"]` → `["defaults"]`; removed entire `# ── uv Package Manager` section (10 lines); removed `verify-migration` task (~40 lines); removed conda-forge comments; cleaned uv references from task descriptions | ~55 |
| 2 | `pyproject.toml` | Removed comments about uv being built into pixi | 3 |
| 3 | `.github/dependabot.yml` | Removed "uv jest wbudowany w pixi" and "pip/uv" comments | 2 |
| 4 | `.github/workflows/ci.yml` | Removed uv comment in test section; removed entire `verify-migration` job (~30 lines) | ~33 |
| 5 | `scripts/aliases.sh` | Removed all uv comments (2 sections) | 9 |
| 6 | `README.md` | Updated uv table row: removed "uv wbudowany" → "Zastąpiony przez pixi" | 1 |
| 7 | `nexus_ai/architecture/perfect_accounting_architecture.py` | Removed `"uv"` from `REQUIRED_TECHNOLOGIES` set; removed `Technology(name="uv", ...)` from DevSecOps component | 2 |
| 8 | `nexus_ai/scripts/profiler.py` | Changed "pixi/uv" → "pixi" in comment | 1 |
| 9 | `nexus_ai/installer/build_scripts/build_exe.sh` | Removed "uv jest wbudowany w pixi" comment | 1 |
| 10 | `nexus_ai/scripts/doctor.py` | Changed "conda-forge deps" → "system deps" in mimalloc message | 1 |
| 11 | `RAPORT_TECHNOLOGII_NEXUSAI.txt` | Removed uv entry (#3); removed Conda-Forge entry (#11); cleaned conda-forge mentions from Python 3.13, Tesseract, and "ZALEŻNOŚCI SYSTEMOWE" sections | 5 |
| 12 | `docs/aa3fvcx.txt` | Removed entire "uv – Najszybszy menadżer pakietów PyPI" section; fixed "Lepsza integracja z pixi (uv wbudowany jako resolver)" → "Lepsza integracja z pixi."; removed "uvloop" reference; removed "tych samych twórców co uv" | ~10 |

## Total Lines Removed: ~123

## Detailed List of All Removed References

### `uv` (the Python package manager tool)
- **pixi.toml**: uv Package Manager section with command equivalents table (uv sync → pixi install, etc.), uv references in task descriptions
- **pyproject.toml**: "nie potrzebujesz osobnego uv", "pixi używa uv jako wewnętrznego resolvera"
- **dependabot.yml**: "pip/uv", "uv jest wbudowany w pixi"
- **ci.yml**: "(uv jest wbudowany w pixi — osobny test-uv nie jest potrzebny)", "Verify Migration: mise/uv → pixi" job
- **aliases.sh**: "(uv jest wbudowany w pixi)", "uv package management" section
- **README.md**: uv table row
- **perfect_accounting_architecture.py**: uv in REQUIRED_TECHNOLOGIES and in DevSecOps component
- **profiler.py**: "pixi/uv" reference
- **build_exe.sh**: "uv jest wbudowany w pixi"
- **RAPORT_TECHNOLOGII_NEXUSAI.txt**: uv entry #3
- **aa3fvcx.txt**: Entire uv section, uv references in hatchling, Granian, and ruff descriptions

### `conda-forge` (the conda channel)
- **pixi.toml**: `channels = ["conda-forge"]` → `["defaults"]`; "Zależności systemowe (conda-forge)" comment
- **doctor.py**: "conda-forge deps" → "system deps"
- **RAPORT_TECHNOLOGII_NEXUSAI.txt**: Conda-Forge entry #11; conda-forge mentions in Python 3.13, Tesseract, and system dependencies sections

## Not Modified (Different Technologies)

The following were **NOT** removed as they are separate technologies unrelated to the `uv` package manager:
- **libuv** (system C library for async I/O — used by Node.js, Julia, etc.) — entries in `pixi.lock`
- **uvicorn** (ASGI server — already replaced by Granian, references in test files check for absence)
- **uvloop** (event loop implementation — mentioned in aa3fvcx.txt, removed only from uv context)
- **tox-uv** (tox plugin — different package in pixi.lock)

## Notes
- `pixi.lock` still contains `libuv` (system library) and `conda-forge` URLs. Regenerate with `pixi update` after changes to resolve dependencies from the new `defaults` channel.
- The `defaults` channel may not have all the same packages as `conda-forge`. If `mimalloc` or other system deps are unavailable, they should be moved to PyPI equivalents.
