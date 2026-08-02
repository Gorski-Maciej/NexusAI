# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: wis_api_enterprise
# Source: wis_api_enterprise.rego
# Generated: 2026-08-02T09:14:32.344897
# Package: jdg.wis_api
# Rules tested: 4
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_wis_api
import data.jdg.wis_api

# 1. jdg.wis_api.no_match
test_positive_no_match {
    result := data.jdg.wis_api.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.wis_api.no_match"
}

test_negative_no_match {
    result := data.jdg.wis_api.decide with input as {}
    result.rule_id != "jdg.wis_api.no_match"
}

# 2. jdg.wis_api.cn_to_vat_mapping
test_positive_cn_to_vat_mapping {
    result := data.jdg.wis_api.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.wis_api.cn_to_vat_mapping"
}

test_negative_cn_to_vat_mapping {
    result := data.jdg.wis_api.decide with input as {}
    result.rule_id != "jdg.wis_api.cn_to_vat_mapping"
}

# 3. jdg.wis_api.wis_w_application
test_positive_wis_w_application {
    result := data.jdg.wis_api.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.wis_api.wis_w_application"
}

test_negative_wis_w_application {
    result := data.jdg.wis_api.decide with input as {}
    result.rule_id != "jdg.wis_api.wis_w_application"
}

# 4. jdg.wis_api.gtu_wis_cross_reference
test_positive_gtu_wis_cross_reference {
    result := data.jdg.wis_api.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.wis_api.gtu_wis_cross_reference"
}

test_negative_gtu_wis_cross_reference {
    result := data.jdg.wis_api.decide with input as {}
    result.rule_id != "jdg.wis_api.gtu_wis_cross_reference"
}
