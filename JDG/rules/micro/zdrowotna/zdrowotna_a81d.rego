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
# ║  zdrowotna.a81d — Roczne rozliczenie zdrowotnej (12 reguł)                                    ║
# ║  Legal basis: Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zdrowotna.a81d.r1: zdrowotna_a81d_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r1",
    "package": "jdg.micro.zdrowotna",
    "priority": 110121,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zdrowotna.a81d.r2: zdrowotna_a81d_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r2",
    "package": "jdg.micro.zdrowotna",
    "priority": 110122,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_condition_met", false) == true
}

# jdg.micro.zdrowotna.a81d.r3: zdrowotna_a81d_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r3",
    "package": "jdg.micro.zdrowotna",
    "priority": 110123,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81d_r3_pass", false) == true
}

# jdg.micro.zdrowotna.a81d.r4: zdrowotna_a81d_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r4",
    "package": "jdg.micro.zdrowotna",
    "priority": 110124,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81d_r4_checks", false) == true
}

# jdg.micro.zdrowotna.a81d.r5: zdrowotna_a81d_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r5",
    "package": "jdg.micro.zdrowotna",
    "priority": 110125,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_applies", false) == false
}

# jdg.micro.zdrowotna.a81d.r6: zdrowotna_a81d_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r6",
    "package": "jdg.micro.zdrowotna",
    "priority": 110126,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_2", false) == false
}

# jdg.micro.zdrowotna.a81d.r7: zdrowotna_a81d_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r7",
    "package": "jdg.micro.zdrowotna",
    "priority": 110127,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zdrowotna_a81d_exception", false) == true
}

# jdg.micro.zdrowotna.a81d.r8: zdrowotna_a81d_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r8",
    "package": "jdg.micro.zdrowotna",
    "priority": 110128,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zdrowotna_a81d_exception_2", false) == true
}

# jdg.micro.zdrowotna.a81d.r9: zdrowotna_a81d_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r9",
    "package": "jdg.micro.zdrowotna",
    "priority": 110129,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_zdrowotna", false) == true
}

# jdg.micro.zdrowotna.a81d.r10: zdrowotna_a81d_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r10",
    "package": "jdg.micro.zdrowotna",
    "priority": 110130,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_zdrowotna", false) == true
}

# jdg.micro.zdrowotna.a81d.r11: zdrowotna_a81d_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r11",
    "package": "jdg.micro.zdrowotna",
    "priority": 110131,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "zdrowotna_deadline_required", false) == true
}

# jdg.micro.zdrowotna.a81d.r12: zdrowotna_a81d_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.r12",
    "package": "jdg.micro.zdrowotna",
    "priority": 110132,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie Roczne rozliczenie zdrowotnej",
    "_legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "_warnings": ["[MICRO] Roczne rozliczenie zdrowotnej: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81d_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