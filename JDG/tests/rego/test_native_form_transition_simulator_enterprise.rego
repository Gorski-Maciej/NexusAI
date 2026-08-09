# Native Rego contract tests for jdg.form_transition.

package test_jdg_form_transition


base_entrepreneur := {
    "tax_form": "PIT_SCALE",
    "business_type": "SERVICES",
    "annual_revenue_projected": 180000,
    "annual_costs_projected": 50000,
    "annual_profit_projected": 100000,
}

test_no_match_for_empty_input {
    result := data.jdg.form_transition.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.form_transition.no_match"
}

test_full_comparison_simulation {
    result := data.jdg.form_transition.decide with input as {
        "simulate_form_transition": true,
        "jdg_entrepreneur": base_entrepreneur,
    }
    result.matched == true
    result.rule_id == "jdg.form_transition.full_comparison_simulation"
    result.priority == 1750
    result.sim_current_form == "PIT_SCALE"
}

test_restrictions_check {
    result := data.jdg.form_transition.decide with input as {
        "simulate_transition_restrictions": true,
        "target_tax_form": "LUMP_SUM",
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "business_type": "PHARMACY",
        },
    }
    result.matched == true
    result.rule_id == "jdg.form_transition.restrictions_check"
    result.priority == 1760
    result.trans_eligible_for_target == false
}

test_relief_loss_calculator {
    result := data.jdg.form_transition.decide with input as {
        "simulate_relief_loss": true,
        "target_tax_form": "LINEAR",
        "jdg_entrepreneur": {
            "has_children_under_18": true,
            "files_jointly_with_spouse": true,
        },
    }
    result.matched == true
    result.rule_id == "jdg.form_transition.relief_loss_calculator"
    result.priority == 1770
    result.trans_reliefs_lost_value_pln > 0
}

test_spzoo_analysis {
    result := data.jdg.form_transition.decide with input as {
        "simulate_spzoo_transition": true,
        "jdg_entrepreneur": {
            "tax_form": "LINEAR",
            "annual_profit_projected": 250000,
            "has_employees": true,
        },
    }
    result.matched == true
    result.rule_id == "jdg.form_transition.jdg_to_spzoo_analysis"
    result.priority == 1775
    result.sim_spzoo_jdg_annual_cost >= 0
}

test_health_contribution_impact {
    result := data.jdg.form_transition.decide with input as {
        "simulate_health_impact": true,
        "jdg_entrepreneur": {
            "annual_profit_projected": 96000,
            "annual_revenue_projected": 180000,
        },
    }
    result.matched == true
    result.rule_id == "jdg.form_transition.health_contribution_details"
    result.priority == 1780
    result.trans_health_scale > 0
    result.trans_health_linear > 0
}

test_first_match_prefers_full_comparison {
    result := data.jdg.form_transition.decide with input as {
        "simulate_form_transition": true,
        "simulate_transition_restrictions": true,
        "simulate_relief_loss": true,
        "simulate_spzoo_transition": true,
        "simulate_health_impact": true,
        "jdg_entrepreneur": base_entrepreneur,
    }
    result.rule_id == "jdg.form_transition.full_comparison_simulation"
    result.priority == 1750
}

test_restrictions_block_lump_sum_for_financial_business {
    result := data.jdg.form_transition.decide with input as {
        "simulate_transition_restrictions": true,
        "target_tax_form": "LUMP_SUM",
        "jdg_entrepreneur": {"business_type": "FINANCIAL_INTERMEDIATION"},
    }
    result.trans_eligible_for_target == false
    result._routing == "BLOCK_AND_ALERT"
}

test_relief_loss_keeps_scale_reliefs_on_scale {
    result := data.jdg.form_transition.decide with input as {
        "simulate_relief_loss": true,
        "target_tax_form": "PIT_SCALE",
        "jdg_entrepreneur": {},
    }
    result.trans_reliefs_lost_value_pln == 0
    count(result.trans_reliefs_kept) > 0
}

test_health_impact_uses_linear_deduction_cap {
    result := data.jdg.form_transition.decide with input as {
        "simulate_health_impact": true,
        "jdg_entrepreneur": {"annual_profit_projected": 1000000},
    }
    result.trans_health_linear_deductible <= 14100
}

test_full_comparison_excludes_pharmacy_lump_sum {
    result := data.jdg.form_transition.decide with input as {
        "simulate_form_transition": true,
        "jdg_entrepreneur": object.union(base_entrepreneur, {"business_type": "PHARMACY"}),
    }
    result.sim_lump_total_annual == 999999
}

test_no_match_does_not_activate_any_simulation {
    result := data.jdg.form_transition.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"},
    }
    result.matched == false
    result.rule_id == "jdg.form_transition.no_match"
}
