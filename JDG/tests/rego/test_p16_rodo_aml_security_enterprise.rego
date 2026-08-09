# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P16 RODO + AML + Compliance + Bezpieczeństwo + Audyt Enterprise — testy rego
# (RAPORT P16 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p16_rodo_aml_security

import future.keywords.in

# ── 1. Mapa pokrycia modułów RODO + AML + security + audit ────────────────────
test_p16_coverage_report {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_aml_coverage_report with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}} with
        data.jdg.p16_audit as {"modules": {
            "rodo": {"status": "COMPLETE"}, "rodo_extended": {"status": "COMPLETE"},
            "micro_rodo": {"status": "COMPLETE"}, "aml": {"status": "COMPLETE"},
            "micro_aml": {"status": "COMPLETE"}, "security": {"status": "COMPLETE"},
            "audit": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.summary.total == 7
    result.summary.complete == 7
    result.summary.missing == 0
}

# ── 2. AUDYT RODO (PRIORYTET — Sekcja 1) ──────────────────────────────────────
test_rodo_audit {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_audit with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}}
    result.rejestr_czynnosci.legal_basis == "Art. 30 RODO"
    result.retencja.years == 5
    result.erasure.deadline_days == 30
    result.sankcje.max_eur == 20000000
    result.sankcje.min_eur == 10000000
    count(result.integrated_packages) == 4
}

# ── 3. Automatyczny rejestr czynności (INN-01) ────────────────────────────────
test_rodo_register_automation {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_register_automation with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "rodo_register_entries": 12}}
    result.register_generated == true
    result.entries == 12
    "grudzień" in result.next_review
}

# ── 4. Tracker 72h breach (INN-02) ────────────────────────────────────────────
test_breach_72h_tracker_within {
    result := data.jdg.p16_rodo_aml_security_innovations.breach_72h_tracker with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "rodo_data_breach": true, "rodo_breach_hours_elapsed": 48}}
    result.within_deadline == true
    result.deadline_hours == 72
    result.sanction_risk_eur == 0
    result._routing == "TRIAGE_QUEUE"
    "W CIĄGU 72H" in result.action
}

test_breach_72h_tracker_exceeded {
    result := data.jdg.p16_rodo_aml_security_innovations.breach_72h_tracker with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "rodo_data_breach": true, "rodo_breach_hours_elapsed": 100}}
    result.within_deadline == false
    result.sanction_risk_eur == 20000000
    result._routing == "BLOCK_AND_ALERT"
    "PRZEKROCZONO 72H" in result.action
}

# ── 5. AUDYT AML (PRIORYTET ★ — Sekcja 2) ─────────────────────────────────────
test_aml_audit {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_audit with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}}
    result.cbdd.ubo != ""
    result.str_gif.deadline_days == 1
    result.transakcje.threshold_eur == 15000
    "15 000" in result.transakcje.obowiązek
    count(result.integrated_packages) == 3
}

# ── 6. Scoring ryzyka AML per klient (INN-03) ─────────────────────────────────
test_aml_risk_scoring_client_low {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_risk_scoring_client with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "aml_client": {"name": "Firma PL", "jurisdiction_risk": 10, "sector_risk": 10, "ownership_risk": 10}}
    result.risk_score == 10
    result.risk_level == "NISKIE"
    result.required_due_diligence == "CDD uproszczona"
}

test_aml_risk_scoring_client_high {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_risk_scoring_client with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "aml_client": {"name": "Offshore Ltd", "jurisdiction_risk": 100, "sector_risk": 100, "ownership_risk": 100}}
    result.risk_score == 100
    result.risk_level == "KRYTYCZNE"
    result._routing == "BLOCK_AND_ALERT"
    "CDD wzmożona" in result.required_due_diligence
}

# ── 7. Scoring ryzyka AML per transakcję (INN-04 — próg 15 000 EUR) ───────────
test_aml_risk_scoring_transaction_above_threshold {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_risk_scoring_transaction with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "aml_transaction": {"amount_eur": 20000, "anomaly_flags": ["SPLIT_TRANSACTIONS", "CASH_LARGE"]}}
    result.above_threshold == true
    result.threshold_eur == 15000
    result.str_required == true
    result.risk_level == "WYSOKIE"
}

