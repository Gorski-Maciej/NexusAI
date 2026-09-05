# NexusAI JDG — V3-19 API + CONTROL PLANE + UI / CENTRUM DECYZJI
# Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą
# progów API/UI. Warstwa bramkuje WYNIKI audytu specyfikacji i control plane
# z evidence; jest deterministyczna, guidance-only i fail-closed
# (brak dowodu = FAIL). Nie serwuje API ani nie obsługuje UI samodzielnie.

package jdg.api_ui.quality_v3_19

import future.keywords.if
import future.keywords.in

_snapshot := object.get(data.jdg.thresholds, "api_ui_quality_v3_19", {})
threshold_version := object.get(_snapshot, "threshold_version", "")
registry_version := object.get(_snapshot, "registry_version", "")
legal_basis_version := object.get(_snapshot, "legal_basis_version", "")
valid_from := object.get(_snapshot, "valid_from", "")
valid_to := object.get(_snapshot, "valid_to", null)
min_api_endpoints := object.get(_snapshot, "min_api_endpoints", 0)
max_documented_only_gaps := object.get(_snapshot, "max_documented_only_gaps", 0)
required_decision_modes := object.get(_snapshot, "required_decision_modes", [])
min_soak_hours := object.get(_snapshot, "min_soak_hours", 0)

ctx := object.get(input, "api_ui_quality_v3_19", {})
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", [])
facts_version := object.get(ctx, "facts_version", "")
evaluation_date := object.get(ctx, "evaluation_date", "")
input_hash := object.get(ctx, "input_hash", "")
owner_approval := object.get(ctx, "owner_approval", false)
manual_recipient := object.get(ctx, "manual_recipient", "")

source_complete := count(source_refs) > 0
source_complete_legal = true {
    source_complete
    count(legal_nodes) > 0
    legal_basis_version != ""
} else = false {
    true
}
temporal_valid = true {
    evaluation_date != ""
    facts_version != ""
    threshold_version != ""
    valid_from != ""
} else = false {
    true
}

api := object.get(ctx, "api", {})
endpoints_total := object.get(api, "endpoints_total", 0)
jwt_security_required := object.get(api, "jwt_security_required", false)
api_ok = true {
    object.get(api, "spec_present", false)
    endpoints_total >= min_api_endpoints
    jwt_security_required
} else = false {
    true
}

consistency := object.get(ctx, "consistency", {})
consistency_ok = true {
    object.get(consistency, "audit_run", false)
    object.get(consistency, "markers_complete", false)
    object.get(consistency, "gap_count", 99999) <= max_documented_only_gaps
} else = false {
    true
}

authz := object.get(ctx, "authz", {})
authz_ok = true {
    object.get(authz, "rbac_roles_defined", false)
    object.get(authz, "sod_enforced", false)
    object.get(authz, "authz_tests_present", false)
} else = false {
    true
}

decision_center := object.get(ctx, "decision_center", {})
modes_covered := {mode | some mode in required_decision_modes;
    mode in object.get(decision_center, "modes_supported", [])}
decision_center_ok = true {
    count(modes_covered) == count(required_decision_modes)
    object.get(decision_center, "certainty_guard_required", false)
} else = false {
    true
}

lifecycle := object.get(ctx, "lifecycle", {})
lifecycle_ok = true {
    object.get(lifecycle, "four_eyes_enforced", false)
    object.get(lifecycle, "canary_required", false)
    object.get(lifecycle, "soak_hours", 0) >= min_soak_hours
} else = false {
    true
}

declarative := object.get(ctx, "declarative_change", {})
declarative_ok = true {
    object.get(declarative, "wizard_present", false)
    object.get(declarative, "dry_run_default", false)
    count(object.get(declarative, "never_automated", [])) > 0
} else = false {
    true
}

resilience := object.get(ctx, "resilience", {})
resilience_ok = true {
    object.get(resilience, "idempotency_key_required", false)
    object.get(resilience, "rate_limit_defined", false)
    object.get(resilience, "health_ready_endpoints", false)
} else = false {
    true
}

versioning := object.get(ctx, "versioning", {})
versioning_ok = true {
    object.get(versioning, "uri_path_versioning", false)
    object.get(versioning, "breaking_changes_rule", false)
} else = false {
    true
}

contract_complete = true {
    api_ok
    consistency_ok
    authz_ok
    decision_center_ok
    lifecycle_ok
    declarative_ok
    resilience_ok
    versioning_ok
    source_complete_legal
    temporal_valid
    input_hash != ""
} else = false {
    true
}

hard_block = true {
    not contract_complete
} else = true {
    not owner_approval
} else = true {
    manual_recipient == ""
} else = false {
    true
}
api_ui_state := "API_UI_VALIDATED" if {
    contract_complete
    not hard_block
} else := "API_UI_BLOCKED" if {
    true
}
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE"

# Publiczny wynik: API/UI Delivery Contract — nigdy czynność wdrożeniowa.
decide := {
    "matched": true,
    "rule_id": "jdg.api_ui.quality_v3_19.api_delivery_contract",
    "package": "jdg.api_ui.quality_v3_19",
    "priority": 22007,
    "stage": "V3-19",
    "state": api_ui_state,
    "decision_mode": "SUGGEST",
    "mode": "DECOUPLED",
    "no_auto_post": true,
    "api_ok": api_ok,
    "consistency_ok": consistency_ok,
    "authz_ok": authz_ok,
    "decision_center_ok": decision_center_ok,
    "lifecycle_ok": lifecycle_ok,
    "declarative_ok": declarative_ok,
    "resilience_ok": resilience_ok,
    "versioning_ok": versioning_ok,
    "hard_block": hard_block,
    "_routing": routing,
    "_routing_reason": "API wymaga spójnej specyfikacji bez luk, JWT/RBAC/SoD, centrum decyzji AUTO_POST/SUGGEST/ASK_USER z certainty guard, cyklu życia 4-eyes z canary i SOAK, kreatora zmian deklaratywnych, idempotencji/rate-limit/health oraz wersjonowania URI.",
    "_legal_basis": "OrdPU art. 12 § 5, art. 193a; PIT art. 44-45; VAT art. 109 (KSeF/e-Doręczenia); RODO art. 32 (bezpieczeństwo API); ADR-001/ADR-009/ADR-002; MANIFEST.md",
    "_threshold_version": threshold_version,
    "_registry_version": registry_version,
    "_valid_from": valid_from,
    "_valid_to": valid_to,
    "owner_approval": owner_approval,
    "manual_recipient": manual_recipient,
    "_warnings": [
        "V3-19 bramkuje wyniki audytu API/control plane — nie serwuje API ani UI.",
        "Specyfikacja z lukami (DOCUMENTED_ONLY) albo bez RBAC/SoD blokuje wynik.",
        "Centrum decyzji bez certainty guard (AUTO_POST dla nie-CERTAIN) blokuje wynik.",
    ],
} if {
    object.get(input, "api_ui_quality_v3_19_check", false) == true
}

default decide := {
    "matched": false,
    "rule_id": "jdg.api_ui.quality_v3_19.no_match",
    "package": "jdg.api_ui.quality_v3_19",
    "priority": 999999,
    "mode": "DECOUPLED",
    "no_auto_post": true,
}
