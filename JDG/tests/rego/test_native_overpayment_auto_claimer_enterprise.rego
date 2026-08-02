# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: overpayment_auto_claimer_enterprise
# Source: overpayment_auto_claimer_enterprise.rego
# Generated: 2026-08-02T09:14:32.266631
# Package: jdg.overpayment_claimer
# Rules tested: 3
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_overpayment_claimer
import data.jdg.overpayment_claimer

# 1. jdg.overpayment_claimer.no_match
test_positive_no_match {
    result := data.jdg.overpayment_claimer.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.overpayment_claimer.no_match"
}

test_negative_no_match {
    result := data.jdg.overpayment_claimer.decide with input as {}
    result.rule_id != "jdg.overpayment_claimer.no_match"
}

# 2. jdg.overpayment_claimer.overpayment_detector
test_positive_overpayment_detector {
    result := data.jdg.overpayment_claimer.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.overpayment_claimer.overpayment_detector"
}

test_negative_overpayment_detector {
    result := data.jdg.overpayment_claimer.decide with input as {}
    result.rule_id != "jdg.overpayment_claimer.overpayment_detector"
}

# 3. jdg.overpayment_claimer.refund_timeline_monitor
test_positive_refund_timeline_monitor {
    result := data.jdg.overpayment_claimer.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.overpayment_claimer.refund_timeline_monitor"
}

test_negative_refund_timeline_monitor {
    result := data.jdg.overpayment_claimer.decide with input as {}
    result.rule_id != "jdg.overpayment_claimer.refund_timeline_monitor"
}
