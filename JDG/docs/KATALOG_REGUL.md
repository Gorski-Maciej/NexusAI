<!--
artifacts: [docs/KATALOG_REGUL.md, rules/, bundles/rule_registry.json]
status: ACTIVE
owner: docs
verified: 2026-09-13
verify_cmd: python3 tools/manifest_v2.py --json
-->

# 📚 NexusAI JDG — Katalog Pakietów Reguł (wszystkie pliki Rego)

> **Dokument:** KATALOG_REGUL.md | **Zakres:** **każdy plik `.rego`** w `JDG/rules/` (535, żywy skan P60) oraz `policies/` (615 plików, żywy skan P60)
> **Dane:** ekstrakcja statyczna (package, bloki `matched:true`, unikalne `rule_id`); liczby kanoniczne (M1/M2) w [MANIFEST.md](../MANIFEST.md)
> **Cel:** Ctrl+F po nazwie pliku, pakiecie lub domenie → od razu wiesz, ile reguł zawiera i gdzie szukać.

---

## 🔎 Wyszukiwarka (Ctrl+F)

`katalog` · `pakiet` · `package` · `pliki rego` · `rego` · `rule_id` · `matched` · `jdg.*` · `tax.*` · nazwa dowolnego pliku (np. `substantive.rego`, `kks.rego`, `plan45`, `_enterprise`)

**Legenda:** kolumna **R** = bloki `matched:true`; kolumna **ID** = unikalne `rule_id` w pliku (wartości przybliżone — licznik linii).

---

## 1. Rdzeń i orkiestracja (`JDG/rules/` — katalog główny)

| Plik | Pakiet | R | ID | Rola |
|---|---|---|---|---|
| `main_jdg.rego` | `jdg.main` | 0 | 0 | 🧠 orkiestrator Multi-Pass + Sharded Router (final_verdict_p26..p34 + final_verdict_enforced) |
| `_helpers_jdg.rego` | `jdg.helpers` | 0 | 0 | helpery (thresholds, FC, MPP) |
| `_metadata_jdg.rego` | `jdg.metadata` | 0 | 0 | metadane reguł (severity, remediacja) |
| `thresholds_jdg.rego` | `jdg.thresholds` | 0 | 0 | definicje progów JDG |
| `_pkpir_rates.rego` | `jdg.pkpir_rates` | 0 | 0 | stawki PKPiR |
| `_uor_rates.rego` | `jdg.uor_rates` | 0 | 0 | stawki UoR |
| `_crossborder_rates.rego` | `jdg.crossborder_rates` | 0 | 0 | stawki cross-border |
| `_compliance_rates.rego` | `jdg.compliance_rates` | 0 | 0 | stawki compliance |
| `_kks_macro_rates.rego` | `jdg.kks.rates` | 0 | 0 | stawki KKS macro (plik w `kks/`) |
| `_kks_micro_rates.rego` | `jdg.micro.kks_rates` | 0 | 0 | stawki KKS micro |
| `_pcc_local_excise_rates.rego` | `jdg.pcc_local_excise_rates` | 0 | 0 | stawki PCC/lokalne/akcyza |
| `_business_lifecycle_rates.rego` | `jdg.business_lifecycle_rates` | 0 | 0 | stawki cyklu życia |
| `_edge_cases_conflicts_rates.rego` | `jdg.edge_cases_conflicts_rates` | 0 | 0 | stawki edge cases/konflikty |
| `provenance.rego` | `jdg.provenance` | 2 | 0 | enrich_verdict → _provenance_tree, decision_hash |
| `fallback.rego` | `jdg.fallback` | 0 | 3 | ostatnia deska ratunku (no_match) |

### Pakiety decyzyjne rdzenia (PASS 0–8)

| Plik | Pakiet | R | ID | Rola |
|---|---|---|---|---|
| `risk.rego` | `jdg.risk` | 17 | 18 | PASS 0: ryzyko/fraud/GAAR |
| `routing.rego` | `jdg.routing` | 5 | 6 | PASS 1: routing wg confidence |
| `compliance.rego` | `jdg.compliance` | 10 | 13 | PASS 2: Biała Lista/MPP |
| `kks.rego` | `jdg.kks` | 255 | 256 | KKS Art. 54–83 |
| `crossborder.rego` | `jdg.crossborder` | 31 | 32 | PASS 3: WNT/WDT/import |
| `vat/substantive.rego` | `jdg.vat.substantive` | 61 | 62 | PASS 4: stawki VAT |
| `pit/forms.rego` | `jdg.pit.forms` | 19 | 20 | PASS 5: forma PIT |
| `pit/kup.rego` | `jdg.pit.kup` | 14 | 15 | KUP/NKUP |
| `allowances.rego` | `jdg.allowances` | 18 | 22 | PASS 6: ulgi |
| `accounting.rego` | `jdg.accounting` | 74 | 74 | PASS 7: PKPiR/księgowość |
| `zus.rego` | `jdg.zus` | 23 | 28 | PASS 8: składki (immutable) |
| `business.rego` | `jdg.business` | 23 | 24 | cykl życia JDG |
| `conflicts.rego` | `jdg.conflicts` | 27 | 28 | POST-MERGE: konflikty domen |
| `edge_cases.rego` | `jdg.edge_cases` | 187 | 188 | przypadki brzegowe |
| `validation.rego` | `jdg.validation` | 8 | 9 | walidacja wejścia |
| `temporal.rego` | `jdg.temporal` | 23 | 24 | temporalność (valid_from/to) |
| `api_fallback.rego` | `jdg.api_fallback` | 6 | 7 | fallback API zewnętrznych |

### Pozostałe pakiety rdzenia

| Plik | Pakiet | R | ID |
|---|---|---|---|
| `allowances/plan23_reliefs.rego` | `jdg.allowances` | 9 | 10 |
| `corrections.rego` | `jdg.corrections` | 19 | 20 |
| `liability.rego` | `jdg.liability` | 15 | 15 |
| `representation.rego` | `jdg.representation` | 9 | 10 |
| `representation/plan26_prokura.rego` | `jdg.representation` | 5 | 5 |
| `restructuring.rego` | `jdg.restructuring` | 12 | 13 |
| `retention.rego` | `jdg.retention` | 13 | 14 |
| `rodo.rego` | `jdg.rodo` | 12 | 13 |
| `rodo_extended.rego` | `jdg.rodo_extended` | 17 | 18 |
| `rodo/plan42_rodo.rego` | `jdg.rodo` | 3 | 4 |
| `mpips.rego` | `jdg.mpips` | 12 | 13 |
| `employer.rego` | `jdg.employer` | 27 | 26 |
| `environmental.rego` | `jdg.environmental` | 14 | 15 |
| `environmental/bdo_enterprise.rego` | `jdg.environmental.bdo` | 23 | 24 |
| `compliance/aml_enterprise.rego` | `jdg.compliance.aml` | 23 | 24 |
| `digital.rego` | `jdg.digital` | 6 | 7 |
| `international.rego` | `jdg.international` | 16 | 17 |
| `international_expanded.rego` | `jdg.international` | 23 | 24 |
| `local_taxes.rego` | `jdg.local_taxes` | 27 | 28 |
| `ksef_jpk.rego` | `jdg.ksef_jpk` | 10 | 11 |
| `jpk_cit.rego` | `jdg.jpk_cit` | 4 | 5 |
| `jpk/plan26_deadlines.rego` | `jdg.jpk` | 1 | 2 |
| `statute_of_limitations.rego` | `jdg.limitations` | 18 | 17 |
| `statute/plan26_detailed.rego` | `jdg.statute` | 9 | 10 |
| `risk/plan26_kks.rego` | `jdg.risk` | 4 | 5 |

