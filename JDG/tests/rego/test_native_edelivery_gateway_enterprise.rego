# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: edelivery_gateway_enterprise
# Source: edelivery_gateway_enterprise.rego
# Generated: 2026-08-02T09:14:32.151177
# Package: jdg.edelivery_gateway
# Rules tested: 4
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_edelivery_gateway
import data.jdg.edelivery_gateway

# 1. jdg.edelivery_gateway.no_match
test_positive_no_match {
    result := data.jdg.edelivery_gateway.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.edelivery_gateway.no_match"
}

test_negative_no_match {
    result := data.jdg.edelivery_gateway.decide with input as {}
    result.rule_id != "jdg.edelivery_gateway.no_match"
}

# 2. jdg.edelivery_gateway.delivery_status
test_positive_delivery_status {
    result := data.jdg.edelivery_gateway.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.edelivery_gateway.delivery_status"
}

test_negative_delivery_status {
    result := data.jdg.edelivery_gateway.decide with input as {}
    result.rule_id != "jdg.edelivery_gateway.delivery_status"
}

# 3. jdg.edelivery_gateway.eus_scanner
test_positive_eus_scanner {
    result := data.jdg.edelivery_gateway.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.edelivery_gateway.eus_scanner"
}

test_negative_eus_scanner {
    result := data.jdg.edelivery_gateway.decide with input as {}
    result.rule_id != "jdg.edelivery_gateway.eus_scanner"
}

# 4. jdg.edelivery_gateway.fiction_delivery_alert
test_positive_fiction_delivery_alert {
    result := data.jdg.edelivery_gateway.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.edelivery_gateway.fiction_delivery_alert"
}

test_negative_fiction_delivery_alert {
    result := data.jdg.edelivery_gateway.decide with input as {}
    result.rule_id != "jdg.edelivery_gateway.fiction_delivery_alert"
}
