# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa o rachunkowości (dla JDG) — 30 artykułów → ~300 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.uor
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.uor

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.uor.no_match",
    "package": "jdg.micro.uor",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a4 — Zakres podmiotowy UoR (8 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a4.r1: uor_a4_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r1",
    "package": "jdg.micro.uor",
    "priority": 160004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zakres podmiotowy UoR: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a4.r2: uor_a4_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r2",
    "package": "jdg.micro.uor",
    "priority": 160005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zakres podmiotowy UoR: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a4.r3: uor_a4_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r3",
    "package": "jdg.micro.uor",
    "priority": 160006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zakres podmiotowy UoR: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a4_r3_pass", false) == true
}

# jdg.micro.uor.a4.r4: uor_a4_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r4",
    "package": "jdg.micro.uor",
    "priority": 160007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zakres podmiotowy UoR: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a4_r4_checks", false) == true
}

# jdg.micro.uor.a4.r5: uor_a4_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r5",
    "package": "jdg.micro.uor",
    "priority": 160008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zakres podmiotowy UoR: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a4.r6: uor_a4_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r6",
    "package": "jdg.micro.uor",
    "priority": 160009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zakres podmiotowy UoR: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a4.r7: uor_a4_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r7",
    "package": "jdg.micro.uor",
    "priority": 160010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zakres podmiotowy UoR: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a4_exception", false) == true
}

# jdg.micro.uor.a4.r8: uor_a4_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r8",
    "package": "jdg.micro.uor",
    "priority": 160011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zakres podmiotowy UoR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a4_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a10 — Polityka rachunkowości (10 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a10.r1: uor_a10_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r1",
    "package": "jdg.micro.uor",
    "priority": 160012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a10.r2: uor_a10_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r2",
    "package": "jdg.micro.uor",
    "priority": 160013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a10.r3: uor_a10_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r3",
    "package": "jdg.micro.uor",
    "priority": 160014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a10_r3_pass", false) == true
}

# jdg.micro.uor.a10.r4: uor_a10_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r4",
    "package": "jdg.micro.uor",
    "priority": 160015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a10_r4_checks", false) == true
}

# jdg.micro.uor.a10.r5: uor_a10_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r5",
    "package": "jdg.micro.uor",
    "priority": 160016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a10.r6: uor_a10_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r6",
    "package": "jdg.micro.uor",
    "priority": 160017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a10.r7: uor_a10_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r7",
    "package": "jdg.micro.uor",
    "priority": 160018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a10_exception", false) == true
}

# jdg.micro.uor.a10.r8: uor_a10_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r8",
    "package": "jdg.micro.uor",
    "priority": 160019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a10_exception_2", false) == true
}

# jdg.micro.uor.a10.r9: uor_a10_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r9",
    "package": "jdg.micro.uor",
    "priority": 160020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a10.r10: uor_a10_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r10",
    "package": "jdg.micro.uor",
    "priority": 160021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Polityka rachunkowości: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a20 — Dowody księgowe (10 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a20.r1: uor_a20_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r1",
    "package": "jdg.micro.uor",
    "priority": 160022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a20.r2: uor_a20_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r2",
    "package": "jdg.micro.uor",
    "priority": 160023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a20.r3: uor_a20_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r3",
    "package": "jdg.micro.uor",
    "priority": 160024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a20_r3_pass", false) == true
}

# jdg.micro.uor.a20.r4: uor_a20_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r4",
    "package": "jdg.micro.uor",
    "priority": 160025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a20_r4_checks", false) == true
}

# jdg.micro.uor.a20.r5: uor_a20_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r5",
    "package": "jdg.micro.uor",
    "priority": 160026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a20.r6: uor_a20_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r6",
    "package": "jdg.micro.uor",
    "priority": 160027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a20.r7: uor_a20_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r7",
    "package": "jdg.micro.uor",
    "priority": 160028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a20_exception", false) == true
}

# jdg.micro.uor.a20.r8: uor_a20_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r8",
    "package": "jdg.micro.uor",
    "priority": 160029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a20_exception_2", false) == true
}

