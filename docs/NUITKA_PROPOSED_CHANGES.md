# Propozycje Konkretnych Zmian — Pełna Transformacja Nuitka

> **Krok 3**: Na podstawie audytu (Krok 1) i listy niewykorzystanych supermocy (Krok 2)
> — konkretne propozycje zmian z kodem PRZED/PO.

**Data**: Czerwiec 2026
**Aktualny stopień**: ~94% wykorzystania Nuitka
**Cel**: 100%

---

## Zmiana #1: `@final` dekoratory na klasach krytycznych

**Plik**: `nexus_ai/core/bus.py`
**Typ**: 🟢 Szybka poprawka (low-hanging fruit)
**Efekt**: 5–15% szybsze wywołania metod przez mypyc devirtualizację

### PRZED
```python
class EventBus:
    """Typed, msgspec-backed in-process event bus."""

    def subscribe(self, event_type, callback, ...): ...
    async def emit(self, event, ...): ...
    def get_history(self, ...): ...
```

### PO
```python
from typing import final

@final
class EventBus:
    """Typed, msgspec-backed in-process event bus."""

    def subscribe(self, event_type, callback, ...): ...
    async def emit(self, event, ...): ...
    def get_history(self, ...): ...
```

**Pozostałe klasy do oznaczenia `@final`**:
- `nexus_ai/core/bus.py`: `EventEnvelope`, `Subscription`
- `nexus_ai/core/plugins.py`: `PluginInfo`, `PluginManager`
- `nexus_ai/core/background_task_manager.py`: `BackgroundTaskManager`, `TaskMetadata`, `TaskInfo`

---

## Zmiana #2: `_NUITKA_COMPILED` guard w `tax/__init__.py`

**Plik**: `nexus_ai/tax/__init__.py`
**Typ**: 🟢 Szybka poprawka (low-hanging fruit)
**Efekt**: Szybszy start przy kompilacji Nuitka

### PRZED
```python
try:
    __compiled__
    _NUITKA_COMPILED: bool = True
except NameError:
    _NUITKA_COMPILED: bool = False

from nexus_ai.services.priority_engine import MatchResult, PrioritizedRule
from nexus_ai.services.rule_store import RuleStore
from nexus_ai.services.temporal_manager import TemporalRule
from nexus_crypto import PriorityEngine as _RustPriorityEngine, TemporalManager as _RustTemporalManager
```

### PO
```python
try:
    __compiled__
    _NUITKA_COMPILED: bool = True
except NameError:
    _NUITKA_COMPILED: bool = False

# Gdy kompilowane przez Nuitka — Rust extension zawsze dostępny
if not _NUITKA_COMPILED:
    from nexus_ai.services.priority_engine import MatchResult, PrioritizedRule
    from nexus_ai.services.rule_store import RuleStore
    from nexus_ai.services.temporal_manager import TemporalRule
else:
    # Compiled path: Rust extension jest zawsze w binary
    pass  # nexus_crypto import poniżej wystarczy

from nexus_crypto import PriorityEngine as _RustPriorityEngine, TemporalManager as _RustTemporalManager
```

---

## Zmiana #3: `__compiled__` guard w `tax/rules.py`

**Plik**: `nexus_ai/tax/rules.py`
**Typ**: 🟢 Szybka poprawka
**Efekt**: Cichszy start przy kompilacji

### PRZED
```python
try:
    from nexus_crypto import (
        PriorityEngine as _RustPriorityEngine,
        TemporalManager as _RustTemporalManager,
    )
    _HAS_RUST_PRIORITY = True
except ImportError:
    _HAS_RUST_PRIORITY = False

    class _RustPriorityEngine:  # fallback stub
        ...
```

### PO
```python
try:
    __compiled__  # type: ignore[name-defined]
    _NUITKA_COMPILED = True
except NameError:
    _NUITKA_COMPILED = False

try:
    from nexus_crypto import (
        PriorityEngine as _RustPriorityEngine,
        TemporalManager as _RustTemporalManager,
    )
    _HAS_RUST_PRIORITY = True
    if not _NUITKA_COMPILED:
        logger.info("Rust PriorityEngine loaded")
except ImportError:
    _HAS_RUST_PRIORITY = False
    if not _NUITKA_COMPILED:
        logger.info("Rust not available — using Python fallback")

    class _RustPriorityEngine:  # fallback stub
        ...
```

---

## Zmiana #4: CI — Clang build job

**Plik**: `.github/workflows/ci.yml`
**Typ**: 🟡 Średni refaktor
**Efekt**: Mniejszy binary o 5–10%, weryfikacja kompatybilności z Clang

### PRZED
```yaml
build-nuitka:
    needs: [test-hatch-matrix, build-rust, mypyc-compile]
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
    # ... używa GCC domyślnie
```

### PO
```yaml
build-nuitka:
    needs: [test-hatch-matrix, build-rust, mypyc-compile]
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
    # ... domyślny GCC

build-nuitka-clang:
    needs: [test-hatch-matrix, build-rust, mypyc-compile]
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - name: Install Clang + LLD
        run: sudo apt-get update -qq && sudo apt-get install -y -qq clang lld
      - name: Install pipx + hatch
        run: |
          pip install pipx && pipx ensurepath
          pipx install hatch
      - name: Cache ccache + NUITKA
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache/ccache
            ~/.cache/nuitka
          key: nuitka-clang-${{ runner.os }}-${{ hashFiles('pyproject.toml', 'nexus_ai/**/*.py') }}
      - name: Build with Clang
        run: |
          export CCACHE_DIR=~/.cache/ccache
          export NUITKA_CACHE_DIR=~/.cache/nuitka
          python -m nuitka --clang --lto=yes --onefile main.py
      - name: Show ccache stats
        if: always()
        run: ccache --show-stats || true
      - name: Upload Clang build
        uses: actions/upload-artifact@v4
        with:
          name: nexus-ai-clang-ubuntu-latest
          path: dist/nexus-ai*
          retention-days: 30
```

