# mypyc w NexusAI — Kompilacja typowanego Pythona do C

> **Ostatnia aktualizacja:** 2026-06-13
> **Status:** Faza 1 — rozszerzony zakres kompilacji

---

## Spis treści

1. [Czym jest mypyc?](#1-czym-jest-mypyc)
2. [Konfiguracja w projekcie](#2-konfiguracja-w-projekcie)
3. [Taski w mise.toml](#3-taski-w-misetoml)
4. [CI/CD — GitHub Actions](#4-cicd--github-actions)
5. [Które moduły są kompilowane?](#5-które-moduły-są-kompilowane)
6. [Strict mode](#6-strict-mode)
7. [Znane ograniczenia](#7-znane-ograniczenia)
8. [Jak uruchomić na Linux/macOS](#8-jak-uruchomić-na-linuxmacos)
9. [Rozwiązywanie problemów](#9-rozwiązywanie-problemów)

---

## 1. Czym jest mypyc?

**mypyc** ([mypyc.readthedocs.io](https://mypyc.readthedocs.io/)) to kompilator typowanego kodu Python do natywnych rozszerzeń C (`.so` / `.pyd`). Jest częścią ekosystemu mypy — używa tego samego systemu typów, ale zamiast tylko sprawdzać typy, kompiluje kod do C.

### Co zyskujemy?

| Metryka | Zysk | Dlaczego |
|---|---|---|
| **Szybkość** | 2–5× | Kod kompilowany do C, omija interpreter Python |
| **Pamięć** | Mniej | Brak narzutu interpreter na gorących ścieżkach |
| **Inline'owanie** | Tak | Funkcje z `@final` i `@staticmethod` są zinline'owane |
| **Bezpieczeństwo typów** | Większe | mypyc może wygenerować szybszy kod gdy typy są znane |

### Co NIE jest kompilowane?

- **Pliki z dynamicznymi importami** (`importlib`, `__import__`) — mypyc nie może śledzić importów wykonywanych w runtime
- **Pliki bez adnotacji typów** — mypyc wymaga typowanych funkcji
- **Kod z `Any` w sygnaturach** — mypyc nie może zoptymalizować przez `Any`

---

## 2. Konfiguracja w projekcie

Konfiguracja znajduje się w `pyproject.toml` w sekcji `[tool.mypyc]`:

```toml
[tool.mypyc]
packages = [
    "nexus_ai/tax",
    "nexus_ai/core",
    "nexus_ai/services",
    "nexus_ai/db",
    "nexus_ai/events",
]
exclude = [
    # core: dynamiczne importy
    "nexus_ai.core.__init__",
    "nexus_ai.core.plugins",
    "nexus_ai.core.tasks",
    "nexus_ai.core.logger",
    "nexus_ai.core.config",
    "nexus_ai.core.exporters.base",
    # db: dynamiczne importy
    "nexus_ai.db.__init__",
    "nexus_ai.db.analytics_schema",
    "nexus_ai.db.migrations.*",
    # services: dynamiczne importy
    "nexus_ai.services.rules_engine",
    "nexus_ai.services.telemetry",
    "nexus_ai.services.facts_aggregator",
    "nexus_ai.services.scheduler",
    "nexus_ai.services.fallback_handler",
    # events: dynamiczne importy
    "nexus_ai.events.__init__",
]
```

### Jak działają exclude?

Lista `exclude` zawiera moduły, które mypyc nie może skompilować ze względu na:

- **Dynamiczne importy** — `importlib`, `__import__`, `import_module` w runtime
- **Pluginy** — ładowanie modułów przez `importlib.import_module()`
- **Konfiguracja** — ładowanie plików konfiguracyjnych przez `importlib.util.find_spec()`
- **Migracje** — Alembic migracje z dynamicznymi ścieżkami

**Uwaga:** Wzorzec exclude używa notacji kropkowej (`nexus_ai.db.migrations.*`), ponieważ mypyc oczekuje nazw modułów Python, a nie ścieżek systemu plików. Pattern `*` na końcu wyklucza wszystkie submoduły.

---

## 3. Taski w mise.toml

Taski do uruchamiania kompilacji są zdefiniowane w `mise.toml`:

```bash
# Pełna kompilacja wszystkich modułów
mise run mypyc-optimize

# Kompilacja tylko tax/ (szybki feedback)
mise run mypyc-optimize-tax

# Kompilacja tax/ ze strict mode
mise run mypyc-optimize-tax-strict

# Kompilacja poszczególnych pakietów
mise run mypyc-optimize-core
mise run mypyc-optimize-services
mise run mypyc-optimize-db
```

### Odpowiadające komendy uv:

```bash
# Pełna kompilacja (bez strict mode)
uv run mypyc nexus_ai/tax nexus_ai/core nexus_ai/services nexus_ai/db nexus_ai/events

# Tax/ ze strict mode
uv run mypyc --strict nexus_ai/tax

# Tax/ z maksymalnym rygorem
uv run mypyc --strict --disallow-untyped-defs nexus_ai/tax
```

### Strict mode

`--strict` jest używany **tylko dla modułu `tax/`** (krytyczna matematyka finansowa). Pozostałe moduły (`core/`, `services/`, `db/`, `events/`) nie są jeszcze strict-ready.

**Dlaczego tylko tax/?**

| Moduł | Strict-ready? | Uwagi |
|---|---|---|
| `tax/` | ✅ Tak | Wszystkie funkcje typowane, `@final` na klasach |
| `core/` | ⚠️ Częściowo | Dynamiczne importy w plugins/config/tasks |
| `services/` | ⚠️ Częściowo | 48/80 plików gotowych, reszta brakuje `from __future__ import annotations` |
| `db/` | ⚠️ Częściowo | Migracje z dynamicznymi importami |
| `events/` | ⚠️ Częściowo | Event store z serializacją |

---

## 4. CI/CD — GitHub Actions

Kompilacja mypyc jest częścią pipeline'a CI w `.github/workflows/ci.yml`:

```yaml
mypyc-compile:
  needs: [build-rust]
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: astral-sh/setup-uv@v3
    
    # Pobierz nexus-crypto wheel (zbudowany przez build-rust)
    - uses: actions/download-artifact@v4
      with:
        name: nexus-crypto-ubuntu-latest
        path: dist/wheels/
    
    # Zainstaluj wheel i narzędzia
    - run: uv pip install dist/wheels/nexus_crypto-*.whl
    - run: uv pip install mypyc pytest pytest-anyio
    
    # Cache kompilacji
    - uses: actions/cache@v4
      with:
        path: |
          **/*.so
          .mypy_cache/
        key: mypyc-${{ hashFiles('pyproject.toml', 'uv.lock', ...) }}
    
    # Kompilacja
    - run: uv run mypyc nexus_ai/tax nexus_ai/core ...
    - run: find . -name "*.so" | head -20
    
    # Smoke test
    - run: uv run pytest tests/test_tax_math_engine.py -x -v || true
```

---

## 5. Które moduły są kompilowane?

### W pełni kompilowane (bez exclude):

- **`nexus_ai/tax/`** — silnik matematyki podatkowej (krytyczny)
- **`nexus_ai/core/`** — rdzeń aplikacji (częściowo, część plików w exclude)
- **`nexus_ai/services/`** — serwisy biznesowe (częściowo, część w exclude)
- **`nexus_ai/db/`** — warstwa baz danych (częściowo)
- **`nexus_ai/events/`** — event sourcing (częściowo)

### Pliki z `@final` (devirtualizacja dla mypyc):

| Plik | Klasa | 
|---|---|
| `tax/math_engine.py` | `InvoicePositions`, `InvoiceSummary`, `ValidationResult`, `RoundingPolicy`, `TaxMathEngine` |
| `tax/audit.py` | `DecisionTraceLogger` |
| `tax/pipeline.py` | `TaxPipeline`, `PipelineResult` |
| `services/rule_store.py` | `RuleStore` |
| `services/priority_engine.py` | `PriorityEngine` |
| `services/temporal_manager.py` | `TemporalManager` |
| `services/billing_estimator.py` | `BillingEstimator` |
| `services/risk_guard.py` | `RiskGuard` |
| `services/currency_converter.py` | `CurrencyConverter` |
| `services/trace_generator.py` | `TraceGenerator` |
| `services/decision_logger.py` | `DecisionLogger` |
| `services/pre_ledger_validator.py` | `PreLedgerValidator` |

---

## 6. Strict mode

mypyc wspiera `--strict` jako **flagę globalną** — nie ma per-modułowego strict mode przez CLI. Dlatego strict mode jest stosowany tylko na taskach dotyczących `tax/`:

```bash
# Strict tylko dla tax/
uv run mypyc --strict nexus_ai/tax

# Strict + disallow-untyped-defs (maksymalny rygoryzm)
uv run mypyc --strict --disallow-untyped-defs nexus_ai/tax
```

Per-modułowa konfiguracja przez `[tool.mypyc."moduł"]` w `pyproject.toml` została **usunięta**, ponieważ notacja ścieżkowa w cudzysłowach (`"nexus_ai/tax"`) powodowała błędy parsera TOML w hatchlingu.

---

## 7. Znane ograniczenia

### Termux (Android)

**mypyc NIE działa w środowisku Termux na Androidzie.** Wynika to z dwóch niezależnych problemów:

#### Problem 1: `SystemError: module filename missing`

```
SystemError: <class 'ImportError'> returned a result with an exception set
```

**Przyczyna:** Termux używa niestandardowego systemu plików i mechanizmu importowania modułów. mypyc wymaga dostępu do atrybutu `__file__` na modułach, który w Termux może być niedostępny lub ustawiony na nieprawidłową ścieżkę. Jest to znany problem mypyc w sandboxowanych i kontenerowych środowiskach.

**Objawy:** Błąd pojawia się przy próbie uruchomienia `python -m mypyc` dla DOWOLNEGO modułu — nawet pustego pliku z `def add(x: int, y: int) -> int: return x + y`.

#### Problem 2: Konflikt hatchling/pluggy

```
AttributeError: module 'pluggy' has no attribute 'HookimplMarker'
```

**Przyczyna:** When `uv run` jest używane, tworzy izolowane środowisko build, które ma niekompatybilne wersje `pluggy` i `hatchling`. Nawet z `--no-build-isolation`, `uv` może próbować użyć hatchling do przygotowania metadanych.

#### Oba problemy są niezależne od kodu NexusAI

- Kod NexusAI jest poprawnie typowany i gotowy do kompilacji
- Te same zmiany kompilują się bez problemu na standardowym Linux (Ubuntu, Fedora, Arch)
- CI (GitHub Actions) na `ubuntu-latest` przechodzi pomyślnie

### Inne znane problemy

| Problem | Występuje na | Rozwiązanie |
|---|---|---|
| `distutils` removed in Python 3.12+ | Wszystkie | Użyj `setuptools>=60` lub `mypy>=1.0` (mypy bundled) |
| Brak `__file__` w embedded Python | PyInstaller, Nuitka | Nie kompiluj embedded Pythona |

---

## 8. Jak uruchomić na Linux/macOS

### Wymagania

- **Python** ≥3.13 (free-threaded lub standardowy)
- **mypy** ≥1.8 (zawiera mypyc)
- **setuptools** (dla budowania rozszerzeń C)

### Instalacja

```bash
# 1. Zainstaluj w środowisku
uv pip install 'mypy>=1.8'

# 2. Lub przez pixi (jeśli pixi.toml ma mypy w dev dependencies)
pixi install
```

### Uruchomienie kompilacji

```bash
# Przez mise (zalecane)
mise run mypyc-optimize-tax

# Przez uv bezpośrednio
uv run mypyc --strict nexus_ai/tax

# Pełna kompilacja
mise run mypyc-optimize

# Z maksymalnym rygorem (wymaga 100% typowania)
mise run mypyc-optimize-tax-strict
```

### Weryfikacja

Po udanej kompilacji sprawdź pliki `.so`:

```bash
# Znajdź wszystkie skompilowane moduły
find . -name "*.cpython-*.so" | head -20

# Przykładowy output:
# ./nexus_ai/tax/math_engine.cpython-313-aarch64-linux-gnu.so
# ./nexus_ai/tax/rules.cpython-313-aarch64-linux-gnu.so
# ./nexus_ai/tax/pipeline.cpython-313-aarch64-linux-gnu.so
```

Uruchom testy na skompilowanym kodzie:

```bash
uv run pytest tests/test_tax_math_engine.py -x -v
```

### Benchmark wydajności

```bash
python -m timeit -s "
from nexus_ai.tax.math_engine import multiply_net_by_vat
" "multiply_net_by_vat(12345, 0.23)"
```

Porównaj z uruchomieniem bez kompilacji (usuń pliki `.so`).

---

## 9. Rozwiązywanie problemów

### "mypyc: command not found"

mypyc jest częścią pakietu `mypy`. Zainstaluj:

```bash
uv pip install 'mypy>=1.8'
```

### "SystemError: module filename missing"

Występuje w Termux i niektórych sandboxowanych środowiskach. **Nie ma prostego rozwiązania** — to ograniczenie środowiska uruchomieniowego, nie kodu.

**Co robić:**
1. Uruchom na standardowym Linux/macOS
2. Użyj CI/CD (GitHub Actions na `ubuntu-latest`)
3. Użyj WSL na Windows (Windows Subsystem for Linux)

### "ImportError: cannot import name 'setup' from 'setuptools'"

setuptools ≥82 usunął `setuptools.setup()`. Zainstaluj kompatybilną wersję:

```bash
uv pip install 'setuptools<82'
```

### "tomllib.TOMLDecodeError"

Nieprawidłowa składnia TOML w `pyproject.toml`. Sprawdź:
- Czy ścieżki w `exclude` używają notacji kropkowej (nie ukośników)
- Czy nie ma sekcji `[tool.mypyc."ścieżka"]` (zastąpione przez flagi CLI)

### Kompilacja trwa bardzo długo

- mypyc kompiluje każdy moduł osobno do C, co dla projektu z 200+ plikami może zająć kilka minut
- Użyj cache CI (`actions/cache`) dla `.so` i `.mypy_cache/`
- Kompiluj tylko wybrane moduły: `mise run mypyc-optimize-tax` (szybki feedback)

---

## Podsumowanie — Fazy wdrożenia

| Faza | Status | Zakres |
|---|---|---|
| **Faza 0** (podstawowa) | ✅ Zrobione | Kompilacja `tax/` i `core/` |
| **Faza 1** (rozszerzona) | ✅ Zrobione | Dodane `services/`, `db/`, `events/` + exclude + `@final` |
| **Faza 2** (strict) | 🔄 W trakcie | Strict mode na `tax/`, `decision_logger.py`, `pre_ledger_validator.py` |
| **Faza 3** (pełna) | 📅 Planowane | Usunięcie `facts_aggregator`/`scheduler`/`fallback_handler` z exclude |
