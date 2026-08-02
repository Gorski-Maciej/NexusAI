# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: decision_composer_enterprise
# Source: decision_composer_enterprise.rego
# Generated: 2026-08-02T09:14:32.143787
# Package: jdg.decision_composer
# Rules tested: 3
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_decision_composer
import data.jdg.decision_composer

# 1. jdg.decision_composer.no_match
test_positive_no_match {
    result := data.jdg.decision_composer.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.decision_composer.no_match"
}

test_negative_no_match {
    result := data.jdg.decision_composer.decide with input as {}
    result.rule_id != "jdg.decision_composer.no_match"
}

# 2. jdg.decision_composer.routing_aggregator
test_positive_routing_aggregator {
    result := data.jdg.decision_composer.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.decision_composer.routing_aggregator"
}

test_negative_routing_aggregator {
    result := data.jdg.decision_composer.decide with input as {}
    result.rule_id != "jdg.decision_composer.routing_aggregator"
}

# 3. jdg.decision_composer.conflict_detector
test_positive_conflict_detector {
    result := data.jdg.decision_composer.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.decision_composer.conflict_detector"
}

test_negative_conflict_detector {
    result := data.jdg.decision_composer.decide with input as {}
    result.rule_id != "jdg.decision_composer.conflict_detector"
}
