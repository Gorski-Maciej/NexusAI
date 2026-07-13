# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: KKS — Kodeks Karny Skarbowy — 40 artykułów → ~480 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.kks
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.kks

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.kks.no_match",
    "package": "jdg.micro.kks",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a16 — Czynny żal (12 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a16.r1: kks_a16_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r1",
    "package": "jdg.micro.kks",
    "priority": 80016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a16.r2: kks_a16_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r2",
    "package": "jdg.micro.kks",
    "priority": 80017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a16.r3: kks_a16_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r3",
    "package": "jdg.micro.kks",
    "priority": 80018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a16_r3_pass", false) == true
}

# jdg.micro.kks.a16.r4: kks_a16_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r4",
    "package": "jdg.micro.kks",
    "priority": 80019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a16_r4_checks", false) == true
}

# jdg.micro.kks.a16.r5: kks_a16_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r5",
    "package": "jdg.micro.kks",
    "priority": 80020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a16.r6: kks_a16_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r6",
    "package": "jdg.micro.kks",
    "priority": 80021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a16.r7: kks_a16_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r7",
    "package": "jdg.micro.kks",
    "priority": 80022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a16_exception", false) == true
}

# jdg.micro.kks.a16.r8: kks_a16_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r8",
    "package": "jdg.micro.kks",
    "priority": 80023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a16_exception_2", false) == true
}

# jdg.micro.kks.a16.r9: kks_a16_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r9",
    "package": "jdg.micro.kks",
    "priority": 80024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a16.r10: kks_a16_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r10",
    "package": "jdg.micro.kks",
    "priority": 80025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# jdg.micro.kks.a16.r11: kks_a16_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r11",
    "package": "jdg.micro.kks",
    "priority": 80026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "kks_deadline_required", false) == true
}

# jdg.micro.kks.a16.r12: kks_a16_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.r12",
    "package": "jdg.micro.kks",
    "priority": 80027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "CRITICAL",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Czynny żal",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Czynny żal: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "kks_a16_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a20 — Przedawnienie karalności — przestępstwa (8 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a20.r1: kks_a20_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a20.r1",
    "package": "jdg.micro.kks",
    "priority": 80028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — przestępstwa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a20.r2: kks_a20_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a20.r2",
    "package": "jdg.micro.kks",
    "priority": 80029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — przestępstwa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a20.r3: kks_a20_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a20.r3",
    "package": "jdg.micro.kks",
    "priority": 80030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — przestępstwa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a20_r3_pass", false) == true
}

# jdg.micro.kks.a20.r4: kks_a20_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a20.r4",
    "package": "jdg.micro.kks",
    "priority": 80031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — przestępstwa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a20_r4_checks", false) == true
}

# jdg.micro.kks.a20.r5: kks_a20_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a20.r5",
    "package": "jdg.micro.kks",
    "priority": 80032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — przestępstwa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a20.r6: kks_a20_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a20.r6",
    "package": "jdg.micro.kks",
    "priority": 80033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — przestępstwa: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a20.r7: kks_a20_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a20.r7",
    "package": "jdg.micro.kks",
    "priority": 80034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — przestępstwa: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a20_exception", false) == true
}

# jdg.micro.kks.a20.r8: kks_a20_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a20.r8",
    "package": "jdg.micro.kks",
    "priority": 80035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — przestępstwa: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a20_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a21 — Przedawnienie karalności — wykroczenia (8 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a21.r1: kks_a21_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a21.r1",
    "package": "jdg.micro.kks",
    "priority": 80036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — wykroczenia: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a21.r2: kks_a21_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a21.r2",
    "package": "jdg.micro.kks",
    "priority": 80037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — wykroczenia: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a21.r3: kks_a21_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a21.r3",
    "package": "jdg.micro.kks",
    "priority": 80038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — wykroczenia: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a21_r3_pass", false) == true
}

# jdg.micro.kks.a21.r4: kks_a21_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a21.r4",
    "package": "jdg.micro.kks",
    "priority": 80039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — wykroczenia: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a21_r4_checks", false) == true
}

# jdg.micro.kks.a21.r5: kks_a21_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a21.r5",
    "package": "jdg.micro.kks",
    "priority": 80040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — wykroczenia: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a21.r6: kks_a21_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a21.r6",
    "package": "jdg.micro.kks",
    "priority": 80041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — wykroczenia: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a21.r7: kks_a21_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a21.r7",
    "package": "jdg.micro.kks",
    "priority": 80042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — wykroczenia: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a21_exception", false) == true
}

# jdg.micro.kks.a21.r8: kks_a21_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a21.r8",
    "package": "jdg.micro.kks",
    "priority": 80043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przedawnienie karalności — wykroczenia: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a21_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a54 — Uchylanie się od opodatkowania (15 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a54.r1: kks_a54_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r1",
    "package": "jdg.micro.kks",
    "priority": 80044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a54.r2: kks_a54_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r2",
    "package": "jdg.micro.kks",
    "priority": 80045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a54.r3: kks_a54_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r3",
    "package": "jdg.micro.kks",
    "priority": 80046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a54_r3_pass", false) == true
}

# jdg.micro.kks.a54.r4: kks_a54_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r4",
    "package": "jdg.micro.kks",
    "priority": 80047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a54_r4_checks", false) == true
}

# jdg.micro.kks.a54.r5: kks_a54_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r5",
    "package": "jdg.micro.kks",
    "priority": 80048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a54.r6: kks_a54_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r6",
    "package": "jdg.micro.kks",
    "priority": 80049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a54.r7: kks_a54_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r7",
    "package": "jdg.micro.kks",
    "priority": 80050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a54_exception", false) == true
}

# jdg.micro.kks.a54.r8: kks_a54_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r8",
    "package": "jdg.micro.kks",
    "priority": 80051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a54_exception_2", false) == true
}

# jdg.micro.kks.a54.r9: kks_a54_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r9",
    "package": "jdg.micro.kks",
    "priority": 80052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a54.r10: kks_a54_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r10",
    "package": "jdg.micro.kks",
    "priority": 80053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# jdg.micro.kks.a54.r11: kks_a54_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r11",
    "package": "jdg.micro.kks",
    "priority": 80054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "kks_deadline_required", false) == true
}

# jdg.micro.kks.a54.r12: kks_a54_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r12",
    "package": "jdg.micro.kks",
    "priority": 80055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "CRITICAL",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Uchylanie się od opodatkowania",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "kks_a54_violation", false) == true
}

# jdg.micro.kks.a54.r13: kks_a54_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r13",
    "package": "jdg.micro.kks",
    "priority": 80056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "kks_a54_edge_case", false) == true
}

# jdg.micro.kks.a54.r14: kks_a54_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r14",
    "package": "jdg.micro.kks",
    "priority": 80057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "kks_a54_edge_case_2", false) == true
}

