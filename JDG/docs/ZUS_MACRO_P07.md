# P07 — ZUS/SUS Macro Enterprise (v9.0)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28/29 — 2026-08-22, 14/14 bramek).

Wdrożenie raportu analitycznego **P07_ZUS_Macro.txt** (prompts_glm52/) jako działającego
kodu w silniku OPA/Rego JDG. **Priorytet: składka zdrowotna.**

## Pakiet rego: `jdg.p07_zus_macro_innovations`

Plik: `JDG/rules/p07_zus_macro_innovations_v9.rego`

### Sekcje wdrożone jako reguły

| Sekcja promptu | Reguły | Kluczowe parametry |
|---|---|---|
| **1. AUDYT SKŁADKI ZDROWOTNEJ (PRIORYTET)** | `health_contribution_audit`, `health_form_matrix`, `health_scale_contribution`, `health_linear_contribution`, `health_lump_contribution`, `health_tax_card_contribution`, `health_annual_reconciliation` | skala 9% od dochodu; liniowy 4,9% (limit odliczenia 14 100); ryczałt 4,9% z 3 progami (≤60K → 491,40; 60-300K → 819,00; >300K → 1474,20); karta 9% od minimalnego (4800) |
| **1a. INN-01..03** | `health_optimizer_realtime`, `health_annual_prediction`, `health_form_change_simulator` | kalkulator realtime (najtańsza forma — deterministyczny `sort`), predykcja roczna, symulator zmiany formy a zdrowotna |
| **2. SKŁADKI SPOŁECZNE** | `social_contribution_audit`, `social_contribution_calculator`, `relief_phase_detector`, `thirtyx_limit_monitor`, `ulga_start_tracker`, `maly_zus_plus_audit`, `preferential_zus_audit` | emerytalna 19,52% / rentowa 8% / chorobowa 2,45% / wypadkowa 1,67% (razem 31,64%); podstawa 5204,40 (60% × 8674); 30-krotność 318 600; ulga na start 6 mies.; MZP 36 mies. (30% min.); preferencyjny 24 mies.; terminy 10/15/20 |
| **3. ZASIŁKI** | `benefits_audit`, `sickness_benefit_calculator`, `sickness_waiting_tracker` | chorobowy 80%/100% (1/30 podstawy), wyczekiwanie 90 dni, macierzyński 140 dni, opiekuńczy 80%, rehabilitacyjny 90%, limit roczny 85 528 |
| **4. PPK/PFRON/FS** | `ppk_pfron_solidarity_audit` | PPK: pracownik 2%, pracodawca 1,5-4%; PFRON: ≥25 etatowych, wskaźnik 6%; FS 1,45% |
| **5. ZBIEGI TYTUŁÓW** | `concurrent_title_engine`, `concurrent_title_matrix`, `etat_jdg_health_only` | etat+JDG / emeryt+JDG / student+JDG / urlop wychowawczy+JDG → z JDG tylko zdrowotna; silnik determinacji obowiązków per zbieg |
| **6. OPA JAKO SYSTEM** | `zus_thresholds_snapshot`, `zus_limit_drift` | thresholdy temporalne (ADR-002 — zero hardcode), migawka 2026 + dryf vs 2025, hot-reload |
| **7. GENIALNE POMYSŁY (15)** | INN-01..15 | kalkulator realtime, predykcja roczna, symulator zmiany formy, monitor 30-krotności, ulga na start, MZP, preferencyjny, wyczekiwanie, zbieg etat+JDG, dryf limitów, kalendarz 10/15/20, detektor błędnych podstaw, symulator 5-letni, optymalizator DRA, kalkulator ZUS+zdrowotna |
| **8. MAPA DROGOWA** | raport R07 | luki P0/P1/P2 (zdrowotna, społeczne, zasiłki, PPK/PFRON) |

## Narzędzie: `JDG/tools/zus_macro_auditor.py`

CLI audytowe z matematyką ZUS:

```bash
python JDG/tools/zus_macro_auditor.py --audit            # audyt realnych plików rego
python JDG/tools/zus_macro_auditor.py --health --income 8000 --revenue 100000
python JDG/tools/zus_macro_auditor.py --social           # składki społeczne
python JDG/tools/zus_macro_auditor.py --benefit --base 5204.40
python JDG/tools/zus_macro_auditor.py --titles --title etat_jdg
python JDG/tools/zus_macro_auditor.py --snapshot         # migawki 2022-2026
python JDG/tools/zus_macro_auditor.py --verify-base --base 1000
```

Funkcje: audyt plików `zus.rego` + `zus/*.rego` (rule_id `jdg.zus.*`, pokrycie artykułów),
kalkulatory groszowe, silnik zbiegów, migawki temporalne 2022-2026.

## Okablowanie: `JDG/rules/main_jdg.rego`

- Import: `import data.jdg.p07_zus_macro_innovations` (PAS 18h)
- `_package_decisions["jdg.p07_zus_macro_innovations"] = p07_zus_macro_innovations.decide`
- `final_verdict_p07 = safe_merge(final_verdict_p06, safe_merge(p07_zus_macro_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p06 ma priorytet)

## Testy

- `JDG/tests/rego/test_p07_zus_macro_enterprise.rego` — 18 scenariuszy rego
  (zdrowotna per forma, kalkulator realtime, predykcja, symulator zmiany formy,
  korekta roczna, społeczne, 30-krotność, ulga na start, MZP, preferencyjny,
  zasiłki, wyczekiwanie, PPK/PFRON, zbiegi, migawka, main decide, no_match)
- `JDG/tests/auto/test_p07_zus_macro_enterprise.py` — 18 testów pytest
  (matematyka zdrowotnej 9%/4,9%/progi ryczałtu, społeczne 31,64%, zasiłki,
  zbiegi, migawki, audyt pliku, struktura rego, okablowanie, ADR-006, tool smoke)

## Walidacja

- `python -m pytest JDG/tests/auto/test_p0X_*_enterprise.py -q` (P01-P07) — wszystkie przechodzą
- `python -m py_compile JDG/tools/zus_macro_auditor.py` — OK
- Code review — 3 rundy (sprintf verb/typ, determinizm rankingu, pełna iniekcja limitów)
