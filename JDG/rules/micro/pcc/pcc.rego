# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PCC + podatki lokalne — 25 artykułów → ~250 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.pcc
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pcc

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pcc.no_match",
    "package": "jdg.micro.pcc",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a1 — Definicja PCC (10 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a1.r1: pcc_a1_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r1",
    "package": "jdg.micro.pcc",
    "priority": 170001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a1.r2: pcc_a1_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r2",
    "package": "jdg.micro.pcc",
    "priority": 170002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a1.r3: pcc_a1_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r3",
    "package": "jdg.micro.pcc",
    "priority": 170003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a1_r3_pass", false) == true
}

# jdg.micro.pcc.a1.r4: pcc_a1_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r4",
    "package": "jdg.micro.pcc",
    "priority": 170004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a1_r4_checks", false) == true
}

# jdg.micro.pcc.a1.r5: pcc_a1_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r5",
    "package": "jdg.micro.pcc",
    "priority": 170005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# jdg.micro.pcc.a1.r6: pcc_a1_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r6",
    "package": "jdg.micro.pcc",
    "priority": 170006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pcc_exclusion_2", false) == false
}

# jdg.micro.pcc.a1.r7: pcc_a1_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r7",
    "package": "jdg.micro.pcc",
    "priority": 170007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pcc_a1_exception", false) == true
}

# jdg.micro.pcc.a1.r8: pcc_a1_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r8",
    "package": "jdg.micro.pcc",
    "priority": 170008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pcc_a1_exception_2", false) == true
}

# jdg.micro.pcc.a1.r9: pcc_a1_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r9",
    "package": "jdg.micro.pcc",
    "priority": 170009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pcc", false) == true
}

# jdg.micro.pcc.a1.r10: pcc_a1_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a1.r10",
    "package": "jdg.micro.pcc",
    "priority": 170010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Definicja PCC: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pcc", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a2 — Zwolnienia PCC (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a2.r1: pcc_a2_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r1",
    "package": "jdg.micro.pcc",
    "priority": 170011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a2.r2: pcc_a2_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r2",
    "package": "jdg.micro.pcc",
    "priority": 170012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a2.r3: pcc_a2_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r3",
    "package": "jdg.micro.pcc",
    "priority": 170013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a2_r3_pass", false) == true
}

# jdg.micro.pcc.a2.r4: pcc_a2_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r4",
    "package": "jdg.micro.pcc",
    "priority": 170014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a2_r4_checks", false) == true
}

# jdg.micro.pcc.a2.r5: pcc_a2_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r5",
    "package": "jdg.micro.pcc",
    "priority": 170015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# jdg.micro.pcc.a2.r6: pcc_a2_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r6",
    "package": "jdg.micro.pcc",
    "priority": 170016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pcc_exclusion_2", false) == false
}

# jdg.micro.pcc.a2.r7: pcc_a2_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r7",
    "package": "jdg.micro.pcc",
    "priority": 170017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pcc_a2_exception", false) == true
}

# jdg.micro.pcc.a2.r8: pcc_a2_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r8",
    "package": "jdg.micro.pcc",
    "priority": 170018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pcc_a2_exception_2", false) == true
}

# jdg.micro.pcc.a2.r9: pcc_a2_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r9",
    "package": "jdg.micro.pcc",
    "priority": 170019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pcc", false) == true
}

# jdg.micro.pcc.a2.r10: pcc_a2_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r10",
    "package": "jdg.micro.pcc",
    "priority": 170020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pcc", false) == true
}

# jdg.micro.pcc.a2.r11: pcc_a2_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r11",
    "package": "jdg.micro.pcc",
    "priority": 170021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pcc_deadline_required", false) == true
}

# jdg.micro.pcc.a2.r12: pcc_a2_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a2.r12",
    "package": "jdg.micro.pcc",
    "priority": 170022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "LOW",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Zwolnienia PCC",
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Zwolnienia PCC: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a2_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a3 — Transfer wierzytelności (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a3.r1: pcc_a3_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a3.r1",
    "package": "jdg.micro.pcc",
    "priority": 170023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Transfer wierzytelności: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a3.r2: pcc_a3_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a3.r2",
    "package": "jdg.micro.pcc",
    "priority": 170024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Transfer wierzytelności: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a3.r3: pcc_a3_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a3.r3",
    "package": "jdg.micro.pcc",
    "priority": 170025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Transfer wierzytelności: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a3_r3_pass", false) == true
}