# jdg.micro.kks.a54.r15: kks_a54_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.r15",
    "package": "jdg.micro.kks",
    "priority": 80058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Uchylanie się od opodatkowania: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "kks_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a55 — Oszustwo podatkowe (12 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a55.r1: kks_a55_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r1",
    "package": "jdg.micro.kks",
    "priority": 80059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a55.r2: kks_a55_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r2",
    "package": "jdg.micro.kks",
    "priority": 80060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a55.r3: kks_a55_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r3",
    "package": "jdg.micro.kks",
    "priority": 80061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a55_r3_pass", false) == true
}

# jdg.micro.kks.a55.r4: kks_a55_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r4",
    "package": "jdg.micro.kks",
    "priority": 80062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a55_r4_checks", false) == true
}

# jdg.micro.kks.a55.r5: kks_a55_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r5",
    "package": "jdg.micro.kks",
    "priority": 80063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a55.r6: kks_a55_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r6",
    "package": "jdg.micro.kks",
    "priority": 80064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a55.r7: kks_a55_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r7",
    "package": "jdg.micro.kks",
    "priority": 80065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a55_exception", false) == true
}

# jdg.micro.kks.a55.r8: kks_a55_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r8",
    "package": "jdg.micro.kks",
    "priority": 80066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a55_exception_2", false) == true
}

# jdg.micro.kks.a55.r9: kks_a55_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r9",
    "package": "jdg.micro.kks",
    "priority": 80067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a55.r10: kks_a55_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r10",
    "package": "jdg.micro.kks",
    "priority": 80068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# jdg.micro.kks.a55.r11: kks_a55_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r11",
    "package": "jdg.micro.kks",
    "priority": 80069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "kks_deadline_required", false) == true
}

# jdg.micro.kks.a55.r12: kks_a55_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a55.r12",
    "package": "jdg.micro.kks",
    "priority": 80070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "CRITICAL",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Oszustwo podatkowe",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo podatkowe: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "kks_a55_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a56 — Nierzetelne księgi / PKPiR (15 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a56.r1: kks_a56_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r1",
    "package": "jdg.micro.kks",
    "priority": 80071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a56.r2: kks_a56_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r2",
    "package": "jdg.micro.kks",
    "priority": 80072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a56.r3: kks_a56_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r3",
    "package": "jdg.micro.kks",
    "priority": 80073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a56_r3_pass", false) == true
}

# jdg.micro.kks.a56.r4: kks_a56_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r4",
    "package": "jdg.micro.kks",
    "priority": 80074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a56_r4_checks", false) == true
}

# jdg.micro.kks.a56.r5: kks_a56_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r5",
    "package": "jdg.micro.kks",
    "priority": 80075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a56.r6: kks_a56_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r6",
    "package": "jdg.micro.kks",
    "priority": 80076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a56.r7: kks_a56_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r7",
    "package": "jdg.micro.kks",
    "priority": 80077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a56_exception", false) == true
}

# jdg.micro.kks.a56.r8: kks_a56_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r8",
    "package": "jdg.micro.kks",
    "priority": 80078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a56_exception_2", false) == true
}

# jdg.micro.kks.a56.r9: kks_a56_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r9",
    "package": "jdg.micro.kks",
    "priority": 80079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a56.r10: kks_a56_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r10",
    "package": "jdg.micro.kks",
    "priority": 80080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# jdg.micro.kks.a56.r11: kks_a56_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r11",
    "package": "jdg.micro.kks",
    "priority": 80081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "kks_deadline_required", false) == true
}

# jdg.micro.kks.a56.r12: kks_a56_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r12",
    "package": "jdg.micro.kks",
    "priority": 80082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "CRITICAL",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Nierzetelne księgi / PKPiR",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "kks_a56_violation", false) == true
}

# jdg.micro.kks.a56.r13: kks_a56_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r13",
    "package": "jdg.micro.kks",
    "priority": 80083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "kks_a56_edge_case", false) == true
}

# jdg.micro.kks.a56.r14: kks_a56_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r14",
    "package": "jdg.micro.kks",
    "priority": 80084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "kks_a56_edge_case_2", false) == true
}

# jdg.micro.kks.a56.r15: kks_a56_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a56.r15",
    "package": "jdg.micro.kks",
    "priority": 80085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne księgi / PKPiR: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "kks_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a57 — Nierzetelna ewidencja VAT (12 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a57.r1: kks_a57_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r1",
    "package": "jdg.micro.kks",
    "priority": 80086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a57.r2: kks_a57_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r2",
    "package": "jdg.micro.kks",
    "priority": 80087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a57.r3: kks_a57_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r3",
    "package": "jdg.micro.kks",
    "priority": 80088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a57_r3_pass", false) == true
}

# jdg.micro.kks.a57.r4: kks_a57_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r4",
    "package": "jdg.micro.kks",
    "priority": 80089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a57_r4_checks", false) == true
}

# jdg.micro.kks.a57.r5: kks_a57_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r5",
    "package": "jdg.micro.kks",
    "priority": 80090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a57.r6: kks_a57_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r6",
    "package": "jdg.micro.kks",
    "priority": 80091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a57.r7: kks_a57_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r7",
    "package": "jdg.micro.kks",
    "priority": 80092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a57_exception", false) == true
}

# jdg.micro.kks.a57.r8: kks_a57_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r8",
    "package": "jdg.micro.kks",
    "priority": 80093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a57_exception_2", false) == true
}

# jdg.micro.kks.a57.r9: kks_a57_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r9",
    "package": "jdg.micro.kks",
    "priority": 80094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a57.r10: kks_a57_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r10",
    "package": "jdg.micro.kks",
    "priority": 80095,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# jdg.micro.kks.a57.r11: kks_a57_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r11",
    "package": "jdg.micro.kks",
    "priority": 80096,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "kks_deadline_required", false) == true
}

# jdg.micro.kks.a57.r12: kks_a57_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a57.r12",
    "package": "jdg.micro.kks",
    "priority": 80097,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "CRITICAL",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Nierzetelna ewidencja VAT",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelna ewidencja VAT: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "kks_a57_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a58 — Oszustwo w zakresie faktur (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a58.r1: kks_a58_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r1",
    "package": "jdg.micro.kks",
    "priority": 80098,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a58.r2: kks_a58_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r2",
    "package": "jdg.micro.kks",
    "priority": 80099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a58.r3: kks_a58_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r3",
    "package": "jdg.micro.kks",
    "priority": 80100,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a58_r3_pass", false) == true
}

# jdg.micro.kks.a58.r4: kks_a58_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r4",
    "package": "jdg.micro.kks",
    "priority": 80101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a58_r4_checks", false) == true
}

# jdg.micro.kks.a58.r5: kks_a58_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r5",
    "package": "jdg.micro.kks",
    "priority": 80102,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a58.r6: kks_a58_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r6",
    "package": "jdg.micro.kks",
    "priority": 80103,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a58.r7: kks_a58_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r7",
    "package": "jdg.micro.kks",
    "priority": 80104,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a58_exception", false) == true
}

# jdg.micro.kks.a58.r8: kks_a58_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r8",
    "package": "jdg.micro.kks",
    "priority": 80105,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a58_exception_2", false) == true
}

