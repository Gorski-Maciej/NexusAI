# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Compliance: Biała Lista, MPP, gotówka, kasy, CESOP (P20-P157)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Compliance Package — Whitelist, MPP, Cash Limits, Fiscal Registers, CESOP
# description: |
#   PAS 2 Multi-Pass. First-Match-Wins else-chain. Weryfikuje zgodność transakcji
#   z obowiązkami compliance: Biała Lista MF (P20/P21), obowiązkowy/dobrowolny MPP
#   (P25/P25b), limit gotówkowy 15k → NKUP (P35), kasy fiskalne B2C (P145),
#   raportowanie CESOP dla transakcji transgranicznych >25k EUR (P155).
# architecture: Multi-Pass PAS 2 (ADR-001)
# legal_basis: Art. 96b VAT, Art. 108a VAT, Art. 22p PIT, Rozp. 2020/284 CESOP
# edge_cases:
#   - P20 vs P21: brak na WL vs niezgodny rachunek (oba BLOCK)
#   - P25b: dobrowolny MPP → safe harbor przed odpowiedzialnością solidarną
#   - P35: tylko przy is_cash_payment AND >= 15000
# package: jdg.compliance
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.compliance
import data.jdg.helpers
import data.jdg.thresholds
default decide := {"matched":false,"rule_id":"jdg.compliance.no_match","package":"jdg.compliance","priority":167}

# ══════ P1730: whistleblower_procedure_check — Sygnaliści ≥50 os. (standalone advisory) ══════
whistleblower_procedure_check := {
    "rule_id":"jdg.compliance.whistleblower_procedure_required",
    "package":"jdg.compliance","priority":1730,
    "whistleblower_procedure_required":true,
    "whistleblower_potential_penalty":"do_30_000_PLN",
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason":sprintf("Obowiązek procedury sygnalistów — %d osób, brak procedury", [workers_count]),
    "_legal_basis":"Ustawa z 14.06.2024 o ochronie sygnalistów (Dz.U. 2024 poz. 928)",
    "_warnings":[sprintf("SYGNALIŚCI — %d osób ≥ 50 → obowiązek wdrożenia procedury zgłoszeń! Kara do 30 000 PLN.", [workers_count])]
} {
    workers_count := object.get(input.jdg_entrepreneur, "workers_count", 0)
    workers_count >= 50
    object.get(input.jdg_entrepreneur, "whistleblower_procedure_implemented", true) == false
}

# ══════ P1731: aml_procedure_check — AML dla biur rachunkowych/krypto (standalone) ══════
aml_procedure_check := {
    "rule_id":"jdg.compliance.aml_procedure_required",
    "package":"jdg.compliance","priority":1731,
    "aml_obligated_entity":true,
    "aml_procedure_required":true,
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason":sprintf("Podmiot obowiązany AML — PKD: %s", [pkd]),
    "_legal_basis":"Ustawa AML z 01.03.2018 (Dz.U. 2025 poz. 567)",
    "_warnings":[sprintf("AML — Twoja działalność (%s) podlega AML. Wdróż procedurę i raportuj do GIIF. Kara do 5 000 000 PLN.", [pkd])]
} {
    pkd := object.get(input.jdg_entrepreneur, "pkd_main", "")
    aml_pkd := {"69.20.Z", "66.19.Z", "68.31.Z", "64.99.Z"}
    pkd in aml_pkd
    object.get(input.jdg_entrepreneur, "aml_procedure_implemented", true) == false
}

# ══════ P20: whitelist_missing_over_limit — Brak na Białej Liście >15k ══════
decide := {
    "matched":true,"rule_id":"jdg.compliance.whitelist_missing_over_limit",
    "package":"jdg.compliance","priority":20,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Brak kontrahenta na Białej Liście MF — odpowiedzialność solidarna",
    "_legal_basis":"Art. 96b VAT, Art. 117ba Ordynacji podatkowej",
    "_warnings":["Brak kontrahenta na Białej Liście MF — odpowiedzialność solidarna przedsiębiorcy!"]
} {
    input.invoice.amount_gross >= thresholds.misc.mpp_mandatory_threshold
    input.vendor.on_whitelist == false
}

# ══════ P21: whitelist_account_mismatch — Rachunek niezgodny z WL ══════
else := {
    "matched":true,"rule_id":"jdg.compliance.whitelist_account_mismatch",
    "package":"jdg.compliance","priority":21,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Rachunek niezgodny z Białą Listą MF",
    "_legal_basis":"Art. 117ba § 1 Ordynacji podatkowej",
    "_warnings":[]
} {
    input.invoice.amount_gross >= thresholds.misc.mpp_mandatory_threshold
    input.vendor.on_whitelist == true
    input.vendor.account_on_whitelist == false
}

# ══════ P25: split_payment_mandatory — Obowiązkowy MPP ══════
# v7.0 QF-3: Dodano BLOCK_AND_ALERT przy braku MPP
else := {
    "matched":true,"rule_id":"jdg.compliance.split_payment_mandatory",
    "package":"jdg.compliance","priority":25,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"none","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "mpp_required":true,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"MPP OBOWIĄZKOWY — brak split payment przy transakcji >15k z Załącznika 15",
    "_legal_basis":"Art. 108a ust. 1-1d VAT, Art. 105a-105c VAT",    "_warnings": [sprintf("BRAK MPP! Faktura %.2f PLN brutto, kategoria %s z Załącznika 15. Sankcja 30%% VAT: %.2f PLN. NKUP PIT/CIT: %.2f PLN. Solidarna odpowiedzialność za VAT dostawcy. Wykonaj przelew MPP.", [amount_gross, category, vat_amount * thresholds.misc.mpp_sanction_rate, amount_net])]
} {
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross >= thresholds.misc.mpp_mandatory_threshold
    category := input.invoice.category_code
    helpers.jdg_is_mpp_sensitive(category)
    input.invoice.split_payment_used == false
    amount_net := object.get(input.invoice, "amount_net", 0)
    vat_amount := amount_gross - amount_net
}

