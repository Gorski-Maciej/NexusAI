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
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)                                                   ║
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Definicja ryczałtu: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a4_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a6 — Limit przychodu 2 mln EUR (10 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)                                                   ║
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Limit przychodu 2 mln EUR: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ryczalt", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a8 — Wyłączenia z ryczałtu (15 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)                                                   ║
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Wyłączenia z ryczałtu: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "ryczalt_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a12 — Stawki per PKWiU (18 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)                                                   ║
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Stawki per PKWiU: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a12_r18_pass", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a15 — Ewidencja ryczałtowa (10 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)                                                   ║
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 15 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Ewidencja ryczałtowa: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ryczalt", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a21 — Karta podatkowa — stawki (12 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)                                                   ║
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Karta podatkowa — stawki: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a21_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a27 — Karta podatkowa — warunki (12 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)                                                   ║
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 27 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Karta podatkowa — warunki: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_a27_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a30 — Utrata prawa do ryczałtu (8 reguł)                                    ║
# ║  Legal basis: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)                                                   ║
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
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
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
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Utrata prawa do ryczałtu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ryczalt_a30_exception_2", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (50 reguł)       ║
# ║  Priorytety: 50000-50049                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.ryc.a22.u1.p1 — `ryc_a22_u1_p1`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a22.u1.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a22_u1_p1_check", false) == true
}
# jdg.ryc.a22.u2.p2 — `ryc_a22_u2_p2`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a22.u2.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a22_u2_p2_check", false) == true
}
# jdg.ryc.a22.u3.p3 — `ryc_a22_u3_p3`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a22.u3.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a22_u3_p3_check", false) == true
}
# jdg.ryc.a22.u4.p4 — `ryc_a22_u4_p4`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a22.u4.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a22_u4_p4_check", false) == true
}
# jdg.ryc.a23.u1.p2 — `ryc_a23_u1_p2`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a23.u1.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a23_u1_p2_check", false) == true
}
# jdg.ryc.a23.u2.p3 — `ryc_a23_u2_p3`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a23.u2.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a23_u2_p3_check", false) == true
}
# jdg.ryc.a23.u3.p4 — `ryc_a23_u3_p4`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a23.u3.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a23_u3_p4_check", false) == true
}
# jdg.ryc.a23.u5.p1 — `ryc_a23_u5_p1`: Art. 23 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a23.u5.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 23 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 23: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a23_u5_p1_check", false) == true
}
# jdg.ryc.a24.u1.p3 — `ryc_a24_u1_p3`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a24.u1.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a24_u1_p3_check", false) == true
}
# jdg.ryc.a24.u2.p4 — `ryc_a24_u2_p4`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a24.u2.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a24_u2_p4_check", false) == true
}
# jdg.ryc.a24.u4.p1 — `ryc_a24_u4_p1`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a24.u4.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a24_u4_p1_check", false) == true
}
# jdg.ryc.a24.u5.p2 — `ryc_a24_u5_p2`: Art. 24 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a24.u5.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 24 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 24: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a24_u5_p2_check", false) == true
}
# jdg.ryc.a25.u1.p4 — `ryc_a25_u1_p4`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a25.u1.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a25_u1_p4_check", false) == true
}
# jdg.ryc.a25.u3.p1 — `ryc_a25_u3_p1`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a25.u3.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a25_u3_p1_check", false) == true
}
# jdg.ryc.a25.u4.p2 — `ryc_a25_u4_p2`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a25.u4.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a25_u4_p2_check", false) == true
}
# jdg.ryc.a25.u5.p3 — `ryc_a25_u5_p3`: Art. 25 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a25.u5.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 25 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 25: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a25_u5_p3_check", false) == true
}
# jdg.ryc.a26.u2.p1 — `ryc_a26_u2_p1`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a26.u2.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a26_u2_p1_check", false) == true
}
# jdg.ryc.a26.u3.p2 — `ryc_a26_u3_p2`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a26.u3.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a26_u3_p2_check", false) == true
}
# jdg.ryc.a26.u4.p3 — `ryc_a26_u4_p3`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a26.u4.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a26_u4_p3_check", false) == true
}
# jdg.ryc.a26.u5.p4 — `ryc_a26_u5_p4`: Art. 26 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a26.u5.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 26 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 26: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a26_u5_p4_check", false) == true
}
# jdg.ryc.a27.u1.p1 — `ryc_a27_u1_p1`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a27.u1.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a27_u1_p1_check", false) == true
}
# jdg.ryc.a27.u2.p2 — `ryc_a27_u2_p2`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a27.u2.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a27_u2_p2_check", false) == true
}
# jdg.ryc.a27.u3.p3 — `ryc_a27_u3_p3`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a27.u3.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a27_u3_p3_check", false) == true
}
# jdg.ryc.a27.u4.p4 — `ryc_a27_u4_p4`: Art. 27 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a27.u4.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 27 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 27: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a27_u4_p4_check", false) == true
}
# jdg.ryc.a28.u1.p2 — `ryc_a28_u1_p2`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a28.u1.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a28_u1_p2_check", false) == true
}
# jdg.ryc.a28.u2.p3 — `ryc_a28_u2_p3`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a28.u2.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a28_u2_p3_check", false) == true
}
# jdg.ryc.a28.u3.p4 — `ryc_a28_u3_p4`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a28.u3.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a28_u3_p4_check", false) == true
}
# jdg.ryc.a28.u5.p1 — `ryc_a28_u5_p1`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a28.u5.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a28_u5_p1_check", false) == true
}
# jdg.ryc.a29.u1.p3 — `ryc_a29_u1_p3`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a29.u1.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a29_u1_p3_check", false) == true
}
# jdg.ryc.a29.u2.p4 — `ryc_a29_u2_p4`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a29.u2.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a29_u2_p4_check", false) == true
}
# jdg.ryc.a29.u4.p1 — `ryc_a29_u4_p1`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a29.u4.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a29_u4_p1_check", false) == true
}
# jdg.ryc.a29.u5.p2 — `ryc_a29_u5_p2`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a29.u5.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a29_u5_p2_check", false) == true
}
# jdg.ryc.a30.u1.p4 — `ryc_a30_u1_p4`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a30.u1.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a30_u1_p4_check", false) == true
}
# jdg.ryc.a30.u3.p1 — `ryc_a30_u3_p1`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a30.u3.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a30_u3_p1_check", false) == true
}
# jdg.ryc.a30.u4.p2 — `ryc_a30_u4_p2`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a30.u4.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a30_u4_p2_check", false) == true
}
# jdg.ryc.a30.u5.p3 — `ryc_a30_u5_p3`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a30.u5.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a30_u5_p3_check", false) == true
}
# jdg.ryc.a31.u2.p1 — `ryc_a31_u2_p1`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a31.u2.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a31_u2_p1_check", false) == true
}
# jdg.ryc.a31.u3.p2 — `ryc_a31_u3_p2`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a31.u3.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a31_u3_p2_check", false) == true
}
# jdg.ryc.a31.u4.p3 — `ryc_a31_u4_p3`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a31.u4.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a31_u4_p3_check", false) == true
}
# jdg.ryc.a31.u5.p4 — `ryc_a31_u5_p4`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a31.u5.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a31_u5_p4_check", false) == true
}
# jdg.ryc.a32.u1.p1 — `ryc_a32_u1_p1`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a32.u1.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a32_u1_p1_check", false) == true
}
# jdg.ryc.a32.u2.p2 — `ryc_a32_u2_p2`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a32.u2.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a32_u2_p2_check", false) == true
}
# jdg.ryc.a32.u3.p3 — `ryc_a32_u3_p3`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a32.u3.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a32_u3_p3_check", false) == true
}
# jdg.ryc.a32.u4.p4 — `ryc_a32_u4_p4`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a32.u4.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a32_u4_p4_check", false) == true
}
# jdg.ryc.a33.u1.p2 — `ryc_a33_u1_p2`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a33.u1.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a33_u1_p2_check", false) == true
}
# jdg.ryc.a33.u2.p3 — `ryc_a33_u2_p3`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a33.u2.p3",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a33_u2_p3_check", false) == true
}
# jdg.ryc.a33.u3.p4 — `ryc_a33_u3_p4`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a33.u3.p4",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a33_u3_p4_check", false) == true
}
# jdg.ryc.a33.u5.p1 — `ryc_a33_u5_p1`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a33.u5.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a33_u5_p1_check", false) == true
}
# jdg.ryc.a34.u4.p1 — `ryc_a34_u4_p1`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a34.u4.p1",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a34_u4_p1_check", false) == true
}
# jdg.ryc.a34.u5.p2 — `ryc_a34_u5_p2`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ryc.a34.u5.p2",
    "package": "jdg.micro.ryczalt",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ryc_a34_u5_p2_check", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a6kurs — Kurs EUR do limitu 2 mln EUR (3 reguły) P24 L-RYC-1      ║
