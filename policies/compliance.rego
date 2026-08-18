# NexusAI JDG Policies — Compliance package (P20-P157).
# Public rules: whitelist, split payment, cash limit, receipt, cash register, CESOP.
# Legal basis: Art. 96b VAT, Art. 108a VAT, Art. 22p PIT, Regulation 2020/284 CESOP.
package jdg.compliance

import future.keywords.in
import data.jdg.helpers
import data.jdg.thresholds

default decide := {"matched": false, "rule_id": "jdg.compliance.no_match", "package": "jdg.compliance", "priority": 167}

whistleblower_procedure_check := {
    "rule_id": "jdg.compliance.whistleblower_procedure_required",
    "package": "jdg.compliance", "priority": 1730,
    "whistleblower_procedure_required": true,
    "whistleblower_potential_penalty": "do_30_000_PLN",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Obowiązek procedury sygnalistów — %d osób, brak procedury", [workers_count]),
    "_legal_basis": "Ustawa z 14.06.2024 o ochronie sygnalistów",
    "_warnings": [sprintf("SYGNALIŚCI — %d osób ≥ 50 → obowiązek wdrożenia procedury zgłoszeń! Kara do 30 000 PLN.", [workers_count])]
} {
    profile := object.get(input, "jdg_entrepreneur", {})
    workers_count := object.get(profile, "workers_count", 0)
    workers_count >= 50
    object.get(profile, "whistleblower_procedure_implemented", true) == false
}

aml_procedure_check := {
    "rule_id": "jdg.compliance.aml_procedure_required",
    "package": "jdg.compliance", "priority": 1731,
    "aml_obligated_entity": true, "aml_procedure_required": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Podmiot obowiązany AML — PKD: %s", [pkd]),
    "_legal_basis": "Ustawa AML z 01.03.2018",
    "_warnings": [sprintf("AML — działalność (%s) podlega AML. Wdróż procedurę i raportuj do GIIF.", [pkd])]
} {
    profile := object.get(input, "jdg_entrepreneur", {})
    pkd := object.get(profile, "pkd_main", "")
    aml_pkd := {"69.20.Z", "66.19.Z", "68.31.Z", "64.99.Z"}
    pkd in aml_pkd
    object.get(profile, "aml_procedure_implemented", true) == false
}

# P20 — whitelist missing over the mandatory threshold.
decide := {
    "matched": true, "rule_id": "jdg.compliance.whitelist_missing_over_limit", "package": "jdg.compliance", "priority": 20,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak kontrahenta na Białej Liście MF — odpowiedzialność solidarna",
    "_legal_basis": "Art. 96b VAT, Art. 117ba Ordynacji podatkowej", "_warnings": ["Brak kontrahenta na Białej Liście MF — odpowiedzialność solidarna przedsiębiorcy!"]
} {
    invoice := object.get(input, "invoice", {})
    vendor := object.get(input, "vendor", {})
    object.get(invoice, "amount_gross", 0) >= thresholds.misc.mpp_mandatory_threshold
    object.get(vendor, "on_whitelist", false) == false
}

# P21 — whitelist account mismatch.
else := {
    "matched": true, "rule_id": "jdg.compliance.whitelist_account_mismatch", "package": "jdg.compliance", "priority": 21,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Rachunek niezgodny z Białą Listą MF", "_legal_basis": "Art. 117ba § 1 Ordynacji podatkowej", "_warnings": []
} {
    invoice := object.get(input, "invoice", {})
    vendor := object.get(input, "vendor", {})
    object.get(invoice, "amount_gross", 0) >= thresholds.misc.mpp_mandatory_threshold
    object.get(vendor, "on_whitelist", false)
    object.get(vendor, "account_on_whitelist", false) == false
}

# P25 — mandatory MPP absent.
else := {
    "matched": true, "rule_id": "jdg.compliance.split_payment_mandatory", "package": "jdg.compliance", "priority": 25,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "mpp_required": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "MPP OBOWIĄZKOWY — brak split payment przy transakcji >15k z Załącznika 15",
    "_legal_basis": "Art. 108a ust. 1-1d VAT", "_warnings": [sprintf("BRAK MPP! Faktura %.2f PLN brutto, kategoria %s. Sankcja 30%% VAT: %.2f PLN. NKUP: %.2f PLN.", [amount_gross, category, vat_amount * thresholds.misc.mpp_sanction_rate, amount_net])]
} {
    invoice := object.get(input, "invoice", {})
    amount_gross := object.get(invoice, "amount_gross", 0)
    amount_gross >= thresholds.misc.mpp_mandatory_threshold
    category := object.get(invoice, "category_code", "")
    helpers.jdg_is_mpp_sensitive(category)
    object.get(invoice, "split_payment_used", false) == false
    amount_net := object.get(invoice, "amount_net", 0)
    vat_amount := amount_gross - amount_net
}

