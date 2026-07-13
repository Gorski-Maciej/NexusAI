# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: RODO dla JDG — 10 artykułów → ~80 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.rodo
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.rodo

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.rodo.no_match",
    "package": "jdg.micro.rodo",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  rodo.a6 — Podstawa prawna przetwarzania (8 reguł)                                    ║
# ║  Legal basis: RODO — Rozporządzenie UE 2016/679                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.rodo.a6.r1: rodo_a6_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a6.r1",
    "package": "jdg.micro.rodo",
    "priority": 210006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Podstawa prawna przetwarzania: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.rodo.a6.r2: rodo_a6_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a6.r2",
    "package": "jdg.micro.rodo",
    "priority": 210007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Podstawa prawna przetwarzania: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "rodo_condition_met", false) == true
}

# jdg.micro.rodo.a6.r3: rodo_a6_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a6.r3",
    "package": "jdg.micro.rodo",
    "priority": 210008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Podstawa prawna przetwarzania: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a6_r3_pass", false) == true
}

# jdg.micro.rodo.a6.r4: rodo_a6_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a6.r4",
    "package": "jdg.micro.rodo",
    "priority": 210009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Podstawa prawna przetwarzania: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a6_r4_checks", false) == true
}

# jdg.micro.rodo.a6.r5: rodo_a6_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a6.r5",
    "package": "jdg.micro.rodo",
    "priority": 210010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Podstawa prawna przetwarzania: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "rodo_exclusion_applies", false) == false
}

# jdg.micro.rodo.a6.r6: rodo_a6_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a6.r6",
    "package": "jdg.micro.rodo",
    "priority": 210011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Podstawa prawna przetwarzania: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "rodo_exclusion_2", false) == false
}

# jdg.micro.rodo.a6.r7: rodo_a6_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a6.r7",
    "package": "jdg.micro.rodo",
    "priority": 210012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Podstawa prawna przetwarzania: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "rodo_a6_exception", false) == true
}

# jdg.micro.rodo.a6.r8: rodo_a6_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a6.r8",
    "package": "jdg.micro.rodo",
    "priority": 210013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Podstawa prawna przetwarzania: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "rodo_a6_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  rodo.a13 — Obowiązek informacyjny (8 reguł)                                    ║
# ║  Legal basis: RODO — Rozporządzenie UE 2016/679                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.rodo.a13.r1: rodo_a13_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a13.r1",
    "package": "jdg.micro.rodo",
    "priority": 210014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Obowiązek informacyjny: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.rodo.a13.r2: rodo_a13_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a13.r2",
    "package": "jdg.micro.rodo",
    "priority": 210015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Obowiązek informacyjny: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "rodo_condition_met", false) == true
}

# jdg.micro.rodo.a13.r3: rodo_a13_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a13.r3",
    "package": "jdg.micro.rodo",
    "priority": 210016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Obowiązek informacyjny: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a13_r3_pass", false) == true
}

# jdg.micro.rodo.a13.r4: rodo_a13_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a13.r4",
    "package": "jdg.micro.rodo",
    "priority": 210017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Obowiązek informacyjny: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a13_r4_checks", false) == true
}

# jdg.micro.rodo.a13.r5: rodo_a13_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a13.r5",
    "package": "jdg.micro.rodo",
    "priority": 210018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Obowiązek informacyjny: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "rodo_exclusion_applies", false) == false
}

# jdg.micro.rodo.a13.r6: rodo_a13_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a13.r6",
    "package": "jdg.micro.rodo",
    "priority": 210019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Obowiązek informacyjny: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "rodo_exclusion_2", false) == false
}

# jdg.micro.rodo.a13.r7: rodo_a13_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a13.r7",
    "package": "jdg.micro.rodo",
    "priority": 210020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Obowiązek informacyjny: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "rodo_a13_exception", false) == true
}

# jdg.micro.rodo.a13.r8: rodo_a13_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a13.r8",
    "package": "jdg.micro.rodo",
    "priority": 210021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Obowiązek informacyjny: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "rodo_a13_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  rodo.a15 — Prawo dostępu do danych (8 reguł)                                    ║
# ║  Legal basis: RODO — Rozporządzenie UE 2016/679                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.rodo.a15.r1: rodo_a15_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a15.r1",
    "package": "jdg.micro.rodo",
    "priority": 210022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Prawo dostępu do danych: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.rodo.a15.r2: rodo_a15_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a15.r2",
    "package": "jdg.micro.rodo",
    "priority": 210023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Prawo dostępu do danych: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "rodo_condition_met", false) == true
}

# jdg.micro.rodo.a15.r3: rodo_a15_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a15.r3",
    "package": "jdg.micro.rodo",
    "priority": 210024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Prawo dostępu do danych: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a15_r3_pass", false) == true
}

# jdg.micro.rodo.a15.r4: rodo_a15_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a15.r4",
    "package": "jdg.micro.rodo",
    "priority": 210025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Prawo dostępu do danych: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a15_r4_checks", false) == true
}

