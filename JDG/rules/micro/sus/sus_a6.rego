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
# ║  sus.a6 — Podmioty podlegające ubezpieczeniom (8 reguł)                                    ║
# ║  Legal basis: Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sus.a6.r1: sus_a6_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a6.r1",
    "package": "jdg.micro.sus",
    "priority": 90006,
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
    "_warnings": ["[MICRO] Podmioty podlegające ubezpieczeniom: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.sus.a6.r2: sus_a6_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a6.r2",
    "package": "jdg.micro.sus",
    "priority": 90007,
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
    "_warnings": ["[MICRO] Podmioty podlegające ubezpieczeniom: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "sus_condition_met", false) == true
}

# jdg.micro.sus.a6.r3: sus_a6_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a6.r3",
    "package": "jdg.micro.sus",
    "priority": 90008,
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
    "_warnings": ["[MICRO] Podmioty podlegające ubezpieczeniom: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "sus_a6_r3_pass", false) == true
}

# jdg.micro.sus.a6.r4: sus_a6_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a6.r4",
    "package": "jdg.micro.sus",
    "priority": 90009,
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
    "_warnings": ["[MICRO] Podmioty podlegające ubezpieczeniom: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "sus_a6_r4_checks", false) == true
}

# jdg.micro.sus.a6.r5: sus_a6_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a6.r5",
    "package": "jdg.micro.sus",
    "priority": 90010,
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
    "_warnings": ["[MICRO] Podmioty podlegające ubezpieczeniom: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "sus_exclusion_applies", false) == false
}

# jdg.micro.sus.a6.r6: sus_a6_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a6.r6",
    "package": "jdg.micro.sus",
    "priority": 90011,
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
    "_warnings": ["[MICRO] Podmioty podlegające ubezpieczeniom: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "sus_exclusion_2", false) == false
}

# jdg.micro.sus.a6.r7: sus_a6_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a6.r7",
    "package": "jdg.micro.sus",
    "priority": 90012,
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
    "_warnings": ["[MICRO] Podmioty podlegające ubezpieczeniom: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "sus_a6_exception", false) == true
}

# jdg.micro.sus.a6.r8: sus_a6_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a6.r8",
    "package": "jdg.micro.sus",
    "priority": 90013,
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
    "_warnings": ["[MICRO] Podmioty podlegające ubezpieczeniom: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sus_a6_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