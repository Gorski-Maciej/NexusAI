# NexusAI JDG — ETAP 27 CROSS-DOMAIN RED TEAM / INTEGRATION / RESILIENCE
# Red-team governance: conflict registry, attack catalog, chaos matrix,
# fraud scenarios, temporal edge attacks, expected fail-closed behavior,
# and the invariant that a single error never silently reaches AUTO_POST.
#
# References existing tools (chaos_runner.py, cross_package_conflict_detector.py,
# predictive_audit_shield.py, rule_impact_simulator.py, chaos_engineering.py,
# fraud_graph_scanner.py, security/security_fortress_v8.rego).
#
# This package is a GOVERNANCE CATALOG, not a replacement for those tools.

package jdg.cross_domain_red_team_etap27

import future.keywords.if
import future.keywords.in

decision_mode := "SUGGEST"

default decide := {
    "matched": false,
    "rule_id": "jdg.cross_domain_red_team_etap27.no_match",
    "package": "jdg.cross_domain_red_team_etap27",
    "priority": 999994,
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
}

_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et27 := object.get(_thresholds, "cross_domain_red_team_etap27", {})
registry_version := object.get(_et27, "registry_version", "cross-domain-red-team-etap27-2026.08")
legal_basis_version := object.get(_et27, "legal_basis_version", "red-team-resilience-2026.08")
min_conflict_pairs := object.get(_et27, "min_conflict_pairs", 6)
min_attack_scenarios := object.get(_et27, "min_attack_scenarios", 12)
min_chaos_experiments := object.get(_et27, "min_chaos_experiments", 8)
max_rto_min := object.get(_et27, "max_rto_min", 30)

ctx := object.get(input, "cross_domain_red_team_etap27", {})
activated := object.get(object.get(input, "jdg_entrepreneur", {}), "cross_domain_red_team_etap27_check", false)
evaluation_date := object.get(ctx, "evaluation_date", "")
run_id := object.get(ctx, "run_id", "")
evidence_refs := object.get(ctx, "evidence_refs", [])

# ── CONFLICT REGISTRY: cross-domain conflict catalog (VAT×PIT×ZUS×PKPiR×KKS) ─
conflict_registry := object.get(ctx, "conflict_registry", {})
conflict_pairs := object.get(conflict_registry, "pairs_count", 0)
conflict_cross_acts := object.get(conflict_registry, "cross_act_pairs", [])
conflict_pit_vat := object.get(conflict_registry, "pit_vat_detected", false)
conflict_zus_pit := object.get(conflict_registry, "zus_pit_detected", false)
conflict_pkpir_vat := object.get(conflict_registry, "pkpir_vat_detected", false)
conflict_kks_ordpu := object.get(conflict_registry, "kks_ordpu_detected", false)
conflict_registry_complete := conflict_pairs >= min_conflict_pairs and
    count(conflict_cross_acts) > 0 and
    conflict_pit_vat and conflict_zus_pit and conflict_kks_ordpu

# ── ATTACK CATALOG: known attack vectors & fraud scenarios ──────────────────
attack_catalog := object.get(ctx, "attack_catalog", {})
attacks_tampering := object.get(attack_catalog, "tampering_detected", false)
attacks_duplicate := object.get(attack_catalog, "duplicate_rule_id_detected", false)
attacks_nondet_merge := object.get(attack_catalog, "non_deterministic_merge_detected", false)
attacks_mid_law_change := object.get(attack_catalog, "mid_law_change_detected", false)
attacks_missing_data := object.get(attack_catalog, "missing_data_detected", false)
attack_scenarios_count := object.get(attack_catalog, "scenarios_count", 0)
attack_catalog_complete := attack_scenarios_count >= min_attack_scenarios and
    attacks_tampering and attacks_duplicate and attacks_nondet_merge and
    attacks_mid_law_change and attacks_missing_data