# jdg.micro.uor.a20.r9: uor_a20_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r9",
    "package": "jdg.micro.uor",
    "priority": 160030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a20.r10: uor_a20_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r10",
    "package": "jdg.micro.uor",
    "priority": 160031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Dowody księgowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a22 — Rzetelność ksiąg (12 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a22.r1: uor_a22_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r1",
    "package": "jdg.micro.uor",
    "priority": 160032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a22.r2: uor_a22_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r2",
    "package": "jdg.micro.uor",
    "priority": 160033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a22.r3: uor_a22_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r3",
    "package": "jdg.micro.uor",
    "priority": 160034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a22_r3_pass", false) == true
}

# jdg.micro.uor.a22.r4: uor_a22_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r4",
    "package": "jdg.micro.uor",
    "priority": 160035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a22_r4_checks", false) == true
}

# jdg.micro.uor.a22.r5: uor_a22_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r5",
    "package": "jdg.micro.uor",
    "priority": 160036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a22.r6: uor_a22_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r6",
    "package": "jdg.micro.uor",
    "priority": 160037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a22.r7: uor_a22_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r7",
    "package": "jdg.micro.uor",
    "priority": 160038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a22_exception", false) == true
}

# jdg.micro.uor.a22.r8: uor_a22_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r8",
    "package": "jdg.micro.uor",
    "priority": 160039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a22_exception_2", false) == true
}

# jdg.micro.uor.a22.r9: uor_a22_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r9",
    "package": "jdg.micro.uor",
    "priority": 160040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a22.r10: uor_a22_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r10",
    "package": "jdg.micro.uor",
    "priority": 160041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}

# jdg.micro.uor.a22.r11: uor_a22_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r11",
    "package": "jdg.micro.uor",
    "priority": 160042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "uor_deadline_required", false) == true
}

# jdg.micro.uor.a22.r12: uor_a22_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r12",
    "package": "jdg.micro.uor",
    "priority": 160043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie Rzetelność ksiąg",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rzetelność ksiąg: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "uor_a22_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a24 — Zasada ostrożności (10 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a24.r1: uor_a24_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r1",
    "package": "jdg.micro.uor",
    "priority": 160044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a24.r2: uor_a24_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r2",
    "package": "jdg.micro.uor",
    "priority": 160045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a24.r3: uor_a24_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r3",
    "package": "jdg.micro.uor",
    "priority": 160046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a24_r3_pass", false) == true
}

# jdg.micro.uor.a24.r4: uor_a24_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r4",
    "package": "jdg.micro.uor",
    "priority": 160047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a24_r4_checks", false) == true
}

# jdg.micro.uor.a24.r5: uor_a24_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r5",
    "package": "jdg.micro.uor",
    "priority": 160048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a24.r6: uor_a24_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r6",
    "package": "jdg.micro.uor",
    "priority": 160049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a24.r7: uor_a24_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r7",
    "package": "jdg.micro.uor",
    "priority": 160050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a24_exception", false) == true
}

# jdg.micro.uor.a24.r8: uor_a24_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r8",
    "package": "jdg.micro.uor",
    "priority": 160051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a24_exception_2", false) == true
}

# jdg.micro.uor.a24.r9: uor_a24_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r9",
    "package": "jdg.micro.uor",
    "priority": 160052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a24.r10: uor_a24_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r10",
    "package": "jdg.micro.uor",
    "priority": 160053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Zasada ostrożności: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a26 — Inwentaryzacja (12 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a26.r1: uor_a26_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r1",
    "package": "jdg.micro.uor",
    "priority": 160054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a26.r2: uor_a26_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r2",
    "package": "jdg.micro.uor",
    "priority": 160055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a26.r3: uor_a26_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r3",
    "package": "jdg.micro.uor",
    "priority": 160056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a26_r3_pass", false) == true
}

# jdg.micro.uor.a26.r4: uor_a26_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r4",
    "package": "jdg.micro.uor",
    "priority": 160057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a26_r4_checks", false) == true
}

# jdg.micro.uor.a26.r5: uor_a26_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r5",
    "package": "jdg.micro.uor",
    "priority": 160058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a26.r6: uor_a26_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r6",
    "package": "jdg.micro.uor",
    "priority": 160059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a26.r7: uor_a26_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r7",
    "package": "jdg.micro.uor",
    "priority": 160060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a26_exception", false) == true
}

# jdg.micro.uor.a26.r8: uor_a26_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r8",
    "package": "jdg.micro.uor",
    "priority": 160061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a26_exception_2", false) == true
}

