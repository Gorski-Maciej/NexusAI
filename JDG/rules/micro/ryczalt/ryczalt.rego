# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa o ryczałcie — 25 artykułów → ~325 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.ryczalt
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.ryczalt

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.ryczalt.no_match",
    "package": "jdg.micro.ryczalt",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a4 — Definicja ryczałtu (12 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a4.r1: ryczalt_a4_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100004,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ryczalt.a4.r2: ryczalt_a4_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100005,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ryczalt_condition_met", false) == true
}

# jdg.micro.ryczalt.a4.r3: ryczalt_a4_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100006,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a4_r3_pass", false) == true
}

# jdg.micro.ryczalt.a4.r4: ryczalt_a4_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r4",
    "package": "jdg.micro.ryczalt",
    "priority": 100007,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a4_r4_checks", false) == true
}

# jdg.micro.ryczalt.a4.r5: ryczalt_a4_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r5",
    "package": "jdg.micro.ryczalt",
    "priority": 100008,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ryczalt_exclusion_applies", false) == false
}

# jdg.micro.ryczalt.a4.r6: ryczalt_a4_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r6",
    "package": "jdg.micro.ryczalt",
    "priority": 100009,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ryczalt_exclusion_2", false) == false
}

# jdg.micro.ryczalt.a4.r7: ryczalt_a4_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r7",
    "package": "jdg.micro.ryczalt",
    "priority": 100010,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ryczalt_a4_exception", false) == true
}

# jdg.micro.ryczalt.a4.r8: ryczalt_a4_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r8",
    "package": "jdg.micro.ryczalt",
    "priority": 100011,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ryczalt_a4_exception_2", false) == true
}

# jdg.micro.ryczalt.a4.r9: ryczalt_a4_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r9",
    "package": "jdg.micro.ryczalt",
    "priority": 100012,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ryczalt", false) == true
}

# jdg.micro.ryczalt.a4.r10: ryczalt_a4_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r10",
    "package": "jdg.micro.ryczalt",
    "priority": 100013,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ryczalt", false) == true
}

# jdg.micro.ryczalt.a4.r11: ryczalt_a4_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r11",
    "package": "jdg.micro.ryczalt",
    "priority": 100014,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ryczalt_deadline_required", false) == true
}

# jdg.micro.ryczalt.a4.r12: ryczalt_a4_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a4.r12",
    "package": "jdg.micro.ryczalt",
    "priority": 100015,
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
    "sanction_type": "KKS",
    "sanction_severity": "MEDIUM",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Definicja ryczałtu",
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Definicja ryczałtu: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a4_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a6 — Limit przychodu 2 mln EUR (10 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a6.r1: ryczalt_a6_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100016,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ryczalt.a6.r2: ryczalt_a6_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100017,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ryczalt_condition_met", false) == true
}

# jdg.micro.ryczalt.a6.r3: ryczalt_a6_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100018,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a6_r3_pass", false) == true
}

# jdg.micro.ryczalt.a6.r4: ryczalt_a6_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r4",
    "package": "jdg.micro.ryczalt",
    "priority": 100019,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a6_r4_checks", false) == true
}

# jdg.micro.ryczalt.a6.r5: ryczalt_a6_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r5",
    "package": "jdg.micro.ryczalt",
    "priority": 100020,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ryczalt_exclusion_applies", false) == false
}

# jdg.micro.ryczalt.a6.r6: ryczalt_a6_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r6",
    "package": "jdg.micro.ryczalt",
    "priority": 100021,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ryczalt_exclusion_2", false) == false
}

# jdg.micro.ryczalt.a6.r7: ryczalt_a6_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r7",
    "package": "jdg.micro.ryczalt",
    "priority": 100022,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ryczalt_a6_exception", false) == true
}

# jdg.micro.ryczalt.a6.r8: ryczalt_a6_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r8",
    "package": "jdg.micro.ryczalt",
    "priority": 100023,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ryczalt_a6_exception_2", false) == true
}

# jdg.micro.ryczalt.a6.r9: ryczalt_a6_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r9",
    "package": "jdg.micro.ryczalt",
    "priority": 100024,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ryczalt", false) == true
}

# jdg.micro.ryczalt.a6.r10: ryczalt_a6_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6.r10",
    "package": "jdg.micro.ryczalt",
    "priority": 100025,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ryczalt", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a8 — Wyłączenia z ryczałtu (15 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a8.r1: ryczalt_a8_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100026,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ryczalt.a8.r2: ryczalt_a8_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100027,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ryczalt_condition_met", false) == true
}

# jdg.micro.ryczalt.a8.r3: ryczalt_a8_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100028,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a8_r3_pass", false) == true
}

