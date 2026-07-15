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
# ║  zdrowotna.a79 — Obowiązek składki zdrowotnej (10 reguł)                                    ║
# ║  Legal basis: Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zdrowotna.a79.r1: zdrowotna_a79_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r1",
    "package": "jdg.micro.zdrowotna",
    "priority": 110079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zdrowotna.a79.r2: zdrowotna_a79_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r2",
    "package": "jdg.micro.zdrowotna",
    "priority": 110080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_condition_met", false) == true
}

# jdg.micro.zdrowotna.a79.r3: zdrowotna_a79_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r3",
    "package": "jdg.micro.zdrowotna",
    "priority": 110081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a79_r3_pass", false) == true
}

# jdg.micro.zdrowotna.a79.r4: zdrowotna_a79_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r4",
    "package": "jdg.micro.zdrowotna",
    "priority": 110082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a79_r4_checks", false) == true
}

# jdg.micro.zdrowotna.a79.r5: zdrowotna_a79_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r5",
    "package": "jdg.micro.zdrowotna",
    "priority": 110083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_applies", false) == false
}

# jdg.micro.zdrowotna.a79.r6: zdrowotna_a79_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r6",
    "package": "jdg.micro.zdrowotna",
    "priority": 110084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_2", false) == false
}

# jdg.micro.zdrowotna.a79.r7: zdrowotna_a79_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r7",
    "package": "jdg.micro.zdrowotna",
    "priority": 110085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zdrowotna_a79_exception", false) == true
}

# jdg.micro.zdrowotna.a79.r8: zdrowotna_a79_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r8",
    "package": "jdg.micro.zdrowotna",
    "priority": 110086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zdrowotna_a79_exception_2", false) == true
}

# jdg.micro.zdrowotna.a79.r9: zdrowotna_a79_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r9",
    "package": "jdg.micro.zdrowotna",
    "priority": 110087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_zdrowotna", false) == true
}

# jdg.micro.zdrowotna.a79.r10: zdrowotna_a79_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.r10",
    "package": "jdg.micro.zdrowotna",
    "priority": 110088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Obowiązek składki zdrowotnej: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_zdrowotna", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  zdrowotna.a81 — Podstawa wymiaru — skala (10 reguł)                                    ║
# ║  Legal basis: Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zdrowotna.a81.r1: zdrowotna_a81_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r1",
    "package": "jdg.micro.zdrowotna",
    "priority": 110089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zdrowotna.a81.r2: zdrowotna_a81_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r2",
    "package": "jdg.micro.zdrowotna",
    "priority": 110090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_condition_met", false) == true
}

# jdg.micro.zdrowotna.a81.r3: zdrowotna_a81_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r3",
    "package": "jdg.micro.zdrowotna",
    "priority": 110091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81_r3_pass", false) == true
}

# jdg.micro.zdrowotna.a81.r4: zdrowotna_a81_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r4",
    "package": "jdg.micro.zdrowotna",
    "priority": 110092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a81_r4_checks", false) == true
}

# jdg.micro.zdrowotna.a81.r5: zdrowotna_a81_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r5",
    "package": "jdg.micro.zdrowotna",
    "priority": 110093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_applies", false) == false
}

# jdg.micro.zdrowotna.a81.r6: zdrowotna_a81_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r6",
    "package": "jdg.micro.zdrowotna",
    "priority": 110094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_2", false) == false
}

# jdg.micro.zdrowotna.a81.r7: zdrowotna_a81_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r7",
    "package": "jdg.micro.zdrowotna",
    "priority": 110095,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zdrowotna_a81_exception", false) == true
}

# jdg.micro.zdrowotna.a81.r8: zdrowotna_a81_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r8",
    "package": "jdg.micro.zdrowotna",
    "priority": 110096,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zdrowotna_a81_exception_2", false) == true
}

# jdg.micro.zdrowotna.a81.r9: zdrowotna_a81_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r9",
    "package": "jdg.micro.zdrowotna",
    "priority": 110097,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_zdrowotna", false) == true
}

# jdg.micro.zdrowotna.a81.r10: zdrowotna_a81_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81.r10",
    "package": "jdg.micro.zdrowotna",
    "priority": 110098,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Podstawa wymiaru — skala: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_zdrowotna", false) == true
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
# ║  zdrowotna.a82 — Zdrowotna przy zawieszeniu (8 reguł)                                    ║
# ║  Legal basis: Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zdrowotna.a82.r1: zdrowotna_a82_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a82.r1",
    "package": "jdg.micro.zdrowotna",
    "priority": 110133,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Zdrowotna przy zawieszeniu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zdrowotna.a82.r2: zdrowotna_a82_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a82.r2",
    "package": "jdg.micro.zdrowotna",
    "priority": 110134,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Zdrowotna przy zawieszeniu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_condition_met", false) == true
}