# ║  Legal basis: Art. 6 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a6kurs.r1: ryczalt_a6kurs_r1_nbp_rate_oct1
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6kurs.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100600,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "eur_limit_amount": 2000000,
    "eur_nbp_rate_date": "",
    "_routing": "",
    "_routing_reason": "Kurs NBP z 1 października — przelicznik limitu 2 mln EUR na PLN dla ryczałtu",
    "_legal_basis": "Art. 6 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] L-RYC-1: Limit 2 mln EUR przelicza się po KURSIE NBP z 1 października roku poprzedzającego rok podatkowy. Aktualny kurs: sprawdź na nbp.pl."]
} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "RYCZALT"
    object.get(input.jdg_entrepreneur, "ryczalt_limit_check_needed", false) == true
}

# jdg.micro.ryczalt.a6kurs.r2: ryczalt_a6kurs_r2_limit_exceeded_pln
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6kurs.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100601,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczenie limitu ryczałtu 2 mln EUR — utrata prawa od miesiąca następującego po przekroczeniu",
    "_legal_basis": "Art. 6 ust. 4 w zw. z art. 8 ust. 2 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] L-RYC-1: PRZEKROCZENIE limitu 2 mln EUR! Od miesiąca następującego po przekroczeniu przechodzisz na skalę podatkową. Obowiązek prowadzenia KPiR od dnia utraty ryczałtu."]
} {
    object.get(input.jdg_entrepreneur, "ryczalt_annual_revenue_pln", 0) > (2000000 * object.get(input, "eur_nbp_rate_oct1", 4.5))
}