test_aml_risk_scoring_transaction_below_threshold {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_risk_scoring_transaction with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "aml_transaction": {"amount_eur": 1000, "anomaly_flags": []}}
    result.above_threshold == false
    result.risk_score == 0
    result.risk_level == "NISKIE"
}

# ── 8. AUDYT BEZPIECZEŃSTWA SYSTEMU (Sekcja 3) ────────────────────────────────
test_security_audit {
    result := data.jdg.p16_rodo_aml_security_innovations.security_audit with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}}
    result.integralnosc.hmac_required == true
    result.immutable_verdicts.enabled == true
    count(result.ataki_blokowane) == 4
    count(result.forteca_warstwy) == 4
}

test_security_fortress_layers_ok {
    result := data.jdg.p16_rodo_aml_security_innovations.security_fortress_layers with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "rule_hmac_valid": true}}
    result.hmac_required == true
    count(result.layers) == 5
    result.rule_hash_verified == true
}

test_security_fortress_layers_tampered {
    result := data.jdg.p16_rodo_aml_security_innovations.security_fortress_layers with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "rule_hmac_valid": false}}
    result.rule_hash_verified == false
    result._routing == "BLOCK_AND_ALERT"
}

# ── 9. AUDYT AUDYTU I ŚCIEŻKI DECYZJI (Sekcja 4) ──────────────────────────────
test_audit_trail_audit {
    result := data.jdg.p16_rodo_aml_security_innovations.audit_trail_audit with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}}
    result.sciezka_decyzji.merkle_required == true
    result.provenance.obowiązek != ""
    count(result.integrated_packages) == 4
}

test_proof_chain_verifier {
    result := data.jdg.p16_rodo_aml_security_innovations.proof_chain_verifier with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "audit": {"decision_id": "D-1", "chain_links": [{"index": 0}], "root_hash": "abc", "hash_expected": "abc"}}
    result.chain_verified == true
    result.decision_id == "D-1"
}

# ── 10. PIPELINE COMPLIANCE (Sekcja 5 — ADR-002, ePrivacy, AMLR) ──────────────
test_compliance_pipeline_snapshot {
    result := data.jdg.p16_rodo_aml_security_innovations.compliance_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}}
    result.pipeline.step_1_ingest == "data.jdg.thresholds.compliance_aml_rodo (ADR-002) — sankcje RODO, progi AML, terminy"
    result.hot_reload == true
    result.auto_update_sources.amlr != ""
    result.auto_update_sources.eprivacy != ""
}

# ── 11. GENIALNE POMYSŁY (INN-07..INN-14) ─────────────────────────────────────
test_self_audit_engine {
    result := data.jdg.p16_rodo_aml_security_innovations.self_audit_engine with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}}
    count(result.checks) == 6
    result.auto_corrective != ""
}

test_aml_risk_panel {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_risk_panel with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "aml_panel": {"clients_high_risk": 2, "transactions_flagged": 3, "str_pending": 1}}
    result.str_pending == 1
    result.panel_level == "KRYTYCZNE — STR zaległe!"
    result._routing == "BLOCK_AND_ALERT"
}

test_rodo_breach_assistant {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_breach_assistant with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "rodo_breach_type": "DATA_BREACH"}}
    count(result.checklist) == 5
    "72h" in result.checklist[1]
}

test_decision_proof_chain {
    result := data.jdg.p16_rodo_aml_security_innovations.decision_proof_chain with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "audit": {"chain_blocks": 12}}
    result.blocks == 12
    "merkle" in result.chain_type
    count(result.use_cases) == 4
}

test_rule_integrity_hmac_ok {
    result := data.jdg.p16_rodo_aml_security_innovations.rule_integrity_hmac with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "packages_monitored": 25, "package_tampered": false}}
    result.packages_monitored == 25
    "OK" in result.integrity_status
    result._routing == ""
}

