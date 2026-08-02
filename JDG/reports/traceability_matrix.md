# 🔗 Doc-to-Rego Traceability Matrix — NexusAI JDG v8.0

> **Wygenerowano:** 2026-08-02 08:41:41 | **Innowacja 10**
> **Reguł:** 11250 | **Testów:** 10 | **ADR-ów:** 14

## Macierz identyfikowalności

| Akt | Artykuł | Rule ID | Plik | Routing | Test? | ADR | Status |
|-----|---------|---------|------|:-------:|:-----:|-----|:------:|
|  |  | `jdg.accounting.depreciation.fallback` | `accounting/depreciation_enterprise.rego` | — | ✅ | ⬜ | ✅ |
|  |  | `jdg.accounting.fixed_asset_kst_group` | `accounting.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.accounting.kst_group_classification` | `accounting.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.accounting.lease_classification_test` | `accounting/plan23_leasing.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.accounting.no_match` | `accounting.rego` | — | ✅ | ⬜ | ✅ |
|  |  | `jdg.accounting.pkpir.fallback_no_match` | `accounting/pkpir_enterprise_validator.re` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.accounting.pkpir_fallback` | `accounting/pkpir_enterprise_validation.r` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.accounting.pkpir_remnant_consistency` | `accounting/plan42_pkpir.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.advertising.foreign_markets_kup` | `advertising/plan44_advertising.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.advertising.hyper.car_wrapping_vat26_full` | `advertising/plan45_advertising.rego` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 4 | `jdg.agricultural_tax.r1` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.agricultural_tax.r2` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 2 | `jdg.agricultural_tax.r3` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 6 | `jdg.agricultural_tax.r4` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.agricultural_tax.r5` | `micro/plan33_agricultural_tax.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.allowances.abolition_relief` | `allowances/plan23_reliefs.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.allowances.relief_rd_carry_forward` | `allowances.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.aml_full.a50.u5.p4` | `micro/aml/aml.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.annual_decl.relief_cross_validation` | `annual_declaration_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.api_fallback.multi_degradation` | `api_fallback.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.api_fallback.nbp_rate_fallback` | `api_fallback.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.api_fallback.whitelist_degradation` | `api_fallback.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.closure_and_follow_up` | `audit/plan44_audit.rego` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 220 | `jdg.audit.correction_during_audit` | `audit/plan44_audit.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.hyper.aggregate_risk_update` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 292 | `jdg.audit.hyper.closure_correction_window` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 81b | `jdg.audit.hyper.closure_decision_deadline` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 107 | `jdg.audit.hyper.closure_decision_issuance` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 107 | `jdg.audit.hyper.cross_border_foreign_officials` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.hyper.cross_border_mutual_assistance` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.hyper.cross_border_simultaneous` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 180a | `jdg.audit.hyper.doc_electronic_evidence` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.doc_foreign_language` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 193a | `jdg.audit.hyper.doc_seizure_duration` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 288 | `jdg.audit.hyper.doc_seizure_receipt` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 119b | `jdg.audit.hyper.followup_deadline_monitoring` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 292 | `jdg.audit.hyper.followup_recommendations` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 272 | `jdg.audit.hyper.no_match` | `audit/plan45_audit.rego` | — | ✅ | ⬜ | ✅ |
|  | Art. 287 | `jdg.audit.hyper.obligation_allow_inspection` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 287 | `jdg.audit.hyper.obligation_provide_docs` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.obligation_provide_explanations` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 70 | `jdg.audit.hyper.obligation_retain_audit_docs` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 86 | `jdg.audit.hyper.obligation_sign_protocol` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 288 | `jdg.audit.hyper.penalty_coercion` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 151 | `jdg.audit.hyper.penalty_obstruction_kks69` | `audit/plan45_audit.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.protocol_deadline_14days` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 138e | `jdg.audit.hyper.protocol_electronic_service` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.protocol_objections_period` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 144b | `jdg.audit.hyper.protocol_objections_to_director` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.protocol_required_elements` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 138e | `jdg.audit.hyper.representation_access_files` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit.hyper.representation_participation` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 138e | `jdg.audit.hyper.representation_pps1` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 178 | `jdg.audit.hyper.representation_upl1` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 52 | `jdg.audit.hyper.right_appeal_14days` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  | Art. 84c | `jdg.audit.hyper.right_break_request` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  | Art. 81b | `jdg.audit.hyper.right_correction_minus_blocked` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 200 | `jdg.audit.hyper.right_correction_plus_allowed` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 199 | `jdg.audit.hyper.right_exclusion_inspector` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 285 | `jdg.audit.hyper.right_no_notification_exceptions` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 282b | `jdg.audit.hyper.right_notification_7days` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 286 | `jdg.audit.hyper.right_object_to_protocol` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 81b | `jdg.audit.hyper.right_oppose_inspection` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 130 | `jdg.audit.hyper.right_presence` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 84c | `jdg.audit.hyper.right_record_activities` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 291 | `jdg.audit.hyper.right_refuse_self_incrimination` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 223 | `jdg.audit.hyper.right_to_be_heard` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  | Art. 287 | `jdg.audit.hyper.right_wsa_30days` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 262 | `jdg.audit.hyper.statute_resume_after_close` | `audit/plan45_audit.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 70 | `jdg.audit.hyper.statute_suspension_duration` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 70 | `jdg.audit.hyper.statute_suspension_effect` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 274 | `jdg.audit.hyper.trigger_cross_checking` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 282b | `jdg.audit.hyper.trigger_external_information` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 281 | `jdg.audit.hyper.trigger_inspection_warrant` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 283 | `jdg.audit.hyper.trigger_return_to_correct` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 272 | `jdg.audit.hyper.type_customs_fiscal` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 120 | `jdg.audit.hyper.type_tax_audit` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  | Art. 54 | `jdg.audit.hyper.type_tax_proceeding` | `audit/plan45_audit.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  | Art. 281 | `jdg.audit.hyper.type_verification` | `audit/plan45_audit.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.audit_defense.statute_of_limitations` | `audit_defense_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.ceidg1_autofill` | `p16_autoform_generator_enterprise.rego` | 🟡 | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.no_match` | `p16_autoform_generator_enterprise.rego` | 🟡 | ✅ | ⬜ | ✅ |
|  |  | `jdg.autoform.notarial_deed_template` | `p16_autoform_generator_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.pit_employee_autofill` | `p16_autoform_generator_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.receipt_generator` | `p16_autoform_generator_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.vat_z_autofill` | `p16_autoform_generator_enterprise.rego` | 🟡 | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.zus_zua_autofill` | `p16_autoform_generator_enterprise.rego` | 🟡 | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.autoform.zus_zwua_autofill` | `p16_autoform_generator_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 64 | `jdg.banking.ais_account_information` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 92 | `jdg.banking.bank_profile_routing` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.batch_payment_format` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 97 | `jdg.banking.elixir_payload_generator` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 66 | `jdg.banking.iban_validation` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.oauth2_eidas_token_management` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.payment_status_tracking` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.pis_payment_initiation` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking.psd2_compliance_audit` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 67 | `jdg.banking.psd2_consent_management` | `banking_automation_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.banking_sca.ais_consent_renewal` | `p16_enhanced_sca_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.banking_sca.eidas_certificates` | `p16_enhanced_sca_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.banking_sca.method_selection` | `p16_enhanced_sca_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.banking_sca.no_match` | `p16_enhanced_sca_enterprise.rego` | — | ✅ | ⬜ | ✅ |
|  |  | `jdg.business.gig_economy.mileage_tracking` | `business/gig_economy.rego` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 12 ust. 1 | `jdg.business.gig_economy.platform_commission_impor` | `business/gig_economy.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 3 | `jdg.business.max_suspension_block` | `business.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  | Art. 3 | `jdg.business.maximum_suspension_period_check` | `business/plan26_suspension_succession.re` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.business.no_match` | `business/plan26_suspension_succession.re` | 🟡 | ✅ | ⬜ | ✅ |
|  | Art. 22 | `jdg.business.no_match` | `business.rego` | — | ✅ | ⬜ | ✅ |
|  | Art. 22 | `jdg.business.resumption_procedure` | `business.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.business.resumption_procedure_valid` | `business/plan26_suspension_succession.re` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 5 | `jdg.business.succession_continuity` | `business.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.business.succession_manager_appointment` | `business/plan26_suspension_succession.re` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.business.succession_manager_valid` | `business.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.business.succession_termination_events` | `business/plan26_suspension_succession.re` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 14 | `jdg.business.succession_time_limit_expiry` | `business/plan26_suspension_succession.re` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.business.suspension_valid` | `business.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.business.suspension_zus` | `business.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 22 | `jdg.business.tax_form_change_inventory` | `business.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.business.tax_form_change_kup_correction` | `business.rego` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 5 | `jdg.business.unregistered_activity_limit_exceeded` | `business.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.alert_1_day_before` | `calendar/plan45_calendar.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.alert_3_days_before` | `calendar/plan45_calendar.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.alert_7_days_before` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 56 | `jdg.calendar.hyper.alert_on_deadline_day` | `calendar/plan45_calendar.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.alert_overdue` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.christmas_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 12 | `jdg.calendar.hyper.easter_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.forecast_annual_tax` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.forecast_history_trend` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.forecast_next_quarter` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.hyper.forecast_optimization` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.holiday_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 10 ust. 1 | `jdg.calendar.hyper.pcc3_deadline_14days` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 9 | `jdg.calendar.hyper.pcc_arrears` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.pcc_exemptions_check` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.pcc_payment_14days` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 56 | `jdg.calendar.hyper.pcc_weekend_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 21 ust. 1 | `jdg.calendar.hyper.pit_advance_20th` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.pit_annual_return_30april` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 56 | `jdg.calendar.hyper.pit_shift_weekend` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.vat_quarterly_25th` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 56 | `jdg.calendar.hyper.vat_weekend_shift` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.weekend_shift_saturday` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.weekend_shift_sunday` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 10 ust. 1 | `jdg.calendar.hyper.zus_arrears` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 12 | `jdg.calendar.hyper.zus_units_15th` | `calendar/plan45_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.overdue_alerts` | `calendar/plan44_calendar.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.calendar.zus_deadlines` | `calendar/plan44_calendar.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.cashflow.annual_settlement_forecast` | `cashflow_tax_predictor_enterprise.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.cashflow.seasonal_pattern_detection` | `cashflow_tax_predictor_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cashflow.tax_deadline_calendar` | `cashflow_tax_predictor_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cashflow.tax_liability_forecast_90d` | `cashflow_tax_predictor_enterprise.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.a45.u5.p4` | `micro/crossborder/crossborder.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.cb.r1` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r10` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r11` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r12` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r13` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r14` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r15` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r16` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r17` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r18` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r19` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r2` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r20` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r3` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r4` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r5` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r6` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r7` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r8` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cb.r9` | `micro/plan33_cb.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.cbam_full.certificate_tracker` | `cbam_full.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.cbam_full.no_match` | `cbam_full.rego` | — | ✅ | ⬜ | ✅ |
|  | Art. 20 | `jdg.cbam_full.quarterly_reporting` | `cbam_full.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.cbam_full.sector_classification` | `cbam_full.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.ceidg.r9` | `micro/plan33_ceidg.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.cfc_auto_classifier.jurisdiction_check` | `cfc_auto_classifier.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.compliance.aml.cbdd_discrepancy_penalty` | `compliance/aml_enterprise.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  | Art. 63 | `jdg.compliance.aml.cbdd_registration` | `compliance/aml_enterprise.rego` | 🟡 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.compliance.aml.crypto_travel_rule` | `compliance/aml_enterprise.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.compliance.aml.fallback` | `compliance/aml_enterprise.rego` | — | ✅ | ⬜ | ✅ |
|  |  | `jdg.compliance.cash_register_b2c_exemption` | `compliance.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.compliance.cesop_cross_border` | `compliance.rego` | — | ⬜ | ⬜ | ⬜ |
|  |  | `jdg.compliance.no_match` | `compliance.rego` | 🟡 | ✅ | ⬜ | ✅ |
|  |  | `jdg.compliance.vat_simplified_receipt_over_limit` | `compliance.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.conflicts.borderline_expense_event` | `conflicts.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.conflicts.fx_rate_source_conflict_nbp_a_vs_c` | `conflicts.rego` | — | ⬜ | ⬜ | ⬜ |
|  | Art. 33 | `jdg.conviction.hyper.bank_account_seizure` | `conviction/plan45_conviction.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.conviction.hyper.bank_account_termination` | `conviction/plan45_conviction.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 41 | `jdg.conviction.hyper.business_ban_art41kk` | `conviction/plan45_conviction.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  | Art. 119b | `jdg.conviction.hyper.cash_monitoring_enhanced` | `conviction/plan45_conviction.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 21 | `jdg.conviction.hyper.collateral_required` | `conviction/plan45_conviction.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.conviction.hyper.contract_termination_clauses` | `conviction/plan45_conviction.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.conviction.hyper.enhanced_aml_kyc` | `conviction/plan45_conviction.rego` | — | ⬜ | ⬜ | 🟡 |
|  | Art. 119b | `jdg.conviction.hyper.enhanced_audit_scrutiny` | `conviction/plan45_conviction.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.conviction.hyper.eu_funds_exclusion` | `conviction/plan45_conviction.rego` | 🔴 | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.conviction.hyper.extended_audit_period` | `conviction/plan45_conviction.rego` | — | ⬜ | ⬜ | 🟡 |
|  |  | `jdg.conviction.hyper.fintech_access_restriction` | `conviction/plan45_conviction.rego` | — | ⬜ | ⬜ | 🟡 |
| ... | ... | ... | ... | ... | ... | ... | *(11050 więcej reguł)* |

## Statystyki

| Metryka | Wartość |
|---------|---------|
| Reguł z testem | 3/11250 (0%) |
| Reguł z podstawą prawną | 10314/11250 |
| Reguł BLOCK_AND_ALERT | 749 |
| Reguł TRIAGE_QUEUE | 613 |

---
*Wygenerowano automatycznie — 2026-08-02 08:41:41*
*Innowacja 10 — `python JDG/tools/traceability_matrix.py`*