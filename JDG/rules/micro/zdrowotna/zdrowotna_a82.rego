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