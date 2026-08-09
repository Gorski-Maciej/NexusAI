# Native Rego contract tests for jdg.interest_calculator.

package test_jdg_interest_calculator


test_no_match_for_empty_input {
    result := data.jdg.interest_calculator.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.interest_calculator.no_match"
}

test_rate_calculator {
    result := data.jdg.interest_calculator.decide with input as {"interest_calculator_check": true}
    result.rule_id == "jdg.interest_calculator.rate_calculator"
    result.priority == 3060
    result.int_base_rate_200pct > 0
}

test_amount_calculator_standard {
    result := data.jdg.interest_calculator.decide with input as {
        "interest_amount_calculate": true,
        "int_principal_pln": 10000,
        "int_days_late": 30,
        "int_violation_type": "STANDARD",
    }
    result.rule_id == "jdg.interest_calculator.amount_calculator"
    result.int_interest_accrued > 0
    result.int_total_to_pay > result.int_principal_amount
}

test_amount_calculator_correction {
    result := data.jdg.interest_calculator.decide with input as {
        "interest_amount_calculate": true,
        "int_principal_pln": 10000,
        "int_days_late": 30,
        "int_violation_type": "CORRECTION_7DAYS",
    }
    result.rule_id == "jdg.interest_calculator.amount_calculator"
    result.int_applicable_rate < 0.3
}

test_cashflow_optimizer {
    result := data.jdg.interest_calculator.decide with input as {
        "interest_cashflow_optimize": true,
        "int_principal_pln": 10000,
        "int_days_to_deadline": 25,
        "int_current_day": 5,
    }
    result.rule_id == "jdg.interest_calculator.cashflow_optimizer"
    result.int_optimize_pay_later_cost >= result.int_optimize_pay_now_cost
    result.int_optimize_savings >= 0
}

test_first_match_prefers_rate_calculator {
    result := data.jdg.interest_calculator.decide with input as {
        "interest_calculator_check": true,
        "interest_amount_calculate": true,
        "interest_cashflow_optimize": true,
    }
    result.rule_id == "jdg.interest_calculator.rate_calculator"
    result.priority == 3060
}