# jdg.micro.zdrowotna.a82.r3: zdrowotna_a82_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a82.r3",
    "package": "jdg.micro.zdrowotna",
    "priority": 110135,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Zdrowotna przy zawieszeniu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a82_r3_pass", false) == true
}

# jdg.micro.zdrowotna.a82.r4: zdrowotna_a82_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a82.r4",
    "package": "jdg.micro.zdrowotna",
    "priority": 110136,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Zdrowotna przy zawieszeniu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zdrowotna_a82_r4_checks", false) == true
}

# jdg.micro.zdrowotna.a82.r5: zdrowotna_a82_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a82.r5",
    "package": "jdg.micro.zdrowotna",
    "priority": 110137,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Zdrowotna przy zawieszeniu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_applies", false) == false
}

# jdg.micro.zdrowotna.a82.r6: zdrowotna_a82_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a82.r6",
    "package": "jdg.micro.zdrowotna",
    "priority": 110138,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Zdrowotna przy zawieszeniu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zdrowotna_exclusion_2", false) == false
}

# jdg.micro.zdrowotna.a82.r7: zdrowotna_a82_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a82.r7",
    "package": "jdg.micro.zdrowotna",
    "priority": 110139,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Zdrowotna przy zawieszeniu: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zdrowotna_a82_exception", false) == true
}

