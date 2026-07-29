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
# ║  zdrowotna.a81b — Podstawa wymiaru — liniowy (10 reguł)                                    ║
# ║  Legal basis: Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zdrowotna.a81b.r1: zdrowotna_a81b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r1",
    "package": "jdg.micro.zdrowotna",
    "priority": 110099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zdrowotna.a81b.r2: zdrowotna_a81b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r2",
    "package": "jdg.micro.zdrowotna",
    "priority": 110100,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_condition_met", false) == true
}

# jdg.micro.zdrowotna.a81b.r3: zdrowotna_a81b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r3",
    "package": "jdg.micro.zdrowotna",
    "priority": 110101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81b_r3_pass", false) == true
}

# jdg.micro.zdrowotna.a81b.r4: zdrowotna_a81b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r4",
    "package": "jdg.micro.zdrowotna",
    "priority": 110102,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81b_r4_checks", false) == true
}

# jdg.micro.zdrowotna.a81b.r5: zdrowotna_a81b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r5",
    "package": "jdg.micro.zdrowotna",
    "priority": 110103,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_applies", false) == false
}

# jdg.micro.zdrowotna.a81b.r6: zdrowotna_a81b_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r6",
    "package": "jdg.micro.zdrowotna",
    "priority": 110104,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_2", false) == false
}

# jdg.micro.zdrowotna.a81b.r7: zdrowotna_a81b_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r7",
    "package": "jdg.micro.zdrowotna",
    "priority": 110105,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zdrowotna_a81b_exception", false) == true
}

# jdg.micro.zdrowotna.a81b.r8: zdrowotna_a81b_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r8",
    "package": "jdg.micro.zdrowotna",
    "priority": 110106,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zdrowotna_a81b_exception_2", false) == true
}

# jdg.micro.zdrowotna.a81b.r9: zdrowotna_a81b_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r9",
    "package": "jdg.micro.zdrowotna",
    "priority": 110107,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_zdrowotna", false) == true
}

# jdg.micro.zdrowotna.a81b.r10: zdrowotna_a81b_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81b.r10",
    "package": "jdg.micro.zdrowotna",
    "priority": 110108,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — liniowy: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_zdrowotna", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