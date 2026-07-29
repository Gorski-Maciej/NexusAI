# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — PIT: Rozszerzenie NKUP Art. 23 + Paliwo + Nadpłata
# Generated: 2026-07-29 — P04 Report Phase 2
# Package: jdg.pit.kup_extended
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.kup_extended

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.pit.kup_extended.no_match",
    "package": "jdg.pit.kup_extended",
    "priority": 999
}

# ═══════════════════════════════════════════════════════════════════════════════
# P573: kup_fuel_75_100 — Paliwo KUP: 75% bez ewidencji, 100% z ewidencją
# Art. 23 ust. 1 pkt 46 PIT
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.fuel_75_100",
    "package": "jdg.pit.kup_extended", "priority": 573,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "car_fuel_kup", "kus_percent": fuel_kup_pct,
    "kus_fuel_mileage_log_required": true,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2022-01-01", "valid_to": null,
    "_routing": "", "_routing_reason": sprintf("Paliwo — %.0f%% KUP (%s ewidencji przebiegu)", [fuel_kup_pct, log_status]),
    "_legal_basis": "Art. 23 ust. 1 pkt 46 PIT (paliwo do auta osobowego)",
    "_warnings": [sprintf("PALIWO — %.0f%% KUP. %s Prowadź ewidencję kilometrową aby odliczyć 100%% kosztów paliwa.", [fuel_kup_pct, log_warn])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "CAR_FUEL"
    has_mileage_log := object.get(input.jdg_entrepreneur, "car_mileage_log_active", false)
    fuel_kup_pct = floor(thresholds.rates.car_kup_with_log * 100) { has_mileage_log == true }
    fuel_kup_pct = floor(thresholds.rates.car_kup_no_log * 100) { has_mileage_log == false }
    log_status = "z" { has_mileage_log == true }
    log_status = "BEZ" { has_mileage_log == false }
    log_warn = "" { has_mileage_log == true }
    log_warn = "BEZ ewidencji tylko 75%." { has_mileage_log == false }
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P574: nkup_fines_penalties — Kary i grzywny → NKUP
# Art. 23 ust. 1 pkt 3 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.fines_penalties_nkup",
    "package": "jdg.pit.kup_extended", "priority": 574,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Kary/grzywny → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 3 PIT",
    "_warnings": ["Kary, grzywny, odszkodowania karne — CAŁKOWICIE wyłączone z KUP"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type in {"FINE", "PENALTY", "DAMAGES_PUNITIVE", "ADMINISTRATIVE_FINE"}
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P575: nkup_personal_expenses — Wydatki osobiste → NKUP
# Art. 23 ust. 1 pkt 33 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.personal_expenses_nkup",
    "package": "jdg.pit.kup_extended", "priority": 575,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Wydatki osobiste → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 33 PIT",
    "_warnings": ["Wydatki na cele osobiste podatnika — NIE stanowią KUP"]
} {
    input.invoice.direction == "PURCHASE"
    object.get(input.invoice, "private_use_percent", 0) == 100
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P576: nkup_donations_over_limit — Darowizny powyżej limitu 6% dochodu → NKUP
# Art. 23 ust. 1 pkt 34 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.donations_over_limit",
    "package": "jdg.pit.kup_extended", "priority": 576,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "kus_donation_excess": true,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": sprintf("Darowizna > 6%% dochodu — nadwyżka %.2f PLN → NKUP", [excess_amount]),
    "_legal_basis": "Art. 23 ust. 1 pkt 34 w zw. z Art. 26 ust. 1 pkt 9 PIT",
    "_warnings": [sprintf("Darowizna %.2f PLN przekracza limit 6%% dochodu (max %.2f PLN). Nadwyżka %.2f PLN = NKUP.", [donation_amount, donation_limit, excess_amount])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "DONATION"
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_estimate", 0)
    donation_amount := object.get(input.invoice, "amount_net", 0)
    donation_limit := floor(annual_income * 0.06 * 100) / 100
    donation_amount > donation_limit
    excess_amount := donation_amount - donation_limit
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P577: nkup_loan_interest_over_limit — Odsetki od kredytów powyżej limitu → NKUP
# Art. 23 ust. 1 pkt 14 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.loan_interest_over_limit",
    "package": "jdg.pit.kup_extended", "priority": 577,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "kus_interest_excess": true,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Odsetki od kredytu > limit — NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 14 PIT (niedostateczna kapitalizacja)",
    "_warnings": ["Odsetki od kredytu powyżej limitu kapitalizacji — NIE stanowią KUP"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "LOAN_INTEREST"
    object.get(input.invoice, "thin_capitalization_excess", false) == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P578: nkup_alcohol_tobacco — Alkohol i tytoń → NKUP
# Art. 23 ust. 1 pkt 2 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.alcohol_tobacco_nkup",
    "package": "jdg.pit.kup_extended", "priority": 578,
    "vat_rate": "", "rounding_level": "", "gtu_code": "GTU_01",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Alkohol/tytoń → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 2 PIT",
    "_warnings": ["Wydatki na alkohol i wyroby tytoniowe — CAŁKOWICIE wyłączone z KUP (chyba że stanowią przedmiot działalności)"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type in {"ALCOHOL", "TOBACCO"}
    object.get(input.jdg_entrepreneur, "is_alcohol_tobacco_business", false) == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P579: kup_insurance_property — Ubezpieczenie majątku firmowego → KUP
# Art. 22 ust. 1 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.insurance_property_kup",
    "package": "jdg.pit.kup_extended", "priority": 579,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Ubezpieczenie majątku firmowego → KUP",
    "_legal_basis": "Art. 22 ust. 1 PIT (ubezpieczenie majątku firmowego)",
    "_warnings": ["Ubezpieczenie majątku firmowego — STANOWI KUP w 100%"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "INSURANCE_BUSINESS_PROPERTY"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P580: nkup_tax_paid — Zapłacone podatki → NKUP
# Art. 23 ust. 1 pkt 32 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.tax_paid_nkup",
    "package": "jdg.pit.kup_extended", "priority": 580,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Zapłacony podatek → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 32 PIT",
    "_warnings": ["Zapłacony podatek dochodowy, VAT naliczony, podatek od nieruchomości (osobisty) — NIE stanowią KUP"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "TAX_PAID"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P581: advance_tax_overpayment_detection — Nadpłata/niedopłata zaliczek PIT
# Art. 44 + Art. 45 PIT — wykrywanie nadpłaty/niedopłaty po zeznaniu rocznym
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.advance_settlement",
    "package": "jdg.pit.kup_extended", "priority": 581,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "pit_advance_settlement": settlement_type,
    "pit_overpayment_amount": overpayment,
    "pit_underpayment_amount": underpayment,
    "pit_underpayment_interest_daily": interest_daily,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2022-07-01", "valid_to": null,
    "_routing": routing_dest,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 44 ust. 1, Art. 45 PIT, Art. 56 § 1 Ordynacji podatkowej",
    "_warnings": [warning_msg]
} {
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 0)
    annual_tax := object.get(input.jdg_entrepreneur, "annual_tax_calculated", 0)
    advances_paid := object.get(input.jdg_entrepreneur, "advances_paid_ytd", 0)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Nadpłata: zaliczki > podatek roczny
    is_overpayment = true { advances_paid > annual_tax }
    is_overpayment = false { advances_paid <= annual_tax }

    # Niedopłata: podatek roczny > zaliczki
    is_underpayment = true { annual_tax > advances_paid }
    is_underpayment = false { annual_tax <= advances_paid }

    settlement_type = "OVERPAYMENT" { is_overpayment == true }
    settlement_type = "UNDERPAYMENT" { is_underpayment == true }
    settlement_type = "BALANCED" { is_overpayment == false; is_underpayment == false }

    overpayment = advances_paid - annual_tax { is_overpayment == true }
    overpayment = 0 { is_overpayment == false }
    underpayment = annual_tax - advances_paid { is_underpayment == true }
    underpayment = 0 { is_underpayment == false }

    # Odsetki za zwłokę (Art. 56 § 1 Ordynacji) — ~14.5% rocznie / 365
    interest_daily = floor(underpayment * thresholds.rates.tax_interest / 365 * 100) / 100 { is_underpayment == true }
    interest_daily = 0 { is_underpayment == false }

    routing_dest = "" { is_overpayment == true }
    routing_dest = "BLOCK_AND_ALERT" { is_underpayment == true }
    routing_dest = "" { settlement_type == "BALANCED" }

    routing_reason = sprintf("Nadpłata %.2f PLN — zwrot lub zaliczenie na przyszłe zaliczki", [overpayment]) { is_overpayment == true }
    routing_reason = sprintf("NIEDOPŁATA %.2f PLN + odsetki %.2f PLN/dzień — DOPŁAĆ NATYCHMIAST!", [underpayment, interest_daily]) { is_underpayment == true }
    routing_reason = "Zaliczki = podatek roczny — rozliczenie zbilansowane" { settlement_type == "BALANCED" }

    warning_msg = sprintf("NADPŁATA PIT: %.2f PLN. Możesz wnioskować o zwrot na konto lub zaliczenie na poczet przyszłych zaliczek (Art. 77 Ordynacji).", [overpayment]) { is_overpayment == true }
    warning_msg = sprintf("NIEDOPŁATA PIT: %.2f PLN! Dopłać natychmiast. Odsetki za zwłokę: %.2f PLN/dzień (14.5%% rocznie). Termin: 30 kwietnia (PIT-36/36L) / 28 lutego (PIT-28).", [underpayment, interest_daily]) { is_underpayment == true }
    warning_msg = "Zaliczki PIT = podatek roczny. Rozliczenie roczne zbilansowane — brak nadpłaty/niedopłaty." { settlement_type == "BALANCED" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P582: nkup_gifts_over_limit — Prezenty powyżej limitu → NKUP
# Art. 23 ust. 1 pkt 34 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.gifts_over_limit",
    "package": "jdg.pit.kup_extended", "priority": 582,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": sprintf("Prezent > %.0f PLN — NKUP", [thresholds.pit.gift_limit_pln]),
    "_legal_basis": "Art. 23 ust. 1 pkt 34 PIT",
    "_warnings": [sprintf("Prezent o wartości %.2f PLN przekracza limit %.0f PLN — NIE stanowi KUP", [amount_net, thresholds.pit.gift_limit_pln])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "GIFT"
    amount_net := object.get(input.invoice, "amount_net", 0)
    amount_net > thresholds.pit.gift_limit_pln
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}
