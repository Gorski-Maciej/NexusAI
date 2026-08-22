package jdg.tests.cross_domain_red_team_etap27

import data.jdg.cross_domain_red_team_etap27

base_input := {
    "jdg_entrepreneur": {"cross_domain_red_team_etap27_check": true},
    "cross_domain_red_team_etap27": {
        "evaluation_date": "2026-08-22",
        "run_id": "run-27",
        "evidence_refs": ["evidence://conflicts", "evidence://chaos", "evidence://fraud"],
        "conflict_registry": {
            "pairs_count": 6, "cross_act_pairs": [{"pair": "VAT-PIT"}, {"pair": "ZUS-PIT"}, {"pair": "KKS-OrdPU"}],
            "pit_vat_detected": true, "zus_pit_detected": true,
            "pkpir_vat_detected": true, "kks_ordpu_detected": true,
        },
        "attack_catalog": {
            "scenarios_count": 12, "tampering_detected": true,
            "duplicate_rule_id_detected": true, "non_deterministic_merge_detected": true,
            "mid_law_change_detected": true, "missing_data_detected": true,
        },
        "chaos_matrix": {
            "experiments_count": 8, "undetected_count": 0,
            "corrupt_bundle": true, "ksef_offline_72h": true,
            "nbp_down": true, "missing_thresholds": true,
            "fail_closed_verified": true,
        },
        "temporal_edge_contracts": {
            "day_minus_1_passed": true, "day_zero_passed": true,
            "day_plus_1_passed": true, "mid_period_law_change_passed": true,
        },
        "fraud_scenarios": {
            "empty_invoice_detected": true, "shell_company_detected": true,
            "circular_trade_detected": true, "carousel_vat_detected": true,
            "transfer_pricing_detected": true,
        },
        "fail_closed_proof": {
            "auto_post_blocked_on_error": true, "no_match_defaults_to_block": true,
            "certainty_blocked_no_auto_post": true, "rollback_on_artifact_breach": true,
            "dr_requires_tested_restore": true,
        },
        "auto_post_guard": {
            "error_blocks_auto_post": true, "manual_review_hard_block": true,
            "decision_mode_suggest_only": true,
        },
        "contract_tests": {
            "cross_domain_tests_passed": true, "integration_tests_passed": true,
            "security_tests_passed": true, "temporal_tests_passed": true,
        },
        "existing_tools_verified": {
            "chaos_runner_verified": true, "conflict_detector_verified": true,
            "predictive_shield_verified": true, "fraud_scanner_verified": true,
            "security_fortress_verified": true,
        },
    },
}

test_no_match if {
    result := cross_domain_red_team_etap27.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.cross_domain_red_team_etap27.no_match"
}

test_missing_contract if {
    result := cross_domain_red_team_etap27.decide with input as {"jdg_entrepreneur": {"cross_domain_red_team_etap27_check": true}}
    result._routing == "BLOCK_AND_ALERT"
    result.state == "RED_TEAM_VULNERABLE"
}

test_conflict_registry if {
    result := cross_domain_red_team_etap27.decide with input as base_input
    result.conflict_registry_complete == true
}

test_chaos if {
    result := cross_domain_red_team_etap27.decide with input as base_input
    result.chaos_matrix_complete == true
    result.attack_catalog_complete == true
}

test_fraud if {
    result := cross_domain_red_team_etap27.decide with input as base_input
    result.fraud_scenarios_complete == true
}

test_fail_closed if {
    result := cross_domain_red_team_etap27.decide with input as base_input
    result.fail_closed_proof_complete == true
}

test_auto_post if {
    result := cross_domain_red_team_etap27.decide with input as base_input
    result.auto_post_guard_complete == true
}

test_temporal if {
    result := cross_domain_red_team_etap27.decide with input as base_input
    result.temporal_boundary_complete == true
}

test_tools if {
    result := cross_domain_red_team_etap27.decide with input as base_input
    result.tools_verified_complete == true
    result.contract_tests_complete == true
}

test_blocked if {
    result := cross_domain_red_team_etap27.decide with input as base_input
    result.decision_mode == "SUGGEST"
    result.no_auto_post == true
    result.manual_review_required == true
}

test_valid if {
    result := cross_domain_red_team_etap27.decide with input as base_input
    result.state == "RED_TEAM_DEFEATED"
    result._routing == "TRIAGE_QUEUE"
}