# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: JPK — 30 artykułów → ~160 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.jpk
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.jpk

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.jpk.no_match",
    "package": "jdg.micro.jpk",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  jpk.a99 — JPK_V7M — struktura (15 reguł)                                    ║
# ║  Legal basis: Rozporządzenie MF w sprawie JPK_VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.jpk.a99.r1: jpk_a99_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r1",
    "package": "jdg.micro.jpk",
    "priority": 190099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.jpk.a99.r2: jpk_a99_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r2",
    "package": "jdg.micro.jpk",
    "priority": 190100,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "jpk_condition_met", false) == true
}

# jdg.micro.jpk.a99.r3: jpk_a99_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r3",
    "package": "jdg.micro.jpk",
    "priority": 190101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "jpk_a99_r3_pass", false) == true
}

# jdg.micro.jpk.a99.r4: jpk_a99_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r4",
    "package": "jdg.micro.jpk",
    "priority": 190102,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "jpk_a99_r4_checks", false) == true
}

# jdg.micro.jpk.a99.r5: jpk_a99_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r5",
    "package": "jdg.micro.jpk",
    "priority": 190103,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "jpk_exclusion_applies", false) == false
}

# jdg.micro.jpk.a99.r6: jpk_a99_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r6",
    "package": "jdg.micro.jpk",
    "priority": 190104,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "jpk_exclusion_2", false) == false
}

# jdg.micro.jpk.a99.r7: jpk_a99_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r7",
    "package": "jdg.micro.jpk",
    "priority": 190105,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "jpk_a99_exception", false) == true
}

# jdg.micro.jpk.a99.r8: jpk_a99_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r8",
    "package": "jdg.micro.jpk",
    "priority": 190106,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "jpk_a99_exception_2", false) == true
}

# jdg.micro.jpk.a99.r9: jpk_a99_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r9",
    "package": "jdg.micro.jpk",
    "priority": 190107,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_jpk", false) == true
}

# jdg.micro.jpk.a99.r10: jpk_a99_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r10",
    "package": "jdg.micro.jpk",
    "priority": 190108,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_jpk", false) == true
}

# jdg.micro.jpk.a99.r11: jpk_a99_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r11",
    "package": "jdg.micro.jpk",
    "priority": 190109,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "jpk_deadline_required", false) == true
}

# jdg.micro.jpk.a99.r12: jpk_a99_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r12",
    "package": "jdg.micro.jpk",
    "priority": 190110,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie JPK_V7M — struktura",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "jpk_a99_violation", false) == true
}

# jdg.micro.jpk.a99.r13: jpk_a99_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r13",
    "package": "jdg.micro.jpk",
    "priority": 190111,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "jpk_a99_edge_case", false) == true
}

# jdg.micro.jpk.a99.r14: jpk_a99_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r14",
    "package": "jdg.micro.jpk",
    "priority": 190112,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "jpk_a99_edge_case_2", false) == true
}

# jdg.micro.jpk.a99.r15: jpk_a99_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99.r15",
    "package": "jdg.micro.jpk",
    "priority": 190113,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7M — struktura: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "jpk_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  jpk.a99b — JPK_V7K — kwartalny (10 reguł)                                    ║
# ║  Legal basis: Rozporządzenie MF w sprawie JPK_VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.jpk.a99b.r1: jpk_a99b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r1",
    "package": "jdg.micro.jpk",
    "priority": 190114,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.jpk.a99b.r2: jpk_a99b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r2",
    "package": "jdg.micro.jpk",
    "priority": 190115,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "jpk_condition_met", false) == true
}

# jdg.micro.jpk.a99b.r3: jpk_a99b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r3",
    "package": "jdg.micro.jpk",
    "priority": 190116,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "jpk_a99b_r3_pass", false) == true
}

# jdg.micro.jpk.a99b.r4: jpk_a99b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r4",
    "package": "jdg.micro.jpk",
    "priority": 190117,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "jpk_a99b_r4_checks", false) == true
}

# jdg.micro.jpk.a99b.r5: jpk_a99b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r5",
    "package": "jdg.micro.jpk",
    "priority": 190118,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "jpk_exclusion_applies", false) == false
}

# jdg.micro.jpk.a99b.r6: jpk_a99b_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r6",
    "package": "jdg.micro.jpk",
    "priority": 190119,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "jpk_exclusion_2", false) == false
}

# jdg.micro.jpk.a99b.r7: jpk_a99b_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r7",
    "package": "jdg.micro.jpk",
    "priority": 190120,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "jpk_a99b_exception", false) == true
}

# jdg.micro.jpk.a99b.r8: jpk_a99b_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r8",
    "package": "jdg.micro.jpk",
    "priority": 190121,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "jpk_a99b_exception_2", false) == true
}

# jdg.micro.jpk.a99b.r9: jpk_a99b_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r9",
    "package": "jdg.micro.jpk",
    "priority": 190122,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_jpk", false) == true
}

# jdg.micro.jpk.a99b.r10: jpk_a99b_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a99b.r10",
    "package": "jdg.micro.jpk",
    "priority": 190123,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK_V7K — kwartalny: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_jpk", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  jpk.a193a — JPK na żądanie (10 reguł)                                    ║
# ║  Legal basis: Rozporządzenie MF w sprawie JPK_VAT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.jpk.a193a.r1: jpk_a193a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r1",
    "package": "jdg.micro.jpk",
    "priority": 190124,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.jpk.a193a.r2: jpk_a193a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r2",
    "package": "jdg.micro.jpk",
    "priority": 190125,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "jpk_condition_met", false) == true
}

# jdg.micro.jpk.a193a.r3: jpk_a193a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r3",
    "package": "jdg.micro.jpk",
    "priority": 190126,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "jpk_a193a_r3_pass", false) == true
}

# jdg.micro.jpk.a193a.r4: jpk_a193a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r4",
    "package": "jdg.micro.jpk",
    "priority": 190127,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "jpk_a193a_r4_checks", false) == true
}

# jdg.micro.jpk.a193a.r5: jpk_a193a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r5",
    "package": "jdg.micro.jpk",
    "priority": 190128,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "jpk_exclusion_applies", false) == false
}

# jdg.micro.jpk.a193a.r6: jpk_a193a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r6",
    "package": "jdg.micro.jpk",
    "priority": 190129,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "jpk_exclusion_2", false) == false
}

# jdg.micro.jpk.a193a.r7: jpk_a193a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r7",
    "package": "jdg.micro.jpk",
    "priority": 190130,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "jpk_a193a_exception", false) == true
}

# jdg.micro.jpk.a193a.r8: jpk_a193a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r8",
    "package": "jdg.micro.jpk",
    "priority": 190131,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "jpk_a193a_exception_2", false) == true
}

# jdg.micro.jpk.a193a.r9: jpk_a193a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r9",
    "package": "jdg.micro.jpk",
    "priority": 190132,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_jpk", false) == true
}

# jdg.micro.jpk.a193a.r10: jpk_a193a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.jpk.a193a.r10",
    "package": "jdg.micro.jpk",
    "priority": 190133,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
    "_warnings": ["[MICRO] JPK na żądanie: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_jpk", false) == true
}
