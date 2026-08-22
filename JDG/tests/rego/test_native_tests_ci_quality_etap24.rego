package jdg.tests.tests_ci_quality_etap24

import data.jdg.tests_ci_quality_etap24

base_input := {
    "jdg_entrepreneur": {"tests_ci_quality_etap24_check": true},
    "tests_ci_quality_etap24": {
        "evaluation_date": "2026-08-22",
        "facts_version": "facts-24",
        "threshold_version": "thresholds-24",
        "run_id": "run-24",
        "reproducibility_seed": "seed-42",
        "run_hash": "sha256:run",
        "evidence_refs": ["evidence://quality"],
        "tool_versions": {"opa": "1.2.4"},
        "opa_version": "1.2.4",
        "pytest_version": "9.0",
        "owner_approval": true,
        "scope": {"files": ["rules/main_jdg.rego"], "packages": ["jdg.vat"], "fail_on_empty": true},
        "syntax": {"passed": true, "non_empty": true},
        "semantic": {"passed": true, "non_empty": true},
        "contract": {"passed": true, "non_empty": true},
        "legal_evidence": {"passed": true, "evidence_ref": "legal://1"},
        "property": {"passed": true, "cases": 200, "evidence_ref": "property://1"},
        "mutation": {"passed": true, "score_pct": 85, "survived": 0, "evidence_ref": "mutation://1"},
        "fuzz": {"passed": true, "cases": 10000, "crashes": 0, "non_deterministic": 0, "evidence_ref": "fuzz://1"},
        "boundary": {"passed": true, "day_minus_one": true, "day_zero": true, "day_plus_one": true, "evidence_ref": "boundary://1"},
        "coverage": {"passed": true, "packages_pct": 95, "critical_pct": 100, "desert_count": 0, "evidence_ref": "coverage://1"},
        "regression": {"passed": true, "failed": 0, "flake_count": 0, "evidence_ref": "regression://1"},
        "golden_replay": {"passed": true, "replays": 10, "uvr_count": 0, "divergence_count": 0, "evidence_ref": "golden://1"},
        "chaos": {"passed": true, "experiments": 8, "undetected_failures": 0, "evidence_ref": "chaos://1"},
        "security": {"passed": true, "dependency_audit_passed": true, "secrets_scan_passed": true, "evidence_ref": "security://1"},
        "disaster_recovery": {"passed": true, "restore_tested": true, "rpo_minutes": 15, "rto_minutes": 30, "evidence_ref": "dr://1"},
    },
}

test_no_match if {
    result := tests_ci_quality_etap24.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.tests_ci_quality_etap24.no_match"
}

test_missing_contract if {
    result := tests_ci_quality_etap24.decide with input as {"jdg_entrepreneur": {"tests_ci_quality_etap24_check": true}}
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_property if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.property_complete == true
    result.mutation_complete == true
    result.fuzz_complete == true
}

test_golden if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.golden_replay_complete == true
    result.regression_complete == true
}

test_chaos if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.chaos_complete == true
    result.security_complete == true
    result.disaster_recovery_complete == true
}

test_fail_closed if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.decision_mode == "SUGGEST"
    result.manual_review_required == true
    result.legal_verdict_authority == "DETERMINISTIC_REGO"
}

test_valid if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.state == "QUALITY_RELEASE_READY"
    result._routing == "TRIAGE_QUEUE"
}

test_mutation if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.mutation_complete == true
}

test_fuzz if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.fuzz_complete == true
}

test_security if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.security_complete == true
}

test_dr if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.disaster_recovery_complete == true
}

test_scope_non_empty if {
    result := tests_ci_quality_etap24.decide with input as base_input
    result.scope_complete == true
}
