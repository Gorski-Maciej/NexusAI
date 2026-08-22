# 🛠️ NexusAI JDG — Katalog Narzędzi (wszystkie pliki w `JDG/tools/`)

> **Dokument:** KATALOG_NARZEDZI.md | **Zakres:** **wszystkie 298 plików `.py`** w `JDG/tools/` (~80 000 linii)
> **Cel:** Ctrl+F po nazwie narzędzia → cel, kategoria i typowe wywołanie. Pełny opis kategorii: [tools/README.md](../tools/README.md).

---

## 🔎 Wyszukiwarka (Ctrl+F)

`narzędzie` · `tool` · `narzędzia` · `auditor` · `toolkit` · `generator` · `linter` · `walidator` · `fix` · `symulator` · `kalkulator` · nazwa dowolnego narzędzia (np. `validate_rules.py`)

---

## 1. Rdzeń produkcyjny (CI / codzienna praca)

| Narzędzie | Linii | Opis |
|---|---:|---|
| `generate_manifest.py` | 359 | ★ generator MANIFEST.md (parser strukturalny v8.0) |
| `generate_coverage_report.py` | 361 | ★ generator COVERAGE_REPORT.md |
| `validate_rules.py` | 326 | ★ 9 walidacji jakości/spójności reguł (`--strict`) |
| `lint_rego_rules.py` | 463 | ★ linter 6-check składni i stylu Rego |
| `tautology_guard.py` | 120 | detektor tautologii (reguły zawsze-true) — CI BLOCKING |
| `dead_rule_detector.py` | 120 | detektor martwych reguł i duplikatów rule_id |
| `else_chain_dead_code_detector.py` | 123 | detektor martwego kodu w else-chainach |
| `cross_package_conflict_detector.py` | 228 | detektor konfliktów między pakietami |
| `initiative_numbering_auditor.py` | 95 | audytor numeracji inicjatyw S1–S24 |
| `cross_ref_validator.py` | 158 | walidator referencji krzyżowych dokumentów |
| `doc_consistency_validator.py` | 150 | walidator spójności dokumentacji z kodem |
| `validate_legal_basis.py` | 203 | walidator podstaw prawnych (`_legal_basis`) |
| `validate_p24_legal_basis.py` | 270 | walidator podstaw prawnych P24 (CI) |
| `rule_provenance_dna.py` | 128 | DNA reguł — proweniencja i pochodzenie |
| `zero_defect_certification.py` | 164 | certyfikacja zero-defect (score ≥ 85%) |
| `self_healing_engine.py` | 134 | silnik auto-naprawy reguł |
| `chaos_engineering.py` | 185 | testy chaosu OPA (odporność na awarie) |
| `hardcoded_audit.py` | 127 | audyt i migracja hardcoded values (B2) |
| `migration_impact_analyzer.py` | 178 | analiza wpływu migracji reguł |
| `rule_impact_simulator.py` | 220 | symulator wpływu zmiany reguły |
| `temporal_drift_detector.py` | 195 | detektor dryfu temporalnego wersji |
| `legal_change_impact_analyzer.py` | 133 | analiza wpływu zmian prawa w czasie rzeczywistym |
| `legal_coverage_heatmap.py` | 282 | heatmap pokrycia prawnego |
| `traceability_matrix.py` | 174 | macierz śledzenia Doc→Rego |
| `api_doc_generator.py` | 173 | auto-generator dokumentacji API (api.md) |
| `enterprise_dashboard.py` | 286 | generator panelu enterprise |
| `adr_auto_proposer.py` | 139 | auto-propozycje ADR |

## 2. Generatory reguł i testów

| Narzędzie | Linii | Opis |
|---|---:|---|
| `generate_micro_rules.py` | 759 | generator mikro-reguł atomowych |
| `generate_massive_rules.py` | 1507 | generator masowy reguł (z Plan OPA) |
| `generate_from_plan50.py` | 455 | generator reguł z Planu OPA 50 |
| `generate_missing_rules.py` | 276 | generator brakujących reguł (checkpoint `chk_`) |
| `generate_test_suite.py` | 280 | generator zestawów testowych |
| `generate_enterprise_tests.py` | 146 | generator testów enterprise |
| `generate_missing_package_tests.py` | 143 | generator testów dla brakujących pakietów |
| `split_micro_tests.py` | 126 | splitter testów mikro |
| `crossref_plan50.py` | 79 | cross-referencje Plan OPA 50 |
| `coverage_95_plan.py` | 170 | plan implementacji pokrycia 95% |
| `parse_plan33_and_generate.py` | 477 | parser Planu 33 + generator mikro-reguł |
| `dedup_micro_plan33.py` | 223 | deduplikator mikro ↔ plan33 (CI) |

