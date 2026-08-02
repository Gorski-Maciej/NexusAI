# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: interest_calculator_enterprise
# Source: interest_calculator_enterprise.rego
# Generated: 2026-08-02T09:14:32.189365
# Package: jdg.interest_calculator
# Rules tested: 4
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_interest_calculator
import data.jdg.interest_calculator

# 1. jdg.interest_calculator.no_match
test_positive_no_match {
    result := data.jdg.interest_calculator.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.interest_calculator.no_match"
}

test_negative_no_match {
    result := data.jdg.interest_calculator.decide with input as {}
    result.rule_id != "jdg.interest_calculator.no_match"
}

# 2. jdg.interest_calculator.rate_calculator
test_positive_rate_calculator {
    result := data.jdg.interest_calculator.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.interest_calculator.rate_calculator"
}

test_negative_rate_calculator {
    result := data.jdg.interest_calculator.decide with input as {}
    result.rule_id != "jdg.interest_calculator.rate_calculator"
}

# 3. jdg.interest_calculator.amount_calculator
test_positive_amount_calculator {
    result := data.jdg.interest_calculator.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.interest_calculator.amount_calculator"
}

test_negative_amount_calculator {
    result := data.jdg.interest_calculator.decide with input as {}
    result.rule_id != "jdg.interest_calculator.amount_calculator"
}

# 4. jdg.interest_calculator.cashflow_optimizer
test_positive_cashflow_optimizer {
    result := data.jdg.interest_calculator.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.interest_calculator.cashflow_optimizer"
}

test_negative_cashflow_optimizer {
    result := data.jdg.interest_calculator.decide with input as {}
    result.rule_id != "jdg.interest_calculator.cashflow_optimizer"
}
