# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Akcyza — 20 artykułów → ~160 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.akcyza
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.akcyza

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.akcyza.no_match",
    "package": "jdg.micro.akcyza",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  akcyza.a2 — Wyroby akcyzowe (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.akcyza.a2.r1: akcyza_a2_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a2.r1",
    "package": "jdg.micro.akcyza",
    "priority": 250002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Wyroby akcyzowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.akcyza.a2.r2: akcyza_a2_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a2.r2",
    "package": "jdg.micro.akcyza",
    "priority": 250003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Wyroby akcyzowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "akcyza_condition_met", false) == true
}

# jdg.micro.akcyza.a2.r3: akcyza_a2_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a2.r3",
    "package": "jdg.micro.akcyza",
    "priority": 250004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Wyroby akcyzowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "akcyza_a2_r3_pass", false) == true
}

# jdg.micro.akcyza.a2.r4: akcyza_a2_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a2.r4",
    "package": "jdg.micro.akcyza",
    "priority": 250005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Wyroby akcyzowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "akcyza_a2_r4_checks", false) == true
}

# jdg.micro.akcyza.a2.r5: akcyza_a2_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a2.r5",
    "package": "jdg.micro.akcyza",
    "priority": 250006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Wyroby akcyzowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "akcyza_exclusion_applies", false) == false
}

# jdg.micro.akcyza.a2.r6: akcyza_a2_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a2.r6",
    "package": "jdg.micro.akcyza",
    "priority": 250007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Wyroby akcyzowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "akcyza_exclusion_2", false) == false
}

# jdg.micro.akcyza.a2.r7: akcyza_a2_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a2.r7",
    "package": "jdg.micro.akcyza",
    "priority": 250008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Wyroby akcyzowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "akcyza_a2_exception", false) == true
}

# jdg.micro.akcyza.a2.r8: akcyza_a2_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a2.r8",
    "package": "jdg.micro.akcyza",
    "priority": 250009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Wyroby akcyzowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "akcyza_a2_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  akcyza.a26 — OBB — obowiązek dokumentowania (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.akcyza.a26.r1: akcyza_a26_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a26.r1",
    "package": "jdg.micro.akcyza",
    "priority": 250010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] OBB — obowiązek dokumentowania: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.akcyza.a26.r2: akcyza_a26_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a26.r2",
    "package": "jdg.micro.akcyza",
    "priority": 250011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] OBB — obowiązek dokumentowania: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "akcyza_condition_met", false) == true
}

# jdg.micro.akcyza.a26.r3: akcyza_a26_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a26.r3",
    "package": "jdg.micro.akcyza",
    "priority": 250012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] OBB — obowiązek dokumentowania: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "akcyza_a26_r3_pass", false) == true
}

# jdg.micro.akcyza.a26.r4: akcyza_a26_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a26.r4",
    "package": "jdg.micro.akcyza",
    "priority": 250013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] OBB — obowiązek dokumentowania: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "akcyza_a26_r4_checks", false) == true
}

# jdg.micro.akcyza.a26.r5: akcyza_a26_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a26.r5",
    "package": "jdg.micro.akcyza",
    "priority": 250014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] OBB — obowiązek dokumentowania: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "akcyza_exclusion_applies", false) == false
}

# jdg.micro.akcyza.a26.r6: akcyza_a26_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a26.r6",
    "package": "jdg.micro.akcyza",
    "priority": 250015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] OBB — obowiązek dokumentowania: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "akcyza_exclusion_2", false) == false
}

# jdg.micro.akcyza.a26.r7: akcyza_a26_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a26.r7",
    "package": "jdg.micro.akcyza",
    "priority": 250016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] OBB — obowiązek dokumentowania: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "akcyza_a26_exception", false) == true
}

# jdg.micro.akcyza.a26.r8: akcyza_a26_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a26.r8",
    "package": "jdg.micro.akcyza",
    "priority": 250017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] OBB — obowiązek dokumentowania: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "akcyza_a26_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  akcyza.a30 — Skład podatkowy (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.akcyza.a30.r1: akcyza_a30_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a30.r1",
    "package": "jdg.micro.akcyza",
    "priority": 250018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Skład podatkowy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.akcyza.a30.r2: akcyza_a30_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a30.r2",
    "package": "jdg.micro.akcyza",
    "priority": 250019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Skład podatkowy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "akcyza_condition_met", false) == true
}

