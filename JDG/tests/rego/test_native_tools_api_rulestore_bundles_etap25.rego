package jdg.tests.tools_api_rulestore_bundles_etap25

import data.jdg.tools_api_rulestore_bundles_etap25

base_input := {
    "jdg_entrepreneur": {"tools_api_rulestore_bundles_etap25_check": true},
    "tools_api_rulestore_bundles_etap25": {
        "evaluation_date": "2026-08-22",
        "run_id": "run-25",
        "evidence_refs": ["evidence://api-spec", "evidence://bundles"],
        "api": {
            "openapi_consistent": true,
            "markers_complete": true,
            "gap_count": 0,
            "idempotency_key": true,
            "versioning": true,
        },
        "authnz": {"jwt": true, "rbac": true, "sod": true},
        "migrations": {
            "pk": true, "fk": true, "unique_constraint": true,
            "check_constraint": true, "idempotent_ddl": true,
            "worm_append_only": true,
        },
        "bundle_integrity": {
            "signing": true, "hsm_signature": true,
            "sbom_present": true, "sbom_verified": true,
            "node_verify": true, "last_healthy_persisted": true,
        },
        "progressive_delivery": {
            "canary": true, "canary_pct": 5,
            "shadow_compare": true, "shadow_delta_pct": 2.0,
            "ramped": true, "soak": true, "soak_hours": 24,
            "rollback": true, "rollback_mttr_min": 5,
        },
        "hot_reload": {"data_hot_reload": true, "sla_minutes": 15},
        "worm_merkle": {"merkle_audit": true, "append_only": true, "decision_certificates_v4": true},
        "disaster_recovery": {
            "backup": true, "restore_tested": true,
            "rpo_minutes": 15, "rto_minutes": 30, "game_day_passed": true,
        },
        "production_honesty": {
            "production_status": "NOT_CERTIFIED",
            "mock_claimed_as_production": false,
        },
    },
}

test_no_match if {
    result := tools_api_rulestore_bundles_etap25.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.tools_api_rulestore_bundles_etap25.no_match"
}

test_missing_contract if {
    result := tools_api_rulestore_bundles_etap25.decide with input as {"jdg_entrepreneur": {"tools_api_rulestore_bundles_etap25_check": true}}
    result._routing == "BLOCK_AND_ALERT"
    result.state == "CONTROL_PLANE_BLOCKED"
    result.no_auto_post == true
}

test_openapi if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.api_schema_consistent == true
}

test_authnz if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.authnz_complete == true
    result.idempotency_complete == true
    result.versioning_complete == true
}

test_migrations if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.migrations_constraints_complete == true
}

test_bundle if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.bundle_integrity_complete == true
    result.healthy_version_persisted == true
}

test_progressive_delivery if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.progressive_delivery_complete == true
}

test_hot_reload if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.hot_reload_complete == true
}

test_worm if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.worm_merkle_complete == true
}

test_dr if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.disaster_recovery_complete == true
}

test_production_honesty if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.production_honest == true
    result.production_status == "NOT_CERTIFIED"
}

test_fail_closed if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.decision_mode == "SUGGEST"
    result.manual_review_required == true
    result.no_auto_post == true
}

test_valid if {
    result := tools_api_rulestore_bundles_etap25.decide with input as base_input
    result.state == "CONTROL_PLANE_READY"
    result._routing == "TRIAGE_QUEUE"
}
