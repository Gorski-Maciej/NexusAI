# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa o CEIDG — 15 artykułów → ~150 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.ceidg
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.ceidg

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.ceidg.no_match",
    "package": "jdg.micro.ceidg",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ceidg.a5 — Zgłoszenie do CEIDG (8 reguł)                                    ║
# ║  Legal basis: Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ceidg.a5.r1: ceidg_a5_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5.r1",
    "package": "jdg.micro.ceidg",
    "priority": 140005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zgłoszenie do CEIDG: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ceidg.a5.r2: ceidg_a5_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5.r2",
    "package": "jdg.micro.ceidg",
    "priority": 140006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zgłoszenie do CEIDG: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ceidg_condition_met", false) == true
}

# jdg.micro.ceidg.a5.r3: ceidg_a5_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5.r3",
    "package": "jdg.micro.ceidg",
    "priority": 140007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zgłoszenie do CEIDG: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a5_r3_pass", false) == true
}

# jdg.micro.ceidg.a5.r4: ceidg_a5_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5.r4",
    "package": "jdg.micro.ceidg",
    "priority": 140008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zgłoszenie do CEIDG: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a5_r4_checks", false) == true
}

# jdg.micro.ceidg.a5.r5: ceidg_a5_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5.r5",
    "package": "jdg.micro.ceidg",
    "priority": 140009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zgłoszenie do CEIDG: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ceidg_exclusion_applies", false) == false
}

# jdg.micro.ceidg.a5.r6: ceidg_a5_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5.r6",
    "package": "jdg.micro.ceidg",
    "priority": 140010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zgłoszenie do CEIDG: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ceidg_exclusion_2", false) == false
}

# jdg.micro.ceidg.a5.r7: ceidg_a5_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5.r7",
    "package": "jdg.micro.ceidg",
    "priority": 140011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zgłoszenie do CEIDG: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ceidg_a5_exception", false) == true
}

# jdg.micro.ceidg.a5.r8: ceidg_a5_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5.r8",
    "package": "jdg.micro.ceidg",
    "priority": 140012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zgłoszenie do CEIDG: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ceidg_a5_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ceidg.a12 — Zmiany wpisu (8 reguł)                                    ║
# ║  Legal basis: Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ceidg.a12.r1: ceidg_a12_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a12.r1",
    "package": "jdg.micro.ceidg",
    "priority": 140013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zmiany wpisu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ceidg.a12.r2: ceidg_a12_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a12.r2",
    "package": "jdg.micro.ceidg",
    "priority": 140014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zmiany wpisu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ceidg_condition_met", false) == true
}

# jdg.micro.ceidg.a12.r3: ceidg_a12_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a12.r3",
    "package": "jdg.micro.ceidg",
    "priority": 140015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zmiany wpisu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a12_r3_pass", false) == true
}

# jdg.micro.ceidg.a12.r4: ceidg_a12_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a12.r4",
    "package": "jdg.micro.ceidg",
    "priority": 140016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zmiany wpisu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a12_r4_checks", false) == true
}

# jdg.micro.ceidg.a12.r5: ceidg_a12_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a12.r5",
    "package": "jdg.micro.ceidg",
    "priority": 140017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zmiany wpisu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ceidg_exclusion_applies", false) == false
}

# jdg.micro.ceidg.a12.r6: ceidg_a12_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a12.r6",
    "package": "jdg.micro.ceidg",
    "priority": 140018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zmiany wpisu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ceidg_exclusion_2", false) == false
}

# jdg.micro.ceidg.a12.r7: ceidg_a12_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a12.r7",
    "package": "jdg.micro.ceidg",
    "priority": 140019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zmiany wpisu: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ceidg_a12_exception", false) == true
}

# jdg.micro.ceidg.a12.r8: ceidg_a12_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a12.r8",
    "package": "jdg.micro.ceidg",
    "priority": 140020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zmiany wpisu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ceidg_a12_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ceidg.a15 — Zawieszenie w CEIDG (6 reguł)                                    ║
