# NexusAI JDG — Narzędzia (Tools)

> **Status:** v8.4 | **Data:** 2026-09-20
> **1045 plików `.py` = 1033 top-level + 12 w `glm52_v3_campaign/`** (344 rdzeń + 689 `v3_*` kampanii V3; pomiar dyskowy)
> Pełna lista narzędzi: [`docs/KATALOG_NARZEDZI.md`](../docs/KATALOG_NARZEDZI.md) · inwentarz: [`docs/INWENTARYZACJA_PLIKOW.md` §5](../docs/INWENTARYZACJA_PLIKOW.md)

> ⚠️ **Struktura katalogu (truth-first, 2026-09-20):** wszystkie narzędzia leżą **płasko** w `tools/` — jedynym podkatalogiem jest `glm52_v3_campaign/` (generator promptów kampanii V3). Podział R15 na kategorie **core / legacy / one-shot jest logiczny** (na podstawie RAPORT_P25), nie fizyczny — nagłówki poniżej grupują narzędzia tematycznie.

## Kategorie narzędzi

### 🔧 Core — główne narzędzia produkcyjne

| Narzędzie | Linii | Opis |
|-----------|:-----:|------|
| `generate_manifest.py` | 359 | Auto-generuje MANIFEST.md (parser strukturalny v8.0, 100% pokrycia) |
| `validate_rules.py` | 389 | 9 walidacji jakości/spójności reguł (stan 2026-09-20: 72 błędy duplikatów rule_id — patrz DEVELOPER_GUIDE §6) |
| `generate_coverage_report.py` | 361 | ⚠️ legacy — wymaga zarchiwizowanego `Plan OPA/50…` (patrz nota poniżej) |
| `generate_missing_rules.py` | 276 | Masowa generacja reguł mikro z Planu 50 |
| `generate_micro_rules.py` | 759 | Generator mikro-reguł atomowych |
| `generate_massive_rules.py` | 1507 | Generator masowy reguł |
| `generate_from_plan50.py` | 455 | Generator reguł z Planu 50 |
| `generate_test_suite.py` | 280 | Generator testów |
| `lint_rego_rules.py` | 501 | Linter składni Rego (6 checków) |
| `isap_crawler.py` | 624 | Crawler ISAP — aktualizacja podstaw prawnych |
| `llm_bridge.py` | 799 | Bridge do LLM (C2) |
| `crossref_plan50.py` | 79 | Cross-referencje Plan 50 |
| `validate_legal_basis.py` | 203 | Walidacja podstaw prawnych |
| `validate_p24_legal_basis.py` | 270 | Walidacja P24 podstaw prawnych |
| `manifest_v2.py` | — | Generuje `bundles/manifest_v2.json` (indeks testów) |
| `v3_p60_engines.py` | — | Silniki weryfikacji front-matter dokumentacji (np. `I03`) |

### 📦 Legacy — narzędzia kampanii P11–P24 (logiczna kategoria R15)

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

### 🧹 One-shot — jednorazowe fixy/konwersje (logiczna kategoria R15)

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

### 🤖 Kampania V3 (`v3_*.py`, 689 narzędzi)

Silniki kontraktów, bramki statyczne, audyty P00–P68, pętla samouczenia (P67), recertyfikacja (P68), ledger
(`v3_campaign_ledger.py`) oraz dane: `v3_p67_learning_data.json`, `v3_p68_settlement.json`. Status: `python tools/v3_campaign_ledger.py`.

---

> ⚠️ **Generatory legacy (pomiar 2026-09-20):** `generate_coverage_report.py` kończy się `FileNotFoundError`
> (zależność od zarchiwizowanego `Plan OPA/50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md`), a `tools/api_doc_generator.py`
> — `KeyError: 'name'` (parametry obecnego `api/openapi.yaml` bez pola `name`).
> Aktualne metryki: `generate_manifest.py` + `GET /jdg/coverage` + [LEGAL_COVERAGE.md](../docs/LEGAL_COVERAGE.md);
> API: [API_REFERENCJA.md](../docs/API_REFERENCJA.md) + `api/openapi.yaml` (v1.0.0, zgodne).

## 🛡️ Bramki kontraktów kampanii V3 (V3-14…V3-20)

Evidence gates bramkujące wyniki warstw z evidence (`JDG/bundles/*_audit_*.json`);
każdy kontrakt: fail-closed, DECOUPLED, `no_auto_post=true`. Wszystkie 7 bramek istnieje (weryfikacja 2026-09-20):

```bash
python JDG/tools/hyper_quality_v3_14_gate.py --write        # deadlines/limits/kalendarze
python JDG/tools/enterprise_quality_v3_15_gate.py --write   # S1-S24 + Neural Mesh
python JDG/tools/tools_quality_v3_16_gate.py --write        # lintery/walidatory/gap reports
python JDG/tools/tests_ci_quality_v3_17_gate.py --write     # CI/chaos/mutation/golden
python JDG/tools/bundles_quality_v3_18_gate.py --write      # delivery: sign/verify/SBOM/mirror/canary/DR
python JDG/tools/api_ui_quality_v3_19_gate.py --write       # API spec/RBAC/centrum decyzji
python JDG/tools/docs_quality_v3_20_gate.py --write         # Legal Twin/dokumentacja/certyfikacja kampanii
```

## Workflow deweloperski

```bash
# 1. Walidacja reguł (9 walidacji; oczekiwane „Błędów: 0" — patrz nota o 72 duplikatach)
python JDG/tools/validate_rules.py

# 2. Generacja manifestu
python JDG/tools/generate_manifest.py

# 3. Budowanie bundle
cd JDG/bundles && bash bundle.sh

# 4. Bramki kontraktów kampanii V3 (po każdej zmianie w danej warstwie)
python JDG/tools/bundles_quality_v3_18_gate.py --write

# 5. Status kampanii V3
python JDG/tools/v3_campaign_ledger.py
```

---

*Zaktualizowano do stanu dyskowego 2026-09-20 (1045 narzędzi; weryfikacja ścieżek i liczb)*
*R15: kategorie core/legacy/one-shot logiczne (na podstawie RAPORT_P25); struktura fizyczna płaska + `glm52_v3_campaign/`*
