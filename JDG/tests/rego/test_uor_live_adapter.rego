package jdg.uor_live_adapter_test

import future.keywords.if
import data.jdg.uor_live

test_default_no_match if {
    result := uor_live.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.uor_live.no_match"
}

test_accounting_obligation_blocks_over_threshold if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {
            "uor_check_requested": true,
            "annual_revenue_actual": 10000000,
            "uor_compliant": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor_live.full_accounting_obligation_check"
    result.uor_full_accounting_required == true
    result._routing == "BLOCK_AND_ALERT"
}

test_accounting_obligation_warns_early if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {
            "uor_check_requested": true,
            "revenue_q1": 6750000,
            "current_quarter": 2
        }
    }
    result.rule_id == "jdg.uor_live.full_accounting_obligation_check"
    result.uor_early_warning_active == true
    result._routing == "WARNING"
}

test_principles_detect_cash_method if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_uses_cash_method": true
        }
    }
    result.rule_id == "jdg.uor_live.accounting_principles_check"
    result.uor_accrual_principle_ok == false
    result._routing == "TRIAGE_QUEUE"
}

test_substance_over_form_detects_lease if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {
            "expense_type": "LEASE",
            "lease_term_vs_useful_life_pct": 80
        }
    }
    result.rule_id == "jdg.uor_live.substance_over_form_check"
    result.uor_sof_ok == false
    result.uor_sof_violations_count == 1
    result._routing == "TRIAGE_QUEUE"
}

test_document_validation_blocks_incomplete_document if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "uor_document_check": true,
        "vendor": {},
        "invoice": {}
    }
    result.rule_id == "jdg.uor_live.accounting_document_validation"
    result.uor_doc_elements_present < 8
    result._routing == "BLOCK_AND_ALERT"
}

test_double_entry_detects_difference if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_debit_total": 2000,
            "uor_credit_total": 1000
        },
        "invoice": {"is_period_end": true}
    }
    result.rule_id == "jdg.uor_live.double_entry_validation"
    result.uor_double_entry_balanced == false
    result._routing == "TRIAGE_QUEUE"
}

test_inventory_requires_all_parts if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_inventory_check": true,
            "uor_physical_count_done": true,
            "uor_balance_confirmation_done": true,
            "uor_document_verification_done": false
        },
        "invoice": {"is_year_end": true}
    }
    result.rule_id == "jdg.uor_live.inventory_obligation_check"
    result.uor_inventory_complete == false
    result._routing == "BLOCK_AND_ALERT"
}

test_asset_impairment_routes_to_triage if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {
            "expense_type": "FIXED_ASSET",
            "amount_net": 100000,
            "asset_market_value": 40000
        }
    }
    result.rule_id == "jdg.uor_live.asset_valuation_check"
    result.uor_valuation_impairment_required == true
    result._routing == "TRIAGE_QUEUE"
}

test_rmk_issue_routes_to_triage if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_has_prepaid_expenses": true,
            "uor_rmk_properly_booked": false
        },
        "invoice": {"is_period_end": true}
    }
    result.rule_id == "jdg.uor_live.accruals_deferrals_check"
    result._routing == "TRIAGE_QUEUE"
}

test_financial_statement_not_filed_blocks if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_financial_statement_filed": false
        },
        "invoice": {"is_year_end": true}
    }
    result.rule_id == "jdg.uor_live.financial_statement_obligation"
    result._routing == "BLOCK_AND_ALERT"
}

test_retention_is_available if {
    result := uor_live.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "uor_retention_check": true
    }
    result.rule_id == "jdg.uor_live.document_retention_check"
    result.uor_retention_years == 5
}
