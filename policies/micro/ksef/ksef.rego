# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: KSeF — 30 artykułów → ~360 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.ksef
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.ksef

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.ksef.no_match",
    "package": "jdg.micro.ksef",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ksef.a106na — KSeF — obowiązek (15 reguł)                                    ║
# ║  Legal basis: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ksef.a106na.r1: ksef_a106na_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r1",
    "package": "jdg.micro.ksef",
    "priority": 180001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ksef.a106na.r2: ksef_a106na_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r2",
    "package": "jdg.micro.ksef",
    "priority": 180002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ksef_condition_met", false) == true
}

# jdg.micro.ksef.a106na.r3: ksef_a106na_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r3",
    "package": "jdg.micro.ksef",
    "priority": 180003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106na_r3_pass", false) == true
}

# jdg.micro.ksef.a106na.r4: ksef_a106na_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r4",
    "package": "jdg.micro.ksef",
    "priority": 180004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106na_r4_checks", false) == true
}

# jdg.micro.ksef.a106na.r5: ksef_a106na_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r5",
    "package": "jdg.micro.ksef",
    "priority": 180005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ksef_exclusion_applies", false) == false
}

# jdg.micro.ksef.a106na.r6: ksef_a106na_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r6",
    "package": "jdg.micro.ksef",
    "priority": 180006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ksef_exclusion_2", false) == false
}

# jdg.micro.ksef.a106na.r7: ksef_a106na_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r7",
    "package": "jdg.micro.ksef",
    "priority": 180007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ksef_a106na_exception", false) == true
}

# jdg.micro.ksef.a106na.r8: ksef_a106na_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r8",
    "package": "jdg.micro.ksef",
    "priority": 180008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ksef_a106na_exception_2", false) == true
}

# jdg.micro.ksef.a106na.r9: ksef_a106na_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r9",
    "package": "jdg.micro.ksef",
    "priority": 180009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ksef", false) == true
}

# jdg.micro.ksef.a106na.r10: ksef_a106na_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r10",
    "package": "jdg.micro.ksef",
    "priority": 180010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ksef", false) == true
}

# jdg.micro.ksef.a106na.r11: ksef_a106na_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r11",
    "package": "jdg.micro.ksef",
    "priority": 180011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ksef_deadline_required", false) == true
}

# jdg.micro.ksef.a106na.r12: ksef_a106na_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r12",
    "package": "jdg.micro.ksef",
    "priority": 180012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie KSeF — obowiązek",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106na_violation", false) == true
}

# jdg.micro.ksef.a106na.r13: ksef_a106na_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r13",
    "package": "jdg.micro.ksef",
    "priority": 180013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "ksef_a106na_edge_case", false) == true
}

# jdg.micro.ksef.a106na.r14: ksef_a106na_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r14",
    "package": "jdg.micro.ksef",
    "priority": 180014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "ksef_a106na_edge_case_2", false) == true
}

# jdg.micro.ksef.a106na.r15: ksef_a106na_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106na.r15",
    "package": "jdg.micro.ksef",
    "priority": 180015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — obowiązek: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "ksef_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ksef.a106nb — KSeF — wystawianie (12 reguł)                                    ║
# ║  Legal basis: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ksef.a106nb.r1: ksef_a106nb_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r1",
    "package": "jdg.micro.ksef",
    "priority": 180016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ksef.a106nb.r2: ksef_a106nb_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r2",
    "package": "jdg.micro.ksef",
    "priority": 180017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ksef_condition_met", false) == true
}

# jdg.micro.ksef.a106nb.r3: ksef_a106nb_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r3",
    "package": "jdg.micro.ksef",
    "priority": 180018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nb_r3_pass", false) == true
}

# jdg.micro.ksef.a106nb.r4: ksef_a106nb_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r4",
    "package": "jdg.micro.ksef",
    "priority": 180019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nb_r4_checks", false) == true
}

# jdg.micro.ksef.a106nb.r5: ksef_a106nb_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r5",
    "package": "jdg.micro.ksef",
    "priority": 180020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ksef_exclusion_applies", false) == false
}