---

## 2. Inicjatywy Enterprise S1–S24 (pliki `*_enterprise.rego`)

| Plik | Pakiet | R | ID | Inicjatywa |
|---|---|---|---|---|
| `tax_optimization_enterprise.rego` | `jdg.tax_optimization` | 10 | 11 | S1 |
| `cross_domain_intelligence_enterprise.rego` | `jdg.cross_domain_hub` | 15 | 16 | S2 |
| `judicial_interpretations_enterprise.rego` | `jdg.judicial_rulings` | 5 | 6 | S3 |
| `audit_defense_enterprise.rego` | `jdg.audit_defense` | 4 | 5 | S4 |
| `strategic_advisor_enterprise.rego` | `jdg.strategic_advisor` | 8 | 9 | S5 |
| `ksef_resilience_enterprise.rego` | `jdg.ksef_resilience` | 7 | 8 | S6 |
| `ppk_pfron_enterprise.rego` | `jdg.ppk_pfron` | 7 | 8 | S7 |
| `cashflow_tax_predictor_enterprise.rego` | `jdg.cashflow_predictor` | 6 | 7 | S8 |
| `form_transition_simulator_enterprise.rego` | `jdg.form_transition` | 5 | 6 | S9 |
| `banking_automation_enterprise.rego` | `jdg.banking` | 14 | 15 | S10 (PSD2/PolishAPI) |
| `annual_declaration_enterprise.rego` | `jdg.annual_declaration` | 6 | 7 | S11 (PIT-36/36L/28) |
| `jpk_v7_autogen_enterprise.rego` | `jdg.jpk_v7_autogen` | 7 | 8 | S12 (JPK_V7M) |
| `legislative_monitor_enterprise.rego` | `jdg.legislative_monitor` | 5 | 6 | S13 |
| `neural_rule_mesh_enterprise.rego` | `jdg.neural_mesh` | 19 | 20 | S14 |
| `neural_mesh_v2_enterprise.rego` | `jdg.neural_mesh_v2` | 15 | 16 | S14 v2 |
| `nkup_enterprise_complete.rego` | `jdg.nkup_enterprise` | 59 | 60 | S15 (Art. 23 PIT) |
| `exit_tax_mdr_enterprise.rego` | `jdg.exit_tax_mdr` | 7 | 8 | S16 |
| `mdr_dac6_enterprise.rego` | `jdg.mdr_dac6` | 3 | 4 | S16b (DAC6) |
| `vat_substantive_complete_enterprise.rego` | `jdg.vat_substantive_complete` | 11 | 12 | S21 (Art. 11–135) |
| `tax_authority_interaction_enterprise.rego` | `jdg.tax_authority_interaction` | 6 | 7 | S22 (auto-korespondencja) |
| `sanctions_optimization_enterprise.rego` | `jdg.sanctions_optimization` | 4 | 5 | S23 (KKS 4-ścieżki) |
| `lifecycle_manager_enterprise.rego` | `jdg.lifecycle_manager` | 4 | 5 | S24 (cykl życia JDG) |

### Pozostałe pakiety enterprise (katalog główny)

