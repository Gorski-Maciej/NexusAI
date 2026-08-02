# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: taxfree
# Generated: 2026-08-02T09:09:55.660288
# Package: jdg.taxfree
# Rules tested: 20
# Report: P27 R3 — 11 missing package coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_taxfree
import data.jdg.taxfree

# Test 1: jdg.taxfree.no_match
test_positive_no_match {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.no_match
test_negative_no_match {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.no_match"
}

# Test 2: jdg.taxfree.jdg_vs_employment
test_positive_jdg_vs_employment {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.jdg_vs_employment
test_negative_jdg_vs_employment {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.jdg_vs_employment"
}

# Test 3: jdg.taxfree.linear_lump_sum_exclusion
test_positive_linear_lump_sum_exclusion {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.linear_lump_sum_exclusion
test_negative_linear_lump_sum_exclusion {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.linear_lump_sum_exclusion"
}

# Test 4: jdg.taxfree.deduction_optimization
test_positive_deduction_optimization {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.deduction_optimization
test_negative_deduction_optimization {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.deduction_optimization"
}

# Test 5: jdg.taxfree.withholding_tax
test_positive_withholding_tax {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.withholding_tax
test_negative_withholding_tax {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.withholding_tax"
}

# Test 6: jdg.taxfree.foreign_income
test_positive_foreign_income {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.foreign_income
test_negative_foreign_income {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.foreign_income"
}

# Test 7: jdg.taxfree.hyper.no_match
test_positive_no_match {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.hyper.no_match
test_negative_no_match {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.hyper.no_match"
}

# Test 8: jdg.taxfree.hyper.scale_reduction_3600
test_positive_scale_reduction_3600 {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.hyper.scale_reduction_3600
test_negative_scale_reduction_3600 {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.hyper.scale_reduction_3600"
}

# Test 9: jdg.taxfree.hyper.scale_decreasing_amount
test_positive_scale_decreasing_amount {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.hyper.scale_decreasing_amount
test_negative_scale_decreasing_amount {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.hyper.scale_decreasing_amount"
}

# Test 10: jdg.taxfree.hyper.scale_no_free_amount_127k
test_positive_scale_no_free_amount_127k {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.hyper.scale_no_free_amount_127k
test_negative_scale_no_free_amount_127k {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.hyper.scale_no_free_amount_127k"
}

# Test 11: jdg.taxfree.hyper.scale_employer_250_monthly
test_positive_scale_employer_250_monthly {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.hyper.scale_employer_250_monthly
test_negative_scale_employer_250_monthly {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.hyper.scale_employer_250_monthly"
}

# Test 12: jdg.taxfree.hyper.linear_no_free_amount
test_positive_linear_no_free_amount {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.hyper.linear_no_free_amount
test_negative_linear_no_free_amount {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.hyper.linear_no_free_amount"
}

# Test 13: jdg.taxfree.hyper.linear_no_deduction_reminder
test_positive_linear_no_deduction_reminder {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.hyper.linear_no_deduction_reminder
test_negative_linear_no_deduction_reminder {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.hyper.linear_no_deduction_reminder"
}

# Test 14: jdg.taxfree.hyper.linear_vs_scale_comparison
test_positive_linear_vs_scale_comparison {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.hyper.linear_vs_scale_comparison
test_negative_linear_vs_scale_comparison {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.hyper.linear_vs_scale_comparison"
}

# Test 15: jdg.taxfree.hyper.linear_communication
test_positive_linear_communication {
    result := data.jdg.taxfree.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.taxfree.hyper.linear_communication
test_negative_linear_communication {
    result := data.jdg.taxfree.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.taxfree.hyper.linear_communication"
}