## 3. Audytorzy domenowe (`*_auditor.py`)

| Narzędzie | Linii | Opis |
|---|---:|---|
| `vat_micro_auditor.py` | 271 | audytor VAT mikro (P04) |
| `pit_reliefs_optimizer.py` | 270 | optymalizator ulg PIT + audytor (P05) |
| `pit_micro_amortization_auditor.py` | 269 | audytor PIT mikro + amortyzacji (P06) |
| `zus_macro_auditor.py` | 369 | audytor ZUS makro (P07) |
| `zus_micro_auditor.py` | 374 | audytor ZUS mikro (P08) |
| `ksiegowosc_pkpir_uor_auditor.py` | 368 | audytor księgowości PKPiR/UoR (P09) |
| `kks_penalty_auditor.py` | 348 | audytor kar KKS (P10) |
| `ordpu_auditor.py` | 352 | audytor Ordynacji Podatkowej (P11) |
| `crossborder_auditor.py` | 391 | audytor cross-border (P12) |
| `ryczalt_lifecycle_auditor.py` | 393 | audytor ryczałtu/cyklu życia (P13) |
| `pcc_local_excise_auditor.py` | 342 | audytor PCC/lokalne/akcyza (P14) |
| `bdo_environment_auditor.py` | 626 | audytor BDO/środowiska (P15) |
| `rodo_aml_security_auditor.py` | 839 | audytor RODO/AML/bezpieczeństwa (P16) |
| `ksef_jpk_edeklaracje_auditor.py` | 740 | audytor KSeF/JPK/e-Deklaracji (P17) |
| `automatyzacja_ksiegowosci_auditor.py` | 731 | audytor automatyzacji księgowości (P18) |
| `hr_swiadczenia_auditor.py` | 621 | audytor HR/świadczeń (P19) |
| `neural_mesh_innovations_auditor.py` | 636 | audytor neural mesh (P20) |
| `opa_system_auditor.py` | 435 | audytor OPA jako systemu (P21) |
| `validation_tools_auditor.py` | 422 | audytor narzędzi walidacji (P22) |
| `test_rego_ci_auditor.py` | 391 | audytor testów Rego/CI (P23) |
| `audyt_kompletny_auditor.py` | 461 | audytor kompletny (P24) |

## 4. Toolkity domenowe (`*_toolkit.py`)

| Narzędzie | Linii | Opis |
|---|---:|---|
| `p10_kks_micro_toolkit.py` | 826 | toolkit KKS mikro (10 obszarów) |
| `p11_accounting_toolkit.py` | 1161 | toolkit PKPiR/księgowość |
| `p12_uor_toolkit.py` | 317 | toolkit UoR |
| `p12_uor_accounting_toolkit.py` | 442 | toolkit UoR pełna rachunkowość (12 innowacji) |
| `p13_crossborder_toolkit.py` | 241 | toolkit cross-border/MDR/exit tax |
| `p14_compliance_toolkit.py` | 386 | toolkit compliance (RODO/AML/BDO) |
| `p15_local_taxes_toolkit.py` | 709 | toolkit podatki lokalne |
| `p15_pcc_local_excise_toolkit.py` | 688 | toolkit PCC/lokalne/akcyza |
| `p16_business_lifecycle_toolkit.py` | 774 | toolkit cykl życia JDG |
| `p17_edge_cases_conflicts_toolkit.py` | 918 | toolkit edge cases + konflikty (12 innowacji) |

## 5. Toolkity ZUS

