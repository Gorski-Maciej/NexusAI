# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY V3-P44 CERTYFIKACJA FINALNA (negative-first, P39-I04)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p44_certyfikacja_finalna_test

import future.keywords.in

import data.jdg.v3_p44_certyfikacja_finalna

# ── Helper ─────────────────────────────────────────────────────────────────────
p44_input(analysis, ctx) = {
    "jdg_entrepreneur": {"v3_p44_check": true},
    "v3_p44": object.union({"analysis": analysis}, ctx),
}

# ═══════════════════════════════════════════════════════════════════════════════
# Brak flagi → no_match; brak selektora → no_match (determinizm łańcucha)
# ═══════════════════════════════════════════════════════════════════════════════
test_p44_no_activation_no_match {
    r := v3_p44_certyfikacja_finalna.decide with input as {"v3_p44": {"analysis": "hard_gate_certificate"}}
    r.rule_id == "jdg.v3_p44_certyfikacja_finalna.no_match"
}

test_p44_no_selector_no_match {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("brak_takiej_analizy", {})
    r.rule_id == "jdg.v3_p44_certyfikacja_finalna.no_match"
}

test_p44_thresholds_missing_fail_closed {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("hard_gate_certificate", {})
        with data.jdg.thresholds.v3_p44 as {}
    r.rule_id == "jdg.v3_p44_certyfikacja_finalna.thresholds_missing"
    r._routing == "BLOCK_AND_ALERT"
}

# ── I01: hard gate certificate ─────────────────────────────────────────────────
test_p44_i01_ok_certified {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("hard_gate_certificate", {"hard_gates": {"g1": true, "g2": true}})
    r.rule_id == "jdg.v3_p44_certyfikacja_finalna.hard_gate_certificate"
    r.decision_mode == "CERTIFIED"
    r._routing == "AUTO_FILE"
}

test_p44_i01_failed_gate_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("hard_gate_certificate", {"hard_gates": {"g1": true, "g2": false}})
    r.decision_mode == "NO_CERT"
    r._routing == "BLOCK_AND_ALERT"
}

test_p44_i01_open_p0_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("hard_gate_certificate", {"hard_gates": {"g1": true}, "open_p0_gaps": 2})
    r._routing == "BLOCK_AND_ALERT"
    r.open_p0_gaps == 2
}

# ── I02: pillar scoreboard ─────────────────────────────────────────────────────
test_p44_i02_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("pillar_scoreboard", {"pillars": {"legal_twin": {"status": "CZĘŚCIOWE", "evidence": "legal_graph.json"}}})
    r._routing == "AUTO_FILE"
}

