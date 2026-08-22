# ETAP 18 — native tests for JDG lifecycle state machine.
package test_jdg_business_lifecycle_etap18

import future.keywords.if

base := {
    "jdg_entrepreneur": {"business_lifecycle_etap18_check": true},
    "business_lifecycle_etap18": {
        "current_state": "PRE_START",
        "event": "REGISTER",
        "evaluation_date": "2026-08-21",
        "facts_version": "facts-1",
        "threshold_version": "lifecycle-2026.08",
        "source_refs": ["CEIDG", "PIT", "VAT", "SUS"],
        "legal_nodes": {"ceidg": "CEIDG art. 5-7", "pit": "PIT art. 9a"},
        "owner_approval": true,
        "pkwiu_verified": true,
        "declared_rate": null
    }
}

test_no_match_without_flag if {
    result := data.jdg.business_lifecycle_etap18.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.business_lifecycle_etap18.no_match"
}

test_invalid_transition_blocks if {
    result := data.jdg.business_lifecycle_etap18.decide with input as {
        "jdg_entrepreneur": {"business_lifecycle_etap18_check": true},
        "business_lifecycle_etap18": {
            "current_state": "UNKNOWN",
            "event": "REGISTER",
            "evaluation_date": "2026-08-21",
            "facts_version": "v1",
            "threshold_version": "v1",
            "source_refs": ["CEIDG"],
            "legal_nodes": {"ceidg": "CEIDG"},
            "owner_approval": true
        }
    }
    result._routing == "BLOCK_AND_ALERT"
    result.state_machine.transition_valid == false
    result.manual_review_required == true
}

test_valid_register_transition_is_suggest_only if {
    result := data.jdg.business_lifecycle_etap18.decide with input as base
    result.state_machine.next_state == "ACTIVE_STARTUP"
    result.state_machine.transition_valid == true
    result.required_forms[0] == "CEIDG-1"
    result.deadline_calendar.deadline_days == 7
    result.state_machine.rollback_event == "CANCEL_REGISTRATION"
    result.decision_mode == "SUGGEST"
    result.no_auto_post == true
}

test_suspend_transition_has_rollback if {
    suspend_input := object.union(base, {"business_lifecycle_etap18": object.union(base.business_lifecycle_etap18, {"current_state": "ACTIVE_GROWTH", "event": "SUSPEND"})})
    result := data.jdg.business_lifecycle_etap18.decide with input as suspend_input
    result.state_machine.next_state == "SUSPENDED"
    result.state_machine.rollback_event == "RESUME"
    result.required_forms[0] == "CEIDG-1 — zawieszenie"
    result.deadline_calendar.deadline_days == 30
}

test_succession_requires_manual_review if {
    succession_input := object.union(base, {"business_lifecycle_etap18": object.union(base.business_lifecycle_etap18, {"current_state": "ACTIVE_GROWTH", "event": "SUCCESSION"})})
    result := data.jdg.business_lifecycle_etap18.decide with input as succession_input
    result.state_machine.next_state == "SUCCESSION"
    result.required_forms[0] == "akt notarialny zarządcy"
    result.manual_review_required == true
    result._routing == "TRIAGE_QUEUE"
}

test_unverified_pkwiu_requires_manual_gate if {
    rate_input := object.union(base, {"business_lifecycle_etap18": object.union(base.business_lifecycle_etap18, {"declared_rate": 0.12, "pkwiu_verified": false})})
    result := data.jdg.business_lifecycle_etap18.decide with input as rate_input
    result.rate_registry.ambiguity == true
    result.manual_review_required == true
    result._routing == "TRIAGE_QUEUE"
}
