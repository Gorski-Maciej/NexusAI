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

# ═══════════════════════════════════════════════════════════════════════════════
# P583: nkup_fixed_asset_improvement — Ulepszenie ŚT powyżej 10k → amortyzacja
# Art. 23 ust. 1 pkt 15 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.asset_improvement",
    "package": "jdg.pit.kup_extended", "priority": 583,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "depreciation_only", "kus_percent": 0,
    "kus_asset_improvement": true, "kus_depreciation_required": true,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Ulepszenie ŚT → amortyzacja, nie bezpośredni KUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 15 PIT",
    "_warnings": [sprintf("ULEPSZENIE ŚT %.2f PLN — NIE jest bezpośrednim KUP! Podwyższa wartość początkową. Rozliczaj przez amortyzację.", [amount_net])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "FIXED_ASSET_IMPROVEMENT"
    amount_net := object.get(input.invoice, "amount_net", 0)
    amount_net >= object.get(object.get(data.thresholds, "depreciation", {}), "improvement_threshold", 10000)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P584: nkup_training_unrelated — Szkolenia niezwiązane z DG → NKUP
# Art. 23 ust. 1 pkt 43 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.training_unrelated",
    "package": "jdg.pit.kup_extended", "priority": 584,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Szkolenie niezwiązane z DG → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 43 PIT",
    "_warnings": ["Szkolenie/kurs niezwiązane z prowadzoną działalnością gospodarczą — NIE stanowi KUP"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "TRAINING"
    object.get(input.invoice, "training_business_related", true) == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P585: nkup_uncompensated_transfer — Nieodpłatne przekazanie → NKUP
# Art. 23 ust. 1 pkt 45 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.uncompensated_transfer",
    "package": "jdg.pit.kup_extended", "priority": 585,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nieodpłatne przekazanie → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 45 PIT",
    "_warnings": ["Nieodpłatne przekazanie towarów/usług — NIE stanowi KUP. Wyjątek: darowizny do 6% dochodu na OPP"]
} {
    input.invoice.direction == "PURCHASE"
    object.get(input.invoice, "is_uncompensated_transfer", false) == true
    object.get(input.invoice, "is_charity_donation", false) == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P586: nkup_health_scale_no_deduction — Składka zdrowotna na skali → nie KUP
# Art. 23 ust. 1 pkt 38 PIT (Polski Ład: skala nie odlicza zdrowotnej)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.health_scale_no_deduction",
    "package": "jdg.pit.kup_extended", "priority": 586,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "kus_health_scale_no_deduction": true,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2022-01-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Skala PIT — składka zdrowotna NIE podlega odliczeniu (Polski Ład)",
    "_legal_basis": "Art. 23 ust. 1 pkt 38 w zw. z Art. 30c ust. 2 PIT",
    "_warnings": [sprintf("SKŁADKA ZDROWOTNA %.2f PLN — NIE odliczasz od dochodu na skali PIT. Tylko liniowy i ryczałt mają odliczenie (Polski Ład 2022).", [health_paid])]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    input.invoice.expense_type == "ZUS_HEALTH_ENTREPRENEUR"
    input.invoice.is_paid == true
    health_paid := object.get(input.invoice, "amount_net", 0)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P587: nkup_lease_over_car_limit — Część kapitałowa raty > limit auta → NKUP
# Art. 23 ust. 1 pkt 48 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.lease_capital_over_limit",
    "package": "jdg.pit.kup_extended", "priority": 587,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "kus_lease_capital_excess": true,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2019-01-01", "valid_to": null,
    "_routing": "", "_routing_reason": sprintf("Część kapitałowa raty > limit %.0f PLN → NKUP", [car_limit]),
    "_legal_basis": "Art. 23 ust. 1 pkt 48 PIT",
    "_warnings": [sprintf("LEASING AUTA — część kapitałowa %.2f PLN przekracza limit %.0f PLN. Nadwyżka = NKUP.", [capital_portion, car_limit])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "CAR_LEASE_CAPITAL"
    car_value := object.get(input.invoice, "car_value", 0)
    is_ev := object.get(input.invoice, "is_electric", false)
    car_limit = thresholds.pit.car_value_limit_standard { is_ev == false }
    car_limit = thresholds.pit.car_value_limit_ev { is_ev == true }
    car_value > car_limit
    capital_portion := object.get(input.invoice, "amount_net", 0)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P588: nkup_tax_loss_liquidation — Strata z likwidacji ŚT → NKUP
# Art. 23 ust. 1 pkt 17 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.liquidation_loss",
    "package": "jdg.pit.kup_extended", "priority": 588,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Strata z likwidacji ŚT → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 17 PIT",
    "_warnings": ["Strata z likwidacji środka trwałego — NIE stanowi KUP. Wyjątek: strata ze sprzedaży — stanowi KUP."]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "FIXED_ASSET_LIQUIDATION_LOSS"
    object.get(input.invoice, "is_sale_proceeds", false) == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P589: nkup_insurance_damages — Odszkodowania z ubezpieczeń → NKUP
# Art. 23 ust. 1 pkt 6 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.insurance_damages_nkup",
    "package": "jdg.pit.kup_extended", "priority": 589,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "",    "_routing_reason": "Odszkodowania wypłacone z ubezpieczeń → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 6 PIT",
    "_warnings": ["Wypłacone odszkodowania z tytułu ubezpieczeń majątkowych — NIE stanowią KUP (wydatek nie jest kosztem)"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "INSURANCE_DAMAGES_PAID"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P590: nkup_personal_care — Zabiegi pielęgnacyjne/kosmetyczne → NKUP
# Art. 23 ust. 1 pkt 28 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.personal_care_nkup",
    "package": "jdg.pit.kup_extended", "priority": 590,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Zabiegi pielęgnacyjne → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 28 PIT",
    "_warnings": ["Wydatki na zabiegi kosmetyczne, pielęgnacyjne, odnowę biologiczną — NIE stanowią KUP"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type in {"PERSONAL_CARE", "COSMETIC_PROCEDURE", "SPA_WELLNESS"}
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P591: nkup_construction_for_sale — Wydatki na budowę na sprzedaż → nie KUP
# Art. 23 ust. 1 pkt 19 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.construction_for_sale_nkup",
    "package": "jdg.pit.kup_extended", "priority": 591,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "capitalize_only", "kus_percent": 0,
    "kus_construction_capitalize": true,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Budowa na sprzedaż → kapitalizacja, nie KUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 19 PIT",
    "_warnings": ["Wydatki na budowę nieruchomości przeznaczonej na sprzedaż — NIE są KUP. Kapitalizuj w wartości środka trwałego/transakcji."]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "CONSTRUCTION_FOR_SALE"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P592: nkup_rd_not_in_relief — B+R nieobjęte ulgą → NKUP
# Art. 23 ust. 1 pkt 52 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.rd_not_in_relief_nkup",
    "package": "jdg.pit.kup_extended", "priority": 592,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "kus_rd_not_qualified": true,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Koszty B+R nieobjęte ulgą → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 52 PIT",
    "_warnings": ["Koszty B+R NIE mieszczące się w definicji ulgi B+R (Art. 26e) — NIE stanowią KUP w części przekraczającej limit"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "RD_EXPENSE"
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P593: nkup_life_insurance — Składki ubezpieczenia życiowego → NKUP
# Art. 23 ust. 1 pkt 55 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.life_insurance_nkup",
    "package": "jdg.pit.kup_extended", "priority": 593,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Ubezpieczenie życiowe → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 55 PIT",
    "_warnings": ["Składki na ubezpieczenie na życie (poza PPE/PPK) — NIE stanowią KUP dla JDG"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "LIFE_INSURANCE"
    object.get(input.invoice, "is_ppe_ppk", false) == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P594: shared_limit_tracker — Śledzenie wykorzystania limitu PIT-0
# Rekomendacja 6.7 — Shared Limit Tracker
# Wartość limitu: thresholds.pit.pit_relief_shared_limit (2026=85528)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.shared_limit_tracker",
    "package": "jdg.pit.kup_extended", "priority": 594,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "pit0_shared_limit_total": thresholds.pit.pit_relief_shared_limit,
    "pit0_used_ytd": pit0_used,
    "pit0_remaining": pit0_remaining,
    "pit0_usage_pct": usage_pct,
    "pit0_limit_exceeded": pit0_used > thresholds.pit.pit_relief_shared_limit,
    "pit0_warning_threshold_80pct": thresholds.pit.pit_relief_shared_limit * 0.80,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2022-01-01", "valid_to": null,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 21 ust. 1 pkt 148-154 PIT (wspólny limit ulg PIT-0)",
    "_warnings": [sprintf("PIT-0 SHARED LIMIT TRACKER — Wykorzystano %.2f PLN z %.0f PLN (%.0f%%). Pozostało: %.2f PLN. %s", [pit0_used, thresholds.pit.pit_relief_shared_limit, usage_pct, pit0_remaining, action])]
} {
    pit0_used := object.get(input.jdg_entrepreneur, "pit0_exemptions_used_ytd", 0)
    pit0_used > 0
    pit0_remaining := max([thresholds.pit.pit_relief_shared_limit - pit0_used, 0])
    usage_pct := floor(pit0_used / thresholds.pit.pit_relief_shared_limit * 1000) / 10
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    routing = "BLOCK_AND_ALERT" { pit0_used > thresholds.pit.pit_relief_shared_limit }
    routing = "TRIAGE_QUEUE" { pit0_used > thresholds.pit.pit_relief_shared_limit * 0.80; pit0_used <= thresholds.pit.pit_relief_shared_limit }
    routing = "" { pit0_used <= thresholds.pit.pit_relief_shared_limit * 0.80 }
    routing_reason = "PRZEKROCZONY limit PIT-0!" { pit0_used > thresholds.pit.pit_relief_shared_limit }
    routing_reason = sprintf("UWAGA: %.0f%% limitu PIT-0 wykorzystane", [usage_pct]) { pit0_used > thresholds.pit.pit_relief_shared_limit * 0.80; pit0_used <= thresholds.pit.pit_relief_shared_limit }
    routing_reason = sprintf("Limit PIT-0: %.0f%% wykorzystane", [usage_pct]) { pit0_used <= thresholds.pit.pit_relief_shared_limit * 0.80 }
    action = "DOPŁAĆ PIT od nadwyżki!" { pit0_used > thresholds.pit.pit_relief_shared_limit }
    action = "Zbliżasz się do limitu — rozważ optymalizację." { pit0_used > thresholds.pit.pit_relief_shared_limit * 0.80; pit0_used <= thresholds.pit.pit_relief_shared_limit }
    action = "OK" { pit0_used <= thresholds.pit.pit_relief_shared_limit * 0.80 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P595: tax_bracket_optimizer — Optymalizacja progu 120k (12%→32%)
# Rekomendacja 6.10 — Tax Bracket Optimizer
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.tax_bracket_optimizer",
    "package": "jdg.pit.kup_extended", "priority": 595,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": bracket,
    "pit_annual_return_type": "",
    "pit_bracket_threshold": scale_threshold,
    "pit_current_income": current_income,
    "pit_bracket_excess": excess_over_threshold,
    "pit_bracket_savings_potential": potential_savings,
    "pit_optimization_strategies": strategies,
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2022-07-01", "valid_to": null,
    "_routing": opt_rt,
    "_routing_reason": opt_rs,
    "_legal_basis": "Art. 27 ust. 1 PIT (optymalizacja progu 12%/32%)",
    "_warnings": [sprintf("TAX BRACKET OPTIMIZER — Dochód: %.2f PLN (próg: %.0f PLN). Nadwyżka: %.2f PLN × 32%% = %.2f PLN podatku. Potencjalna oszczędność: %.2f PLN (przez obniżenie dochodu poniżej progu). Strategie: %s", [current_income, scale_threshold, excess_over_threshold, excess_tax, potential_savings, strategies])]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    current_income := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    current_income > scale_threshold * 0.85  # Alert at 85% of threshold
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    bracket = "HIGH" { current_income > scale_threshold }
    bracket = "LOW_APPROACHING" { current_income <= scale_threshold }
    excess_over_threshold := max([current_income - scale_threshold, 0])
    excess_tax := excess_over_threshold * 0.32
    staying_low_tax := excess_over_threshold * 0.12
    potential_savings := excess_tax - staying_low_tax
    # Build strategies list as CSV string
    strat_list := ["IKZE (max 16 956 PLN)"]
    strat_list := array.concat(strat_list, ["B+R 200% (jeśli status CBR)"]) { object.get(input.jdg_entrepreneur, "has_rd_status", false) == true }
    strat_list := array.concat(strat_list, ["Darowizny OPP (6% dochodu)"])
    strat_list := array.concat(strat_list, ["ZUS społeczne (odliczenie od dochodu)"])
    strat_list := array.concat(strat_list, ["Przyspieszenie wydatków firmowych"])
    strat_list := array.concat(strat_list, ["Strata z lat ubiegłych (max 50%/rok)"]) { object.get(input.jdg_entrepreneur, "has_tax_loss_carryforward", false) == true }
    strategies := concat(", ", strat_list)
    opt_rt = "TRIAGE_QUEUE" { current_income > scale_threshold }
    opt_rt = "" { current_income <= scale_threshold }
    opt_rs = sprintf("PRZEKROCZONY PRÓG 120k — oszczędność %.2f PLN możliwa", [potential_savings]) { current_income > scale_threshold }
    opt_rs = sprintf("Zbliżasz się do progu 120k (%.0f%%). Rozważ optymalizację.", [current_income / scale_threshold * 100]) { current_income <= scale_threshold }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P596: health_deduction_maximizer — Maksymalizacja odliczenia składki zdrowotnej
# Rekomendacja 6.12 — Health Insurance Deduction Maximizer
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.health_deduction_maximizer",
    "package": "jdg.pit.kup_extended", "priority": 596,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "health_deduction_limit": health_limit,
    "health_paid_ytd": health_paid,
    "health_deductible": health_deductible,
    "health_excess_lost": health_excess,
    "health_deduction_pct": deduction_pct,
    "zus_social_base_type": "", "zus_health_rate": health_rate,
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2022-01-01", "valid_to": null,
    "_routing": health_rt,
    "_routing_reason": health_rs,
    "_legal_basis": "Art. 30c ust. 2 PIT (liniowy) + Art. 81 ustawy o świadczeniach",
    "_warnings": [sprintf("HEALTH DEDUCTION MAXIMIZER — Forma: %s. Składka %.0f%%: %.2f PLN/rok. Limit odliczenia: %.0f PLN. Odliczasz: %.2f PLN (%.0f%%). %s", [pit_form, health_rate * 100, health_paid, health_limit, health_deductible, deduction_pct, excess_msg])]
} {
    input.invoice.expense_type == "ZUS_HEALTH_ENTREPRENEUR"
    input.invoice.is_paid == true
    health_paid := object.get(input.jdg_entrepreneur, "cumulative_zus_health_paid", 0)
    health_paid > 0
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    # Guard: only fire for forms that actually have health deduction (LINEAR, LUMP_SUM)
    pit_form in {"LINEAR", "LUMP_SUM"}

    # Liniowy: odliczenie max 14100 PLN (2026)
    health_limit = thresholds.zus.health_linear_deduction_limit { pit_form == "LINEAR" }
    health_rate = 0.049 { pit_form == "LINEAR" }

    # Ryczałt: 50% składki (odliczenie od przychodu)
    health_limit = health_paid * 0.50 { pit_form == "LUMP_SUM" }
    health_rate = 0.049 { pit_form == "LUMP_SUM" }

    # Skala: BRAK odliczenia (Polski Ład)
    health_limit = 0 { pit_form == "PIT_SCALE" }
    health_rate = 0.09 { pit_form == "PIT_SCALE" }

    # Karta: jak skala
    health_limit = 0 { pit_form == "TAX_CARD" }
    health_rate = 0.09 { pit_form == "TAX_CARD" }

    health_deductible := min([health_paid, health_limit])
    health_excess := max([health_paid - health_limit, 0])
    deduction_pct := floor(health_deductible / max([health_paid, 0.01]) * 100)

    excess_msg = sprintf("Nadwyżka %.2f PLN PRZEPADA — nie przechodzi na kolejny rok!", [health_excess]) { health_excess > 0 }
    excess_msg = "Pełne wykorzystanie limitu." { health_excess == 0; health_limit > 0 }
    excess_msg = "Skala PIT — brak odliczenia (Polski Ład 2022)." { pit_form == "PIT_SCALE" }

    health_rt = "TRIAGE_QUEUE" { health_excess > 1000 }
    health_rt = "" { health_excess <= 1000 }
    health_rs = sprintf("%.2f PLN składki PRZEPADA (ponad limit %.0f PLN)", [health_excess, health_limit]) { health_excess > 1000 }
    health_rs = "Odliczenie zoptymalizowane" { health_excess <= 1000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P597: nkup_social_benefits — Świadczenia ZUS → NKUP (pkt 7)
# Art. 23 ust. 1 pkt 7 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.social_benefits_nkup",
    "package": "jdg.pit.kup_extended", "priority": 597,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Świadczenia ZUS → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 7 PIT",
    "_warnings": ["Wydatki na świadczenia z ZUS wypłacane pracownikom — NIE stanowią KUP (są kosztem pracownika)"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "ZUS_EMPLOYEE_BENEFIT"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P598: nkup_employee_benefits_private — Świadczenia pracownicze prywatne → NKUP
# Art. 23 ust. 1 pkt 10, 11 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.employee_benefits_nkup",
    "package": "jdg.pit.kup_extended", "priority": 598,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Świadczenia prywatne pracowników → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 10-11 PIT",
    "_warnings": ["Świadczenia na cele prywatne pracowników (dofinansowanie wczasów, karnetów sportowych ponad limit) — NIE stanowią KUP"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type in {"EMPLOYEE_VACATION_SUBSIDY", "EMPLOYEE_SPORTS_CARD_EXCESS"}
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P599: nkup_document_loss — Utrata dokumentów → NKUP
# Art. 23 ust. 1 pkt 36 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.document_loss_nkup",
    "package": "jdg.pit.kup_extended", "priority": 599,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak dokumentacji → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 36 PIT",
    "_warnings": ["Wydatki nieudokumentowane lub z utraconą dokumentacją — CAŁKOWICIE wyłączone z KUP! Odtwórz dokumentację przed kontrolą US."]
} {
    input.invoice.direction == "PURCHASE"
    object.get(input.invoice, "documentation_lost", false) == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P600: nkup_penalty_interest — Odsetki karne i sankcyjne → NKUP
# Art. 23 ust. 1 pkt 18 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.penalty_interest_nkup",
    "package": "jdg.pit.kup_extended", "priority": 600,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Odsetki karne/sankcyjne → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 18 PIT",
    "_warnings": ["Odsetki od zaległości podatkowych, karnych, sankcyjnych — NIE stanowią KUP"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type in {"PENALTY_INTEREST", "TAX_ARREARS_INTEREST"}
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P601: cross_relief_interaction_analyzer — Analiza interakcji ulg (Rekomendacja 6.5)
# Matryca NxN: kompatybilność, wykluczenia, synergia między ulgami PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.cross_relief_analyzer",
    "package": "jdg.pit.kup_extended", "priority": 601,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "cross_relief_matrix": relief_matrix,
    "cross_relief_conflicts": conflicts,
    "cross_relief_synergies": synergies,
    "cross_relief_optimal_combo": optimal,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2022-01-01", "valid_to": null,
    "_routing": xr_rt,
    "_routing_reason": xr_rs,
    "_legal_basis": "Art. 21, 26e, 26ha, 30ca, 27f PIT (interakcje ulg)",
    "_warnings": [sprintf("CROSS-RELIEF ANALYZER — %d ulg: %d synergii, %d konfliktów. %s", [count(active_reliefs), count(synergies_list), count(conflicts_list), recommendation])]
} {
    has_rd := object.get(input.jdg_entrepreneur, "has_rd_status", false)
    has_ipbox := object.get(input.jdg_entrepreneur, "ipbox_requested", false)
    has_donations := object.get(input.jdg_entrepreneur, "has_donations", false)
    has_thermo := object.get(input.jdg_entrepreneur, "has_thermo_relief", false)
    has_ikze := object.get(input.jdg_entrepreneur, "has_ikze_account", false)
    children := object.get(input.jdg_entrepreneur, "children_count", 0)
    has_child_relief := children > 0
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Build active reliefs in a single pass
    rd_list := ["B+R"] { has_rd == true } else := [] { has_rd == false }
    ipbox_list := ["IP_BOX"] { has_ipbox == true } else := [] { has_ipbox == false }
    don_list := ["DONATIONS"] { has_donations == true } else := [] { has_donations == false }
    thermo_list := ["THERMO"] { has_thermo == true } else := [] { has_thermo == false }
    ikze_list := ["IKZE"] { has_ikze == true } else := [] { has_ikze == false }
    child_list := ["CHILD"] { has_child_relief == true } else := [] { has_child_relief == false }
    active_reliefs := array.concat(array.concat(array.concat(array.concat(array.concat(rd_list, ipbox_list), don_list), thermo_list), ikze_list), child_list)

    # Build synergies list
    syn_rd_ipbox := ["B+R + IP Box (różne dochody)"] { has_rd == true; has_ipbox == true } else := [] { not (has_rd == true; has_ipbox == true) }
    syn_rd_ikze := ["B+R + IKZE (odliczenie dochodu + od dochodu)"] { has_rd == true; has_ikze == true } else := [] { not (has_rd == true; has_ikze == true) }
    syn_don_ikze := ["Darowizny + IKZE (łączne odliczenie)"] { has_donations == true; has_ikze == true } else := [] { not (has_donations == true; has_ikze == true) }
    synergies_list := array.concat(array.concat(syn_rd_ipbox, syn_rd_ikze), syn_don_ikze)

    # Build conflicts list
    conf_ipbox_lump := ["IP Box vs ryczałt — WYKLUCZONE"] { has_ipbox == true; pit_form == "LUMP_SUM" } else := [] { not (has_ipbox == true; pit_form == "LUMP_SUM") }
    conf_ipbox_est := ["IP Box vs CIT estoński — wybierz jedno"] { has_ipbox == true; pit_form == "ESTONIAN_CIT" } else := [] { not (has_ipbox == true; pit_form == "ESTONIAN_CIT") }
    conflicts_list := array.concat(conf_ipbox_lump, conf_ipbox_est)

    # Gate: only fire when at least 2 reliefs are active
    count(active_reliefs) >= 2

    relief_matrix := {"active": count(active_reliefs), "compatible_pairs": count(synergies_list), "conflict_pairs": count(conflicts_list)}
    conflicts := concat("; ", conflicts_list) { count(conflicts_list) > 0 }
    conflicts := "brak" { count(conflicts_list) == 0 }
    synergies := concat("; ", synergies_list) { count(synergies_list) > 0 }
    synergies := "brak" { count(synergies_list) == 0 }

    recommendation = "Optymalna kombinacja: wykorzystaj wszystkie kompatybilne ulgi." { count(conflicts_list) == 0; count(active_reliefs) >= 2 }
    recommendation = sprintf("UWAGA: %d konfliktów do rozwiązania!", [count(conflicts_list)]) { count(conflicts_list) > 0 }
    recommendation = "Zastosuj dostępne ulgi." { count(active_reliefs) <= 1 }

    xr_rt = "BLOCK_AND_ALERT" { count(conflicts_list) > 0 }
    xr_rt = "TRIAGE_QUEUE" { count(active_reliefs) >= 3 }
    xr_rt = "" { count(active_reliefs) < 3; count(conflicts_list) == 0 }
    xr_rs = sprintf("%d konfliktów ulg — wymagana decyzja", [count(conflicts_list)]) { count(conflicts_list) > 0 }
    xr_rs = sprintf("Analiza %d aktywnych ulg — %d synergii", [count(active_reliefs), count(synergies_list)]) { count(conflicts_list) == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P602: tax_loss_optimizer — Optymalizacja odliczania strat (Rekomendacja 6.6)
# Strategia: max 50% rocznie, 5 lat, optymalizacja progu 12%/32%
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.tax_loss_optimizer",
    "package": "jdg.pit.kup_extended", "priority": 602,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "pit_loss_available": loss_total,
    "pit_loss_year1": loss_year1,
    "pit_loss_max_deductible": max_deduction,
    "pit_loss_optimal_strategy": loss_strategy,
    "pit_loss_savings": loss_savings,
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "TAX_LOSS", "relief_limit": 0, "relief_deductible": max_deduction, "relief_carry_forward_years": 5,
    "valid_from": "2019-01-01", "valid_to": null,
    "_routing": loss_rt,
    "_routing_reason": loss_rs,
    "_legal_basis": "Art. 9 ust. 3 PIT (rozliczanie strat)",
    "_warnings": [sprintf("TAX LOSS OPTIMIZER — Strata: %.2f PLN (rok 1: %.2f PLN). Max odliczenie: %.2f PLN/rok. Optymalna strategia: %s. Oszczędność: %.2f PLN.", [loss_total, loss_year1, max_deduction, loss_strategy, loss_savings])]
} {
    loss_total := object.get(input.jdg_entrepreneur, "tax_loss_available", 0)
    loss_total > 0
    loss_year1 := object.get(input.jdg_entrepreneur, "tax_loss_oldest_year", 0)
    current_income := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    max_deduction := current_income * 0.50  # Max 50% dochodu

    # Sprawdź czy odliczenie obniży próg 32%→12%
    in_high_bracket := current_income > scale_threshold
    reduces_bracket := in_high_bracket == true; (current_income - max_deduction) <= scale_threshold

    loss_strategy = "ODLICZ MAKSYMALNIE (50%) — jesteś w 32% progu" { in_high_bracket == true; reduces_bracket == false }
    loss_strategy = sprintf("ODLICZ %.2f PLN — obniżysz dochód poniżej progu 120k (32%%→12%%)!", [current_income - scale_threshold]) { in_high_bracket == true; reduces_bracket == true }
    loss_strategy = "Rozłóż odliczenie na 5 lat — niski dochód" { in_high_bracket == false; current_income < scale_threshold * 0.5 }
    loss_strategy = "Odlicz do progu 120k — utrzymaj 12% stawkę" { in_high_bracket == false; current_income >= scale_threshold * 0.5 }

    loss_savings = max_deduction * 0.32 { in_high_bracket == true }
    loss_savings = max_deduction * 0.12 { in_high_bracket == false }

    loss_rt = "TRIAGE_QUEUE" { loss_total > 50000 }
    loss_rt = "" { loss_total <= 50000 }
    loss_rs = sprintf("Strata %.2f PLN — odlicz %.2f PLN/rok przez max 5 lat", [loss_total, max_deduction]) { loss_total > 50000 }
    loss_rs = sprintf("Strata %.2f PLN — standardowe odliczenie", [loss_total]) { loss_total <= 50000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P603: nkup_sport_competition — Wydatki na zawody sportowe → NKUP
# Art. 23 ust. 1 pkt 10 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.sport_competition_nkup",
    "package": "jdg.pit.kup_extended", "priority": 603,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "", "_routing_reason": "Zawody sportowe → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 10 PIT",
    "_warnings": ["Wydatki na organizację/sponsoring zawodów sportowych — NIE stanowią KUP (chyba że CSR sponsoring)"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "SPORT_COMPETITION"
    object.get(input.invoice, "is_csr_sponsoring", false) == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P604: nkup_loan_for_partner — Pożyczki dla wspólników → NKUP
# Art. 23 ust. 1 pkt 9 PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.loan_for_partner_nkup",
    "package": "jdg.pit.kup_extended", "priority": 604,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Pożyczka dla wspólnika → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 9 PIT",
    "_warnings": ["Pożyczki udzielone wspólnikom/podatnikowi — NIE stanowią KUP"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "LOAN_TO_PARTNER"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P605: tax_form_optimizer — Rekomendacja optymalnej formy opodatkowania (Rek. 6.1)
# Simplified rule-based optimizer: porównuje skalę/liniowy/ryczałt
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.tax_form_optimizer",
    "package": "jdg.pit.kup_extended", "priority": 605,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "pit_form_recommended": recommended,
    "pit_form_savings": savings,
    "pit_form_analysis": analysis,
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2022-07-01", "valid_to": null,
    "_routing": opt_rt,
    "_routing_reason": sprintf("Rekomendacja: %s — oszczędność %.2f PLN/rok", [recommended, savings]),
    "_legal_basis": "Art. 27, 30c PIT, ustawa o ryczałcie (optymalizacja formy)",
    "_warnings": [sprintf("TAX FORM OPTIMIZER — %s. %s Oszczędność vs obecna forma: %.2f PLN/rok.", [recommended, analysis, savings])]
} {
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_estimate", 100000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_estimate", 30000)
    annual_profit := annual_income - annual_costs
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    tax_free := object.get(object.get(data.thresholds, "pit", {}), "tax_free_amount", 30000)

    # Skala 12%/32%
    scale_tax := max([(annual_profit - tax_free) * 0.12, 0]) { annual_profit <= scale_threshold }
    scale_tax := max([(scale_threshold - tax_free) * 0.12 + (annual_profit - scale_threshold) * 0.32, 0]) { annual_profit > scale_threshold }
    scale_health := max([annual_profit * 0.09, 0])
    scale_total := scale_tax + scale_health

    # Liniowy 19%
    linear_tax := max([annual_profit * 0.19, 0])
    linear_health := max([annual_profit * 0.049, 0])
    linear_health_deduction := min([linear_health, thresholds.zus.health_linear_deduction_limit])
    linear_total := linear_tax + linear_health - linear_health_deduction * 0.19

    # Ryczałt
    lump_rate := 0.085
    lump_tax := max([annual_income * lump_rate, 0])
    lump_health := max([annual_income * 0.049 * 0.5, 0])
    lump_total := lump_tax + lump_health

    # Determine best (strict comparisons to avoid ties)
    recommended = "SCALE" { scale_total <= linear_total; scale_total <= lump_total }
    recommended = "LINEAR" { linear_total < scale_total; linear_total <= lump_total }
    recommended = "LUMP_SUM" { lump_total < scale_total; lump_total < linear_total }

    current_total := scale_total { current_form == "PIT_SCALE" }
    current_total := linear_total { current_form == "LINEAR" }
    current_total := lump_total { current_form == "LUMP_SUM" }

    best_total := scale_total { recommended == "SCALE" }
    best_total := linear_total { recommended == "LINEAR" }
    best_total := lump_total { recommended == "LUMP_SUM" }

    savings := max([current_total - best_total, 0])
    analysis := sprintf("Skala: %.0f PLN, Liniowy: %.0f PLN, Ryczałt: %.0f PLN", [scale_total, linear_total, lump_total])

    # Gate: only fire when savings are meaningful
    annual_profit > 0
    savings > 500

    opt_rt = "TRIAGE_QUEUE" { recommended != current_form; savings > 3000 }
    else = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P606: advance_tax_predictor — Prognoza zaliczek PIT (Rekomendacja 6.3)
# Rule-based projection: przewiduje przekroczenie progu i zalecenia
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup_extended.advance_tax_predictor",
    "package": "jdg.pit.kup_extended", "priority": 606,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "pit_forecast_annual_income": forecast_income,
    "pit_forecast_annual_tax": forecast_tax,
    "pit_forecast_bracket": forecast_bracket,
    "pit_forecast_monthly_advance": monthly_advance,
    "pit_forecast_underpayment_risk": underpayment_risk,
    "pit_forecast_recommendation": recommendation,
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "valid_from": "2022-07-01", "valid_to": null,
    "_routing": pred_rt,
    "_routing_reason": pred_rs,
    "_legal_basis": "Art. 44 PIT (prognoza zaliczek)",
    "_warnings": [sprintf("ADVANCE TAX PREDICTOR — Prognoza roczna: %.2f PLN dochodu, próg: %s. Zaliczka miesięczna: ~%.2f PLN. %s", [forecast_income, forecast_bracket, monthly_advance, recommendation])]
} {
    ytd_income := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    ytd_income > 0
    months_elapsed := object.get(input.jdg_entrepreneur, "months_elapsed_this_year", 6)
    months_elapsed > 0
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    tax_free := object.get(object.get(data.thresholds, "pit", {}), "tax_free_amount", 30000)

    monthly_avg := ytd_income / months_elapsed
    months_remaining := 12 - months_elapsed
    forecast_income := ytd_income + monthly_avg * months_remaining

    # Predict bracket
    forecast_bracket = "HIGH (32%)" { forecast_income > scale_threshold }
    forecast_bracket = "LOW (12%)" { forecast_income <= scale_threshold }

    # Forecast annual tax
    forecast_tax := (forecast_income - tax_free) * 0.12 { forecast_income <= scale_threshold }
    forecast_tax := (scale_threshold - tax_free) * 0.12 + (forecast_income - scale_threshold) * 0.32 { forecast_income > scale_threshold }

    # Monthly advance estimate
    monthly_advance := floor(forecast_tax / 12 * 100) / 100

    # Underpayment risk assessment
    ytd_advances_paid := object.get(input.jdg_entrepreneur, "advances_paid_ytd", 0)
    expected_advances := forecast_tax * months_elapsed / 12
    underpayment_risk := ytd_advances_paid < expected_advances * 0.9

    recommendation = sprintf("ZWIĘKSZ zaliczki — niedopłata %.2f PLN narasta!", [expected_advances - ytd_advances_paid]) { underpayment_risk == true }
    recommendation = "Zaliczki na odpowiednim poziomie." { underpayment_risk == false }

    pred_rt = "TRIAGE_QUEUE" { underpayment_risk == true }
    pred_rt = "" { underpayment_risk == false }
    pred_rs = sprintf("Ryzyko niedopłaty: %.2f PLN — zwiększ zaliczki", [expected_advances - ytd_advances_paid]) { underpayment_risk == true }
    pred_rs = sprintf("Prognoza: %.2f PLN/rok (%s)", [forecast_income, forecast_bracket]) { underpayment_risk == false }
}


