# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Transport drogowy — 20 artykułów → ~160 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.transport
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.transport

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.transport.no_match",
    "package": "jdg.micro.transport",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  transport.a4 — Licencja transportowa (8 reguł)                                    ║
# ║  Legal basis: Ustawa o transporcie drogowym                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.transport.a4.r1: transport_a4_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a4.r1",
    "package": "jdg.micro.transport",
    "priority": 240004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Licencja transportowa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.transport.a4.r2: transport_a4_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a4.r2",
    "package": "jdg.micro.transport",
    "priority": 240005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Licencja transportowa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "transport_condition_met", false) == true
}

# jdg.micro.transport.a4.r3: transport_a4_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a4.r3",
    "package": "jdg.micro.transport",
    "priority": 240006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Licencja transportowa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "transport_a4_r3_pass", false) == true
}

# jdg.micro.transport.a4.r4: transport_a4_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a4.r4",
    "package": "jdg.micro.transport",
    "priority": 240007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Licencja transportowa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "transport_a4_r4_checks", false) == true
}

# jdg.micro.transport.a4.r5: transport_a4_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a4.r5",
    "package": "jdg.micro.transport",
    "priority": 240008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Licencja transportowa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "transport_exclusion_applies", false) == false
}

# jdg.micro.transport.a4.r6: transport_a4_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a4.r6",
    "package": "jdg.micro.transport",
    "priority": 240009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Licencja transportowa: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "transport_exclusion_2", false) == false
}

# jdg.micro.transport.a4.r7: transport_a4_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a4.r7",
    "package": "jdg.micro.transport",
    "priority": 240010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Licencja transportowa: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "transport_a4_exception", false) == true
}

# jdg.micro.transport.a4.r8: transport_a4_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a4.r8",
    "package": "jdg.micro.transport",
    "priority": 240011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Licencja transportowa: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "transport_a4_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  transport.a8 — Zezwolenia (8 reguł)                                    ║
# ║  Legal basis: Ustawa o transporcie drogowym                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.transport.a8.r1: transport_a8_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a8.r1",
    "package": "jdg.micro.transport",
    "priority": 240012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Zezwolenia: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.transport.a8.r2: transport_a8_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a8.r2",
    "package": "jdg.micro.transport",
    "priority": 240013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Zezwolenia: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "transport_condition_met", false) == true
}

# jdg.micro.transport.a8.r3: transport_a8_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a8.r3",
    "package": "jdg.micro.transport",
    "priority": 240014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Zezwolenia: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "transport_a8_r3_pass", false) == true
}

# jdg.micro.transport.a8.r4: transport_a8_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a8.r4",
    "package": "jdg.micro.transport",
    "priority": 240015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Zezwolenia: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "transport_a8_r4_checks", false) == true
}

# jdg.micro.transport.a8.r5: transport_a8_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a8.r5",
    "package": "jdg.micro.transport",
    "priority": 240016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Zezwolenia: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "transport_exclusion_applies", false) == false
}

# jdg.micro.transport.a8.r6: transport_a8_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a8.r6",
    "package": "jdg.micro.transport",
    "priority": 240017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Zezwolenia: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "transport_exclusion_2", false) == false
}

# jdg.micro.transport.a8.r7: transport_a8_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a8.r7",
    "package": "jdg.micro.transport",
    "priority": 240018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Zezwolenia: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "transport_a8_exception", false) == true
}

# jdg.micro.transport.a8.r8: transport_a8_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a8.r8",
    "package": "jdg.micro.transport",
    "priority": 240019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Zezwolenia: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "transport_a8_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  transport.a12 — Czas pracy kierowców (8 reguł)                                    ║
# ║  Legal basis: Ustawa o transporcie drogowym                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.transport.a12.r1: transport_a12_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a12.r1",
    "package": "jdg.micro.transport",
    "priority": 240020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Czas pracy kierowców: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.transport.a12.r2: transport_a12_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a12.r2",
    "package": "jdg.micro.transport",
    "priority": 240021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Czas pracy kierowców: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "transport_condition_met", false) == true
}

# jdg.micro.transport.a12.r3: transport_a12_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a12.r3",
    "package": "jdg.micro.transport",
    "priority": 240022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Czas pracy kierowców: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "transport_a12_r3_pass", false) == true
}

# jdg.micro.transport.a12.r4: transport_a12_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a12.r4",
    "package": "jdg.micro.transport",
    "priority": 240023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Czas pracy kierowców: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "transport_a12_r4_checks", false) == true
}

# jdg.micro.transport.a12.r5: transport_a12_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a12.r5",
    "package": "jdg.micro.transport",
    "priority": 240024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Czas pracy kierowców: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "transport_exclusion_applies", false) == false
}

# jdg.micro.transport.a12.r6: transport_a12_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a12.r6",
    "package": "jdg.micro.transport",
    "priority": 240025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Czas pracy kierowców: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "transport_exclusion_2", false) == false
}

