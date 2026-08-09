# Native Rego contract tests for jdg.gtu_checker.

package test_jdg_gtu_checker


test_no_match_for_empty_input {
    result := data.jdg.gtu_checker.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.gtu_checker.no_match"
}

test_completeness_audit {
    result := data.jdg.gtu_checker.decide with input as {
        "gtu_completeness_audit": true,
        "gtu_audit_period": "2026-07",
        "gtu_total_taxable_items": 10,
        "gtu_correctly_assigned": 8,
        "gtu_missing_count": 1,
        "gtu_incorrect_count": 1,
        "gtu_missing_codes": ["GTU_08"],
    }
    result.matched == true
    result.rule_id == "jdg.gtu_checker.completeness_audit"
    result.priority == 2120
    result.gtu_audit_completeness_pct == 80
    result._routing == "BLOCK_AND_ALERT"
}

test_per_invoice_validation_correct {
    result := data.jdg.gtu_checker.decide with input as {
        "gtu_validate_invoice": true,
        "product_category": "TOBACCO",
        "invoice": {"gtu_code": "GTU_04"},
    }
    result.rule_id == "jdg.gtu_checker.per_invoice_validation"
    result.gtu_is_correct == true
    result._routing == ""
}

test_per_invoice_validation_incorrect {
    result := data.jdg.gtu_checker.decide with input as {
        "gtu_validate_invoice": true,
        "product_category": "TOBACCO",
        "invoice": {"gtu_code": "GTU_01"},
    }
    result.rule_id == "jdg.gtu_checker.per_invoice_validation"
    result.gtu_is_correct == false
    result._routing == "BLOCK_AND_ALERT"
}

test_correction_proposal {
    result := data.jdg.gtu_checker.decide with input as {
        "gtu_propose_correction": true,
        "product_category": "TOBACCO",
        "invoice": {"invoice_number": "FV/1/2026", "gtu_code": "GTU_01"},
    }
    result.rule_id == "jdg.gtu_checker.correction_proposal"
    result.gtu_correction_proposed == "GTU_04"
    result._routing == "TRIAGE_QUEUE"
}

test_first_match_prefers_audit {
    result := data.jdg.gtu_checker.decide with input as {
        "gtu_completeness_audit": true,
        "gtu_validate_invoice": true,
        "gtu_propose_correction": true,
    }
    result.rule_id == "jdg.gtu_checker.completeness_audit"
    result.priority == 2120
}

test_no_match_for_unrelated_input {
    result := data.jdg.gtu_checker.decide with input as {"invoice": {"gtu_code": "GTU_04"}}
    result.matched == false
    result.rule_id == "jdg.gtu_checker.no_match"
}