# jdg.micro.ryczalt.a6kurs.r3: ryczalt_a6kurs_r3_rate_cache_warning
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a6kurs.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100602,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Kurs EUR nie został zaktualizowany — użyto wartości domyślnej 4.50 PLN",
    "_legal_basis": "Art. 6 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.) — NBP Tabela A z 1.10",
    "_warnings": ["[MICRO] L-RYC-1: Użyto domyślnego kursu EUR 4.50 PLN. Rzeczywisty kurs pobierz z NBP (Tabela A z 1 października). Błędny kurs = błędne ustalenie limitu = ryzyko sankcji."]
} {
    object.get(input, "eur_nbp_rate_oct1", null) == null
    object.get(input.jdg_entrepreneur, "tax_form", "") == "RYCZALT"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ryczalt.a29 — Karta podatkowa: zgłoszenie 14 dni (5 reguł) P24 L-RYC-3  ║
# ║  Legal basis: Art. 29 ust. 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ryczalt.a29.r1: ryczalt_a29_r1_tax_card_14day_deadline
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a29.r1",
    "package": "jdg.micro.ryczalt",
    "priority": 100500,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "KARTA_PODATKOWA",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "PIT-16A",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "L-RYC-3: Karta podatkowa — termin 14 dni na zgłoszenie PRZEKROCZONY",
    "_legal_basis": "Art. 29 ust. 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] L-RYC-3: Zgłoszenie karty podatkowej (PIT-16) należy złożyć na 14 DNI przed rozpoczęciem działalności. Przekroczenie = brak możliwości skorzystania z karty w danym roku!"]
} {
    object.get(input.jdg_entrepreneur, "tax_card_selected", false) == true
    object.get(input.jdg_entrepreneur, "tax_card_filed", false) == false
    object.get(input.jdg_entrepreneur, "days_before_business_start", 0) < 14
    object.get(input.jdg_entrepreneur, "business_not_started", false) == true
}