# jdg.micro.uor.a26.r9: uor_a26_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r9",
    "package": "jdg.micro.uor",
    "priority": 160062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a26.r10: uor_a26_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r10",
    "package": "jdg.micro.uor",
    "priority": 160063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}

# jdg.micro.uor.a26.r11: uor_a26_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r11",
    "package": "jdg.micro.uor",
    "priority": 160064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "uor_deadline_required", false) == true
}

# jdg.micro.uor.a26.r12: uor_a26_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r12",
    "package": "jdg.micro.uor",
    "priority": 160065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie Inwentaryzacja",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Inwentaryzacja: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "uor_a26_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a28 — Wycena aktywów (12 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a28.r1: uor_a28_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r1",
    "package": "jdg.micro.uor",
    "priority": 160066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a28.r2: uor_a28_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r2",
    "package": "jdg.micro.uor",
    "priority": 160067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a28.r3: uor_a28_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r3",
    "package": "jdg.micro.uor",
    "priority": 160068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a28_r3_pass", false) == true
}

# jdg.micro.uor.a28.r4: uor_a28_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r4",
    "package": "jdg.micro.uor",
    "priority": 160069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a28_r4_checks", false) == true
}

# jdg.micro.uor.a28.r5: uor_a28_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r5",
    "package": "jdg.micro.uor",
    "priority": 160070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a28.r6: uor_a28_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r6",
    "package": "jdg.micro.uor",
    "priority": 160071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a28.r7: uor_a28_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r7",
    "package": "jdg.micro.uor",
    "priority": 160072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a28_exception", false) == true
}

# jdg.micro.uor.a28.r8: uor_a28_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r8",
    "package": "jdg.micro.uor",
    "priority": 160073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a28_exception_2", false) == true
}

# jdg.micro.uor.a28.r9: uor_a28_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r9",
    "package": "jdg.micro.uor",
    "priority": 160074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a28.r10: uor_a28_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r10",
    "package": "jdg.micro.uor",
    "priority": 160075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}

# jdg.micro.uor.a28.r11: uor_a28_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r11",
    "package": "jdg.micro.uor",
    "priority": 160076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "uor_deadline_required", false) == true
}

# jdg.micro.uor.a28.r12: uor_a28_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r12",
    "package": "jdg.micro.uor",
    "priority": 160077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie Wycena aktywów",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Wycena aktywów: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "uor_a28_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a32 — Różnice kursowe — UoR (8 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a32.r1: uor_a32_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r1",
    "package": "jdg.micro.uor",
    "priority": 160078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Różnice kursowe — UoR: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a32.r2: uor_a32_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r2",
    "package": "jdg.micro.uor",
    "priority": 160079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Różnice kursowe — UoR: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a32.r3: uor_a32_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r3",
    "package": "jdg.micro.uor",
    "priority": 160080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Różnice kursowe — UoR: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a32_r3_pass", false) == true
}

# jdg.micro.uor.a32.r4: uor_a32_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r4",
    "package": "jdg.micro.uor",
    "priority": 160081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Różnice kursowe — UoR: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a32_r4_checks", false) == true
}

# jdg.micro.uor.a32.r5: uor_a32_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r5",
    "package": "jdg.micro.uor",
    "priority": 160082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Różnice kursowe — UoR: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a32.r6: uor_a32_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r6",
    "package": "jdg.micro.uor",
    "priority": 160083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Różnice kursowe — UoR: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a32.r7: uor_a32_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r7",
    "package": "jdg.micro.uor",
    "priority": 160084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Różnice kursowe — UoR: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a32_exception", false) == true
}

# jdg.micro.uor.a32.r8: uor_a32_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r8",
    "package": "jdg.micro.uor",
    "priority": 160085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Różnice kursowe — UoR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a32_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a35 — Sprawozdanie finansowe (12 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a35.r1: uor_a35_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r1",
    "package": "jdg.micro.uor",
    "priority": 160086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a35.r2: uor_a35_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r2",
    "package": "jdg.micro.uor",
    "priority": 160087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a35.r3: uor_a35_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r3",
    "package": "jdg.micro.uor",
    "priority": 160088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a35_r3_pass", false) == true
}

# jdg.micro.uor.a35.r4: uor_a35_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r4",
    "package": "jdg.micro.uor",
    "priority": 160089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a35_r4_checks", false) == true
}