test_p44_i02_declared_without_plan_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("pillar_scoreboard", {"pillars": {"radar": {"status": "DEKLAROWANE", "evidence": "x", "closure_plan": ""}}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p44_i02_no_evidence_triage {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("pillar_scoreboard", {"pillars": {"radar": {"status": "DOWIEDZONE", "evidence": ""}}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I03: campaign aggregate ledger ─────────────────────────────────────────────
test_p44_i03_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("campaign_aggregate_ledger", {"gap_aggregate": {"unique_gaps": ["a", "b"], "duplicate_keys": [], "p0_open": 0}})
    r._routing == "AUTO_FILE"
}

test_p44_i03_open_p0_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("campaign_aggregate_ledger", {"gap_aggregate": {"unique_gaps": ["a"], "duplicate_keys": [], "p0_open": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p44_i03_duplicates_triage {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("campaign_aggregate_ledger", {"gap_aggregate": {"unique_gaps": ["a"], "duplicate_keys": ["a"], "p0_open": 0}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I04: owner decision map ────────────────────────────────────────────────────
test_p44_i04_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("owner_decision_map", {"owner_decision_map": [{"priority": "P0", "decision_owner": "wlasciciel"}]})
    r._routing == "AUTO_FILE"
}

test_p44_i04_p0_unassigned_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("owner_decision_map", {"owner_decision_map": [{"priority": "P0", "decision_owner": ""}]})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I05: V4 inheritance contract ───────────────────────────────────────────────
test_p44_i05_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("v4_inheritance_contract", {"v4_inheritance_contracts": [{"source_of_truth": "ADR-004"}]})
    r._routing == "AUTO_FILE"
}

test_p44_i05_no_sot_triage {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("v4_inheritance_contract", {"v4_inheritance_contracts": [{"source_of_truth": ""}]})
    r._routing == "TRIAGE_QUEUE"
}

# ── I06: success metric freeze ─────────────────────────────────────────────────
test_p44_i06_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("success_metric_freeze", {"success_metrics": [{"threshold": 99}]})
    r._routing == "AUTO_FILE"
}

test_p44_i06_no_threshold_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("success_metric_freeze", {"success_metrics": [{"threshold": null}]})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I07: certificate WORM + signature ──────────────────────────────────────────
test_p44_i07_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("certificate_worm_signature", {"final_certificate": {"signature": "HSM-ECDSA", "worm": true, "retention_years": 5}})
    r._routing == "AUTO_FILE"
}

test_p44_i07_no_signature_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("certificate_worm_signature", {"final_certificate": {"signature": "", "worm": true, "retention_years": 5}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p44_i07_no_worm_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("certificate_worm_signature", {"final_certificate": {"signature": "HSM", "worm": false, "retention_years": 5}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p44_i07_low_retention_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("certificate_worm_signature", {"final_certificate": {"signature": "HSM", "worm": true, "retention_years": 3}})
    r._routing == "BLOCK_AND_ALERT"
    r.retention_min == 5
}

# ── I08: knowledge transfer pack ───────────────────────────────────────────────
test_p44_i08_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("knowledge_transfer_pack", {"knowledge_transfer_pack": {"required_artifacts": {"docs/x.md": true}}})
    r._routing == "AUTO_FILE"
}

test_p44_i08_missing_triage {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("knowledge_transfer_pack", {"knowledge_transfer_pack": {"required_artifacts": {"docs/x.md": false}}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I09: certification renewal policy ──────────────────────────────────────────
test_p44_i09_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("certification_renewal_policy", {"renewal_policy": {"days_since_certification": 10}})
    r._routing == "AUTO_FILE"
}

test_p44_i09_no_policy_blocks {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("certification_renewal_policy", {})
    r._routing == "BLOCK_AND_ALERT"
}

test_p44_i09_expired_triage {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("certification_renewal_policy", {"renewal_policy": {"days_since_certification": 120}})
    r._routing == "TRIAGE_QUEUE"
    r.validity_max_days == 90
}

# ── I10: legacy cleanup closure ────────────────────────────────────────────────
test_p44_i10_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("legacy_cleanup_closure", {})
    r._routing == "AUTO_FILE"
}

test_p44_i10_open_facades_triage {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("legacy_cleanup_closure", {"legacy_facades_open": 1})
    r._routing == "TRIAGE_QUEUE"
}

# ── I11: owner attestation ─────────────────────────────────────────────────────
test_p44_i11_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("owner_attestation", {"owner_attestation": {"signed": true}})
    r._routing == "AUTO_FILE"
}

test_p44_i11_unsigned_triage {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("owner_attestation", {"owner_attestation": {"signed": false}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I12: fortress self-portrait ────────────────────────────────────────────────
test_p44_i12_ok {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("fortress_self_portrait", {"self_portrait": {"rules": {"evidence_link": "rules/main_jdg.rego", "contract": "verdict"}}})
    r._routing == "AUTO_FILE"
}

test_p44_i12_no_evidence_triage {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("fortress_self_portrait", {"self_portrait": {"rules": {"evidence_link": "", "contract": "verdict"}}})
    r._routing == "TRIAGE_QUEUE"
}

# ── Metadane certyfikatu (F4) ──────────────────────────────────────────────────
test_p44_certificate_metadata_present {
    r := v3_p44_certyfikacja_finalna.decide with input as p44_input("legacy_cleanup_closure", {})
    r.threshold_version != "MISSING"
    r.priority == 444010
}