# jdg.micro.ryczalt.a29.r2: ryczalt_a29_r2_tax_card_scope_limited
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a29.r2",
    "package": "jdg.micro.ryczalt",
    "priority": 100501,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "KARTA_PODATKOWA",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "L-RYC-3: Karta podatkowa — ograniczenia zakresu działalności",
    "_legal_basis": "Art. 21-25 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] L-RYC-3: Karta podatkowa dostępna TYLKO dla: handlu detalicznego, gastronomii, usług transportowych, niektórych wolnych zawodów. Limit zatrudnienia: max 2 pracowników."]
} {
    object.get(input.jdg_entrepreneur, "tax_card_selected", false) == true
    object.get(input.jdg_entrepreneur, "tax_card_employees_count", 0) > 2
}

# jdg.micro.ryczalt.a29.r3: ryczalt_a29_r3_tax_card_monthly_rates
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a29.r3",
    "package": "jdg.micro.ryczalt",
    "priority": 100502,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "KARTA_PODATKOWA",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "PIT-16A",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "L-RYC-3: Karta podatkowa — stawki miesięczne wg Art. 23-26",
    "_legal_basis": "Art. 23-26 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.) — tabele stawek miesięcznych",
    "_warnings": ["[MICRO] L-RYC-3: Stawki karty podatkowej zależą od: rodzaju działalności, liczby mieszkańców gminy, liczby zatrudnionych. Formularz PIT-16 składa się do US właściwego dla miejsca zamieszkania."]
} {
    object.get(input.jdg_entrepreneur, "tax_card_selected", false) == true
}

# jdg.micro.ryczalt.a29.r4: ryczalt_a29_r4_tax_card_no_ledger
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a29.r4",
    "package": "jdg.micro.ryczalt",
    "priority": 100503,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "KARTA_PODATKOWA",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "L-RYC-3: Karta podatkowa — brak obowiązku ewidencji przychodów",
    "_legal_basis": "Art. 24 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[MICRO] L-RYC-3: Karta podatkowa = BRAK obowiązku prowadzenia ewidencji przychodów. Wystarczy przechowywać faktury zakupowe przez 5 lat."]
} {
    object.get(input.jdg_entrepreneur, "tax_card_selected", false) == true
    object.get(input.jdg_entrepreneur, "ledger_being_kept", false) == true
}

# jdg.micro.ryczalt.a29.r5: ryczalt_a29_r5_tax_card_loss_of_right
else := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt.a29.r5",
    "package": "jdg.micro.ryczalt",
    "priority": 100504,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "L-RYC-3: Karta podatkowa — UTRATA prawa",
    "_legal_basis": "Art. 30 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.) — utrata prawa do karty",
    "_warnings": ["[MICRO] L-RYC-3: UTRATA prawa do karty podatkowej! Przyczyny: przekroczenie limitu zatrudnienia, zmiana zakresu działalności poza katalog, prowadzenie innej działalności. Powrót do karty możliwy dopiero po 2 latach."]
} {
    object.get(input.jdg_entrepreneur, "tax_card_lost_right", false) == true
}