# jdg.micro.uor.a35.r5: uor_a35_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r5",
    "package": "jdg.micro.uor",
    "priority": 160090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a35.r6: uor_a35_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r6",
    "package": "jdg.micro.uor",
    "priority": 160091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a35.r7: uor_a35_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r7",
    "package": "jdg.micro.uor",
    "priority": 160092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a35_exception", false) == true
}

# jdg.micro.uor.a35.r8: uor_a35_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r8",
    "package": "jdg.micro.uor",
    "priority": 160093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a35_exception_2", false) == true
}

# jdg.micro.uor.a35.r9: uor_a35_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r9",
    "package": "jdg.micro.uor",
    "priority": 160094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a35.r10: uor_a35_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r10",
    "package": "jdg.micro.uor",
    "priority": 160095,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}

# jdg.micro.uor.a35.r11: uor_a35_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r11",
    "package": "jdg.micro.uor",
    "priority": 160096,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "uor_deadline_required", false) == true
}

# jdg.micro.uor.a35.r12: uor_a35_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r12",
    "package": "jdg.micro.uor",
    "priority": 160097,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie Sprawozdanie finansowe",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Sprawozdanie finansowe: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "uor_a35_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a39 — Rozliczenia międzyokresowe (10 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a39.r1: uor_a39_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r1",
    "package": "jdg.micro.uor",
    "priority": 160098,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a39.r2: uor_a39_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r2",
    "package": "jdg.micro.uor",
    "priority": 160099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a39.r3: uor_a39_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r3",
    "package": "jdg.micro.uor",
    "priority": 160100,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a39_r3_pass", false) == true
}

# jdg.micro.uor.a39.r4: uor_a39_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r4",
    "package": "jdg.micro.uor",
    "priority": 160101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a39_r4_checks", false) == true
}

# jdg.micro.uor.a39.r5: uor_a39_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r5",
    "package": "jdg.micro.uor",
    "priority": 160102,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a39.r6: uor_a39_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r6",
    "package": "jdg.micro.uor",
    "priority": 160103,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a39.r7: uor_a39_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r7",
    "package": "jdg.micro.uor",
    "priority": 160104,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a39_exception", false) == true
}

# jdg.micro.uor.a39.r8: uor_a39_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r8",
    "package": "jdg.micro.uor",
    "priority": 160105,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a39_exception_2", false) == true
}

# jdg.micro.uor.a39.r9: uor_a39_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r9",
    "package": "jdg.micro.uor",
    "priority": 160106,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a39.r10: uor_a39_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r10",
    "package": "jdg.micro.uor",
    "priority": 160107,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Rozliczenia międzyokresowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a45 — Badanie sprawozdań (10 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a45.r1: uor_a45_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r1",
    "package": "jdg.micro.uor",
    "priority": 160108,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a45.r2: uor_a45_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r2",
    "package": "jdg.micro.uor",
    "priority": 160109,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a45.r3: uor_a45_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r3",
    "package": "jdg.micro.uor",
    "priority": 160110,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a45_r3_pass", false) == true
}

# jdg.micro.uor.a45.r4: uor_a45_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r4",
    "package": "jdg.micro.uor",
    "priority": 160111,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a45_r4_checks", false) == true
}

# jdg.micro.uor.a45.r5: uor_a45_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r5",
    "package": "jdg.micro.uor",
    "priority": 160112,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a45.r6: uor_a45_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r6",
    "package": "jdg.micro.uor",
    "priority": 160113,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a45.r7: uor_a45_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r7",
    "package": "jdg.micro.uor",
    "priority": 160114,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a45_exception", false) == true
}

# jdg.micro.uor.a45.r8: uor_a45_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r8",
    "package": "jdg.micro.uor",
    "priority": 160115,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a45_exception_2", false) == true
}

# jdg.micro.uor.a45.r9: uor_a45_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r9",
    "package": "jdg.micro.uor",
    "priority": 160116,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a45.r10: uor_a45_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r10",
    "package": "jdg.micro.uor",
    "priority": 160117,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Badanie sprawozdań: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  uor.a74 — Przechowywanie dokumentów (10 reguł)                                    ║
# ║  Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a74.r1: uor_a74_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r1",
    "package": "jdg.micro.uor",
    "priority": 160118,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.uor.a74.r2: uor_a74_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r2",
    "package": "jdg.micro.uor",
    "priority": 160119,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "uor_condition_met", false) == true
}