# jdg.micro.kks.a58.r9: kks_a58_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r9",
    "package": "jdg.micro.kks",
    "priority": 80106,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a58.r10: kks_a58_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a58.r10",
    "package": "jdg.micro.kks",
    "priority": 80107,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Oszustwo w zakresie faktur: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a59 — Fałszowanie dokumentów (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a59.r1: kks_a59_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r1",
    "package": "jdg.micro.kks",
    "priority": 80108,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a59.r2: kks_a59_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r2",
    "package": "jdg.micro.kks",
    "priority": 80109,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a59.r3: kks_a59_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r3",
    "package": "jdg.micro.kks",
    "priority": 80110,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a59_r3_pass", false) == true
}

# jdg.micro.kks.a59.r4: kks_a59_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r4",
    "package": "jdg.micro.kks",
    "priority": 80111,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a59_r4_checks", false) == true
}

# jdg.micro.kks.a59.r5: kks_a59_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r5",
    "package": "jdg.micro.kks",
    "priority": 80112,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a59.r6: kks_a59_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r6",
    "package": "jdg.micro.kks",
    "priority": 80113,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a59.r7: kks_a59_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r7",
    "package": "jdg.micro.kks",
    "priority": 80114,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a59_exception", false) == true
}

# jdg.micro.kks.a59.r8: kks_a59_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r8",
    "package": "jdg.micro.kks",
    "priority": 80115,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a59_exception_2", false) == true
}

# jdg.micro.kks.a59.r9: kks_a59_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r9",
    "package": "jdg.micro.kks",
    "priority": 80116,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a59.r10: kks_a59_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a59.r10",
    "package": "jdg.micro.kks",
    "priority": 80117,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Fałszowanie dokumentów: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a60 — Przekroczenie uprawnień (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a60.r1: kks_a60_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r1",
    "package": "jdg.micro.kks",
    "priority": 80118,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a60.r2: kks_a60_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r2",
    "package": "jdg.micro.kks",
    "priority": 80119,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a60.r3: kks_a60_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r3",
    "package": "jdg.micro.kks",
    "priority": 80120,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a60_r3_pass", false) == true
}

# jdg.micro.kks.a60.r4: kks_a60_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r4",
    "package": "jdg.micro.kks",
    "priority": 80121,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a60_r4_checks", false) == true
}

# jdg.micro.kks.a60.r5: kks_a60_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r5",
    "package": "jdg.micro.kks",
    "priority": 80122,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a60.r6: kks_a60_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r6",
    "package": "jdg.micro.kks",
    "priority": 80123,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a60.r7: kks_a60_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r7",
    "package": "jdg.micro.kks",
    "priority": 80124,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a60_exception", false) == true
}

# jdg.micro.kks.a60.r8: kks_a60_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r8",
    "package": "jdg.micro.kks",
    "priority": 80125,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a60_exception_2", false) == true
}

# jdg.micro.kks.a60.r9: kks_a60_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r9",
    "package": "jdg.micro.kks",
    "priority": 80126,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a60.r10: kks_a60_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a60.r10",
    "package": "jdg.micro.kks",
    "priority": 80127,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przekroczenie uprawnień: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a61 — Narażenie na uszczuplenie (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a61.r1: kks_a61_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r1",
    "package": "jdg.micro.kks",
    "priority": 80128,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a61.r2: kks_a61_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r2",
    "package": "jdg.micro.kks",
    "priority": 80129,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a61.r3: kks_a61_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r3",
    "package": "jdg.micro.kks",
    "priority": 80130,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a61_r3_pass", false) == true
}

# jdg.micro.kks.a61.r4: kks_a61_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r4",
    "package": "jdg.micro.kks",
    "priority": 80131,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a61_r4_checks", false) == true
}

# jdg.micro.kks.a61.r5: kks_a61_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r5",
    "package": "jdg.micro.kks",
    "priority": 80132,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a61.r6: kks_a61_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r6",
    "package": "jdg.micro.kks",
    "priority": 80133,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a61.r7: kks_a61_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r7",
    "package": "jdg.micro.kks",
    "priority": 80134,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a61_exception", false) == true
}

# jdg.micro.kks.a61.r8: kks_a61_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r8",
    "package": "jdg.micro.kks",
    "priority": 80135,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a61_exception_2", false) == true
}

# jdg.micro.kks.a61.r9: kks_a61_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r9",
    "package": "jdg.micro.kks",
    "priority": 80136,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a61.r10: kks_a61_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a61.r10",
    "package": "jdg.micro.kks",
    "priority": 80137,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Narażenie na uszczuplenie: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a62 — Puste faktury / fałszerstwo faktur (15 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a62.r1: kks_a62_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r1",
    "package": "jdg.micro.kks",
    "priority": 80138,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a62.r2: kks_a62_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r2",
    "package": "jdg.micro.kks",
    "priority": 80139,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a62.r3: kks_a62_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r3",
    "package": "jdg.micro.kks",
    "priority": 80140,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a62_r3_pass", false) == true
}

# jdg.micro.kks.a62.r4: kks_a62_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r4",
    "package": "jdg.micro.kks",
    "priority": 80141,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a62_r4_checks", false) == true
}

# jdg.micro.kks.a62.r5: kks_a62_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r5",
    "package": "jdg.micro.kks",
    "priority": 80142,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a62.r6: kks_a62_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r6",
    "package": "jdg.micro.kks",
    "priority": 80143,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a62.r7: kks_a62_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r7",
    "package": "jdg.micro.kks",
    "priority": 80144,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a62_exception", false) == true
}

# jdg.micro.kks.a62.r8: kks_a62_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r8",
    "package": "jdg.micro.kks",
    "priority": 80145,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a62_exception_2", false) == true
}

# jdg.micro.kks.a62.r9: kks_a62_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r9",
    "package": "jdg.micro.kks",
    "priority": 80146,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a62.r10: kks_a62_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r10",
    "package": "jdg.micro.kks",
    "priority": 80147,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# jdg.micro.kks.a62.r11: kks_a62_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r11",
    "package": "jdg.micro.kks",
    "priority": 80148,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "kks_deadline_required", false) == true
}

# jdg.micro.kks.a62.r12: kks_a62_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r12",
    "package": "jdg.micro.kks",
    "priority": 80149,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "CRITICAL",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Puste faktury / fałszerstwo faktur",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "kks_a62_violation", false) == true
}

# jdg.micro.kks.a62.r13: kks_a62_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r13",
    "package": "jdg.micro.kks",
    "priority": 80150,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "kks_a62_edge_case", false) == true
}

# jdg.micro.kks.a62.r14: kks_a62_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r14",
    "package": "jdg.micro.kks",
    "priority": 80151,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "kks_a62_edge_case_2", false) == true
}

