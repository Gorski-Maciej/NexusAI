# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: deadline_monitor_enterprise
# Source: deadline_monitor_enterprise.rego
# Generated: 2026-08-02T09:14:32.141026
# Package: jdg.deadline_monitor
# Rules tested: 3
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_deadline_monitor
import data.jdg.deadline_monitor

# 1. jdg.deadline_monitor.no_match
test_positive_no_match {
    result := data.jdg.deadline_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.deadline_monitor.no_match"
}

test_negative_no_match {
    result := data.jdg.deadline_monitor.decide with input as {}
    result.rule_id != "jdg.deadline_monitor.no_match"
}

# 2. jdg.deadline_monitor.payment_calendar
test_positive_payment_calendar {
    result := data.jdg.deadline_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.deadline_monitor.payment_calendar"
}

test_negative_payment_calendar {
    result := data.jdg.deadline_monitor.decide with input as {}
    result.rule_id != "jdg.deadline_monitor.payment_calendar"
}

# 3. jdg.deadline_monitor.late_payment_impact
test_positive_late_payment_impact {
    result := data.jdg.deadline_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.deadline_monitor.late_payment_impact"
}

test_negative_late_payment_impact {
    result := data.jdg.deadline_monitor.decide with input as {}
    result.rule_id != "jdg.deadline_monitor.late_payment_impact"
}