# jdg.micro.uor.a74.r3: uor_a74_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r3",
    "package": "jdg.micro.uor",
    "priority": 160120,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "uor_a74_r3_pass", false) == true
}

# jdg.micro.uor.a74.r4: uor_a74_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r4",
    "package": "jdg.micro.uor",
    "priority": 160121,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "uor_a74_r4_checks", false) == true
}

# jdg.micro.uor.a74.r5: uor_a74_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r5",
    "package": "jdg.micro.uor",
    "priority": 160122,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "uor_exclusion_applies", false) == false
}

# jdg.micro.uor.a74.r6: uor_a74_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r6",
    "package": "jdg.micro.uor",
    "priority": 160123,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "uor_exclusion_2", false) == false
}

# jdg.micro.uor.a74.r7: uor_a74_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r7",
    "package": "jdg.micro.uor",
    "priority": 160124,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "uor_a74_exception", false) == true
}

# jdg.micro.uor.a74.r8: uor_a74_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r8",
    "package": "jdg.micro.uor",
    "priority": 160125,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "uor_a74_exception_2", false) == true
}

# jdg.micro.uor.a74.r9: uor_a74_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r9",
    "package": "jdg.micro.uor",
    "priority": 160126,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_uor", false) == true
}

# jdg.micro.uor.a74.r10: uor_a74_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r10",
    "package": "jdg.micro.uor",
    "priority": 160127,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_uor", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (50 reguł)       ║
