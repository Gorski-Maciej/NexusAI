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
# ║  Legal basis: Ustawa o podatku akcyzowym z 06.12.2008                                                   ║
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
    "_warnings": ["[MICRO] Wyroby akcyzowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "akcyza_a2_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  akcyza.a26 — OBB — obowiązek dokumentowania (8 reguł)                                    ║
# ║  Legal basis: Ustawa o podatku akcyzowym z 06.12.2008                                                   ║
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
    "_warnings": ["[MICRO] OBB — obowiązek dokumentowania: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "akcyza_a26_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  akcyza.a30 — Skład podatkowy (8 reguł)                                    ║
# ║  Legal basis: Ustawa o podatku akcyzowym z 06.12.2008                                                   ║
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
    "_warnings": ["[MICRO] Skład podatkowy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "akcyza_a30_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  akcyza.a99 — Obrót wyrobami akcyzowymi (8 reguł)                                    ║
# ║  Legal basis: Ustawa o podatku akcyzowym z 06.12.2008                                                   ║
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
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
    "_legal_basis": "Ustawa o podatku akcyzowym z 06.12.2008",
    "_warnings": ["[MICRO] Obrót wyrobami akcyzowymi: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "akcyza_a99_exception_2", false) == true
}
