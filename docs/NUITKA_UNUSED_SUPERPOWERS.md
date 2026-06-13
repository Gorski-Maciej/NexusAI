# Niewykorzystane Supermoce Nuitka — NexusAI

> **Krok 2**: Kompletna lista funkcji i możliwości Nuitka, które NIE zostały
> wykorzystane w projekcie, wraz z oceną czy warto je wdrożyć (i dlaczego).

**Data**: Czerwiec 2026
**Aktualny stopień wykorzystania Nuitka**: ~94%

---

## Legenda

| Priorytet | Opis |
|-----------|------|
| 🔴 **High** | Znaczący wpływ na wydajność/bezpieczeństwo/rozmiar — warto wdrożyć |
| 🟡 **Medium** | Umiarkowany wpływ — wdrożyć przy okazji większych zmian |
| 🟢 **Low** | Niski wpływ — tylko jeśli będzie konkretna potrzeba |
| ⚪ **Rejected** | Świadomie odrzucone — nie ma zastosowania w NexusAI |

---

## 1. 🔴 `@final` dekoratory na klasach krytycznych

**Dotyczy**: `nexus_ai/core/bus.py`, `nexus_ai/core/plugins.py`, `nexus_ai/core/background_task_manager.py`

**Efekt**: Pomaga mypyc **zdewirtualizować** wywołania metod — zamiast vtable lookup
(virtual dispatch) kompilator generuje bezpośrednie wywołanie funkcji. Daje 5–15%
przyspieszenia dla gorących ścieżek.

**Obecny stan**:
```python
# bus.py — brak @final
class EventBus: ...  # ← powinno być: @final class EventBus

# plugins.py — brak @final
class PluginManager: ...  # ← powinno być: @final class PluginManager
class PluginInfo: ...     # ← powinno być: @final class PluginInfo

# background_task_manager.py — brak @final
class BackgroundTaskManager: ...  # ← powinno być: @final
class TaskMetadata: ...           # ← powinno być: @final
class TaskInfo: ...               # ← powinno być: @final
```

**Proponowana zmiana**:
```python
from typing import final

@final
class EventBus: ...
```

**Wysiłek**: ~5 minut (dodać `@final` do 6 klas)
**Efekt**: 5–15% szybsze wywołania metod na gorących ścieżkach

---

## 2. 🔴 `tax/__init__.py` — wykorzystaj `_NUITKA_COMPILED`

**Dotyczy**: `nexus_ai/tax/__init__.py`

**Efekt**: Obecnie `_NUITKA_COMPILED` jest zdefiniowane ale **nigdzie nieużywane**.
Można wykorzystać do pominięcia fallback path `from nexus_crypto import ...` gdy
skompilowane — Rust extension jest zawsze dostępny w compiled binary.

**Obecny stan**:
```python
# tax/__init__.py
try:
    __compiled__
    _NUITKA_COMPILED: bool = True
except NameError:
    _NUITKA_COMPILED: bool = False

# ... _NUITKA_COMPILED NIGDZIE NIE UŻYTE
```

**Proponowana zmiana**:
```python
# Zastosuj guard do pominięcia fallback importów gdy compiled
if not _NUITKA_COMPILED:
    from nexus_ai.services.priority_engine import MatchResult, PrioritizedRule
    from nexus_ai.services.rule_store import RuleStore
    from nexus_ai.services.temporal_manager import TemporalRule
```

**Wysiłek**: ~10 minut
**Efekt**: Szybszy start, mniejszy binary przy kompilacji Nuitka

---

## 3. 🟡 CI — Clang build job

**Dotyczy**: `.github/workflows/ci.yml`

**Efekt**: Clang produkuje mniejszy binary (~5–10%) i ma lepsze diagnostyki błędów.
Warto dodać opcjonalny job który testuje build z Clang.

**Obecny stan**: `build-nuitka` używa domyślnego GCC na Linux, MSVC na Windows.

**Proponowana zmiana**:
```yaml
build-nuitka-clang:
    needs: [test-hatch-matrix, build-rust]
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - name: Install Clang
        run: sudo apt-get install -y -qq clang lld
      # ... pozostałe kroki jak build-nuitka
      - name: Build with Clang
        run: hatch run build:build-nuitka -- --clang
```

**Wysiłek**: ~30 minut
**Efekt**: Mniejszy binary, weryfikacja że build działa z Clang

---

## 4. 🟡 `__compiled__` w `tax/rules.py` i `tax/pipeline.py`

**Dotyczy**: `nexus_ai/tax/rules.py`, `nexus_ai/tax/pipeline.py`

**Efekt**: Te pliki mają `logger.info()` przy starcie który można pominąć gdy
skompilowane — tak samo jak w `math_engine.py`.

**Obecny stan**:
```python
# rules.py — brak __compiled__ guard
logger.info("RuleEngine initialised")  # ← loguje nawet przy compiled
```

**Wysiłek**: ~15 minut (2 pliki)
**Efekt**: Nieznacznie szybszy start, mniejszy binary (marginalny, bo to stringi)

---

## 5. 🟢 CI — Clang + LLD (fast linker)

**Dotyczy**: `.github/workflows/ci.yml`

**Efekt**: LLD (LLVM Linker) jest ~5× szybszy niż GNU ld przy linkowaniu.
Razem z Clang daje szybszy build.