| Plik | Pakiet | R | ID |
|---|---|---|---|
| `adaptive_trust_scoring_enterprise.rego` | `jdg.adaptive_trust` | 3 | 4 |
| `conflict_declaration_enterprise.rego` | `jdg.conflict_declaration` | 4 | 5 |
| `decision_core_completeness_enterprise.rego` | `jdg.decision_core_completeness` | 5 | 6 |
| `decision_composer_enterprise.rego` | `jdg.decision_composer` | 2 | 3 |
| `rule_lifecycle_enterprise.rego` | `jdg.rule_lifecycle` | 4 | 5 |
| `reliability_guarantee_enterprise.rego` | `jdg.reliability_guarantee` | 5 | 5 |
| `deadline_monitor_enterprise.rego` | `jdg.deadline_monitor` | 2 | 3 |
| `calendar_notifier_enterprise.rego` | `jdg.enterprise.calendar_notifier` | 0 | 0 |
| `defense_builder_enterprise.rego` | `jdg.defense_builder` | 3 | 4 |
| `proceeding_tracker_enterprise.rego` | `jdg.proceeding_tracker` | 2 | 3 |
| `poa_manager_enterprise.rego` | `jdg.poa_manager` | 2 | 3 |
| `overpayment_auto_claimer_enterprise.rego` | `jdg.overpayment_claimer` | 2 | 3 |
| `interest_calculator_enterprise.rego` | `jdg.interest_calculator` | 3 | 4 |
| `gaar_shield_enterprise.rego` | `jdg.gaar_shield` | 2 | 3 |
| `epuap_enterprise.rego` | `jdg.epuap` | 3 | 4 |
| `edelivery_gateway_enterprise.rego` | `jdg.edelivery_gateway` | 3 | 4 |
| `edelivery_gateway_v2_enterprise.rego` | `jdg.enterprise.edelivery_gateway` | 0 | 0 |
| `esig_auto_applicator_enterprise.rego` | `jdg.esig_auto` | 4 | 5 |
| `wis_api_enterprise.rego` | `jdg.wis_api` | 3 | 4 |
| `wis_autorequester_enterprise.rego` | `jdg.enterprise.wis_autorequester` | 0 | 0 |
| `gtu_completeness_checker_enterprise.rego` | `jdg.gtu_checker` | 3 | 4 |
| `cross_declaration_validator_enterprise.rego` | `jdg.cross_validator` | 4 | 5 |
| `vat_cashflow_predictor_enterprise.rego` | `jdg.vat_cashflow` | 4 | 5 |
| `form_optimizer_enterprise.rego` | `jdg.form_optimizer` | 5 | 6 |
| `pkpir_to_uor_transformer.rego` | `jdg.pkpir_to_uor_transformer` | 6 | 7 |
| `hyper_plan45_meta_enterprise.rego` | `jdg.hyper_plan45_meta` | 3 | 4 |
| `mdr_auto_generator.rego` | `jdg.mdr_auto_generator` | 5 | 6 |
| `wdt_document_tracker.rego` | `jdg.wdt_document_tracker` | 3 | 4 |
| `cfc_auto_classifier.rego` | `jdg.cfc_auto_classifier` | 3 | 4 |
| `exit_tax_interest_calculator.rego` | `jdg.exit_tax_interest_calculator` | 3 | 4 |
| `vida_drr_full.rego` | `jdg.vida_drr_full` | 3 | 4 |
| `dac8_report_generator.rego` | `jdg.dac8_report_generator` | 3 | 4 |
| `cbam_full.rego` | `jdg.cbam_full` | 3 | 4 |
| `jpk_kr_st_generator_enterprise.rego` | `jdg.jpk_kr_st` | 4 | 5 |
| `jpk_corrections_workflow_enterprise.rego` | `jdg.jpk_corrections` | 3 | 4 |
| `vat_rates_exemptions_audit_enterprise.rego` | `jdg.vat_rates_audit` | 4 | 5 |
| `vat_deductions_corrections_enterprise.rego` | `jdg.vat_deductions_audit` | 7 | 8 |
| `vat_mpp_split_payment_enterprise.rego` | `jdg.vat_mpp_split_payment` | 6 | 6 |
| `vat_fraud_detection_enterprise.rego` | `jdg.vat_fraud_detection` | 5 | 6 |
| `pit/art21_exemptions_enterprise.rego` | `jdg.pit.art21_exemptions` | 29 | 29 |
| `pit/rd_relief_enterprise.rego` | `jdg.pit.rd_relief` | 13 | 14 |
| `pit/ipbox_enterprise.rego` | `jdg.pit.ipbox` | 9 | 9 |
| `pit/thermo_relief_enterprise.rego` | `jdg.pit.thermo_relief` | 11 | 12 |
| `pit/donation_relief_enterprise.rego` | `jdg.pit.donation_relief` | 8 | 9 |
| `pit/cross_relief_optimizer_enterprise.rego` | `jdg.pit.cross_relief` | 8 | 8 |
| `pit/tax_loss_harvesting_enterprise.rego` | `jdg.pit.tax_loss_harvesting` | 6 | 6 |
| `pit/family_estonian_enterprise.rego` | `jdg.pit.family_estonian` | 10 | 11 |
| `pit/kup_extended.rego` | `jdg.pit.kup_extended` | 34 | 35 |
| `pit/tax_form_transition_intelligence.rego` | `jdg.pit.transition_intel` | 11 | 12 |
| `zus/enterprise_benefits.rego` | `jdg.zus.benefits` | 11 | 12 |
| `zus/sickness_benefits_enterprise.rego` | `jdg.zus.sickness_benefits` | 14 | 15 |
| `zus/health_contribution_enterprise.rego` | `jdg.zus.health_contribution` | 15 | 16 |
| `zus/cumulative_revenue_engine.rego` | `jdg.zus.cumulative_engine` | 4 | 5 |
| `zus/health_precision_engine_v8.rego` | `jdg.zus.precision_engine` | 0 | 11 |
| `accounting/depreciation_enterprise.rego` | `jdg.accounting.depreciation` | 11 | 12 |
| `accounting/depreciation_enterprise_complete.rego` | `jdg.pit.depreciation` | 29 | 30 |
| `accounting/pkpir_enterprise_live.rego` | `jdg.pkpir_live` | 12 | 13 |
| `accounting/pkpir_enterprise_validation.rego` | `jdg.accounting.pkpir_validation` | 34 | 35 |
| `accounting/pkpir_enterprise_validator.rego` | `jdg.accounting.pkpir` | 21 | 22 |
| `accounting/uor_enterprise_live.rego` | `jdg.uor_live` | 10 | 11 |
| `accounting/plan23_leasing.rego` | `jdg.accounting` | 5 | 6 |
| `accounting/plan42_pkpir.rego` | `jdg.accounting` | 1 | 2 |
| `pcc/plan42_pcc.rego` | `jdg.pcc` | 4 | 5 |
| `mdr/mdr_enterprise.rego` | `jdg.mdr.enterprise` | 18 | 19 |
| `mdr/mdr_hallmarks.rego` | `jdg.mdr.hallmarks` | 20 | 21 |
| `kks/enterprise_penalties.rego` | `jdg.kks.enterprise_penalties` | 21 | 22 |
| `kks/kks_innovations_v8.rego` | `jdg.kks.innovations` | 13 | 14 |
| `local_taxes/excise_enterprise_complete.rego` | `jdg.local_taxes.excise_enterprise` | 15 | 16 |
| `local_taxes/local_procedures_enterprise.rego` | `jdg.local_taxes.procedures_enterprise` | 15 | 16 |
| `local_taxes/pcc_enterprise_complete.rego` | `jdg.local_taxes.pcc_enterprise` | 51 | 52 |
| `local_taxes/pcc_excise_enterprise.rego` | `jdg.local.enterprise` | 18 | 19 |
| `local_taxes/akcyza_fuel.rego` | `jdg.akcyza.fuel_energy` | 18 | 19 |
| `local_taxes/akcyza_alcohol.rego` | `jdg.akcyza.alcohol_tobacco` | 20 | 21 |
| `crossborder/exit_tax_cfc_complete.rego` | `jdg.exit_tax_cfc` | 16 | 17 |
| `crossborder/plan23_ue.rego` | `jdg.crossborder` | 8 | 9 |
| `crossborder/post_brexit.rego` | `jdg.crossborder.post_brexit` | 3 | 4 |
| `business/gig_economy.rego` | `jdg.business.gig_economy` | 5 | 6 |
| `business/plan26_suspension_succession.rego` | `jdg.business` | 5 | 5 |
| `business/strategic_intelligence.rego` | `jdg.strategic` | 7 | 8 |
| `ord/ord_innovations_v8.rego` | `jdg.ord.innovations` | 20 | 21 |
| `security/security_fortress_v8.rego` | `jdg.security.fortress` | 19 | 20 |

### Pakiety stub/planowane (`jdg.enterprise.*` — 0 reguł w ekstrakcji)

`penalty_ai_enterprise.rego`, `decision_scoring_enterprise.rego`, `financial_hardship_scorer_enterprise.rego`, `insurance_tracker_enterprise.rego`, `judicial_trend_enterprise.rego`, `legislative_impact_analyzer_enterprise.rego`, `ord_supplements_enterprise.rego`, `regulated_compliance_enterprise.rego`, `sanctions_supplements_enterprise.rego`, `solidarity_auto_calc_enterprise.rego`, `strategic_roadmap_enterprise.rego`, `tax_correspondence_engine_enterprise.rego`, `tax_ruling_autodrafter_enterprise.rego`, `conviction_checker_enterprise.rego`, `cross_jurisdiction_ruling_enterprise.rego` — zadeklarowane w orkiestratorze jako rezerwowane (wymagają wypełnienia warunków — patrz ADR-015).

---

## 3. Domena VAT (`rules/vat/`)

| Plik | Pakiet | R | ID |
|---|---|---|---|
| `substantive.rego` | `jdg.vat.substantive` | 61 | 62 |
| `deductions.rego` | `jdg.vat.deductions` | 28 | 29 |
| `procedures.rego` | `jdg.vat.procedures` | 20 | 21 |
| `place_of_supply.rego` | `jdg.vat.place_of_supply` | 11 | 12 |
| `enterprise_vat_bridge.rego` | `jdg.vat.enterprise` | 11 | 12 |
| `plan23_detailed.rego` | `jdg.vat` | 16 | 17 |
| `plan26_critical.rego` | `jdg.vat.plan26_critical` | 18 | 19 |
| `plan42_reduced_rates.rego` | `jdg.vat.reduced_rates` | 13 | 14 |

## 4. Domena PIT (`rules/pit/`)

| Plik | Pakiet | R | ID |
|---|---|---|---|
| `forms.rego` | `jdg.pit.forms` | 19 | 20 |
| `kup.rego` | `jdg.pit.kup` | 14 | 15 |
| `advances_returns.rego` | `jdg.pit.advances` | 10 | 11 |
| `exemptions.rego` | `jdg.pit.exemptions` | 9 | 10 |
| `transitions.rego` | `jdg.pit.transitions` | 9 | 10 |
| `elearning.rego` | `jdg.pit.elearning` | 5 | 6 |
| `plan23_exemptions.rego` | `jdg.pit` | 6 | 7 |
| `plan23_tax_form_change.rego` | `jdg.pit.tax_form_change` | 7 | 8 |
| `plan26_detailed.rego` | `jdg.pit` | 8 | 9 |
| `plan26_pit_critical.rego` | `jdg.pit.plan26_critical` | 13 | 14 |
| + 11 plików enterprise (patrz §2: art21, rd_relief, ipbox, thermo, donation, cross_relief, tax_loss, family_estonian, kup_extended, transition_intel, elearning) | | | |

## 5. Domena ZUS (`rules/zus/`)

