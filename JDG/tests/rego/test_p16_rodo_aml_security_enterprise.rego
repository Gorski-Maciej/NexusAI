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

# ── 12. Główny decide (P16) + no_match ────────────────────────────────────────
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
}

test_p16_default_no_match {
    result := data.jdg.p16_rodo_aml_security_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.matched == false
    result.rule_id == "jdg.p16_rodo_aml_security_innovations.no_match"
}
