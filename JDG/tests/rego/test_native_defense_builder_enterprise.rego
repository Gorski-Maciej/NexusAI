# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: defense_builder_enterprise
# Source: defense_builder_enterprise.rego
# Generated: 2026-08-02T09:14:32.148519
# Package: jdg.defense_builder
# Rules tested: 4
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_defense_builder
import data.jdg.defense_builder

# 1. jdg.defense_builder.no_match
test_positive_no_match {
    result := data.jdg.defense_builder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.defense_builder.no_match"
}

test_negative_no_match {
    result := data.jdg.defense_builder.decide with input as {}
    result.rule_id != "jdg.defense_builder.no_match"
}

# 2. jdg.defense_builder.audit_prep_checklist
test_positive_audit_prep_checklist {
    result := data.jdg.defense_builder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.defense_builder.audit_prep_checklist"
}

test_negative_audit_prep_checklist {
    result := data.jdg.defense_builder.decide with input as {}
    result.rule_id != "jdg.defense_builder.audit_prep_checklist"
}

# 3. jdg.defense_builder.mock_audit
test_positive_mock_audit {
    result := data.jdg.defense_builder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.defense_builder.mock_audit"
}

test_negative_mock_audit {
    result := data.jdg.defense_builder.decide with input as {}
    result.rule_id != "jdg.defense_builder.mock_audit"
}

# 4. jdg.defense_builder.article_193a_planner
test_positive_article_193a_planner {
    result := data.jdg.defense_builder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.defense_builder.article_193a_planner"
}

test_negative_article_193a_planner {
    result := data.jdg.defense_builder.decide with input as {}
    result.rule_id != "jdg.defense_builder.article_193a_planner"
}