| Plik | Pakiet | R | ID |
|---|---|---|---|
| `plan23_interactions.rego` | `jdg.zus` | 9 | 10 |
| `plan42_benefits.rego` | `jdg.zus` | 8 | 9 |
| `enterprise_benefits.rego` | `jdg.zus.benefits` | 11 | 12 |
| `sickness_benefits_enterprise.rego` | `jdg.zus.sickness_benefits` | 14 | 15 |
| `health_contribution_enterprise.rego` | `jdg.zus.health_contribution` | 15 | 16 |
| `health_precision_engine_v8.rego` | `jdg.zus.precision_engine` | 0 | 11 |
| `cumulative_revenue_engine.rego` | `jdg.zus.cumulative_engine` | 4 | 5 |

## 6. Księgowość: UoR (`rules/uor/`) i PCC (`rules/pcc/`)

| Plik | Pakiet | R | ID |
|---|---|---|---|
| `uor/plan42_uor.rego` | `jdg.uor` | 5 | 6 |
| `uor/uor_obligation.rego` | `jdg.uor.obligation` | 30 | 31 |
| `uor/uor_books.rego` | `jdg.uor.books` | 52 | 53 |
| `uor/uor_revenue.rego` | `jdg.uor.revenue` | 29 | 30 |
| `uor/uor_costs.rego` | `jdg.uor.costs` | 26 | 27 |
| `uor/uor_assets.rego` | `jdg.uor.assets` | 33 | 34 |
| `uor/uor_inventory.rego` | `jdg.uor.inventory` | 17 | 18 |
| `uor/uor_closing.rego` | `jdg.uor.closing` | 25 | 26 |
| `uor/uor_financial_stmt.rego` | `jdg.uor.financial_stmt` | 27 | 28 |
| `pcc/pcc_sales.rego` | `jdg.pcc.sales_agreements` | 25 | 26 |
| `pcc/pcc_loans.rego` | `jdg.pcc.loans` | 15 | 16 |
| `pcc/pcc_companies.rego` | `jdg.pcc.exchanges_companies` | 19 | 20 |
| `pcc/pcc_rates.rego` | `jdg.pcc.rate_changes` | 25 | 26 |

## 7. Serie Plan44/Plan45 (hiper-szczegółowe)

| Plik | Pakiet | R | ID | Plik | Pakiet | R | ID |
|---|---|---|---|---|---|---|---|
| `audit/plan44_audit` | `jdg.audit` | 15 | 16 | `audit/plan45_audit` | `jdg.audit.hyper` | 55 | 56 |
| `calendar/plan44_calendar` | `jdg.calendar` | 6 | 7 | `calendar/plan45_calendar` | `jdg.calendar.hyper` | 35 | 36 |
| `edelivery/plan44_edelivery` | `jdg.edelivery` | 8 | 9 | `edelivery/plan45_edelivery` | `jdg.edelivery.hyper` | 41 | 42 |
| `esig/plan44_esig` | `jdg.esig` | 7 | 8 | `esig/plan45_esig` | `jdg.esig.hyper` | 36 | 37 |
| `family/plan44_family` | `jdg.family` | 10 | 11 | `family/plan45_family` | `jdg.family.hyper` | 51 | 52 |
| `force_majeure/plan44_*` | `jdg.force_majeure` | 8 | 9 | `force_majeure/plan45_*` | `jdg.force_majeure.hyper` | 32 | 33 |
| `fx/plan44_fx` | `jdg.fx` | 9 | 10 | `fx/plan45_fx` | `jdg.fx.hyper` | 46 | 47 |
| `insurance/plan44_*` | `jdg.insurance` | 6 | 7 | `insurance/plan45_*` | `jdg.insurance.hyper` | 28 | 29 |
| `mdr/plan44_mdr` | `jdg.mdr` | 10 | 11 | `mdr/plan45_mdr` | `jdg.mdr.hyper` | 42 | 43 |
| `payments/plan44_*` | `jdg.payments` | 9 | 10 | `payments/plan45_*` | `jdg.payments.hyper` | 50 | 51 |
| `procurement/plan44_*` | `jdg.procurement` | 8 | 9 | `procurement/plan45_*` | `jdg.procurement.hyper` | 38 | 39 |
| `regulated/plan44_*` | `jdg.regulated` | 8 | 9 | `regulated/plan45_*` | `jdg.regulated.hyper` | 32 | 33 |
| `residency/plan44_*` | `jdg.residency` | 10 | 11 | `residency/plan45_*` | `jdg.residency.hyper` | 48 | 49 |
| `seasonal/plan44_*` | `jdg.seasonal` | 7 | 8 | `seasonal/plan45_*` | `jdg.seasonal.hyper` | 28 | 29 |
| `solidarity/plan44_*` | `jdg.solidarity` | 5 | 6 | `solidarity/plan45_*` | `jdg.solidarity.hyper` | 28 | 29 |
| `taxfree/plan44_*` | `jdg.taxfree` | 6 | 7 | `taxfree/plan45_*` | `jdg.taxfree.hyper` | 38 | 39 |
| `tp/plan44_tp` | `jdg.tp` | 9 | 10 | `tp/plan45_tp` | `jdg.tp.hyper` | 52 | 53 |
| `wis/plan44_wis` | `jdg.wis` | 8 | 9 | `wis/plan45_wis` | `jdg.wis.hyper` | 35 | 36 |
| `conviction/plan44_*` | `jdg.conviction` | 6 | 7 | `conviction/plan45_*` | `jdg.conviction.hyper` | 30 | 31 |
| `advertising/plan44_*` | `jdg.advertising` | 9 | 10 | `advertising/plan45_*` | `jdg.advertising.hyper` | 37 | 38 |
| `kks/plan42_detailed` | `jdg.kks` | 12 | 13 | `kks/plan43_decomposition` | `jdg.kks` | 21 | 22 |
| `kks/plan44_kks_conviction` | `jdg.kks` | 2 | 3 | | | | |
| `local_taxes/plan26_local` | `jdg.local_taxes` | 6 | 7 | `local_taxes/real_estate` | `jdg.local_taxes.real_estate` | 2 | 3 |
| `local_taxes/transport` | `jdg.local_taxes.transport` | 1 | 2 | `local_taxes/pcc.rego` | `jdg.local_taxes.pcc` | 3 | 4 |

## 8. Warstwa Hyper (`rules/jdg/hyper/`) — Plan45 hiper-detal

| Plik | Pakiet | R | ID | Zakres |
|---|---|---|---|---|
| `general/plan45.rego` | `jdg.hyper.general` | 100 | 101 | ogólne |
| `deadlines/plan45.rego` | `jdg.hyper.deadlines` | 56 | 57 | terminy |
| `limits/plan45.rego` | `jdg.hyper.limits` | 33 | 34 | limity |
| `mdr/plan45.rego` | `jdg.hyper.mdr` | 38 | 39 | MDR |
| `misc/plan45.rego` | `jdg.hyper.misc` | 49 | 50 | różne |
| `sanctions/plan45.rego` | `jdg.hyper.sanctions` | 51 | 52 | sankcje |
| `audit/plan45.rego` | `jdg.hyper.audit` | 25 | 26 | audyt |
| `family/plan45.rego` | `jdg.hyper.family` | 21 | 22 | rodzina |
| `force_majeure/plan45.rego` | `jdg.hyper.force_majeure` | 21 | 22 | siła wyższa |
| `fx/plan45.rego` | `jdg.hyper.fx` | 24 | 25 | FX |
| `edelivery/plan45.rego` | `jdg.hyper.edelivery` | 21 | 22 | e-Doręczenia |
| `procurement/plan45.rego` | `jdg.hyper.procurement` | 21 | 22 | zamówienia |
| `solidarity/plan45.rego` | `jdg.hyper.solidarity` | 11 | 12 | solidarnościowe |
| `wis/plan45.rego` | `jdg.hyper.wis` | 18 | 19 | WIS |

