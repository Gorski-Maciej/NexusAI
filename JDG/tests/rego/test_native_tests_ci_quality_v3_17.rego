package jdg.tests_ci.quality_v3_17

import data.jdg.tests_ci.quality_v3_17

# Golden evidence: pełny zestaw CI (pytest + natywne Rego), coverage 97,
# mutation 90 blocking, fuzz 12000 (schematy KSeF/JPK), property 250,
# chaos 6/0 undetected, golden replay z czystym diffem prawnym.
valid_ctx := {
    "source_refs": ["isap://ordpu/12", "isap://vat/106na"],
    "legal_nodes": ["ordpu.art12", "vat.art106na"],
    "evaluation_date": "2026-08-26",
    "facts_version": "facts-2026.08",
    "input_hash": "sha256:tests-ci-golden-17",
    "owner_approval": true,
    "manual_recipient": "OWNER_QA",
    "suites": {
        "pytest": {"passed": true, "count": 198},
        "native_rego": {"passed": true, "count": 207},
    },
    "coverage": {"pct": 97},
    "mutation": {"score": 90, "blocking": true},
    "fuzz": {"cases": 12000, "schema_validated": true},
    "property": {"cases": 250},
    "chaos": {"experiments": 6, "undetected_failures": 0},
    "golden": {"replay_passed": true, "diff_legal_clean": true},
    "workflows": ["ci.yml", "opa-ci.yml", "jdg-quality-gates-blocking.yml", "jdg-scheduled-drift.yml"],
    "regression": {"auto_registered": true, "registry_versioned": true},
}

full_input := {"tests_ci_v3_17_check": true, "tests_ci_v3_17": valid_ctx}

test_full_contract_validated if {
    result := quality_v3_17.decide with input as full_input
    result.state == "CI_VALIDATED"
    result._routing == "TRIAGE_QUEUE"
    result.no_auto_post == true
    result.mode == "DECOUPLED"
}

test_fail_closed_without_owner_approval if {
    ctx := object.union(valid_ctx, {"owner_approval": false})
    result := quality_v3_17.decide with input as {"tests_ci_v3_17_check": true, "tests_ci_v3_17": ctx}
    result.state == "CI_BLOCKED"
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_empty_suites_block if {
    ctx := object.union(valid_ctx, {"suites": {"pytest": {"passed": true, "count": 0}, "native_rego": {"passed": false, "count": 5}}})
    result := quality_v3_17.decide with input as {"tests_ci_v3_17_check": true, "tests_ci_v3_17": ctx}
    result.suites_complete == false
    result.state == "CI_BLOCKED"
}

test_mutation_below_threshold_blocks if {
    ctx := object.union(valid_ctx, {"mutation": {"score": 70, "blocking": false}})
    result := quality_v3_17.decide with input as {"tests_ci_v3_17_check": true, "tests_ci_v3_17": ctx}
    result.mutation.ok == false
    result.mutation.score == 70
    result.state == "CI_BLOCKED"
}

test_golden_without_legal_diff_blocks if {
    ctx := object.union(valid_ctx, {"golden": {"replay_passed": true, "diff_legal_clean": false}})
    result := quality_v3_17.decide with input as {"tests_ci_v3_17_check": true, "tests_ci_v3_17": ctx}
    result.golden_ok == false
    result.state == "CI_BLOCKED"
}

test_chaos_undetected_failure_blocks if {
    ctx := object.union(valid_ctx, {"chaos": {"experiments": 8, "undetected_failures": 2}})
    result := quality_v3_17.decide with input as {"tests_ci_v3_17_check": true, "tests_ci_v3_17": ctx}
    result.chaos_ok == false
    result.state == "CI_BLOCKED"
}

test_missing_workflow_blocks if {
    ctx := object.union(valid_ctx, {"workflows": ["ci.yml", "opa-ci.yml"]})
    result := quality_v3_17.decide with input as {"tests_ci_v3_17_check": true, "tests_ci_v3_17": ctx}
    count(result.missing_workflows) == 2
    result.workflows_complete == false
    result.state == "CI_BLOCKED"
}

test_no_auto_post_always_true if {
    blocked := quality_v3_17.decide with input as {"tests_ci_v3_17_check": true, "tests_ci_v3_17": {}}
    blocked.no_auto_post == true
}
