# 🔗 Doc-to-Rego Traceability Matrix — NexusAI JDG v8.0

> **Wygenerowano:** 2026-08-08 12:11:30 | **Innowacja 10 + P02 §7 (LKG refs)**
> **Reguł:** 12286 | **Testów:** 28 | **ADR-ów:** 21 | **Węzłów LKG:** 103

## Macierz identyfikowalności

| Akt | Artykuł | Rule ID | Plik | Routing | Test? | ADR | LKG ref | Status |
|-----|---------|---------|------|:-------:|:-----:|-----|:-------:|:------:|
|  |  | `jdg.accounting.depreciation.fallback` | `accounting/depreciation_enterprise.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  |  | `jdg.accounting.fixed_asset_kst_group` | `accounting.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.accounting.kst_group_classification` | `accounting.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.accounting.lease_classification_test` | `accounting/plan23_leasing.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.accounting.no_match` | `accounting.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  |  | `jdg.accounting.pkpir.fallback_no_match` | `accounting/pkpir_enterprise_validator.re` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.accounting.pkpir_fallback` | `accounting/pkpir_enterprise_validation.r` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.accounting.pkpir_remnant_consistency` | `accounting/plan42_pkpir.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.adaptive_trust.auto_post_gate` | `adaptive_trust_scoring_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.adaptive_trust.no_match` | `adaptive_trust_scoring_enterprise.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  |  | `jdg.adaptive_trust.suggest_gate` | `adaptive_trust_scoring_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.adaptive_trust.triage_gate` | `adaptive_trust_scoring_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.advertising.foreign_markets_kup` | `advertising/plan44_advertising.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.advertising.hyper.car_wrapping_vat26_full` | `advertising/plan45_advertising.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 4 | `jdg.agricultural_tax.r1` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.agricultural_tax.r2` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 2 | `jdg.agricultural_tax.r3` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 6 | `jdg.agricultural_tax.r4` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.agricultural_tax.r5` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 93 ust. 1 | `jdg.akcyza.alcohol_tobacco.alcohol.r2` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 93 ust. 1 | `jdg.akcyza.alcohol_tobacco.alcohol.r3` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 93 ust. 1 | `jdg.akcyza.alcohol_tobacco.alcohol.r4` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 94 | `jdg.akcyza.alcohol_tobacco.alcohol.r5` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 30 ust. 9 | `jdg.akcyza.alcohol_tobacco.alcohol.r6` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 48 | `jdg.akcyza.alcohol_tobacco.alcohol.r7` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 99 ust. 1 | `jdg.akcyza.alcohol_tobacco.alcohol.r8` | `local_taxes/akcyza_alcohol.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 93 ust. 1 | `jdg.akcyza.alcohol_tobacco.no_match` | `local_taxes/akcyza_alcohol.rego` | 🔴 | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 100 | `jdg.akcyza.alcohol_tobacco.other.r1` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 89 ust. 2 | `jdg.akcyza.alcohol_tobacco.other.r3` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.akcyza.alcohol_tobacco.other.r4` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 99 ust. 3 | `jdg.akcyza.alcohol_tobacco.tobacco.r1` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 99 ust. 4 | `jdg.akcyza.alcohol_tobacco.tobacco.r2` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 99 ust. 5 | `jdg.akcyza.alcohol_tobacco.tobacco.r3` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 99 ust. 9 | `jdg.akcyza.alcohol_tobacco.tobacco.r4` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 99a | `jdg.akcyza.alcohol_tobacco.tobacco.r5` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 116 | `jdg.akcyza.alcohol_tobacco.tobacco.r6` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 99 ust. 10 | `jdg.akcyza.alcohol_tobacco.tobacco.r7` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 89 ust. 1 | `jdg.akcyza.alcohol_tobacco.tobacco.r8` | `local_taxes/akcyza_alcohol.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 89 ust. 3 | `jdg.akcyza.fuel_energy.energy.r1` | `local_taxes/akcyza_fuel.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 89 ust. 3 | `jdg.akcyza.fuel_energy.energy.r2` | `local_taxes/akcyza_fuel.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 30 ust. 9 | `jdg.akcyza.fuel_energy.energy.r3` | `local_taxes/akcyza_fuel.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 89 ust. 1 | `jdg.akcyza.fuel_energy.energy.r4` | `local_taxes/akcyza_fuel.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 89 ust. 1 | `jdg.akcyza.fuel_energy.energy.r5` | `local_taxes/akcyza_fuel.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 24 | `jdg.akcyza.fuel_energy.energy.r6` | `local_taxes/akcyza_fuel.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 16 ust. 1 | `jdg.akcyza.fuel_energy.energy.r7` | `local_taxes/akcyza_fuel.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 21 | `jdg.akcyza.fuel_energy.energy.r8` | `local_taxes/akcyza_fuel.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.akcyza.fuel_energy.energy.r9` | `local_taxes/akcyza_fuel.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 89 ust. 1 | `jdg.akcyza.fuel_energy.fuel.r1` | `local_taxes/akcyza_fuel.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 89 ust. 1 | `jdg.akcyza.fuel_energy.fuel.r2` | `local_taxes/akcyza_fuel.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 89 ust. 1 | `jdg.akcyza.fuel_energy.fuel.r3` | `local_taxes/akcyza_fuel.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 40 ust. 1 | `jdg.akcyza.fuel_energy.fuel.r4` | `local_taxes/akcyza_fuel.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 8 ust. 2 | `jdg.akcyza.fuel_energy.fuel.r5` | `local_taxes/akcyza_fuel.rego` | 🟡 | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 24a | `jdg.akcyza.fuel_energy.fuel.r6` | `local_taxes/akcyza_fuel.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 90 | `jdg.akcyza.fuel_energy.fuel.r7` | `local_taxes/akcyza_fuel.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 89 ust. 2 | `jdg.akcyza.fuel_energy.fuel.r8` | `local_taxes/akcyza_fuel.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 2 ust. 1 | `jdg.akcyza.fuel_energy.fuel.r9` | `local_taxes/akcyza_fuel.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 89 ust. 1 | `jdg.akcyza.fuel_energy.no_match` | `local_taxes/akcyza_fuel.rego` | 🔴 | ✅ | ⬜ | ⬜ | ✅ |
|  |  | `jdg.allowances.abolition_relief` | `allowances/plan23_reliefs.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.allowances.relief_rd_carry_forward` | `allowances.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.aml_full.a50.u5.p4` | `micro/aml/aml.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.annual_decl.relief_cross_validation` | `annual_declaration_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.api_fallback.multi_degradation` | `api_fallback.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.api_fallback.nbp_rate_fallback` | `api_fallback.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.api_fallback.whitelist_degradation` | `api_fallback.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.closure_and_follow_up` | `audit/plan44_audit.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 220 | `jdg.audit.correction_during_audit` | `audit/plan44_audit.rego` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.hyper.aggregate_risk_update` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 292 | `jdg.audit.hyper.closure_correction_window` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 81b | `jdg.audit.hyper.closure_decision_deadline` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 107 | `jdg.audit.hyper.closure_decision_issuance` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 107 | `jdg.audit.hyper.cross_border_foreign_officials` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.hyper.cross_border_mutual_assistance` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.hyper.cross_border_simultaneous` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 180a | `jdg.audit.hyper.doc_electronic_evidence` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.doc_foreign_language` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 193a | `jdg.audit.hyper.doc_seizure_duration` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 288 | `jdg.audit.hyper.doc_seizure_receipt` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 119b | `jdg.audit.hyper.followup_deadline_monitoring` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 292 | `jdg.audit.hyper.followup_recommendations` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 272 | `jdg.audit.hyper.no_match` | `audit/plan45_audit.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 287 | `jdg.audit.hyper.obligation_allow_inspection` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 287 | `jdg.audit.hyper.obligation_provide_docs` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.obligation_provide_explanations` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 70 | `jdg.audit.hyper.obligation_retain_audit_docs` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 86 | `jdg.audit.hyper.obligation_sign_protocol` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 288 | `jdg.audit.hyper.penalty_coercion` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 151 | `jdg.audit.hyper.penalty_obstruction_kks69` | `audit/plan45_audit.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.protocol_deadline_14days` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 138e | `jdg.audit.hyper.protocol_electronic_service` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.protocol_objections_period` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 144b | `jdg.audit.hyper.protocol_objections_to_director` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.protocol_required_elements` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 138e | `jdg.audit.hyper.representation_access_files` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.hyper.representation_participation` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 138e | `jdg.audit.hyper.representation_pps1` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 178 | `jdg.audit.hyper.representation_upl1` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 52 | `jdg.audit.hyper.right_appeal_14days` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 84c | `jdg.audit.hyper.right_break_request` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 81b | `jdg.audit.hyper.right_correction_minus_blocked` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 200 | `jdg.audit.hyper.right_correction_plus_allowed` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 199 | `jdg.audit.hyper.right_exclusion_inspector` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 285 | `jdg.audit.hyper.right_no_notification_exceptions` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 282b | `jdg.audit.hyper.right_notification_7days` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 286 | `jdg.audit.hyper.right_object_to_protocol` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 81b | `jdg.audit.hyper.right_oppose_inspection` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 130 | `jdg.audit.hyper.right_presence` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 84c | `jdg.audit.hyper.right_record_activities` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.right_refuse_self_incrimination` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 223 | `jdg.audit.hyper.right_to_be_heard` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 287 | `jdg.audit.hyper.right_wsa_30days` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 262 | `jdg.audit.hyper.statute_resume_after_close` | `audit/plan45_audit.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 70 | `jdg.audit.hyper.statute_suspension_duration` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 70 | `jdg.audit.hyper.statute_suspension_effect` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 274 | `jdg.audit.hyper.trigger_cross_checking` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 282b | `jdg.audit.hyper.trigger_external_information` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 281 | `jdg.audit.hyper.trigger_inspection_warrant` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 283 | `jdg.audit.hyper.trigger_return_to_correct` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 272 | `jdg.audit.hyper.type_customs_fiscal` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 120 | `jdg.audit.hyper.type_tax_audit` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 54 | `jdg.audit.hyper.type_tax_proceeding` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 281 | `jdg.audit.hyper.type_verification` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit_defense.statute_of_limitations` | `audit_defense_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.ceidg1_autofill` | `p16_autoform_generator_enterprise.rego` | 🟡 | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.no_match` | `p16_autoform_generator_enterprise.rego` | 🟡 | ✅ | ⬜ | ⬜ | ✅ |
|  |  | `jdg.autoform.notarial_deed_template` | `p16_autoform_generator_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.pit_employee_autofill` | `p16_autoform_generator_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.receipt_generator` | `p16_autoform_generator_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.vat_z_autofill` | `p16_autoform_generator_enterprise.rego` | 🟡 | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.zus_zua_autofill` | `p16_autoform_generator_enterprise.rego` | 🟡 | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.zus_zwua_autofill` | `p16_autoform_generator_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 64 | `jdg.banking.ais_account_information` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 92 | `jdg.banking.bank_profile_routing` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.batch_payment_format` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 97 | `jdg.banking.elixir_payload_generator` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 66 | `jdg.banking.iban_validation` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.oauth2_eidas_token_management` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.payment_status_tracking` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.pis_payment_initiation` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.psd2_compliance_audit` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 67 | `jdg.banking.psd2_consent_management` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking_sca.ais_consent_renewal` | `p16_enhanced_sca_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.banking_sca.eidas_certificates` | `p16_enhanced_sca_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.banking_sca.method_selection` | `p16_enhanced_sca_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.banking_sca.no_match` | `p16_enhanced_sca_enterprise.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  |  | `jdg.business.gig_economy.mileage_tracking` | `business/gig_economy.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 12 ust. 1 | `jdg.business.gig_economy.platform_commission_impor` | `business/gig_economy.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.business.maximum_suspension_period_check` | `business/plan26_suspension_succession.re` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.business.no_match` | `business.rego` | — | ✅ | ⬜ | ⬜ | ✅ |
|  | Art. 22 | `jdg.business.resumption_procedure` | `business.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.business.resumption_procedure_valid` | `business/plan26_suspension_succession.re` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 5 ust. 1 | `jdg.business.succession_continuity` | `business.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 3 | `jdg.business.succession_manager_appointment` | `business/plan26_suspension_succession.re` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.business.succession_manager_valid` | `business.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 3 | `jdg.business.succession_no_manager_expiry` | `business.rego` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 14 | `jdg.business.succession_termination_events` | `business/plan26_suspension_succession.re` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.business.succession_time_limit_expiry` | `business/plan26_suspension_succession.re` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.business.suspension_period_boundary` | `business.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 22 | `jdg.business.suspension_valid` | `business.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.business.suspension_zus` | `business.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.business.tax_form_change_inventory` | `business.rego` | 🟡 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 5 ust. 1 | `jdg.business.tax_form_change_kup_correction` | `business.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 5 | `jdg.business.unregistered_activity_limit_exceeded` | `business.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.business.unregistered_limit_check` | `business.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.alert_1_day_before` | `calendar/plan45_calendar.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.alert_3_days_before` | `calendar/plan45_calendar.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.alert_7_days_before` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 56 | `jdg.calendar.hyper.alert_on_deadline_day` | `calendar/plan45_calendar.rego` | 🔴 | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.alert_overdue` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.christmas_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  | Art. 12 | `jdg.calendar.hyper.easter_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.forecast_annual_tax` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.forecast_history_trend` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.forecast_next_quarter` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.forecast_optimization` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.holiday_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 10 ust. 1 | `jdg.calendar.hyper.pcc3_deadline_14days` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 9 | `jdg.calendar.hyper.pcc_arrears` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.pcc_exemptions_check` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.pcc_payment_14days` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 56 | `jdg.calendar.hyper.pcc_weekend_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 21 ust. 1 | `jdg.calendar.hyper.pit_advance_20th` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.pit_annual_return_30april` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 56 | `jdg.calendar.hyper.pit_shift_weekend` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.vat_quarterly_25th` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 56 | `jdg.calendar.hyper.vat_weekend_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.weekend_shift_saturday` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.weekend_shift_sunday` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 10 ust. 1 | `jdg.calendar.hyper.zus_arrears` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.zus_units_15th` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.overdue_alerts` | `calendar/plan44_calendar.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.zus_deadlines` | `calendar/plan44_calendar.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.cashflow.annual_settlement_forecast` | `cashflow_tax_predictor_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.cashflow.seasonal_pattern_detection` | `cashflow_tax_predictor_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cashflow.tax_deadline_calendar` | `cashflow_tax_predictor_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cashflow.tax_liability_forecast_90d` | `cashflow_tax_predictor_enterprise.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.a45.u5.p4` | `micro/crossborder/crossborder.rego` | — | ⬜ | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.cb.r1` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r10` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r11` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r12` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | ⬜ | 🟡 |
| ... | ... | ... | ... | ... | ... | ... | ... | *(12086 więcej reguł)* |

## Statystyki

| Metryka | Wartość |
|---------|---------|
| Reguł z testem | 3/12286 (0%) |
| Reguł z podstawą prawną | 11465/12286 |
| Reguł BLOCK_AND_ALERT | 839 |
| Reguł TRIAGE_QUEUE | 668 |

---
*Wygenerowano automatycznie — 2026-08-08 12:11:30*
*Innowacja 10 — `python JDG/tools/traceability_matrix.py`*