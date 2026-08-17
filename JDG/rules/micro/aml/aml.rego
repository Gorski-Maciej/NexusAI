# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: AML + Prawo dewizowe — 15 artykułów → ~150 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.aml
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.aml

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.aml.no_match",
    "package": "jdg.micro.aml",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  aml.a8 — Instytucje obowiązane (10 reguł)                                    ║
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.aml.a8.r1: aml_a8_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r1",
    "package": "jdg.micro.aml",
    "priority": 200008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.aml.a8.r2: aml_a8_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r2",
    "package": "jdg.micro.aml",
    "priority": 200009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "aml_condition_met", false) == true
}

# jdg.micro.aml.a8.r3: aml_a8_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r3",
    "package": "jdg.micro.aml",
    "priority": 200010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "aml_a8_r3_pass", false) == true
}

# jdg.micro.aml.a8.r4: aml_a8_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r4",
    "package": "jdg.micro.aml",
    "priority": 200011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "aml_a8_r4_checks", false) == true
}

# jdg.micro.aml.a8.r5: aml_a8_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r5",
    "package": "jdg.micro.aml",
    "priority": 200012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "aml_exclusion_applies", false) == false
}

# jdg.micro.aml.a8.r6: aml_a8_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r6",
    "package": "jdg.micro.aml",
    "priority": 200013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "aml_exclusion_2", false) == false
}

# jdg.micro.aml.a8.r7: aml_a8_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r7",
    "package": "jdg.micro.aml",
    "priority": 200014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "aml_a8_exception", false) == true
}

# jdg.micro.aml.a8.r8: aml_a8_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r8",
    "package": "jdg.micro.aml",
    "priority": 200015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "aml_a8_exception_2", false) == true
}

# jdg.micro.aml.a8.r9: aml_a8_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r9",
    "package": "jdg.micro.aml",
    "priority": 200016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_aml", false) == true
}

# jdg.micro.aml.a8.r10: aml_a8_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a8.r10",
    "package": "jdg.micro.aml",
    "priority": 200017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Instytucje obowiązane: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_aml", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  aml.a10 — Środki bezpieczeństwa finansowego (10 reguł)                                    ║
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.aml.a10.r1: aml_a10_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r1",
    "package": "jdg.micro.aml",
    "priority": 200018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.aml.a10.r2: aml_a10_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r2",
    "package": "jdg.micro.aml",
    "priority": 200019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "aml_condition_met", false) == true
}

# jdg.micro.aml.a10.r3: aml_a10_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r3",
    "package": "jdg.micro.aml",
    "priority": 200020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "aml_a10_r3_pass", false) == true
}

# jdg.micro.aml.a10.r4: aml_a10_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r4",
    "package": "jdg.micro.aml",
    "priority": 200021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "aml_a10_r4_checks", false) == true
}

# jdg.micro.aml.a10.r5: aml_a10_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r5",
    "package": "jdg.micro.aml",
    "priority": 200022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "aml_exclusion_applies", false) == false
}

# jdg.micro.aml.a10.r6: aml_a10_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r6",
    "package": "jdg.micro.aml",
    "priority": 200023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "aml_exclusion_2", false) == false
}

# jdg.micro.aml.a10.r7: aml_a10_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r7",
    "package": "jdg.micro.aml",
    "priority": 200024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "aml_a10_exception", false) == true
}

# jdg.micro.aml.a10.r8: aml_a10_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r8",
    "package": "jdg.micro.aml",
    "priority": 200025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "aml_a10_exception_2", false) == true
}

# jdg.micro.aml.a10.r9: aml_a10_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r9",
    "package": "jdg.micro.aml",
    "priority": 200026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_aml", false) == true
}

# jdg.micro.aml.a10.r10: aml_a10_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a10.r10",
    "package": "jdg.micro.aml",
    "priority": 200027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_aml", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  aml.a15 — Raportowanie SAR (8 reguł)                                    ║
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.aml.a15.r1: aml_a15_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a15.r1",
    "package": "jdg.micro.aml",
    "priority": 200028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Raportowanie SAR: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.aml.a15.r2: aml_a15_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a15.r2",
    "package": "jdg.micro.aml",
    "priority": 200029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Raportowanie SAR: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "aml_condition_met", false) == true
}

# jdg.micro.aml.a15.r3: aml_a15_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a15.r3",
    "package": "jdg.micro.aml",
    "priority": 200030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Raportowanie SAR: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "aml_a15_r3_pass", false) == true
}