---

## Zmiana #5: `--prefer-source-code` optymalizacja

**Plik**: `pyproject.toml`
**Typ**: 🟢 Szybka poprawka (już zrobione)

Obecnie:
```ini
[tool.nuitka]
prefer-source-code = false
```

To jest **już wdrożone** w ramach Fazy 2. Nuitka używa `.so` plików z mypyc
zamiast `.py` źródła. Efekt: 2–5× szybsze moduły.

---

## Zmiana #6: Multidist — wiele entry points

**Plik**: `main.py`
**Typ**: 🟡 Średni refaktor
**Efekt**: Jeden binary, 3 entry points (API, worker, CLI)

### PRZED
```python
# Tylko jeden entry point
# nuitka-project: --onefile
# main.py → cała aplikacja
```

### PO
```python
# Wiele entry points w jednym binary
# nuitka-project: --onefile
# nuitka-project: --main=main.py
# nuitka-project: --main=nexus_ai.api.server:run_backend
# nuitka-project: --main=nexus_ai.luz.worker:main
# nuitka-project: --main=nexus_ai.scripts.nexus_cli:main
```

Użycie:
```bash
# Uruchom API
./NexusAI nexus_ai.api.server:run_backend

# Uruchom worker
./NexusAI nexus_ai.luz.worker:main

# Uruchom CLI
./NexusAI nexus_ai.scripts.nexus_cli:main
```

---

## Zmiana #7: `--windows-splash-screen`

**Plik**: `main.py` (sekcja Windows)
**Typ**: 🟢 Szybka poprawka
**Efekt**: Profesjonalny splash screen podczas rozpakowywania

### PRZED
```python
# nuitka-project-if: os.name == "nt":
# nuitka-project: --windows-icon-from-ico=assets/nexus.ico
# nuitka-project: --windows-console-mode=disable
```

### PO
```python
# nuitka-project-if: os.name == "nt":
# nuitka-project: --windows-icon-from-ico=assets/nexus.ico
# nuitka-project: --windows-console-mode=disable
# nuitka-project: --windows-splash-screen=assets/splash.png
# nuitka-project-else:
# nuitka-project: --linux-onefile-icon=assets/nexus.png
```

---

## Zmiana #8: Raport niestandardowy (Jinja2 template)

**Plik**: `main.py` + `build/report-template.rst.j2`
**Typ**: 🟢 Szybka poprawka
**Efekt**: Czytelniejszy, dostosowany do projektu raport kompilacji

### PLIK: `build/report-template.rst.j2`
```jinja2
NexusAI — Compilation Report
=============================

Project: {{ project_name }}
Version: {{ project_version }}
Date: {{ date }}

Modules included:
{% for module in modules %}
  - {{ module.name }} ({{ module.kind }})
{% endfor %}

Data files:
{% for datafile in datafiles %}
  - {{ datafile.source }} → {{ datafile.dest }}
{% endfor %}

Plugins:
{% for plugin in plugins %}
  - {{ plugin.name }} v{{ plugin.version }}
{% endfor %}
```

### PLIK: `main.py`
```python
# nuitka-project: --report-template=build/report-template.rst.j2:build/report.rst
```

---

## Podsumowanie — mapa zmian

| # | Zmiana | Typ | Wysiłek | Efekt | Status |
|---|--------|-----|---------|-------|--------|
| 1 | `@final` dekoratory | 🟢 Quick | 5 min | 5–15% szybsze metody | ⏳ Niezrobione |
| 2 | `_NUITKA_COMPILED` w `tax/__init__` | 🟢 Quick | 10 min | Szybszy start | ⏳ Niezrobione |
| 3 | `__compiled__` w `tax/rules.py` | 🟢 Quick | 10 min | Cichszy import | ⏳ Niezrobione |
| 4 | CI Clang build job | 🟡 Medium | 30 min | Mniejszy binary | ⏳ Niezrobione |
| 5 | `prefer-source-code=false` | 🟢 Quick | 1 min | mypyc .so priority | ✅ Wdrożone (Faza 2) |
| 6 | Multidist | 🟡 Medium | 30 min | Wiele entry points | ⏳ Niezrobione |
| 7 | Splash screen Windows | 🟢 Quick | 5 min | UX | ⏳ Niezrobione |
| 8 | Niestandardowy raport | 🟢 Quick | 15 min | Debugowanie | ⏳ Niezrobione |

### Rekomendowana kolejność wdrożenia:

1. **Sprint 1** (15 min): #1 + #2 + #3 — szybkie poprawki kodu
2. **Sprint 2** (30 min): #7 — splash screen (asset + 1 linia configu)
3. **Sprint 3** (45 min): #4 — CI Clang job
4. **Opcjonalnie**: #6 (multidist) + #8 (raport) — gdy będzie potrzeba

---

*Raport wygenerowany: Czerwiec 2026*
*Stan: Fazy 1–3 wdrożone, Krok 0–2 zrobione, 8 konkretnych propozycji zmian*
