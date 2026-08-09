# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: audit_defense_enterprise
# ═══════════════════════════════════════════════════════════════
# Public contract: data.jdg.audit_defense.decide
# ═══════════════════════════════════════════════════════════════

package test_jdg_audit_defense

import data.jdg.audit_defense

# Default is fail-closed for an empty context.
test_no_match_empty_input {
    result := data.jdg.audit_defense.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.audit_defense.no_match"
}

test_no_match_is_not_positive_rule {
    result := data.jdg.audit_defense.decide with input as {"audit_risk_check": true, "jdg_entrepreneur": {}}
    result.rule_id != "jdg.audit_defense.no_match"
}

test_positive_risk_scoring {
    result := data.jdg.audit_defense.decide with input as {
        "audit_risk_check": true,
        "jdg_entrepreneur": {
            "vat_correction_pct_annual": 0.31,
            "tax_form": "PIT_SCALE"
        }
    }
    result.matched == true
    result.rule_id == "jdg.audit_defense.risk_scoring"
    result.audit_risk_score == 25
}

test_negative_risk_scoring_without_flag {
    result := data.jdg.audit_defense.decide with input as {}
    result.rule_id != "jdg.audit_defense.risk_scoring"
}

test_positive_voluntary_disclosure_strategy {
    result := data.jdg.audit_defense.decide with input as {
        "audit_voluntary_disclosure_check": true,
        "jdg_entrepreneur": {
            "has_unreported_income": true,
            "tax_authority_initiated_proceedings": false,
            "unreported_tax_amount": 10000
        }
    }
    result.matched == true
    result.rule_id == "jdg.audit_defense.voluntary_disclosure_strategy"
    result.audit_voluntary_disclosure_recommended == true
}

test_negative_voluntary_disclosure_without_flag {
    result := data.jdg.audit_defense.decide with input as {}
    result.rule_id != "jdg.audit_defense.voluntary_disclosure_strategy"
}

test_positive_appeal_procedure {
    result := data.jdg.audit_defense.decide with input as {
        "audit_appeal_needed": true,
        "jdg_entrepreneur": {"tax_decision_amount": 20000}
    }
    result.matched == true
    result.rule_id == "jdg.audit_defense.appeal_procedure"
}

test_negative_appeal_without_flag {
    result := data.jdg.audit_defense.decide with input as {}
    result.rule_id != "jdg.audit_defense.appeal_procedure"
}

test_positive_statute_of_limitations {
    result := data.jdg.audit_defense.decide with input as {
        "audit_statute_check": true,
        "jdg_entrepreneur": {
            "tax_years_active": [2020, 2024],
            "tax_events": [{"type": "AUDIT_INITIATED"}]
        }
    }
    result.matched == true
    result.rule_id == "jdg.audit_defense.statute_of_limitations"
    result.audit_tax_year_expiring == [2020]
}

test_negative_statute_without_flag {
    result := data.jdg.audit_defense.decide with input as {}
    result.rule_id != "jdg.audit_defense.statute_of_limitations"
}
