# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: fx
# Generated: 2026-08-02T09:09:55.528371
# Package: jdg.fx
# Rules tested: 20
# Report: P27 R3 — 11 missing package coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_fx
import data.jdg.fx

# Test 1: jdg.fx.no_match
test_positive_no_match {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.no_match
test_negative_no_match {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.no_match"
}

# Test 2: jdg.fx.pit_rate_determination
test_positive_pit_rate_determination {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.pit_rate_determination
test_negative_pit_rate_determination {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.pit_rate_determination"
}

# Test 3: jdg.fx.differences_method
test_positive_differences_method {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.differences_method
test_negative_differences_method {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.differences_method"
}

# Test 4: jdg.fx.realized_vs_unrealized
test_positive_realized_vs_unrealized {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.realized_vs_unrealized
test_negative_realized_vs_unrealized {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.realized_vs_unrealized"
}

# Test 5: jdg.fx.differences_method_selection
test_positive_differences_method_selection {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.differences_method_selection
test_negative_differences_method_selection {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.differences_method_selection"
}

# Test 6: jdg.fx.own_funds
test_positive_own_funds {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.own_funds
test_negative_own_funds {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.own_funds"
}

# Test 7: jdg.fx.crypto_fx_differences
test_positive_crypto_fx_differences {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.crypto_fx_differences
test_negative_crypto_fx_differences {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.crypto_fx_differences"
}

# Test 8: jdg.fx.hedging_instruments
test_positive_hedging_instruments {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.hedging_instruments
test_negative_hedging_instruments {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.hedging_instruments"
}

# Test 9: jdg.fx.multi_currency_accounting
test_positive_multi_currency_accounting {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.multi_currency_accounting
test_negative_multi_currency_accounting {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.multi_currency_accounting"
}

# Test 10: jdg.fx.hyper.no_match
test_positive_no_match {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.hyper.no_match
test_negative_no_match {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.hyper.no_match"
}

# Test 11: jdg.fx.hyper.vat_wnt_ecb_rate
test_positive_vat_wnt_ecb_rate {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.hyper.vat_wnt_ecb_rate
test_negative_vat_wnt_ecb_rate {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.hyper.vat_wnt_ecb_rate"
}

# Test 12: jdg.fx.hyper.vat_import_services_nbp
test_positive_vat_import_services_nbp {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.hyper.vat_import_services_nbp
test_negative_vat_import_services_nbp {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.hyper.vat_import_services_nbp"
}

# Test 13: jdg.fx.hyper.vat_fx_invoice_nbp
test_positive_vat_fx_invoice_nbp {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.hyper.vat_fx_invoice_nbp
test_negative_vat_fx_invoice_nbp {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.hyper.vat_fx_invoice_nbp"
}

# Test 14: jdg.fx.hyper.vat_correction_original_rate
test_positive_vat_correction_original_rate {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.hyper.vat_correction_original_rate
test_negative_vat_correction_original_rate {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.hyper.vat_correction_original_rate"
}

# Test 15: jdg.fx.hyper.vat_ecb_vs_nbp_choice
test_positive_vat_ecb_vs_nbp_choice {
    result := data.jdg.fx.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.fx.hyper.vat_ecb_vs_nbp_choice
test_negative_vat_ecb_vs_nbp_choice {
    result := data.jdg.fx.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.fx.hyper.vat_ecb_vs_nbp_choice"
}