test_rule_integrity_hmac_tampered {
    result := data.jdg.p16_rodo_aml_security_innovations.rule_integrity_hmac with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "packages_monitored": 25, "package_tampered": true}}
    "TAMPERED" in result.integrity_status
    result._routing == "BLOCK_AND_ALERT"
}

test_rodo_sanctions_calculator {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_sanctions_calculator with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true,
                                       "rodo_violation_type": "DATA_BREACH_UNREPORTED",
                                       "annual_revenue_eur": 50000000}}
    result.max_fine_eur == 20000000
    result.revenue_based_fine == 2000000.0
    result.effective_fine_eur == 20000000
    result._routing == "BLOCK_AND_ALERT"
}

test_beneficiary_verifier_missing {
    result := data.jdg.p16_rodo_aml_security_innovations.beneficiary_verifier with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "aml_client": {"name": "Firma", "ubo_identified": false, "ubo_share_pct": 0}}
    result.ubo_identified == false
    result.threshold_25pct == 25
    result._routing == "TRIAGE_QUEUE"
    "BRAK IDENTYFIKACJI" in result.verification_status
}

test_beneficiary_verifier_ok {
    result := data.jdg.p16_rodo_aml_security_innovations.beneficiary_verifier with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "aml_client": {"name": "Firma", "ubo_identified": true, "ubo_share_pct": 60}}
    result.ubo_identified == true
    result._routing == ""
}

test_compliance_scorecard {
    result := data.jdg.p16_rodo_aml_security_innovations.compliance_scorecard with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "rodo_score": 100, "aml_score": 100, "security_score": 100}}
    result.score_total == 100
    result.grade == "A — PEŁNA ZGODNOŚĆ"
}

# ── 12. MAPA DROGOWA P0/P1/P2 (R16) ──────────────────────────────────────────
test_crbr_registry_api_missing {
    result := data.jdg.p16_rodo_aml_security_innovations.crbr_registry_api with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "crbr": {"nip": "7777777777", "registered": false}}
    result.registered == false
    result.registration_deadline_days == 7
    result.sanction_max_pln == 1000000
    result._routing == "TRIAGE_QUEUE"
    "BRAK REJESTRACJI W CRBR" in result.registration_status
}

test_crbr_registry_api_ok {
    result := data.jdg.p16_rodo_aml_security_innovations.crbr_registry_api with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "crbr": {"nip": "7777777777", "registered": true, "ubo_declared": true}}
    result.registered == true
    result._routing == ""
    result.ubo_declared == true
}

test_str_gijf_auto_submission_missing {
    result := data.jdg.p16_rodo_aml_security_innovations.str_gijf_auto_submission with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "str_gijf": {"str_id": "STR-001", "submitted": false, "confirmation_received": false, "days_since_detection": 3}}
    result.submitted == false
    result.deadline_working_days == 1
    result._routing == "BLOCK_AND_ALERT"
    "NIEZGŁOSZONE" in result.submission_status
}

test_str_gijf_auto_submission_ok {
    result := data.jdg.p16_rodo_aml_security_innovations.str_gijf_auto_submission with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "str_gijf": {"str_id": "STR-001", "submitted": true, "confirmation_received": true, "days_since_detection": 1}}
    result.submitted == true
    result.confirmation_received == true
    result._routing == ""
    "potwierdzone" in result.submission_status
}

test_subprocessor_saas_map {
    result := data.jdg.p16_rodo_aml_security_innovations.subprocessor_saas_map with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "subprocessors": {"used": ["HOSTING_CHMURY", "CRM"],
                                     "has_art28": {"HOSTING_CHMURY": false, "CRM": false},
                                     "has_subprocessing_consent": {"HOSTING_CHMURY": false, "CRM": false}}}
    count(result.used_processors) == 2
    count(result.missing_art28) == 2
    result.compliance_score == 0
    count(result.saas_catalog) >= 8
}

