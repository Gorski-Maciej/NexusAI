# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa o świadczeniach opieki zdrowotnej — 10 artykułów → ~130 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.zdrowotna
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.zdrowotna

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.zdrowotna.no_match",
    "package": "jdg.micro.zdrowotna",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  zdrowotna.a81c — Podstawa wymiaru — ryczałt (12 reguł)                                    ║
# ║  Legal basis: Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zdrowotna.a81c.r1: zdrowotna_a81c_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r1",
    "package": "jdg.micro.zdrowotna",
    "priority": 110109,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zdrowotna.a81c.r2: zdrowotna_a81c_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r2",
    "package": "jdg.micro.zdrowotna",
    "priority": 110110,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_condition_met", false) == true
}

# jdg.micro.zdrowotna.a81c.r3: zdrowotna_a81c_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r3",
    "package": "jdg.micro.zdrowotna",
    "priority": 110111,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81c_r3_pass", false) == true
}

# jdg.micro.zdrowotna.a81c.r4: zdrowotna_a81c_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r4",
    "package": "jdg.micro.zdrowotna",
    "priority": 110112,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81c_r4_checks", false) == true
}

# jdg.micro.zdrowotna.a81c.r5: zdrowotna_a81c_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r5",
    "package": "jdg.micro.zdrowotna",
    "priority": 110113,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_applies", false) == false
}

# jdg.micro.zdrowotna.a81c.r6: zdrowotna_a81c_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r6",
    "package": "jdg.micro.zdrowotna",
    "priority": 110114,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_2", false) == false
}

# jdg.micro.zdrowotna.a81c.r7: zdrowotna_a81c_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r7",
    "package": "jdg.micro.zdrowotna",
    "priority": 110115,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zdrowotna_a81c_exception", false) == true
}

# jdg.micro.zdrowotna.a81c.r8: zdrowotna_a81c_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r8",
    "package": "jdg.micro.zdrowotna",
    "priority": 110116,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zdrowotna_a81c_exception_2", false) == true
}

# jdg.micro.zdrowotna.a81c.r9: zdrowotna_a81c_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r9",
    "package": "jdg.micro.zdrowotna",
    "priority": 110117,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_zdrowotna", false) == true
}

# jdg.micro.zdrowotna.a81c.r10: zdrowotna_a81c_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r10",
    "package": "jdg.micro.zdrowotna",
    "priority": 110118,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_zdrowotna", false) == true
}

# jdg.micro.zdrowotna.a81c.r11: zdrowotna_a81c_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r11",
    "package": "jdg.micro.zdrowotna",
    "priority": 110119,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "zdrowotna_deadline_required", false) == true
}

# jdg.micro.zdrowotna.a81c.r12: zdrowotna_a81c_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.r12",
    "package": "jdg.micro.zdrowotna",
    "priority": 110120,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie Podstawa wymiaru — ryczałt",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Podstawa wymiaru — ryczałt: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81c_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