# jdg.micro.kks.a62.r15: kks_a62_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a62.r15",
    "package": "jdg.micro.kks",
    "priority": 80152,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Puste faktury / fałszerstwo faktur: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "kks_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a63 — Niewystawienie faktury (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a63.r1: kks_a63_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r1",
    "package": "jdg.micro.kks",
    "priority": 80153,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a63.r2: kks_a63_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r2",
    "package": "jdg.micro.kks",
    "priority": 80154,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a63.r3: kks_a63_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r3",
    "package": "jdg.micro.kks",
    "priority": 80155,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a63_r3_pass", false) == true
}

# jdg.micro.kks.a63.r4: kks_a63_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r4",
    "package": "jdg.micro.kks",
    "priority": 80156,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a63_r4_checks", false) == true
}

# jdg.micro.kks.a63.r5: kks_a63_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r5",
    "package": "jdg.micro.kks",
    "priority": 80157,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a63.r6: kks_a63_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r6",
    "package": "jdg.micro.kks",
    "priority": 80158,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a63.r7: kks_a63_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r7",
    "package": "jdg.micro.kks",
    "priority": 80159,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a63_exception", false) == true
}

# jdg.micro.kks.a63.r8: kks_a63_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r8",
    "package": "jdg.micro.kks",
    "priority": 80160,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a63_exception_2", false) == true
}

# jdg.micro.kks.a63.r9: kks_a63_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r9",
    "package": "jdg.micro.kks",
    "priority": 80161,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a63.r10: kks_a63_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a63.r10",
    "package": "jdg.micro.kks",
    "priority": 80162,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewystawienie faktury: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a64 — Niewłaściwa stawka VAT (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a64.r1: kks_a64_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r1",
    "package": "jdg.micro.kks",
    "priority": 80163,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a64.r2: kks_a64_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r2",
    "package": "jdg.micro.kks",
    "priority": 80164,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a64.r3: kks_a64_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r3",
    "package": "jdg.micro.kks",
    "priority": 80165,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a64_r3_pass", false) == true
}

# jdg.micro.kks.a64.r4: kks_a64_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r4",
    "package": "jdg.micro.kks",
    "priority": 80166,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a64_r4_checks", false) == true
}

# jdg.micro.kks.a64.r5: kks_a64_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r5",
    "package": "jdg.micro.kks",
    "priority": 80167,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a64.r6: kks_a64_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r6",
    "package": "jdg.micro.kks",
    "priority": 80168,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a64.r7: kks_a64_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r7",
    "package": "jdg.micro.kks",
    "priority": 80169,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a64_exception", false) == true
}

# jdg.micro.kks.a64.r8: kks_a64_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r8",
    "package": "jdg.micro.kks",
    "priority": 80170,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a64_exception_2", false) == true
}

# jdg.micro.kks.a64.r9: kks_a64_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r9",
    "package": "jdg.micro.kks",
    "priority": 80171,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a64.r10: kks_a64_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a64.r10",
    "package": "jdg.micro.kks",
    "priority": 80172,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewłaściwa stawka VAT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a65 — Zawyżenie zwrotu VAT (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a65.r1: kks_a65_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r1",
    "package": "jdg.micro.kks",
    "priority": 80173,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a65.r2: kks_a65_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r2",
    "package": "jdg.micro.kks",
    "priority": 80174,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a65.r3: kks_a65_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r3",
    "package": "jdg.micro.kks",
    "priority": 80175,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a65_r3_pass", false) == true
}

# jdg.micro.kks.a65.r4: kks_a65_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r4",
    "package": "jdg.micro.kks",
    "priority": 80176,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a65_r4_checks", false) == true
}

# jdg.micro.kks.a65.r5: kks_a65_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r5",
    "package": "jdg.micro.kks",
    "priority": 80177,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a65.r6: kks_a65_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r6",
    "package": "jdg.micro.kks",
    "priority": 80178,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a65.r7: kks_a65_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r7",
    "package": "jdg.micro.kks",
    "priority": 80179,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a65_exception", false) == true
}

# jdg.micro.kks.a65.r8: kks_a65_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r8",
    "package": "jdg.micro.kks",
    "priority": 80180,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a65_exception_2", false) == true
}

# jdg.micro.kks.a65.r9: kks_a65_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r9",
    "package": "jdg.micro.kks",
    "priority": 80181,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a65.r10: kks_a65_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a65.r10",
    "package": "jdg.micro.kks",
    "priority": 80182,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zawyżenie zwrotu VAT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a66 — Nierzetelne zeznanie (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a66.r1: kks_a66_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r1",
    "package": "jdg.micro.kks",
    "priority": 80183,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a66.r2: kks_a66_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r2",
    "package": "jdg.micro.kks",
    "priority": 80184,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a66.r3: kks_a66_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r3",
    "package": "jdg.micro.kks",
    "priority": 80185,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a66_r3_pass", false) == true
}

# jdg.micro.kks.a66.r4: kks_a66_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r4",
    "package": "jdg.micro.kks",
    "priority": 80186,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a66_r4_checks", false) == true
}

# jdg.micro.kks.a66.r5: kks_a66_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r5",
    "package": "jdg.micro.kks",
    "priority": 80187,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a66.r6: kks_a66_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r6",
    "package": "jdg.micro.kks",
    "priority": 80188,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a66.r7: kks_a66_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r7",
    "package": "jdg.micro.kks",
    "priority": 80189,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a66_exception", false) == true
}

# jdg.micro.kks.a66.r8: kks_a66_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r8",
    "package": "jdg.micro.kks",
    "priority": 80190,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a66_exception_2", false) == true
}

# jdg.micro.kks.a66.r9: kks_a66_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r9",
    "package": "jdg.micro.kks",
    "priority": 80191,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a66.r10: kks_a66_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a66.r10",
    "package": "jdg.micro.kks",
    "priority": 80192,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nierzetelne zeznanie: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a67 — Nieprowadzenie ksiąg (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a67.r1: kks_a67_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r1",
    "package": "jdg.micro.kks",
    "priority": 80193,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a67.r2: kks_a67_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r2",
    "package": "jdg.micro.kks",
    "priority": 80194,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a67.r3: kks_a67_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r3",
    "package": "jdg.micro.kks",
    "priority": 80195,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a67_r3_pass", false) == true
}

# jdg.micro.kks.a67.r4: kks_a67_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r4",
    "package": "jdg.micro.kks",
    "priority": 80196,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a67_r4_checks", false) == true
}

# jdg.micro.kks.a67.r5: kks_a67_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r5",
    "package": "jdg.micro.kks",
    "priority": 80197,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a67.r6: kks_a67_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r6",
    "package": "jdg.micro.kks",
    "priority": 80198,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a67.r7: kks_a67_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r7",
    "package": "jdg.micro.kks",
    "priority": 80199,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a67_exception", false) == true
}

# jdg.micro.kks.a67.r8: kks_a67_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r8",
    "package": "jdg.micro.kks",
    "priority": 80200,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a67_exception_2", false) == true
}