## 9. Warstwa mikro-atomowa (`rules/micro/`)

> **Największy obszar:** ~2 900+ reguł atomowych per artykuł ustawy.

### 9.1. Serie plan33 / plan34 (generowane)

| Plik | Pakiet | R | ID |
|---|---|---|---|
| `plan33_agricultural_tax.rego` | `jdg.micro.agricultural_tax` | 5 | 6 |
| `plan33_cb.rego` | `jdg.micro.cb` | 20 | 21 |
| `plan33_ceidg.rego` | `jdg.micro.ceidg` | 15 | 16 |
| `plan33_est.rego` | `jdg.micro.est` | 15 | 16 |
| `plan33_health.rego` | `jdg.micro.health` | 40 | 41 |
| `plan33_jpk.rego` | `jdg.micro.jpk` | 70 | 71 |
| `plan33_kks.rego` | `jdg.micro.kks` | 64 | 65 |
| `plan33_ksef.rego` | `jdg.micro.ksef` | 74 | 75 |
| `plan33_mdr.rego` | `jdg.micro.mdr` | 10 | 11 |
| `plan33_ord.rego` | `jdg.micro.plan33_ord` | 1 | 2 |
| `plan33_pcc.rego` | `jdg.micro.pcc` | 59 | 60 |
| `plan33_pit.rego` | `jdg.micro.pit` | 86 | 87 |
| `plan33_prop.rego` | `jdg.micro.prop` | 30 | 31 |
| `plan33_prop_transport.rego` | `jdg.micro.prop_transport` | 5 | 6 |
| `plan33_rodo.rego` | `jdg.micro.rodo` | 10 | 11 |
| `plan33_ryc.rego` | `jdg.micro.ryc` | 158 | 159 |
| `plan33_succ.rego` | `jdg.micro.succ` | 20 | 21 |
| `plan33_tax_trans.rego` | `jdg.micro.tax_trans` | 15 | 16 |
| `plan33_tp.rego` | `jdg.micro.tp` | 15 | 16 |
| `plan33_uor.rego` | `jdg.micro.uor_plan33` | 25 | 26 |
| `plan33_vat.rego` | `jdg.micro.vat.plan33` | 115 | 116 |
| `plan33_zus.rego` | `jdg.micro.zus` | 180 | 176 |
| `plan34_ord.rego` | `jdg.micro.ord` | 189 | 190 |
| `plan34_pit.rego` | `jdg.micro.pit` | 265 | 266 |
| `plan34_vat.rego` | `jdg.micro.vat.plan34` | 179 | 180 |
| `plan34_zus.rego` | `jdg.micro.zus` | 20 | 21 |
| `p24_innovations_enterprise.rego` | `jdg.p24.innovations` | 29 | 30 |
| `_zus_micro_rates.rego` | `jdg.micro.zus_rates` | 0 | 0 |
| `GENERATION_SUMMARY.txt` | — | — | — (raport generacji) |

### 9.2. Mikro-domeny (per obszar)