# ── CHAOS MATRIX: expected fail-closed behavior per experiment ──────────────
chaos := object.get(ctx, "chaos_matrix", {})
chaos_experiments := object.get(chaos, "experiments_count", 0)
chaos_undetected := object.get(chaos, "undetected_count", 0)
chaos_corrupt_bundle := object.get(chaos, "corrupt_bundle", false)
chaos_ksef_offline_72h := object.get(chaos, "ksef_offline_72h", false)
chaos_nbp_down := object.get(chaos, "nbp_down", false)
chaos_missing_thresholds := object.get(chaos, "missing_thresholds", false)
chaos_fail_closed := object.get(chaos, "fail_closed_verified", false)
chaos_complete := chaos_experiments >= min_chaos_experiments and
    chaos_undetected == 0 and chaos_fail_closed and
    chaos_corrupt_bundle and chaos_ksef_offline_72h and
    chaos_nbp_down and chaos_missing_thresholds

# ── TEMPORAL EDGE CONTRACTS: day-1/0/+1, mid-period law change ──────────────
temporal := object.get(ctx, "temporal_edge_contracts", {})
temporal_day_minus_1 := object.get(temporal, "day_minus_1_passed", false)
temporal_day_zero := object.get(temporal, "day_zero_passed", false)
temporal_day_plus_1 := object.get(temporal, "day_plus_1_passed", false)
temporal_mid_period := object.get(temporal, "mid_period_law_change_passed", false)
temporal_boundary_complete := temporal_day_minus_1 and temporal_day_zero and
    temporal_day_plus_1 and temporal_mid_period

# ── FRAUD SCENARIOS: empty invoice, shell company, circular trade ───────────
fraud := object.get(ctx, "fraud_scenarios", {})
fraud_empty_invoice := object.get(fraud, "empty_invoice_detected", false)
fraud_shell_company := object.get(fraud, "shell_company_detected", false)
fraud_circular_trade := object.get(fraud, "circular_trade_detected", false)
fraud_carousel := object.get(fraud, "carousel_vat_detected", false)
fraud_transfer_pricing := object.get(fraud, "transfer_pricing_detected", false)
fraud_scenarios_complete := fraud_empty_invoice and fraud_shell_company and
    fraud_circular_trade and fraud_carousel and fraud_transfer_pricing

# ── FAIL-CLOSED PROOF: no single error reaches AUTO_POST silently ────────────
fail_closed := object.get(ctx, "fail_closed_proof", {})
fail_closed_auto_post_guard := object.get(fail_closed, "auto_post_blocked_on_error", false)
fail_closed_no_match_sets_block := object.get(fail_closed, "no_match_defaults_to_block", false)
fail_closed_certainty_guard := object.get(fail_closed, "certainty_blocked_no_auto_post", false)
fail_closed_rollback_on_breach := object.get(fail_closed, "rollback_on_artifact_breach", false)
fail_closed_dr_requires_tested_restore := object.get(fail_closed, "dr_requires_tested_restore", false)
fail_closed_proof_complete := fail_closed_auto_post_guard and
    fail_closed_no_match_sets_block and fail_closed_certainty_guard and
    fail_closed_rollback_on_breach and fail_closed_dr_requires_tested_restore

# ── AUTO_POST guard: never on error, always manual review ────────────────────
auto_post_guard := object.get(ctx, "auto_post_guard", {})
auto_post_blocked_on_any_error := object.get(auto_post_guard, "error_blocks_auto_post", false)
auto_post_manual_review_hard_block := object.get(auto_post_guard, "manual_review_hard_block", false)
auto_post_decision_mode_suggest_only := object.get(auto_post_guard, "decision_mode_suggest_only", false)
auto_post_complete := auto_post_blocked_on_any_error and
    auto_post_manual_review_hard_block and auto_post_decision_mode_suggest_only

