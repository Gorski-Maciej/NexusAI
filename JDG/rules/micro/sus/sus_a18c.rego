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
# ║  sus.a18c — Mały ZUS Plus (10 reguł)                                    ║
# ║  Legal basis: Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sus.a18c.r1: sus_a18c_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r1",
    "package": "jdg.micro.sus",
    "priority": 90072,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.sus.a18c.r2: sus_a18c_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r2",
    "package": "jdg.micro.sus",
    "priority": 90073,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "sus_condition_met", false) == true
}

# jdg.micro.sus.a18c.r3: sus_a18c_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r3",
    "package": "jdg.micro.sus",
    "priority": 90074,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "sus_a18c_r3_pass", false) == true
}

# jdg.micro.sus.a18c.r4: sus_a18c_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r4",
    "package": "jdg.micro.sus",
    "priority": 90075,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "sus_a18c_r4_checks", false) == true
}

# jdg.micro.sus.a18c.r5: sus_a18c_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r5",
    "package": "jdg.micro.sus",
    "priority": 90076,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "sus_exclusion_applies", false) == false
}

# jdg.micro.sus.a18c.r6: sus_a18c_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r6",
    "package": "jdg.micro.sus",
    "priority": 90077,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "sus_exclusion_2", false) == false
}

# jdg.micro.sus.a18c.r7: sus_a18c_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r7",
    "package": "jdg.micro.sus",
    "priority": 90078,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "sus_a18c_exception", false) == true
}

# jdg.micro.sus.a18c.r8: sus_a18c_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r8",
    "package": "jdg.micro.sus",
    "priority": 90079,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sus_a18c_exception_2", false) == true
}

# jdg.micro.sus.a18c.r9: sus_a18c_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r9",
    "package": "jdg.micro.sus",
    "priority": 90080,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_sus", false) == true
}

# jdg.micro.sus.a18c.r10: sus_a18c_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a18c.r10",
    "package": "jdg.micro.sus",
    "priority": 90081,
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
    "_warnings": ["[MICRO] Mały ZUS Plus: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_sus", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