**Proponowana zmiana**:
```bash
# Install Clang + LLD
sudo apt-get install -y -qq clang lld

# Build z Clang + LLD
python -m nuitka --clang --scons-flag="-fuse-ld=lld" main.py
```

**Wysiłek**: ~15 minut (rozszerzenie joba Clang)
**Efekt**: Szybszy czas linkowania

---

## 6. 🟢 Multidist — wiele entry points w jednym binary

**Dotyczy**: `main.py`

**Efekt**: Pozwala zbudować jeden binary który może uruchomić wiele entry points
(np. API, worker, CLI) bez osobnych buildów.

**Obecny stan**: Jeden entry point (`main.py`), różne tryby przez `--mode`.

**Proponowana zmiana**:
```ini
# main.py
# nuitka-project: --main=nexus_ai.api.server:run_backend
# nuitka-project: --main=nexus_ai.luz.worker:main
# nuitka-project: --main=nexus_ai.scripts.nexus_cli:main
```

**Wysiłek**: ~30 minut
**Efekt**: Jeden binary, wiele entry points

**Pułapka**: Może powodować konflikty importów między entry points.
Konieczne testy.

---

## 7. 🟢 `--windows-splash-screen` (Windows only)

**Dotyczy**: `main.py` (sekcja `nuitka-project-if: os.name == "nt"`)

**Efekt**: Wyświetla splash screen podczas rozpakowywania onefile binary.
Profesjonalny wygląd dla Windows użytkowników.

**Proponowana zmiana**:
```ini
# nuitka-project-if: os.name == "nt":
# nuitka-project: --windows-splash-screen=assets/splash.png
```

**Wysiłek**: ~5 minut + asset splash.png
**Efekt**: Profesjonalny splash screen na Windows

---

## 8. 🟢 niestandardowe raporty Jinja2

**Dotyczy**: `main.py`

**Efekt**: Niestandardowe szablony raportów kompilacji przez Jinja2.

**Proponowana zmiana**:
```ini
# nuitka-project: --report-template=build/report-template.rst.j2:build/report.rst
```

**Wysiłek**: ~30 minut (template + konfiguracja)
**Efekt**: Czytelniejsze raporty kompilacji

---

## 9. ⚪ ODRZUCONE — `--module` (kompilacja pojedynczego modułu)

**Powód odrzucenia**: NexusAI jest kompilowany jako całość (`--onefile`),
nie jako pojedyncze moduły. `--module` jest przydatne dla bibliotek, nie aplikacji.

---

## 10. ⚪ ODRZUCONE — `--windows-uac-admin`

**Powód odrzucenia**: Aplikacja nie wymaga administratora. Uruchamianie z UAC
byłoby anty-wzorem bezpieczeństwa.

---

## 11. ⚪ ODRZUCONE — `--windows-uac-uiaccess`

**Powód odrzucenia**: Aplikacja nie jest usługą systemową.

---

## 12. ⚪ ODRZUCONE — macOS `.app` bundle

**Powód odrzucenia**: NexusAI nie ma jeszcze macOS jako target platformy.
Gdy będzie, można dodać `macos-create-app-bundle = true`.

---

## 13. ⚪ ODRZUCONE — `--scons-options` (custom CCFLAGS/LDFLAGS)

**Powód odrzucenia**: Obecne ustawienia kompilatora (GCC domyślnie, LTO włączone)
są optymalne. Custom CCFLAGS mogą powodować problemy kompatybilności.

---

## 14. ⚪ ODRZUCONE — skomercjalizowane funkcje Nuitka

Nuitka oferuje w wersji komercyjnej:
- `--onefile-auto-extract` — progresywny extract (szybszy start)
- `--windows-signed` — podpisywanie certyfikatem
- Priorytetowe wsparcie

**Powód odrzucenia**: Wersja darmowa (Nuitka Open Source) wystarcza.
Gdy projekt wejdzie w fazę komercyjną, warto rozważyć Nuitka Commercial.

---

## Podsumowanie — priorytety wdrożenia

| # | Supermoc | Priorytet | Wysiłek | Efekt |
|---|----------|-----------|---------|-------|
| 1 | `@final` na 6 klasach | 🔴 **High** | 5 min | 5–15% szybsze wywołania |
| 2 | Użyj `_NUITKA_COMPILED` w `tax/__init__` | 🔴 **High** | 10 min | Szybszy start |
| 3 | CI Clang job | 🟡 **Medium** | 30 min | Mniejszy binary |
| 4 | `__compiled__` w `rules.py` + `pipeline.py` | 🟡 **Medium** | 15 min | Marginalny |
| 5 | CI Clang + LLD | 🟢 **Low** | 15 min | Szybszy build |
| 6 | Multidist | 🟢 **Low** | 30 min | Wiele entry points |
| 7 | Splash screen (Windows) | 🟢 **Low** | 5 min | UX |
| 8 | Niestandardowe raporty | 🟢 **Low** | 30 min | Debugowanie |
| 9–14 | Odrzucone | ⚪ | — | — |

### Rekomendacja

Wdrożyć **#1 i #2** natychmiast (~15 minut) — to pozostałe 6% z audytu Krok 1.
Reszta (#3–#8) w miarę potrzeb — ich wpływ jest niski, a projekt już osiągnął
**94% wykorzystania** supermocy Nuitka.

---

*Raport wygenerowany: Czerwiec 2026*
*Po wdrożeniu: Faza 1–3, Krok 0 (dokumentacja), Krok 1 (audyt)*