test_subprocessor_saas_map_empty {
    result := data.jdg.p16_rodo_aml_security_innovations.subprocessor_saas_map with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}}
    result.compliance_score == 100
    count(result.used_processors) == 0
}

test_rodo_deadline_calendar_december {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_deadline_calendar with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "current_month": 12}}
    count(result.calendar) >= 6
    result.next_review_month == 12
    "rejestru czynności" in result.upcoming_this_month[_]
}

test_rodo_deadline_calendar_june {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_deadline_calendar with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "current_month": 6}}
    "umów powierzenia" in result.upcoming_this_month[_]
}

test_aml_sanctions_screening_block {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_sanctions_screening with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "sanctions_screening": {"entity_name": "Entity X", "matched_lists": ["eu_consolidated", "un_sc"]}}
    result.sanctions_score == 100
    result._routing == "BLOCK_AND_ALERT"
    "KRYTYCZNE" in result.sanctions_level
    count(result.matched_details) == 2
}

test_aml_sanctions_screening_pep {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_sanctions_screening with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "sanctions_screening": {"entity_name": "Osoba Y", "matched_lists": ["pep_national"]}}
    result.sanctions_score == 20
    result._routing == "TRIAGE_QUEUE"
}

test_aml_sanctions_screening_clear {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_sanctions_screening with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "sanctions_screening": {"entity_name": "Firma Z", "matched_lists": []}}
    result.sanctions_score == 0
    result._routing == ""
}

test_amlr_2027_implementation_over {
    result := data.jdg.p16_rodo_aml_security_innovations.amlr_2027_implementation with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "amlr": {"cash_transaction_eur": 12000, "crypto_transaction_eur": 500, "entity_covered": true}}
    result.cash_over_threshold == true
    result.crypto_over_threshold == false
    result.application_from == "2027-07-10"
    result.cash_threshold_eur == 10000
    result._routing == "TRIAGE_QUEUE"
    "OBOWIĄZEK CBDD" in result.status
}

test_amlr_2027_implementation_below {
    result := data.jdg.p16_rodo_aml_security_innovations.amlr_2027_implementation with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "amlr": {"cash_transaction_eur": 5000, "crypto_transaction_eur": 500, "entity_covered": true}}
    result.cash_over_threshold == false
    result._routing == ""
    "poniżej progów" in result.status
}

test_compliance_dashboard_ui_block {
    result := data.jdg.p16_rodo_aml_security_innovations.compliance_dashboard_ui with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "dashboard": {"clients_high_risk": 1, "transactions_flagged": 2, "str_pending": 1, "breaches_open": 2}}
    result.aml_panel.str_pending == 1
    result.breach_72h.deadline_hours == 72
    result.breach_72h.within_deadline == false
    result._routing == "BLOCK_AND_ALERT"
}

test_compliance_dashboard_ui_ok {
    result := data.jdg.p16_rodo_aml_security_innovations.compliance_dashboard_ui with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true},
                  "dashboard": {"clients_high_risk": 0, "transactions_flagged": 0, "str_pending": 0, "breaches_open": 0}}
    result.breach_72h.within_deadline == true
    result.aml_panel.panel_score == 0
}

# ── 13. Główny decide (P16) + no_match ────────────────────────────────────────
test_p16_main_decide {
    result := data.jdg.p16_rodo_aml_security_innovations.decide with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}}
    result.matched == true
    result.rule_id == "jdg.p16_rodo_aml_security_innovations.report"
    result._routing == "REPORT"
    result.rodo.rejestr_czynnosci.legal_basis == "Art. 30 RODO"
    result.aml.transakcje.threshold_eur == 15000
    result.security.integralnosc.hmac_required == true
    result.audit_trail.sciezka_decyzji.merkle_required == true
    result.roadmap.crbr_registry_api.registration_deadline_days == 7
    result.roadmap.amlr_2027_implementation.application_from == "2027-07-10"
    count(result.roadmap) == 7
}

test_p16_default_no_match {
    result := data.jdg.p16_rodo_aml_security_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.matched == false
    result.rule_id == "jdg.p16_rodo_aml_security_innovations.no_match"
}