# jdg.micro.rodo.a15.r5: rodo_a15_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a15.r5",
    "package": "jdg.micro.rodo",
    "priority": 210026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Prawo dostępu do danych: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "rodo_exclusion_applies", false) == false
}

# jdg.micro.rodo.a15.r6: rodo_a15_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a15.r6",
    "package": "jdg.micro.rodo",
    "priority": 210027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Prawo dostępu do danych: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "rodo_exclusion_2", false) == false
}

# jdg.micro.rodo.a15.r7: rodo_a15_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a15.r7",
    "package": "jdg.micro.rodo",
    "priority": 210028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Prawo dostępu do danych: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "rodo_a15_exception", false) == true
}

# jdg.micro.rodo.a15.r8: rodo_a15_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a15.r8",
    "package": "jdg.micro.rodo",
    "priority": 210029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Prawo dostępu do danych: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "rodo_a15_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  rodo.a32 — Bezpieczeństwo przetwarzania (8 reguł)                                    ║
# ║  Legal basis: RODO — Rozporządzenie UE 2016/679                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.rodo.a32.r1: rodo_a32_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a32.r1",
    "package": "jdg.micro.rodo",
    "priority": 210030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Bezpieczeństwo przetwarzania: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.rodo.a32.r2: rodo_a32_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a32.r2",
    "package": "jdg.micro.rodo",
    "priority": 210031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Bezpieczeństwo przetwarzania: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "rodo_condition_met", false) == true
}

# jdg.micro.rodo.a32.r3: rodo_a32_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a32.r3",
    "package": "jdg.micro.rodo",
    "priority": 210032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Bezpieczeństwo przetwarzania: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a32_r3_pass", false) == true
}

# jdg.micro.rodo.a32.r4: rodo_a32_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a32.r4",
    "package": "jdg.micro.rodo",
    "priority": 210033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Bezpieczeństwo przetwarzania: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a32_r4_checks", false) == true
}

# jdg.micro.rodo.a32.r5: rodo_a32_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a32.r5",
    "package": "jdg.micro.rodo",
    "priority": 210034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Bezpieczeństwo przetwarzania: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "rodo_exclusion_applies", false) == false
}

# jdg.micro.rodo.a32.r6: rodo_a32_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a32.r6",
    "package": "jdg.micro.rodo",
    "priority": 210035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Bezpieczeństwo przetwarzania: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "rodo_exclusion_2", false) == false
}

# jdg.micro.rodo.a32.r7: rodo_a32_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a32.r7",
    "package": "jdg.micro.rodo",
    "priority": 210036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Bezpieczeństwo przetwarzania: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "rodo_a32_exception", false) == true
}

# jdg.micro.rodo.a32.r8: rodo_a32_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a32.r8",
    "package": "jdg.micro.rodo",
    "priority": 210037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Bezpieczeństwo przetwarzania: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "rodo_a32_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  rodo.a33 — Zgłaszanie naruszeń (8 reguł)                                    ║
# ║  Legal basis: RODO — Rozporządzenie UE 2016/679                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.rodo.a33.r1: rodo_a33_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a33.r1",
    "package": "jdg.micro.rodo",
    "priority": 210038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Zgłaszanie naruszeń: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.rodo.a33.r2: rodo_a33_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a33.r2",
    "package": "jdg.micro.rodo",
    "priority": 210039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Zgłaszanie naruszeń: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "rodo_condition_met", false) == true
}

# jdg.micro.rodo.a33.r3: rodo_a33_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a33.r3",
    "package": "jdg.micro.rodo",
    "priority": 210040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Zgłaszanie naruszeń: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a33_r3_pass", false) == true
}

# jdg.micro.rodo.a33.r4: rodo_a33_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a33.r4",
    "package": "jdg.micro.rodo",
    "priority": 210041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Zgłaszanie naruszeń: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "rodo_a33_r4_checks", false) == true
}

# jdg.micro.rodo.a33.r5: rodo_a33_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a33.r5",
    "package": "jdg.micro.rodo",
    "priority": 210042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Zgłaszanie naruszeń: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "rodo_exclusion_applies", false) == false
}

# jdg.micro.rodo.a33.r6: rodo_a33_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a33.r6",
    "package": "jdg.micro.rodo",
    "priority": 210043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Zgłaszanie naruszeń: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "rodo_exclusion_2", false) == false
}

# jdg.micro.rodo.a33.r7: rodo_a33_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a33.r7",
    "package": "jdg.micro.rodo",
    "priority": 210044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Zgłaszanie naruszeń: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "rodo_a33_exception", false) == true
}

# jdg.micro.rodo.a33.r8: rodo_a33_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.rodo.a33.r8",
    "package": "jdg.micro.rodo",
    "priority": 210045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "RODO — Rozporządzenie UE 2016/679",
    "_warnings": ["[MICRO] Zgłaszanie naruszeń: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "rodo_a33_exception_2", false) == true
}
