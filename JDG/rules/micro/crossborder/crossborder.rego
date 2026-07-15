# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Cross-border — 20 artykułów → ~200 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.crossborder
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.crossborder

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.crossborder.no_match",
    "package": "jdg.micro.crossborder",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  crossborder.a23o — Ceny transferowe — dokumentacja (10 reguł)                                    ║
# ║  Legal basis: Dyrektywy UE, UPO, TP, CFC                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.crossborder.a23o.r1: crossborder_a23o_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r1",
    "package": "jdg.micro.crossborder",
    "priority": 230023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.crossborder.a23o.r2: crossborder_a23o_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r2",
    "package": "jdg.micro.crossborder",
    "priority": 230024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "crossborder_condition_met", false) == true
}

# jdg.micro.crossborder.a23o.r3: crossborder_a23o_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r3",
    "package": "jdg.micro.crossborder",
    "priority": 230025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a23o_r3_pass", false) == true
}

# jdg.micro.crossborder.a23o.r4: crossborder_a23o_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r4",
    "package": "jdg.micro.crossborder",
    "priority": 230026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a23o_r4_checks", false) == true
}

# jdg.micro.crossborder.a23o.r5: crossborder_a23o_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r5",
    "package": "jdg.micro.crossborder",
    "priority": 230027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "crossborder_exclusion_applies", false) == false
}

# jdg.micro.crossborder.a23o.r6: crossborder_a23o_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r6",
    "package": "jdg.micro.crossborder",
    "priority": 230028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "crossborder_exclusion_2", false) == false
}

# jdg.micro.crossborder.a23o.r7: crossborder_a23o_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r7",
    "package": "jdg.micro.crossborder",
    "priority": 230029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "crossborder_a23o_exception", false) == true
}

# jdg.micro.crossborder.a23o.r8: crossborder_a23o_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r8",
    "package": "jdg.micro.crossborder",
    "priority": 230030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "crossborder_a23o_exception_2", false) == true
}

# jdg.micro.crossborder.a23o.r9: crossborder_a23o_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r9",
    "package": "jdg.micro.crossborder",
    "priority": 230031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_crossborder", false) == true
}

# jdg.micro.crossborder.a23o.r10: crossborder_a23o_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23o.r10",
    "package": "jdg.micro.crossborder",
    "priority": 230032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — dokumentacja: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_crossborder", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  crossborder.a23zf — Ceny transferowe — progi (8 reguł)                                    ║
# ║  Legal basis: Dyrektywy UE, UPO, TP, CFC                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.crossborder.a23zf.r1: crossborder_a23zf_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23zf.r1",
    "package": "jdg.micro.crossborder",
    "priority": 230033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — progi: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.crossborder.a23zf.r2: crossborder_a23zf_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23zf.r2",
    "package": "jdg.micro.crossborder",
    "priority": 230034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — progi: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "crossborder_condition_met", false) == true
}

# jdg.micro.crossborder.a23zf.r3: crossborder_a23zf_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23zf.r3",
    "package": "jdg.micro.crossborder",
    "priority": 230035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — progi: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a23zf_r3_pass", false) == true
}

# jdg.micro.crossborder.a23zf.r4: crossborder_a23zf_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23zf.r4",
    "package": "jdg.micro.crossborder",
    "priority": 230036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — progi: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a23zf_r4_checks", false) == true
}

# jdg.micro.crossborder.a23zf.r5: crossborder_a23zf_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23zf.r5",
    "package": "jdg.micro.crossborder",
    "priority": 230037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — progi: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "crossborder_exclusion_applies", false) == false
}

# jdg.micro.crossborder.a23zf.r6: crossborder_a23zf_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23zf.r6",
    "package": "jdg.micro.crossborder",
    "priority": 230038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — progi: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "crossborder_exclusion_2", false) == false
}

# jdg.micro.crossborder.a23zf.r7: crossborder_a23zf_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23zf.r7",
    "package": "jdg.micro.crossborder",
    "priority": 230039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — progi: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "crossborder_a23zf_exception", false) == true
}

# jdg.micro.crossborder.a23zf.r8: crossborder_a23zf_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a23zf.r8",
    "package": "jdg.micro.crossborder",
    "priority": 230040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Ceny transferowe — progi: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "crossborder_a23zf_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  crossborder.a30da — Exit Tax (10 reguł)                                    ║
