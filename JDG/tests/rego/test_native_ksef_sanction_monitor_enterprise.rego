# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: ksef_sanction_monitor_enterprise
# Source: ksef_sanction_monitor_enterprise.rego
# Generated: 2026-08-02T09:14:32.239879
# Package: jdg.ksef_sanction_monitor
# Rules tested: 3
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_ksef_sanction_monitor
import data.jdg.ksef_sanction_monitor

# 1. jdg.ksef_sanction_monitor.no_match
test_positive_no_match {
    result := data.jdg.ksef_sanction_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ksef_sanction_monitor.no_match"
}

test_negative_no_match {
    result := data.jdg.ksef_sanction_monitor.decide with input as {}
    result.rule_id != "jdg.ksef_sanction_monitor.no_match"
}

# 2. jdg.ksef_sanction_monitor.exposure_calculator
test_positive_exposure_calculator {
    result := data.jdg.ksef_sanction_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ksef_sanction_monitor.exposure_calculator"
}

test_negative_exposure_calculator {
    result := data.jdg.ksef_sanction_monitor.decide with input as {}
    result.rule_id != "jdg.ksef_sanction_monitor.exposure_calculator"
}

# 3. jdg.ksef_sanction_monitor.per_invoice_estimator
test_positive_per_invoice_estimator {
    result := data.jdg.ksef_sanction_monitor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ksef_sanction_monitor.per_invoice_estimator"
}

test_negative_per_invoice_estimator {
    result := data.jdg.ksef_sanction_monitor.decide with input as {}
    result.rule_id != "jdg.ksef_sanction_monitor.per_invoice_estimator"
}
