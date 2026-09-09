# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY V3-P41 DOKUMENTACJA (negative-first, konwencja P39-I04)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p41_dokumentacja_test

import future.keywords.in

import data.jdg.v3_p41_dokumentacja

# ── Helper ─────────────────────────────────────────────────────────────────────
p41_input(analysis, ctx) = {
    "jdg_entrepreneur": {"v3_p41_check": true},
    "v3_p41": object.union({"analysis": analysis}, ctx),
}

# ═══════════════════════════════════════════════════════════════════════════════
# Brak flagi → no_match
# ═══════════════════════════════════════════════════════════════════════════════
test_p41_no_activation_no_match {
    r := v3_p41_dokumentacja.decide with input as {"v3_p41": {"analysis": "doc_code_binding"}}
    r.rule_id == "jdg.v3_p41_dokumentacja.no_match"
}

# ── I01: doc-code binding ──────────────────────────────────────────────────────
test_p41_i01_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("doc_code_binding", {"docs_gate_in_ci": true})
    r.rule_id == "jdg.v3_p41_dokumentacja.doc_code_binding"
    r._routing == "SUGGEST"
}

test_p41_i01_no_binding_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("doc_code_binding", {"doc_binding_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p41_i01_no_ci_gate_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("doc_code_binding", {})
    r._routing == "BLOCK_AND_ALERT"
}

test_p41_i01_stale_bindings_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("doc_code_binding", {"docs_gate_in_ci": true, "doc_code_binding": {"stale_bindings": 2}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I02: SSOT numbers ──────────────────────────────────────────────────────────
test_p41_i02_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("ssot_numbers", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.ssot_numbers"
    r._routing == "SUGGEST"
}

test_p41_i02_no_validator_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("ssot_numbers", {"consistency_validator_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p41_i02_handwritten_drift_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("ssot_numbers", {"ssot_numbers": {"handwritten_numbers_in_drift": 3}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I03: role doc maps ─────────────────────────────────────────────────────────
test_p41_i03_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("role_doc_maps", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.role_doc_maps"
    r._routing == "SUGGEST"
}

test_p41_i03_missing_role_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("role_doc_maps", {"role_doc_maps": {"roles_without_map": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I04: semantic diff PL/EN ───────────────────────────────────────────────────
test_p41_i04_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("semantic_diff_pl_en", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.semantic_diff_pl_en"
    r._routing == "SUGGEST"
}

test_p41_i04_no_tool_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("semantic_diff_pl_en", {"semantic_diff_tool_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p41_i04_drift_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("semantic_diff_pl_en", {"semantic_diff_pl_en": {"drift_findings": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I05: glossary enforcement ──────────────────────────────────────────────────
test_p41_i05_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("glossary_enforcement", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.glossary_enforcement"
    r._routing == "SUGGEST"
}

test_p41_i05_no_source_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("glossary_enforcement", {"glossary_source_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p41_i05_violations_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("glossary_enforcement", {"glossary_enforcement": {"glossary_violations": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I06: audit export pack ─────────────────────────────────────────────────────
test_p41_i06_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("audit_export_pack", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.audit_export_pack"
    r._routing == "SUGGEST"
}

test_p41_i06_no_checksum_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("audit_export_pack", {"audit_export_pack": {"exports_without_checksum": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p41_i06_missing_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("audit_export_pack", {"audit_export_missing": true})
    r._routing == "TRIAGE_QUEUE"
}

# ── I07: runbook coverage ──────────────────────────────────────────────────────
test_p41_i07_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("runbook_coverage", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.runbook_coverage"
    r._routing == "SUGGEST"
}

test_p41_i07_uncovered_alert_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("runbook_coverage", {"runbook_coverage": {"alerts_without_runbook": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I08: changelog automation ──────────────────────────────────────────────────
test_p41_i08_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("changelog_automation", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.changelog_automation"
    r._routing == "SUGGEST"
}

test_p41_i08_manual_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("changelog_automation", {"changelog_manual": true})
    r._routing == "TRIAGE_QUEUE"
}

test_p41_i08_stale_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("changelog_automation", {"changelog_automation": {"changelog_age_days": 30}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I09: freshness stamps ──────────────────────────────────────────────────────
test_p41_i09_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("freshness_stamps", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.freshness_stamps"
    r._routing == "SUGGEST"
}

test_p41_i09_stale_docs_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("freshness_stamps", {"freshness_stamps": {"docs_stale": 1}})
    r._routing == "TRIAGE_QUEUE"
}

test_p41_i09_missing_stamp_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("freshness_stamps", {"freshness_stamps": {"docs_without_stamp": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I10: doc testing ───────────────────────────────────────────────────────────
test_p41_i10_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("doc_testing", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.doc_testing"
    r._routing == "SUGGEST"
}

test_p41_i10_broken_example_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("doc_testing", {"doc_testing": {"broken_examples": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p41_i10_no_mechanism_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("doc_testing", {"example_testing_missing": true})
    r._routing == "TRIAGE_QUEUE"
}

# ── I11: auditor mode ──────────────────────────────────────────────────────────
test_p41_i11_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("auditor_mode", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.auditor_mode"
    r._routing == "SUGGEST"
}

test_p41_i11_no_view_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("auditor_mode", {"auditor_view_missing": true})
    r._routing == "TRIAGE_QUEUE"
}

test_p41_i11_missing_domain_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("auditor_mode", {"auditor_mode": {"domains_without_evidence_path": 2}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I12: legacy retirement ─────────────────────────────────────────────────────
test_p41_i12_ok {
    r := v3_p41_dokumentacja.decide with input as p41_input("legacy_retirement", {})
    r.rule_id == "jdg.v3_p41_dokumentacja.legacy_retirement"
    r._routing == "SUGGEST"
}

test_p41_i12_cannibalism_blocks {
    r := v3_p41_dokumentacja.decide with input as p41_input("legacy_retirement", {"legacy_retirement": {"duplicate_current_docs": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p41_i12_no_status_triage {
    r := v3_p41_dokumentacja.decide with input as p41_input("legacy_retirement", {"legacy_retirement": {"docs_without_status": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Fail-closed + certyfikat + unikalność priorytetów
# ═══════════════════════════════════════════════════════════════════════════════
test_p41_certificate_fields_present {
    r := v3_p41_dokumentacja.decide with input as p41_input("doc_code_binding", {"doc_code_binding": {"docs_gate_in_ci": true}})
    r.threshold_version == "dokumentacja-v3p41-2026.09"
    r.legal_basis_version == "dokumentacja-legal-2026.09"
    r.valid_from == "2026-01-01"
}

test_p41_priorities_unique_range {
    prios := [p |
        some a in ["doc_code_binding", "ssot_numbers", "role_doc_maps", "semantic_diff_pl_en", "glossary_enforcement", "audit_export_pack", "runbook_coverage", "changelog_automation", "freshness_stamps", "doc_testing", "auditor_mode", "legacy_retirement"]
        d := v3_p41_dokumentacja.decide with input as p41_input(a, {})
        p := d.priority
    ]
    count({p | some p in prios}) == 12
    max(prios) == 441012
    min(prios) == 441001
}

test_p41_no_test_prefix_rule_names {
    r := v3_p41_dokumentacja.decide with input as p41_input("doc_code_binding", {})
    not startswith(r.rule_id, "jdg.v3_p41_dokumentacja.test_")
}