# jdg.micro.aml.a15.r4: aml_a15_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a15.r4",
    "package": "jdg.micro.aml",
    "priority": 200031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Raportowanie SAR: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "aml_a15_r4_checks", false) == true
}

# jdg.micro.aml.a15.r5: aml_a15_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a15.r5",
    "package": "jdg.micro.aml",
    "priority": 200032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Raportowanie SAR: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "aml_exclusion_applies", false) == false
}

# jdg.micro.aml.a15.r6: aml_a15_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a15.r6",
    "package": "jdg.micro.aml",
    "priority": 200033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Raportowanie SAR: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "aml_exclusion_2", false) == false
}

# jdg.micro.aml.a15.r7: aml_a15_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a15.r7",
    "package": "jdg.micro.aml",
    "priority": 200034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Raportowanie SAR: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "aml_a15_exception", false) == true
}

# jdg.micro.aml.a15.r8: aml_a15_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a15.r8",
    "package": "jdg.micro.aml",
    "priority": 200035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Raportowanie SAR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "aml_a15_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  aml.a18 — Transakcje >15k EUR (8 reguł)                                    ║
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.aml.a18.r1: aml_a18_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a18.r1",
    "package": "jdg.micro.aml",
    "priority": 200036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Transakcje >15k EUR: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.aml.a18.r2: aml_a18_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a18.r2",
    "package": "jdg.micro.aml",
    "priority": 200037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Transakcje >15k EUR: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "aml_condition_met", false) == true
}

# jdg.micro.aml.a18.r3: aml_a18_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a18.r3",
    "package": "jdg.micro.aml",
    "priority": 200038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Transakcje >15k EUR: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "aml_a18_r3_pass", false) == true
}

# jdg.micro.aml.a18.r4: aml_a18_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a18.r4",
    "package": "jdg.micro.aml",
    "priority": 200039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Transakcje >15k EUR: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "aml_a18_r4_checks", false) == true
}

# jdg.micro.aml.a18.r5: aml_a18_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a18.r5",
    "package": "jdg.micro.aml",
    "priority": 200040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Transakcje >15k EUR: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "aml_exclusion_applies", false) == false
}

# jdg.micro.aml.a18.r6: aml_a18_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a18.r6",
    "package": "jdg.micro.aml",
    "priority": 200041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Transakcje >15k EUR: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "aml_exclusion_2", false) == false
}

# jdg.micro.aml.a18.r7: aml_a18_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a18.r7",
    "package": "jdg.micro.aml",
    "priority": 200042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Transakcje >15k EUR: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "aml_a18_exception", false) == true
}

# jdg.micro.aml.a18.r8: aml_a18_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a18.r8",
    "package": "jdg.micro.aml",
    "priority": 200043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Transakcje >15k EUR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "aml_a18_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  aml.a22 — Sankcje AML (8 reguł)                                    ║
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.aml.a22.r1: aml_a22_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a22.r1",
    "package": "jdg.micro.aml",
    "priority": 200044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Sankcje AML: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.aml.a22.r2: aml_a22_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a22.r2",
    "package": "jdg.micro.aml",
    "priority": 200045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Sankcje AML: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "aml_condition_met", false) == true
}

# jdg.micro.aml.a22.r3: aml_a22_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a22.r3",
    "package": "jdg.micro.aml",
    "priority": 200046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Sankcje AML: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "aml_a22_r3_pass", false) == true
}

# jdg.micro.aml.a22.r4: aml_a22_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a22.r4",
    "package": "jdg.micro.aml",
    "priority": 200047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Sankcje AML: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "aml_a22_r4_checks", false) == true
}

# jdg.micro.aml.a22.r5: aml_a22_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a22.r5",
    "package": "jdg.micro.aml",
    "priority": 200048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Sankcje AML: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "aml_exclusion_applies", false) == false
}

# jdg.micro.aml.a22.r6: aml_a22_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a22.r6",
    "package": "jdg.micro.aml",
    "priority": 200049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Sankcje AML: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "aml_exclusion_2", false) == false
}

# jdg.micro.aml.a22.r7: aml_a22_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a22.r7",
    "package": "jdg.micro.aml",
    "priority": 200050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Sankcje AML: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "aml_a22_exception", false) == true
}

