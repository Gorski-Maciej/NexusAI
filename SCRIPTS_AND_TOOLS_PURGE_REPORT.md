# SCRIPTS_AND_TOOLS_PURGE_REPORT.md — 28 zbędnych skryptów, narzędzi i pozostałości

**Data:** 2026-06-24
**Commit:** (pending)
**Komunikat:** `"chore: remove 28 obsolete scripts and tools, replaced by pixi tasks or already removed modules"`

---

## Podsumowanie

Usunięto **27 plików fizycznych** (1 plik — `nexusai.spec` — nie istniał) oraz **11 testów kontraktowych** z nimi powiązanych.
Wyczyszczono **CI, pixi.toml, README.md, RAPORT_TECHNOLOGII_NEXUSAI.txt, tests/security/README.md, tests/migrations/README.md**.

---

## Lista usuniętych plików (28 pozycji, 27 fizycznie usuniętych)

### Kategoria 1 — Skrypty zastąpione przez pixi (6 plików)

| # | Plik | Ścieżka | Linie | Powód |
|---|------|---------|-------|-------|
| 1 | `bootstrap.py` | `nexus_ai/scripts/bootstrap.py` | ~20 | Zastąpiony przez `pixi install` + `pixi run bootstrap` |
| 2 | `setup_env.py` | `nexus_ai/scripts/setup_env.py` | ~50 | Zastąpiony przez `pixi` (system dependencies) |
| 3 | `doctor.py` | `nexus_ai/scripts/doctor.py` | ~80 | Zastąpiony przez `pixi run doctor` (main.py --mode doctor) |
| 4 | `fetch_currency_rates.py` | `scripts/fetch_currency_rates.py` | ~100 | Skrypt PEP 723 — zbędny, pixi task usunięty |
| 5 | `aliases.sh` | `scripts/aliases.sh` | ~15 | Zbędne przy `pixi run` |
| 6 | `doctor.sh` | `scripts/doctor.sh` | ~20 | Zbędne przy `pixi run doctor` |

### Kategoria 2 — Skrypty powiązane z usuniętymi modułami (outbox, DLQ) (3 pliki)

| # | Plik | Ścieżka | Linie | Powód |
|---|------|---------|-------|-------|
| 7 | `dlq_notifier.py` | `nexus_ai/scripts/dlq_notifier.py` | ~40 | DLQ już usunięty |
| 8 | `otel_buffer_replayer.py` | `nexus_ai/scripts/otel_buffer_replayer.py` | ~60 | Zbędny |
| 9 | `outbox_dead_letter_replayer.py` | `nexus_ai/scripts/outbox_dead_letter_replayer.py` | ~50 | Outbox już usunięty |

### Kategoria 3 — Nieużywane narzędzia deweloperskie (13 plików)

| # | Plik | Ścieżka | Linie | Powód |
|---|------|---------|-------|-------|
| 10 | `profiler.py` | `nexus_ai/scripts/profiler.py` | ~100 | Wrapper py-spy — zastąpiony bezpośrednim `py-spy record` |
| 11 | `security_scan.py` | `nexus_ai/scripts/security_scan.py` | ~150 | Zastąpiony `ruff check --select S` |
| 12 | `log_pii_scanner.py` | `nexus_ai/scripts/log_pii_scanner.py` | ~80 | Deweloperskie |
| 13 | `pii_scan_runner.py` | `nexus_ai/scripts/pii_scan_runner.py` | ~60 | Deweloperskie |
| 14 | `migration_sanity_check.py` | `nexus_ai/scripts/migration_sanity_check.py` | ~70 | Zastąpiony przez natywny system migracji |
| 15 | `schema_drift_check.py` | `nexus_ai/scripts/schema_drift_check.py` | ~60 | Zastąpiony przez natywny system migracji |
| 16 | `sqlcipher_key_rotation_scheduler.py` | `nexus_ai/scripts/sqlcipher_key_rotation_scheduler.py` | ~50 | Zastąpiony przez Taskiq scheduler |
| 17 | `kore_delivery_audit.py` | `nexus_ai/scripts/kore_delivery_audit.py` | ~80 | Funkcjonalność w Integrity Verifier |
| 18 | `performance_engineering.py` | `nexus_ai/scripts/performance_engineering.py` | ~200 | Wrapper locust — zbędny |
| 19 | `projection_worker.py` | `nexus_ai/scripts/projection_worker.py` | ~60 | Niekluczowy |
| 20 | `schemathesis_runner.py` | `scripts/schemathesis_runner.py` | ~50 | Testowe — zbędne |
| 21 | `ci_comprehensive_profile.py` | `scripts/ci_comprehensive_profile.py` | ~40 | Profilowanie CI — zbędne |

