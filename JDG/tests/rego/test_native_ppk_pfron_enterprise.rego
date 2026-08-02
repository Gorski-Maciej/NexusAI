# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: ppk_pfron_enterprise
# Source: ppk_pfron_enterprise.rego
# Generated: 2026-08-02T09:14:32.303556
# Package: jdg.ppk_pfron
# Rules tested: 8
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_ppk_pfron
import data.jdg.ppk_pfron

# 1. jdg.ppk_pfron.no_match
test_positive_no_match {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.no_match"
}

test_negative_no_match {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.rule_id != "jdg.ppk_pfron.no_match"
}

# 2. jdg.ppk_pfron.ppk_enrollment_check
test_positive_ppk_enrollment_check {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.ppk_enrollment_check"
}

test_negative_ppk_enrollment_check {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.rule_id != "jdg.ppk_pfron.ppk_enrollment_check"
}

# 3. jdg.ppk_pfron.ppk_contribution_calculation
test_positive_ppk_contribution_calculation {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.ppk_contribution_calculation"
}

test_negative_ppk_contribution_calculation {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.rule_id != "jdg.ppk_pfron.ppk_contribution_calculation"
}

# 4. jdg.ppk_pfron.pfron_obligation_check
test_positive_pfron_obligation_check {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.pfron_obligation_check"
}

test_negative_pfron_obligation_check {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.rule_id != "jdg.ppk_pfron.pfron_obligation_check"
}

# 5. jdg.ppk_pfron.pfron_relief_calculation
test_positive_pfron_relief_calculation {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.pfron_relief_calculation"
}

test_negative_pfron_relief_calculation {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.rule_id != "jdg.ppk_pfron.pfron_relief_calculation"
}

# 6. jdg.ppk_pfron.fgsp_contribution
test_positive_fgsp_contribution {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.fgsp_contribution"
}

test_negative_fgsp_contribution {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.rule_id != "jdg.ppk_pfron.fgsp_contribution"
}

# 7. jdg.ppk_pfron.zfss_obligation
test_positive_zfss_obligation {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.zfss_obligation"
}

test_negative_zfss_obligation {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.rule_id != "jdg.ppk_pfron.zfss_obligation"
}

# 8. jdg.ppk_pfron.employer_total_cost_summary
test_positive_employer_total_cost_summary {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.employer_total_cost_summary"
}

test_negative_employer_total_cost_summary {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.rule_id != "jdg.ppk_pfron.employer_total_cost_summary"
}
