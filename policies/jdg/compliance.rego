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
default decide := {"matched":false,"rule_id":"jdg.compliance.no_match","package":"jdg.compliance","priority":167}

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
    input.invoice.amount_gross >= 15000
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
    input.invoice.amount_gross >= 15000
    input.vendor.on_whitelist == true
    input.vendor.account_on_whitelist == false
}

# ══════ P25: split_payment_mandatory — Obowiązkowy MPP ══════
else := {
    "matched":true,"rule_id":"jdg.compliance.split_payment_mandatory",
    "package":"jdg.compliance","priority":25,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "mpp_required":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 108a VAT",
    "_warnings":["Obowiązkowy mechanizm podzielonej płatności (MPP) — towary/usługi wrażliwe + kwota ≥ 15 000 PLN"]
} {
    input.invoice.amount_gross >= 15000
    helpers.jdg_is_mpp_sensitive(input.invoice.category_code)
}

# ══════ P25_b: split_payment_voluntary_safe_harbor — Dobrowolny MPP ══════
else := {
    "matched":true,"rule_id":"jdg.compliance.split_payment_voluntary_safe_harbor",
    "package":"jdg.compliance","priority":25,
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
    input.invoice.amount_gross < 15000
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
    input.invoice.amount_gross >= 15000
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
