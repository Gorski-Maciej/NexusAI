# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: legislative_monitor_enterprise
# Source: legislative_monitor_enterprise.rego
# Generated: 2026-08-02T09:14:32.250604
# Package: jdg.legislative_monitor
# Rules tested: 6
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_legislative_monitor
import data.jdg.legislative_monitor

# 1. jdg.legislative.no_match
test_positive_no_match {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.legislative.no_match"
}

test_negative_no_match {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.rule_id != "jdg.legislative.no_match"
}

# 2. jdg.legislative.change_detection
test_positive_change_detection {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.legislative.change_detection"
}

test_negative_change_detection {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.rule_id != "jdg.legislative.change_detection"
}

# 3. jdg.legislative.impact_analysis
test_positive_impact_analysis {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.legislative.impact_analysis"
}

test_negative_impact_analysis {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.rule_id != "jdg.legislative.impact_analysis"
}

# 4. jdg.legislative.transitional_provisions
test_positive_transitional_provisions {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.legislative.transitional_provisions"
}

test_negative_transitional_provisions {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.rule_id != "jdg.legislative.transitional_provisions"
}

# 5. jdg.legislative.compliance_calendar
test_positive_compliance_calendar {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.legislative.compliance_calendar"
}

test_negative_compliance_calendar {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.rule_id != "jdg.legislative.compliance_calendar"
}

# 6. jdg.legislative.rule_versioning
test_positive_rule_versioning {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.legislative.rule_versioning"
}

test_negative_rule_versioning {
    result := data.jdg.legislative_monitor.decide with input as {}
    result.rule_id != "jdg.legislative.rule_versioning"
}