| Obszar | Plik | Pakiet | R | ID |
|---|---|---|---|---|
| Akcyza | `akcyza/akcyza.rego` | `jdg.micro.akcyza` | 132 | 133 |
| AML | `aml/aml.rego` | `jdg.micro.aml` | 125 | 126 |
| AML-CBDD | `aml/aml_cbdd.rego` | `jdg.micro.aml_cbdd` | 6 | 7 |
| AML-ryzyko | `aml/aml_ryzyko.rego` | `jdg.micro.aml_ryzyko` | 8 | 9 |
| AML-STR/GIF | `aml/aml_str_gif.rego` | `jdg.micro.aml_str_gif` | 8 | 9 |
| AML-transakcje | `aml/aml_transakcje.rego` | `jdg.micro.aml_transakcje` | 7 | 8 |
| Amortyzacja | `amortyzacja/pit_a22a.rego` | `jdg.micro.amort_a22a` | 10 | 11 |
| Amortyzacja | `amortyzacja/pit_a22i.rego` | `jdg.micro.amort_a22i` | 9 | 10 |
| Amortyzacja | `amortyzacja/pit_a22k.rego` | `jdg.micro.amort_a22k` | 7 | 8 |
| Amortyzacja | `amortyzacja/pit_a22n.rego` | `jdg.micro.amort_a22n` | 7 | 8 |
| BDO | `bdo/bdo_rejestracja.rego` | `jdg.micro.bdo_rejestracja` | 9 | 10 |
| BDO | `bdo/bdo_ewc.rego` | `jdg.micro.bdo_ewc` | 9 | 10 |
| BDO | `bdo/bdo_ewidencja.rego` | `jdg.micro.bdo_ewidencja` | 9 | 10 |
| BDO | `bdo/bdo_transport.rego` | `jdg.micro.bdo_transport` | 7 | 8 |
| BDO | `bdo/bdo_zezwolenia.rego` | `jdg.micro.bdo_zezwolenia` | 7 | 8 |
| BDO | `bdo/bdo_weee_baterie.rego` | `jdg.micro.bdo_weee` | 6 | 7 |
| Budownictwo | `budownictwo/budownictwo.rego` | `jdg.micro.budownictwo` | 64 | 65 |
| CEIDG | `ceidg/ceidg.rego` | `jdg.micro.ceidg` | 42 | 43 |
| Cross-border | `crossborder/crossborder.rego` | `jdg.micro.crossborder` | 192 | 193 |
| JPK | `jpk/jpk.rego` | `jdg.micro.jpk` | 35 | 36 |
| KKS | `kks/kks.rego` | `jdg.micro.kks` | 473 | 474 |
| KSeF | `ksef/ksef.rego` | `jdg.micro.ksef` | 79 | 80 |
| Ordynacja | `ord/ord.rego` | `jdg.micro.ord` | 423 | 424 |
| PCC | `pcc/pcc.rego` | `jdg.micro.pcc` | 89 | 90 |
| PIT | `pit/pit.rego` | `jdg.micro.pit` | 811 | 812 |
| PKPiR | `pkpir/pkpir.rego` | `jdg.micro.pkpir` | 11 | 12 |
| PKPiR | `pkpir/pkpir_kolumny.rego` | `jdg.micro.pkpir_columns` | 12 | 13 |
| PKPiR | `pkpir/pkpir_przychody.rego` | `jdg.micro.pkpir_revenue` | 11 | 12 |
| PKPiR | `pkpir/pkpir_koszty.rego` | `jdg.micro.pkpir_costs` | 11 | 12 |
| PKPiR | `pkpir/pkpir_nkup.rego` | `jdg.micro.pkpir_nkup` | 11 | 12 |
| PKPiR | `pkpir/pkpir_remanent.rego` | `jdg.micro.pkpir_remnant` | 9 | 10 |
| PKPiR | `pkpir/pkpir_korekty.rego` | `jdg.micro.pkpir_corrections` | 9 | 10 |
| Prawo Przedsiębiorców | `pp/pp.rego` | `jdg.micro.pp` | 147 | 148 |
| RODO | `rodo/rodo.rego` | `jdg.micro.rodo` | 40 | 41 |
| RODO-erasure | `rodo/rodo_erasure.rego` | `jdg.micro.rodo_erasure` | 5 | 6 |
| RODO-podprocesorzy | `rodo/rodo_podprocesorzy.rego` | `jdg.micro.rodo_podprocesorzy` | 5 | 6 |
| RODO-zatrudnienie | `rodo/rodo_zatrudnienie.rego` | `jdg.micro.rodo_zatrudnienie` | 5 | 6 |
| RODO-AI | `rodo/rodo_ai_marketing.rego` | `jdg.micro.rodo_ai_marketing` | 6 | 7 |
| RODO-sankcje | `rodo/rodo_sankcje.rego` | `jdg.micro.rodo_sankcje` | 6 | 7 |
| Ryczałt | `ryczalt/ryczalt.rego` | `jdg.micro.ryczalt` | 155 | 156 |
| Środowisko | `srodowisko/srodowisko.rego` | `jdg.micro.srodowisko` | 48 | 49 |
| Sukcesja | `sukcesja/sukcesja.rego` | `jdg.micro.sukcesja` | 140 | 138 |
| SUS | `sus/sus.rego` | `jdg.micro.sus` | 122 | 123 |
| SUS | `sus/sus_a6.rego` | `jdg.micro.sus` | 8 | 9 |
| SUS | `sus/sus_a6b.rego` | `jdg.micro.sus` | 6 | 7 |
| SUS | `sus/sus_a9.rego` | `jdg.micro.sus` | 8 | 9 |
| SUS | `sus/sus_a11.rego` | `jdg.micro.sus` | 8 | 9 |
| SUS | `sus/sus_a13.rego` | `jdg.micro.sus` | 8 | 9 |
| SUS | `sus/sus_a14.rego` | `jdg.micro.sus` | 8 | 9 |
| SUS | `sus/sus_a18.rego` | `jdg.micro.sus` | 10 | 11 |
| SUS | `sus/sus_a18a.rego` | `jdg.micro.sus` | 10 | 11 |
| SUS | `sus/sus_a18c.rego` | `jdg.micro.sus` | 10 | 11 |
| SUS | `sus/sus_a19.rego` | `jdg.micro.sus` | 8 | 9 |
| SUS | `sus/sus_a22.rego` | `jdg.micro.sus` | 8 | 9 |
| SUS | `sus/sus_a24.rego` | `jdg.micro.sus` | 6 | 7 |
| SUS | `sus/sus_a36.rego` | `jdg.micro.sus` | 8 | 9 |
| SUS | `sus/sus_a40.rego` | `jdg.micro.sus` | 8 | 9 |
| SUS | `sus/sus_a47.rego` | `jdg.micro.sus` | 8 | 9 |
| Transport | `transport/transport.rego` | `jdg.micro.transport` | 44 | 45 |
| UoR | `uor/uor.rego` | `jdg.micro.uor` | 148 | 149 |
| VAT | `vat/vat.rego` | `jdg.micro.vat` | 1091 | 1092 |
| VAT-KSeF | `vat/ksef_micro.rego` | `jdg.micro.vat.ksef` | 10 | 11 |
| VAT-marża | `vat/margin_scheme_micro.rego` | `jdg.micro.vat.margin` | 10 | 11 |
| VAT-miejsce | `vat/place_of_supply_micro.rego` | `jdg.micro.vat.place_of_supply` | 11 | 12 |
| VAT-proporcja | `vat/proportion_vat.rego` | `jdg.micro.vat.proportion` | 10 | 11 |
| VAT-WDT | `vat/wdt_export_import.rego` | `jdg.micro.vat.wdt_export` | 16 | 17 |
| Zasiłkowa | `zasilkowa/zasilkowa.rego` | `jdg.micro.zasilkowa` | 38 | 39 |
| Zasiłkowa | `zasilkowa/zasilkowa_a19.rego` | `jdg.micro.zasilkowa` | 10 | 11 |
| Zasiłkowa | `zasilkowa/zasilkowa_a29.rego` | `jdg.micro.zasilkowa` | 10 | 11 |
| Zasiłkowa | `zasilkowa/zasilkowa_a32.rego` | `jdg.micro.zasilkowa` | 10 | 11 |
| Zasiłkowa | `zasilkowa/zasilkowa_a33.rego` | `jdg.micro.zasilkowa` | 8 | 9 |
| Zdrowotna | `zdrowotna/zdrowotna.rego` | `jdg.micro.zdrowotna` | 136 | 137 |
| Zdrowotna | `zdrowotna/zdrowotna_a79.rego` | `jdg.micro.zdrowotna` | 10 | 11 |
| Zdrowotna | `zdrowotna/zdrowotna_a81.rego` | `jdg.micro.zdrowotna` | 10 | 11 |
| Zdrowotna | `zdrowotna/zdrowotna_a81b.rego` | `jdg.micro.zdrowotna` | 10 | 11 |
| Zdrowotna | `zdrowotna/zdrowotna_a81c.rego` | `jdg.micro.zdrowotna` | 12 | 13 |
| Zdrowotna | `zdrowotna/zdrowotna_a81d.rego` | `jdg.micro.zdrowotna` | 12 | 13 |
| Zdrowotna | `zdrowotna/zdrowotna_a82.rego` | `jdg.micro.zdrowotna` | 82 | 83 |

> ⚠️ Pliki `.bak_stubs_removed` / `.p03backup` w `micro/vat/` — kopie zapasowe przed usunięciem stubów (nie ładowane jako reguły).

---

## 10. Serie innowacji v8/v9 (`pNN_*_innovations_*.rego`)