# jdg.micro.kks.a67.r9: kks_a67_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r9",
    "package": "jdg.micro.kks",
    "priority": 80201,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a67.r10: kks_a67_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a67.r10",
    "package": "jdg.micro.kks",
    "priority": 80202,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprowadzenie ksiąg: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a68 — Zniszczenie dokumentów (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a68.r1: kks_a68_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r1",
    "package": "jdg.micro.kks",
    "priority": 80203,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a68.r2: kks_a68_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r2",
    "package": "jdg.micro.kks",
    "priority": 80204,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a68.r3: kks_a68_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r3",
    "package": "jdg.micro.kks",
    "priority": 80205,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a68_r3_pass", false) == true
}

# jdg.micro.kks.a68.r4: kks_a68_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r4",
    "package": "jdg.micro.kks",
    "priority": 80206,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a68_r4_checks", false) == true
}

# jdg.micro.kks.a68.r5: kks_a68_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r5",
    "package": "jdg.micro.kks",
    "priority": 80207,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a68.r6: kks_a68_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r6",
    "package": "jdg.micro.kks",
    "priority": 80208,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a68.r7: kks_a68_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r7",
    "package": "jdg.micro.kks",
    "priority": 80209,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a68_exception", false) == true
}

# jdg.micro.kks.a68.r8: kks_a68_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r8",
    "package": "jdg.micro.kks",
    "priority": 80210,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a68_exception_2", false) == true
}

# jdg.micro.kks.a68.r9: kks_a68_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r9",
    "package": "jdg.micro.kks",
    "priority": 80211,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a68.r10: kks_a68_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a68.r10",
    "package": "jdg.micro.kks",
    "priority": 80212,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Zniszczenie dokumentów: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a69 — Utrudnianie kontroli (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a69.r1: kks_a69_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r1",
    "package": "jdg.micro.kks",
    "priority": 80213,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a69.r2: kks_a69_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r2",
    "package": "jdg.micro.kks",
    "priority": 80214,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a69.r3: kks_a69_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r3",
    "package": "jdg.micro.kks",
    "priority": 80215,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a69_r3_pass", false) == true
}

# jdg.micro.kks.a69.r4: kks_a69_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r4",
    "package": "jdg.micro.kks",
    "priority": 80216,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a69_r4_checks", false) == true
}

# jdg.micro.kks.a69.r5: kks_a69_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r5",
    "package": "jdg.micro.kks",
    "priority": 80217,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a69.r6: kks_a69_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r6",
    "package": "jdg.micro.kks",
    "priority": 80218,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a69.r7: kks_a69_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r7",
    "package": "jdg.micro.kks",
    "priority": 80219,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a69_exception", false) == true
}

# jdg.micro.kks.a69.r8: kks_a69_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r8",
    "package": "jdg.micro.kks",
    "priority": 80220,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a69_exception_2", false) == true
}

# jdg.micro.kks.a69.r9: kks_a69_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r9",
    "package": "jdg.micro.kks",
    "priority": 80221,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a69.r10: kks_a69_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a69.r10",
    "package": "jdg.micro.kks",
    "priority": 80222,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Utrudnianie kontroli: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a70 — Nieskładanie deklaracji (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a70.r1: kks_a70_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r1",
    "package": "jdg.micro.kks",
    "priority": 80223,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a70.r2: kks_a70_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r2",
    "package": "jdg.micro.kks",
    "priority": 80224,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a70.r3: kks_a70_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r3",
    "package": "jdg.micro.kks",
    "priority": 80225,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a70_r3_pass", false) == true
}

# jdg.micro.kks.a70.r4: kks_a70_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r4",
    "package": "jdg.micro.kks",
    "priority": 80226,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a70_r4_checks", false) == true
}

# jdg.micro.kks.a70.r5: kks_a70_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r5",
    "package": "jdg.micro.kks",
    "priority": 80227,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a70.r6: kks_a70_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r6",
    "package": "jdg.micro.kks",
    "priority": 80228,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a70.r7: kks_a70_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r7",
    "package": "jdg.micro.kks",
    "priority": 80229,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a70_exception", false) == true
}

# jdg.micro.kks.a70.r8: kks_a70_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r8",
    "package": "jdg.micro.kks",
    "priority": 80230,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a70_exception_2", false) == true
}

# jdg.micro.kks.a70.r9: kks_a70_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r9",
    "package": "jdg.micro.kks",
    "priority": 80231,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a70.r10: kks_a70_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a70.r10",
    "package": "jdg.micro.kks",
    "priority": 80232,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieskładanie deklaracji: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a71 — Naruszenie obowiązków płatniczych (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a71.r1: kks_a71_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r1",
    "package": "jdg.micro.kks",
    "priority": 80233,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a71.r2: kks_a71_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r2",
    "package": "jdg.micro.kks",
    "priority": 80234,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a71.r3: kks_a71_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r3",
    "package": "jdg.micro.kks",
    "priority": 80235,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a71_r3_pass", false) == true
}

# jdg.micro.kks.a71.r4: kks_a71_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r4",
    "package": "jdg.micro.kks",
    "priority": 80236,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a71_r4_checks", false) == true
}

# jdg.micro.kks.a71.r5: kks_a71_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r5",
    "package": "jdg.micro.kks",
    "priority": 80237,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a71.r6: kks_a71_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r6",
    "package": "jdg.micro.kks",
    "priority": 80238,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a71.r7: kks_a71_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r7",
    "package": "jdg.micro.kks",
    "priority": 80239,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a71_exception", false) == true
}

# jdg.micro.kks.a71.r8: kks_a71_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r8",
    "package": "jdg.micro.kks",
    "priority": 80240,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a71_exception_2", false) == true
}

# jdg.micro.kks.a71.r9: kks_a71_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r9",
    "package": "jdg.micro.kks",
    "priority": 80241,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a71.r10: kks_a71_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a71.r10",
    "package": "jdg.micro.kks",
    "priority": 80242,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków płatniczych: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a72 — Niepobranie podatku (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a72.r1: kks_a72_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r1",
    "package": "jdg.micro.kks",
    "priority": 80243,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a72.r2: kks_a72_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r2",
    "package": "jdg.micro.kks",
    "priority": 80244,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a72.r3: kks_a72_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r3",
    "package": "jdg.micro.kks",
    "priority": 80245,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a72_r3_pass", false) == true
}

# jdg.micro.kks.a72.r4: kks_a72_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r4",
    "package": "jdg.micro.kks",
    "priority": 80246,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a72_r4_checks", false) == true
}

# jdg.micro.kks.a72.r5: kks_a72_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r5",
    "package": "jdg.micro.kks",
    "priority": 80247,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a72.r6: kks_a72_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r6",
    "package": "jdg.micro.kks",
    "priority": 80248,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a72.r7: kks_a72_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r7",
    "package": "jdg.micro.kks",
    "priority": 80249,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a72_exception", false) == true
}

# jdg.micro.kks.a72.r8: kks_a72_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r8",
    "package": "jdg.micro.kks",
    "priority": 80250,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a72_exception_2", false) == true
}

