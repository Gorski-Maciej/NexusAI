# NexusAI JDG — Narzędzia (Tools)

> **Status:** v8.0 | **Data:** 2026-08-02
> **57 plików .py, ~22,525 linii** — uporządkowane wg kategorii (R15)

---

## Kategorie narzędzi

### 🔧 Core (`core/`) — Główne narzędzia produkcyjne

| Narzędzie | Linii | Opis |
|-----------|:-----:|------|
| `generate_manifest.py` | ~330 | Auto-generuje MANIFEST.md (parser strukturalny v8.0, 100% pokrycia) |
| `validate_rules.py` | ~260 | 9 walidacji jakości/spójności reguł |
| `generate_coverage_report.py` | ~250 | Generuje COVERAGE_REPORT.md (v8.0, fix NameError, wszystkie prefiksy) |
| `generate_missing_rules.py` | ~276 | Masowa generacja reguł mikro z Plan OPA/50 |
| `generate_micro_rules.py` | ~759 | Generator mikro-reguł atomowych |
| `generate_massive_rules.py` | ~1507 | Generator masowy reguł |
| `generate_from_plan50.py` | ~455 | Generator reguł z Planu 50 |
| `generate_test_suite.py` | ~204 | Generator testów |
| `lint_rego_rules.py` | ~463 | Linter składni Rego |
| `isap_crawler.py` | ~624 | Crawler ISAP — aktualizacja podstaw prawnych |
| `llm_bridge.py` | ~796 | Bridge do LLM (C2) |
| `crossref_plan50.py` | ~50 | Cross-referencje Plan 50 |
| `validate_legal_basis.py` | ~50 | Walidacja podstaw prawnych |
| `validate_p24_legal_basis.py` | ~50 | Walidacja P24 podstaw prawnych |

### 📦 Legacy (`legacy/`) — Narzędzia kampanii P11-P24

| Narzędzie | Opis |
|-----------|------|
| `p11_accounting_toolkit.py` | Toolkit PKPiR/księgowość |
| `p12_uor_toolkit.py` | Toolkit UoR (pełna rachunkowość) |
| `p13_crossborder_toolkit.py` | Toolkit cross-border/MDR/Exit Tax |
| `p14_compliance_toolkit.py` | Toolkit RODO/AML/BDO |
| `p15_local_taxes_toolkit.py` | Toolkit podatki lokalne |
| `p15_pcc_local_excise_toolkit.py` | Toolkit PCC/lokalne/akcyza |
| `p16_business_lifecycle_toolkit.py` | Toolkit cykl życia JDG |
| `p17_edge_cases_conflicts_toolkit.py` | Toolkit edge cases i konflikty |
| `p12_uor_accounting_toolkit.py` | Toolkit UoR + rachunkowość |

### 🛠️ ZUS Toolkits

| Narzędzie | Opis |
|-----------|------|
| `zus_atom_linter.py` | Linter atomów ZUS |
| `zus_completeness_engine.py` | Silnik kompletności ZUS |
| `zus_atom_test_matrix.py` | Macierz testowa ZUS |
| `zus_rule_sharding.py` | Sharding reguł ZUS |
| `zus_naming_unifier.py` | Unifikacja nazw ZUS |
| `health_tier_recalculator.py` | Przelicznik progów zdrowotnych |
| `health_reconciliation_micro.py` | Uzgadnianie mikro-zdrowotne |
| `sickness_duration_tracker.py` | Śledzenie czasu choroby |
| `contribution_base_validator.py` | Walidacja podstawy składek |
| `cross_act_zus_checker.py` | Cross-act checker ZUS |
| `preferential_period_tracker.py` | Śledzenie okresów preferencyjnych |

### 🛠️ KKS Toolkits

| Narzędzie | Opis |
|-----------|------|
| `kks_penalty_simulator.py` | Symulator kar KKS |
| `kks_voluntary_disclosure.py` | Czynny żal KKS |
| `kks_limitations_calendar.py` | Kalendarz przedawnień KKS |
| `kks_risk_scorer.py` | Scoring ryzyka KKS |
| `kks_completeness_matrix.py` | Macierz kompletności KKS |
| `p10_kks_micro_toolkit.py` | Toolkit mikro KKS |
| `p10_kks_test_generator.py` | Generator testów KKS |
| `p10_kks_proactive_shield.py` | Proaktywna tarcza KKS |
| `p10_kks_jurisprudence.py` | Orzecznictwo KKS |
| `p10_kks_micro_simulator.py` | Symulator mikro KKS |

### 🧹 One-shot (`one-shot/`) — Jednorazowe fixy/konwersje

| Narzędzie | Opis |
|-----------|------|
| `fix_plan34_duplicates.py` | Fix duplikatów plan34 |
| `fix_hyper_legal_basis.py` | Fix legal_basis w hyper |
| `fix_micro_plan33_legal_basis.py` | Fix legal_basis w micro/plan33 |
| `fix_p06_legal_basis.py` | Fix legal_basis P06 |
| `fix_p07_thresholds.py` | Fix progów P07 |
| `fix_p10_plan33_kks.py` | Fix plan33 KKS |
| `fix_zus_naming.py` | Fix nazw ZUS |
| `dedup_micro_plan33.py` | Deduplikacja micro/plan33 |
| `convert_true_to_conditions.py` | Konwersja true→conditions |
| `debug_converter.py` | Debug konwerter |
| `parse_plan33_and_generate.py` | Parser i generator plan33 |

### 📊 Analityczne

| Narzędzie | Opis |
|-----------|------|
| `temporal_drift_detector.py` | Detektor dryfu temporalnego |
| `rule_impact_simulator.py` | Symulator wpływu reguł |
| `cross_package_conflict_detector.py` | Detektor konfliktów między pakietami |
| `judgment_predictor.py` | Predyktor wyroków (C1) |

---

## Workflow deweloperski

```bash
# 1. Walidacja reguł
python JDG/tools/validate_rules.py --strict

# 2. Generacja manifestu
python JDG/tools/generate_manifest.py --check  # Sprawdź
python JDG/tools/generate_manifest.py          # Generuj

# 3. Raport pokrycia
python JDG/tools/generate_coverage_report.py

# 4. Budowanie bundle
cd JDG/bundles && bash bundle.sh
```

---

*Wygenerowano dla NexusAI JDG Module — 2026-08-02*
*R15: Segregacja core/legacy/one-shot na podstawie RAPORT_P25*
