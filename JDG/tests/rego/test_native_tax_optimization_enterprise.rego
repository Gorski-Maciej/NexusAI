# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: tax_optimization_enterprise
# Source: tax_optimization_enterprise.rego
# Generated: 2026-08-02T09:14:32.332138
# Package: jdg.tax_optimization
# Rules tested: 10
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_tax_optimization
import data.jdg.tax_optimization

# 1. jdg.tax_opt.no_match
test_positive_no_match {
    result := data.jdg.tax_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.tax_opt.no_match"
}

test_negative_no_match {
    result := data.jdg.tax_optimization.decide with input as {}
    result.rule_id != "jdg.tax_opt.no_match"
}

# 2. jdg.tax_opt.form_comparison_annual
test_positive_form_comparison_annual {
    result := data.jdg.tax_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.tax_opt.form_comparison_annual"
}

test_negative_form_comparison_annual {
    result := data.jdg.tax_optimization.decide with input as {}
    result.rule_id != "jdg.tax_opt.form_comparison_annual"
}

# 3. jdg.tax_opt.allowance_stacking_strategy
test_positive_allowance_stacking_strategy {
    result := data.jdg.tax_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.tax_opt.allowance_stacking_strategy"
}

test_negative_allowance_stacking_strategy {
    result := data.jdg.tax_optimization.decide with input as {}
    result.rule_id != "jdg.tax_opt.allowance_stacking_strategy"
}

# 4. jdg.tax_opt.ip_box_deep_analysis
test_positive_ip_box_deep_analysis {
    result := data.jdg.tax_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.tax_opt.ip_box_deep_analysis"
}

test_negative_ip_box_deep_analysis {
    result := data.jdg.tax_optimization.decide with input as {}
    result.rule_id != "jdg.tax_opt.ip_box_deep_analysis"
}

# 5. jdg.tax_opt.zus_comparison_by_form
test_positive_zus_comparison_by_form {
    result := data.jdg.tax_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.tax_opt.zus_comparison_by_form"
}

test_negative_zus_comparison_by_form {
    result := data.jdg.tax_optimization.decide with input as {}
    result.rule_id != "jdg.tax_opt.zus_comparison_by_form"
}

# 6. jdg.tax_opt.estonian_cit_analysis
test_positive_estonian_cit_analysis {
    result := data.jdg.tax_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.tax_opt.estonian_cit_analysis"
}

test_negative_estonian_cit_analysis {
    result := data.jdg.tax_optimization.decide with input as {}
    result.rule_id != "jdg.tax_opt.estonian_cit_analysis"
}

# 7. jdg.tax_opt.joint_filing_optimizer
test_positive_joint_filing_optimizer {
    result := data.jdg.tax_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.tax_opt.joint_filing_optimizer"
}

test_negative_joint_filing_optimizer {
    result := data.jdg.tax_optimization.decide with input as {}
    result.rule_id != "jdg.tax_opt.joint_filing_optimizer"
}

# 8. jdg.tax_opt.income_smoothing_strategy
test_positive_income_smoothing_strategy {
    result := data.jdg.tax_optimization.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.tax_opt.income_smoothing_strategy"
}

test_negative_income_smoothing_strategy {
    result := data.jdg.tax_optimization.decide with input as {}
    result.rule_id != "jdg.tax_opt.income_smoothing_strategy"
}