| Narzędzie | Linii | Opis |
|---|---:|---|
| `zus_atom_linter.py` | 483 | linter atomów ZUS |
| `zus_completeness_engine.py` | 344 | silnik kompletności ZUS |
| `zus_atom_test_matrix.py` | 320 | macierz testowa atomów ZUS |
| `zus_rule_sharding.py` | 272 | sharding reguł ZUS |
| `zus_naming_unifier.py` | 203 | unifikacja nazewnictwa ZUS |
| `health_tier_recalculator.py` | 299 | przelicznik progów zdrowotnych |
| `health_reconciliation_micro.py` | 313 | uzgadnianie mikro-zdrowotne |
| `sickness_duration_tracker.py` | 314 | śledzenie czasu chorób |
| `contribution_base_validator.py` | 370 | walidator podstawy składek |
| `cross_act_zus_checker.py` | 299 | cross-act checker ZUS |
| `preferential_period_tracker.py` | 314 | tracker okresów preferencyjnych |

## 6. Toolkity KKS

| Narzędzie | Linii | Opis |
|---|---:|---|
| `kks_penalty_simulator.py` | 154 | symulator kar KKS (stawki dzienne, mnożniki) |
| `kks_voluntary_disclosure.py` | 187 | czynny żal (Art. 16) |
| `kks_limitations_calendar.py` | 157 | kalendarz przedawnień (Art. 44) |
| `kks_risk_scorer.py` | 185 | scoring ryzyka KKS |
| `kks_completeness_matrix.py` | 168 | macierz kompletności KKS |
| `p10_kks_test_generator.py` | 228 | generator testów KKS |
| `p10_kks_proactive_shield.py` | 260 | proaktywna tarcza KKS |
| `p10_kks_jurisprudence.py` | 176 | orzecznictwo KKS |
| `p10_kks_micro_simulator.py` | 247 | symulator mikro KKS |

## 7. Narzędzia jednorazowe (fixy, konwersje)

| Narzędzie | Linii | Opis |
|---|---:|---|
| `convert_true_to_conditions.py` | 891 | konwersja `{ true }` → realne warunki |
| `debug_converter.py` | 53 | debug konwertera |
| `fix_plan34_duplicates.py` | 108 | fix duplikatów rule_id w plan34 |
| `fix_plan34_legal_basis.py` | 149 | fix podstaw prawnych plan34 |
| `fix_hyper_legal_basis.py` | 406 | fix podstaw prawnych warstwy hyper |
| `fix_micro_plan33_legal_basis.py` | 286 | fix podstaw prawnych micro/plan33 |
| `fix_p06_legal_basis.py` | 131 | fix P06: puste `_legal_basis` (265 reguł) |
| `fix_p07_thresholds.py` | 66 | fix P07: hardcoded ZUS defaults |
| `fix_p10_plan33_kks.py` | 151 | fix krytycznego buga plan33_kks |
| `fix_zus_naming.py` | 80 | wykonawca unifikacji nazw ZUS |

## 8. Innowacje P28 (AI / kryptografia / analityka)

| Narzędzie | Linii | Opis |
|---|---:|---|
| `self_healing_engine.py` | 134 | (patrz §1) auto-naprawa |
| `federated_tax_mesh.py` | 133 | federacyjna siatka wiedzy podatkowej |
| `ai_augmented_rule_generator.py` | 159 | generator reguł wspomagany AI |
| `legal_change_impact_analyzer.py` | 133 | (patrz §1) |
| `zero_defect_certification.py` | 164 | (patrz §1) |
| `predictive_audit_shield.py` | 159 | predykcyjna tarcza audytowa |
| `quantum_safe_encryption.py` | 136 | kryptografia odporna na kwant |
| `holographic_viz.py` | 171 | holograficzna wizualizacja reguł |
| `autonomous_tax_strategy.py` | 151 | autonomiczna strategia podatkowa |
| `cross_jurisdiction_harmonizer.py` | 130 | harmonizacja między jurysdykcjami |
| `blockchain_audit_trail.py` | 139 | ślad audytowy zakotwiczony w blockchain |
| `digital_twin_simulator.py` | 118 | symulator cyfrowego bliźniaka podatkowego |
| `rule_provenance_dna.py` | 128 | (patrz §1) |
| `dead_rule_detector.py` | 120 | (patrz §1) |
| `adaptive_trust_score.py` | 118 | ML scoring zaufania (Trust Score) |
| `chaos_engineering.py` | 185 | (patrz §1) |