| Plik | Pakiet | R | ID | Plik | Pakiet | R | ID |
|---|---|---|---|---|---|---|---|
| `p01_core_architecture_innovations_v8` | `jdg.p01_innovations` | 7 | 8 | `p01_fundament_innovations_v9` | `jdg.p01_fundament_innovations` | 8 | 3 |
| `p02_vat_macro_innovations_v8` | `jdg.p02_innovations` | 7 | 8 | `p02_decision_core_innovations_v9` | `jdg.p02_decision_core_innovations` | 10 | 2 |
| `p03_vat_micro_innovations_v8` | `jdg.p03_innovations` | 7 | 8 | `p03_vat_macro_innovations_v9` | `jdg.p03_vat_macro_innovations` | 9 | 9 |
| `p04_pit_macro_innovations_v8` | `jdg.p04_innovations` | 7 | 8 | `p04_vat_micro_innovations_v9` | `jdg.p04_vat_micro_innovations` | 9 | 10 |
| `p05_pit_innovations_v8` | `jdg.p05_innovations` | 30 | 31 | `p05_pit_macro_innovations_v9` | `jdg.p05_pit_macro_innovations` | 14 | 15 |
| `p06_pit_micro_innovations_v8` | `jdg.p06_innovations` | 34 | 35 | `p06_pit_micro_innovations_v9` | `jdg.p06_pit_micro_innovations` | 13 | 14 |
| `p07_zus_macro_innovations_v8` | `jdg.p07_innovations` | 19 | 20 | `p07_zus_macro_innovations_v9` | `jdg.p07_zus_macro_innovations` | 23 | 24 |
| `p08_zus_micro_innovations_v8` | `jdg.p08_innovations` | 15 | 16 | `p08_zus_micro_innovations_v9` | `jdg.p08_zus_micro_innovations` | 21 | 22 |
| `p09_kks_macro_innovations_v8` | `jdg.p09_innovations` | 14 | 15 | `p09_ksiegowosc_pkpir_uor_innovations_v9` | `jdg.p09_ksiegowosc_pkpir_uor_innovations` | 22 | 23 |
| `p10_kks_micro_innovations_v8` | `jdg.p10_innovations` | 11 | 12 | `p10_kks_innovations_v9` | `jdg.p10_kks_innovations` | 19 | 20 |
| `p11_accounting_pkpir_innovations_v8` | `jdg.p11_innovations` | 13 | 14 | `p11_ordynacja_podatkowa_innovations_v9` | `jdg.p11_ordynacja_podatkowa_innovations` | 22 | 23 |
| `p12_uor_innovations_v8` | `jdg.p12_innovations` | 13 | 14 | `p12_crossborder_innovations_v9` | `jdg.p12_crossborder_innovations` | 21 | 21 |
| `p13_crossborder_innovations_v8` | `jdg.p13_innovations` | 13 | 14 | `p13_ryczalt_cykl_zycia_innovations_v9` | `jdg.p13_ryczalt_cykl_zycia_innovations` | 20 | 21 |
| `p14_compliance_innovations_v8` | `jdg.p14_innovations` | 12 | 13 | `p14_pcc_lokalne_akcyza_innovations_v9` | `jdg.p14_pcc_lokalne_akcyza_innovations` | 19 | 20 |
| `p15_pcc_local_excise_innovations_v8` | `jdg.p15_innovations` | 13 | 14 | `p15_srodowisko_bdo_innovations_v9` | `jdg.p15_srodowisko_bdo_innovations` | 27 | 28 |
| `p16_business_lifecycle_innovations_v8` | `jdg.p16_innovations` | 13 | 14 | `p16_rodo_aml_security_innovations_v9` | `jdg.p16_rodo_aml_security_innovations` | 28 | 29 |
| `p17_edge_conflicts_innovations_v8` | `jdg.p17_innovations` | 12 | 13 | `p17_ksef_jpk_edeklaracje_innovations_v9` | `jdg.p17_ksef_jpk_edeklaracje_innovations` | 29 | 30 |
| | | | | `p18_automatyzacja_ksiegowosci_innovations_v9` | `jdg.p18_automatyzacja_ksiegowosci_innovations` | 31 | 31 |
| | | | | `p19_hr_swiadczenia_innovations_v9` | `jdg.p19_hr_swiadczenia_innovations` | 26 | 27 |
| | | | | `p20_neural_mesh_innovations_v9` | `jdg.p20_neural_mesh_innovations` | 28 | 29 |
| | | | | `p21_opa_system_innovations_v9` | `jdg.p21_opa_system_innovations` | 1 | 2 |
| | | | | `p22_validation_tools_innovations_v9` | `jdg.p22_validation_tools_innovations` | 1 | 2 |
| | | | | `p23_test_rego_ci_innovations_v9` | `jdg.p23_test_rego_ci_innovations` | 1 | 2 |
| | | | | `p24_audyt_kompletny_innovations_v9` | `jdg.p24_audyt_kompletny_innovations` | 1 | 2 |
| `p21_innovations_enterprise` | `jdg.p21_innovations` | 48 | 49 | `p22_innovations_enterprise` | `jdg.p22_innovations` | 48 | 49 |
| `p23_innovations_enterprise` | `jdg.p23_innovations` | 20 | 21 | `p24_innovations_enterprise` | `jdg.p24_innovations` | 28 | 30 |
| `p3233_innovations.rego` | `jdg.p3233_innovations` | 7 | 8 | | | | |
| `p33_uor_supplement.rego` | `jdg.p33_uor_supplement` | 7 | 8 | `p33_pcc_complete.rego` | `jdg.p33_pcc_complete` | 6 | 7 |
| `p33_excise_supplement.rego` | `jdg.p33_excise_supplement` | 7 | 8 | `p33_ordpu_kks_supplement.rego` | `jdg.p33_ordpu_kks_supplement` | 7 | 8 |
| `p34_innovations_engine.rego` | `jdg.p34_innovations` | 15 | 17 | `p34_remaining_fixes.rego` | `jdg.p34_remaining` | 13 | 15 |
| `p35_cross_act_coherence.rego` | `jdg.p35_coherence` | 9 | 11 | `p35_innovations_engine.rego` | `jdg.p35_innovations` | 15 | 17 |
| `p35_system_gaps.rego` | `jdg.p35_gaps` | 10 | 12 | | | | |

### Pakiety pomocnicze P16 (autoformy i SCA)

| Plik | Pakiet | R | ID |
|---|---|---|---|
| `p16_autoform_generator_enterprise.rego` | `jdg.autoform` | 7 | 8 |
| `p16_enhanced_sca_enterprise.rego` | `jdg.banking_sca` | 3 | 4 |
| `p16_entrepreneur_test_enterprise.rego` | `jdg.entrepreneur_test` | 1 | 2 |
| `p16_estonian_cit_enterprise.rego` | `jdg.estonian_cit` | 4 | 5 |

---

## 11. Mirror `policies/jdg/` (32 pliki, starsza wersja v2026.07.10)

| Plik | Pakiet | R | ID |
|---|---|---|---|
| `main_jdg.rego` | `jdg.main` | 0 | 0 |
| `_helpers_jdg.rego` | `jdg.helpers` | 0 | 0 |
| `_metadata_jdg.rego` | `jdg.metadata` | 0 | 0 |
| `risk.rego` | `jdg.risk` | 8 | — |
| `routing.rego` | `jdg.routing` | 5 | — |
| `compliance.rego` | `jdg.compliance` | 7 | — |
| `kks.rego` | `jdg.kks` | 152 | — |
| `crossborder.rego` | `jdg.crossborder` | 14 | — |
| `vat/substantive.rego` | `jdg.vat.substantive` | 43 | — |
| `vat/deductions.rego` | `jdg.vat.deductions` | 25 | — |
| `vat/procedures.rego` | `jdg.vat.procedures` | 17 | — |
| `pit/forms.rego` | `jdg.pit.forms` | 7 | — |
| `pit/kup.rego` | `jdg.pit.kup` | 9 | — |
| `pit/advances_returns.rego` | `jdg.pit.advances` | 8 | — |
| `pit/exemptions.rego` | `jdg.pit.exemptions` | 5 | — |
| `pit/transitions.rego` | `jdg.pit.transitions` | 5 | — |
| `allowances.rego` | `jdg.allowances` | 12 | — |
| `accounting.rego` | `jdg.accounting` | 56 | — |
| `business.rego` | `jdg.business` | 23 | — |
| `corrections.rego` | `jdg.corrections` | 6 | — |
| `conflicts.rego` | `jdg.conflicts` | 27 | — |
| `liability.rego` | `jdg.liability` | 5 | — |
| `representation.rego` | `jdg.representation` | 7 | — |
| `local_taxes.rego` | `jdg.local` | 7 | — |
| `ksef_jpk.rego` | `jdg.ksef_jpk` | 6 | — |
| `international.rego` | `jdg.international` | 4 | — |
| `employer.rego` | `jdg.employer` | 9 | — |
| `environmental.rego` | `jdg.environmental` | 8 | — |
| `restructuring.rego` | `jdg.restructuring` | 7 | — |
| `temporal.rego` | `jdg.temporal` | 9 | — |
| `digital.rego` | `jdg.digital` | 6 | — |
| `retention.rego` | `jdg.retention` | 6 | — |
| `mpips.rego` | `jdg.mpips` | 4 | — |
| `rodo.rego` | `jdg.rodo` | 4 | — |
| `validation.rego` | `jdg.validation` | 8 | — |
| `fallback.rego` | `jdg.fallback` | 1 | — |
| `edge_cases.rego` | `jdg.edge_cases` | 114 | — |

## 12. `policies/tax/` (seria SC — Spółka Cywilna i podatki bezpośrednie)