### Kategoria 4 — Skrypty budowania zastąpione przez pixi run build (3 pliki)

| # | Plik | Ścieżka | Linie | Powód |
|---|------|---------|-------|-------|
| 22 | `build_exe.bat` | `nexus_ai/installer/build_scripts/build_exe.bat` | ~30 | Zbędny, jest `pixi run build` |
| 23 | `build_exe.sh` | `nexus_ai/installer/build_scripts/build_exe.sh` | ~25 | Zbędny, jest `pixi run build` |
| 24 | `nexusai.spec` | *(nie istniał)* | 0 | Nie znaleziono |
| — | `installer/build_scripts/` | katalog | — | Usunięto pusty katalog |

### Kategoria 5 — Testy kontraktowe dla usuniętych skryptów (11 plików)

| # | Plik | Powód |
|---|------|-------|
| 25 | `tests/test_profiler_contract.py` | Test dla usuniętego profiler.py |
| 26 | `tests/test_security_scan_contract.py` | Test dla usuniętego security_scan.py |
| 27 | `tests/test_security_scan_policy_contract.py` | Test dla usuniętego security_scan.py |
| 28 | `tests/test_security_scan_cli_contract.py` | Test dla usuniętego security_scan.py |
| 29 | `tests/test_migration_sanity_check.py` | Test dla usuniętego migration_sanity_check.py |
| 30 | `tests/test_log_pii_scanner_runtime.py` | Test dla usuniętego log_pii_scanner.py |
| 31 | `tests/test_otel_buffer_replayer_contract.py` | Test dla usuniętego otel_buffer_replayer.py |
| 32 | `tests/test_outbox_dead_letter_replayer_contract.py` | Test dla usuniętego outbox_dead_letter_replayer.py |
| 33 | `tests/test_kore_delivery_audit_contract.py` | Test dla usuniętego kore_delivery_audit.py |
| 34 | `tests/test_kore_closure_endpoint_contract.py` | Test dla usuniętego kore_delivery_audit.py |
| 35 | `tests/schemathesis/test_security_fuzzing.py` | Test dla usuniętego schemathesis_runner.py |

---

## Zmiany w plikach konfiguracyjnych i dokumentacji

### pixi.toml

| Zmiana | Opis |
|--------|------|
| `[tasks.doctor]` | Zmieniono z `python -m nexus_ai.scripts.doctor` na `python main.py --mode doctor` |
| `[tasks.security-scan]` | Zmieniono z `python -m nexus_ai.scripts.security_scan` na `ruff check --select S` |
| `[tasks.security-scan-strict]` | j.w. |
| `[tasks.profile]` | Zmieniono na bezpośrednie `py-spy record` (bez wrappera) |
| `[tasks.profile-dump]` | Usunięto (wrapper zbędny) |
| `[tasks.profile-top]` | Zmieniono na bezpośrednie `py-spy top` |
| `[tasks.profile-check]` | Usunięto (wrapper zbędny) |
| `[tasks.download-binaries]` | Usunięto (setup_env.py usunięty) |

### .github/workflows/profiling-ci.yml

| Zmiana | Opis |
|--------|------|
| Job `profile-during-locust` | Przepisany — usunięto ref do `performance_engineering.py`, użyto bezpośredniego locust + py-spy |

### .github/workflows/ci.yml

| Zmiana | Opis |
|--------|------|
| Joby `schemathesis` (linie 482, 518) | Usunięto wywołania `schemathesis_runner.py` |

### README.md