# jdg.micro.ryczalt.a8.r4: ryczalt_a8_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r4",
    "package": "jdg.micro.ryczalt",
    "priority": 100029,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a8_r4_checks", false) == true
}

# jdg.micro.ryczalt.a8.r5: ryczalt_a8_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r5",
    "package": "jdg.micro.ryczalt",
    "priority": 100030,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ryczalt_exclusion_applies", false) == false
}

# jdg.micro.ryczalt.a8.r6: ryczalt_a8_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r6",
    "package": "jdg.micro.ryczalt",
    "priority": 100031,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ryczalt_exclusion_2", false) == false
}

# jdg.micro.ryczalt.a8.r7: ryczalt_a8_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r7",
    "package": "jdg.micro.ryczalt",
    "priority": 100032,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ryczalt_a8_exception", false) == true
}

# jdg.micro.ryczalt.a8.r8: ryczalt_a8_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r8",
    "package": "jdg.micro.ryczalt",
    "priority": 100033,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ryczalt_a8_exception_2", false) == true
}

# jdg.micro.ryczalt.a8.r9: ryczalt_a8_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r9",
    "package": "jdg.micro.ryczalt",
    "priority": 100034,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ryczalt", false) == true
}

# jdg.micro.ryczalt.a8.r10: ryczalt_a8_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r10",
    "package": "jdg.micro.ryczalt",
    "priority": 100035,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ryczalt", false) == true
}

# jdg.micro.ryczalt.a8.r11: ryczalt_a8_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r11",
    "package": "jdg.micro.ryczalt",
    "priority": 100036,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ryczalt_deadline_required", false) == true
}

# jdg.micro.ryczalt.a8.r12: ryczalt_a8_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r12",
    "package": "jdg.micro.ryczalt",
    "priority": 100037,
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
    "sanction_type": "KKS",
    "sanction_severity": "MEDIUM",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Wyłączenia z ryczałtu",
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a8_violation", false) == true
}

# jdg.micro.ryczalt.a8.r13: ryczalt_a8_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r13",
    "package": "jdg.micro.ryczalt",
    "priority": 100038,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "ryczalt_a8_edge_case", false) == true
}

# jdg.micro.ryczalt.a8.r14: ryczalt_a8_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r14",
    "package": "jdg.micro.ryczalt",
    "priority": 100039,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "ryczalt_a8_edge_case_2", false) == true
}

# jdg.micro.ryczalt.a8.r15: ryczalt_a8_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a8.r15",
    "package": "jdg.micro.ryczalt",
    "priority": 100040,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "ryczalt_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a12 — Stawki per PKWiU (18 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a12.r1: ryczalt_a12_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100041,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ryczalt.a12.r2: ryczalt_a12_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100042,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ryczalt_condition_met", false) == true
}

# jdg.micro.ryczalt.a12.r3: ryczalt_a12_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100043,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a12_r3_pass", false) == true
}

# jdg.micro.ryczalt.a12.r4: ryczalt_a12_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r4",
    "package": "jdg.micro.ryczalt",
    "priority": 100044,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a12_r4_checks", false) == true
}

# jdg.micro.ryczalt.a12.r5: ryczalt_a12_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r5",
    "package": "jdg.micro.ryczalt",
    "priority": 100045,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ryczalt_exclusion_applies", false) == false
}

# jdg.micro.ryczalt.a12.r6: ryczalt_a12_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r6",
    "package": "jdg.micro.ryczalt",
    "priority": 100046,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ryczalt_exclusion_2", false) == false
}

# jdg.micro.ryczalt.a12.r7: ryczalt_a12_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r7",
    "package": "jdg.micro.ryczalt",
    "priority": 100047,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ryczalt_a12_exception", false) == true
}

# jdg.micro.ryczalt.a12.r8: ryczalt_a12_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r8",
    "package": "jdg.micro.ryczalt",
    "priority": 100048,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ryczalt_a12_exception_2", false) == true
}

# jdg.micro.ryczalt.a12.r9: ryczalt_a12_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r9",
    "package": "jdg.micro.ryczalt",
    "priority": 100049,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ryczalt", false) == true
}

# jdg.micro.ryczalt.a12.r10: ryczalt_a12_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r10",
    "package": "jdg.micro.ryczalt",
    "priority": 100050,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ryczalt", false) == true
}

# jdg.micro.ryczalt.a12.r11: ryczalt_a12_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r11",
    "package": "jdg.micro.ryczalt",
    "priority": 100051,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ryczalt_deadline_required", false) == true
}

# jdg.micro.ryczalt.a12.r12: ryczalt_a12_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r12",
    "package": "jdg.micro.ryczalt",
    "priority": 100052,
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
    "sanction_type": "KKS",
    "sanction_severity": "MEDIUM",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Stawki per PKWiU",
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a12_violation", false) == true
}

