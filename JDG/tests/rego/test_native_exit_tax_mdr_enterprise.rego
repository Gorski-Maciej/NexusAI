# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: exit_tax_mdr_enterprise
# Source: exit_tax_mdr_enterprise.rego
# Generated: 2026-08-02T09:14:32.159854
# Package: jdg.exit_tax_mdr
# Rules tested: 8
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_exit_tax_mdr
import data.jdg.exit_tax_mdr

# 1. jdg.exit_tax_mdr.no_match
test_positive_no_match {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.exit_tax_mdr.no_match"
}

test_negative_no_match {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.rule_id != "jdg.exit_tax_mdr.no_match"
}

# 2. jdg.exit_tax.asset_transfer_abroad_detected
test_positive_asset_transfer_abroad_detected {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.exit_tax.asset_transfer_abroad_detected"
}

test_negative_asset_transfer_abroad_detected {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.rule_id != "jdg.exit_tax.asset_transfer_abroad_detected"
}

# 3. jdg.exit_tax.cfc_foreign_company_detected
test_positive_cfc_foreign_company_detected {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.exit_tax.cfc_foreign_company_detected"
}

test_negative_cfc_foreign_company_detected {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.rule_id != "jdg.exit_tax.cfc_foreign_company_detected"
}

# 4. jdg.exit_tax.mdr_scheme_detected
test_positive_mdr_scheme_detected {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.exit_tax.mdr_scheme_detected"
}

test_negative_mdr_scheme_detected {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.rule_id != "jdg.exit_tax.mdr_scheme_detected"
}

# 5. jdg.exit_tax.transfer_pricing_obligation
test_positive_transfer_pricing_obligation {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.exit_tax.transfer_pricing_obligation"
}

test_negative_transfer_pricing_obligation {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.rule_id != "jdg.exit_tax.transfer_pricing_obligation"
}

# 6. jdg.exit_tax.estonian_cit_vs_pit_analysis
test_positive_estonian_cit_vs_pit_analysis {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.exit_tax.estonian_cit_vs_pit_analysis"
}

test_negative_estonian_cit_vs_pit_analysis {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.rule_id != "jdg.exit_tax.estonian_cit_vs_pit_analysis"
}

# 7. jdg.exit_tax.double_tax_treaty_analyzer
test_positive_double_tax_treaty_analyzer {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.exit_tax.double_tax_treaty_analyzer"
}

test_negative_double_tax_treaty_analyzer {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.rule_id != "jdg.exit_tax.double_tax_treaty_analyzer"
}

# 8. jdg.exit_tax.cross_border_risk_summary
test_positive_cross_border_risk_summary {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.exit_tax.cross_border_risk_summary"
}

test_negative_cross_border_risk_summary {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.rule_id != "jdg.exit_tax.cross_border_risk_summary"
}