# jdg.micro.pcc.a3.r4: pcc_a3_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a3.r4",
    "package": "jdg.micro.pcc",
    "priority": 170026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Transfer wierzytelności: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a3_r4_checks", false) == true
}

# jdg.micro.pcc.a3.r5: pcc_a3_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a3.r5",
    "package": "jdg.micro.pcc",
    "priority": 170027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Transfer wierzytelności: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# jdg.micro.pcc.a3.r6: pcc_a3_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a3.r6",
    "package": "jdg.micro.pcc",
    "priority": 170028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Transfer wierzytelności: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pcc_exclusion_2", false) == false
}

# jdg.micro.pcc.a3.r7: pcc_a3_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a3.r7",
    "package": "jdg.micro.pcc",
    "priority": 170029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Transfer wierzytelności: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pcc_a3_exception", false) == true
}

# jdg.micro.pcc.a3.r8: pcc_a3_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a3.r8",
    "package": "jdg.micro.pcc",
    "priority": 170030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Transfer wierzytelności: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pcc_a3_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a4 — Umowa pożyczki (10 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a4.r1: pcc_a4_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r1",
    "package": "jdg.micro.pcc",
    "priority": 170031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a4.r2: pcc_a4_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r2",
    "package": "jdg.micro.pcc",
    "priority": 170032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a4.r3: pcc_a4_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r3",
    "package": "jdg.micro.pcc",
    "priority": 170033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a4_r3_pass", false) == true
}

# jdg.micro.pcc.a4.r4: pcc_a4_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r4",
    "package": "jdg.micro.pcc",
    "priority": 170034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a4_r4_checks", false) == true
}

# jdg.micro.pcc.a4.r5: pcc_a4_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r5",
    "package": "jdg.micro.pcc",
    "priority": 170035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# jdg.micro.pcc.a4.r6: pcc_a4_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r6",
    "package": "jdg.micro.pcc",
    "priority": 170036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pcc_exclusion_2", false) == false
}

# jdg.micro.pcc.a4.r7: pcc_a4_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r7",
    "package": "jdg.micro.pcc",
    "priority": 170037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pcc_a4_exception", false) == true
}

# jdg.micro.pcc.a4.r8: pcc_a4_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r8",
    "package": "jdg.micro.pcc",
    "priority": 170038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pcc_a4_exception_2", false) == true
}

# jdg.micro.pcc.a4.r9: pcc_a4_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r9",
    "package": "jdg.micro.pcc",
    "priority": 170039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pcc", false) == true
}

# jdg.micro.pcc.a4.r10: pcc_a4_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a4.r10",
    "package": "jdg.micro.pcc",
    "priority": 170040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Umowa pożyczki: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pcc", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a6 — Pojazdy (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a6.r1: pcc_a6_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a6.r1",
    "package": "jdg.micro.pcc",
    "priority": 170041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Pojazdy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a6.r2: pcc_a6_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a6.r2",
    "package": "jdg.micro.pcc",
    "priority": 170042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Pojazdy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a6.r3: pcc_a6_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a6.r3",
    "package": "jdg.micro.pcc",
    "priority": 170043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Pojazdy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a6_r3_pass", false) == true
}

# jdg.micro.pcc.a6.r4: pcc_a6_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a6.r4",
    "package": "jdg.micro.pcc",
    "priority": 170044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Pojazdy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a6_r4_checks", false) == true
}

# jdg.micro.pcc.a6.r5: pcc_a6_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a6.r5",
    "package": "jdg.micro.pcc",
    "priority": 170045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Pojazdy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# jdg.micro.pcc.a6.r6: pcc_a6_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a6.r6",
    "package": "jdg.micro.pcc",
    "priority": 170046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Pojazdy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pcc_exclusion_2", false) == false
}

