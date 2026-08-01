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

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ceidg.a13 — Termin 7 dni na zgłoszenie zmian (3 reguły) P24 L-CEIDG-2     ║
# ║  Legal basis: Art. 14 ust. 1 ustawy o CEIDG                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ceidg.a13.r1: ceidg_a13_r1_change_deadline_7_days
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a13.r1",
    "package": "jdg.micro.ceidg",
    "priority": 140039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Termin 7 dni na zgłoszenie zmiany danych w CEIDG PRZEKROCZONY",
    "_legal_basis": "Art. 14 ust. 1 ustawy o CEIDG",
    "_warnings": ["[MICRO] L-CEIDG-2: Zmianę danych w CEIDG należy zgłosić w ciągu 7 DNI od jej zaistnienia. Przekroczenie terminu = kara porządkowa 700 zł (przy powtórce do 1 400 zł)!"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_data_changed", false) == true
    object.get(input.jdg_entrepreneur, "ceidg_change_days_elapsed", 0) > 7
    object.get(input.jdg_entrepreneur, "ceidg_change_reported", false) == false
}

# jdg.micro.ceidg.a13.r2: ceidg_a13_r2_sanction_first
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a13.r2",
    "package": "jdg.micro.ceidg",
    "priority": 140040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_base_amount_pln": 700,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja: pierwsze naruszenie terminu 7 dni — kara porządkowa 700 zł",
    "_legal_basis": "Art. 48-49 ustawy o CEIDG",
    "_warnings": ["[MICRO] L-CEIDG-2: PIERWSZE naruszenie terminu 7 dni. Kara porządkowa: 700 zł. Zgłoś zmianę niezwłocznie!"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_deadline_violation_count", 0) == 1
}

# jdg.micro.ceidg.a13.r3: ceidg_a13_r3_sanction_repeat
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a13.r3",
    "package": "jdg.micro.ceidg",
    "priority": 140041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_base_amount_pln": 1400,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja: powtórne naruszenie terminu 7 dni — kara porządkowa do 1 400 zł",
    "_legal_basis": "Art. 48-49 ustawy o CEIDG",
    "_warnings": ["[MICRO] L-CEIDG-2: POWTÓRNE naruszenie terminu 7 dni. Kara porządkowa: do 1 400 zł. Systematyczne naruszenia mogą skutkować wykreśleniem z CEIDG!"]
} {
    object.get(input.jdg_entrepreneur, "ceidg_deadline_violation_count", 0) >= 2
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ceidg.a5data — Dane obowiązkowe CEIDG-1 (5 reguł) P24 L-CEIDG-1           ║
# ║  Legal basis: Art. 5-7 ustawy o CEIDG                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ceidg.a5data.r1: ceidg_a5data_r1_personal_data_required
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5data.r1",
    "package": "jdg.micro.ceidg",
    "priority": 140042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": true,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CEIDG-1 — brak wymaganych danych osobowych (imię, nazwisko, PESEL)",
    "_legal_basis": "Art. 5 ustawy o CEIDG",
    "_warnings": ["[MICRO] L-CEIDG-1: Wniosek CEIDG-1 wymaga: imię, nazwisko, PESEL (lub data urodzenia), NIP, adres zamieszkania. Brak danych = wniosek niekompletny."]
} {
    object.get(input.jdg_entrepreneur, "ceidg_application_filed", false) == true
    object.get(input.jdg_entrepreneur, "ceidg_personal_data_complete", false) == false
}

# jdg.micro.ceidg.a5data.r2: ceidg_a5data_r2_business_data_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5data.r2",
    "package": "jdg.micro.ceidg",
    "priority": 140043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": true,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CEIDG-1 — brak danych działalności (PKD, adres, forma)",
    "_legal_basis": "Art. 6 ustawy o CEIDG",
    "_warnings": ["[MICRO] L-CEIDG-1: Wniosek CEIDG-1 wymaga: kody PKD (główny + dodatkowe), adres prowadzenia działalności, forma prawna (JDG), data rozpoczęcia."]
} {
    object.get(input.jdg_entrepreneur, "ceidg_application_filed", false) == true
    object.get(input.jdg_entrepreneur, "ceidg_business_data_complete", false) == false
}

# jdg.micro.ceidg.a5data.r3: ceidg_a5data_r3_tax_form_selection_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5data.r3",
    "package": "jdg.micro.ceidg",
    "priority": 140044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "CEIDG-1 — wybór formy opodatkowania (skala/ryczałt/liniowy/karta)",
    "_legal_basis": "Art. 7 ustawy o CEIDG",
    "_warnings": ["[MICRO] L-CEIDG-1: We wniosku CEIDG-1 należy wskazać formę opodatkowania PIT (skala/ryczałt/liniowy/karta). Wybór można zmienić do 20. dnia następnego miesiąca."]
} {
    object.get(input.jdg_entrepreneur, "ceidg_application_filed", false) == true
    object.get(input.jdg_entrepreneur, "tax_form_selected", "") == ""
}

# jdg.micro.ceidg.a5data.r4: ceidg_a5data_r4_zus_registration_required
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5data.r4",
    "package": "jdg.micro.ceidg",
    "priority": 140045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "CEIDG-1 — zgłoszenie do ZUS automatycznie przez CEIDG",
    "_legal_basis": "Art. 7a ustawy o CEIDG (CEIDG ↔ ZUS integracja)",
    "_warnings": ["[MICRO] L-CEIDG-1: CEIDG automatycznie przekazuje dane do ZUS (ZUS ZUA). Nie musisz składać osobnego zgłoszenia — system zrobi to za Ciebie w ciągu 7 dni."]
} {
    object.get(input.jdg_entrepreneur, "ceidg_application_filed", false) == true
    object.get(input.jdg_entrepreneur, "zus_zua_auto_from_ceidg", false) == false
}

# jdg.micro.ceidg.a5data.r5: ceidg_a5data_r5_nip_auto_assignment
else := {
    "matched": true,
    "rule_id": "jdg.micro.ceidg.a5data.r5",
    "package": "jdg.micro.ceidg",
    "priority": 140046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "CEIDG-1 — NIP nadawany automatycznie przy rejestracji",
    "_legal_basis": "Art. 8 ustawy o CEIDG",
    "_warnings": ["[MICRO] L-CEIDG-1: NIP nadawany automatycznie przy rejestracji CEIDG-1. Nie musisz składać osobnego zgłoszenia NIP-7."]
} {
    object.get(input.jdg_entrepreneur, "ceidg_application_filed", false) == true
    object.get(input.jdg_entrepreneur, "nip_assigned_auto", false) == false
    object.get(input.jdg_entrepreneur, "nip_separate_form_filed", false) == true
}
