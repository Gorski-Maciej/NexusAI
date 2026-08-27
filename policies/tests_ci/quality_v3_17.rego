# NexusAI JDG — V3-17 TESTY + CI/CD + CHAOS + MUTATION + GOLDEN
# Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą
# progów CI. Warstwa bramkuje WYNIKI suit testowych z evidence; jest
# deterministyczna, guidance-only i fail-closed (brak dowodu = FAIL).

package jdg.tests_ci.quality_v3_17

import future.keywords.if
import future.keywords.in

_snapshot := object.get(data.jdg.thresholds, "tests_ci_quality_v3_17", {})
threshold_version := object.get(_snapshot, "threshold_version", "")
registry_version := object.get(_snapshot, "registry_version", "")
legal_basis_version := object.get(_snapshot, "legal_basis_version", "")
valid_from := object.get(_snapshot, "valid_from", "")
valid_to := object.get(_snapshot, "valid_to", null)
min_mutation_score := object.get(_snapshot, "min_mutation_score", 0)
min_fuzz_cases := object.get(_snapshot, "min_fuzz_cases", 0)
min_property_cases := object.get(_snapshot, "min_property_cases", 0)
min_chaos_experiments := object.get(_snapshot, "min_chaos_experiments", 0)
golden_required := object.get(_snapshot, "golden_replay_required", true)
required_workflows := object.get(_snapshot, "required_workflows", [])

ctx := object.get(input, "tests_ci_v3_17", {})
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", [])
facts_version := object.get(ctx, "facts_version", "")
evaluation_date := object.get(ctx, "evaluation_date", "")
input_hash := object.get(ctx, "input_hash", "")
owner_approval := object.get(ctx, "owner_approval", false)
manual_recipient := object.get(ctx, "manual_recipient", "")

source_complete := count(source_refs) > 0 and count(legal_nodes) > 0 and
    legal_basis_version != ""
temporal_valid := evaluation_date != "" and facts_version != "" and
    threshold_version != "" and valid_from != ""

suites := object.get(ctx, "suites", {})
pytest_suite := object.get(suites, "pytest", {})
native_suite := object.get(suites, "native_rego", {})
pytest_ok := object.get(pytest_suite, "passed", false) and object.get(pytest_suite, "count", 0) > 0
native_ok := object.get(native_suite, "passed", false) and object.get(native_suite, "count", 0) > 0
suites_complete := pytest_ok and native_ok

coverage := object.get(object.get(ctx, "coverage", {}), "pct", 0)
coverage_ok := coverage >= object.get(_snapshot, "coverage_target_pct", 100)

mutation := object.get(ctx, "mutation", {})
mutation_score := object.get(mutation, "score", 0)
mutation_blocked := object.get(mutation, "blocking", false)
mutation_ok := mutation_score >= min_mutation_score and mutation_blocked

fuzz := object.get(ctx, "fuzz", {})
fuzz_cases := object.get(fuzz, "cases", 0)
fuzz_ok := fuzz_cases >= min_fuzz_cases and object.get(fuzz, "schema_validated", false)

property := object.get(ctx, "property", {})
property_ok := object.get(property, "cases", 0) >= min_property_cases

chaos := object.get(ctx, "chaos", {})
chaos_ok := object.get(chaos, "experiments", 0) >= min_chaos_experiments and
    object.get(chaos, "undetected_failures", 1) == 0

golden := object.get(ctx, "golden", {})
golden_ok := golden_required == false or (
    object.get(golden, "replay_passed", false) and
    object.get(golden, "diff_legal_clean", false)
)

workflows_seen := object.get(ctx, "workflows", [])
missing_workflows := [name |
    name := required_workflows[_]
    not name in workflows_seen
]
workflows_complete := count(missing_workflows) == 0

regression := object.get(ctx, "regression", {})
regression_ok := object.get(regression, "auto_registered", false) and
    object.get(regression, "registry_versioned", false)

contract_complete := suites_complete and coverage_ok and mutation_ok and
    fuzz_ok and property_ok and chaos_ok and golden_ok and
    workflows_complete and regression_ok and source_complete and
    temporal_valid and input_hash != ""

hard_block := not contract_complete or not owner_approval or manual_recipient == ""
ci_state := "CI_VALIDATED" if {
    contract_complete
    not hard_block
} else := "CI_BLOCKED" if {
    true
}
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE"

# Publiczny wynik: CI Quality Certificate — nigdy czynność zewnętrzna.
decide := {
    "matched": true,
    "rule_id": "jdg.tests_ci.quality_v3_17.ci_quality_contract",
    "package": "jdg.tests_ci.quality_v3_17",
    "priority": 22005,
    "stage": "V3-17",
    "state": ci_state,
    "decision_mode": "SUGGEST",
    "mode": "DECOUPLED",
    "no_auto_post": true,
    "suites_complete": suites_complete,
    "coverage": {"pct": coverage, "ok": coverage_ok},
    "mutation": {"score": mutation_score, "blocking": mutation_blocked, "ok": mutation_ok},
    "fuzz_ok": fuzz_ok,
    "property_ok": property_ok,
    "chaos_ok": chaos_ok,
    "golden_ok": golden_ok,
    "missing_workflows": missing_workflows,
    "workflows_complete": workflows_complete,
    "regression_ok": regression_ok,
    "hard_block": hard_block,
    "_routing": routing,
    "_routing_reason": "CI wymaga pełnych suite'ów, coverage >= celu, mutation blocking, fuzz/property/chaos w progach, czystego Golden replay z diffem prawnym i ręcznego odbiorcy.",
    "_legal_basis": "OrdPU art. 12 § 5, art. 193a; PIT art. 44-45; VAT art. 106na-106nq (schematy KSeF/JPK dla fuzz); KKS art. 16; ADR-002; MANIFEST.md",
    "_threshold_version": threshold_version,
    "_registry_version": registry_version,
    "_valid_from": valid_from,
    "_valid_to": valid_to,
    "owner_approval": owner_approval,
    "manual_recipient": manual_recipient,
    "_warnings": [
        "V3-17 bramkuje wyniki CI — sam nie uruchamia testów ani mutacji.",
        "Golden replay bez diffu prawnego lub z niezarejestrowaną regresją blokuje wynik.",
        "Chaos z niewykrytą awarią (undetected_failures > 0) blokuje wynik.",
    ],
} if {
    object.get(input, "tests_ci_v3_17_check", false) == true
}

default decide := {
    "matched": false,
    "rule_id": "jdg.tests_ci.quality_v3_17.no_match",
    "package": "jdg.tests_ci.quality_v3_17",
    "priority": 999999,
    "mode": "DECOUPLED",
    "no_auto_post": true,
}