# jdg.micro.pcc.a6.r7: pcc_a6_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a6.r7",
    "package": "jdg.micro.pcc",
    "priority": 170047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Pojazdy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pcc_a6_exception", false) == true
}

# jdg.micro.pcc.a6.r8: pcc_a6_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a6.r8",
    "package": "jdg.micro.pcc",
    "priority": 170048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Pojazdy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pcc_a6_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a7 — Nieruchomości (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a7.r1: pcc_a7_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a7.r1",
    "package": "jdg.micro.pcc",
    "priority": 170049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Nieruchomości: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a7.r2: pcc_a7_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a7.r2",
    "package": "jdg.micro.pcc",
    "priority": 170050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Nieruchomości: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a7.r3: pcc_a7_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a7.r3",
    "package": "jdg.micro.pcc",
    "priority": 170051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Nieruchomości: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a7_r3_pass", false) == true
}

# jdg.micro.pcc.a7.r4: pcc_a7_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a7.r4",
    "package": "jdg.micro.pcc",
    "priority": 170052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Nieruchomości: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a7_r4_checks", false) == true
}

# jdg.micro.pcc.a7.r5: pcc_a7_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a7.r5",
    "package": "jdg.micro.pcc",
    "priority": 170053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Nieruchomości: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# jdg.micro.pcc.a7.r6: pcc_a7_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a7.r6",
    "package": "jdg.micro.pcc",
    "priority": 170054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Nieruchomości: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pcc_exclusion_2", false) == false
}

# jdg.micro.pcc.a7.r7: pcc_a7_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a7.r7",
    "package": "jdg.micro.pcc",
    "priority": 170055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Nieruchomości: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pcc_a7_exception", false) == true
}

# jdg.micro.pcc.a7.r8: pcc_a7_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a7.r8",
    "package": "jdg.micro.pcc",
    "priority": 170056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Nieruchomości: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pcc_a7_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a5l — Podatek od nieruchomości (10 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a5l.r1: pcc_a5l_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r1",
    "package": "jdg.micro.pcc",
    "priority": 170057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a5l.r2: pcc_a5l_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r2",
    "package": "jdg.micro.pcc",
    "priority": 170058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a5l.r3: pcc_a5l_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r3",
    "package": "jdg.micro.pcc",
    "priority": 170059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a5l_r3_pass", false) == true
}

# jdg.micro.pcc.a5l.r4: pcc_a5l_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r4",
    "package": "jdg.micro.pcc",
    "priority": 170060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a5l_r4_checks", false) == true
}

# jdg.micro.pcc.a5l.r5: pcc_a5l_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r5",
    "package": "jdg.micro.pcc",
    "priority": 170061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# jdg.micro.pcc.a5l.r6: pcc_a5l_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r6",
    "package": "jdg.micro.pcc",
    "priority": 170062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pcc_exclusion_2", false) == false
}

# jdg.micro.pcc.a5l.r7: pcc_a5l_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r7",
    "package": "jdg.micro.pcc",
    "priority": 170063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pcc_a5l_exception", false) == true
}

# jdg.micro.pcc.a5l.r8: pcc_a5l_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r8",
    "package": "jdg.micro.pcc",
    "priority": 170064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pcc_a5l_exception_2", false) == true
}

# jdg.micro.pcc.a5l.r9: pcc_a5l_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r9",
    "package": "jdg.micro.pcc",
    "priority": 170065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pcc", false) == true
}

# jdg.micro.pcc.a5l.r10: pcc_a5l_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a5l.r10",
    "package": "jdg.micro.pcc",
    "priority": 170066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od nieruchomości: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pcc", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a9l — Podatek od środków transportowych (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a9l.r1: pcc_a9l_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a9l.r1",
    "package": "jdg.micro.pcc",
    "priority": 170067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od środków transportowych: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a9l.r2: pcc_a9l_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a9l.r2",
    "package": "jdg.micro.pcc",
    "priority": 170068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od środków transportowych: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a9l.r3: pcc_a9l_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a9l.r3",
    "package": "jdg.micro.pcc",
    "priority": 170069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od środków transportowych: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a9l_r3_pass", false) == true
}