# ║  Legal basis: Dyrektywy UE, UPO, TP, CFC                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.crossborder.a30da.r1: crossborder_a30da_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r1",
    "package": "jdg.micro.crossborder",
    "priority": 230041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.crossborder.a30da.r2: crossborder_a30da_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r2",
    "package": "jdg.micro.crossborder",
    "priority": 230042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "crossborder_condition_met", false) == true
}

# jdg.micro.crossborder.a30da.r3: crossborder_a30da_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r3",
    "package": "jdg.micro.crossborder",
    "priority": 230043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a30da_r3_pass", false) == true
}

# jdg.micro.crossborder.a30da.r4: crossborder_a30da_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r4",
    "package": "jdg.micro.crossborder",
    "priority": 230044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a30da_r4_checks", false) == true
}

# jdg.micro.crossborder.a30da.r5: crossborder_a30da_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r5",
    "package": "jdg.micro.crossborder",
    "priority": 230045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "crossborder_exclusion_applies", false) == false
}

# jdg.micro.crossborder.a30da.r6: crossborder_a30da_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r6",
    "package": "jdg.micro.crossborder",
    "priority": 230046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "crossborder_exclusion_2", false) == false
}

# jdg.micro.crossborder.a30da.r7: crossborder_a30da_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r7",
    "package": "jdg.micro.crossborder",
    "priority": 230047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "crossborder_a30da_exception", false) == true
}

# jdg.micro.crossborder.a30da.r8: crossborder_a30da_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r8",
    "package": "jdg.micro.crossborder",
    "priority": 230048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "crossborder_a30da_exception_2", false) == true
}

# jdg.micro.crossborder.a30da.r9: crossborder_a30da_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r9",
    "package": "jdg.micro.crossborder",
    "priority": 230049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_crossborder", false) == true
}

# jdg.micro.crossborder.a30da.r10: crossborder_a30da_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30da.r10",
    "package": "jdg.micro.crossborder",
    "priority": 230050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Exit Tax: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_crossborder", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  crossborder.a30f — CFC — definicja (8 reguł)                                    ║
# ║  Legal basis: Dyrektywy UE, UPO, TP, CFC                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.crossborder.a30f.r1: crossborder_a30f_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f.r1",
    "package": "jdg.micro.crossborder",
    "priority": 230051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — definicja: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.crossborder.a30f.r2: crossborder_a30f_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f.r2",
    "package": "jdg.micro.crossborder",
    "priority": 230052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — definicja: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "crossborder_condition_met", false) == true
}

# jdg.micro.crossborder.a30f.r3: crossborder_a30f_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f.r3",
    "package": "jdg.micro.crossborder",
    "priority": 230053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — definicja: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a30f_r3_pass", false) == true
}

# jdg.micro.crossborder.a30f.r4: crossborder_a30f_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f.r4",
    "package": "jdg.micro.crossborder",
    "priority": 230054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — definicja: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a30f_r4_checks", false) == true
}

# jdg.micro.crossborder.a30f.r5: crossborder_a30f_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f.r5",
    "package": "jdg.micro.crossborder",
    "priority": 230055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — definicja: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "crossborder_exclusion_applies", false) == false
}

# jdg.micro.crossborder.a30f.r6: crossborder_a30f_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f.r6",
    "package": "jdg.micro.crossborder",
    "priority": 230056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — definicja: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "crossborder_exclusion_2", false) == false
}

# jdg.micro.crossborder.a30f.r7: crossborder_a30f_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f.r7",
    "package": "jdg.micro.crossborder",
    "priority": 230057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — definicja: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "crossborder_a30f_exception", false) == true
}

# jdg.micro.crossborder.a30f.r8: crossborder_a30f_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f.r8",
    "package": "jdg.micro.crossborder",
    "priority": 230058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — definicja: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "crossborder_a30f_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  crossborder.a30f2 — CFC — test dochodu pasywnego (8 reguł)                                    ║
# ║  Legal basis: Dyrektywy UE, UPO, TP, CFC                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.crossborder.a30f2.r1: crossborder_a30f2_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f2.r1",
    "package": "jdg.micro.crossborder",
    "priority": 230059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — test dochodu pasywnego: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.crossborder.a30f2.r2: crossborder_a30f2_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f2.r2",
    "package": "jdg.micro.crossborder",
    "priority": 230060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — test dochodu pasywnego: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "crossborder_condition_met", false) == true
}

# jdg.micro.crossborder.a30f2.r3: crossborder_a30f2_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f2.r3",
    "package": "jdg.micro.crossborder",
    "priority": 230061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — test dochodu pasywnego: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a30f2_r3_pass", false) == true
}