# ║  Priorytety: 50000-50049                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.uor.a45.u1.p1 — `uor_a45_u1_p1`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a45.u1.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a45_u1_p1_check", false) == true
}
# jdg.uor.a45.u2.p2 — `uor_a45_u2_p2`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a45.u2.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a45_u2_p2_check", false) == true
}
# jdg.uor.a45.u3.p3 — `uor_a45_u3_p3`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a45.u3.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a45_u3_p3_check", false) == true
}
# jdg.uor.a45.u4.p4 — `uor_a45_u4_p4`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a45.u4.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a45_u4_p4_check", false) == true
}
# jdg.uor.a46.u1.p2 — `uor_a46_u1_p2`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a46.u1.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a46_u1_p2_check", false) == true
}
# jdg.uor.a46.u2.p3 — `uor_a46_u2_p3`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a46.u2.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a46_u2_p3_check", false) == true
}
# jdg.uor.a46.u3.p4 — `uor_a46_u3_p4`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a46.u3.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a46_u3_p4_check", false) == true
}
# jdg.uor.a46.u5.p1 — `uor_a46_u5_p1`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a46.u5.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a46_u5_p1_check", false) == true
}
# jdg.uor.a47.u1.p3 — `uor_a47_u1_p3`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a47.u1.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a47_u1_p3_check", false) == true
}
# jdg.uor.a47.u2.p4 — `uor_a47_u2_p4`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a47.u2.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a47_u2_p4_check", false) == true
}
# jdg.uor.a47.u4.p1 — `uor_a47_u4_p1`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a47.u4.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a47_u4_p1_check", false) == true
}
# jdg.uor.a47.u5.p2 — `uor_a47_u5_p2`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a47.u5.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a47_u5_p2_check", false) == true
}
# jdg.uor.a48.u1.p4 — `uor_a48_u1_p4`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a48.u1.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a48_u1_p4_check", false) == true
}
# jdg.uor.a48.u3.p1 — `uor_a48_u3_p1`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a48.u3.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a48_u3_p1_check", false) == true
}
# jdg.uor.a48.u4.p2 — `uor_a48_u4_p2`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a48.u4.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a48_u4_p2_check", false) == true
}
# jdg.uor.a48.u5.p3 — `uor_a48_u5_p3`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a48.u5.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a48_u5_p3_check", false) == true
}
# jdg.uor.a49.u2.p1 — `uor_a49_u2_p1`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a49.u2.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a49_u2_p1_check", false) == true
}
# jdg.uor.a49.u3.p2 — `uor_a49_u3_p2`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a49.u3.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a49_u3_p2_check", false) == true
}
# jdg.uor.a49.u4.p3 — `uor_a49_u4_p3`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a49.u4.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a49_u4_p3_check", false) == true
}
# jdg.uor.a49.u5.p4 — `uor_a49_u5_p4`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a49.u5.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a49_u5_p4_check", false) == true
}
# jdg.uor.a50.u1.p1 — `uor_a50_u1_p1`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a50.u1.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a50_u1_p1_check", false) == true
}
# jdg.uor.a50.u2.p2 — `uor_a50_u2_p2`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a50.u2.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a50_u2_p2_check", false) == true
}
# jdg.uor.a50.u3.p3 — `uor_a50_u3_p3`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a50.u3.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a50_u3_p3_check", false) == true
}
# jdg.uor.a50.u4.p4 — `uor_a50_u4_p4`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a50.u4.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a50_u4_p4_check", false) == true
}
# jdg.uor.a51.u1.p2 — `uor_a51_u1_p2`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a51.u1.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a51_u1_p2_check", false) == true
}
# jdg.uor.a51.u2.p3 — `uor_a51_u2_p3`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a51.u2.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a51_u2_p3_check", false) == true
}
# jdg.uor.a51.u3.p4 — `uor_a51_u3_p4`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a51.u3.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a51_u3_p4_check", false) == true
}
# jdg.uor.a51.u5.p1 — `uor_a51_u5_p1`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a51.u5.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a51_u5_p1_check", false) == true
}
# jdg.uor.a52.u1.p3 — `uor_a52_u1_p3`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a52.u1.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a52_u1_p3_check", false) == true
}
# jdg.uor.a52.u2.p4 — `uor_a52_u2_p4`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a52.u2.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a52_u2_p4_check", false) == true
}
# jdg.uor.a52.u4.p1 — `uor_a52_u4_p1`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a52.u4.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a52_u4_p1_check", false) == true
}
# jdg.uor.a52.u5.p2 — `uor_a52_u5_p2`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a52.u5.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a52_u5_p2_check", false) == true
}
# jdg.uor.a53.u1.p4 — `uor_a53_u1_p4`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a53.u1.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a53_u1_p4_check", false) == true
}
# jdg.uor.a53.u3.p1 — `uor_a53_u3_p1`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a53.u3.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a53_u3_p1_check", false) == true
}
# jdg.uor.a53.u4.p2 — `uor_a53_u4_p2`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a53.u4.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a53_u4_p2_check", false) == true
}
# jdg.uor.a53.u5.p3 — `uor_a53_u5_p3`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a53.u5.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a53_u5_p3_check", false) == true
}
# jdg.uor.a54.u2.p1 — `uor_a54_u2_p1`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a54.u2.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a54_u2_p1_check", false) == true
}
# jdg.uor.a54.u3.p2 — `uor_a54_u3_p2`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a54.u3.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a54_u3_p2_check", false) == true
}
# jdg.uor.a54.u4.p3 — `uor_a54_u4_p3`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a54.u4.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a54_u4_p3_check", false) == true
}
# jdg.uor.a54.u5.p4 — `uor_a54_u5_p4`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a54.u5.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a54_u5_p4_check", false) == true
}
# jdg.uor.a55.u1.p1 — `uor_a55_u1_p1`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a55.u1.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a55_u1_p1_check", false) == true
}
# jdg.uor.a55.u2.p2 — `uor_a55_u2_p2`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a55.u2.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a55_u2_p2_check", false) == true
}
# jdg.uor.a55.u3.p3 — `uor_a55_u3_p3`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a55.u3.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a55_u3_p3_check", false) == true
}
# jdg.uor.a55.u4.p4 — `uor_a55_u4_p4`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a55.u4.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a55_u4_p4_check", false) == true
}
# jdg.uor.a56.u1.p2 — `uor_a56_u1_p2`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a56.u1.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a56_u1_p2_check", false) == true
}
# jdg.uor.a56.u2.p3 — `uor_a56_u2_p3`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a56.u2.p3",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a56_u2_p3_check", false) == true
}
# jdg.uor.a56.u3.p4 — `uor_a56_u3_p4`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a56.u3.p4",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a56_u3_p4_check", false) == true
}
# jdg.uor.a56.u5.p1 — `uor_a56_u5_p1`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a56.u5.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a56_u5_p1_check", false) == true
}
# jdg.uor.a57.u4.p1 — `uor_a57_u4_p1`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a57.u4.p1",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a57_u4_p1_check", false) == true
}
# jdg.uor.a57.u5.p2 — `uor_a57_u5_p2`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.uor.a57.u5.p2",
    "package": "jdg.micro.uor",
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
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "uor_a57_u5_p2_check", false) == true
}