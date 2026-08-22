# NexusAI JDG — ETAP 24 TESTS / CI / QUALITY GOVERNANCE
# Quality evidence is a release prerequisite; it never replaces legal evaluation.
# zero_defect: every required control must pass before release.

package jdg.tests_ci_quality_etap24

import future.keywords.if
import future.keywords.in

decision_mode := "SUGGEST"

default decide := {
    "matched": false,
    "rule_id": "jdg.tests_ci_quality_etap24.no_match",
    "package": "jdg.tests_ci_quality_etap24",
    "priority": 999997,
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
}

_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et24 := object.get(_thresholds, "tests_ci_quality_etap24", {})
registry_version := object.get(_et24, "registry_version", "tests-ci-quality-etap24-2026.08")
legal_basis_version := object.get(_et24, "legal_basis_version", "quality-governance-2026.08")
min_coverage_pct := object.get(_et24, "min_coverage_pct", 95)
min_critical_coverage_pct := object.get(_et24, "min_critical_coverage_pct", 100)
min_mutation_pct := object.get(_et24, "min_mutation_pct", 85)
min_fuzz_cases := object.get(_et24, "min_fuzz_cases", 10000)
min_property_cases := object.get(_et24, "min_property_cases", 200)

ctx := object.get(input, "tests_ci_quality_etap24", {})
activated := object.get(object.get(input, "jdg_entrepreneur", {}), "tests_ci_quality_etap24_check", false)
evaluation_date := object.get(ctx, "evaluation_date", "")
facts_version := object.get(ctx, "facts_version", "")
threshold_version := object.get(ctx, "threshold_version", "")
run_id := object.get(ctx, "run_id", "")
reproducibility_seed := object.get(ctx, "reproducibility_seed", "")
run_hash := object.get(ctx, "run_hash", "")
evidence_refs := object.get(ctx, "evidence_refs", [])
tool_versions := object.get(ctx, "tool_versions", {})
owner_approval := object.get(ctx, "owner_approval", false)

# Scope must be declared and non-empty. Empty suites are failures, not passes.
scope := object.get(ctx, "scope", {})
scope_files := object.get(scope, "files", [])
scope_packages := object.get(scope, "packages", [])
scope_complete := count(scope_files) > 0 and count(scope_packages) > 0 and object.get(scope, "fail_on_empty", false)

# Syntax, semantic, contract and legal evidence gates.
syntax := object.get(ctx, "syntax", {})
semantic := object.get(ctx, "semantic", {})
contract := object.get(ctx, "contract", {})
legal := object.get(ctx, "legal_evidence", {})
static_gates_complete := object.get(syntax, "passed", false) and object.get(syntax, "non_empty", false) and
    object.get(semantic, "passed", false) and object.get(semantic, "non_empty", false) and
    object.get(contract, "passed", false) and object.get(contract, "non_empty", false) and
    object.get(legal, "passed", false) and object.get(legal, "evidence_ref", "") != ""

# Property, mutation, fuzz and boundary checks.
property := object.get(ctx, "property", {})
mutation := object.get(ctx, "mutation", {})
fuzz := object.get(ctx, "fuzz", {})
boundary := object.get(ctx, "boundary", {})
property_complete := object.get(property, "passed", false) and object.get(property, "cases", 0) >= min_property_cases and object.get(property, "evidence_ref", "") != ""
mutation_complete := object.get(mutation, "passed", false) and object.get(mutation, "score_pct", 0) >= min_mutation_pct and object.get(mutation, "survived", 1) >= 0 and object.get(mutation, "evidence_ref", "") != ""
fuzz_complete := object.get(fuzz, "passed", false) and object.get(fuzz, "cases", 0) >= min_fuzz_cases and object.get(fuzz, "crashes", 1) == 0 and object.get(fuzz, "non_deterministic", 1) == 0 and object.get(fuzz, "evidence_ref", "") != ""
boundary_complete := object.get(boundary, "passed", false) and object.get(boundary, "day_minus_one", false) and object.get(boundary, "day_zero", false) and object.get(boundary, "day_plus_one", false) and object.get(boundary, "evidence_ref", "") != ""

# Coverage, regression, golden replay and cross-node determinism.
coverage := object.get(ctx, "coverage", {})
regression := object.get(ctx, "regression", {})
golden := object.get(ctx, "golden_replay", {})
coverage_complete := object.get(coverage, "passed", false) and object.get(coverage, "packages_pct", 0) >= min_coverage_pct and object.get(coverage, "critical_pct", 0) >= min_critical_coverage_pct and object.get(coverage, "desert_count", 1) == 0 and object.get(coverage, "evidence_ref", "") != ""
regression_complete := object.get(regression, "passed", false) and object.get(regression, "failed", 1) == 0 and object.get(regression, "flake_count", 1) == 0 and object.get(regression, "evidence_ref", "") != ""
golden_complete := object.get(golden, "passed", false) and object.get(golden, "replays", 0) > 0 and object.get(golden, "uvr_count", 1) == 0 and object.get(golden, "divergence_count", 1) == 0 and object.get(golden, "evidence_ref", "") != ""