# jdg.micro.aml.a22.r8: aml_a22_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.aml.a22.r8",
    "package": "jdg.micro.aml",
    "priority": 200051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2025 poz. 213)",
    "_warnings": ["[MICRO] Sankcje AML: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "aml_a22_exception_2", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (81 reguł)       ║
# ║  Priorytety: 50000-50080                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.aml.a8.r1 — `aml_a8_r1`: Art. 8 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml.a8.r1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 8 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 8: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_a8_r1_check", false) == true
}
# jdg.aml_full.a30.u1.p1 — `aml_full_a30_u1_p1`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a30.u1.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a30_u1_p1_check", false) == true
}
# jdg.aml_full.a30.u2.p2 — `aml_full_a30_u2_p2`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a30.u2.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a30_u2_p2_check", false) == true
}
# jdg.aml_full.a31.u1.p2 — `aml_full_a31_u1_p2`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a31.u1.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a31_u1_p2_check", false) == true
}
# jdg.aml_full.a31.u3.p3 — `aml_full_a31_u3_p3`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a31.u3.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a31_u3_p3_check", false) == true
}
# jdg.aml_full.a31.u4.p4 — `aml_full_a31_u4_p4`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a31.u4.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a31_u4_p4_check", false) == true
}
# jdg.aml_full.a31.u5.p1 — `aml_full_a31_u5_p1`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a31.u5.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a31_u5_p1_check", false) == true
}
# jdg.aml_full.a32.u2.p3 — `aml_full_a32_u2_p3`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a32.u2.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a32_u2_p3_check", false) == true
}
# jdg.aml_full.a32.u3.p4 — `aml_full_a32_u3_p4`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a32.u3.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a32_u3_p4_check", false) == true
}
# jdg.aml_full.a32.u4.p1 — `aml_full_a32_u4_p1`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a32.u4.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a32_u4_p1_check", false) == true
}
# jdg.aml_full.a32.u5.p2 — `aml_full_a32_u5_p2`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a32.u5.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a32_u5_p2_check", false) == true
}
# jdg.aml_full.a33.u1.p3 — `aml_full_a33_u1_p3`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a33.u1.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a33_u1_p3_check", false) == true
}
# jdg.aml_full.a33.u2.p4 — `aml_full_a33_u2_p4`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a33.u2.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a33_u2_p4_check", false) == true
}
# jdg.aml_full.a33.u3.p1 — `aml_full_a33_u3_p1`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a33.u3.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a33_u3_p1_check", false) == true
}
# jdg.aml_full.a33.u4.p2 — `aml_full_a33_u4_p2`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a33.u4.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a33_u4_p2_check", false) == true
}
# jdg.aml_full.a34.u1.p4 — `aml_full_a34_u1_p4`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a34.u1.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a34_u1_p4_check", false) == true
}
# jdg.aml_full.a34.u2.p1 — `aml_full_a34_u2_p1`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a34.u2.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a34_u2_p1_check", false) == true
}
# jdg.aml_full.a34.u3.p2 — `aml_full_a34_u3_p2`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a34.u3.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a34_u3_p2_check", false) == true
}
# jdg.aml_full.a34.u5.p3 — `aml_full_a34_u5_p3`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a34.u5.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a34_u5_p3_check", false) == true
}
# jdg.aml_full.a35.u1.p1 — `aml_full_a35_u1_p1`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a35.u1.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a35_u1_p1_check", false) == true
}
# jdg.aml_full.a35.u2.p2 — `aml_full_a35_u2_p2`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a35.u2.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a35_u2_p2_check", false) == true
}
# jdg.aml_full.a35.u4.p3 — `aml_full_a35_u4_p3`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a35.u4.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a35_u4_p3_check", false) == true
}
# jdg.aml_full.a35.u5.p4 — `aml_full_a35_u5_p4`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a35.u5.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a35_u5_p4_check", false) == true
}
# jdg.aml_full.a36.u1.p2 — `aml_full_a36_u1_p2`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a36.u1.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a36_u1_p2_check", false) == true
}
# jdg.aml_full.a36.u3.p3 — `aml_full_a36_u3_p3`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a36.u3.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a36_u3_p3_check", false) == true
}
# jdg.aml_full.a36.u4.p4 — `aml_full_a36_u4_p4`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a36.u4.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a36_u4_p4_check", false) == true
}
# jdg.aml_full.a36.u5.p1 — `aml_full_a36_u5_p1`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a36.u5.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a36_u5_p1_check", false) == true
}
# jdg.aml_full.a37.u2.p3 — `aml_full_a37_u2_p3`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a37.u2.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a37_u2_p3_check", false) == true
}
# jdg.aml_full.a37.u3.p4 — `aml_full_a37_u3_p4`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a37.u3.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a37_u3_p4_check", false) == true
}
# jdg.aml_full.a37.u4.p1 — `aml_full_a37_u4_p1`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a37.u4.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a37_u4_p1_check", false) == true
}
# jdg.aml_full.a37.u5.p2 — `aml_full_a37_u5_p2`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a37.u5.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a37_u5_p2_check", false) == true
}
# jdg.aml_full.a38.u1.p3 — `aml_full_a38_u1_p3`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a38.u1.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a38_u1_p3_check", false) == true
}
# jdg.aml_full.a38.u2.p4 — `aml_full_a38_u2_p4`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a38.u2.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a38_u2_p4_check", false) == true
}
# jdg.aml_full.a38.u3.p1 — `aml_full_a38_u3_p1`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a38.u3.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a38_u3_p1_check", false) == true
}
# jdg.aml_full.a38.u4.p2 — `aml_full_a38_u4_p2`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a38.u4.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a38_u4_p2_check", false) == true
}
# jdg.aml_full.a39.u1.p4 — `aml_full_a39_u1_p4`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a39.u1.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a39_u1_p4_check", false) == true
}
# jdg.aml_full.a39.u2.p1 — `aml_full_a39_u2_p1`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a39.u2.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a39_u2_p1_check", false) == true
}
# jdg.aml_full.a39.u3.p2 — `aml_full_a39_u3_p2`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a39.u3.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a39_u3_p2_check", false) == true
}
# jdg.aml_full.a39.u5.p3 — `aml_full_a39_u5_p3`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a39.u5.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a39_u5_p3_check", false) == true
}
# jdg.aml_full.a40.u1.p1 — `aml_full_a40_u1_p1`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a40.u1.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a40_u1_p1_check", false) == true
}
# jdg.aml_full.a40.u2.p2 — `aml_full_a40_u2_p2`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a40.u2.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a40_u2_p2_check", false) == true
}
# jdg.aml_full.a40.u4.p3 — `aml_full_a40_u4_p3`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a40.u4.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a40_u4_p3_check", false) == true
}
# jdg.aml_full.a40.u5.p4 — `aml_full_a40_u5_p4`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a40.u5.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a40_u5_p4_check", false) == true
}
# jdg.aml_full.a41.u1.p2 — `aml_full_a41_u1_p2`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a41.u1.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a41_u1_p2_check", false) == true
}
# jdg.aml_full.a41.u3.p3 — `aml_full_a41_u3_p3`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a41.u3.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a41_u3_p3_check", false) == true
}
# jdg.aml_full.a41.u4.p4 — `aml_full_a41_u4_p4`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a41.u4.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a41_u4_p4_check", false) == true
}
# jdg.aml_full.a41.u5.p1 — `aml_full_a41_u5_p1`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a41.u5.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a41_u5_p1_check", false) == true
}
# jdg.aml_full.a42.u2.p3 — `aml_full_a42_u2_p3`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a42.u2.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a42_u2_p3_check", false) == true
}
# jdg.aml_full.a42.u3.p4 — `aml_full_a42_u3_p4`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a42.u3.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a42_u3_p4_check", false) == true
}
# jdg.aml_full.a42.u4.p1 — `aml_full_a42_u4_p1`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a42.u4.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a42_u4_p1_check", false) == true
}
# jdg.aml_full.a42.u5.p2 — `aml_full_a42_u5_p2`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a42.u5.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a42_u5_p2_check", false) == true
}
# jdg.aml_full.a43.u1.p3 — `aml_full_a43_u1_p3`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a43.u1.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a43_u1_p3_check", false) == true
}
# jdg.aml_full.a43.u2.p4 — `aml_full_a43_u2_p4`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a43.u2.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a43_u2_p4_check", false) == true
}
# jdg.aml_full.a43.u3.p1 — `aml_full_a43_u3_p1`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a43.u3.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a43_u3_p1_check", false) == true
}
# jdg.aml_full.a43.u4.p2 — `aml_full_a43_u4_p2`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a43.u4.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a43_u4_p2_check", false) == true
}
# jdg.aml_full.a44.u1.p4 — `aml_full_a44_u1_p4`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a44.u1.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a44_u1_p4_check", false) == true
}
# jdg.aml_full.a44.u2.p1 — `aml_full_a44_u2_p1`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a44.u2.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a44_u2_p1_check", false) == true
}
# jdg.aml_full.a44.u3.p2 — `aml_full_a44_u3_p2`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a44.u3.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a44_u3_p2_check", false) == true
}
# jdg.aml_full.a44.u5.p3 — `aml_full_a44_u5_p3`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a44.u5.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a44_u5_p3_check", false) == true
}
# jdg.aml_full.a45.u1.p1 — `aml_full_a45_u1_p1`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a45.u1.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a45_u1_p1_check", false) == true
}
# jdg.aml_full.a45.u2.p2 — `aml_full_a45_u2_p2`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a45.u2.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a45_u2_p2_check", false) == true
}
# jdg.aml_full.a45.u4.p3 — `aml_full_a45_u4_p3`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a45.u4.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a45_u4_p3_check", false) == true
}
# jdg.aml_full.a45.u5.p4 — `aml_full_a45_u5_p4`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a45.u5.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a45_u5_p4_check", false) == true
}
# jdg.aml_full.a46.u1.p2 — `aml_full_a46_u1_p2`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a46.u1.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a46_u1_p2_check", false) == true
}
# jdg.aml_full.a46.u3.p3 — `aml_full_a46_u3_p3`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a46.u3.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a46_u3_p3_check", false) == true
}
# jdg.aml_full.a46.u4.p4 — `aml_full_a46_u4_p4`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a46.u4.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a46_u4_p4_check", false) == true
}
# jdg.aml_full.a46.u5.p1 — `aml_full_a46_u5_p1`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a46.u5.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a46_u5_p1_check", false) == true
}
# jdg.aml_full.a47.u2.p3 — `aml_full_a47_u2_p3`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a47.u2.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a47_u2_p3_check", false) == true
}
# jdg.aml_full.a47.u3.p4 — `aml_full_a47_u3_p4`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a47.u3.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a47_u3_p4_check", false) == true
}
# jdg.aml_full.a47.u4.p1 — `aml_full_a47_u4_p1`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a47.u4.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a47_u4_p1_check", false) == true
}
# jdg.aml_full.a47.u5.p2 — `aml_full_a47_u5_p2`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a47.u5.p2",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a47_u5_p2_check", false) == true
}
# jdg.aml_full.a48.u1.p3 — `aml_full_a48_u1_p3`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a48.u1.p3",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a48_u1_p3_check", false) == true
}
# jdg.aml_full.a48.u2.p4 — `aml_full_a48_u2_p4`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a48.u2.p4",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a48_u2_p4_check", false) == true
}
# jdg.aml_full.a48.u3.p1 — `aml_full_a48_u3_p1`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a48.u3.p1",
    "package": "jdg.micro.aml",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a48_u3_p1_check", false) == true
}
# jdg.aml_full.a48.u4.p2 — `aml_full_a48_u4_p2`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a48.u4.p2",
    "package": "jdg.micro.aml",
    "priority": 50074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a48_u4_p2_check", false) == true
}
# jdg.aml_full.a49.u1.p4 — `aml_full_a49_u1_p4`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a49.u1.p4",
    "package": "jdg.micro.aml",
    "priority": 50075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a49_u1_p4_check", false) == true
}
# jdg.aml_full.a49.u2.p1 — `aml_full_a49_u2_p1`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a49.u2.p1",
    "package": "jdg.micro.aml",
    "priority": 50076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a49_u2_p1_check", false) == true
}
# jdg.aml_full.a49.u3.p2 — `aml_full_a49_u3_p2`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a49.u3.p2",
    "package": "jdg.micro.aml",
    "priority": 50077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a49_u3_p2_check", false) == true
}
# jdg.aml_full.a49.u5.p3 — `aml_full_a49_u5_p3`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a49.u5.p3",
    "package": "jdg.micro.aml",
    "priority": 50078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a49_u5_p3_check", false) == true
}
# jdg.aml_full.a50.u4.p3 — `aml_full_a50_u4_p3`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a50.u4.p3",
    "package": "jdg.micro.aml",
    "priority": 50079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a50_u4_p3_check", false) == true
}
# jdg.aml_full.a50.u5.p4 — `aml_full_a50_u5_p4`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.aml_full.a50.u5.p4",
    "package": "jdg.micro.aml",
    "priority": 50080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa AML V z 1.03.2018",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "aml_full_a50_u5_p4_check", false) == true
}