# jdg.micro.crossborder.a30f2.r4: crossborder_a30f2_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f2.r4",
    "package": "jdg.micro.crossborder",
    "priority": 230062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — test dochodu pasywnego: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a30f2_r4_checks", false) == true
}

# jdg.micro.crossborder.a30f2.r5: crossborder_a30f2_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f2.r5",
    "package": "jdg.micro.crossborder",
    "priority": 230063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — test dochodu pasywnego: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "crossborder_exclusion_applies", false) == false
}

# jdg.micro.crossborder.a30f2.r6: crossborder_a30f2_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f2.r6",
    "package": "jdg.micro.crossborder",
    "priority": 230064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — test dochodu pasywnego: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "crossborder_exclusion_2", false) == false
}

# jdg.micro.crossborder.a30f2.r7: crossborder_a30f2_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f2.r7",
    "package": "jdg.micro.crossborder",
    "priority": 230065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — test dochodu pasywnego: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "crossborder_a30f2_exception", false) == true
}

# jdg.micro.crossborder.a30f2.r8: crossborder_a30f2_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a30f2.r8",
    "package": "jdg.micro.crossborder",
    "priority": 230066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] CFC — test dochodu pasywnego: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "crossborder_a30f2_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  crossborder.a29 — Podatek u źródła WHT (10 reguł)                                    ║
# ║  Legal basis: Dyrektywy UE, UPO, TP, CFC                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.crossborder.a29.r1: crossborder_a29_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r1",
    "package": "jdg.micro.crossborder",
    "priority": 230067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.crossborder.a29.r2: crossborder_a29_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r2",
    "package": "jdg.micro.crossborder",
    "priority": 230068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "crossborder_condition_met", false) == true
}

# jdg.micro.crossborder.a29.r3: crossborder_a29_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r3",
    "package": "jdg.micro.crossborder",
    "priority": 230069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a29_r3_pass", false) == true
}

# jdg.micro.crossborder.a29.r4: crossborder_a29_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r4",
    "package": "jdg.micro.crossborder",
    "priority": 230070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a29_r4_checks", false) == true
}

# jdg.micro.crossborder.a29.r5: crossborder_a29_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r5",
    "package": "jdg.micro.crossborder",
    "priority": 230071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "crossborder_exclusion_applies", false) == false
}

# jdg.micro.crossborder.a29.r6: crossborder_a29_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r6",
    "package": "jdg.micro.crossborder",
    "priority": 230072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "crossborder_exclusion_2", false) == false
}

# jdg.micro.crossborder.a29.r7: crossborder_a29_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r7",
    "package": "jdg.micro.crossborder",
    "priority": 230073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "crossborder_a29_exception", false) == true
}

# jdg.micro.crossborder.a29.r8: crossborder_a29_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r8",
    "package": "jdg.micro.crossborder",
    "priority": 230074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "crossborder_a29_exception_2", false) == true
}

# jdg.micro.crossborder.a29.r9: crossborder_a29_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r9",
    "package": "jdg.micro.crossborder",
    "priority": 230075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_crossborder", false) == true
}

# jdg.micro.crossborder.a29.r10: crossborder_a29_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a29.r10",
    "package": "jdg.micro.crossborder",
    "priority": 230076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Podatek u źródła WHT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_crossborder", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  crossborder.a86r — MDR — raportowanie schematów (10 reguł)                                    ║
# ║  Legal basis: Dyrektywy UE, UPO, TP, CFC                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.crossborder.a86r.r1: crossborder_a86r_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r1",
    "package": "jdg.micro.crossborder",
    "priority": 230077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.crossborder.a86r.r2: crossborder_a86r_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r2",
    "package": "jdg.micro.crossborder",
    "priority": 230078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "crossborder_condition_met", false) == true
}

# jdg.micro.crossborder.a86r.r3: crossborder_a86r_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r3",
    "package": "jdg.micro.crossborder",
    "priority": 230079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a86r_r3_pass", false) == true
}

# jdg.micro.crossborder.a86r.r4: crossborder_a86r_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r4",
    "package": "jdg.micro.crossborder",
    "priority": 230080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a86r_r4_checks", false) == true
}

# jdg.micro.crossborder.a86r.r5: crossborder_a86r_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r5",
    "package": "jdg.micro.crossborder",
    "priority": 230081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "crossborder_exclusion_applies", false) == false
}