# P25b — mandatory MPP applied.
else := {
    "matched": true, "rule_id": "jdg.compliance.split_payment_mandatory_applied", "package": "jdg.compliance", "priority": 25,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "mpp_required": true, "mpp_applied": true, "joint_vat_liability_exempt": true, "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 108a VAT", "_warnings": ["MPP zastosowany prawidłowo — zwolnienie z odpowiedzialności solidarnej za VAT kontrahenta"]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "amount_gross", 0) >= thresholds.misc.mpp_mandatory_threshold
    helpers.jdg_is_mpp_sensitive(object.get(invoice, "category_code", ""))
    object.get(invoice, "split_payment_used", false)
}

# P26 — voluntary MPP safe harbor.
else := {
    "matched": true, "rule_id": "jdg.compliance.split_payment_voluntary_safe_harbor", "package": "jdg.compliance", "priority": 26,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "joint_vat_liability_exempt": true, "mpp_voluntary_safe_harbor": true, "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 108a ust. 1d VAT", "_warnings": ["Dobrowolny MPP — zwolnienie z odpowiedzialności solidarnej za VAT kontrahenta"]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "amount_gross", 0) < thresholds.misc.mpp_mandatory_threshold
    object.get(invoice, "voluntary_split_payment_used", false)
}

# P35 — cash transaction over 15k.
else := {
    "matched": true, "rule_id": "jdg.compliance.cash_transaction_over_limit", "package": "jdg.compliance", "priority": 35,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 22p ustawy o PIT", "_warnings": ["Płatność gotówkowa powyżej 15 000 PLN — wydatek NIE stanowi KUP!"]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "is_cash_payment", false)
    object.get(invoice, "amount_gross", 0) >= thresholds.misc.cash_payment_limit
}

# P36 — simplified receipt and over-limit receipt.
else := {
    "matched": true, "rule_id": "jdg.compliance.vat_simplified_receipt", "package": "jdg.compliance", "priority": 36,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "vat_deduction_allowed": true, "receipt_treated_as_invoice": true, "_routing": "", "_routing_reason": "Paragon z NIP do 450 PLN jako faktura uproszczona",
    "_legal_basis": "Art. 106e ust. 5 pkt 3 VAT", "_warnings": ["Paragon z NIP — odliczenie VAT możliwe do 450 PLN brutto"]
} {
    invoice := object.get(input, "invoice", {})
    profile := object.get(input, "jdg_entrepreneur", {})
    object.get(invoice, "direction", "") == "PURCHASE"
    object.get(invoice, "invoice_type", "") == "RECEIPT"
    object.get(invoice, "has_nip", false)
    object.get(profile, "is_vat_payer", false)
    object.get(invoice, "amount_gross", 0) > 0
    object.get(invoice, "amount_gross", 0) <= 450
} else := {
    "matched": true, "rule_id": "jdg.compliance.vat_simplified_receipt_over_limit", "package": "jdg.compliance", "priority": 36,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "vat_deduction_allowed": false, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Paragon powyżej 450 PLN — brak prawa do odliczenia VAT",
    "_legal_basis": "Art. 106e ust. 5 pkt 3 VAT", "_warnings": ["Paragon powyżej 450 PLN brutto NIE jest fakturą uproszczoną — brak prawa do odliczenia VAT"]
} {
    invoice := object.get(input, "invoice", {})
    object.get(invoice, "direction", "") == "PURCHASE"
    object.get(invoice, "invoice_type", "") == "RECEIPT"
    object.get(invoice, "has_nip", false)
    object.get(invoice, "amount_gross", 0) > 450
}

# P145 — cash register B2C exemption.
else := {
    "matched": true, "rule_id": "jdg.compliance.cash_register_b2c_exemption", "package": "jdg.compliance", "priority": 145,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "cash_register_exempt": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Rozporządzenie MF w sprawie zwolnień z kas rejestrujących",
    "_warnings": ["Zwolnienie z kasy fiskalnej — limit 20 000 PLN rocznego obrotu B2C"]
} {
    invoice := object.get(input, "invoice", {})
    profile := object.get(input, "jdg_entrepreneur", {})
    vendor := object.get(input, "vendor", {})
    object.get(invoice, "direction", "") == "SALE"
    object.get(profile, "b2c_annual_turnover_for_fiscal", 0) < 20000
    object.get(vendor, "is_b2c", false)
}

# P155 — CESOP cross-border reporting.
else := {
    "matched": true, "rule_id": "jdg.compliance.cesop_cross_border", "package": "jdg.compliance", "priority": 155,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,
    "cesop_reportable": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Rozporządzenie 2020/284 (CESOP)",
    "_warnings": ["Transgraniczne płatności UE >25 000 EUR rocznie — raportowanie CESOP"]
} {
    invoice := object.get(input, "invoice", {})
    vendor := object.get(input, "vendor", {})
    profile := object.get(input, "jdg_entrepreneur", {})
    object.get(invoice, "direction", "") == "SALE"
    object.get(vendor, "country", "") in eu_countries
    object.get(profile, "annual_cross_border_eur", 0) > 25000
}

eu_countries := {"AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"}