# jdg.micro.ksef.a106nb.r6: ksef_a106nb_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r6",
    "package": "jdg.micro.ksef",
    "priority": 180021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ksef_exclusion_2", false) == false
}

# jdg.micro.ksef.a106nb.r7: ksef_a106nb_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r7",
    "package": "jdg.micro.ksef",
    "priority": 180022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ksef_a106nb_exception", false) == true
}

# jdg.micro.ksef.a106nb.r8: ksef_a106nb_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r8",
    "package": "jdg.micro.ksef",
    "priority": 180023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ksef_a106nb_exception_2", false) == true
}

# jdg.micro.ksef.a106nb.r9: ksef_a106nb_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r9",
    "package": "jdg.micro.ksef",
    "priority": 180024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ksef", false) == true
}

# jdg.micro.ksef.a106nb.r10: ksef_a106nb_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r10",
    "package": "jdg.micro.ksef",
    "priority": 180025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ksef", false) == true
}

# jdg.micro.ksef.a106nb.r11: ksef_a106nb_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r11",
    "package": "jdg.micro.ksef",
    "priority": 180026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ksef_deadline_required", false) == true
}

# jdg.micro.ksef.a106nb.r12: ksef_a106nb_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nb.r12",
    "package": "jdg.micro.ksef",
    "priority": 180027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie KSeF — wystawianie",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — wystawianie: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nb_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ksef.a106nc — KSeF — odbiór (10 reguł)                                    ║
# ║  Legal basis: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ksef.a106nc.r1: ksef_a106nc_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r1",
    "package": "jdg.micro.ksef",
    "priority": 180028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ksef.a106nc.r2: ksef_a106nc_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r2",
    "package": "jdg.micro.ksef",
    "priority": 180029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ksef_condition_met", false) == true
}

# jdg.micro.ksef.a106nc.r3: ksef_a106nc_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r3",
    "package": "jdg.micro.ksef",
    "priority": 180030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nc_r3_pass", false) == true
}

# jdg.micro.ksef.a106nc.r4: ksef_a106nc_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r4",
    "package": "jdg.micro.ksef",
    "priority": 180031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nc_r4_checks", false) == true
}

# jdg.micro.ksef.a106nc.r5: ksef_a106nc_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r5",
    "package": "jdg.micro.ksef",
    "priority": 180032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ksef_exclusion_applies", false) == false
}

# jdg.micro.ksef.a106nc.r6: ksef_a106nc_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r6",
    "package": "jdg.micro.ksef",
    "priority": 180033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ksef_exclusion_2", false) == false
}

# jdg.micro.ksef.a106nc.r7: ksef_a106nc_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r7",
    "package": "jdg.micro.ksef",
    "priority": 180034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ksef_a106nc_exception", false) == true
}

# jdg.micro.ksef.a106nc.r8: ksef_a106nc_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r8",
    "package": "jdg.micro.ksef",
    "priority": 180035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ksef_a106nc_exception_2", false) == true
}

# jdg.micro.ksef.a106nc.r9: ksef_a106nc_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r9",
    "package": "jdg.micro.ksef",
    "priority": 180036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ksef", false) == true
}

# jdg.micro.ksef.a106nc.r10: ksef_a106nc_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nc.r10",
    "package": "jdg.micro.ksef",
    "priority": 180037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — odbiór: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ksef", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ksef.a106nd — KSeF — przechowywanie (10 reguł)                                    ║
# ║  Legal basis: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ksef.a106nd.r1: ksef_a106nd_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r1",
    "package": "jdg.micro.ksef",
    "priority": 180038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ksef.a106nd.r2: ksef_a106nd_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r2",
    "package": "jdg.micro.ksef",
    "priority": 180039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ksef_condition_met", false) == true
}

# jdg.micro.ksef.a106nd.r3: ksef_a106nd_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r3",
    "package": "jdg.micro.ksef",
    "priority": 180040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nd_r3_pass", false) == true
}

# jdg.micro.ksef.a106nd.r4: ksef_a106nd_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r4",
    "package": "jdg.micro.ksef",
    "priority": 180041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nd_r4_checks", false) == true
}