# jdg.micro.akcyza.a30.r3: akcyza_a30_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a30.r3",
    "package": "jdg.micro.akcyza",
    "priority": 250020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Skład podatkowy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "akcyza_a30_r3_pass", false) == true
}

# jdg.micro.akcyza.a30.r4: akcyza_a30_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a30.r4",
    "package": "jdg.micro.akcyza",
    "priority": 250021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Skład podatkowy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "akcyza_a30_r4_checks", false) == true
}

# jdg.micro.akcyza.a30.r5: akcyza_a30_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a30.r5",
    "package": "jdg.micro.akcyza",
    "priority": 250022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Skład podatkowy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "akcyza_exclusion_applies", false) == false
}

# jdg.micro.akcyza.a30.r6: akcyza_a30_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a30.r6",
    "package": "jdg.micro.akcyza",
    "priority": 250023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Skład podatkowy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "akcyza_exclusion_2", false) == false
}

# jdg.micro.akcyza.a30.r7: akcyza_a30_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a30.r7",
    "package": "jdg.micro.akcyza",
    "priority": 250024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Skład podatkowy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "akcyza_a30_exception", false) == true
}

# jdg.micro.akcyza.a30.r8: akcyza_a30_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a30.r8",
    "package": "jdg.micro.akcyza",
    "priority": 250025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Skład podatkowy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "akcyza_a30_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  akcyza.a99 — Obrót wyrobami akcyzowymi (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.akcyza.a99.r1: akcyza_a99_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a99.r1",
    "package": "jdg.micro.akcyza",
    "priority": 250026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Obrót wyrobami akcyzowymi: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.akcyza.a99.r2: akcyza_a99_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a99.r2",
    "package": "jdg.micro.akcyza",
    "priority": 250027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Obrót wyrobami akcyzowymi: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "akcyza_condition_met", false) == true
}

# jdg.micro.akcyza.a99.r3: akcyza_a99_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a99.r3",
    "package": "jdg.micro.akcyza",
    "priority": 250028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Obrót wyrobami akcyzowymi: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "akcyza_a99_r3_pass", false) == true
}

# jdg.micro.akcyza.a99.r4: akcyza_a99_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a99.r4",
    "package": "jdg.micro.akcyza",
    "priority": 250029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Obrót wyrobami akcyzowymi: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "akcyza_a99_r4_checks", false) == true
}

# jdg.micro.akcyza.a99.r5: akcyza_a99_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a99.r5",
    "package": "jdg.micro.akcyza",
    "priority": 250030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Obrót wyrobami akcyzowymi: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "akcyza_exclusion_applies", false) == false
}

# jdg.micro.akcyza.a99.r6: akcyza_a99_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a99.r6",
    "package": "jdg.micro.akcyza",
    "priority": 250031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Obrót wyrobami akcyzowymi: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "akcyza_exclusion_2", false) == false
}

# jdg.micro.akcyza.a99.r7: akcyza_a99_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a99.r7",
    "package": "jdg.micro.akcyza",
    "priority": 250032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Obrót wyrobami akcyzowymi: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "akcyza_a99_exception", false) == true
}