# jdg.micro.ryczalt.a12.r13: ryczalt_a12_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r13",
    "package": "jdg.micro.ryczalt",
    "priority": 100053,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "ryczalt_a12_edge_case", false) == true
}

# jdg.micro.ryczalt.a12.r14: ryczalt_a12_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r14",
    "package": "jdg.micro.ryczalt",
    "priority": 100054,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "ryczalt_a12_edge_case_2", false) == true
}

# jdg.micro.ryczalt.a12.r15: ryczalt_a12_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r15",
    "package": "jdg.micro.ryczalt",
    "priority": 100055,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "ryczalt_validation_required", false) == true
}

# jdg.micro.ryczalt.a12.r16: ryczalt_a12_r16_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r16",
    "package": "jdg.micro.ryczalt",
    "priority": 100056,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ryczalt.a12.r17: ryczalt_a12_r17_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r17",
    "package": "jdg.micro.ryczalt",
    "priority": 100057,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ryczalt_condition_met", false) == true
}

# jdg.micro.ryczalt.a12.r18: ryczalt_a12_r18_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a12.r18",
    "package": "jdg.micro.ryczalt",
    "priority": 100058,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Stawki per PKWiU: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a12_r18_pass", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a15 — Ewidencja ryczałtowa (10 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a15.r1: ryczalt_a15_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100059,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ryczalt.a15.r2: ryczalt_a15_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100060,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ryczalt_condition_met", false) == true
}

# jdg.micro.ryczalt.a15.r3: ryczalt_a15_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100061,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a15_r3_pass", false) == true
}

# jdg.micro.ryczalt.a15.r4: ryczalt_a15_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r4",
    "package": "jdg.micro.ryczalt",
    "priority": 100062,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a15_r4_checks", false) == true
}

# jdg.micro.ryczalt.a15.r5: ryczalt_a15_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r5",
    "package": "jdg.micro.ryczalt",
    "priority": 100063,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ryczalt_exclusion_applies", false) == false
}

# jdg.micro.ryczalt.a15.r6: ryczalt_a15_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r6",
    "package": "jdg.micro.ryczalt",
    "priority": 100064,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ryczalt_exclusion_2", false) == false
}

# jdg.micro.ryczalt.a15.r7: ryczalt_a15_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r7",
    "package": "jdg.micro.ryczalt",
    "priority": 100065,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ryczalt_a15_exception", false) == true
}

# jdg.micro.ryczalt.a15.r8: ryczalt_a15_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r8",
    "package": "jdg.micro.ryczalt",
    "priority": 100066,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ryczalt_a15_exception_2", false) == true
}

# jdg.micro.ryczalt.a15.r9: ryczalt_a15_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r9",
    "package": "jdg.micro.ryczalt",
    "priority": 100067,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ryczalt", false) == true
}

# jdg.micro.ryczalt.a15.r10: ryczalt_a15_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a15.r10",
    "package": "jdg.micro.ryczalt",
    "priority": 100068,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ryczalt", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a21 — Karta podatkowa — stawki (12 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a21.r1: ryczalt_a21_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100069,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ryczalt.a21.r2: ryczalt_a21_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100070,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ryczalt_condition_met", false) == true
}

# jdg.micro.ryczalt.a21.r3: ryczalt_a21_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100071,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a21_r3_pass", false) == true
}

# jdg.micro.ryczalt.a21.r4: ryczalt_a21_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r4",
    "package": "jdg.micro.ryczalt",
    "priority": 100072,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a21_r4_checks", false) == true
}

# jdg.micro.ryczalt.a21.r5: ryczalt_a21_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r5",
    "package": "jdg.micro.ryczalt",
    "priority": 100073,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ryczalt_exclusion_applies", false) == false
}

# jdg.micro.ryczalt.a21.r6: ryczalt_a21_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r6",
    "package": "jdg.micro.ryczalt",
    "priority": 100074,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ryczalt_exclusion_2", false) == false
}

# jdg.micro.ryczalt.a21.r7: ryczalt_a21_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r7",
    "package": "jdg.micro.ryczalt",
    "priority": 100075,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ryczalt_a21_exception", false) == true
}

# jdg.micro.ryczalt.a21.r8: ryczalt_a21_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r8",
    "package": "jdg.micro.ryczalt",
    "priority": 100076,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ryczalt_a21_exception_2", false) == true
}

# jdg.micro.ryczalt.a21.r9: ryczalt_a21_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r9",
    "package": "jdg.micro.ryczalt",
    "priority": 100077,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ryczalt", false) == true
}

