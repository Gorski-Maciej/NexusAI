# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PCC Loans + Companies + Rates
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pcc.loans_companies_rates_test

import data.jdg.pcc.loans
import data.jdg.pcc.exchanges_companies
import data.jdg.pcc.rate_changes

# ── Loans tests ───────────────────────────────────────────────────────────────

test_loan_basic_pcc if {
    result := loans.decide with input as {
        "invoice": {"transaction_type": "LOAN"}
    }
    result.matched == true
    result.rule_id == "jdg.pcc.loans.a1.r1"
    result.pcc_rate == 0.005
}

test_family_loan_exempt if {
    result := loans.decide with input as {
        "invoice": {
            "transaction_type": "LOAN",
            "lender_family_group": "I",
            "amount_gross": 20000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.loans.a1.r2"
}

test_family_loan_over_limit if {
    result := loans.decide with input as {
        "invoice": {
            "transaction_type": "LOAN",
            "lender_family_group": "I",
            "amount_gross": 50000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.loans.a1.r3"
}

test_third_party_loan if {
    result := loans.decide with input as {
        "invoice": {
            "transaction_type": "LOAN",
            "lender_family_group": "III"
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.loans.a1.r5"
}

test_pcc_deadline_exceeded if {
    result := loans.decide with input as {
        "invoice": {
            "transaction_type": "LOAN",
            "pcc_3_deadline_exceeded": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.loans.a1.r6"
    result._routing == "BLOCK_AND_ALERT"
}

# ── Companies tests ───────────────────────────────────────────────────────────

test_company_formation_capital if {
    result := exchanges_companies.decide with input as {
        "invoice": {
            "transaction_type": "COMPANY_FORMATION",
            "company_type": "CAPITAL"
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.exchanges_companies.company.r1"
}

test_capital_increase if {
    result := exchanges_companies.decide with input as {
        "invoice": {"transaction_type": "CAPITAL_INCREASE"}
    }
    result.matched == true
    result.rule_id == "jdg.pcc.exchanges_companies.company.r2"
}

test_barter_exchange_pcc if {
    result := exchanges_companies.decide with input as {
        "invoice": {
            "transaction_type": "BARTER_EXCHANGE",
            "has_vat": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.exchanges_companies.exchange.r1"
}

test_donation_no_pcc if {
    result := exchanges_companies.decide with input as {
        "invoice": {"transaction_type": "DONATION_CIVIL_LAW"}
    }
    result.matched == true
    result.rule_id == "jdg.pcc.exchanges_companies.donation.r1"
}

# ── Rate changes tests ────────────────────────────────────────────────────────

test_pcc_obligation_trigger if {
    result := rate_changes.decide with input as {
        "invoice": {"is_pcc_transaction": true}
    }
    result.matched == true
    result.rule_id == "jdg.pcc.rate_changes.a3.r1"
}

test_preliminary_agreement_no_pcc if {
    result := rate_changes.decide with input as {
        "invoice": {"is_preliminary_agreement": true}
    }
    result.matched == true
    result.rule_id == "jdg.pcc.rate_changes.a3.r5"
}

test_contract_modification if {
    result := rate_changes.decide with input as {
        "invoice": {
            "is_contract_modification": true,
            "modification_additional_value": 10000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.rate_changes.modification.r1"
}

test_sanction_rate if {
    result := rate_changes.decide with input as {
        "invoice": {"pcc_sanction_triggered": true}
    }
    result.matched == true
    result.rule_id == "jdg.pcc.rate_changes.a7.r5"
    result.sanction_rate == 0.20
}

test_voluntary_disclosure if {
    result := rate_changes.decide with input as {
        "invoice": {"is_voluntary_disclosure_pcc": true}
    }
    result.matched == true
    result.rule_id == "jdg.pcc.rate_changes.payment.r4"
}
