# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: BDO — Rejestracja (P1900-P1903 → 10 reguł)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.bdo_rejestracja
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.bdo_rejestracja

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.bdo_rejestracja.no_match",
    "package": "jdg.micro.bdo_rejestracja",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  BDO Registration — Rejestracja w Bazie Danych Odpadowych (10 reguł)     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.bdo_rejestracja.r1: waste_producer_check — czy JDG wytwarza odpady?
decide := {
    "matched": true, "rule_id": "jdg.micro.bdo_rejestracja.r1",
    "package": "jdg.micro.bdo_rejestracja", "priority": 82001,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 49 ust. 1 Ustawy o odpadach",
    "_warnings": ["[MICRO] BDO: sprawdzenie czy JDG wytwarza odpady — przesłanka do rejestracji w BDO"]
} { input.business.produces_waste == true }

# jdg.micro.bdo_rejestracja.r2: bdo_not_registered_micro — mikroprzedsiębiorca bez BDO
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_rejestracja.r2",
    "package": "jdg.micro.bdo_rejestracja", "priority": 82002,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak rejestracji BDO — mikroprzedsiębiorca. Opłata 100 PLN.",
    "_legal_basis": "Art. 49-54 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO: mikroprzedsiębiorca NIEZAREJESTROWANY w BDO. Opłata rejestracyjna: %d PLN. Termin: przed rozpoczęciem działalności. Kara: do 5000 PLN.", [bdo_fee])]
} {
    input.business.produces_waste == true
    input.business.bdo_registered == false
    object.get(input.jdg_entrepreneur, "is_micro_entrepreneur", false) == true
    bdo_fee := object.get(object.get(data.thresholds, "jdg", {}), "bdo_fee_micro_pln", 100)
}

# jdg.micro.bdo_rejestracja.r3: bdo_not_registered_small — mały przedsiębiorca bez BDO
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_rejestracja.r3",
    "package": "jdg.micro.bdo_rejestracja", "priority": 82003,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Brak rejestracji BDO — mały przedsiębiorca (%d prac.). Opłata %d PLN.", [emp, fee]),
    "_legal_basis": "Art. 49-54 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO: mały przedsiębiorca (%d prac.) NIEZAREJESTROWANY. Opłata: %d PLN. Kara do 10 000 PLN. Zarejestruj przed rozpoczęciem wytwarzania odpadów!", [emp, fee])]
} {
    input.business.produces_waste == true
    input.business.bdo_registered == false
    emp := object.get(input.employment, "employee_count", 0)
    rev_eur := object.get(input.jdg_entrepreneur, "annual_revenue_eur_m", 0)
    emp < 50
    rev_eur < 10
    fee := object.get(object.get(data.thresholds, "jdg", {}), "bdo_fee_small_pln", 300)
}

# jdg.micro.bdo_rejestracja.r4: bdo_registered_ok — BDO zarejestrowane prawidłowo
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_rejestracja.r4",
    "package": "jdg.micro.bdo_rejestracja", "priority": 82004,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 50 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO: JDG zarejestrowane w BDO (nr: %s). Pamiętaj o aktualizacji danych w ciągu 30 dni od zmiany.", [bdo_number])]
} {
    input.business.bdo_registered == true
    bdo_number := object.get(input.business, "bdo_registration_number", "XXXXX")
}

# jdg.micro.bdo_rejestracja.r5: bdo_update_required — zmiana danych wymaga aktualizacji
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_rejestracja.r5",
    "package": "jdg.micro.bdo_rejestracja", "priority": 82005,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("BDO — aktualizacja: %s. Termin: 30 dni.", [change_type]),
    "_legal_basis": "Art. 53 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO: AKTUALIZACJA — zmiana: %s. Masz 30 dni od zmiany na aktualizację w systemie BDO. Opłata za zmianę: 50 PLN. Przekroczenie terminu = kara administracyjna.", [change_type])]
} {
    input.business.bdo_registered == true
    object.get(input.business, "bdo_data_changed", false) == true
    change_type := object.get(input.business, "bdo_change_type", "dane adresowe")
}

# jdg.micro.bdo_rejestracja.r6: bdo_deregistration — zaprzestanie wytwarzania odpadów
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_rejestracja.r6",
    "package": "jdg.micro.bdo_rejestracja", "priority": 82006,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "BDO — wyrejestruj po zaprzestaniu wytwarzania odpadów. Termin: 30 dni.",
    "_legal_basis": "Art. 55 Ustawy o odpadach",
    "_warnings": ["[MICRO] BDO: WYREJESTROWANIE — zaprzestano wytwarzania odpadów, ale BDO wciąż aktywne. Złóż wniosek o wykreślenie w ciągu 30 dni. Zachowaj potwierdzenie na 5 lat!"]
} {
    input.business.produces_waste == false
    input.business.bdo_registered == true
    object.get(input.business, "bdo_deregistration_filed", false) == false
}

# jdg.micro.bdo_rejestracja.r7: bdo_fee_payment_reminder — przypomnienie o opłacie rocznej
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_rejestracja.r7",
    "package": "jdg.micro.bdo_rejestracja", "priority": 82007,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 55a Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO: Opłata roczna za wpis w BDO — %d PLN. Termin: do końca lutego %d. Numer konta w komunikacie MF.", [annual_fee, year])]
} {
    input.business.bdo_registered == true
    input.calendar.month == 2
    year := object.get(input.calendar, "year", 2026)
    is_micro := object.get(input.jdg_entrepreneur, "is_micro_entrepreneur", false)
    annual_fee = 100 { is_micro == true }
    annual_fee = 300 { is_micro == false }
}

# jdg.micro.bdo_rejestracja.r8: bdo_registration_sanction — sankcja za brak rejestracji
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_rejestracja.r8",
    "package": "jdg.micro.bdo_rejestracja", "priority": 82008,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "ADMINISTRACYJNA", "sanction_severity": "MEDIUM",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Sankcja BDO: brak rejestracji — %d PLN. Art. 194 UoO.", [penalty]),
    "_legal_basis": "Art. 194 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO: SANKCJA — brak rejestracji w BDO mimo obowiązku. Kara: %d PLN. Zarejestruj się natychmiast aby uniknąć dalszych kar!", [penalty])]
} {
    input.business.produces_waste == true
    input.business.bdo_registered == false
    object.get(input.business, "bdo_sanction_issued", false) == true
    penalty := object.get(input.business, "bdo_penalty_amount_pln", 5000)
}

