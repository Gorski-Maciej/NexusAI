# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY V3-P43 SECURITY I DR (negative-first, P39-I04)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p43_security_dr_test

import future.keywords.in

import data.jdg.v3_p43_security_dr

# ── Helper ─────────────────────────────────────────────────────────────────────
p43_input(analysis, ctx) = {
    "jdg_entrepreneur": {"v3_p43_check": true},
    "v3_p43": object.union({"analysis": analysis}, ctx),
}

# ═══════════════════════════════════════════════════════════════════════════════
# Brak flagi → no_match
# ═══════════════════════════════════════════════════════════════════════════════
test_p43_no_activation_no_match {
    r := v3_p43_security_dr.decide with input as {"v3_p43": {"analysis": "threat_model"}}
    r.rule_id == "jdg.v3_p43_security_dr.no_match"
}

# ── I01: threat model ──────────────────────────────────────────────────────────
test_p43_i01_ok {
    r := v3_p43_security_dr.decide with input as p43_input("threat_model", {})
    r.rule_id == "jdg.v3_p43_security_dr.threat_model"
    r._routing == "SUGGEST"
}

test_p43_i01_facade_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("threat_model", {"threat_model_facade": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i01_untested_controls_triage {
    r := v3_p43_security_dr.decide with input as p43_input("threat_model", {"threat_model": {"controls_without_tests": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I02: rule quarantine ───────────────────────────────────────────────────────
test_p43_i02_ok {
    r := v3_p43_security_dr.decide with input as p43_input("rule_quarantine", {})
    r.rule_id == "jdg.v3_p43_security_dr.rule_quarantine"
    r._routing == "SUGGEST"
}

test_p43_i02_missing_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("rule_quarantine", {"quarantine_mechanism_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i02_no_deadline_triage {
    r := v3_p43_security_dr.decide with input as p43_input("rule_quarantine", {"rule_quarantine": {"quarantined_without_deadline": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I03: dual control ──────────────────────────────────────────────────────────
test_p43_i03_ok {
    r := v3_p43_security_dr.decide with input as p43_input("dual_control", {})
    r.rule_id == "jdg.v3_p43_security_dr.dual_control"
    r._routing == "SUGGEST"
}

test_p43_i03_missing_approval_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("dual_control", {"dual_control": {"deploys_without_dual_approval": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i03_procedural_only_triage {
    r := v3_p43_security_dr.decide with input as p43_input("dual_control", {"dual_control_procedural_only": true})
    r._routing == "TRIAGE_QUEUE"
}

# ── I04: secrets rotation ──────────────────────────────────────────────────────
test_p43_i04_ok {
    r := v3_p43_security_dr.decide with input as p43_input("secrets_rotation", {})
    r.rule_id == "jdg.v3_p43_security_dr.secrets_rotation"
    r._routing == "SUGGEST"
}

test_p43_i04_no_rotation_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("secrets_rotation", {"rotation_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i04_no_old_key_test_triage {
    r := v3_p43_security_dr.decide with input as p43_input("secrets_rotation", {"secrets_rotation": {"rotations_without_old_key_test": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I05: chaos drill ───────────────────────────────────────────────────────────
test_p43_i05_ok {
    r := v3_p43_security_dr.decide with input as p43_input("chaos_drill", {})
    r.rule_id == "jdg.v3_p43_security_dr.chaos_drill"
    r._routing == "SUGGEST"
}

test_p43_i05_missing_triage {
    r := v3_p43_security_dr.decide with input as p43_input("chaos_drill", {"chaos_drill_missing": true})
    r._routing == "TRIAGE_QUEUE"
}

test_p43_i05_stale_triage {
    r := v3_p43_security_dr.decide with input as p43_input("chaos_drill", {"chaos_drill": {"days_since_last_drill": 120}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I06: restore drill ─────────────────────────────────────────────────────────
test_p43_i06_ok {
    r := v3_p43_security_dr.decide with input as p43_input("restore_drill", {})
    r.rule_id == "jdg.v3_p43_security_dr.restore_drill"
    r._routing == "SUGGEST"
}

test_p43_i06_missing_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("restore_drill", {"restore_drill_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i06_no_checksum_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("restore_drill", {"restore_drill": {"restores_without_checksum_verify": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I07: paper mode ────────────────────────────────────────────────────────────
test_p43_i07_ok {
    r := v3_p43_security_dr.decide with input as p43_input("paper_mode", {})
    r.rule_id == "jdg.v3_p43_security_dr.paper_mode"
    r._routing == "SUGGEST"
}

test_p43_i07_missing_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("paper_mode", {"paper_mode_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i07_no_reconciliation_triage {
    r := v3_p43_security_dr.decide with input as p43_input("paper_mode", {"paper_mode": {"manual_periods_without_reconciliation": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I08: tamper rule history ───────────────────────────────────────────────────
test_p43_i08_ok {
    r := v3_p43_security_dr.decide with input as p43_input("tamper_rule_history", {})
    r.rule_id == "jdg.v3_p43_security_dr.tamper_rule_history"
    r._routing == "SUGGEST"
}

test_p43_i08_broken_chain_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("tamper_rule_history", {"tamper_rule_history": {"chain_broken_entries": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i08_no_chain_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("tamper_rule_history", {"rule_history_no_chain": true})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I09: ransomware playbook ───────────────────────────────────────────────────
test_p43_i09_ok {
    r := v3_p43_security_dr.decide with input as p43_input("ransomware_playbook", {"ransomware_playbook": {"days_since_last_exercise": 30}})
    r.rule_id == "jdg.v3_p43_security_dr.ransomware_playbook"
    r._routing == "SUGGEST"
}

test_p43_i09_missing_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("ransomware_playbook", {"ransomware_playbook_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i09_not_exercised_triage {
    r := v3_p43_security_dr.decide with input as p43_input("ransomware_playbook", {"ransomware_playbook": {"days_since_last_exercise": 200}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I10: breach taxonomy ───────────────────────────────────────────────────────
test_p43_i10_ok {
    r := v3_p43_security_dr.decide with input as p43_input("breach_taxonomy", {})
    r.rule_id == "jdg.v3_p43_security_dr.breach_taxonomy"
    r._routing == "SUGGEST"
}

test_p43_i10_missing_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("breach_taxonomy", {"breach_taxonomy_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i10_unclassified_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("breach_taxonomy", {"breach_taxonomy": {"breaches_without_class": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I11: zero standing access ──────────────────────────────────────────────────
test_p43_i11_ok {
    r := v3_p43_security_dr.decide with input as p43_input("zero_standing_access", {})
    r.rule_id == "jdg.v3_p43_security_dr.zero_standing_access"
    r._routing == "SUGGEST"
}

test_p43_i11_standing_admin_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("zero_standing_access", {"zero_standing_access": {"standing_admin_accounts": 2}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i11_no_usage_proof_triage {
    r := v3_p43_security_dr.decide with input as p43_input("zero_standing_access", {"zero_standing_access": {"jit_sessions_without_usage_proof": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I12: DR continuity ─────────────────────────────────────────────────────────
test_p43_i12_ok {
    r := v3_p43_security_dr.decide with input as p43_input("dr_continuity", {})
    r.rule_id == "jdg.v3_p43_security_dr.dr_continuity"
    r._routing == "SUGGEST"
}

test_p43_i12_missing_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("dr_continuity", {"dr_mode_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p43_i12_unmarked_blocks {
    r := v3_p43_security_dr.decide with input as p43_input("dr_continuity", {"dr_continuity": {"dr_decisions_unmarked": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Certyfikat + priorytety + ochrona nazw
# ═══════════════════════════════════════════════════════════════════════════════
test_p43_certificate_fields_present {
    r := v3_p43_security_dr.decide with input as p43_input("threat_model", {})
    r.threshold_version == "security-dr-v3p43-2026.09"
    r.legal_basis_version == "security-dr-legal-2026.09"
    r.valid_from == "2026-01-01"
}

test_p43_priorities_unique_range {
    prios := [p |
        some a in ["threat_model", "rule_quarantine", "dual_control", "secrets_rotation", "chaos_drill", "restore_drill", "paper_mode", "tamper_rule_history", "ransomware_playbook", "breach_taxonomy", "zero_standing_access", "dr_continuity"]
        d := v3_p43_security_dr.decide with input as p43_input(a, {})
        p := d.priority
    ]
    count({p | some p in prios}) == 12
    max(prios) == 443012
    min(prios) == 443001
}

test_p43_no_test_prefix_rule_names {
    r := v3_p43_security_dr.decide with input as p43_input("threat_model", {})
    not startswith(r.rule_id, "jdg.v3_p43_security_dr.test_")
}
