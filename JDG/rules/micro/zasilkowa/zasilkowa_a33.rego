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
# ║  zasilkowa.a33 — Zasiłek rehabilitacyjny (8 reguł)                                    ║
# ║  Legal basis: Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zasilkowa.a33.r1: zasilkowa_a33_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r1",
    "package": "jdg.micro.zasilkowa",
    "priority": 120049,
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
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zasilkowa.a33.r2: zasilkowa_a33_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r2",
    "package": "jdg.micro.zasilkowa",
    "priority": 120050,
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
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_condition_met", false) == true
}

# jdg.micro.zasilkowa.a33.r3: zasilkowa_a33_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r3",
    "package": "jdg.micro.zasilkowa",
    "priority": 120051,
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
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a33_r3_pass", false) == true
}

# jdg.micro.zasilkowa.a33.r4: zasilkowa_a33_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r4",
    "package": "jdg.micro.zasilkowa",
    "priority": 120052,
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
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a33_r4_checks", false) == true
}

# jdg.micro.zasilkowa.a33.r5: zasilkowa_a33_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r5",
    "package": "jdg.micro.zasilkowa",
    "priority": 120053,
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
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_applies", false) == false
}

# jdg.micro.zasilkowa.a33.r6: zasilkowa_a33_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r6",
    "package": "jdg.micro.zasilkowa",
    "priority": 120054,
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
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_2", false) == false
}

# jdg.micro.zasilkowa.a33.r7: zasilkowa_a33_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r7",
    "package": "jdg.micro.zasilkowa",
    "priority": 120055,
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
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zasilkowa_a33_exception", false) == true
}

# jdg.micro.zasilkowa.a33.r8: zasilkowa_a33_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r8",
    "package": "jdg.micro.zasilkowa",
    "priority": 120056,
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
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zasilkowa_a33_exception_2", false) == true
}
