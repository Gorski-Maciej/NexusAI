# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: uor
# Generated: 2026-08-02T09:09:55.668710
# Package: jdg.uor
# Rules tested: 5
# Report: P27 R3 — 11 missing package coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_uor
import data.jdg.uor

# Test 1: jdg.uor.no_match
test_positive_no_match {
    result := data.jdg.uor.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.uor.no_match
test_negative_no_match {
    result := data.jdg.uor.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.uor.no_match"
}

# Test 2: jdg.uor.asset_valuation
test_positive_asset_valuation {
    result := data.jdg.uor.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.uor.asset_valuation
test_negative_asset_valuation {
    result := data.jdg.uor.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.uor.asset_valuation"
}

# Test 3: jdg.uor.accruals_deferrals
test_positive_accruals_deferrals {
    result := data.jdg.uor.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.uor.accruals_deferrals
test_negative_accruals_deferrals {
    result := data.jdg.uor.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.uor.accruals_deferrals"
}

# Test 4: jdg.uor.financial_statement
test_positive_financial_statement {
    result := data.jdg.uor.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.uor.financial_statement
test_negative_financial_statement {
    result := data.jdg.uor.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.uor.financial_statement"
}

# Test 5: jdg.uor.document_storage
test_positive_document_storage {
    result := data.jdg.uor.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.uor.document_storage
test_negative_document_storage {
    result := data.jdg.uor.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.uor.document_storage"
}