# jdg.micro.ryczalt.a21.r10: ryczalt_a21_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r10",
    "package": "jdg.micro.ryczalt",
    "priority": 100078,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ryczalt", false) == true
}

# jdg.micro.ryczalt.a21.r11: ryczalt_a21_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r11",
    "package": "jdg.micro.ryczalt",
    "priority": 100079,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ryczalt_deadline_required", false) == true
}

# jdg.micro.ryczalt.a21.r12: ryczalt_a21_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a21.r12",
    "package": "jdg.micro.ryczalt",
    "priority": 100080,
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
    "sanction_type": "KKS",
    "sanction_severity": "MEDIUM",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Karta podatkowa — stawki",
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a21_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a27 — Karta podatkowa — warunki (12 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a27.r1: ryczalt_a27_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100081,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ryczalt.a27.r2: ryczalt_a27_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100082,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ryczalt_condition_met", false) == true
}

# jdg.micro.ryczalt.a27.r3: ryczalt_a27_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100083,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a27_r3_pass", false) == true
}

# jdg.micro.ryczalt.a27.r4: ryczalt_a27_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r4",
    "package": "jdg.micro.ryczalt",
    "priority": 100084,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a27_r4_checks", false) == true
}

# jdg.micro.ryczalt.a27.r5: ryczalt_a27_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r5",
    "package": "jdg.micro.ryczalt",
    "priority": 100085,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ryczalt_exclusion_applies", false) == false
}

# jdg.micro.ryczalt.a27.r6: ryczalt_a27_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r6",
    "package": "jdg.micro.ryczalt",
    "priority": 100086,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ryczalt_exclusion_2", false) == false
}

# jdg.micro.ryczalt.a27.r7: ryczalt_a27_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r7",
    "package": "jdg.micro.ryczalt",
    "priority": 100087,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ryczalt_a27_exception", false) == true
}

# jdg.micro.ryczalt.a27.r8: ryczalt_a27_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r8",
    "package": "jdg.micro.ryczalt",
    "priority": 100088,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ryczalt_a27_exception_2", false) == true
}

# jdg.micro.ryczalt.a27.r9: ryczalt_a27_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r9",
    "package": "jdg.micro.ryczalt",
    "priority": 100089,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ryczalt", false) == true
}

# jdg.micro.ryczalt.a27.r10: ryczalt_a27_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r10",
    "package": "jdg.micro.ryczalt",
    "priority": 100090,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ryczalt", false) == true
}

# jdg.micro.ryczalt.a27.r11: ryczalt_a27_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r11",
    "package": "jdg.micro.ryczalt",
    "priority": 100091,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ryczalt_deadline_required", false) == true
}

# jdg.micro.ryczalt.a27.r12: ryczalt_a27_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a27.r12",
    "package": "jdg.micro.ryczalt",
    "priority": 100092,
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
    "sanction_type": "KKS",
    "sanction_severity": "MEDIUM",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Karta podatkowa — warunki",
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a27_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a30 — Utrata prawa do ryczałtu (8 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a30.r1: ryczalt_a30_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a30.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100093,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Utrata prawa do ryczałtu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ryczalt.a30.r2: ryczalt_a30_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a30.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100094,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Utrata prawa do ryczałtu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ryczalt_condition_met", false) == true
}

# jdg.micro.ryczalt.a30.r3: ryczalt_a30_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a30.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100095,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Utrata prawa do ryczałtu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a30_r3_pass", false) == true
}

# jdg.micro.ryczalt.a30.r4: ryczalt_a30_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a30.r4",
    "package": "jdg.micro.ryczalt",
    "priority": 100096,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Utrata prawa do ryczałtu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a30_r4_checks", false) == true
}

# jdg.micro.ryczalt.a30.r5: ryczalt_a30_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a30.r5",
    "package": "jdg.micro.ryczalt",
    "priority": 100097,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Utrata prawa do ryczałtu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ryczalt_exclusion_applies", false) == false
}

# jdg.micro.ryczalt.a30.r6: ryczalt_a30_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a30.r6",
    "package": "jdg.micro.ryczalt",
    "priority": 100098,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Utrata prawa do ryczałtu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ryczalt_exclusion_2", false) == false
}

# jdg.micro.ryczalt.a30.r7: ryczalt_a30_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a30.r7",
    "package": "jdg.micro.ryczalt",
    "priority": 100099,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Utrata prawa do ryczałtu: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ryczalt_a30_exception", false) == true
}

# jdg.micro.ryczalt.a30.r8: ryczalt_a30_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a30.r8",
    "package": "jdg.micro.ryczalt",
    "priority": 100100,
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
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "_warnings": ["[MICRO] Utrata prawa do ryczałtu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ryczalt_a30_exception_2", false) == true
}
