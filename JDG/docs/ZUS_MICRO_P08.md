# P08 — ZUS/SUS Micro Enterprise (v9.0)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28/29 — 2026-08-22, 14/14 bramek).

Wdrożenie raportu analitycznego **P08_ZUS_Micro.txt** (prompts_glm52/) jako działającego
kodu w silniku OPA/Rego JDG. **Priorytet: audyt zdrowotnej mikro.**

## Pakiet rego: `jdg.p08_zus_micro_innovations`

Plik: `JDG/rules/p08_zus_micro_innovations_v9.rego`

### Sekcje wdrożone jako reguły

| Sekcja promptu | Reguły | Kluczowe parametry |
|---|---|---|
| **1. MAPA POKRYCIA ARTYKUŁÓW SUS** | `zus_coverage_report`, `zus_micro_article_status`, `zus_micro_coverage_summary` | 25 priorytetowych artykułów (SUS sus_a6-sus_a47, zdrowotna h_a79-h_a82, zasiłkowa z_a19-z_a33) — status COMPLETE/PARTIAL/MISSING z `data.jdg.zus_micro_audit` + `gap_pct` |
| **2. ZDROWOTNA MIKRO (PRIORYTET)** | `health_micro_audit`, `zus_health_scale`, `zus_health_linear`, `zus_health_lump`, `zus_health_tax_card`, `lump_tier_auto_recalc` (INN-01), `health_excess_detector` (INN-02) | progi ryczałtowe 60K/300K (60%/100%/180% przeciętnego → 491,40/819,00/1474,20), stawki 9%/4,9%/9%, minimalna 432, korekta roczna (skala), składka od nadwyżki, **silnik auto-przeliczenia progu ryczałtowego** |
| **3. ZASIŁKI MIKRO** | `benefits_micro_audit`, `zus_sickness_benefit`, `waiting_period_calculator` (INN-03) | wyczekiwanie 90 dni, stawki 80%/100%, macierzyński 140 dni (20 tyg.), rehab 90%, limit 85 528, termin wypłaty 30 dni |
| **4. DUPLIKATY I MARTWE REGUŁY** | `zus_stub_duplicate_report`, `stub_deduplicator` (INN-08), `dead_code_detector` (INN-09) | rule_id z `data.jdg.zus_micro_audit` — duplikaty, stuby `{ true }`, plan `MERGE_INTO_HIGHEST_PRIORITY`, detektor dead-code |
| **5. SPÓJNOŚĆ MICRO ↔ MACRO** | `zus_micro_macro_report`, `atomic_concurrent_title_engine` (INN-04) | decyzje macro ZUS (P07: P720-P770) mają atomowe wsparcie (a6-a47); silnik zbiegów na art. 6/9 SUS |
| **6. OPA JAKO SYSTEM** | `zus_micro_pipeline_snapshot`, `temporal_pipeline_hook` (INN-14) | pipeline ingest→generate→verify→emit, thresholdy temporalne (ADR-002 — zero hardcode), hot-reload |
| **7. GENIALNE POMYSŁY (14)** | INN-01..14 | auto-przeliczenie progu ryczałtowego, detektor nadwyżki, kalkulator wyczekiwania, atomowy silnik zbiegów, tracker podstaw 12 mies., symulator zdrowotnej per forma, detektor niekonsekwencji rule_id (`jdg.zus` vs `jdg.micro.sus`), deduplikator, detektor dead-code, monitor limitu zasiłku, kalkulator macierzyńskiego, zbieg z pracą (art. 29), terminy wypłaty (art. 33), hook auto-aktualizacji |
| **8. MAPA DROGOWA** | raport R08 | luki P0/P1/P2 (zdrowotna, zasiłki, spójność rule_id) |

## Narzędzie: `JDG/tools/zus_micro_auditor.py`

CLI audytowe z matematyką mikro ZUS:

```bash
python JDG/tools/zus_micro_auditor.py --audit            # audyt realnych plików mikro
python JDG/tools/zus_micro_auditor.py --health --income 8000 --revenue 100000
python JDG/tools/zus_micro_auditor.py --benefit --base 5204.40 --insured-months 6
python JDG/tools/zus_micro_auditor.py --titles --title etat_jdg
python JDG/tools/zus_micro_auditor.py --pipeline         # migawki 2022-2026
python JDG/tools/zus_micro_auditor.py --check-plan33     # prefiksy rule_id plan33 vs katalogi
```

Funkcje: audyt plików `micro/sus/*.rego` (rule_id `jdg.micro.sus.a{N}.r{M}`),
`micro/zdrowotna/*.rego`, `micro/zasilkowa/*.rego`, `plan33_zus.rego`
(wykrywa niekonsekwencję prefiksu `jdg.zus.*` vs `jdg.micro.*`), kalkulatory
groszowe, silnik zbiegów, pipeline temporalny 2022-2026.

## Okablowanie: `JDG/rules/main_jdg.rego`

- Import: `import data.jdg.p08_zus_micro_innovations` (PAS 18i)
- `_package_decisions["jdg.p08_zus_micro_innovations"] = p08_zus_micro_innovations.decide`
- `final_verdict_p08 = safe_merge(final_verdict_p07, safe_merge(p08_zus_micro_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p07 ma priorytet)

## Testy

- `JDG/tests/rego/test_p08_zus_micro_enterprise.rego` — 14 scenariuszy rego
  (pokrycie, zdrowotna mikro, auto-przeliczenie progu, nadwyżka, zasiłki,
  wyczekiwanie, duplikaty/stuby, micro↔macro, silnik zbiegów, pipeline,
  symulator, niekonsekwencja rule_id, main decide, no_match)
- `JDG/tests/auto/test_p08_zus_micro_enterprise.py` — 16 testów pytest
  (matematyka zdrowotnej 9%/4,9%/progi ryczałtu, zasiłki z podwójnym
  zaokrąglaniem, audyt realnych plików mikro, pokrycie COMPLETE,
  niekonsekwencja plan33, struktura rego, okablowanie, ADR-006, tool smoke)

## Walidacja

- `python -m pytest JDG/tests/auto/test_p0X_*_enterprise.py -q` (P01-P08) — 101/101 przechodzi
- `python -m py_compile JDG/tools/zus_micro_auditor.py` — OK
- Code review — 3 rundy (sprintf verb/typ, prefiksy rule_id, `_derive_prefix` z właściwej puli rule_id plan33, pełna iniekcja danych audytowych)