# jdg.micro.kks.a72.r9: kks_a72_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r9",
    "package": "jdg.micro.kks",
    "priority": 80251,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a72.r10: kks_a72_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a72.r10",
    "package": "jdg.micro.kks",
    "priority": 80252,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niepobranie podatku: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a73 — Niewpłacenie podatku (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a73.r1: kks_a73_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r1",
    "package": "jdg.micro.kks",
    "priority": 80253,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a73.r2: kks_a73_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r2",
    "package": "jdg.micro.kks",
    "priority": 80254,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a73.r3: kks_a73_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r3",
    "package": "jdg.micro.kks",
    "priority": 80255,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a73_r3_pass", false) == true
}

# jdg.micro.kks.a73.r4: kks_a73_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r4",
    "package": "jdg.micro.kks",
    "priority": 80256,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a73_r4_checks", false) == true
}

# jdg.micro.kks.a73.r5: kks_a73_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r5",
    "package": "jdg.micro.kks",
    "priority": 80257,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a73.r6: kks_a73_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r6",
    "package": "jdg.micro.kks",
    "priority": 80258,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a73.r7: kks_a73_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r7",
    "package": "jdg.micro.kks",
    "priority": 80259,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a73_exception", false) == true
}

# jdg.micro.kks.a73.r8: kks_a73_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r8",
    "package": "jdg.micro.kks",
    "priority": 80260,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a73_exception_2", false) == true
}

# jdg.micro.kks.a73.r9: kks_a73_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r9",
    "package": "jdg.micro.kks",
    "priority": 80261,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a73.r10: kks_a73_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a73.r10",
    "package": "jdg.micro.kks",
    "priority": 80262,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niewpłacenie podatku: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a74 — Naruszenie obowiązków ewidencyjnych (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a74.r1: kks_a74_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r1",
    "package": "jdg.micro.kks",
    "priority": 80263,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a74.r2: kks_a74_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r2",
    "package": "jdg.micro.kks",
    "priority": 80264,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a74.r3: kks_a74_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r3",
    "package": "jdg.micro.kks",
    "priority": 80265,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a74_r3_pass", false) == true
}

# jdg.micro.kks.a74.r4: kks_a74_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r4",
    "package": "jdg.micro.kks",
    "priority": 80266,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a74_r4_checks", false) == true
}

# jdg.micro.kks.a74.r5: kks_a74_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r5",
    "package": "jdg.micro.kks",
    "priority": 80267,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a74.r6: kks_a74_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r6",
    "package": "jdg.micro.kks",
    "priority": 80268,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a74.r7: kks_a74_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r7",
    "package": "jdg.micro.kks",
    "priority": 80269,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a74_exception", false) == true
}

# jdg.micro.kks.a74.r8: kks_a74_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r8",
    "package": "jdg.micro.kks",
    "priority": 80270,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a74_exception_2", false) == true
}

# jdg.micro.kks.a74.r9: kks_a74_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r9",
    "package": "jdg.micro.kks",
    "priority": 80271,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a74.r10: kks_a74_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a74.r10",
    "package": "jdg.micro.kks",
    "priority": 80272,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie obowiązków ewidencyjnych: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a75 — Naruszenie KSeF (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a75.r1: kks_a75_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r1",
    "package": "jdg.micro.kks",
    "priority": 80273,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a75.r2: kks_a75_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r2",
    "package": "jdg.micro.kks",
    "priority": 80274,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a75.r3: kks_a75_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r3",
    "package": "jdg.micro.kks",
    "priority": 80275,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a75_r3_pass", false) == true
}

# jdg.micro.kks.a75.r4: kks_a75_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r4",
    "package": "jdg.micro.kks",
    "priority": 80276,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a75_r4_checks", false) == true
}

# jdg.micro.kks.a75.r5: kks_a75_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r5",
    "package": "jdg.micro.kks",
    "priority": 80277,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a75.r6: kks_a75_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r6",
    "package": "jdg.micro.kks",
    "priority": 80278,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a75.r7: kks_a75_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r7",
    "package": "jdg.micro.kks",
    "priority": 80279,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a75_exception", false) == true
}

# jdg.micro.kks.a75.r8: kks_a75_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r8",
    "package": "jdg.micro.kks",
    "priority": 80280,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a75_exception_2", false) == true
}

# jdg.micro.kks.a75.r9: kks_a75_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r9",
    "package": "jdg.micro.kks",
    "priority": 80281,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a75.r10: kks_a75_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a75.r10",
    "package": "jdg.micro.kks",
    "priority": 80282,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie KSeF: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a76 — Naruszenie JPK (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a76.r1: kks_a76_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r1",
    "package": "jdg.micro.kks",
    "priority": 80283,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a76.r2: kks_a76_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r2",
    "package": "jdg.micro.kks",
    "priority": 80284,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a76.r3: kks_a76_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r3",
    "package": "jdg.micro.kks",
    "priority": 80285,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a76_r3_pass", false) == true
}

# jdg.micro.kks.a76.r4: kks_a76_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r4",
    "package": "jdg.micro.kks",
    "priority": 80286,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a76_r4_checks", false) == true
}

# jdg.micro.kks.a76.r5: kks_a76_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r5",
    "package": "jdg.micro.kks",
    "priority": 80287,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a76.r6: kks_a76_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r6",
    "package": "jdg.micro.kks",
    "priority": 80288,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a76.r7: kks_a76_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r7",
    "package": "jdg.micro.kks",
    "priority": 80289,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a76_exception", false) == true
}

# jdg.micro.kks.a76.r8: kks_a76_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r8",
    "package": "jdg.micro.kks",
    "priority": 80290,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a76_exception_2", false) == true
}

# jdg.micro.kks.a76.r9: kks_a76_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r9",
    "package": "jdg.micro.kks",
    "priority": 80291,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a76.r10: kks_a76_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a76.r10",
    "package": "jdg.micro.kks",
    "priority": 80292,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Naruszenie JPK: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a77 — Niezłożenie deklaracji w terminie (12 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a77.r1: kks_a77_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r1",
    "package": "jdg.micro.kks",
    "priority": 80293,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a77.r2: kks_a77_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r2",
    "package": "jdg.micro.kks",
    "priority": 80294,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a77.r3: kks_a77_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r3",
    "package": "jdg.micro.kks",
    "priority": 80295,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a77_r3_pass", false) == true
}

# jdg.micro.kks.a77.r4: kks_a77_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r4",
    "package": "jdg.micro.kks",
    "priority": 80296,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a77_r4_checks", false) == true
}

# jdg.micro.kks.a77.r5: kks_a77_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r5",
    "package": "jdg.micro.kks",
    "priority": 80297,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a77.r6: kks_a77_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r6",
    "package": "jdg.micro.kks",
    "priority": 80298,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a77.r7: kks_a77_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r7",
    "package": "jdg.micro.kks",
    "priority": 80299,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a77_exception", false) == true
}

# jdg.micro.kks.a77.r8: kks_a77_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r8",
    "package": "jdg.micro.kks",
    "priority": 80300,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a77_exception_2", false) == true
}

