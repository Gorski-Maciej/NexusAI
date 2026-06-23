# PY-SPY REMOVAL FROM ARCHITECTURE REPORT

**Data:** 23 czerwca 2026
**Autor:** Buffy (AI Agent)

## Cel

Usunięcie `py-spy` jako samodzielnej pozycji z głównej listy technologii architektonicznych i sekcji metryk/monitoringu. `py-spy` to narzędzie deweloperskie (sampling profiler), a nie komponent architektury produkcyjnej.

## Zmodyfikowane pliki (2)

| Plik | Zmiany |
|------|--------|
| `RAPORT_TECHNOLOGII_NEXUSAI.txt` | Usunięto py-spy z sekcji 2.12 (Metryki i Monitoring) i 2.22 (Testowanie); pozycja "Profiling CI (py-spy)" w 2.19 zmieniona na "Profiling CI" z adnotacją o użyciu py-spy; usunięto z sekcji 3 |
| `README.md` | Usunięto py-spy z tabeli Punkt 15 (Testowanie); usunięto z tabeli Punkt 12 (Metryki) |

## Usunięte pozycje

| Sekcja | Pozycja | Typ |
|--------|---------|-----|
| 2.12 Metryki i Monitoring | `py-spy >=0.3.0 [D] — Sampling profiler` | Usunięto całkowicie |
| 2.22 Testowanie | `py-spy >=0.3.0 [D] — Profiler (testy wydajności)` | Usunięto całkowicie |
| 3. Lista wszystkich bibliotek | `• py-spy — Profiler (v0.3.0+)` | Usunięto całkowicie |
| README Punkt 15 | `py-spy — profiler w Rust | cProfile | ✅ | Dev dependency` | Usunięto całkowicie |

## Pozostałe wzmianki (poprawne kontekstowo)

| Lokalizacja | Treść | Uzasadnienie |
|------------|-------|-------------|
| Sekcja 2.19 (CI/CD) | `Profiling CI — Profilowanie wydajności (z użyciem py-spy)` | Narzędzie pomocnicze w CI |
| Sekcja 2.21 (Narzędzia) | `profiler.py [A] — Profilowanie (py-spy wrapper)` | Opis skryptu, nie osobna technologia |
| `.github/workflows/profiling-ci.yml` | Liczne wzmianki | CI workflow — narzędzie, nie technologia |

## Funkcjonalność CI

✅ **Nie naruszona.** `py-spy` pozostaje w `pixi.toml` i `pyproject.toml` jako zależność deweloperska.
✅ Pipeline CI (`profiling-ci.yml`) nie został zmodyfikowany.
✅ Wszystkie skrypty profilujące (`profiler.py`, `performance_engineering.py`) działają bez zmian.

## Status

✅ py-spy nie figuruje jako samodzielna technologia w głównym spisie architektury.
✅ py-spy usunięty z sekcji Metryki i Monitoring.
✅ Wzmianki ograniczone do kontekstu testowania/CI (jako narzędzie pomocnicze).
✅ Funkcjonalność CI i profilowania nie naruszona.