# jdg.micro.crossborder.a86r.r6: crossborder_a86r_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r6",
    "package": "jdg.micro.crossborder",
    "priority": 230082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "crossborder_exclusion_2", false) == false
}

# jdg.micro.crossborder.a86r.r7: crossborder_a86r_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r7",
    "package": "jdg.micro.crossborder",
    "priority": 230083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "crossborder_a86r_exception", false) == true
}

# jdg.micro.crossborder.a86r.r8: crossborder_a86r_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r8",
    "package": "jdg.micro.crossborder",
    "priority": 230084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "crossborder_a86r_exception_2", false) == true
}

# jdg.micro.crossborder.a86r.r9: crossborder_a86r_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r9",
    "package": "jdg.micro.crossborder",
    "priority": 230085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_crossborder", false) == true
}

# jdg.micro.crossborder.a86r.r10: crossborder_a86r_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a86r.r10",
    "package": "jdg.micro.crossborder",
    "priority": 230086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] MDR — raportowanie schematów: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_crossborder", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  crossborder.a20 — Konwencje MLI (8 reguł)                                    ║
# ║  Legal basis: Dyrektywy UE, UPO, TP, CFC                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.crossborder.a20.r1: crossborder_a20_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a20.r1",
    "package": "jdg.micro.crossborder",
    "priority": 230087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Konwencje MLI: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.crossborder.a20.r2: crossborder_a20_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a20.r2",
    "package": "jdg.micro.crossborder",
    "priority": 230088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Konwencje MLI: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "crossborder_condition_met", false) == true
}

# jdg.micro.crossborder.a20.r3: crossborder_a20_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a20.r3",
    "package": "jdg.micro.crossborder",
    "priority": 230089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Konwencje MLI: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a20_r3_pass", false) == true
}

# jdg.micro.crossborder.a20.r4: crossborder_a20_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a20.r4",
    "package": "jdg.micro.crossborder",
    "priority": 230090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Konwencje MLI: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "crossborder_a20_r4_checks", false) == true
}

# jdg.micro.crossborder.a20.r5: crossborder_a20_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a20.r5",
    "package": "jdg.micro.crossborder",
    "priority": 230091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Konwencje MLI: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "crossborder_exclusion_applies", false) == false
}

# jdg.micro.crossborder.a20.r6: crossborder_a20_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a20.r6",
    "package": "jdg.micro.crossborder",
    "priority": 230092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Konwencje MLI: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "crossborder_exclusion_2", false) == false
}

# jdg.micro.crossborder.a20.r7: crossborder_a20_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a20.r7",
    "package": "jdg.micro.crossborder",
    "priority": 230093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Konwencje MLI: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "crossborder_a20_exception", false) == true
}