# jdg.micro.kks.a77.r9: kks_a77_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r9",
    "package": "jdg.micro.kks",
    "priority": 80301,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a77.r10: kks_a77_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r10",
    "package": "jdg.micro.kks",
    "priority": 80302,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# jdg.micro.kks.a77.r11: kks_a77_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r11",
    "package": "jdg.micro.kks",
    "priority": 80303,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "kks_deadline_required", false) == true
}

# jdg.micro.kks.a77.r12: kks_a77_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a77.r12",
    "package": "jdg.micro.kks",
    "priority": 80304,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "CRITICAL",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Niezłożenie deklaracji w terminie",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezłożenie deklaracji w terminie: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "kks_a77_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a78 — Nieprawidłowe dane w deklaracji (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a78.r1: kks_a78_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r1",
    "package": "jdg.micro.kks",
    "priority": 80305,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a78.r2: kks_a78_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r2",
    "package": "jdg.micro.kks",
    "priority": 80306,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a78.r3: kks_a78_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r3",
    "package": "jdg.micro.kks",
    "priority": 80307,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a78_r3_pass", false) == true
}

# jdg.micro.kks.a78.r4: kks_a78_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r4",
    "package": "jdg.micro.kks",
    "priority": 80308,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a78_r4_checks", false) == true
}

# jdg.micro.kks.a78.r5: kks_a78_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r5",
    "package": "jdg.micro.kks",
    "priority": 80309,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a78.r6: kks_a78_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r6",
    "package": "jdg.micro.kks",
    "priority": 80310,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a78.r7: kks_a78_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r7",
    "package": "jdg.micro.kks",
    "priority": 80311,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a78_exception", false) == true
}

# jdg.micro.kks.a78.r8: kks_a78_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r8",
    "package": "jdg.micro.kks",
    "priority": 80312,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a78_exception_2", false) == true
}

# jdg.micro.kks.a78.r9: kks_a78_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r9",
    "package": "jdg.micro.kks",
    "priority": 80313,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a78.r10: kks_a78_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a78.r10",
    "package": "jdg.micro.kks",
    "priority": 80314,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nieprawidłowe dane w deklaracji: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a79 — Niezapłacenie podatku w terminie (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a79.r1: kks_a79_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r1",
    "package": "jdg.micro.kks",
    "priority": 80315,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a79.r2: kks_a79_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r2",
    "package": "jdg.micro.kks",
    "priority": 80316,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a79.r3: kks_a79_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r3",
    "package": "jdg.micro.kks",
    "priority": 80317,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a79_r3_pass", false) == true
}

# jdg.micro.kks.a79.r4: kks_a79_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r4",
    "package": "jdg.micro.kks",
    "priority": 80318,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a79_r4_checks", false) == true
}

# jdg.micro.kks.a79.r5: kks_a79_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r5",
    "package": "jdg.micro.kks",
    "priority": 80319,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a79.r6: kks_a79_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r6",
    "package": "jdg.micro.kks",
    "priority": 80320,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a79.r7: kks_a79_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r7",
    "package": "jdg.micro.kks",
    "priority": 80321,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a79_exception", false) == true
}

# jdg.micro.kks.a79.r8: kks_a79_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r8",
    "package": "jdg.micro.kks",
    "priority": 80322,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a79_exception_2", false) == true
}

# jdg.micro.kks.a79.r9: kks_a79_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r9",
    "package": "jdg.micro.kks",
    "priority": 80323,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a79.r10: kks_a79_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a79.r10",
    "package": "jdg.micro.kks",
    "priority": 80324,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Niezapłacenie podatku w terminie: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a80 — Sankcje — grzywny, kara (12 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a80.r1: kks_a80_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r1",
    "package": "jdg.micro.kks",
    "priority": 80325,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a80.r2: kks_a80_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r2",
    "package": "jdg.micro.kks",
    "priority": 80326,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a80.r3: kks_a80_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r3",
    "package": "jdg.micro.kks",
    "priority": 80327,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a80_r3_pass", false) == true
}

# jdg.micro.kks.a80.r4: kks_a80_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r4",
    "package": "jdg.micro.kks",
    "priority": 80328,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a80_r4_checks", false) == true
}

# jdg.micro.kks.a80.r5: kks_a80_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r5",
    "package": "jdg.micro.kks",
    "priority": 80329,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a80.r6: kks_a80_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r6",
    "package": "jdg.micro.kks",
    "priority": 80330,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a80.r7: kks_a80_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r7",
    "package": "jdg.micro.kks",
    "priority": 80331,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a80_exception", false) == true
}

# jdg.micro.kks.a80.r8: kks_a80_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r8",
    "package": "jdg.micro.kks",
    "priority": 80332,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a80_exception_2", false) == true
}

# jdg.micro.kks.a80.r9: kks_a80_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r9",
    "package": "jdg.micro.kks",
    "priority": 80333,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a80.r10: kks_a80_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r10",
    "package": "jdg.micro.kks",
    "priority": 80334,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# jdg.micro.kks.a80.r11: kks_a80_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r11",
    "package": "jdg.micro.kks",
    "priority": 80335,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "kks_deadline_required", false) == true
}

# jdg.micro.kks.a80.r12: kks_a80_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a80.r12",
    "package": "jdg.micro.kks",
    "priority": 80336,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "CRITICAL",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Sankcje — grzywny, kara",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Sankcje — grzywny, kara: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "kks_a80_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a81 — Nadzwyczajne złagodzenie kary (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a81.r1: kks_a81_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r1",
    "package": "jdg.micro.kks",
    "priority": 80337,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a81.r2: kks_a81_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r2",
    "package": "jdg.micro.kks",
    "priority": 80338,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a81.r3: kks_a81_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r3",
    "package": "jdg.micro.kks",
    "priority": 80339,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a81_r3_pass", false) == true
}

# jdg.micro.kks.a81.r4: kks_a81_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r4",
    "package": "jdg.micro.kks",
    "priority": 80340,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a81_r4_checks", false) == true
}

# jdg.micro.kks.a81.r5: kks_a81_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r5",
    "package": "jdg.micro.kks",
    "priority": 80341,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a81.r6: kks_a81_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r6",
    "package": "jdg.micro.kks",
    "priority": 80342,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a81.r7: kks_a81_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r7",
    "package": "jdg.micro.kks",
    "priority": 80343,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a81_exception", false) == true
}

# jdg.micro.kks.a81.r8: kks_a81_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r8",
    "package": "jdg.micro.kks",
    "priority": 80344,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a81_exception_2", false) == true
}

# jdg.micro.kks.a81.r9: kks_a81_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r9",
    "package": "jdg.micro.kks",
    "priority": 80345,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a81.r10: kks_a81_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a81.r10",
    "package": "jdg.micro.kks",
    "priority": 80346,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Nadzwyczajne złagodzenie kary: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a82 — Odstąpienie od wymierzenia kary (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a82.r1: kks_a82_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r1",
    "package": "jdg.micro.kks",
    "priority": 80347,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a82.r2: kks_a82_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r2",
    "package": "jdg.micro.kks",
    "priority": 80348,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a82.r3: kks_a82_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r3",
    "package": "jdg.micro.kks",
    "priority": 80349,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a82_r3_pass", false) == true
}