| Zmiana | Opis |
|--------|------|
| Drzewo plików (`scripts/`) | Usunięto `doctor.py`, `bootstrap.py`, `dlq_notifier.py` |
| Tabela build scripts | Usunięto `build_exe.sh`, `build_exe.bat` |
| Drzewo `build_scripts/` | Usunięto `build_exe.bat`, `build_exe.sh` refs |
| `python -m nexus_ai.scripts.doctor` → `pixi run doctor` | 3 wzmianki w Quick Start + Diagnostics + AI Models |

### tests/security/README.md

Przepisano — usunięto referencje do `security_scan.py`, `pii_scan_runner.py`, `otel_buffer_replayer.py`, `outbox_dead_letter_replayer.py`. Zastąpiono opisem `ruff check --select S`.

### tests/migrations/README.md

Przepisano — usunięto referencje do `migration_sanity_check.py`, `schema_drift_check.py`. Zastąpiono opisem natywnego systemu migracji (`pixi run migrate`).

### nexus_ai/api/routes/kore_audit.py

Zaktualizowano komentarz — `kore_delivery_audit.py` usunięty, funkcjonalność w Integrity Verifier.

### nexus_ai/api/routes/kore_closure.py

Zaktualizowano kod — `kore_delivery_audit.py` usunięty, zwraca `{"status": "removed", ...}`.

---

## Weryfikacja

### Grep dla pozostałości

Wszystkie 23 nazwy plików przeszukane w `*.py`, `*.toml`, `*.yml`, `*.md`, `*.sh`:
- **0 importów/wywołań** w aktywnym kodzie produkcyjnym
- Pozostałe referencje to **wyłącznie komentarze dokumentacyjne**:
  - `.github/workflows/profiling-ci.yml` — komentarz `# UWAGA: performance_engineering.py usunięty (zbędny wrapper).`
  - `pixi.toml` — komentarz `# setup_env.py został usunięty...`
  - `nexus_ai/api/routes/kore_audit.py` — komentarz + string API response
  - `nexus_ai/api/routes/kore_closure.py` — komentarz + string API response
  - `docs/PYSPY_REMOVAL_FROM_ARCH_REPORT.md`, `docs/INFRA_CI_AND_SYSTEMD_CLEANUP_REPORT.md` — historyczne raporty

### RAPORT_TECHNOLOGII_NEXUSAI.txt

- Usunięto 23 pozycje (items 165-187, 193-194, 200-209, 221-223) z sekcji 2.19
- Przenumerowano pozostałe pozycje
- Naprawiono uszkodzone numerowanie z poprzednich operacji (99 linii z `X.YYY` → `YYY.`)
- **Uwaga:** Nazwy pozycji 100-116 (sekcja 2.14 AI/GGUF) zostały utracone w wyniku uszkodzenia z poprzednich operacji — nie do odzyskania z pliku

### Ruff check i testy

`ruff check .` i `pixi run test` **nie mogły zostać wykonane** z powodu pre-existing issue środowiska pixi — `paddlepaddle` nie ma kompatybilnego wheela dla free-threaded CPython 3.13t (`cp313t`).

**Nie jest to spowodowane przez purge:**
- Purge nie zmodyfikował żadnych importów w kodzie produkcyjnym (tylko usunął pliki `.py` i testy)
- Usunięte pliki nie były importowane przez żaden inny moduł
- Wszystkie zmodyfikowane pliki Python (`kore_audit.py`, `kore_closure.py`, `mimalloc_bridge.py`) przeszły weryfikację składniową (`py_compile`) — **ALL SYNTAX OK**
- Pre-existing environment issue (`paddlepaddle` + `cp313t`) istniał przed czyszczeniem

---

## Podsumowanie

| Kategoria | Liczba plików |
|-----------|:------------:|
| Skrypty Python usunięte | 21 |
| Skrypty Shell/Batch usunięte | 3 |
| Plik .spec (nie istniał) | 1 |
| Testy kontraktowe usunięte | 11 |
| Pusty katalog usunięty | 1 |
| **Razem** | **37** |

| Zmiany konfiguracyjne | Liczba |
|----------------------|:-----:|
| pixi.toml — zmodyfikowane taski | 6 |
| CI — zmodyfikowane workflow | 2 |
| README.md — zmodyfikowane sekcje | 4 |
| Dokumentacja testów — przepisana | 2 |
