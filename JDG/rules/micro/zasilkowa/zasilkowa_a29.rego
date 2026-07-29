# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa zasiłkowa — 10 artykułów → ~100 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.zasilkowa
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.zasilkowa

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.zasilkowa.no_match",
    "package": "jdg.micro.zasilkowa",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  zasilkowa.a29 — Zasiłek macierzyński (10 reguł)                                    ║
# ║  Legal basis: Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zasilkowa.a29.r1: zasilkowa_a29_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r1",
    "package": "jdg.micro.zasilkowa",
    "priority": 120029,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zasilkowa.a29.r2: zasilkowa_a29_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r2",
    "package": "jdg.micro.zasilkowa",
    "priority": 120030,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_condition_met", false) == true
}

# jdg.micro.zasilkowa.a29.r3: zasilkowa_a29_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r3",
    "package": "jdg.micro.zasilkowa",
    "priority": 120031,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a29_r3_pass", false) == true
}

# jdg.micro.zasilkowa.a29.r4: zasilkowa_a29_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r4",
    "package": "jdg.micro.zasilkowa",
    "priority": 120032,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a29_r4_checks", false) == true
}

# jdg.micro.zasilkowa.a29.r5: zasilkowa_a29_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r5",
    "package": "jdg.micro.zasilkowa",
    "priority": 120033,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_applies", false) == false
}

# jdg.micro.zasilkowa.a29.r6: zasilkowa_a29_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r6",
    "package": "jdg.micro.zasilkowa",
    "priority": 120034,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_2", false) == false
}

# jdg.micro.zasilkowa.a29.r7: zasilkowa_a29_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r7",
    "package": "jdg.micro.zasilkowa",
    "priority": 120035,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zasilkowa_a29_exception", false) == true
}

# jdg.micro.zasilkowa.a29.r8: zasilkowa_a29_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r8",
    "package": "jdg.micro.zasilkowa",
    "priority": 120036,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zasilkowa_a29_exception_2", false) == true
}

# jdg.micro.zasilkowa.a29.r9: zasilkowa_a29_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r9",
    "package": "jdg.micro.zasilkowa",
    "priority": 120037,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_zasilkowa", false) == true
}

# jdg.micro.zasilkowa.a29.r10: zasilkowa_a29_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r10",
    "package": "jdg.micro.zasilkowa",
    "priority": 120038,
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
    "_legal_basis": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "_warnings": ["[MICRO] Zasiłek macierzyński: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_zasilkowa", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