# jdg.micro.kks.a82.r4: kks_a82_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r4",
    "package": "jdg.micro.kks",
    "priority": 80350,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a82_r4_checks", false) == true
}

# jdg.micro.kks.a82.r5: kks_a82_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r5",
    "package": "jdg.micro.kks",
    "priority": 80351,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a82.r6: kks_a82_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r6",
    "package": "jdg.micro.kks",
    "priority": 80352,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a82.r7: kks_a82_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r7",
    "package": "jdg.micro.kks",
    "priority": 80353,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a82_exception", false) == true
}

# jdg.micro.kks.a82.r8: kks_a82_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r8",
    "package": "jdg.micro.kks",
    "priority": 80354,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a82_exception_2", false) == true
}

# jdg.micro.kks.a82.r9: kks_a82_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r9",
    "package": "jdg.micro.kks",
    "priority": 80355,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a82.r10: kks_a82_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a82.r10",
    "package": "jdg.micro.kks",
    "priority": 80356,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Odstąpienie od wymierzenia kary: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a83 — Przepadek przedmiotów / korzyści (10 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a83.r1: kks_a83_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r1",
    "package": "jdg.micro.kks",
    "priority": 80357,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a83.r2: kks_a83_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r2",
    "package": "jdg.micro.kks",
    "priority": 80358,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a83.r3: kks_a83_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r3",
    "package": "jdg.micro.kks",
    "priority": 80359,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a83_r3_pass", false) == true
}

# jdg.micro.kks.a83.r4: kks_a83_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r4",
    "package": "jdg.micro.kks",
    "priority": 80360,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a83_r4_checks", false) == true
}

# jdg.micro.kks.a83.r5: kks_a83_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r5",
    "package": "jdg.micro.kks",
    "priority": 80361,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a83.r6: kks_a83_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r6",
    "package": "jdg.micro.kks",
    "priority": 80362,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a83.r7: kks_a83_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r7",
    "package": "jdg.micro.kks",
    "priority": 80363,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a83_exception", false) == true
}

# jdg.micro.kks.a83.r8: kks_a83_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r8",
    "package": "jdg.micro.kks",
    "priority": 80364,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a83_exception_2", false) == true
}

# jdg.micro.kks.a83.r9: kks_a83_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r9",
    "package": "jdg.micro.kks",
    "priority": 80365,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_kks", false) == true
}

# jdg.micro.kks.a83.r10: kks_a83_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a83.r10",
    "package": "jdg.micro.kks",
    "priority": 80366,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Przepadek przedmiotów / korzyści: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_kks", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a85 — Karalność łączna — zbieg przestępstw (8 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a85.r1: kks_a85_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a85.r1",
    "package": "jdg.micro.kks",
    "priority": 80367,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg przestępstw: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a85.r2: kks_a85_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a85.r2",
    "package": "jdg.micro.kks",
    "priority": 80368,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg przestępstw: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a85.r3: kks_a85_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a85.r3",
    "package": "jdg.micro.kks",
    "priority": 80369,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg przestępstw: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a85_r3_pass", false) == true
}

# jdg.micro.kks.a85.r4: kks_a85_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a85.r4",
    "package": "jdg.micro.kks",
    "priority": 80370,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg przestępstw: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a85_r4_checks", false) == true
}

# jdg.micro.kks.a85.r5: kks_a85_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a85.r5",
    "package": "jdg.micro.kks",
    "priority": 80371,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg przestępstw: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a85.r6: kks_a85_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a85.r6",
    "package": "jdg.micro.kks",
    "priority": 80372,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg przestępstw: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a85.r7: kks_a85_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a85.r7",
    "package": "jdg.micro.kks",
    "priority": 80373,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg przestępstw: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a85_exception", false) == true
}

# jdg.micro.kks.a85.r8: kks_a85_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a85.r8",
    "package": "jdg.micro.kks",
    "priority": 80374,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg przestępstw: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a85_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a86 — Karalność łączna — zbieg wykroczeń (8 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a86.r1: kks_a86_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a86.r1",
    "package": "jdg.micro.kks",
    "priority": 80375,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg wykroczeń: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a86.r2: kks_a86_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a86.r2",
    "package": "jdg.micro.kks",
    "priority": 80376,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg wykroczeń: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a86.r3: kks_a86_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a86.r3",
    "package": "jdg.micro.kks",
    "priority": 80377,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg wykroczeń: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a86_r3_pass", false) == true
}

# jdg.micro.kks.a86.r4: kks_a86_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a86.r4",
    "package": "jdg.micro.kks",
    "priority": 80378,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg wykroczeń: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a86_r4_checks", false) == true
}

# jdg.micro.kks.a86.r5: kks_a86_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a86.r5",
    "package": "jdg.micro.kks",
    "priority": 80379,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg wykroczeń: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a86.r6: kks_a86_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a86.r6",
    "package": "jdg.micro.kks",
    "priority": 80380,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg wykroczeń: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a86.r7: kks_a86_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a86.r7",
    "package": "jdg.micro.kks",
    "priority": 80381,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg wykroczeń: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a86_exception", false) == true
}

# jdg.micro.kks.a86.r8: kks_a86_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a86.r8",
    "package": "jdg.micro.kks",
    "priority": 80382,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Karalność łączna — zbieg wykroczeń: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a86_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  kks.a87 — Kary łączne (8 reguł)                                    ║
# ║  Legal basis: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a87.r1: kks_a87_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a87.r1",
    "package": "jdg.micro.kks",
    "priority": 80383,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Kary łączne: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.kks.a87.r2: kks_a87_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a87.r2",
    "package": "jdg.micro.kks",
    "priority": 80384,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Kary łączne: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "kks_condition_met", false) == true
}

# jdg.micro.kks.a87.r3: kks_a87_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a87.r3",
    "package": "jdg.micro.kks",
    "priority": 80385,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Kary łączne: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "kks_a87_r3_pass", false) == true
}

# jdg.micro.kks.a87.r4: kks_a87_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a87.r4",
    "package": "jdg.micro.kks",
    "priority": 80386,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Kary łączne: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "kks_a87_r4_checks", false) == true
}

# jdg.micro.kks.a87.r5: kks_a87_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a87.r5",
    "package": "jdg.micro.kks",
    "priority": 80387,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Kary łączne: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "kks_exclusion_applies", false) == false
}

# jdg.micro.kks.a87.r6: kks_a87_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a87.r6",
    "package": "jdg.micro.kks",
    "priority": 80388,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Kary łączne: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "kks_exclusion_2", false) == false
}

# jdg.micro.kks.a87.r7: kks_a87_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a87.r7",
    "package": "jdg.micro.kks",
    "priority": 80389,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Kary łączne: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "kks_a87_exception", false) == true
}

# jdg.micro.kks.a87.r8: kks_a87_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a87.r8",
    "package": "jdg.micro.kks",
    "priority": 80390,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "_warnings": ["[MICRO] Kary łączne: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "kks_a87_exception_2", false) == true
}
