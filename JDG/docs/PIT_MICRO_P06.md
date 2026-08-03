# PIT MICRO + AMORTYZACJA ENTERPRISE — P06 v9.0

> Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_PIT_MICRO_AMORTYZACJA (P06) v8.0
> Prompt źródłowy: `prompts_glm52/P06_PIT_Micro.txt`
> Data wdrożenia: 2026-08-02
> Status: ✅ WDROŻONY

## Przegląd

P06 obejmuje **atomową warstwę PIT** (`JDG/rules/micro/pit/pit.rego`, ~22 738
linii, 522 unikalne rule_id) oraz **amortyzację** (art. 22a-22n,
`JDG/rules/micro/amortyzacja/pit_a22a/22i/22k/22n.rego`). GŁÓWNY PRIORYTET
promptu: **AUDYT AMORTYZACJI**. Prompt wymaga raportu analitycznego (Sekcje
1-8); w serii wdrożeniowej P01-P24 **każda sekcja jest implementowana jako
działający kod** (rego + narzędzia + testy + dokumentacja).

## Wdrożone sekcje (jako działający kod)

### Pakiet rego: `jdg.p06_pit_micro_innovations`

Plik: `JDG/rules/p06_pit_micro_innovations_v9.rego`

| Sekcja | Reguły | Opis |
|---|---|---|
| 1. Mapa pokrycia artykułów PIT | `priority_articles_pit`, `pit_article_status()`, `pit_coverage_summary`, `pit_coverage_report` | 33 artykuły priorytetowe (9-45a: przychody 10/13/14, KUP 22-23, dochód 9/24, ulgi 26-26h, skala 27, liniowy 30c, zaliczki 44, zeznanie 45, amortyzacja 22a-22p) ze statusem COMPLETE/PARTIAL/MISSING + `gap_pct` |
| 2. **Audyt amortyzacji (PRIORYTET)** | `kst_groups` (9 grup KŚT), `amortization_calculator`, `amort_schedule`, `kst_rate_verifier`, `one_time_amortization` (art. 22i, 100k EUR), `car_depreciation_audit` (art. 22k, 150k/225k), `individual_rate_audit` (art. 22n, 2× standard), `car_limit`, `small_taxpayer_ok` | Kalkulator pełnej amortyzacji z harmonogramem KŚT, weryfikator błędnych stawek → TRIAGE_QUEUE, jednorazowa 100 000 EUR (mały podatnik/startup), samochody osobowe 150k/225k z nadwyżką nieamortyzowaną, stawki indywidualne max 2× standard |
| 3. Duplikaty/martwe reguły | `pit_stub_rules`, `pit_duplicate_rules`, `pit_dead_rules`, `pit_stub_duplicate_report` | 522 unikalne rule_id, 0 duplikatów, 0 stubów (audyt narzędzia) |
| 4. Spójność micro ↔ macro | `pit_macro_micro_map`, `pit_priority_issues`, `pit_micro_macro_report` | Graf zależności: decyzje macro mają wsparcie atomowe micro; priorytety atomowe (10) < macro (500) |
| 5. Audyt obliczeń | `rounding_ok_pit`, `tax_free_amount`, `combined_income`, `pit_math_audit` | Zaokrąglenia do pełnych złotych (art. 63 Ordynacji), kwota wolna 30k, dochód łączny art. 9 ust. 1a, ulga dla klasy średniej (historyczna 2022) |
| 6. Pipeline auto-generacji | `pit_micro_pipeline` | ingest → generate → verify → emit (ISAP/Dz.U. 2025 poz. 789), weryfikacja semantyczna (stawki KŚT, limity), hot-reload |
| 7. 14 genius ideas | `amortization_calculator` (INN-01), `amort_pit_impact` (INN-02), `pit_advance_optimizer` (INN-03), `pit_lost_relief_detector` (INN-04), `pit_temporal_engine` (INN-05), `kst_rate_verifier` (INN-06), `kst_misclassification` (INN-08), `amort_method_optimizer` (INN-09), `pit_coverage_heatmap` (INN-12), `pit_proof_of_correctness` (INN-14) | Kalkulator pełnej amortyzacji KŚT, symulator wpływu amortyzacji na PIT, auto-optymalizator zaliczek, wykrywacz utraconych ulg, temporalny silnik progów, weryfikator stawek, detektor błędnej klasyfikacji, optymalizator metody |
| 8. Mapa drogowa | `raporty_jdg_enterprise/R06_PIT_Micro.txt` | Luki P0/P1/P2 + estymaty czasu i ryzyka |