# ── SEKCJA 8: innowacje INN-15..19 ────────────────────────────────────────────
test_aml_obligation_detector {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_obligation_detector with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}, "company_setup": {"activity_desc": "doradca podatkowy"}}
    result.obliged_entity == true
    result._routing == "AML_OBLIGATION_QUEUE"
    contains(result.obligation_source, "art. 2 ust. 1")
    count(result.required_measures) == 5
}

test_aml_obligation_detector_clean {
    result := data.jdg.p16_rodo_aml_security_innovations.aml_obligation_detector with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}, "company_setup": {"activity_desc": "usługi księgowe"}}
    result.obliged_entity == false
    result._routing == ""
    count(result.required_measures) == 0
}

test_rodo_by_design_anonymizer {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_by_design_anonymizer with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}, "verdict": {"fields": ["NIP", "kwota"]}}
    result.verdict_contains_pii == true
    result.pii_fields_detected == ["NIP"]
    result._routing == "PII_STRIP_QUEUE"
    result.anonymized_verdict == false
}

test_rodo_by_design_clean {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_by_design_anonymizer with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}, "verdict": {"fields": ["kwota", "data"]}}
    result.verdict_contains_pii == false
    result.anonymized_verdict == true
    result._routing == ""
    result.hash_verdict_id == true
}

test_rodo_request_workflow {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_request_workflow with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}, "rodo_request": {"type": "USUNIECIE", "days_elapsed": 5}}
    result.request_type == "USUNIECIE"
    result.deadline_days == 30
    result.days_remaining == 25
    result.overdue == false
    contains(result.template, "art. 17")
    result._routing == "RODO_REQUEST_QUEUE"
}

test_rodo_request_workflow_overdue {
    result := data.jdg.p16_rodo_aml_security_innovations.rodo_request_workflow with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}, "rodo_request": {"type": "DOSTEP", "days_elapsed": 35}}
    result.days_remaining == 0
    result.overdue == true
    result._routing == "RODO_REQUEST_OVERDUE"
    contains(result.template, "art. 15")
}

test_penalty_simulator {
    result := data.jdg.p16_rodo_aml_security_innovations.penalty_simulator with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true, "annual_revenue_eur": 0}, "penalty_sim": {"scenario": "DATA_BREACH_UNREPORTED"}}
    result.rodo_fine_eur == 20000000
    result.aml_fine_pln == 0
    result._routing == "BLOCK_AND_ALERT"
}

test_penalty_simulator_aml {
    result := data.jdg.p16_rodo_aml_security_innovations.penalty_simulator with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}, "penalty_sim": {"scenario": "NO_STR"}}
    result.aml_fine_pln == 1000000
    result._routing == "BLOCK_AND_ALERT"
}

test_dead_data_monitor {
    result := data.jdg.p16_rodo_aml_security_innovations.dead_data_monitor with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}, "retention": {"expiring_30d": 3, "expired": 0}}
    result.expiring_30d == 3
    result.action_required == true
    result._routing == "TRIAGE_QUEUE"
}

test_dead_data_monitor_expired {
    result := data.jdg.p16_rodo_aml_security_innovations.dead_data_monitor with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}, "retention": {"expired": 2}}
    result.expired == 2
    result._routing == "DATA_RETENTION_ALERT"
    contains(result.retention_policy.ksiegowe_5_lat, "art. 74")
}

test_p16_decide_includes_innovations_v9 {
    result := data.jdg.p16_rodo_aml_security_innovations.decide with
        input as {"jdg_entrepreneur": {"p16_compliance_check": true}}
    result.innovations_v9.aml_obligation_detector.obliged_entity == false
    result.innovations_v9.rodo_by_design_anonymizer.anonymized_verdict == true
    result.innovations_v9.rodo_request_workflow.deadline_days == 30
    result.innovations_v9.penalty_simulator.aml_fine_pln == 0
    result.innovations_v9.dead_data_monitor.action_required == false
}