# ── CONTRACT TESTS: cross-domain + cross-tool ───────────────────────────────
contract_tests := object.get(ctx, "contract_tests", {})
contract_cross_domain := object.get(contract_tests, "cross_domain_tests_passed", false)
contract_integration := object.get(contract_tests, "integration_tests_passed", false)
contract_security := object.get(contract_tests, "security_tests_passed", false)
contract_temporal := object.get(contract_tests, "temporal_tests_passed", false)
contract_tests_complete := contract_cross_domain and contract_integration and
    contract_security and contract_temporal

# ── EXISTING TOOLS VERIFICATION ────────────────────────────────────────────
tools_verified := object.get(ctx, "existing_tools_verified", {})
tools_chaos_runner := object.get(tools_verified, "chaos_runner_verified", false)
tools_conflict_detector := object.get(tools_verified, "conflict_detector_verified", false)
tools_predictive_shield := object.get(tools_verified, "predictive_shield_verified", false)
tools_fraud_scanner := object.get(tools_verified, "fraud_scanner_verified", false)
tools_security_fortress := object.get(tools_verified, "security_fortress_verified", false)
tools_verified_complete := tools_chaos_runner and tools_conflict_detector and
    tools_predictive_shield and tools_fraud_scanner and tools_security_fortress

provenance_complete := evaluation_date != "" and run_id != "" and
    count(evidence_refs) > 0 and registry_version != "" and
    legal_basis_version != ""

all_controls_complete := conflict_registry_complete and attack_catalog_complete and
    chaos_complete and temporal_boundary_complete and fraud_scenarios_complete and
    fail_closed_proof_complete and auto_post_complete and contract_tests_complete and
    tools_verified_complete and provenance_complete

manual_review_required := true
hard_block := not all_controls_complete
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    manual_review_required
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.cross_domain_red_team_etap27.red_team_governance",
    "package": "jdg.cross_domain_red_team_etap27",
    "priority": 27001,
    "stage": "ETAP_27",
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
    "state": "RED_TEAM_DEFEATED" if {all_controls_complete} else "RED_TEAM_VULNERABLE",
    "conflict_registry_complete": conflict_registry_complete,
    "attack_catalog_complete": attack_catalog_complete,
    "chaos_matrix_complete": chaos_complete,
    "temporal_boundary_complete": temporal_boundary_complete,
    "fraud_scenarios_complete": fraud_scenarios_complete,
    "fail_closed_proof_complete": fail_closed_proof_complete,
    "auto_post_guard_complete": auto_post_complete,
    "contract_tests_complete": contract_tests_complete,
    "tools_verified_complete": tools_verified_complete,
    "provenance_complete": provenance_complete,
    "manual_review_required": manual_review_required,
    "red_team_thresholds": {
        "min_conflict_pairs": min_conflict_pairs,
        "min_attack_scenarios": min_attack_scenarios,
        "min_chaos_experiments": min_chaos_experiments,
        "max_rto_min": max_rto_min,
    },
    "evidence_chain": {
        "run_id": run_id, "evidence_refs": evidence_refs,
        "evaluation_date": evaluation_date,
        "registry_version": registry_version,
        "legal_basis_version": legal_basis_version,
    },
    "_routing": routing,
    "_routing_reason": "ETAP 27: red-team governance — żaden błąd nie przechodzi cicho do AUTO_POST; fail-closed verified.",
    "_legal_basis": "V1 §3-6 security; ADR-011 (security_fortress); chaos_runner.py; cross_package_conflict_detector.py; predictive_audit_shield.py; fraud_graph_scanner.py; rule_impact_simulator.py; INV-006/035 (auto-post guard)",
    "_warnings": ["Niekompletny conflict registry, brak wykrycia ataku, chaotyczny eksperyment bez wykrycia, brak fail-closed proof, brak testów kontraktowych lub niezweryfikowane narzędzia = BLOCK_AND_ALERT."],
    "valid_from": "2026-01-01",
    "valid_to": null,
} {
    activated
}