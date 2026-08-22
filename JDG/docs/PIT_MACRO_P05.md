# PIT MACRO ENTERPRISE — P05 v9.0

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28/29 — 2026-08-22, 14/14 bramek).

> Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_PIT_MACRO (P05) v8.0
> Prompt źródłowy: `prompts_glm52/P05_PIT_Macro.txt`
> Data wdrożenia: 2026-08-02
> Status: ✅ WDROŻONY

## Przegląd

P05 obejmuje **warstwę makro PIT** (formy opodatkowania, ulgi, KUP/NKUP,
zaliczki, zwolnienia Art. 21, optymalizacja). GŁÓWNY PRIORYTET promptu:
**ULGI PODATKOWE I OPTYMALIZACJA**. Prompt wymaga raportu analitycznego
(Sekcje 1-8); w serii wdrożeniowej P01-P24 **każda sekcja jest implementowana
jako działający kod** (rego + narzędzia + testy + dokumentacja).

## Wdrożone sekcje (jako działający kod)

### Pakiet rego: `jdg.p05_pit_macro_innovations`

Plik: `JDG/rules/p05_pit_macro_innovations_v9.rego`

| Sekcja | Reguły | Opis |
|---|---|---|
| 1. Formy opodatkowania | `form_audit_report`, `tax_form_change_ok`, `form_change_simulator`, `scale_tax_for()`, `linear_tax_for()`, `recommended_form()` | Skala 12%/32% (próg 120k z `data.jdg.thresholds` — ADR-002), liniowy 19%, warunki zmiany art. 9a, 3-letni symulator zmiany formy |
| 2. **Audyt ulg (PRIORYTET)** | `relief_registry` (8 ulg), `relief_base()`, `relief_eligible()`, `relief_claimed()`, `relief_saving()`, `relief_audit_report`, `unused_relief_detector`, `relief_what_if`, `relief_ranking` | B+R (art. 26e 100-200%), IP Box 5% (art. 30ca), termo 53k (art. 26h — cap w `relief_base`), prototyp 30% (26eb), robotyzacja 50% (26gb), ekspansja 30% (26ec), PIT-0 (art. 21, 85 528 PLN), straty 5 lat/50% (art. 9); symulator "co by było gdyby" + ranking + detektor niewykorzystanych ulg (TRIAGE_QUEUE) |
| 3. KUP/NKUP | `kup_audit_report`, `kup_rate_selected` | Art. 22-23: KUP 20% standard / 50% twórcy (art. 22 ust. 9 pkt 3), moment potrącenia, reprezentacja vs reklama |
| 4. Zaliczki/zeznanie | `advance_audit_report`, `advance_deadline_ok`, `zaliczka_recommendation` | Art. 44 (termin 20. dnia, uproszczone zaliczki 1/12), art. 45 (PIT-36/36L/28), zaokrąglenia (art. 63 Ordynacji) |
| 5. Zwolnienia Art. 21 | `art21_audit_report`, `pit0_categories`, `pit0_category` | Kategorie PIT-0 (młodzi/powrót/4+/emeryci), łączny limit 85 528 PLN, weryfikacja reguł pakietu art21 (29 reguł) |
| 6. Thresholdy temporalne | `pit_thresholds_snapshot`, `relief_limit_drift` | Migawka progów z `data.jdg.thresholds` (ADR-002, hot-reload), detekcja driftu limitów per rok |
| 7. 15+ genius ideas | `zaliczka_recommendation` (INN-03), `ml_advance_contract` (INN-05), `relief_stacking_guard` (INN-06), `pit0_cross_check` (INN-07), `loss_optimizer` (INN-08), `spouse_synergy` (INN-09), `health_contribution_impact` (INN-10), `deadline_radar` (INN-11), `rounding_guard` (INN-12), `annual_return_contract` (INN-13), `relief_limit_drift` (INN-14), INN-15 audit trail | 15 innowacji (3-letni symulator formy, kalkulator ulg realtime, auto-optymalizacja zaliczek, detektor niewykorzystanych ulg, ML predykcja zaliczek, stacking guard, loss optimizer, synergia małżeńska) |
| 8. Mapa drogowa | `raporty_jdg_enterprise/R05_PIT_Macro.txt` | Luki P0/P1/P2 osobno dla: ulgi, formy, KUP, zaliczki, Art. 21 |

### Główny decide

`decide` (priority 700) — raport zbiorczy Sekcji 1-7, `_routing: REPORT`,
`_legal_basis: "P05 Sekcje 1-8 + ustawa o PIT (Dz.U. 2025 poz. 789)"`.
W normalnym ruchu (bez flag `p05_*_check`) zwraca `no_match` (matched:false).

## Narzędzie: `JDG/tools/pit_reliefs_optimizer.py`

```bash
# symulacja "co by było gdyby" (B+R vs IP Box vs termo vs prototyp...)
python JDG/tools/pit_reliefs_optimizer.py --what-if --bases "BR=10000,IP_BOX=50000,THERMO=20000"

# ranking ulg
python JDG/tools/pit_reliefs_optimizer.py --ranking --bases "BR=10000,THERMO=20000"

# detektor niewykorzystanych ulg
python JDG/tools/pit_reliefs_optimizer.py --unused --bases "BR=10000" --claimed "BR"

# symulacja zaliczek (art. 44)
python JDG/tools/pit_reliefs_optimizer.py --advances --prev-year-income 120000 --income 180000

# migawka thresholdów temporalnych (2025 vs 2026)
python JDG/tools/pit_reliefs_optimizer.py --snapshot

# predykcja zaliczek (INN-05 — deterministyczny baseline ML)
python JDG/tools/pit_reliefs_optimizer.py --predict-advances --history 1000,1200,1100,1300
```

Oblicza: `scale_tax()` (12%/32% próg 120k), `linear_tax()` (19%), `relief_saving()`
(cap termo 53k), ranking malejący (deterministyczny tie-break), detektor
niewykorzystanych ulg, symulację zaliczek, różnice migawek temporalnych.

## Okablowanie: `JDG/rules/main_jdg.rego`

- Import: `import data.jdg.p05_pit_macro_innovations` (PAS 18f)
- `_package_decisions["jdg.p05_pit_macro_innovations"] = p05_pit_macro_innovations.decide`
- `final_verdict_p05 = safe_merge(final_verdict_p04, safe_merge(p05_pit_macro_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p04 ma priorytet)

## Testy

- `JDG/tests/rego/test_p05_pit_macro_enterprise.rego` — 12 scenariuszy rego
  (formy, ulgi, KUP, zaliczki, Art. 21, thresholdy, genius ideas, main decide, no_match)
- `JDG/tests/auto/test_p05_pit_macro_enterprise.py` — 14 testów pytest
  (matematyka podatkowa, what-if, ranking, unused detector, zaliczki, migawki,
  predykcja ML, struktura rego, okablowanie, ADR-006)

## Zasady Rego (egzekwowane przez code review serii P01-P05)

- Brak inline `else` w ciałach funkcji/obiektów — else-chain tylko na najwyższym poziomie
- Brak reassignment — idiomatyczne funkcje z else-chain (`scale_tax_for`, `relief_base`)
- Determinizm: `sort()` par `[-saving, id]` zamiast niestabilnego max
- Bezpieczne referencje: `object.get(data.jdg, "thresholds", {})` — brak crashy
- ADR-002: stawki/progi wyłącznie z `data.jdg.thresholds` (zero hardcode)
- ADR-006: każda decyzja z `_legal_basis`