| Plik | Pakiet | R | Plik | Pakiet | R |
|---|---|---|---|---|---|
| `main_sc.rego` | `tax.main_sc` | 0 | `sc_partnership.rego` | `tax.sc_partnership` | 7 |
| `_helpers.rego` | `tax.helpers` | 0 | `sc_liability.rego` | `tax.sc_liability` | 5 |
| `_helpers_sc.rego` | `tax.helpers_sc` | 0 | `sc_ksef_jpk.rego` | `tax.sc_ksef_jpk` | 6 |
| `_metadata.rego` | `tax.metadata` | 0 | `sc_fallback.rego` | `tax.sc_fallback` | 6 |
| `risk.rego` | `tax.risk` | 5 | `direct/cit.rego` | `tax.direct.cit` | 5 |
| `routing.rego` | `tax.routing` | 2 | `direct/pit.rego` | `tax.direct.pit` | 7 |
| `compliance.rego` | `tax.compliance` | 3 | `vat/substantive.rego` | `tax.vat.substantive` | 9 |
| `crossborder.rego` | `tax.crossborder` | 4 | `vat/gtu.rego` | `tax.vat.gtu` | 1 |
| `allowances.rego` | `tax.allowances` | 11 | `vat/deductions.rego` | `tax.vat.deductions` | 0 |
| `accounting.rego` | `tax.accounting` | 5 | `vat/procedures.rego` | `tax.vat.procedures` | 0 |
| `zus.rego` | `tax.zus` | 5 | `vat_registration.rego` | `tax.vat_registration` | 1 |
| `temporal.rego` | `tax.temporal` | 1 | `cit_deductions.rego` | `tax.cit_deductions` | 1 |
| `fallback.rego` | `tax.fallback` | 2 | `pit_withholding.rego` | `tax.pit_withholding` | 1 |
| `anomaly.rego` | `tax.anomaly` | 5 | `uor_books.rego` | `tax.uor_books` | 4 |
| `what_if.rego` | `tax.what_if` | 1 | `uor_reports.rego` | `tax.uor_reports` | 2 |
| `ordynacja_extended.rego` | `tax.ordynacja_extended` | 2 | `uor_valuation.rego` | `tax.uor_valuation` | 2 |
| `labor_extended.rego` | `tax.labor_extended` | 1 | `partner_mirror.rego` | `tax.partner_mirror` | 1 |
| `data/thresholds_sc.rego` | `data.sc.thresholds` | 0 | `tests/sc_main_test.rego` | `tax.main_sc_test` | 6 |

---

## 12b. ETAP 10–28 — pliki audytów kampanii GLM 5.2 (`rules/*_etapNN_v1.rego`)

> Reguły decyzyjne + bramki jakości dla każdego etapu kampanii. Pełny opis: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json`.

| Plik | Pakiet | Rola |
|---|---|---|
| `pit_macro_etap10_innovations_v1.rego` | `jdg.pit_macro_etap10` | PIT Macro innowacje |
| `pit_micro_reliefs_etap11_v1.rego` | `jdg.pit_micro_reliefs_etap11` | PIT Micro ulgi |
| `zus_core_etap12_v1.rego` | `jdg.zus_core_etap12` | ZUS Core |
| `zus_micro_etap13_v1.rego` | `jdg.zus_micro_etap13` | ZUS Micro |
| `pkpir_etap14_v1.rego` | `jdg.pkpir_etap14` | PKPiR |
| `uor_etap15_v1.rego` | `jdg.uor_etap15` | UoR / amortyzacja |
| `kks_ord_etap16_v1.rego` | `jdg.kks_ord_etap16` | KKS + Ordynacja |
| `crossborder_etap17_v1.rego` | `jdg.crossborder_etap17` | Cross-border / TP / MDR |
| `business_lifecycle_etap18_v1.rego` | `jdg.business_lifecycle_etap18` | Cykl życia JDG |
| `local_excise_etap19_v1.rego` | `jdg.local_excise_etap19` | PCC / lokalne / akcyza |
| `ksef_jpk_etap20_v1.rego` | `jdg.ksef_jpk_etap20` | KSeF / JPK / e-Deklaracje |
| `rodo_aml_bdo_hr_etap21_v1.rego` | `jdg.rodo_aml_bdo_hr_etap21` | RODO / AML / BDO / HR |
| `hyper_enterprise_contexts_etap22_v1.rego` | `jdg.hyper_enterprise_contexts_etap22` | Hyper Enterprise Contexts |
| `enterprise_ai_neural_etap23_v1.rego` | `jdg.enterprise_ai_neural_etap23` | Enterprise AI / Neural Mesh |
| `tests_ci_quality_etap24_v1.rego` | `jdg.tests_ci_quality_etap24` | Testy + CI/CD |
| `tools_api_rulestore_bundles_etap25_v1.rego` | `jdg.tools_api_rulestore_bundles_etap25` | Narzędzia / API / RuleStore / Bundle |
| `policies_mirror_sync_etap26_v1.rego` | `jdg.policies_mirror_sync_etap26` | policies mirror sync |
| `cross_domain_red_team_etap27_v1.rego` | `jdg.cross_domain_red_team_etap27` | Cross-domain red team / chaos |
| `final_certification_etap28_v1.rego` | `jdg.final_certification_etap28` | Certyfikacja końcowa |

---

## 13. Podsumowanie statystyczne

| Obszar | Pliki | Reguły (matched) | Największe pliki |
|---|---|---|---|
| **JDG/rules — rdzeń i domeny** | ~231 | ~2 400+ | kks.rego (255), edge_cases (187), accounting.rego (74) |
| **JDG/rules — micro** | 91 | ~6 900 | micro/vat/vat.rego (1091), micro/pit/pit.rego (811), micro/kks/kks.rego (473) |
| **JDG/rules — plan44/45 + hyper** | ~70 | ~1 500 | hyper/general (100), hyper/deadlines (56) |
| **JDG/rules — innowacje v8/v9** | ~55 | ~750 | p21_innovations (48), p22_innovations (48) |
| **JDG/rules — enterprise S1–S24** | ~50 | ~450 | nkup_enterprise_complete (59), pit/art21 (29) |
| **JDG/rules — ETAP 10–28 (`*_etapNN_v1.rego`)** | 19 | ~200 | patrz §12b |
| **policies/jdg (mirror)** | 52 | ~700 | kks.rego (152), edge_cases (114) |
| **policies/tax (SC)** | 29 | ~120 | direct/pit (7), sc_partnership (7) |

> ⚠️ **Uwaga o metodzie:** wiersze **nie są rozłączne** — pliki plan44/45 w katalogach domenowych (np. `audit/`, `calendar/`) są uwzględnione zarówno w „rdzeń i domeny", jak i w „plan44/45 + hyper". Suma wierszy (~12 800) może więc przekraczać kanoniczne 11 821 bloków `matched:true` z MANIFEST — traktuj wiersze jako orientacyjne, a MANIFEST.md jako źródło prawdy.

> **Uwaga metodyczna:** kolumny R/ID pochodzą z ekstrakcji statycznej (grep linii `matched…true` i `rule_id"`). Kanoniczne wartości M1/M2 (11 811 bloków, 11 808 unikalnych rule_id na 2026-08-22) — patrz [MANIFEST.md](../MANIFEST.md). Aktualny stan (2026-08-30): 490 plików / 11 855 unique rule_id / 0 duplikatów.

---

*Spójny z: MANIFEST.md · STRUKTURA_PROJEKTU.md · ARCHITEKTURA.md (warstwy reguł) · DEVELOPER_GUIDE.md (konwencje)*
