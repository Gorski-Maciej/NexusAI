package jdg.tests.pit_missing_reliefs

import future.keywords.if
import data.jdg.pit.missing_reliefs


test_missing_reliefs_no_match_for_lump_sum if {
    result := missing_reliefs.decide with input as {
        "pit_internet_check": true,
        "jdg_entrepreneur": {
            "tax_form": "LUMP_SUM",
            "internet_expenses_annual": 900,
            "internet_relief_years_used": 0
        }
    }
    result.matched == false
}

test_missing_reliefs_no_match_without_explicit_request if {
    result := missing_reliefs.decide with input as {"jdg_entrepreneur": {"tax_form": "PIT_SCALE"}}
    result.matched == false
    result.rule_id == "jdg.pit.missing_reliefs.no_match"
}

test_missing_reliefs_active_loss if {
    result := missing_reliefs.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "annual_taxable_income": 100000,
            "tax_loss_2021": 20000,
            "tax_loss_2024": 10000
        }
    }
    result.rule_id == "jdg.pit.missing_reliefs.loss_carry_forward_active"
    result.loss_total_available == 30000
    result.loss_actual_deducted == 30000
    result.loss_expiring_this_year == 20000
}

test_missing_reliefs_internet_limit if {
    result := missing_reliefs.decide with input as {
        "pit_internet_check": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "internet_expenses_annual": 900,
            "internet_relief_years_used": 0
        }
    }
    result.rule_id == "jdg.pit.missing_reliefs.internet"
    result.relief_deductible == 760
    result.relief_years_remaining == 2
}

test_missing_reliefs_child_scale_only if {
    result := missing_reliefs.decide with input as {
        "pit_child_check": true,
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE", "children_count": 3}
    }
    result.rule_id == "jdg.pit.missing_reliefs.child_tax_credit"
    result.relief_total_deductible == 4224.12
}

test_missing_reliefs_expansion_cap if {
    result := missing_reliefs.decide with input as {
        "pit_expansion_check": true,
        "jdg_entrepreneur": {"tax_form": "LINEAR", "expansion_trade_fairs_costs": 1200000}
    }
    result.rule_id == "jdg.pit.missing_reliefs.expansion"
    result.relief_deductible == 1000000
}

test_missing_reliefs_robotization_rate if {
    result := missing_reliefs.decide with input as {
        "pit_robotization_check": true,
        "jdg_entrepreneur": {"tax_form": "LINEAR", "robotization_purchase_costs": 100000}
    }
    result.rule_id == "jdg.pit.missing_reliefs.robotization"
    result.relief_deductible == 50000
}
