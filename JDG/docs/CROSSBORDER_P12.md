# P12 — Cross-Border / MDR / TP / CFC / FX (Enterprise)

> Wdrożenie raportu analitycznego **P12_CrossBorder_MDR_TP_CFC_FX.txt** (v8.0)
> jako działający pakiet rego + narzędzie audytowe + testy + dokumentacja.
> **Priorytet: miejsce świadczenia B2B/B2C (art. 28a-28o VAT) i MDR/DAC6.**

## Pakiet rego

**Plik:** `JDG/rules/p12_crossborder_innovations_v9.rego`
**Pakiet:** `jdg.p12_crossborder_innovations`
**Okablowanie:** `main_jdg.rego` — import PAS 18m + `_package_decisions` + `final_verdict_p12`

### Sekcje wdrożone jako reguły

| Sekcja | Reguły | Kluczowe elementy |
|---|---|---|
| **1. Mapa pokrycia** | `crossborder_coverage_report` | 12 artykułów priorytetowych (a20, a23o, a23zf, a29, a30da, a30f, a86r + luki a25b/a25c/a25d/a86o/a24c), status z `data.jdg.crossborder_audit`, gap_pct |
| **1. WNT/WDT/eksport/import** | `wnt_wdt_audit` | WNT 23% (odliczenie), WDT 0% (dowód wywozu 30 dni), eksport/import, art. 9-13 VAT |
| **2. MIEJSCE ŚWIADCZENIA ★** | `place_of_supply_audit`, `place_of_supply_calculator` (INN-01) | art. 28a-28o: B2B — siedziba nabywcy, B2C — siedziba usługodawcy, nieruchomości, transport, e-usługi (OSS), platformy (art. 28m) |
| **3. MDR/DAC6** | `mdr_audit`, `mdr_auto_detector` (INN-02) | hallmarks A-E, terminy 30 dni, formularz MDR-1, sankcje art. 80f KKS |
| **4. TP/CFC/rezydencja/FX** | `tp_cfc_residency_audit`, `residency_decision_engine` (INN-03) | TP 500k/200M, CFC 50%/33%/14,25%, rezydencja 183 dni, metody FX |
| **5. ViDA/DRR/DAC8/exit tax** | `vida_dac8_exit_tax_audit`, `exit_tax_calculator` (INN-10) | ViDA 2025-2030, DAC8 (krypto), exit tax 4M/19% (art. 30da-30db) |
| **6. OPA jako system** | `crossborder_pipeline_snapshot` | pipeline ingest→generate→verify→emit (ADR-002, hot-reload) |
| **7. Genius ideas (12)** | INN-01..INN-12 | kalkulator miejsca świadczenia, detektor MDR, silnik rezydencji, tracker WDT, kalkulator TP, generator raportu MDR, kalkulator FX, kalkulator CFC, monitor UE (Brexit), kalkulator exit tax, hook szablonów, panel compliance |

### Progi ustawowe (ADR-002 — zero hardcode)

Wszystkie progi czytane z `data.jdg.thresholds.crossborder`:
`wdt_documentation_days: 30` · `mdr_deadline_days: 30` · `exit_tax_threshold_pln: 4 000 000` · `exit_tax_rate_pct: 19` · `cfc_ownership_min_pct: 50` · `cfc_passive_income_pct: 33` · `cfc_tax_rate_threshold_pct: 14,25` · `tp_local_file_pln: 500 000` · `tp_master_file_pln: 200 000 000` · `residency_days: 183`

## Narzędzie

**Plik:** `JDG/tools/crossborder_auditor.py`

- `--audit` — audyt realnych plików: `micro/crossborder/crossborder.rego` (5 319 linii, **193 rule_id**), `micro/plan33_cb.rego` (21 rule_id); pokrycie 12 artykułów priorytetowych, duplikaty, stuby
- `--place-supply` — auto-kalkulator miejsca świadczenia (art. 28a-28o)
- `--mdr` — auto-detektor schematów MDR/DAC6 (hallmarks A-E)
- `--residency` — silnik decyzji rezydencji (183 dni / centrum interesów)
- `--tp` — kalkulator dokumentacji TP (500k/200M)
- `--cfc` — kalkulator CFC (50%/33%/14,25%)
- `--fx` — kalkulator różnic kursowych (metoda podatkowa art. 24c)
- `--exit-tax` — kalkulator exit tax (4M/19%)
- `--wdt` — tracker dokumentów WDT (30 dni)
- `--compliance` — panel ryzyka transgranicznego (score)
- `--table` / `--out FILE`

## Testy

- `JDG/tests/rego/test_p12_crossborder_enterprise.rego` — 21 scenariuszy rego
- `JDG/tests/auto/test_p12_crossborder_enterprise.py` — 24 testy pytest (narzędzia, audyt realnych plików, struktura, okablowanie, smoke CLI)

## Mapa drogowa (luki P0/P1/P2)

Wykryte przez realny audyt narzędzia:

| Luka | Priorytet | Opis |
|---|---|---|
| `a86o` (MDR) | **P0** | Brak reguł micro MDR/DAC6 (OrdPU art. 86a-86o) — tylko pakiet `mdr/` enterprise |
| `a24c` (FX) | **P0** | Brak reguł micro różnic kursowych — tylko kalkulator enterprise (metoda podatkowa) |
| `a25b/a25c/a25d` | **P1** | Brak reguł micro (transakcje łańcuchowe / dostawy) |
| Integracja ViDA/DRR | **P1** | Monitoring etapów implementacji 2025-2030 |
| `plan33_cb` duplikaty | **P2** | 21 rule_id w plan33 — weryfikacja spójności z micro |

## Raport

`raporty_jdg_enterprise/R12_CrossBorder_MDR_TP_CFC_FX.txt` — pełny raport wdrożenia P12.