# jdg.micro.crossborder.a20.r8: crossborder_a20_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.crossborder.a20.r8",
    "package": "jdg.micro.crossborder",
    "priority": 230094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Dyrektywy UE, UPO, TP, CFC",
    "_warnings": ["[MICRO] Konwencje MLI: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "crossborder_a20_exception_2", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (120 reguł)       ║
# ║  Priorytety: 50000-50119                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.cb.a28.u1.p1 — `cb_a28_u1_p1`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a28.u1.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a28_u1_p1_check", false) == true
}
# jdg.cb.a28.u2.p2 — `cb_a28_u2_p2`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a28.u2.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a28_u2_p2_check", false) == true
}
# jdg.cb.a28.u3.p3 — `cb_a28_u3_p3`: Art. 28 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a28.u3.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 28 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 28: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a28_u3_p3_check", false) == true
}
# jdg.cb.a29.u1.p2 — `cb_a29_u1_p2`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a29.u1.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a29_u1_p2_check", false) == true
}
# jdg.cb.a29.u2.p3 — `cb_a29_u2_p3`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a29.u2.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a29_u2_p3_check", false) == true
}
# jdg.cb.a29.u4.p4 — `cb_a29_u4_p4`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a29.u4.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a29_u4_p4_check", false) == true
}
# jdg.cb.a29.u5.p1 — `cb_a29_u5_p1`: Art. 29 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a29.u5.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 29 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 29: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a29_u5_p1_check", false) == true
}
# jdg.cb.a30.u1.p1 — `cb_a30_u1_p1`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a30.u1.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a30_u1_p1_check", false) == true
}
# jdg.cb.a30.u1.p3 — `cb_a30_u1_p3`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a30.u1.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a30_u1_p3_check", false) == true
}
# jdg.cb.a30.u2.p2 — `cb_a30_u2_p2`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a30.u2.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a30_u2_p2_check", false) == true
}
# jdg.cb.a30.u3.p4 — `cb_a30_u3_p4`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a30.u3.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a30_u3_p4_check", false) == true
}
# jdg.cb.a30.u4.p1 — `cb_a30_u4_p1`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a30.u4.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a30_u4_p1_check", false) == true
}
# jdg.cb.a30.u5.p2 — `cb_a30_u5_p2`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a30.u5.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a30_u5_p2_check", false) == true
}
# jdg.cb.a31.u1.p2 — `cb_a31_u1_p2`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a31.u1.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a31_u1_p2_check", false) == true
}
# jdg.cb.a31.u2.p4 — `cb_a31_u2_p4`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a31.u2.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a31_u2_p4_check", false) == true
}
# jdg.cb.a31.u3.p1 — `cb_a31_u3_p1`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a31.u3.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a31_u3_p1_check", false) == true
}
# jdg.cb.a31.u3.p3 — `cb_a31_u3_p3`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a31.u3.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a31_u3_p3_check", false) == true
}
# jdg.cb.a31.u4.p2 — `cb_a31_u4_p2`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a31.u4.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a31_u4_p2_check", false) == true
}
# jdg.cb.a31.u4.p4 — `cb_a31_u4_p4`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a31.u4.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a31_u4_p4_check", false) == true
}
# jdg.cb.a31.u5.p1 — `cb_a31_u5_p1`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a31.u5.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a31_u5_p1_check", false) == true
}
# jdg.cb.a31.u5.p3 — `cb_a31_u5_p3`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a31.u5.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a31_u5_p3_check", false) == true
}
# jdg.cb.a32.u1.p4 — `cb_a32_u1_p4`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a32.u1.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a32_u1_p4_check", false) == true
}
# jdg.cb.a32.u2.p1 — `cb_a32_u2_p1`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a32.u2.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a32_u2_p1_check", false) == true
}
# jdg.cb.a32.u2.p3 — `cb_a32_u2_p3`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a32.u2.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a32_u2_p3_check", false) == true
}
# jdg.cb.a32.u3.p2 — `cb_a32_u3_p2`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a32.u3.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a32_u3_p2_check", false) == true
}
# jdg.cb.a32.u3.p4 — `cb_a32_u3_p4`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a32.u3.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a32_u3_p4_check", false) == true
}
# jdg.cb.a32.u4.p1 — `cb_a32_u4_p1`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a32.u4.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a32_u4_p1_check", false) == true
}
# jdg.cb.a32.u4.p3 — `cb_a32_u4_p3`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a32.u4.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a32_u4_p3_check", false) == true
}
# jdg.cb.a32.u5.p2 — `cb_a32_u5_p2`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a32.u5.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a32_u5_p2_check", false) == true
}
# jdg.cb.a33.u1.p1 — `cb_a33_u1_p1`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a33.u1.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a33_u1_p1_check", false) == true
}
# jdg.cb.a33.u1.p3 — `cb_a33_u1_p3`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a33.u1.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a33_u1_p3_check", false) == true
}
# jdg.cb.a33.u2.p2 — `cb_a33_u2_p2`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a33.u2.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a33_u2_p2_check", false) == true
}
# jdg.cb.a33.u2.p4 — `cb_a33_u2_p4`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a33.u2.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a33_u2_p4_check", false) == true
}
# jdg.cb.a33.u3.p1 — `cb_a33_u3_p1`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a33.u3.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a33_u3_p1_check", false) == true
}
# jdg.cb.a33.u3.p3 — `cb_a33_u3_p3`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a33.u3.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a33_u3_p3_check", false) == true
}
# jdg.cb.a33.u4.p2 — `cb_a33_u4_p2`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a33.u4.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a33_u4_p2_check", false) == true
}
# jdg.cb.a33.u5.p4 — `cb_a33_u5_p4`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a33.u5.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a33_u5_p4_check", false) == true
}
# jdg.cb.a34.u1.p2 — `cb_a34_u1_p2`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a34.u1.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a34_u1_p2_check", false) == true
}
# jdg.cb.a34.u1.p4 — `cb_a34_u1_p4`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a34.u1.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a34_u1_p4_check", false) == true
}
# jdg.cb.a34.u2.p1 — `cb_a34_u2_p1`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a34.u2.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a34_u2_p1_check", false) == true
}
# jdg.cb.a34.u2.p3 — `cb_a34_u2_p3`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a34.u2.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a34_u2_p3_check", false) == true
}
# jdg.cb.a34.u3.p2 — `cb_a34_u3_p2`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a34.u3.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a34_u3_p2_check", false) == true
}
# jdg.cb.a34.u4.p4 — `cb_a34_u4_p4`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a34.u4.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a34_u4_p4_check", false) == true
}
# jdg.cb.a34.u5.p1 — `cb_a34_u5_p1`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a34.u5.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a34_u5_p1_check", false) == true
}
# jdg.cb.a34.u5.p3 — `cb_a34_u5_p3`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a34.u5.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a34_u5_p3_check", false) == true
}
# jdg.cb.a35.u1.p1 — `cb_a35_u1_p1`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a35.u1.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a35_u1_p1_check", false) == true
}
# jdg.cb.a35.u1.p3 — `cb_a35_u1_p3`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a35.u1.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a35_u1_p3_check", false) == true
}
# jdg.cb.a35.u2.p2 — `cb_a35_u2_p2`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a35.u2.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a35_u2_p2_check", false) == true
}
# jdg.cb.a35.u3.p4 — `cb_a35_u3_p4`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a35.u3.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a35_u3_p4_check", false) == true
}
# jdg.cb.a35.u4.p1 — `cb_a35_u4_p1`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a35.u4.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a35_u4_p1_check", false) == true
}
# jdg.cb.a35.u4.p3 — `cb_a35_u4_p3`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a35.u4.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a35_u4_p3_check", false) == true
}
# jdg.cb.a35.u5.p2 — `cb_a35_u5_p2`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a35.u5.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a35_u5_p2_check", false) == true
}
# jdg.cb.a35.u5.p4 — `cb_a35_u5_p4`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a35.u5.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a35_u5_p4_check", false) == true
}
# jdg.cb.a36.u1.p2 — `cb_a36_u1_p2`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a36.u1.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a36_u1_p2_check", false) == true
}
# jdg.cb.a36.u2.p4 — `cb_a36_u2_p4`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a36.u2.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a36_u2_p4_check", false) == true
}
# jdg.cb.a36.u3.p1 — `cb_a36_u3_p1`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a36.u3.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a36_u3_p1_check", false) == true
}
# jdg.cb.a36.u3.p3 — `cb_a36_u3_p3`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a36.u3.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a36_u3_p3_check", false) == true
}
# jdg.cb.a36.u4.p2 — `cb_a36_u4_p2`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a36.u4.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a36_u4_p2_check", false) == true
}
# jdg.cb.a36.u4.p4 — `cb_a36_u4_p4`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a36.u4.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a36_u4_p4_check", false) == true
}
# jdg.cb.a36.u5.p1 — `cb_a36_u5_p1`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a36.u5.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a36_u5_p1_check", false) == true
}
# jdg.cb.a36.u5.p3 — `cb_a36_u5_p3`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a36.u5.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a36_u5_p3_check", false) == true
}
# jdg.cb.a37.u1.p4 — `cb_a37_u1_p4`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a37.u1.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a37_u1_p4_check", false) == true
}
# jdg.cb.a37.u2.p1 — `cb_a37_u2_p1`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a37.u2.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a37_u2_p1_check", false) == true
}
# jdg.cb.a37.u2.p3 — `cb_a37_u2_p3`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a37.u2.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a37_u2_p3_check", false) == true
}
# jdg.cb.a37.u3.p2 — `cb_a37_u3_p2`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a37.u3.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a37_u3_p2_check", false) == true
}
# jdg.cb.a37.u3.p4 — `cb_a37_u3_p4`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a37.u3.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a37_u3_p4_check", false) == true
}
# jdg.cb.a37.u4.p1 — `cb_a37_u4_p1`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a37.u4.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a37_u4_p1_check", false) == true
}
# jdg.cb.a37.u4.p3 — `cb_a37_u4_p3`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a37.u4.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a37_u4_p3_check", false) == true
}
# jdg.cb.a37.u5.p2 — `cb_a37_u5_p2`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a37.u5.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a37_u5_p2_check", false) == true
}
# jdg.cb.a38.u1.p1 — `cb_a38_u1_p1`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a38.u1.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a38_u1_p1_check", false) == true
}
# jdg.cb.a38.u1.p3 — `cb_a38_u1_p3`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a38.u1.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a38_u1_p3_check", false) == true
}
# jdg.cb.a38.u2.p2 — `cb_a38_u2_p2`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a38.u2.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a38_u2_p2_check", false) == true
}
# jdg.cb.a38.u2.p4 — `cb_a38_u2_p4`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a38.u2.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a38_u2_p4_check", false) == true
}
# jdg.cb.a38.u3.p1 — `cb_a38_u3_p1`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a38.u3.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a38_u3_p1_check", false) == true
}
# jdg.cb.a38.u3.p3 — `cb_a38_u3_p3`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a38.u3.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a38_u3_p3_check", false) == true
}
# jdg.cb.a38.u4.p2 — `cb_a38_u4_p2`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a38.u4.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a38_u4_p2_check", false) == true
}
# jdg.cb.a38.u5.p4 — `cb_a38_u5_p4`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a38.u5.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a38_u5_p4_check", false) == true
}
# jdg.cb.a39.u1.p2 — `cb_a39_u1_p2`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a39.u1.p2",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a39_u1_p2_check", false) == true
}
# jdg.cb.a39.u1.p4 — `cb_a39_u1_p4`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a39.u1.p4",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a39_u1_p4_check", false) == true
}
# jdg.cb.a39.u2.p1 — `cb_a39_u2_p1`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a39.u2.p1",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a39_u2_p1_check", false) == true
}
# jdg.cb.a39.u2.p3 — `cb_a39_u2_p3`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a39.u2.p3",
    "package": "jdg.micro.crossborder",
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
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a39_u2_p3_check", false) == true
}
# jdg.cb.a39.u3.p2 — `cb_a39_u3_p2`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a39.u3.p2",
    "package": "jdg.micro.crossborder",
    "priority": 50081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a39_u3_p2_check", false) == true
}
# jdg.cb.a39.u4.p4 — `cb_a39_u4_p4`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a39.u4.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a39_u4_p4_check", false) == true
}
# jdg.cb.a39.u5.p1 — `cb_a39_u5_p1`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a39.u5.p1",
    "package": "jdg.micro.crossborder",
    "priority": 50083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a39_u5_p1_check", false) == true
}
# jdg.cb.a39.u5.p3 — `cb_a39_u5_p3`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a39.u5.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a39_u5_p3_check", false) == true
}
# jdg.cb.a40.u1.p1 — `cb_a40_u1_p1`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a40.u1.p1",
    "package": "jdg.micro.crossborder",
    "priority": 50085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a40_u1_p1_check", false) == true
}
# jdg.cb.a40.u1.p3 — `cb_a40_u1_p3`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a40.u1.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a40_u1_p3_check", false) == true
}
# jdg.cb.a40.u2.p2 — `cb_a40_u2_p2`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a40.u2.p2",
    "package": "jdg.micro.crossborder",
    "priority": 50087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a40_u2_p2_check", false) == true
}
# jdg.cb.a40.u3.p4 — `cb_a40_u3_p4`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a40.u3.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a40_u3_p4_check", false) == true
}
# jdg.cb.a40.u4.p1 — `cb_a40_u4_p1`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a40.u4.p1",
    "package": "jdg.micro.crossborder",
    "priority": 50089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a40_u4_p1_check", false) == true
}
# jdg.cb.a40.u4.p3 — `cb_a40_u4_p3`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a40.u4.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a40_u4_p3_check", false) == true
}
# jdg.cb.a40.u5.p2 — `cb_a40_u5_p2`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a40.u5.p2",
    "package": "jdg.micro.crossborder",
    "priority": 50091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a40_u5_p2_check", false) == true
}
# jdg.cb.a40.u5.p4 — `cb_a40_u5_p4`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a40.u5.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a40_u5_p4_check", false) == true
}
# jdg.cb.a41.u1.p2 — `cb_a41_u1_p2`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a41.u1.p2",
    "package": "jdg.micro.crossborder",
    "priority": 50093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a41_u1_p2_check", false) == true
}
# jdg.cb.a41.u2.p4 — `cb_a41_u2_p4`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a41.u2.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a41_u2_p4_check", false) == true
}
# jdg.cb.a41.u3.p1 — `cb_a41_u3_p1`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a41.u3.p1",
    "package": "jdg.micro.crossborder",
    "priority": 50095,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a41_u3_p1_check", false) == true
}
# jdg.cb.a41.u3.p3 — `cb_a41_u3_p3`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a41.u3.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50096,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a41_u3_p3_check", false) == true
}
# jdg.cb.a41.u4.p2 — `cb_a41_u4_p2`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a41.u4.p2",
    "package": "jdg.micro.crossborder",
    "priority": 50097,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a41_u4_p2_check", false) == true
}
# jdg.cb.a41.u4.p4 — `cb_a41_u4_p4`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a41.u4.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50098,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a41_u4_p4_check", false) == true
}
# jdg.cb.a41.u5.p1 — `cb_a41_u5_p1`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a41.u5.p1",
    "package": "jdg.micro.crossborder",
    "priority": 50099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a41_u5_p1_check", false) == true
}
# jdg.cb.a41.u5.p3 — `cb_a41_u5_p3`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a41.u5.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50100,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a41_u5_p3_check", false) == true
}
# jdg.cb.a42.u1.p4 — `cb_a42_u1_p4`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a42.u1.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a42_u1_p4_check", false) == true
}
# jdg.cb.a42.u2.p1 — `cb_a42_u2_p1`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a42.u2.p1",
    "package": "jdg.micro.crossborder",
    "priority": 50102,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a42_u2_p1_check", false) == true
}
# jdg.cb.a42.u2.p3 — `cb_a42_u2_p3`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a42.u2.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50103,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a42_u2_p3_check", false) == true
}
# jdg.cb.a42.u3.p2 — `cb_a42_u3_p2`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a42.u3.p2",
    "package": "jdg.micro.crossborder",
    "priority": 50104,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a42_u3_p2_check", false) == true
}
# jdg.cb.a42.u3.p4 — `cb_a42_u3_p4`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a42.u3.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50105,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a42_u3_p4_check", false) == true
}
# jdg.cb.a42.u4.p1 — `cb_a42_u4_p1`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a42.u4.p1",
    "package": "jdg.micro.crossborder",
    "priority": 50106,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a42_u4_p1_check", false) == true
}
# jdg.cb.a42.u4.p3 — `cb_a42_u4_p3`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a42.u4.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50107,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a42_u4_p3_check", false) == true
}
# jdg.cb.a42.u5.p2 — `cb_a42_u5_p2`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a42.u5.p2",
    "package": "jdg.micro.crossborder",
    "priority": 50108,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a42_u5_p2_check", false) == true
}
# jdg.cb.a43.u1.p3 — `cb_a43_u1_p3`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a43.u1.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50109,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a43_u1_p3_check", false) == true
}
# jdg.cb.a43.u2.p4 — `cb_a43_u2_p4`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a43.u2.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50110,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a43_u2_p4_check", false) == true
}
# jdg.cb.a43.u3.p1 — `cb_a43_u3_p1`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a43.u3.p1",
    "package": "jdg.micro.crossborder",
    "priority": 50111,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a43_u3_p1_check", false) == true
}
# jdg.cb.a43.u4.p2 — `cb_a43_u4_p2`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a43.u4.p2",
    "package": "jdg.micro.crossborder",
    "priority": 50112,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a43_u4_p2_check", false) == true
}
# jdg.cb.a43.u5.p4 — `cb_a43_u5_p4`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a43.u5.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50113,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a43_u5_p4_check", false) == true
}
# jdg.cb.a44.u1.p4 — `cb_a44_u1_p4`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a44.u1.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50114,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a44_u1_p4_check", false) == true
}
# jdg.cb.a44.u2.p1 — `cb_a44_u2_p1`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a44.u2.p1",
    "package": "jdg.micro.crossborder",
    "priority": 50115,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a44_u2_p1_check", false) == true
}
# jdg.cb.a44.u3.p2 — `cb_a44_u3_p2`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a44.u3.p2",
    "package": "jdg.micro.crossborder",
    "priority": 50116,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a44_u3_p2_check", false) == true
}
# jdg.cb.a44.u5.p3 — `cb_a44_u5_p3`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a44.u5.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50117,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a44_u5_p3_check", false) == true
}
# jdg.cb.a45.u4.p3 — `cb_a45_u4_p3`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a45.u4.p3",
    "package": "jdg.micro.crossborder",
    "priority": 50118,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a45_u4_p3_check", false) == true
}
# jdg.cb.a45.u5.p4 — `cb_a45_u5_p4`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.cb.a45.u5.p4",
    "package": "jdg.micro.crossborder",
    "priority": 50119,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ustawa o PIT/CIT — cross-border",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "cb_a45_u5_p4_check", false) == true
}