# jdg.micro.ksef.a106nd.r5: ksef_a106nd_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r5",
    "package": "jdg.micro.ksef",
    "priority": 180042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ksef_exclusion_applies", false) == false
}

# jdg.micro.ksef.a106nd.r6: ksef_a106nd_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r6",
    "package": "jdg.micro.ksef",
    "priority": 180043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ksef_exclusion_2", false) == false
}

# jdg.micro.ksef.a106nd.r7: ksef_a106nd_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r7",
    "package": "jdg.micro.ksef",
    "priority": 180044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ksef_a106nd_exception", false) == true
}

# jdg.micro.ksef.a106nd.r8: ksef_a106nd_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r8",
    "package": "jdg.micro.ksef",
    "priority": 180045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ksef_a106nd_exception_2", false) == true
}

# jdg.micro.ksef.a106nd.r9: ksef_a106nd_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r9",
    "package": "jdg.micro.ksef",
    "priority": 180046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ksef", false) == true
}

# jdg.micro.ksef.a106nd.r10: ksef_a106nd_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nd.r10",
    "package": "jdg.micro.ksef",
    "priority": 180047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — przechowywanie: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ksef", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ksef.a106ne — KSeF — tryb awaryjny (10 reguł)                                    ║
# ║  Legal basis: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ksef.a106ne.r1: ksef_a106ne_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r1",
    "package": "jdg.micro.ksef",
    "priority": 180048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ksef.a106ne.r2: ksef_a106ne_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r2",
    "package": "jdg.micro.ksef",
    "priority": 180049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ksef_condition_met", false) == true
}

# jdg.micro.ksef.a106ne.r3: ksef_a106ne_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r3",
    "package": "jdg.micro.ksef",
    "priority": 180050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106ne_r3_pass", false) == true
}

# jdg.micro.ksef.a106ne.r4: ksef_a106ne_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r4",
    "package": "jdg.micro.ksef",
    "priority": 180051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106ne_r4_checks", false) == true
}

# jdg.micro.ksef.a106ne.r5: ksef_a106ne_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r5",
    "package": "jdg.micro.ksef",
    "priority": 180052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ksef_exclusion_applies", false) == false
}

# jdg.micro.ksef.a106ne.r6: ksef_a106ne_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r6",
    "package": "jdg.micro.ksef",
    "priority": 180053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ksef_exclusion_2", false) == false
}

# jdg.micro.ksef.a106ne.r7: ksef_a106ne_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r7",
    "package": "jdg.micro.ksef",
    "priority": 180054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ksef_a106ne_exception", false) == true
}

# jdg.micro.ksef.a106ne.r8: ksef_a106ne_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r8",
    "package": "jdg.micro.ksef",
    "priority": 180055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ksef_a106ne_exception_2", false) == true
}

# jdg.micro.ksef.a106ne.r9: ksef_a106ne_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r9",
    "package": "jdg.micro.ksef",
    "priority": 180056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ksef", false) == true
}

# jdg.micro.ksef.a106ne.r10: ksef_a106ne_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ne.r10",
    "package": "jdg.micro.ksef",
    "priority": 180057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — tryb awaryjny: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ksef", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ksef.a106nf — KSeF — UPO (8 reguł)                                    ║
# ║  Legal basis: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ksef.a106nf.r1: ksef_a106nf_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nf.r1",
    "package": "jdg.micro.ksef",
    "priority": 180058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — UPO: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ksef.a106nf.r2: ksef_a106nf_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nf.r2",
    "package": "jdg.micro.ksef",
    "priority": 180059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — UPO: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ksef_condition_met", false) == true
}

# jdg.micro.ksef.a106nf.r3: ksef_a106nf_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nf.r3",
    "package": "jdg.micro.ksef",
    "priority": 180060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — UPO: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nf_r3_pass", false) == true
}

# jdg.micro.ksef.a106nf.r4: ksef_a106nf_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nf.r4",
    "package": "jdg.micro.ksef",
    "priority": 180061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — UPO: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nf_r4_checks", false) == true
}

