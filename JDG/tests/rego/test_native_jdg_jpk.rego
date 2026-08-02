# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: jpk
# Generated: 2026-08-02T09:09:55.539124
# Package: jdg.jpk
# Rules tested: 1
# Report: P27 R3 — 11 missing package coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_jpk
import data.jdg.jpk

# Test 1: jdg.jpk.no_match
test_positive_no_match {
    result := data.jdg.jpk.decide with input as {}
    result.matched == true
}

# Negative test for: jdg.jpk.no_match
test_negative_no_match {
    result := data.jdg.jpk.decide with input as {"__neg_test__": true}
    result.rule_id != "jdg.jpk.no_match"
}
