package jdg.api_ui.quality_v3_19

import data.jdg.api_ui.quality_v3_19

# Golden evidence: pełny cykl API/control plane (18 ścieżek IMPLEMENTED,
# 0 luk DOCUMENTED_ONLY, JWT+RBAC+SoD, centrum decyzji AUTO_POST/SUGGEST/
# ASK_USER z certainty guard, lifecycle 4-eyes + canary + SOAK 24 h, kreator
# zmian deklaratywnych dry-run, idempotencja + rate-limit + health/ready,
# wersjonowanie URI-path).
valid_ctx := {
    "source_refs": ["isap://ordpu/12", "isap://vat/109"],
    "legal_nodes": ["ordpu.art12", "vat.art109"],
    "evaluation_date": "2026-08-26",
    "facts_version": "facts-2026.08",
    "input_hash": "sha256:api-ui-golden-19",
    "owner_approval": true,
    "manual_recipient": "OWNER_API",
    "api": {"spec_present": true, "endpoints_total": 18, "jwt_security_required": true},
    "consistency": {"audit_run": true, "markers_complete": true, "gap_count": 0},
    "authz": {"rbac_roles_defined": true, "sod_enforced": true, "authz_tests_present": true},
    "decision_center": {"modes_supported": ["AUTO_POST", "SUGGEST", "ASK_USER"], "certainty_guard_required": true},
    "lifecycle": {"four_eyes_enforced": true, "canary_required": true, "soak_hours": 24},
    "declarative_change": {"wizard_present": true, "dry_run_default": true, "never_automated": ["NIGDY bez canary", "NIGDY bez człowieka"]},
    "resilience": {"idempotency_key_required": true, "rate_limit_defined": true, "health_ready_endpoints": true},
    "versioning": {"uri_path_versioning": true, "breaking_changes_rule": true},
}

full_input := {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": valid_ctx}

test_full_contract_validated if {
    result := quality_v3_19.decide with input as full_input
    result.state == "API_UI_VALIDATED"
    result._routing == "TRIAGE_QUEUE"
    result.no_auto_post == true
    result.mode == "DECOUPLED"
}

test_fail_closed_without_owner_approval if {
    ctx := object.union(valid_ctx, {"owner_approval": false})
    result := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": ctx}
    result.state == "API_UI_BLOCKED"
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_spec_gaps_block if {
    gaps := object.union(valid_ctx, {"consistency": {"audit_run": true, "markers_complete": false, "gap_count": 4}})
    r1 := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": gaps}
    r1.consistency_ok == false
    r1.state == "API_UI_BLOCKED"

    few_paths := object.union(valid_ctx, {"api": {"spec_present": true, "endpoints_total": 9, "jwt_security_required": true}})
    r2 := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": few_paths}
    r2.api_ok == false
    r2.state == "API_UI_BLOCKED"
}

test_missing_authz_blocks if {
    no_sod := object.union(valid_ctx, {"authz": {"rbac_roles_defined": true, "sod_enforced": false, "authz_tests_present": true}})
    r1 := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": no_sod}
    r1.authz_ok == false
    r1.state == "API_UI_BLOCKED"

    no_tests := object.union(valid_ctx, {"authz": {"rbac_roles_defined": true, "sod_enforced": true, "authz_tests_present": false}})
    r2 := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": no_tests}
    r2.authz_ok == false
    r2.state == "API_UI_BLOCKED"
}

test_decision_center_incomplete_modes_block if {
    partial := object.union(valid_ctx, {"decision_center": {"modes_supported": ["AUTO_POST"], "certainty_guard_required": true}})
    r1 := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": partial}
    r1.decision_center_ok == false
    r1.state == "API_UI_BLOCKED"

    no_guard := object.union(valid_ctx, {"decision_center": {"modes_supported": ["AUTO_POST", "SUGGEST", "ASK_USER"], "certainty_guard_required": false}})
    r2 := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": no_guard}
    r2.decision_center_ok == false
    r2.state == "API_UI_BLOCKED"
}

test_lifecycle_soak_below_min_blocks if {
    short_soak := object.union(valid_ctx, {"lifecycle": {"four_eyes_enforced": true, "canary_required": true, "soak_hours": 6}})
    result := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": short_soak}
    result.lifecycle_ok == false
    result.state == "API_UI_BLOCKED"
}

test_resilience_and_versioning_block if {
    no_rate_limit := object.union(valid_ctx, {"resilience": {"idempotency_key_required": true, "rate_limit_defined": false, "health_ready_endpoints": true}})
    r1 := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": no_rate_limit}
    r1.resilience_ok == false

    no_breaking_rule := object.union(valid_ctx, {"versioning": {"uri_path_versioning": true, "breaking_changes_rule": false}})
    r2 := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": no_breaking_rule}
    r2.versioning_ok == false
    r2.state == "API_UI_BLOCKED"
}

test_no_auto_post_always_true if {
    blocked := quality_v3_19.decide with input as {"api_ui_quality_v3_19_check": true, "api_ui_quality_v3_19": {}}
    blocked.no_auto_post == true
}