# ║  Legal basis: Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ceidg.a15.r1: ceidg_a15_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a15.r1",
    "package": "jdg.micro.ceidg",
    "priority": 140021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zawieszenie w CEIDG: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ceidg.a15.r2: ceidg_a15_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a15.r2",
    "package": "jdg.micro.ceidg",
    "priority": 140022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zawieszenie w CEIDG: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ceidg_condition_met", false) == true
}

# jdg.micro.ceidg.a15.r3: ceidg_a15_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a15.r3",
    "package": "jdg.micro.ceidg",
    "priority": 140023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zawieszenie w CEIDG: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a15_r3_pass", false) == true
}

# jdg.micro.ceidg.a15.r4: ceidg_a15_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a15.r4",
    "package": "jdg.micro.ceidg",
    "priority": 140024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zawieszenie w CEIDG: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a15_r4_checks", false) == true
}

# jdg.micro.ceidg.a15.r5: ceidg_a15_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a15.r5",
    "package": "jdg.micro.ceidg",
    "priority": 140025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zawieszenie w CEIDG: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ceidg_exclusion_applies", false) == false
}

# jdg.micro.ceidg.a15.r6: ceidg_a15_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a15.r6",
    "package": "jdg.micro.ceidg",
    "priority": 140026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Zawieszenie w CEIDG: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ceidg_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ceidg.a22 — Wykreślenie z CEIDG (6 reguł)                                    ║
# ║  Legal basis: Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ceidg.a22.r1: ceidg_a22_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a22.r1",
    "package": "jdg.micro.ceidg",
    "priority": 140027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wykreślenie z CEIDG: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ceidg.a22.r2: ceidg_a22_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a22.r2",
    "package": "jdg.micro.ceidg",
    "priority": 140028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wykreślenie z CEIDG: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ceidg_condition_met", false) == true
}

# jdg.micro.ceidg.a22.r3: ceidg_a22_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a22.r3",
    "package": "jdg.micro.ceidg",
    "priority": 140029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wykreślenie z CEIDG: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a22_r3_pass", false) == true
}

# jdg.micro.ceidg.a22.r4: ceidg_a22_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a22.r4",
    "package": "jdg.micro.ceidg",
    "priority": 140030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wykreślenie z CEIDG: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a22_r4_checks", false) == true
}

# jdg.micro.ceidg.a22.r5: ceidg_a22_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a22.r5",
    "package": "jdg.micro.ceidg",
    "priority": 140031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wykreślenie z CEIDG: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ceidg_exclusion_applies", false) == false
}

# jdg.micro.ceidg.a22.r6: ceidg_a22_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a22.r6",
    "package": "jdg.micro.ceidg",
    "priority": 140032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wykreślenie z CEIDG: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ceidg_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ceidg.a25 — Wznowienie wpisu (6 reguł)                                    ║
# ║  Legal basis: Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ceidg.a25.r1: ceidg_a25_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a25.r1",
    "package": "jdg.micro.ceidg",
    "priority": 140033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wznowienie wpisu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ceidg.a25.r2: ceidg_a25_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a25.r2",
    "package": "jdg.micro.ceidg",
    "priority": 140034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wznowienie wpisu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ceidg_condition_met", false) == true
}

# jdg.micro.ceidg.a25.r3: ceidg_a25_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a25.r3",
    "package": "jdg.micro.ceidg",
    "priority": 140035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wznowienie wpisu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a25_r3_pass", false) == true
}

# jdg.micro.ceidg.a25.r4: ceidg_a25_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a25.r4",
    "package": "jdg.micro.ceidg",
    "priority": 140036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wznowienie wpisu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_a25_r4_checks", false) == true
}

# jdg.micro.ceidg.a25.r5: ceidg_a25_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a25.r5",
    "package": "jdg.micro.ceidg",
    "priority": 140037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wznowienie wpisu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ceidg_exclusion_applies", false) == false
}

# jdg.micro.ceidg.a25.r6: ceidg_a25_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a25.r6",
    "package": "jdg.micro.ceidg",
    "priority": 140038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "_warnings": ["[MICRO] Wznowienie wpisu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ceidg_exclusion_2", false) == false
}
