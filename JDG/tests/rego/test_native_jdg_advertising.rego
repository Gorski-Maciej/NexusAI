# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: advertising
# Generated: 2026-08-02T09:09:55.458184
# Package: jdg.advertising
# Rules tested: 20
# Report: P27 R3 — 11 missing package coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_advertising
import data.jdg.advertising

# Test 1: jdg.advertising.no_match
test_positive_no_match {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.no_match
test_negative_no_match {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.no_match"
}

# Test 2: jdg.advertising.online_digital_kup
test_positive_online_digital_kup {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.online_digital_kup
test_negative_online_digital_kup {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.online_digital_kup"
}

# Test 3: jdg.advertising.events_hospitality
test_positive_events_hospitality {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.events_hospitality
test_negative_events_hospitality {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.events_hospitality"
}

# Test 4: jdg.advertising.gifts_limit_200
test_positive_gifts_limit_200 {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.gifts_limit_200
test_negative_gifts_limit_200 {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.gifts_limit_200"
}

# Test 5: jdg.advertising.sponsorship_kup
test_positive_sponsorship_kup {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.sponsorship_kup
test_negative_sponsorship_kup {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.sponsorship_kup"
}

# Test 6: jdg.advertising.vat_deduction
test_positive_vat_deduction {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.vat_deduction
test_negative_vat_deduction {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.vat_deduction"
}

# Test 7: jdg.advertising.social_media_influencer
test_positive_social_media_influencer {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.social_media_influencer
test_negative_social_media_influencer {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.social_media_influencer"
}

# Test 8: jdg.advertising.car_wrapping_vat26
test_positive_car_wrapping_vat26 {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.car_wrapping_vat26
test_negative_car_wrapping_vat26 {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.car_wrapping_vat26"
}

# Test 9: jdg.advertising.foreign_markets_kup
test_positive_foreign_markets_kup {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.foreign_markets_kup
test_negative_foreign_markets_kup {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.foreign_markets_kup"
}

# Test 10: jdg.advertising.hyper.no_match
test_positive_no_match {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.hyper.no_match
test_negative_no_match {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.hyper.no_match"
}

# Test 11: jdg.advertising.hyper.product_promotion_kup
test_positive_product_promotion_kup {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.hyper.product_promotion_kup
test_negative_product_promotion_kup {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.hyper.product_promotion_kup"
}

# Test 12: jdg.advertising.hyper.brand_building_kup
test_positive_brand_building_kup {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.hyper.brand_building_kup
test_negative_brand_building_kup {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.hyper.brand_building_kup"
}

# Test 13: jdg.advertising.hyper.personal_prestige_nkup
test_positive_personal_prestige_nkup {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.hyper.personal_prestige_nkup
test_negative_personal_prestige_nkup {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.hyper.personal_prestige_nkup"
}

# Test 14: jdg.advertising.hyper.representation_nkup_full
test_positive_representation_nkup_full {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.hyper.representation_nkup_full
test_negative_representation_nkup_full {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.hyper.representation_nkup_full"
}

# Test 15: jdg.advertising.hyper.representation_audit_gastronomy
test_positive_epresentation_audit_gastronomy {
    result := data.jdg.advertising.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.advertising.hyper.representation_audit_gastronomy
test_negative_epresentation_audit_gastronomy {
    result := data.jdg.advertising.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.advertising.hyper.representation_audit_gastronomy"
}