# ══════ P25b: split_payment_mandatory_ok — MPP obowiązkowy zastosowany ══════
else := {
    "matched":true,"rule_id":"jdg.compliance.split_payment_mandatory_applied",
    "package":"jdg.compliance","priority":25,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "mpp_required":true,"mpp_applied":true,
    "joint_vat_liability_exempt":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 108a VAT",
    "_warnings":["MPP zastosowany prawidłowo — zwolnienie z odpowiedzialności solidarnej za VAT kontrahenta"]
} {
    input.invoice.amount_gross >= thresholds.misc.mpp_mandatory_threshold
    helpers.jdg_is_mpp_sensitive(input.invoice.category_code)
    input.invoice.split_payment_used == true
}

# ══════ P26: split_payment_voluntary_safe_harbor — Dobrowolny MPP ══════
else := {
    "matched":true,"rule_id":"jdg.compliance.split_payment_voluntary_safe_harbor",
    "package":"jdg.compliance","priority":26,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "joint_vat_liability_exempt":true,"mpp_voluntary_safe_harbor":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 108a ust. 1d VAT",
    "_warnings":["Dobrowolny MPP — zwolnienie z odpowiedzialności solidarnej za VAT kontrahenta"]
} {
    input.invoice.amount_gross < thresholds.misc.mpp_mandatory_threshold
    input.invoice.voluntary_split_payment_used == true
}

# ══════ P35: cash_transaction_over_limit — Gotówka >15k → NKUP ══════
else := {
    "matched":true,"rule_id":"jdg.compliance.cash_transaction_over_limit",
    "package":"jdg.compliance","priority":35,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"none","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22p ustawy o PIT",
    "_warnings":["Płatność gotówkowa powyżej 15 000 PLN — wydatek NIE stanowi KUP!"]
} {
    input.invoice.is_cash_payment == true
    input.invoice.amount_gross >= thresholds.misc.cash_payment_limit
}

# ══════ P36: vat_simplified_receipt — Paragon z NIP jako faktura uproszczona ══════
# Doc 26 §II: Paragon z NIP do 450 PLN brutto = faktura uproszczona → można odliczyć VAT
else := {
    "matched":true,"rule_id":"jdg.compliance.vat_simplified_receipt",
    "package":"jdg.compliance","priority":36,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "vat_deduction_allowed":true,"receipt_treated_as_invoice":true,
    "_routing":"","_routing_reason":"Paragon z NIP do 450 PLN jako faktura uproszczona",
    "_legal_basis":"Art. 106e ust. 5 pkt 3 VAT",
    "_warnings":["Paragon z NIP — odliczenie VAT możliwe do kwoty 450 PLN brutto"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.invoice_type == "RECEIPT"
    input.invoice.has_nip == true
    input.jdg_entrepreneur.is_vat_payer == true
    amount_gross := object.get(input.invoice,"amount_gross",0)
    amount_gross <= 450
    amount_gross > 0
} else := {
    "matched":true,"rule_id":"jdg.compliance.vat_simplified_receipt_over_limit",
    "package":"jdg.compliance","priority":36,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "vat_deduction_allowed":false,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Paragon powyżej 450 PLN — brak prawa do odliczenia VAT",
    "_legal_basis":"Art. 106e ust. 5 pkt 3 VAT",
    "_warnings":["Paragon powyżej 450 PLN brutto NIE jest fakturą uproszczoną — brak prawa do odliczenia VAT"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.invoice_type == "RECEIPT"
    input.invoice.has_nip == true
    amount_gross := object.get(input.invoice,"amount_gross",0)
    amount_gross > 450
}

# ══════ P145: cash_register_b2c_exemption — Zwolnienie z kasy fiskalnej ══════
else := {
    "matched":true,"rule_id":"jdg.compliance.cash_register_b2c_exemption",
    "package":"jdg.compliance","priority":145,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "cash_register_exempt":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozporządzenie MF w sprawie zwolnień z kas rejestrujących",
    "_warnings":["Zwolnienie z kasy fiskalnej — limit 20 000 PLN rocznego obrotu B2C"]
} {
    input.invoice.direction == "SALE"
    b2c_turnover := object.get(input.jdg_entrepreneur,"b2c_annual_turnover_for_fiscal",0)
    b2c_turnover < 20000
    input.vendor.is_b2c == true
}

# ══════ P155: cesop_cross_border_payment_reporting ══════
else := {
    "matched":true,"rule_id":"jdg.compliance.cesop_cross_border",
    "package":"jdg.compliance","priority":155,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "cesop_reportable":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozporządzenie 2020/284 (CESOP)",
    "_warnings":["Transgraniczne płatności UE >25 000 EUR rocznie — raportowanie CESOP od 01.01.2024"]
} {
    input.invoice.direction == "SALE"
    input.vendor.country in eu_countries
    cross_border := object.get(input.jdg_entrepreneur,"annual_cross_border_eur",0)
    cross_border > 25000
}

# ── EU countries ──
eu_countries := {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE"}
