package jdg.tests.final_certification_etap28

import data.jdg.final_certification_etap28

base_input := {
    "jdg_entrepreneur": {"final_certification_etap28_check": true},
    "final_certification_etap28": {
        "evaluation_date": "2026-08-22",
        "run_id": "run-28",
        "evidence_refs": ["evidence://reconciliation", "evidence://matrix", "evidence://certification"],
        "reconciliation": {
            "reports_present": 28, "reports_wdrozone": 28,
            "reports_incomplete": 0, "reports_unproven": 0,
            "artifacts_present": 500, "audit_states_present": 21,
        },
        "traceability_matrix": {
            "domains_covered": 18, "legal_nodes_traced": 120,
            "rules_traced": 500, "tests_traced": 150,
            "bundles_per_domain": 1, "operators_defined": 5,
        },
        "domain_certifications": {
            "vat": "CERTIFIED", "pit": "CERTIFIED", "zus": "CERTIFIED",
            "accounting": "CERTIFIED", "kks_ord": "CERTIFIED",
            "crossborder": "CERTIFIED", "pcc_local": "CERTIFIED",
            "ksef_jpk": "CERTIFIED", "rodo_aml": "CERTIFIED",
            "hyper_contexts": "CERTIFIED", "ai_neural": "CERTIFIED",
            "orchestrator": "CERTIFIED", "legal_twin": "CERTIFIED",
            "control_plane": "CERTIFIED", "security": "CERTIFIED",
            "disaster_recovery": "CERTIFIED", "tests_ci": "CERTIFIED",
            "mirror_sync": "CERTIFIED",
        },
        "production_blockers": {
            "no_critical_legal_gap": true, "temporal_chain_complete": true,
            "test_gates_passing": true, "runtime_invariants_enforced": true,
            "openapi_implemented": true, "security_fortress_active": true,
            "full_traceability_chain": true,
        },
        "slo_sla": {
            "bundle_verify_fail_closed": true, "rollback_mttr_min": 4,
            "hot_reload_min": 14, "rpo_min": 15, "rto_min": 30,
            "opa_check_gate_active": true,
        },
        "change_control": {
            "four_eyes_sod": true, "canary_required": true,
            "shadow_delta_threshold": true, "rollback_tested": true,
            "runbooks_present": true,
        },
        "what_really_works": {
            "fully_working_domains": ["vat","pit","zus","accounting","kks_ord","crossborder","pcc_local","ksef_jpk","rodo_aml","hyper","ai_neural","orchestrator","legal_twin","control_plane","security","dr","tests_ci","mirror"],
            "partial_domains": [],
            "blocked_domains": [],
        },
    },
}

test_no_match if {
    result := final_certification_etap28.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.final_certification_etap28.no_match"
}

test_missing if {
    result := final_certification_etap28.decide with input as {"jdg_entrepreneur": {"final_certification_etap28_check": true}}
    result._routing == "BLOCK_AND_ALERT"
    result.state == "CERTIFICATION_FAILED"
}

test_reconciliation if {
    result := final_certification_etap28.decide with input as base_input
    result.reconciliation_ok == true
}

test_matrix if {
    result := final_certification_etap28.decide with input as base_input
    result.matrix_complete == true
}

test_certification if {
    result := final_certification_etap28.decide with input as base_input
    result.system_certified == true
    result.domains_blocked == 0
    result.domains_certified == 18
}

test_blockers if {
    result := final_certification_etap28.decide with input as base_input
    result.blockers_cleared == true
    result.slo_sla_complete == true
    result.change_control_complete == true
}

test_honesty if {
    result := final_certification_etap28.decide with input as base_input
    result.honesty_declared == true
}

test_fail_closed if {
    result := final_certification_etap28.decide with input as base_input
    result.decision_mode == "SUGGEST"
    result.no_auto_post == true
    result.manual_review_required == true
    result.production_status == "NOT_CERTIFIED"
}

test_valid if {
    result := final_certification_etap28.decide with input as base_input
    result.state == "CERTIFICATION_PASSED"
    result._routing == "TRIAGE_QUEUE"
}