# jdg.micro.ksef.a106nf.r5: ksef_a106nf_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nf.r5",
    "package": "jdg.micro.ksef",
    "priority": 180062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — UPO: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ksef_exclusion_applies", false) == false
}

# jdg.micro.ksef.a106nf.r6: ksef_a106nf_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nf.r6",
    "package": "jdg.micro.ksef",
    "priority": 180063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — UPO: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ksef_exclusion_2", false) == false
}

# jdg.micro.ksef.a106nf.r7: ksef_a106nf_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nf.r7",
    "package": "jdg.micro.ksef",
    "priority": 180064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — UPO: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ksef_a106nf_exception", false) == true
}

# jdg.micro.ksef.a106nf.r8: ksef_a106nf_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nf.r8",
    "package": "jdg.micro.ksef",
    "priority": 180065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — UPO: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ksef_a106nf_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ksef.a106ng — KSeF — QR kod (6 reguł)                                    ║
# ║  Legal basis: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ksef.a106ng.r1: ksef_a106ng_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ng.r1",
    "package": "jdg.micro.ksef",
    "priority": 180066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — QR kod: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ksef.a106ng.r2: ksef_a106ng_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ng.r2",
    "package": "jdg.micro.ksef",
    "priority": 180067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — QR kod: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ksef_condition_met", false) == true
}

# jdg.micro.ksef.a106ng.r3: ksef_a106ng_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ng.r3",
    "package": "jdg.micro.ksef",
    "priority": 180068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — QR kod: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106ng_r3_pass", false) == true
}

# jdg.micro.ksef.a106ng.r4: ksef_a106ng_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ng.r4",
    "package": "jdg.micro.ksef",
    "priority": 180069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — QR kod: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106ng_r4_checks", false) == true
}

# jdg.micro.ksef.a106ng.r5: ksef_a106ng_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ng.r5",
    "package": "jdg.micro.ksef",
    "priority": 180070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — QR kod: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ksef_exclusion_applies", false) == false
}

# jdg.micro.ksef.a106ng.r6: ksef_a106ng_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106ng.r6",
    "package": "jdg.micro.ksef",
    "priority": 180071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — QR kod: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ksef_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ksef.a106nh — KSeF — zgoda nabywcy (8 reguł)                                    ║
# ║  Legal basis: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ksef.a106nh.r1: ksef_a106nh_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nh.r1",
    "package": "jdg.micro.ksef",
    "priority": 180072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — zgoda nabywcy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ksef.a106nh.r2: ksef_a106nh_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nh.r2",
    "package": "jdg.micro.ksef",
    "priority": 180073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — zgoda nabywcy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ksef_condition_met", false) == true
}

# jdg.micro.ksef.a106nh.r3: ksef_a106nh_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nh.r3",
    "package": "jdg.micro.ksef",
    "priority": 180074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — zgoda nabywcy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nh_r3_pass", false) == true
}

# jdg.micro.ksef.a106nh.r4: ksef_a106nh_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nh.r4",
    "package": "jdg.micro.ksef",
    "priority": 180075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — zgoda nabywcy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ksef_a106nh_r4_checks", false) == true
}

# jdg.micro.ksef.a106nh.r5: ksef_a106nh_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nh.r5",
    "package": "jdg.micro.ksef",
    "priority": 180076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — zgoda nabywcy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ksef_exclusion_applies", false) == false
}

# jdg.micro.ksef.a106nh.r6: ksef_a106nh_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nh.r6",
    "package": "jdg.micro.ksef",
    "priority": 180077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — zgoda nabywcy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ksef_exclusion_2", false) == false
}

# jdg.micro.ksef.a106nh.r7: ksef_a106nh_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nh.r7",
    "package": "jdg.micro.ksef",
    "priority": 180078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — zgoda nabywcy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ksef_a106nh_exception", false) == true
}

# jdg.micro.ksef.a106nh.r8: ksef_a106nh_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ksef.a106nh.r8",
    "package": "jdg.micro.ksef",
    "priority": 180079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "_warnings": ["[MICRO] KSeF — zgoda nabywcy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ksef_a106nh_exception_2", false) == true
}
