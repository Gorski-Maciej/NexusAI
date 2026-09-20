# VAT MICRO ENTERPRISE — P04 v9.0

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28 — 2026-08-22: 13/14 bramek `NIEPELNY`; domknięcie V4 2026-08-29: `WDROŻONY_100` 6/6).

> Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_VAT_MICRO (P04) v8.0
> Prompt źródłowy: `prompts_glm52/P04_VAT_Micro.txt`
> Data wdrożenia: 2026-08-02
> Status: ✅ WDROŻONY

## Przegląd

P04 obejmuje **atomową warstwę VAT** (`JDG/rules/micro/vat/vat.rego`, ~28 718 linii,
1091 bloków reguł). Prompt wymaga raportu analitycznego (Sekcje 1-8); w serii
wdrożeniowej P01-P24 **każda sekcja jest implementowana jako działający kod**
(rego + narzędzia + testy + dokumentacja), zgodnie z metodą projektu.

## Wdrożone sekcje (jako działający kod)

### Pakiet rego: `jdg.p04_vat_micro_innovations`

Plik: `JDG/rules/p04_vat_micro_innovations_v9.rego`

| Sekcja | Reguły | Opis |
|---|---|---|
| 1. Mapa pokrycia artykułów | `priority_articles`, `article_status()`, `coverage_summary`, `coverage_report` | 52 artykuły priorytetowe (5-14, 15-18, 19a-21, 29a-32, 41-43, 86-96, 106a-106n, 113, 120) ze statusem COMPLETE/PARTIAL/MISSING/DUPLICATE/DEAD + `gap_pct` |
| 2. Audyt duplikatów/martwych reguł | `stub_rules`, `duplicate_rules`, `dead_rules`, `stub_duplicate_report`, `deduplication_plan` | Detektor stubów `{ true }`, duplikatów rule_id, martwych reguł + plan automatycznej deduplikacji (MERGE_INTO_HIGHEST_PRIORITY) |
| 3. Spójność micro ↔ macro | `macro_micro_map`, `priority_coherence_issues`, `micro_macro_report` | Graf zależności: każda decyzja macro ma wsparcie atomowe micro; priorytety atomowe < macro |
| 4. Gwarancje matematyczne | `amount_contract_ok`, `rounding_ok`, `rate_math_ok`, `math_guarantee`, `math_property_contract` | Kontrakt groszowy (netto+VAT=brutto, tol. 0.01), zaokrąglenia position/total, property-based per formuła (F1-F5) |
| 5. Pakiety specjalistyczne | `specialist_packages`, `specialist_actual_rules`, `specialist_gaps`, `specialist_audit` | ksef_micro, margin_scheme_micro, place_of_supply_micro, proportion_vat, wdt_export_import + compliance KSeF 2026 |
| 6. Pipeline auto-generacji | `micro_pipeline_snapshot` | ingest → generate → verify → emit (ISAP/Dz.U. → rego), hot-reload, weryfikacja `opa test` + semantyczna |
| 7. Genius ideas (14) | `auto_generator_ready`, `vector_db_status`, `proof_of_correctness`, `rate_description_mismatch`, `detected_rate`, `self_healing_duplicates`, `novelization_delta`, `semantic_rate_verifier`, `stub_elimination_progress`, `priority_auditor`, `grosz_guard`, `test_generator_ready`, `metadata_autofill`, `dead_else_detected`, `coverage_heatmap` | INN-01..INN-14 — auto-generator z ISAP, wektorowa baza, proof-of-correctness, detektor stawka↔opis, samonaprawa duplikatów, semantic verifier, stub eliminator, grosz guard, generator testów rego, metadata autofill, heatmap |
| 8. Mapa drogowa | `raporty_jdg_enterprise/R04_VAT_Micro.txt` | Luki P0/P1/P2 + estymaty czasu i ryzyka |

### Główny decide

`decide` (priority 700) — raport zbiorczy Sekcji 1-7, `_routing: REPORT`,
`_legal_basis: "P04 Sekcje 1-8 + ustawy o VAT"`. W normalnym ruchu (bez flag
`p04_*_check`) zwraca `no_match` (matched:false, priority 999999).

## Narzędzie: `JDG/tools/vat_micro_auditor.py`

Audyt realnego `micro/vat/vat.rego` i produkcja JSON `data.jdg.vat_micro_audit`
(wstrzykiwany przez host dla pakietu P04):

```bash
# pełny audyt (JSON na stdout)
python JDG/tools/vat_micro_auditor.py --audit

# raport tekstowy
python JDG/tools/vat_micro_auditor.py --table

# property-based sanity per formuła (F1-F5, 1000 iteracji)
python JDG/tools/vat_micro_auditor.py --math --fuzz 1000

# zapis JSON do wstrzyknięcia jako data
python JDG/tools/vat_micro_auditor.py --audit --out /tmp/vat_micro_audit.json
```

Wykrywa: duplikaty rule_id (`jdg.micro.vat.a{article}.r{n}`), stuby `{ true }`,
pokrycie per artykuł priorytetowy, liczbę reguł w pakietach specjalistycznych,
spójność priorytetów micro↔macro, compliance KSeF 2026.

## Okablowanie: `JDG/rules/main_jdg.rego`

- Import: `import data.jdg.p04_vat_micro_innovations` (PAS 18e)
- `_package_decisions["jdg.p04_vat_micro_innovations"] = p04_vat_micro_innovations.decide`
- `final_verdict_p04 = safe_merge(final_verdict_p03, safe_merge(p04_vat_micro_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p03 ma priorytet)

## Testy

- `JDG/tests/rego/test_p04_vat_micro_enterprise.rego` — 10 scenariuszy rego
  (pokrycie, duplikaty, micro↔macro, gwarancje matematyczne, specjaliści,
  rate↔description, główny decide, default no_match)
- `JDG/tests/auto/test_p04_vat_micro_enterprise.py` — 11 testów pytest
  (audyt realnego pliku, format rule_id, pokrycie, specjaliści, priorytety,
  property math, struktura rego, okablowanie, innowacje)

## Zasady Rego (egzekwowane przez code review serii P01-P04)

- Brak inline `else` w ciałach funkcji/obiektów — else-chain tylko na najwyższym poziomie
- Brak reassignment `s := s + N {cond}` — idiomatyczne comprehensions + `sum()`
- Determinizm: `sort()` przed wyborem `[0]`, brak eval-conflictów w kompletnych regułach
- Bezpieczne referencje: `object.get(data.jdg, "vat_micro_audit", {})` — brak crashy przy braku danych
- Brak wzorca zawsze-fałszywego `not object.get(x, k, null)`
