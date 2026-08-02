# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: sanctions_optimization_enterprise
# Source: sanctions_optimization_enterprise.rego
# Generated: 2026-08-02T09:14:32.312827
# Package: jdg.sanctions_optimization
# Rules tested: 5
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_sanctions_optimization
import data.jdg.sanctions_optimization

# 1. jdg.sanctions.no_match
test_positive_no_match {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.sanctions.no_match"
}

test_negative_no_match {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.rule_id != "jdg.sanctions.no_match"
}

# 2. jdg.sanctions.kks_art54_graduation
test_positive_kks_art54_graduation {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.sanctions.kks_art54_graduation"
}

test_negative_kks_art54_graduation {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.rule_id != "jdg.sanctions.kks_art54_graduation"
}

# 3. jdg.sanctions.kks_specific_offenses
test_positive_kks_specific_offenses {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.sanctions.kks_specific_offenses"
}

test_negative_kks_specific_offenses {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.rule_id != "jdg.sanctions.kks_specific_offenses"
}

# 4. jdg.sanctions.penalty_optimization_decision_tree
test_positive_lty_optimization_decision_tree {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.sanctions.penalty_optimization_decision_tree"
}

test_negative_lty_optimization_decision_tree {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.rule_id != "jdg.sanctions.penalty_optimization_decision_tree"
}

# 5. jdg.sanctions.kks_risk_calculator
test_positive_kks_risk_calculator {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.sanctions.kks_risk_calculator"
}

test_negative_kks_risk_calculator {
    result := data.jdg.sanctions_optimization.decide with input as {}
    result.rule_id != "jdg.sanctions.kks_risk_calculator"
}
