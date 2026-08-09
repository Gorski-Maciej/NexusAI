# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: banking_automation_enterprise
# Source: banking_automation_enterprise.rego
# Package: jdg.banking
# ═══════════════════════════════════════════════════════════════

package test_jdg_banking

import data.jdg.banking

# Empty input must remain fail-closed.
test_positive_no_match {
    result := data.jdg.banking.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.banking.no_match"
}

test_negative_no_match {
    result := data.jdg.banking.decide with input as {"banking_iban_validation": true, "bank_account_to_validate": "bad"}
    result.rule_id != "jdg.banking.no_match"
}

# BNK-1800
test_positive_split_payment_preparation {
    result := data.jdg.banking.decide with input as {
        "banking_mpp_prepare": true,
        "invoice": {"direction": "PURCHASE", "amount_gross": 20000, "amount_net": 16260.16, "vat_amount": 3739.84, "vat_rate": "23%", "gtu_code": "GTU_01", "document_type": "INVOICE", "invoice_number": "FV/1"},
        "vendor": {"nip": "1111111111", "bank_account": "PL00102010260000042270201111", "name": "Vendor"},
        "jdg_entrepreneur": {"nip": "2222222222"}
    }
    result.matched == true
    result.rule_id == "jdg.banking.split_payment_preparation"
}

test_negative_split_payment_preparation {
    result := data.jdg.banking.decide with input as {}
    result.rule_id != "jdg.banking.split_payment_preparation"
}

# BNK-1810
test_positive_zus_transfer_preparation {
    result := data.jdg.banking.decide with input as {"banking_zus_prepare": true, "jdg_entrepreneur": {"zus_status": "STANDARD", "tax_form": "PIT_SCALE"}} with data.thresholds as {"bounds": {"minimum_wage_gross": 4800, "average_wage": 8000}, "limits": {"health_linear_deduction_limit": 11800}}
    result.matched == true
    result.rule_id == "jdg.banking.zus_transfer_preparation"
}

test_negative_zus_transfer_preparation {
    result := data.jdg.banking.decide with input as {}
    result.rule_id != "jdg.banking.zus_transfer_preparation"
}

# BNK-1820
test_positive_tax_office_transfer_preparation {
    result := data.jdg.banking.decide with input as {"banking_tax_office_prepare": true, "jdg_entrepreneur": {"monthly_vat_to_pay": 1000, "monthly_pit_advance": 500}}
    result.matched == true
    result.rule_id == "jdg.banking.tax_office_transfer_preparation"
}

test_negative_tax_office_transfer_preparation {
    result := data.jdg.banking.decide with input as {}
    result.rule_id != "jdg.banking.tax_office_transfer_preparation"
}

# BNK-1830
test_positive_monthly_payment_batch {
    result := data.jdg.banking.decide with input as {"banking_generate_batch": true, "jdg_entrepreneur": {"monthly_vat_to_pay": 1000}}
    result.matched == true
    result.rule_id == "jdg.banking.monthly_payment_batch"
}

test_negative_monthly_payment_batch {
    result := data.jdg.banking.decide with input as {}
    result.rule_id != "jdg.banking.monthly_payment_batch"
}

# BNK-1840
test_positive_iban_validation {
    result := data.jdg.banking.decide with input as {"banking_validate_iban": true, "bank_account_to_validate": "PL00102010260000042270201111"}
    result.matched == true
    result.rule_id == "jdg.banking.iban_validation"
}

test_negative_iban_validation {
    result := data.jdg.banking.decide with input as {}
    result.rule_id != "jdg.banking.iban_validation"
}

# BNK-1845
test_positive_psd2_consent_management {
    result := data.jdg.banking.decide with input as {"banking_psd2_consent_check": true, "psd2": {"consent_status": "VALID", "consent_type": "AIS"}}
    result.matched == true
    result.rule_id == "jdg.banking.psd2_consent_management"
}

test_negative_psd2_consent_management {
    result := data.jdg.banking.decide with input as {}
    result.rule_id != "jdg.banking.psd2_consent_management"
}

# BNK-1850
test_positive_ais_account_information {
    result := data.jdg.banking.decide with input as {"banking_ais_fetch": true, "psd2": {"account_id": "acct-1", "last_known_available": 10000}}
    result.matched == true
    result.rule_id == "jdg.banking.ais_account_information"
}

test_negative_ais_account_information {
    result := data.jdg.banking.decide with input as {}
    result.rule_id != "jdg.banking.ais_account_information"
}
