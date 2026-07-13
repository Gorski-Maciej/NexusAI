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
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)                                                   ║
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
    "_warnings": ["[MICRO] Instytucje obowiązane: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_aml", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  aml.a10 — Środki bezpieczeństwa finansowego (10 reguł)                                    ║
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)                                                   ║
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
    "_warnings": ["[MICRO] Środki bezpieczeństwa finansowego: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_aml", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  aml.a15 — Raportowanie SAR (8 reguł)                                    ║
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)                                                   ║
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
    "_warnings": ["[MICRO] Raportowanie SAR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "aml_a15_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  aml.a18 — Transakcje >15k EUR (8 reguł)                                    ║
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)                                                   ║
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
    "_warnings": ["[MICRO] Transakcje >15k EUR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "aml_a18_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  aml.a22 — Sankcje AML (8 reguł)                                    ║
# ║  Legal basis: Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)                                                   ║
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
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
    "_legal_basis": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
    "_warnings": ["[MICRO] Sankcje AML: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "aml_a22_exception_2", false) == true
}