# Chaos, security and disaster recovery are required release controls.
chaos := object.get(ctx, "chaos", {})
security := object.get(ctx, "security", {})
dr := object.get(ctx, "disaster_recovery", {})
chaos_complete := object.get(chaos, "passed", false) and object.get(chaos, "experiments", 0) > 0 and object.get(chaos, "undetected_failures", 1) == 0 and object.get(chaos, "evidence_ref", "") != ""
security_complete := object.get(security, "passed", false) and object.get(security, "dependency_audit_passed", false) and object.get(security, "secrets_scan_passed", false) and object.get(security, "evidence_ref", "") != ""
dr_complete := object.get(dr, "passed", false) and object.get(dr, "restore_tested", false) and object.get(dr, "rpo_minutes", 999999) <= 15 and object.get(dr, "rto_minutes", 999999) <= 30 and object.get(dr, "evidence_ref", "") != ""

versions_complete := count(tool_versions) > 0 and object.get(ctx, "opa_version", "") != "" and object.get(ctx, "pytest_version", "") != ""
provenance_complete := evaluation_date != "" and facts_version != "" and threshold_version != "" and run_id != "" and reproducibility_seed != "" and run_hash != "" and count(evidence_refs) > 0 and versions_complete

all_gates_complete := scope_complete and static_gates_complete and property_complete and mutation_complete and fuzz_complete and boundary_complete and coverage_complete and regression_complete and golden_complete and chaos_complete and security_complete and dr_complete and provenance_complete and owner_approval
manual_review_required := true
hard_block := not all_gates_complete
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    manual_review_required
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.tests_ci_quality_etap24.quality_release_verdict",
    "package": "jdg.tests_ci_quality_etap24",
    "priority": 24001,
    "stage": "ETAP_24",
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
    "state": "QUALITY_RELEASE_READY" if {all_gates_complete} else "QUALITY_RELEASE_BLOCKED",
    "scope_complete": scope_complete,
    "static_gates_complete": static_gates_complete,
    "property_complete": property_complete,
    "mutation_complete": mutation_complete,
    "fuzz_complete": fuzz_complete,
    "boundary_complete": boundary_complete,
    "coverage_complete": coverage_complete,
    "regression_complete": regression_complete,
    "golden_replay_complete": golden_complete,
    "chaos_complete": chaos_complete,
    "security_complete": security_complete,
    "disaster_recovery_complete": dr_complete,
    "provenance_complete": provenance_complete,
    "manual_review_required": manual_review_required,
    "owner_approval": owner_approval,
    "quality_thresholds": {"coverage_pct": min_coverage_pct, "critical_coverage_pct": min_critical_coverage_pct, "mutation_pct": min_mutation_pct, "fuzz_cases": min_fuzz_cases, "property_cases": min_property_cases},
    "evidence_chain": {"run_id": run_id, "run_hash": run_hash, "seed": reproducibility_seed, "refs": evidence_refs, "facts_version": facts_version, "threshold_version": threshold_version, "registry_version": registry_version, "legal_basis_version": legal_basis_version, "evaluation_date": evaluation_date},
    "quality_authority": "CI_RELEASE_GATE_ONLY",
    "legal_verdict_authority": "DETERMINISTIC_REGO",
    "_routing": routing,
    "_routing_reason": "ETAP 24: pusty, niereprodukowalny lub niekompletny test/gate blokuje release; jakość CI nie podejmuje decyzji prawnej.",
    "_legal_basis": "ADR-001; ADR-006; ADR-013; ADR-017; ADR-018; ADR-022; OPA test --fail-on-empty; pytest; property/mutation/fuzz/golden/chaos/security/DR controls",
    "_warnings": ["Brak wyniku dowolnej bramki oznacza BLOCK_AND_ALERT.", "Testy pozorne, stałe asercje, ignorowanie błędów i niejawne puste suite nie są dowodem jakości.", "Wymagane jest odtworzenie run_id, seed, hash, wersji narzędzi i evidence refs."],
    "auto_action": "NONE — MANUAL_REVIEW_REQUIRED",
    "valid_from": "2026-01-01",
    "valid_to": null,
} {
    activated
}