# jdg.micro.transport.a12.r7: transport_a12_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a12.r7",
    "package": "jdg.micro.transport",
    "priority": 240026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Czas pracy kierowców: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "transport_a12_exception", false) == true
}

# jdg.micro.transport.a12.r8: transport_a12_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a12.r8",
    "package": "jdg.micro.transport",
    "priority": 240027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Czas pracy kierowców: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "transport_a12_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  transport.a16 — Pakiet Mobilności — delegowanie (8 reguł)                                    ║
# ║  Legal basis: Ustawa o transporcie drogowym                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.transport.a16.r1: transport_a16_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a16.r1",
    "package": "jdg.micro.transport",
    "priority": 240028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Pakiet Mobilności — delegowanie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.transport.a16.r2: transport_a16_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a16.r2",
    "package": "jdg.micro.transport",
    "priority": 240029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Pakiet Mobilności — delegowanie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "transport_condition_met", false) == true
}

# jdg.micro.transport.a16.r3: transport_a16_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a16.r3",
    "package": "jdg.micro.transport",
    "priority": 240030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Pakiet Mobilności — delegowanie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "transport_a16_r3_pass", false) == true
}

# jdg.micro.transport.a16.r4: transport_a16_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a16.r4",
    "package": "jdg.micro.transport",
    "priority": 240031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Pakiet Mobilności — delegowanie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "transport_a16_r4_checks", false) == true
}

# jdg.micro.transport.a16.r5: transport_a16_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a16.r5",
    "package": "jdg.micro.transport",
    "priority": 240032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Pakiet Mobilności — delegowanie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "transport_exclusion_applies", false) == false
}

# jdg.micro.transport.a16.r6: transport_a16_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a16.r6",
    "package": "jdg.micro.transport",
    "priority": 240033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Pakiet Mobilności — delegowanie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "transport_exclusion_2", false) == false
}

# jdg.micro.transport.a16.r7: transport_a16_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a16.r7",
    "package": "jdg.micro.transport",
    "priority": 240034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Pakiet Mobilności — delegowanie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "transport_a16_exception", false) == true
}

# jdg.micro.transport.a16.r8: transport_a16_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a16.r8",
    "package": "jdg.micro.transport",
    "priority": 240035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Pakiet Mobilności — delegowanie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "transport_a16_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  transport.a20 — Przewóz kabotażowy (6 reguł)                                    ║
# ║  Legal basis: Ustawa o transporcie drogowym                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.transport.a20.r1: transport_a20_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a20.r1",
    "package": "jdg.micro.transport",
    "priority": 240036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Przewóz kabotażowy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.transport.a20.r2: transport_a20_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a20.r2",
    "package": "jdg.micro.transport",
    "priority": 240037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Przewóz kabotażowy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "transport_condition_met", false) == true
}

# jdg.micro.transport.a20.r3: transport_a20_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a20.r3",
    "package": "jdg.micro.transport",
    "priority": 240038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Przewóz kabotażowy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "transport_a20_r3_pass", false) == true
}

# jdg.micro.transport.a20.r4: transport_a20_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a20.r4",
    "package": "jdg.micro.transport",
    "priority": 240039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Przewóz kabotażowy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "transport_a20_r4_checks", false) == true
}

# jdg.micro.transport.a20.r5: transport_a20_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a20.r5",
    "package": "jdg.micro.transport",
    "priority": 240040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Przewóz kabotażowy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "transport_exclusion_applies", false) == false
}

# jdg.micro.transport.a20.r6: transport_a20_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a20.r6",
    "package": "jdg.micro.transport",
    "priority": 240041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Przewóz kabotażowy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "transport_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  transport.a24 — Sankcje transportowe (6 reguł)                                    ║
# ║  Legal basis: Ustawa o transporcie drogowym                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.transport.a24.r1: transport_a24_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a24.r1",
    "package": "jdg.micro.transport",
    "priority": 240042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Sankcje transportowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.transport.a24.r2: transport_a24_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a24.r2",
    "package": "jdg.micro.transport",
    "priority": 240043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Sankcje transportowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "transport_condition_met", false) == true
}

# jdg.micro.transport.a24.r3: transport_a24_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a24.r3",
    "package": "jdg.micro.transport",
    "priority": 240044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Sankcje transportowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "transport_a24_r3_pass", false) == true
}

# jdg.micro.transport.a24.r4: transport_a24_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a24.r4",
    "package": "jdg.micro.transport",
    "priority": 240045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Sankcje transportowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "transport_a24_r4_checks", false) == true
}

# jdg.micro.transport.a24.r5: transport_a24_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a24.r5",
    "package": "jdg.micro.transport",
    "priority": 240046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Sankcje transportowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "transport_exclusion_applies", false) == false
}

# jdg.micro.transport.a24.r6: transport_a24_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.transport.a24.r6",
    "package": "jdg.micro.transport",
    "priority": 240047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o transporcie drogowym",
    "_warnings": ["[MICRO] Sankcje transportowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "transport_exclusion_2", false) == false
}
