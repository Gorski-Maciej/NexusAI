# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: pcc
# Generated: 2026-08-02T09:09:55.592865
# Package: jdg.pcc
# Rules tested: 4
# Report: P27 R3 — 11 missing package coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_pcc
import data.jdg.pcc

# Test 1: jdg.pcc.no_match
test_positive_no_match {
    result := data.jdg.pcc.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.pcc.no_match
test_negative_no_match {
    result := data.jdg.pcc.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.pcc.no_match"
}

# Test 2: jdg.pcc.car_purchase_from_private
test_positive_car_purchase_from_private {
    result := data.jdg.pcc.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.pcc.car_purchase_from_private
test_negative_car_purchase_from_private {
    result := data.jdg.pcc.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.pcc.car_purchase_from_private"
}

# Test 3: jdg.pcc.real_estate_purchase
test_positive_real_estate_purchase {
    result := data.jdg.pcc.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.pcc.real_estate_purchase
test_negative_real_estate_purchase {
    result := data.jdg.pcc.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.pcc.real_estate_purchase"
}

# Test 4: jdg.pcc.aggregate_liability_check
test_positive_aggregate_liability_check {
    result := data.jdg.pcc.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.pcc.aggregate_liability_check
test_negative_aggregate_liability_check {
    result := data.jdg.pcc.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.pcc.aggregate_liability_check"
}
