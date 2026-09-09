# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY V3-P42 ENTERPRISE RESZTA (negative-first, P39-I04)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p42_enterprise_reszta_test

import future.keywords.in

import data.jdg.v3_p42_enterprise_reszta

# ── Helper ─────────────────────────────────────────────────────────────────────
p42_input(analysis, ctx) = {
    "jdg_entrepreneur": {"v3_p42_check": true},
    "v3_p42": object.union({"analysis": analysis}, ctx),
}

# ═══════════════════════════════════════════════════════════════════════════════
# Brak flagi → no_match
# ═══════════════════════════════════════════════════════════════════════════════
test_p42_no_activation_no_match {
    r := v3_p42_enterprise_reszta.decide with input as {"v3_p42": {"analysis": "health_tier"}}
    r.rule_id == "jdg.v3_p42_enterprise_reszta.no_match"
}

# ── I01: health tier ───────────────────────────────────────────────────────────
test_p42_i01_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("health_tier", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.health_tier"
    r._routing == "SUGGEST"
}

test_p42_i01_facade_blocks {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("health_tier", {"health_tier_facade": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p42_i01_drift_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("health_tier", {"health_tier": {"tier_drift_count": 2}})
    r._routing == "TRIAGE_QUEUE"
}

test_p42_i01_no_ci_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("health_tier", {"health_tier_no_ci": true})
    r._routing == "TRIAGE_QUEUE"
}

# ── I02: SMT proof pack ────────────────────────────────────────────────────────
test_p42_i02_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("smt_proof_pack", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.smt_proof_pack"
    r._routing == "SUGGEST"
}

test_p42_i02_counterexample_blocks {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("smt_proof_pack", {"smt_proof_pack": {"counterexamples": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p42_i02_missing_proofs_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("smt_proof_pack", {"smt_proof_pack": {"critical_rules_without_proof": 2}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I03: WORM hash chain ───────────────────────────────────────────────────────
test_p42_i03_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("worm_hash_chain", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.worm_hash_chain"
    r._routing == "SUGGEST"
}

test_p42_i03_broken_chain_blocks {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("worm_hash_chain", {"worm_hash_chain": {"chain_broken_blocks": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p42_i03_no_chain_blocks {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("worm_hash_chain", {"worm_no_hash_chain": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p42_i03_no_tamper_test_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("worm_hash_chain", {"worm_tamper_test_missing": true})
    r._routing == "TRIAGE_QUEUE"
}

# ── I04: retention calculator ──────────────────────────────────────────────────
test_p42_i04_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("retention_calculator", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.retention_calculator"
    r._routing == "SUGGEST"
}

test_p42_i04_premature_deletion_blocks {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("retention_calculator", {"retention_calculator": {"premature_deletions": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p42_i04_no_expiry_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("retention_calculator", {"retention_calculator": {"artifacts_without_expiry": 3}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I05: provenance query ──────────────────────────────────────────────────────
test_p42_i05_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("provenance_query", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.provenance_query"
    r._routing == "SUGGEST"
}

test_p42_i05_dna_without_act_blocks {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("provenance_query", {"provenance_query": {"dna_without_legal_act": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p42_i05_missing_dna_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("provenance_query", {"provenance_query": {"active_rules_without_dna": 2}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I06: coverage unifier ──────────────────────────────────────────────────────
test_p42_i06_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("coverage_unifier", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.coverage_unifier"
    r._routing == "SUGGEST"
}

test_p42_i06_no_canon_blocks {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("coverage_unifier", {"coverage_canon_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p42_i06_conflicts_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("coverage_unifier", {"coverage_unifier": {"report_conflicts": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I07: dependency graph ──────────────────────────────────────────────────────
test_p42_i07_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("dependency_graph", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.dependency_graph"
    r._routing == "SUGGEST"
}

test_p42_i07_cycle_blocks {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("dependency_graph", {"dependency_graph": {"dependency_cycles": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p42_i07_spof_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("dependency_graph", {"dependency_graph": {"critical_spof": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I08: orphan sweep ──────────────────────────────────────────────────────────
test_p42_i08_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("orphan_sweep", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.orphan_sweep"
    r._routing == "SUGGEST"
}

test_p42_i08_orphans_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("orphan_sweep", {"orphan_sweep": {"orphan_artifacts": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I09: completeness register ─────────────────────────────────────────────────
test_p42_i09_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("completeness_register", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.completeness_register"
    r._routing == "SUGGEST"
}

test_p42_i09_unregistered_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("completeness_register", {"completeness_register": {"requirements_unregistered": 1}})
    r._routing == "TRIAGE_QUEUE"
}

test_p42_i09_missing_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("completeness_register", {"completeness_register": {"requirements_missing": 3}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I10: STR evidence ──────────────────────────────────────────────────────────
test_p42_i10_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("str_evidence", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.str_evidence"
    r._routing == "SUGGEST"
}

test_p42_i10_incidents_without_str_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("str_evidence", {"str_evidence": {"incidents_without_str": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I11: cross-domain health ───────────────────────────────────────────────────
test_p42_i11_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("cross_domain_health", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.cross_domain_health"
    r._routing == "SUGGEST"
}

test_p42_i11_no_propagation_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("cross_domain_health", {"cross_domain_health": {"contracts_without_propagation": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I12: maturity ladder ───────────────────────────────────────────────────────
test_p42_i12_ok {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("maturity_ladder", {})
    r.rule_id == "jdg.v3_p42_enterprise_reszta.maturity_ladder"
    r._routing == "SUGGEST"
}

test_p42_i12_no_criteria_blocks {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("maturity_ladder", {"maturity_criteria_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p42_i12_level_above_max_triage {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("maturity_ladder", {"maturity_ladder": {"declared_level": 6}})
    r._routing == "TRIAGE_QUEUE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Certyfikat + priorytety + ochrona nazw
# ═══════════════════════════════════════════════════════════════════════════════
test_p42_certificate_fields_present {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("health_tier", {})
    r.threshold_version == "enterprise-reszta-v3p42-2026.09"
    r.legal_basis_version == "enterprise-reszta-legal-2026.09"
    r.valid_from == "2026-01-01"
}

test_p42_priorities_unique_range {
    prios := [p |
        some a in ["health_tier", "smt_proof_pack", "worm_hash_chain", "retention_calculator", "provenance_query", "coverage_unifier", "dependency_graph", "orphan_sweep", "completeness_register", "str_evidence", "cross_domain_health", "maturity_ladder"]
        d := v3_p42_enterprise_reszta.decide with input as p42_input(a, {})
        p := d.priority
    ]
    count({p | some p in prios}) == 12
    max(prios) == 442012
    min(prios) == 442001
}

test_p42_no_test_prefix_rule_names {
    r := v3_p42_enterprise_reszta.decide with input as p42_input("health_tier", {})
    not startswith(r.rule_id, "jdg.v3_p42_enterprise_reszta.test_")
}
