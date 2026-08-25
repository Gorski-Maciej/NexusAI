# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE REGO TESTS: jdg.business.v3_09 (Kampania V3, część 09)
# Uruchamiane przez `opa test JDG/rules JDG/tests/rego` (bramka CI).
# Konwencja: `v := ...decide with input as {...}` — modyfikator `with` dotyczy
# dokładnie jednego wyrażenia, dlatego każdy test wiąże wynik do zmiennej `v`.
# ═══════════════════════════════════════════════════════════════════════════════
package tests.test_native_ryczalt_v3_09

import future.keywords.in

# T01: fail-closed — brak snapshotu business_lifecycle blokuje domenę
test_v3_09_fail_closed_without_thresholds {
    v := data.jdg.business.v3_09.decide with input as {"jdg_entrepreneur": {}}
         with data.jdg.thresholds as {}
    startswith(v.rule_id, "jdg.business.v3_09.thresholds_missing")
    v._routing == "BLOCK_AND_ALERT"
}

# T02: limit monitor SAFE — 800k EUR z 2M (40%)
test_v3_09_limit_safe_zone {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {"tax_regime": "RYCZALT", "annual_revenue_eur": 800000},
    }
    v.rule_id == "jdg.business.v3_09.ryczalt_limit_monitor"
    v.ryczalt_limit_zone == "SAFE"
    v.ryczalt_limit_used_pct == 40
    v._routing == ""
}

# T03: limit monitor EXCEEDED — 2,1M EUR → BLOCK_AND_ALERT + manual review
test_v3_09_limit_exceeded {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {"tax_regime": "RYCZALT", "annual_revenue_eur": 2100000},
    }
    v.ryczalt_limit_exceeded == true
    v.ryczalt_limit_used_pct == 105
    v.manual_review_required == true
    v._routing == "BLOCK_AND_ALERT"
}

# T04: limit monitor — przeliczenie PLN→EUR po kursie referencyjnym z thresholds
test_v3_09_limit_pln_conversion {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {"tax_regime": "RYCZALT", "annual_revenue_pln": 4300000},
    }
    v.ryczalt_revenue_eur_effective == 1000000
    v.ryczalt_limit_zone == "WARNING"
}

# T05: FormAdvisor — SUGGEST bez auto-postu, decyzja należy do człowieka
test_v3_09_form_advisor_suggest_mode {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {
            "form_advisor_requested": true,
            "projected_annual_revenue_pln": 500000,
            "cost_ratio_pct": 10,
            "pkwiu_ryczalt_rate": 0.085,
        },
    }
    v.rule_id == "jdg.business.v3_09.form_advisor_checkpoint"
    v.form_advisor_mode == "SUGGEST"
    v.no_auto_post == true
    v.form_decision_owner == "HUMAN"
    v.form_recommended != ""
}

# T06: zawieszenie — plan mieści się w limicie 24 mies.
test_v3_09_suspension_within_limit {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {
            "suspension_requested": true,
            "suspension_planned_months": 6,
            "suspension_used_months_total": 0,
        },
    }
    v.rule_id == "jdg.business.v3_09.suspension_checklist"
    v.suspension_over_limit == false
    v.suspension_health_contribution_due == true
    v.suspension_b2b_invoices_blocked == true
    count(v.checklist_items) == 5
}

# T07: zawieszenie — przekroczenie limitu 24 mies. → BLOCK_AND_ALERT
test_v3_09_suspension_over_limit {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {
            "suspension_requested": true,
            "suspension_planned_months": 6,
            "suspension_used_months_total": 20,
        },
    }
    v.suspension_total_after_months == 26
    v.suspension_over_limit == true
    v._routing == "BLOCK_AND_ALERT"
}

# T08: sukcesja — horyzont ustawowy 24 mies., wpis CEIDG w terminie → TRIAGE
test_v3_09_succession_default_horizon {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {
            "succession_applicable": true,
            "succession_ceidg_filed_within_days": true,
            "succession_inventory_value_pln": 100000,
        },
    }
    v.rule_id == "jdg.business.v3_09.succession_planner"
    v.succession_horizon_months == 24
    v.succession_ceidg_deadline_days == 14
    v.succession_remnant_tax_pln == 10000
    v._routing == "TRIAGE_QUEUE"
}

# T09: sukcesja — brak wpisu w terminie → BLOCK_AND_ALERT
test_v3_09_succession_missing_filing {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {"succession_applicable": true},
    }
    v.succession_ceidg_filed_in_time == false
    v.manual_review_required == true
    v._routing == "BLOCK_AND_ALERT"
}

# T10: state machine — ACTIVE → SUSPENDED dozwolone
test_v3_09_state_machine_allowed {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {
            "lifecycle_current_state": "ACTIVE",
            "lifecycle_target_state": "SUSPENDED",
        },
    }
    v.rule_id == "jdg.business.v3_09.lifecycle_state_machine"
    v.lifecycle_transition_allowed == true
}

# T11: state machine — LIQUIDATION → ACTIVE niedozwolone (stan terminalny)
test_v3_09_state_machine_blocked {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {
            "lifecycle_current_state": "LIQUIDATION",
            "lifecycle_target_state": "ACTIVE",
        },
    }
    v.lifecycle_transition_allowed == false
    v.manual_review_required == true
    v._routing == "BLOCK_AND_ALERT"
}

# T12: karta podatkowa — 4 pracowników ≤ limit 5 → eligible; certyfikat catch-all
test_v3_09_karta_eligible_and_certificate_fallback {
    v := data.jdg.business.v3_09.decide with input as {
        "jdg_entrepreneur": {
            "karta_podatkowa_considered": true,
            "employees_count": 4,
        },
    }
    v.rule_id == "jdg.business.v3_09.karta_eligibility"
    v.karta_eligible == true
}