# jdg.micro.zdrowotna.a82.r8: zdrowotna_a82_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a82.r8",
    "package": "jdg.micro.zdrowotna",
    "priority": 110140,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
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
    "_warnings": ["[MICRO] Zdrowotna przy zawieszeniu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zdrowotna_a82_exception_2", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (74 reguł)       ║
# ║  Priorytety: 50000-50073                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.zdr.a10.u1.p2 — `zdr_a10_u1_p2`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a10.u1.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50000,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 10 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a10_u1_p2_check", false) == true
}
# jdg.zdr.a10.u2.p3 — `zdr_a10_u2_p3`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a10.u2.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 10 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a10_u2_p3_check", false) == true
}
# jdg.zdr.a10.u4.p4 — `zdr_a10_u4_p4`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a10.u4.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 10 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a10_u4_p4_check", false) == true
}
# jdg.zdr.a10.u5.p1 — `zdr_a10_u5_p1`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a10.u5.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 10 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a10_u5_p1_check", false) == true
}
# jdg.zdr.a11.u1.p1 — `zdr_a11_u1_p1`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a11.u1.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a11_u1_p1_check", false) == true
}
# jdg.zdr.a11.u1.p3 — `zdr_a11_u1_p3`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a11.u1.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a11_u1_p3_check", false) == true
}
# jdg.zdr.a11.u2.p2 — `zdr_a11_u2_p2`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a11.u2.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a11_u2_p2_check", false) == true
}
# jdg.zdr.a11.u3.p3 — `zdr_a11_u3_p3`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a11.u3.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a11_u3_p3_check", false) == true
}
# jdg.zdr.a11.u3.p4 — `zdr_a11_u3_p4`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a11.u3.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a11_u3_p4_check", false) == true
}
# jdg.zdr.a11.u4.p1 — `zdr_a11_u4_p1`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a11.u4.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a11_u4_p1_check", false) == true
}
# jdg.zdr.a11.u4.p4 — `zdr_a11_u4_p4`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a11.u4.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a11_u4_p4_check", false) == true
}
# jdg.zdr.a11.u5.p2 — `zdr_a11_u5_p2`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a11.u5.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 11 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a11_u5_p2_check", false) == true
}
# jdg.zdr.a12.u1.p2 — `zdr_a12_u1_p2`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a12.u1.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a12_u1_p2_check", false) == true
}
# jdg.zdr.a12.u2.p3 — `zdr_a12_u2_p3`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a12.u2.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a12_u2_p3_check", false) == true
}
# jdg.zdr.a12.u2.p4 — `zdr_a12_u2_p4`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a12.u2.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a12_u2_p4_check", false) == true
}
# jdg.zdr.a12.u3.p1 — `zdr_a12_u3_p1`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a12.u3.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a12_u3_p1_check", false) == true
}
# jdg.zdr.a12.u3.p4 — `zdr_a12_u3_p4`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a12.u3.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a12_u3_p4_check", false) == true
}
# jdg.zdr.a12.u4.p2 — `zdr_a12_u4_p2`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a12.u4.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a12_u4_p2_check", false) == true
}
# jdg.zdr.a12.u5.p1 — `zdr_a12_u5_p1`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a12.u5.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a12_u5_p1_check", false) == true
}
# jdg.zdr.a12.u5.p3 — `zdr_a12_u5_p3`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a12.u5.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a12_u5_p3_check", false) == true
}
# jdg.zdr.a13.u1.p3 — `zdr_a13_u1_p3`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a13.u1.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a13_u1_p3_check", false) == true
}
# jdg.zdr.a13.u1.p4 — `zdr_a13_u1_p4`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a13.u1.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a13_u1_p4_check", false) == true
}
# jdg.zdr.a13.u2.p1 — `zdr_a13_u2_p1`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a13.u2.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a13_u2_p1_check", false) == true
}
# jdg.zdr.a13.u2.p4 — `zdr_a13_u2_p4`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a13.u2.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a13_u2_p4_check", false) == true
}
# jdg.zdr.a13.u3.p2 — `zdr_a13_u3_p2`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a13.u3.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a13_u3_p2_check", false) == true
}
# jdg.zdr.a13.u4.p1 — `zdr_a13_u4_p1`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a13.u4.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a13_u4_p1_check", false) == true
}
# jdg.zdr.a13.u4.p3 — `zdr_a13_u4_p3`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a13.u4.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a13_u4_p3_check", false) == true
}
# jdg.zdr.a13.u5.p2 — `zdr_a13_u5_p2`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a13.u5.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a13_u5_p2_check", false) == true
}
# jdg.zdr.a14.u1.p1 — `zdr_a14_u1_p1`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a14.u1.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a14_u1_p1_check", false) == true
}
# jdg.zdr.a14.u1.p4 — `zdr_a14_u1_p4`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a14.u1.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a14_u1_p4_check", false) == true
}
# jdg.zdr.a14.u2.p2 — `zdr_a14_u2_p2`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a14.u2.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a14_u2_p2_check", false) == true
}
# jdg.zdr.a14.u3.p1 — `zdr_a14_u3_p1`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a14.u3.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a14_u3_p1_check", false) == true
}
# jdg.zdr.a14.u3.p3 — `zdr_a14_u3_p3`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a14.u3.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a14_u3_p3_check", false) == true
}
# jdg.zdr.a14.u4.p2 — `zdr_a14_u4_p2`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a14.u4.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a14_u4_p2_check", false) == true
}
# jdg.zdr.a14.u5.p3 — `zdr_a14_u5_p3`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a14.u5.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a14_u5_p3_check", false) == true
}
# jdg.zdr.a14.u5.p4 — `zdr_a14_u5_p4`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a14.u5.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a14_u5_p4_check", false) == true
}
# jdg.zdr.a15.u1.p2 — `zdr_a15_u1_p2`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a15.u1.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a15_u1_p2_check", false) == true
}
# jdg.zdr.a15.u2.p1 — `zdr_a15_u2_p1`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a15.u2.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a15_u2_p1_check", false) == true
}
# jdg.zdr.a15.u2.p3 — `zdr_a15_u2_p3`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a15.u2.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a15_u2_p3_check", false) == true
}
# jdg.zdr.a15.u3.p2 — `zdr_a15_u3_p2`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a15.u3.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a15_u3_p2_check", false) == true
}
# jdg.zdr.a15.u4.p3 — `zdr_a15_u4_p3`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a15.u4.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a15_u4_p3_check", false) == true
}
# jdg.zdr.a15.u4.p4 — `zdr_a15_u4_p4`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a15.u4.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a15_u4_p4_check", false) == true
}
# jdg.zdr.a15.u5.p1 — `zdr_a15_u5_p1`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a15.u5.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a15_u5_p1_check", false) == true
}
# jdg.zdr.a15.u5.p4 — `zdr_a15_u5_p4`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a15.u5.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a15_u5_p4_check", false) == true
}
# jdg.zdr.a16.u1.p1 — `zdr_a16_u1_p1`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a16.u1.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a16_u1_p1_check", false) == true
}
# jdg.zdr.a16.u1.p3 — `zdr_a16_u1_p3`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a16.u1.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a16_u1_p3_check", false) == true
}
# jdg.zdr.a16.u2.p2 — `zdr_a16_u2_p2`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a16.u2.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a16_u2_p2_check", false) == true
}
# jdg.zdr.a16.u3.p3 — `zdr_a16_u3_p3`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a16.u3.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a16_u3_p3_check", false) == true
}
# jdg.zdr.a16.u3.p4 — `zdr_a16_u3_p4`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a16.u3.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a16_u3_p4_check", false) == true
}
# jdg.zdr.a16.u4.p1 — `zdr_a16_u4_p1`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a16.u4.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a16_u4_p1_check", false) == true
}
# jdg.zdr.a16.u4.p4 — `zdr_a16_u4_p4`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a16.u4.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a16_u4_p4_check", false) == true
}
# jdg.zdr.a16.u5.p2 — `zdr_a16_u5_p2`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a16.u5.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a16_u5_p2_check", false) == true
}
# jdg.zdr.a17.u1.p2 — `zdr_a17_u1_p2`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a17.u1.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a17_u1_p2_check", false) == true
}
# jdg.zdr.a17.u2.p3 — `zdr_a17_u2_p3`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a17.u2.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a17_u2_p3_check", false) == true
}
# jdg.zdr.a17.u2.p4 — `zdr_a17_u2_p4`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a17.u2.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a17_u2_p4_check", false) == true
}
# jdg.zdr.a17.u3.p1 — `zdr_a17_u3_p1`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a17.u3.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a17_u3_p1_check", false) == true
}
# jdg.zdr.a17.u3.p4 — `zdr_a17_u3_p4`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a17.u3.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a17_u3_p4_check", false) == true
}
# jdg.zdr.a17.u4.p2 — `zdr_a17_u4_p2`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a17.u4.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a17_u4_p2_check", false) == true
}
# jdg.zdr.a17.u5.p1 — `zdr_a17_u5_p1`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a17.u5.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a17_u5_p1_check", false) == true
}
# jdg.zdr.a17.u5.p3 — `zdr_a17_u5_p3`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a17.u5.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a17_u5_p3_check", false) == true
}
# jdg.zdr.a18.u1.p4 — `zdr_a18_u1_p4`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a18.u1.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a18_u1_p4_check", false) == true
}
# jdg.zdr.a18.u2.p1 — `zdr_a18_u2_p1`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a18.u2.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a18_u2_p1_check", false) == true
}
# jdg.zdr.a18.u3.p2 — `zdr_a18_u3_p2`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a18.u3.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a18_u3_p2_check", false) == true
}
# jdg.zdr.a18.u4.p1 — `zdr_a18_u4_p1`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a18.u4.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a18_u4_p1_check", false) == true
}
# jdg.zdr.a18.u4.p3 — `zdr_a18_u4_p3`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a18.u4.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a18_u4_p3_check", false) == true
}
# jdg.zdr.a18.u5.p2 — `zdr_a18_u5_p2`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a18.u5.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a18_u5_p2_check", false) == true
}
# jdg.zdr.a19.u1.p1 — `zdr_a19_u1_p1`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a19.u1.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a19_u1_p1_check", false) == true
}
# jdg.zdr.a19.u2.p2 — `zdr_a19_u2_p2`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a19.u2.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a19_u2_p2_check", false) == true
}
# jdg.zdr.a19.u3.p3 — `zdr_a19_u3_p3`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a19.u3.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a19_u3_p3_check", false) == true
}
# jdg.zdr.a19.u5.p4 — `zdr_a19_u5_p4`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a19.u5.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a19_u5_p4_check", false) == true
}
# jdg.zdr.a20.u4.p4 — `zdr_a20_u4_p4`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a20.u4.p4",
    "package": "jdg.micro.zdrowotna",
    "priority": 50070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a20_u4_p4_check", false) == true
}
# jdg.zdr.a9.u1.p1 — `zdr_a9_u1_p1`: Art. 9 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a9.u1.p1",
    "package": "jdg.micro.zdrowotna",
    "priority": 50071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 9 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 9: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a9_u1_p1_check", false) == true
}
# jdg.zdr.a9.u2.p2 — `zdr_a9_u2_p2`: Art. 9 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a9.u2.p2",
    "package": "jdg.micro.zdrowotna",
    "priority": 50072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 9 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 9: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a9_u2_p2_check", false) == true
}
# jdg.zdr.a9.u3.p3 — `zdr_a9_u3_p3`: Art. 9 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.zdr.a9.u3.p3",
    "package": "jdg.micro.zdrowotna",
    "priority": 50073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 9 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o świadczeniach zdrowotnych z 27.08.2004",
    "_warnings": ["[MICRO] Art. 9: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "zdr_a9_u3_p3_check", false) == true
}