### Główny decide

`decide` (priority 700) — raport zbiorczy Sekcji 1-7, `_routing: REPORT`,
`_legal_basis: "P06 Sekcje 1-8 + ustawa o PIT (Dz.U. 2025 poz. 789) +
rozporządzenie KŚT"`. W normalnym ruchu (bez flag `p06_*_check`) zwraca
`no_match` (matched:false).

## Narzędzie: `JDG/tools/pit_micro_amortization_auditor.py`

Audyt realnego `micro/pit/pit.rego` + plików amortyzacji i produkcja JSON
`data.jdg.pit_micro_audit` (wstrzykiwany przez host dla pakietu P06):

```bash
# pełny audyt (JSON na stdout)
python JDG/tools/pit_micro_amortization_auditor.py --audit

# raport tekstowy
python JDG/tools/pit_micro_amortization_auditor.py --table

# harmonogram amortyzacji (grupa KŚT 4 = 14%)
python JDG/tools/pit_micro_amortization_auditor.py --schedule --value 100000 --group 4

# weryfikator stawki KŚT
python JDG/tools/pit_micro_amortization_auditor.py --verify-rate --group 4 --declared 0.20

# zapis JSON do wstrzyknięcia jako data
python JDG/tools/pit_micro_amortization_auditor.py --audit --out /tmp/pit_micro_audit.json
```

Wykrywa: duplikaty rule_id (`jdg.micro.pit.a{N}.r{M}`), stuby `{ true }`,
pokrycie per artykuł priorytetowy, pliki amortyzacji (istnienie + liczba reguł),
harmonogram liniowy (roczna/miesięczna/lata), weryfikację stawek KŚT,
limit jednorazowej art. 22i (100k EUR → 430k PLN przy kursie 4.3).

## Okablowanie: `JDG/rules/main_jdg.rego`

- Import: `import data.jdg.p06_pit_micro_innovations` (PAS 18g)
- `_package_decisions["jdg.p06_pit_micro_innovations"] = p06_pit_micro_innovations.decide`
- `final_verdict_p06 = safe_merge(final_verdict_p05, safe_merge(p06_pit_micro_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p05 ma priorytet)

## Testy

- `JDG/tests/rego/test_p06_pit_micro_enterprise.rego` — 13 scenariuszy rego
  (pokrycie, kalkulator amortyzacji, weryfikator KŚT, jednorazowa 22i,
  samochody 22k, stawki indywidualne 22n, duplikaty, micro↔macro, obliczenia,
  wpływu amortyzacji, główny decide, no_match)
- `JDG/tests/auto/test_p06_pit_micro_enterprise.py` — 13 testów pytest
  (audyt realnego pliku, format rule_id, pokrycie, pliki amortyzacji,
  harmonogram, weryfikator KŚT, limit jednorazowej, priorytety, struktura
  rego, okablowanie, ADR-006)

## Zasady Rego (egzekwowane przez code review serii P01-P06)

- Brak inline `else` w ciałach funkcji/obiektów — else-chain tylko na najwyższym poziomie
- Brak reassignment — idiomatyczne funkcje z else-chain (`kst_rate_for`, `car_limit`)
- Determinizm: brak zależności od kolejności w obiektach; `sort()` tam gdzie wymagane
- Bezpieczne referencje: `object.get(data.jdg, "pit_micro_audit", {})` — brak crashy
- ADR-002: limity amortyzacji z `data.jdg.thresholds.amortization_limits`
- ADR-006: każda decyzja z `_legal_basis`