## 9. Monitorowanie prawa i narzędzia pomocnicze

| Narzędzie | Linii | Opis |
|---|---:|---|
| `isap_crawler.py` | 624 | crawler ISAP (codzienny monitoring aktów) |
| `isap_drift_alarm.py` | 214 | alarm dryfu prawnego ISAP |
| `isap_rule_update_pipeline.py` | 210 | pipeline aktualizacji reguł z ISAP |
| `rule_lifecycle_manager.py` | 243 | menedżer cyklu życia reguł (shadow/A-B/rollback) |
| `decision_quality_monitor.py` | 143 | monitor jakości decyzji |
| `limitations_calendar.py` | 126 | kalendarz przedawnień (P02) |
| `vat_gap_detector.py` | 100 | detektor luk VAT |
| `vat_mpp_auto_detector.py` | 190 | auto-detektor MPP (P03 §4 PRIORYTET) |
| `vat_traceability_matrix.py` | 127 | macierz śledzenia VAT |
| `vat_ruleid_migrator.py` | 87 | migrator rule_id VAT |
| `vat_innovation_tools.py` | 242 | narzędzia innowacji VAT |
| `pit_innovation_tools.py` | 708 | narzędzia innowacji PIT |
| `pit_temporal_snapshot_engine.py` | 211 | silnik snapshotów temporalnych PIT |
| `llm_bridge.py` | 799 | most LLM (C2 — wyjaśnienia werdyktów) |
| `judgment_predictor.py` | 759 | predyktor wyroków organów (C1) |

## 10. Podsumowanie

> ⚠️ **Uwaga:** katalog zawiera obecnie **298 plików `.py`** (stan 2026-08-22; kampania GLM 5.2 dodała ~170 narzędzi: audyty ETAP 10–28, bramki raportowe R01–R24, generatory). Poniższe sekcje opisują kategorie rdzenia; pełną listę generuje `ls JDG/tools/*.py` oraz [INWENTARYZACJA_PLIKOW.md](INWENTARYZACJA_PLIKOW.md).

| Kategoria | Narzędzi | Reprezentatywne |
|---|---:|---|
| Rdzeń produkcyjny (CI) | 27+ | validate_rules, generate_manifest, lint_rego |
| Generatory reguł/testów | 12+ | generate_micro_rules, generate_massive_rules |
| Audytorzy domen P02–P24 | 21+ | kks_penalty_auditor, zus_macro_auditor |
| **Audyty ETAP 10–28 (`*_etapNN_audit.py`)** | **17** | policies_mirror_sync_etap26_audit, final_certification_etap28_audit |
| **Bramki raportów GLM52 (`*_gate.py`)** | **37** | vat_core_report02_gate, orchestrator_core_report01_gate |
| Toolkity domenowe | 10+ | p11_accounting_toolkit, p10_kks_micro_toolkit |
| Toolkity ZUS | 11+ | zus_completeness_engine, health_tier_recalculator |
| Toolkity KKS | 9+ | kks_penalty_simulator, kks_voluntary_disclosure |
| Fixy jednorazowe | 10+ | convert_true_to_conditions, fix_* |
| Innowacje P28 | 16+ | self_healing_engine, blockchain_audit_trail |
| Monitoring prawa / pomocnicze | 15+ | isap_crawler, llm_bridge, judgment_predictor |

> 📌 Pełna lista 298 narzędzi: `ls JDG/tools/*.py` — kategorie powyżej są reprezentatywne, nie wyczerpujące.

**Typowe wywołania:**

```bash
# Walidacja + lint + certyfikacja (codzienny cykl)
python JDG/tools/validate_rules.py --strict
python JDG/tools/lint_rego_rules.py --check --strict
python JDG/tools/zero_defect_certification.py

# Manifest + raport pokrycia
python JDG/tools/generate_manifest.py
python JDG/tools/generate_coverage_report.py

# Detekcja problemów
python JDG/tools/tautology_guard.py --strict
python JDG/tools/dead_rule_detector.py
python JDG/tools/cross_package_conflict_detector.py
```

---

*Spójny z: tools/README.md (kategorie core/legacy/one-shot/analytics) · DEVELOPER_GUIDE.md (cykl życia reguły) · LOGIKA_BIZNESOWA.md (debugowanie)*