# jdg.micro.pcc.a9l.r4: pcc_a9l_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a9l.r4",
    "package": "jdg.micro.pcc",
    "priority": 170070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od środków transportowych: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a9l_r4_checks", false) == true
}

# jdg.micro.pcc.a9l.r5: pcc_a9l_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a9l.r5",
    "package": "jdg.micro.pcc",
    "priority": 170071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od środków transportowych: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# jdg.micro.pcc.a9l.r6: pcc_a9l_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a9l.r6",
    "package": "jdg.micro.pcc",
    "priority": 170072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od środków transportowych: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pcc_exclusion_2", false) == false
}

# jdg.micro.pcc.a9l.r7: pcc_a9l_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a9l.r7",
    "package": "jdg.micro.pcc",
    "priority": 170073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od środków transportowych: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pcc_a9l_exception", false) == true
}

# jdg.micro.pcc.a9l.r8: pcc_a9l_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a9l.r8",
    "package": "jdg.micro.pcc",
    "priority": 170074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Podatek od środków transportowych: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pcc_a9l_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a13l — Opłata targowa (5 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a13l.r1: pcc_a13l_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a13l.r1",
    "package": "jdg.micro.pcc",
    "priority": 170075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata targowa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a13l.r2: pcc_a13l_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a13l.r2",
    "package": "jdg.micro.pcc",
    "priority": 170076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata targowa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a13l.r3: pcc_a13l_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a13l.r3",
    "package": "jdg.micro.pcc",
    "priority": 170077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata targowa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a13l_r3_pass", false) == true
}

# jdg.micro.pcc.a13l.r4: pcc_a13l_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a13l.r4",
    "package": "jdg.micro.pcc",
    "priority": 170078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata targowa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a13l_r4_checks", false) == true
}

# jdg.micro.pcc.a13l.r5: pcc_a13l_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a13l.r5",
    "package": "jdg.micro.pcc",
    "priority": 170079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata targowa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a14l — Opłata miejscowa (5 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a14l.r1: pcc_a14l_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a14l.r1",
    "package": "jdg.micro.pcc",
    "priority": 170080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata miejscowa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a14l.r2: pcc_a14l_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a14l.r2",
    "package": "jdg.micro.pcc",
    "priority": 170081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata miejscowa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a14l.r3: pcc_a14l_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a14l.r3",
    "package": "jdg.micro.pcc",
    "priority": 170082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata miejscowa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a14l_r3_pass", false) == true
}

# jdg.micro.pcc.a14l.r4: pcc_a14l_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a14l.r4",
    "package": "jdg.micro.pcc",
    "priority": 170083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata miejscowa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a14l_r4_checks", false) == true
}

# jdg.micro.pcc.a14l.r5: pcc_a14l_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a14l.r5",
    "package": "jdg.micro.pcc",
    "priority": 170084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata miejscowa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pcc.a16l — Opłata reklamowa (5 reguł)                                    ║
# ║  Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pcc.a16l.r1: pcc_a16l_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a16l.r1",
    "package": "jdg.micro.pcc",
    "priority": 170085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata reklamowa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pcc.a16l.r2: pcc_a16l_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a16l.r2",
    "package": "jdg.micro.pcc",
    "priority": 170086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata reklamowa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pcc_condition_met", false) == true
}

# jdg.micro.pcc.a16l.r3: pcc_a16l_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a16l.r3",
    "package": "jdg.micro.pcc",
    "priority": 170087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata reklamowa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a16l_r3_pass", false) == true
}

# jdg.micro.pcc.a16l.r4: pcc_a16l_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a16l.r4",
    "package": "jdg.micro.pcc",
    "priority": 170088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata reklamowa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pcc_a16l_r4_checks", false) == true
}

# jdg.micro.pcc.a16l.r5: pcc_a16l_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pcc.a16l.r5",
    "package": "jdg.micro.pcc",
    "priority": 170089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "_warnings": ["[MICRO] Opłata reklamowa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pcc_exclusion_applies", false) == false
}