# jdg.micro.akcyza.a99.r8: akcyza_a99_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.akcyza.a99.r8",
    "package": "jdg.micro.akcyza",
    "priority": 250033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008",
    "_warnings": ["[MICRO] Obrót wyrobami akcyzowymi: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "akcyza_a99_exception_2", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (100 reguł)       ║
# ║  Priorytety: 50000-50099                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.pcc_akc.a10.u1.p1 — `pcc_akc_a10_u1_p1`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a10.u1.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50000,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 10 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a10_u1_p1_check", false) == true
}
# jdg.pcc_akc.a10.u2.p2 — `pcc_akc_a10_u2_p2`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a10.u2.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 10 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a10_u2_p2_check", false) == true
}
# jdg.pcc_akc.a11.u1.p2 — `pcc_akc_a11_u1_p2`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a11.u1.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a11_u1_p2_check", false) == true
}
# jdg.pcc_akc.a11.u3.p3 — `pcc_akc_a11_u3_p3`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a11.u3.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a11_u3_p3_check", false) == true
}
# jdg.pcc_akc.a11.u4.p4 — `pcc_akc_a11_u4_p4`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a11.u4.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a11_u4_p4_check", false) == true
}
# jdg.pcc_akc.a11.u5.p1 — `pcc_akc_a11_u5_p1`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a11.u5.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a11_u5_p1_check", false) == true
}
# jdg.pcc_akc.a12.u2.p3 — `pcc_akc_a12_u2_p3`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a12.u2.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a12_u2_p3_check", false) == true
}
# jdg.pcc_akc.a12.u3.p4 — `pcc_akc_a12_u3_p4`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a12.u3.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a12_u3_p4_check", false) == true
}
# jdg.pcc_akc.a12.u4.p1 — `pcc_akc_a12_u4_p1`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a12.u4.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a12_u4_p1_check", false) == true
}
# jdg.pcc_akc.a12.u5.p2 — `pcc_akc_a12_u5_p2`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a12.u5.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a12_u5_p2_check", false) == true
}
# jdg.pcc_akc.a13.u1.p3 — `pcc_akc_a13_u1_p3`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a13.u1.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a13_u1_p3_check", false) == true
}
# jdg.pcc_akc.a13.u2.p4 — `pcc_akc_a13_u2_p4`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a13.u2.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a13_u2_p4_check", false) == true
}
# jdg.pcc_akc.a13.u3.p1 — `pcc_akc_a13_u3_p1`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a13.u3.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a13_u3_p1_check", false) == true
}
# jdg.pcc_akc.a13.u4.p2 — `pcc_akc_a13_u4_p2`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a13.u4.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a13_u4_p2_check", false) == true
}
# jdg.pcc_akc.a14.u1.p4 — `pcc_akc_a14_u1_p4`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a14.u1.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a14_u1_p4_check", false) == true
}
# jdg.pcc_akc.a14.u2.p1 — `pcc_akc_a14_u2_p1`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a14.u2.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a14_u2_p1_check", false) == true
}
# jdg.pcc_akc.a14.u3.p2 — `pcc_akc_a14_u3_p2`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a14.u3.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a14_u3_p2_check", false) == true
}
# jdg.pcc_akc.a14.u5.p3 — `pcc_akc_a14_u5_p3`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a14.u5.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a14_u5_p3_check", false) == true
}
# jdg.pcc_akc.a15.u1.p1 — `pcc_akc_a15_u1_p1`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a15.u1.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a15_u1_p1_check", false) == true
}
# jdg.pcc_akc.a15.u2.p2 — `pcc_akc_a15_u2_p2`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a15.u2.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a15_u2_p2_check", false) == true
}
# jdg.pcc_akc.a15.u4.p3 — `pcc_akc_a15_u4_p3`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a15.u4.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a15_u4_p3_check", false) == true
}
# jdg.pcc_akc.a15.u5.p4 — `pcc_akc_a15_u5_p4`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a15.u5.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a15_u5_p4_check", false) == true
}
# jdg.pcc_akc.a16.u1.p2 — `pcc_akc_a16_u1_p2`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a16.u1.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a16_u1_p2_check", false) == true
}
# jdg.pcc_akc.a16.u3.p3 — `pcc_akc_a16_u3_p3`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a16.u3.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a16_u3_p3_check", false) == true
}
# jdg.pcc_akc.a16.u4.p4 — `pcc_akc_a16_u4_p4`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a16.u4.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a16_u4_p4_check", false) == true
}
# jdg.pcc_akc.a16.u5.p1 — `pcc_akc_a16_u5_p1`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a16.u5.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a16_u5_p1_check", false) == true
}
# jdg.pcc_akc.a17.u2.p3 — `pcc_akc_a17_u2_p3`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a17.u2.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a17_u2_p3_check", false) == true
}
# jdg.pcc_akc.a17.u3.p4 — `pcc_akc_a17_u3_p4`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a17.u3.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a17_u3_p4_check", false) == true
}
# jdg.pcc_akc.a17.u4.p1 — `pcc_akc_a17_u4_p1`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a17.u4.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a17_u4_p1_check", false) == true
}
# jdg.pcc_akc.a17.u5.p2 — `pcc_akc_a17_u5_p2`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a17.u5.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a17_u5_p2_check", false) == true
}
# jdg.pcc_akc.a18.u1.p3 — `pcc_akc_a18_u1_p3`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a18.u1.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a18_u1_p3_check", false) == true
}
# jdg.pcc_akc.a18.u2.p4 — `pcc_akc_a18_u2_p4`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a18.u2.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a18_u2_p4_check", false) == true
}
# jdg.pcc_akc.a18.u3.p1 — `pcc_akc_a18_u3_p1`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a18.u3.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a18_u3_p1_check", false) == true
}
# jdg.pcc_akc.a18.u4.p2 — `pcc_akc_a18_u4_p2`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a18.u4.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a18_u4_p2_check", false) == true
}
# jdg.pcc_akc.a19.u1.p4 — `pcc_akc_a19_u1_p4`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a19.u1.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a19_u1_p4_check", false) == true
}
# jdg.pcc_akc.a19.u2.p1 — `pcc_akc_a19_u2_p1`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a19.u2.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a19_u2_p1_check", false) == true
}
# jdg.pcc_akc.a19.u3.p2 — `pcc_akc_a19_u3_p2`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a19.u3.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a19_u3_p2_check", false) == true
}
# jdg.pcc_akc.a19.u5.p3 — `pcc_akc_a19_u5_p3`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a19.u5.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a19_u5_p3_check", false) == true
}
# jdg.pcc_akc.a20.u1.p1 — `pcc_akc_a20_u1_p1`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a20.u1.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a20_u1_p1_check", false) == true
}
# jdg.pcc_akc.a20.u2.p2 — `pcc_akc_a20_u2_p2`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a20.u2.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a20_u2_p2_check", false) == true
}
# jdg.pcc_akc.a20.u4.p3 — `pcc_akc_a20_u4_p3`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a20.u4.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a20_u4_p3_check", false) == true
}
# jdg.pcc_akc.a20.u5.p4 — `pcc_akc_a20_u5_p4`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a20.u5.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a20_u5_p4_check", false) == true
}
# jdg.pcc_akc.a21.u1.p2 — `pcc_akc_a21_u1_p2`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a21.u1.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a21_u1_p2_check", false) == true
}
# jdg.pcc_akc.a21.u3.p3 — `pcc_akc_a21_u3_p3`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a21.u3.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a21_u3_p3_check", false) == true
}
# jdg.pcc_akc.a21.u4.p4 — `pcc_akc_a21_u4_p4`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a21.u4.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a21_u4_p4_check", false) == true
}
# jdg.pcc_akc.a21.u5.p1 — `pcc_akc_a21_u5_p1`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a21.u5.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a21_u5_p1_check", false) == true
}
# jdg.pcc_akc.a22.u2.p3 — `pcc_akc_a22_u2_p3`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a22.u2.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a22_u2_p3_check", false) == true
}
# jdg.pcc_akc.a22.u3.p4 — `pcc_akc_a22_u3_p4`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a22.u3.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a22_u3_p4_check", false) == true
}
# jdg.pcc_akc.a22.u4.p1 — `pcc_akc_a22_u4_p1`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a22.u4.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a22_u4_p1_check", false) == true
}
# jdg.pcc_akc.a22.u5.p2 — `pcc_akc_a22_u5_p2`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a22.u5.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a22_u5_p2_check", false) == true
}
# jdg.pcc_akc.a23.u1.p3 — `pcc_akc_a23_u1_p3`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a23.u1.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a23_u1_p3_check", false) == true
}
# jdg.pcc_akc.a23.u2.p4 — `pcc_akc_a23_u2_p4`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a23.u2.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a23_u2_p4_check", false) == true
}
# jdg.pcc_akc.a23.u3.p1 — `pcc_akc_a23_u3_p1`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a23.u3.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a23_u3_p1_check", false) == true
}
# jdg.pcc_akc.a23.u4.p2 — `pcc_akc_a23_u4_p2`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a23.u4.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a23_u4_p2_check", false) == true
}
# jdg.pcc_akc.a24.u1.p4 — `pcc_akc_a24_u1_p4`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a24.u1.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a24_u1_p4_check", false) == true
}
# jdg.pcc_akc.a24.u2.p1 — `pcc_akc_a24_u2_p1`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a24.u2.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a24_u2_p1_check", false) == true
}
# jdg.pcc_akc.a24.u3.p2 — `pcc_akc_a24_u3_p2`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a24.u3.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a24_u3_p2_check", false) == true
}
# jdg.pcc_akc.a24.u5.p3 — `pcc_akc_a24_u5_p3`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a24.u5.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a24_u5_p3_check", false) == true
}
# jdg.pcc_akc.a25.u1.p1 — `pcc_akc_a25_u1_p1`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a25.u1.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a25_u1_p1_check", false) == true
}
# jdg.pcc_akc.a25.u2.p2 — `pcc_akc_a25_u2_p2`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a25.u2.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a25_u2_p2_check", false) == true
}
# jdg.pcc_akc.a25.u4.p3 — `pcc_akc_a25_u4_p3`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a25.u4.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a25_u4_p3_check", false) == true
}
# jdg.pcc_akc.a25.u5.p4 — `pcc_akc_a25_u5_p4`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a25.u5.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a25_u5_p4_check", false) == true
}
# jdg.pcc_akc.a26.u1.p2 — `pcc_akc_a26_u1_p2`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a26.u1.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a26_u1_p2_check", false) == true
}
# jdg.pcc_akc.a26.u3.p3 — `pcc_akc_a26_u3_p3`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a26.u3.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a26_u3_p3_check", false) == true
}
# jdg.pcc_akc.a26.u4.p4 — `pcc_akc_a26_u4_p4`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a26.u4.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a26_u4_p4_check", false) == true
}
# jdg.pcc_akc.a26.u5.p1 — `pcc_akc_a26_u5_p1`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a26.u5.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a26_u5_p1_check", false) == true
}
# jdg.pcc_akc.a27.u2.p3 — `pcc_akc_a27_u2_p3`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a27.u2.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a27_u2_p3_check", false) == true
}
# jdg.pcc_akc.a27.u3.p4 — `pcc_akc_a27_u3_p4`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a27.u3.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a27_u3_p4_check", false) == true
}
# jdg.pcc_akc.a27.u4.p1 — `pcc_akc_a27_u4_p1`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a27.u4.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a27_u4_p1_check", false) == true
}
# jdg.pcc_akc.a27.u5.p2 — `pcc_akc_a27_u5_p2`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a27.u5.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a27_u5_p2_check", false) == true
}
# jdg.pcc_akc.a28.u1.p3 — `pcc_akc_a28_u1_p3`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a28.u1.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a28_u1_p3_check", false) == true
}
# jdg.pcc_akc.a28.u2.p4 — `pcc_akc_a28_u2_p4`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a28.u2.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a28_u2_p4_check", false) == true
}
# jdg.pcc_akc.a28.u3.p1 — `pcc_akc_a28_u3_p1`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a28.u3.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a28_u3_p1_check", false) == true
}
# jdg.pcc_akc.a28.u4.p2 — `pcc_akc_a28_u4_p2`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a28.u4.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a28_u4_p2_check", false) == true
}
# jdg.pcc_akc.a29.u1.p4 — `pcc_akc_a29_u1_p4`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a29.u1.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a29_u1_p4_check", false) == true
}
# jdg.pcc_akc.a29.u2.p1 — `pcc_akc_a29_u2_p1`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a29.u2.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a29_u2_p1_check", false) == true
}
# jdg.pcc_akc.a29.u3.p2 — `pcc_akc_a29_u3_p2`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a29.u3.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a29_u3_p2_check", false) == true
}
# jdg.pcc_akc.a29.u5.p3 — `pcc_akc_a29_u5_p3`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a29.u5.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a29_u5_p3_check", false) == true
}
# jdg.pcc_akc.a30.u1.p1 — `pcc_akc_a30_u1_p1`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a30.u1.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a30_u1_p1_check", false) == true
}
# jdg.pcc_akc.a30.u2.p2 — `pcc_akc_a30_u2_p2`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a30.u2.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a30_u2_p2_check", false) == true
}
# jdg.pcc_akc.a30.u4.p3 — `pcc_akc_a30_u4_p3`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a30.u4.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a30_u4_p3_check", false) == true
}
# jdg.pcc_akc.a30.u5.p4 — `pcc_akc_a30_u5_p4`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a30.u5.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a30_u5_p4_check", false) == true
}
# jdg.pcc_akc.a31.u1.p2 — `pcc_akc_a31_u1_p2`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a31.u1.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a31_u1_p2_check", false) == true
}
# jdg.pcc_akc.a31.u3.p3 — `pcc_akc_a31_u3_p3`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a31.u3.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a31_u3_p3_check", false) == true
}
# jdg.pcc_akc.a31.u4.p4 — `pcc_akc_a31_u4_p4`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a31.u4.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a31_u4_p4_check", false) == true
}
# jdg.pcc_akc.a31.u5.p1 — `pcc_akc_a31_u5_p1`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a31.u5.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a31_u5_p1_check", false) == true
}
# jdg.pcc_akc.a32.u2.p3 — `pcc_akc_a32_u2_p3`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a32.u2.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a32_u2_p3_check", false) == true
}
# jdg.pcc_akc.a32.u3.p4 — `pcc_akc_a32_u3_p4`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a32.u3.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a32_u3_p4_check", false) == true
}
# jdg.pcc_akc.a32.u4.p1 — `pcc_akc_a32_u4_p1`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a32.u4.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a32_u4_p1_check", false) == true
}
# jdg.pcc_akc.a32.u5.p2 — `pcc_akc_a32_u5_p2`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a32.u5.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a32_u5_p2_check", false) == true
}
# jdg.pcc_akc.a33.u1.p3 — `pcc_akc_a33_u1_p3`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a33.u1.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a33_u1_p3_check", false) == true
}
# jdg.pcc_akc.a33.u2.p4 — `pcc_akc_a33_u2_p4`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a33.u2.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a33_u2_p4_check", false) == true
}
# jdg.pcc_akc.a33.u3.p1 — `pcc_akc_a33_u3_p1`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a33.u3.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a33_u3_p1_check", false) == true
}
# jdg.pcc_akc.a33.u4.p2 — `pcc_akc_a33_u4_p2`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a33.u4.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a33_u4_p2_check", false) == true
}
# jdg.pcc_akc.a34.u1.p4 — `pcc_akc_a34_u1_p4`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a34.u1.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a34_u1_p4_check", false) == true
}
# jdg.pcc_akc.a34.u2.p1 — `pcc_akc_a34_u2_p1`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a34.u2.p1",
    "package": "jdg.micro.akcyza",
    "priority": 50095,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a34_u2_p1_check", false) == true
}
# jdg.pcc_akc.a34.u3.p2 — `pcc_akc_a34_u3_p2`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a34.u3.p2",
    "package": "jdg.micro.akcyza",
    "priority": 50096,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a34_u3_p2_check", false) == true
}
# jdg.pcc_akc.a34.u5.p3 — `pcc_akc_a34_u5_p3`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a34.u5.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50097,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a34_u5_p3_check", false) == true
}
# jdg.pcc_akc.a35.u4.p3 — `pcc_akc_a35_u4_p3`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a35.u4.p3",
    "package": "jdg.micro.akcyza",
    "priority": 50098,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a35_u4_p3_check", false) == true
}
# jdg.pcc_akc.a35.u5.p4 — `pcc_akc_a35_u5_p4`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pcc_akc.a35.u5.p4",
    "package": "jdg.micro.akcyza",
    "priority": 50099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 6.12.2008 (Dz.U. 2009 nr 3 poz. 11)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pcc_akc_a35_u5_p4_check", false) == true
}