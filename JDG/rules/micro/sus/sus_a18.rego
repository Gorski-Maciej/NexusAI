# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa o SUS (ZUS) — 30 artykułów → ~390 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.sus
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.sus

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.sus.no_match",
    "package": "jdg.micro.sus",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sus.a18 — Podstawy wymiaru składek (10 reguł)                                    ║
# ║  Legal basis: Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sus.a18.r1: sus_a18_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r1",
    "package": "jdg.micro.sus",
    "priority": 90052,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.sus.a18.r2: sus_a18_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r2",
    "package": "jdg.micro.sus",
    "priority": 90053,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "sus_condition_met", false) == true
}

# jdg.micro.sus.a18.r3: sus_a18_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r3",
    "package": "jdg.micro.sus",
    "priority": 90054,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "sus_a18_r3_pass", false) == true
}

# jdg.micro.sus.a18.r4: sus_a18_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r4",
    "package": "jdg.micro.sus",
    "priority": 90055,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "sus_a18_r4_checks", false) == true
}

# jdg.micro.sus.a18.r5: sus_a18_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r5",
    "package": "jdg.micro.sus",
    "priority": 90056,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "sus_exclusion_applies", false) == false
}

# jdg.micro.sus.a18.r6: sus_a18_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r6",
    "package": "jdg.micro.sus",
    "priority": 90057,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "sus_exclusion_2", false) == false
}

# jdg.micro.sus.a18.r7: sus_a18_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r7",
    "package": "jdg.micro.sus",
    "priority": 90058,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "sus_a18_exception", false) == true
}

# jdg.micro.sus.a18.r8: sus_a18_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r8",
    "package": "jdg.micro.sus",
    "priority": 90059,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sus_a18_exception_2", false) == true
}

# jdg.micro.sus.a18.r9: sus_a18_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r9",
    "package": "jdg.micro.sus",
    "priority": 90060,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_sus", false) == true
}

# jdg.micro.sus.a18.r10: sus_a18_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18.r10",
    "package": "jdg.micro.sus",
    "priority": 90061,
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
    "_legal_basis": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "_warnings": ["[MICRO] Podstawy wymiaru składek: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_sus", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