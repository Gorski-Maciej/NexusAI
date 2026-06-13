# Nuitka Superpowers — NexusAI Technical Documentation

> **Krok 0**: Kompletna dokumentacja wszystkich wykorzystanych supermocy Nuitka w projekcie NexusAI.
>
> Niniejszy dokument opisuje każdą zoptymalizowaną flagę, plugin, dyrektywę i mechanizm
> Nuitka zaimplementowany w projekcie — wraz z lokalizacją w kodzie, efektem i przykładem użycia.

---

## Spis treści

1. [Architektura kompilacji — 3 źródła konfiguracji](#1-architektura-kompilacji)
2. [Tryby kompilacji](#2-tryby-kompilacji)
3. [Optymalizacje wydajności](#3-optymalizacje-wydajności)
4. [Pluginy Nuitka](#4-pluginy-nuitka)
5. [Custom User Plugin — NexusAIPlugin](#5-custom-user-plugin)
6. [Package & Data Inclusion](#6-package--data-inclusion)
7. [Nofollow — redukcja rozmiaru](#7-nofollow)
8. [User Package Configuration — DLL/Shared Library handling](#8-user-package-configuration)
9. [`__compiled__` Guard — runtime detection](#9-__compiled__-guard)
10. [PGO — Profile Guided Optimization](#10-pgo)
11. [Clang/Zig — alternatywne kompilatory](#11-clangzig)
12. [mypyc → Nuitka pipeline](#12-mypyc--nuitka-pipeline)
13. [CCache — infra kompilacji](#13-ccache)
14. [Infrastruktura CI/CD](#14-infrastruktura-cicd)
15. [Głębokie transformacje architektoniczne](#15-głębokie-transformacje)
16. [Cheatsheet — szybki start](#16-cheatsheet)

---

## 1. Architektura kompilacji

NexusAI wykorzystuje **3 źródła konfiguracji Nuitka**, które współpracują hierarchicznie:

| Źródło | Plik | Priorytet | Zastosowanie |
|--------|------|-----------|--------------|
| **Source-level directives** | `main.py` (`# nuitka-project:`) | 🔴 **Najwyższy** | Warunkowe flagi, metadata, onefile-cache |
| **pyproject.toml** | `[tool.nuitka]` | 🟡 Średni | Canonical config, pakiety, pluginy, nofollow |
| **Build scripts** | `build_exe.sh` / `build_exe.bat` | 🟢 Najniższy | CLI flags + LTO + ccache + Clang/Zig |

### Hierarchia ładowania

```
main.py  (# nuitka-project: --lto=yes)
    ↓ override
pyproject.toml  ([tool.nuitka] lto = true)
    ↓ fallback
build_exe.sh  (python -m nuitka --lto=yes main.py)
```

### 3 sposoby uruchomienia builda

```bash
# 1. Bezpośrednio (używa main.py directives)
python -m nuitka main.py

# 2. Przez hatch (używa pyproject.toml + build_nexus.py)
hatch run build:build-nuitka

# 3. Przez build scripts (używa CLI flags + ccache)
./nexus_ai/installer/build_scripts/build_exe.sh
./nexus_ai/installer/build_scripts/build_exe.bat
```

---

## 2. Tryby kompilacji

### `--onefile`

**Lokalizacja**: `main.py`, `pyproject.toml`, `build_nexus.py`

Tworzy pojedynczy plik binarny z wszystkimi zależnościami. Przy pierwszym uruchomieniu
binary rozpakowuje się do tymczasowego katalogu.

```ini
# main.py
# nuitka-project: --onefile

# pyproject.toml
[tool.nuitka]
onefile = true
```

### `--standalone`

**Lokalizacja**: `pyproject.toml`, `build_nexus.py`

Tworzy folder z binarnym + wszystkimi zależnościami (bez instalacji systemowej).

```ini
# pyproject.toml
standalone = true
```

---

## 3. Optymalizacje wydajności

### 3.1 LTO — Link Time Optimization

**Lokalizacja**: `main.py`, `pyproject.toml`, `build_exe.sh`, `build_exe.bat`, `build_nexus.py`

**Efekt**: 5–15% szybszy kod, mniejszy binary. Kompilator C wykonuje optymalizacje
między-modułowe podczas linkowania.

```ini
# main.py
# nuitka-project: --lto=yes

# pyproject.toml
[tool.nuitka]
lto = true
```

### 3.2 Python flags — no_asserts, no_docstrings, isolated

**Lokalizacja**: `main.py` (warunkowo przez `nuitka-project-if:`)

**Efekt**: 
- `no_asserts`: usuwa `assert` statements → 5–10% szybszy kod, mniejszy binary
- `no_docstrings`: usuwa `__doc__` → 15–30% mniejszy binary
- `isolated`: ignoruje `PYTHONPATH`, deterministyczny build → bezpieczniejszy binary

**Warunkowe włączanie**: Tylko gdy `NEXUS_DEBUG != "1"` (debug build ma asserty i docstringi).

```ini
# main.py
# nuitka-project-if: os.environ.get("NEXUS_DEBUG", "0") != "1":
# nuitka-project: --python-flag=no_asserts
# nuitka-project: --python-flag=no_docstrings
# nuitka-project: --python-flag=isolated
```

Debug build:
```bash
NEXUS_DEBUG=1 python -m nuitka main.py   # bez python-flag
```

### 3.3 Onefile tempdir spec — szybki start

**Lokalizacja**: `main.py`, `pyproject.toml`, `build_nexus.py`

**Efekt**: Przy kolejnych uruchomieniach Nuitka nie rozpakowuje binary od nowa —
używa cache'owanego katalogu. Zmienne `{CACHE_DIR}`, `{PRODUCT}`, `{VERSION}` są
automatycznie rozwijane przez Nuitka.

```ini
# main.py
# nuitka-project: --onefile-tempdir-spec={CACHE_DIR}/NexusAI/{PRODUCT}/{VERSION}

# pyproject.toml
[tool.nuitka]
onefile-tempdir-spec = "{CACHE_DIR}/NexusAI/{PRODUCT}/{VERSION}"
```

**Przykładowa ścieżka cache**:
- Linux: `~/.cache/NexusAI/NexusAI/2.0.0/`
- Windows: `%LOCALAPPDATA%/NexusAI/NexusAI/2.0.0/`

### 3.4 UPX — kompresja post-build

**Lokalizacja**: `pyproject.toml` (komentarz z instrukcją)

**Efekt**: 30–50% mniejszy plik binarny. UPX to zewnętrzne narzędzie (NIE plugin Nuitka).

```bash
# Instalacja UPX
apt install upx              # Linux
choco install upx            # Windows
brew install upx             # macOS

# Kompresja po buildzie
upx --best --lzma dist/NexusAI
```

**Uwaga**: UPX wydłuża start aplikacji o ~100–200ms (czas dekompresji w pamięci).

### 3.5 Metadata aplikacji

**Lokalizacja**: `main.py`, `pyproject.toml`, `build_nexus.py`

**Efekt**: Profesjonalne właściwości pliku na Windows (wersja, copyright, opis).

```ini
# main.py
# nuitka-project-set: VERSION = __import__("json").load(open("{MAIN_DIRECTORY}/config/version.json"))["version"]
# nuitka-project: --product-name=NexusAI
# nuitka-project: --file-version={VERSION}
# nuitka-project: --copyright="© 2026 NexusAI Team"
# nuitka-project: --file-description="NexusAI — AI-Powered Accounting System"
```

### 3.6 Raport kompilacji

**Lokalizacja**: `main.py` (warunkowo przez `NEXUS_BUILD_REPORT`)

**Efekt**: Generuje szczegółowy raport XML co zostało włączone do builda.

```ini
# main.py
# nuitka-project-if: os.environ.get("NEXUS_BUILD_REPORT", "0") == "1":
# nuitka-project: --report=build/compilation-report.xml
```

```bash
NEXUS_BUILD_REPORT=1 python -m nuitka main.py
```

### 3.7 Wiele rdzeni CPU

**Lokalizacja**: `main.py`, `pyproject.toml`

**Efekt**: Kompilacja na wszystkich dostępnych rdzeniach CPU.

```ini
# main.py / pyproject.toml
jobs = 0    # 0 = wszystkie rdzenie
```

---

## 4. Pluginy Nuitka

**Lokalizacja**: `main.py`, `pyproject.toml`, `build_nexus.py`

NexusAI używa 6 oficjalnych pluginów Nuitka:

| Plugin | Opis | Efekt |
|--------|------|-------|
| `pydantic` | Obsługa Pydantic/SQLModel | Poprawna kompilacja Pydantic v2 |
| `numpy` | Obsługa NumPy | Włączenie numpy w standalone |
| `anti-bloat` | Usuwa zbędny kod z bibliotek | Mniejszy binary (5–10 MB) |
| `mimalloc` | Microsoft mimalloc allocator | 5–15% mniej RAM |
| `multiprocessing` | Procesy potomne | Działa `multiprocessing.Pool` |
| `trio` | Obsługa anyio/trio | Poprawna kompilacja anyio |

```ini
# main.py
# nuitka-project: --enable-plugin=pydantic,numpy,anti-bloat,mimalloc,multiprocessing,trio

# pyproject.toml
[tool.nuitka]
enable-plugin = ["pydantic", "numpy", "anti-bloat", "mimalloc", "multiprocessing", "trio"]
```

---

## 5. Custom User Plugin

**Lokalizacja**: `nexus_ai/build/nuitka_plugins.py`

Własny plugin Nuitka (`NexusAIPlugin`) który rozszerza możliwości kompilacji:

### 5.1 Force compilation (isModnameCompiled)

25 krytycznych modułów wymuszonych do kompilacji C:

```python
FORCE_COMPILED_MODULES = frozenset({
    "nexus_ai.tax.math_engine",   # Matematyka finansowa
    "nexus_ai.tax.rules",         # Silnik reguł podatkowych
    "nexus_ai.services.forex_engine",  # Kursy walut
    "nexus_ai.core.msgspec_utils",     # Serializacja
    "nexus_ai.db.models",              # Modele danych
    # ... łącznie 25 modułów
})
```

### 5.2 Hidden imports (getImplicitImports)

Deklaracje dynamicznych importów które Nuitka nie może wykryć statycznie:

```python
IMPLICIT_IMPORTS = {
    "nexus_ai.core.plugins": [
        "nexus_ai.core.exporters.*",    # System pluginów
    ],
    "nexus_ai.core.tasks": [
        "nexus_ai.services.outbox_relay",  # Taskiq tasks
        "nexus_ai.events.jetstream_bus",   # Event sourcing
    ],
    # ... łącznie ~20 dynamicznych zależności
}
```

### 5.3 Data file inclusion (considerDataFiles)

Pliki konfiguracyjne dołączane do binary:

```python
DATA_FILE_PATTERNS = {
    "nexus_ai.config": ["*.toml", "*.json"],
    "nexus_ai.db.migrations": ["*.py", "*.mako"],
    "nexus_ai.core.integrations.ksef.schema": ["*.xsd"],
}
```

### 5.4 DLL handling (getExtraDlls)

Natywne biblioteki współdzielone:

```python
DLL_MODULES = {
    "llama_cpp": ["libllama.so", "libggml.so"],
    "lxml": ["libxml2.so", "libxslt.so"],
    "PIL": ["libjpeg.so", "libz.so"],
    "pymupdf": ["libmupdf.so"],
}
```

### 5.5 Pre-load code injection (createPreModuleLoadCode)

Kod wstrzykiwany przed załadowaniem modułów:

```python
# Przed nexus_ai.core.config: ustaw zmienne mimalloc
# Przed nexus_ai.core.logger: skonfiguruj poziom logowania
```

### 5.6 Build logging & verification

```python
# onOnefileFinished — zapis build loga do build/plugin-build-log.json
# onStandaloneBinary — weryfikacja rozmiaru i uprawnień binary
# onStandaloneDistributionFinished — sprawdza obecność nexus_crypto w dystrybucji
```

### Włączenie pluginu

```ini
# main.py
# nuitka-project: --user-plugin=nexus_ai/build/nuitka_plugins.py

# build_nexus.py
"--user-plugin=nexus_ai/build/nuitka_plugins.py"
```

Debugowanie pluginu:
```bash
NEXUS_PLUGIN_VERBOSE=1 python -m nuitka main.py
```

---

## 6. Package & Data Inclusion

### 6.1 include-package

**Lokalizacja**: `main.py`, `pyproject.toml`, `build_nexus.py`

**Efekt**: Wszystkie pakiety aplikacji i zależności wkompilowane do binary.

```ini
include-package = [
    "nexus_ai",           # Główny pakiet aplikacji
    "nexus_crypto",       # Rust + PyO3 native extension
    "granian",            # ASGI server (Rust)
    "litestar",           # API framework
    "duckdb",             # OLAP engine
    "polars",             # DataFrame library
    "llama_cpp",          # LLM inference
    "msgspec",            # Serializacja
    "stamina",            # Resilience (retry + CB)
    "anyio",              # Async runtime
    # ... łącznie ~25 pakietów
]
```

### 6.2 include-data-dir

```ini
include-data-dir = [
    "nexus_ai/config/=nexus_ai/config/",
    "nexus_ai/db/migrations/=nexus_ai/db/migrations/",
    "assets/=assets/",
]
```

### 6.3 include-data-files

```ini
include-data-files = [
    "pyproject.toml=pyproject.toml",
    "README.md=README.md",
]
```

---

## 7. Nofollow

**Lokalizacja**: `main.py`, `pyproject.toml`

**Efekt**: Redukcja czasu kompilacji o 15–30% i rozmiaru binary o 5–10 MB.

```ini
nofollow-import-to = [
    "tkinter", "unittest", "distutils", "setuptools",
    "pip", "pdb", "test", "ensurepip", "lib2to3",
    "idlelib", "turtle", "venv", "webbrowser",
    "http.server", "socketserver", "xmlrpc",
    "cgi", "dbm", "msilib", "smtpd", "telnetlib",
    # ... łącznie ~30 modułów
]
```

Zasada: `nofollow-import-to` jest bezpieczniejsze niż `exclude-module` — moduły
mogą być wciąż zaimportowane dynamicznie, ale Nuitka nie marnuje czasu na
ich analizę.

---

## 8. User Package Configuration

**Lokalizacja**: `user.nuitka-package-config.yml`

**Efekt**: Precyzyjna kontrola nad pakietami zewnętrznymi — DLL, nofollow, stdlib flags.

```yaml
# user.nuitka-package-config.yml
- package-name: 'llama_cpp'
  dlls:
    - 'libllama.so'
    - 'libggml.so'
    - 'libggml-cpu.so'
  nofollow:
    - 'llama_cpp.*test*'

- package-name: 'PIL'
  dlls:
    - 'libjpeg.so'
    - 'libpng16.so'
    - 'libtiff.so'
  nofollow:
    - 'PIL.*test*'
```

**Włączenie**:
```bash
python -m nuitka --user-package-configuration-file=user.nuitka-package-config.yml main.py
```

---

## 9. `__compiled__` Guard

**Lokalizacja**: `nexus_ai/tax/math_engine.py`, `nexus_ai/core/__init__.py`, `nexus_ai/tax/__init__.py`

**Efekt**: Kod zachowuje się inaczej gdy jest skompilowany przez Nuitka — szybszy
start, mniejszy binary.

### Wzorzec (standard Nuitka idiom)

```python
try:
    __compiled__  # type: ignore[name-defined]
    _NUITKA_COMPILED: bool = True
except NameError:
    _NUITKA_COMPILED: bool = False
```

### Zastosowanie w projekcie

**`math_engine.py`** — pomija `logger.info()` przy imporcie gdy skompilowany:

```python
try:
    from nexus_crypto._core import TaxMathEngine as _RustTaxMathEngine
    _HAS_NATIVE_RUST = True
    if not _NUITKA_COMPILED:
        logger.info("Rust native loaded")  # Cicho gdy skompilowane
except ImportError:
    if not _NUITKA_COMPILED:
        logger.info("Using Python fallback")
```

**`core/__init__.py`** — pomija cały mechanizm `_safe_import()` (10 optionalnych
importów) gdy skompilowany, importuje tylko 4 znane moduły:

```python
if not _NUITKA_COMPILED:
    # Pełna ścieżka: safe_import dla 10 modułów + init globals
else:
    # Ścieżka skompilowana: tylko mimalloc, crypto, resilience
    # Reszta ustawiona na None
```

---

## 10. PGO (Profile Guided Optimization)

**Lokalizacja**: `.github/workflows/ci.yml` — job `pgo-benchmark`

**Efekt**: 15–40% szybszy kod, szczególnie w pętlach i gorących ścieżkach.

### Proces

1. **Build instrumentowany** (`--pgo`): Nuitka tworzy binary zbierający profile
2. **Uruchomienie**: binary uruchamiany z reprezentatywnymi danymi
3. **Rebuild optymalny**: Nuitka automatycznie używa zebranych profili

```yaml
# CI: tylko dla tagów v*
pgo-benchmark:
    if: startsWith(github.ref, 'refs/tags/v')
    timeout-minutes: 90
    # Step 1: hatch run build:build-nuitka -- --pgo
    # Step 2: uruchom instrumentowany binary
    # Step 3: rebuild bez --pgo
```

**Uwaga**: `--pgo` wymaga GCC (`--clang` nie wspiera PGO).

---

## 11. Clang/Zig

**Lokalizacja**: `nexus_ai/installer/build_scripts/build_exe.sh`, `nexus_ai/installer/build_scripts/build_exe.bat`

**Efekt**: Alternatywne kompilatory C dla mniejszego binary i szybszego linkowania.

```bash
# Użycie Clang (mniejszy binary, lepsze diagnostyki)
./build_exe.sh --use-clang

# Użycie Zig linker (cross-compilation ready)
./build_exe.sh --use-zig

# Windows
build_exe.bat --use-clang
build_exe.bat --use-zig
```

Automatyczna detekcja + graceful fallback:
```bash
if command -v clang &>/dev/null; then
    NUITKA_EXTRA_FLAGS="$NUITKA_EXTRA_FLAGS --clang"
else
    echo "[WARN] Clang not found, using default compiler"
fi
```

---

## 12. mypyc → Nuitka Pipeline

**Lokalizacja**: `.github/workflows/ci.yml` — job `mypyc-compile` + `build-nuitka`

**Efekt**: Kod typowany przez mypy jest kompilowany do `.so` (C extensions),
a Nuitka wkompilowuje te `.so` do finalnego binary — 2–5× szybsze moduły.

### Pipeline

```
1. build-rust → nexus_crypto wheel (.whl)
2. mypyc-compile → skompilowane .so (nexus_ai/tax, core, services, db, events)
     └── upload artifact: mypyc-compiled-so
3. build-nuitka → pobiera .so + Rust wheel → kompiluje Nuitka
     └── prefer-source-code = false (Nuitka używa .so zamiast .py)
```

### Konfiguracja mypyc

```ini
# pyproject.toml
[tool.mypyc]
packages = [
    "nexus_ai/tax",      # Matematyka finansowa → C
    "nexus_ai/core",     # Core utilities → C
    "nexus_ai/services",  # Serwisy → C
    "nexus_ai/db",       # Baza danych → C
    "nexus_ai/events",   # Event sourcing → C
]
exclude = [
    "nexus_ai.core.__init__",  # Dynamiczne importy
    "nexus_ai.core.plugins",    # Dynamiczne ładowanie
    "nexus_ai.core.tasks",      # Taskiq task discovery
]
```

---

## 13. CCache

**Lokalizacja**: `nexus_ai/installer/build_scripts/build_exe.sh`, `nexus_ai/installer/build_scripts/build_exe.bat`, `.github/workflows/ci.yml`

**Efekt**: 10–50× szybsze rebuildy — cache'owanie skompilowanych plików C++.

```bash
# Automatyczna detekcja
if command -v ccache &>/dev/null; then
    export CCACHE_DIR="${CCACHE_DIR:-$HOME/.cache/ccache}"
    export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-5G}"
    mkdir -p "$CCACHE_DIR"
fi

# Podgląd statystyk po buildzie
ccache --show-stats
```

### NUITKA_CACHE_DIR

```bash
export NUITKA_CACHE_DIR="${NUITKA_CACHE_DIR:-$HOME/.cache/nuitka}"
mkdir -p "$NUITKA_CACHE_DIR"
```

---

## 14. Infrastruktura CI/CD

**Lokalizacja**: `.github/workflows/ci.yml`

### Joby związane z Nuitka

| Job | Zależności | Czas | Opis |
|-----|-----------|------|------|
| `build-rust` | — | 20 min | Rust → .whl (ABI3 + strip) |
| `mypyc-compile` | `build-rust` | 10 min | mypyc → .so |
| `pgo-benchmark` | `test-hatch-matrix` + `build-rust` | 90 min | PGO release build (tylko tagi v*) |
| `build-nuitka` | `test-hatch-matrix` + `build-rust` + `mypyc-compile` | 60 min | Finalny binary z .so |

### Dependency graph

```
hatch-ci (lint + typecheck + test)
  ├── test-hatch-matrix (matrix Python 3.13)
  ├── build-rust (Rust → .whl)
  │    ├── mypyc-compile (Python → .so)
  │    │    └── build-nuitka (.so + .whl → .exe)
  │    └── pgo-benchmark (PGO optimized)
  └── release (GitHub Release)
```

### Cache strategy

```
ccache:  ~/.cache/ccache        → hash(pyproject.toml, **/*.py)
NUITKA:  ~/.cache/nuitka        → hash(pyproject.toml)
mypyc:   **/*.so, .mypy_cache/  → hash(pyproject.toml, uv.lock, **/*.py)
hatch:   ~/.hatch/env/virtual   → hash(pyproject.toml)
cargo:   ~/.cargo/registry      → hash(Cargo.lock)
```

---

## 15. Głębokie transformacje architektoniczne

### 15.1 BackgroundTaskManager — CancelScope-based

**Plik**: `nexus_ai/core/background_task_manager.py`

Task metadata jako typowany `msgspec.Struct`:

```python
class TaskMetadata(msgspec.Struct, kw_only=True):
    description: str = ""
    started_at: float = 0.0
    owner: str = ""
    interval_seconds: float = 0.0
```

Structured concurrency z `CancelScope`:
```python
cancel_scope = anyio.CancelScope()
with cancel_scope:
    await coro_fn(*args, **kwargs)  # Task may be cancelled
```

### 15.2 Typed EventBus — msgspec Generic

**Plik**: `nexus_ai/core/bus.py`

Typed subscriptions z `Generic[EventT]`:
```python
EventT = TypeVar("EventT", bound=msgspec.Struct)

class Subscription(Generic[EventT]):
    async def invoke(self, event: EventT) -> None: ...
```

Concurrent dispatch:
```python
async with anyio.create_task_group() as tg:
    for sub in subs:
        tg.start_soon(_dispatch, sub)
```

### 15.3 PluginManager v2 — lifecycle hooks

**Plik**: `nexus_ai/core/plugins.py`

```python
@runtime_checkable
class PluginProtocol(Protocol):
    name: str
    version: str = ""
    description: str = ""

    async def on_startup(self, bus: EventBus) -> None: ...
    async def on_shutdown(self) -> None: ...
    async def on_event(self, event_type: str, payload: Any) -> None: ...
```

---

## 16. Cheatsheet

### Szybki start — build

```bash
# Minimalny build
python -m nuitka main.py

# Build z raportem (debugowanie)
NEXUS_BUILD_REPORT=1 python -m nuitka main.py

# Build debug (bez optymalizacji)
NEXUS_DEBUG=1 python -m nuitka main.py

# Przez hatch (zalecane)
hatch run build:build-nuitka

# Przez build script (z ccache)
./nexus_ai/installer/build_scripts/build_exe.sh
./nexus_ai/installer/build_scripts/build_exe.sh --use-clang
./nexus_ai/installer/build_scripts/build_exe.sh --use-zig

# Build z mypyc
uv run mypyc nexus_ai/tax nexus_ai/core
python -m nuitka main.py   # Nuitka użyje .so

# Build z PGO (tylko GCC)
python -m nuitka --pgo main.py
./main.pgo --help          # Zbierz profile
python -m nuitka main.py   # Rebuild z profilami
```

### Debugowanie

```bash
# Co Nuitka włącza do builda?
NEXUS_BUILD_REPORT=1 python -m nuitka main.py
# → build/compilation-report.xml

# Co custom plugin robi?
NEXUS_PLUGIN_VERBOSE=1 python -m nuitka main.py
# → build/plugin-build-log.json

# Czy kod jest skompilowany?
python -c "try: __compiled__; print('COMPILED'); except NameError: print('INTERPRETED')"
```

### Zmienne środowiskowe

| Zmienna | Domyślnie | Opis |
|---------|-----------|------|
| `NEXUS_DEBUG` | `0` | `=1` wyłącza `python-flag` optymalizacje |
| `NEXUS_BUILD_REPORT` | `0` | `=1` generuje raport XML |
| `NEXUS_PLUGIN_VERBOSE` | `0` | `=1` verbose logging z custom pluginu |
| `NEXUS_LOG_LEVEL` | `INFO` | Poziom logowania |
| `CCACHE_DIR` | `~/.cache/ccache` | Katalog cache ccache |
| `CCACHE_MAXSIZE` | `5G` | Maksymalny rozmiar ccache |
| `NUITKA_CACHE_DIR` | `~/.cache/nuitka` | Katalog cache Nuitka |
| `NUITKA_JOBS` | auto | Liczba rdzeni do kompilacji |

---

*Ostatnia aktualizacja: Czerwiec 2026*
*Dokumentacja wygenerowana przez audyt Nuitka Krok 0*
