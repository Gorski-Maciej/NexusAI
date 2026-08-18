# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: BDO, SUP, CBAM — 15 artykułów → ~150 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.srodowisko
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.srodowisko

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.srodowisko.no_match",
    "package": "jdg.micro.srodowisko",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  srodowisko.a7 — BDO — rejestracja (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.srodowisko.a7.r1: srodowisko_a7_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a7.r1",
    "package": "jdg.micro.srodowisko",
    "priority": 220007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — rejestracja: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.srodowisko.a7.r2: srodowisko_a7_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a7.r2",
    "package": "jdg.micro.srodowisko",
    "priority": 220008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — rejestracja: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "srodowisko_condition_met", false) == true
}

# jdg.micro.srodowisko.a7.r3: srodowisko_a7_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a7.r3",
    "package": "jdg.micro.srodowisko",
    "priority": 220009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — rejestracja: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a7_r3_pass", false) == true
}

# jdg.micro.srodowisko.a7.r4: srodowisko_a7_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a7.r4",
    "package": "jdg.micro.srodowisko",
    "priority": 220010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — rejestracja: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a7_r4_checks", false) == true
}

# jdg.micro.srodowisko.a7.r5: srodowisko_a7_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a7.r5",
    "package": "jdg.micro.srodowisko",
    "priority": 220011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — rejestracja: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "srodowisko_exclusion_applies", false) == false
}

# jdg.micro.srodowisko.a7.r6: srodowisko_a7_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a7.r6",
    "package": "jdg.micro.srodowisko",
    "priority": 220012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — rejestracja: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "srodowisko_exclusion_2", false) == false
}

# jdg.micro.srodowisko.a7.r7: srodowisko_a7_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a7.r7",
    "package": "jdg.micro.srodowisko",
    "priority": 220013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — rejestracja: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "srodowisko_a7_exception", false) == true
}

# jdg.micro.srodowisko.a7.r8: srodowisko_a7_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a7.r8",
    "package": "jdg.micro.srodowisko",
    "priority": 220014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — rejestracja: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "srodowisko_a7_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  srodowisko.a10 — BDO — ewidencja odpadów (10 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.srodowisko.a10.r1: srodowisko_a10_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r1",
    "package": "jdg.micro.srodowisko",
    "priority": 220015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.srodowisko.a10.r2: srodowisko_a10_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r2",
    "package": "jdg.micro.srodowisko",
    "priority": 220016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "srodowisko_condition_met", false) == true
}

# jdg.micro.srodowisko.a10.r3: srodowisko_a10_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r3",
    "package": "jdg.micro.srodowisko",
    "priority": 220017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a10_r3_pass", false) == true
}

# jdg.micro.srodowisko.a10.r4: srodowisko_a10_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r4",
    "package": "jdg.micro.srodowisko",
    "priority": 220018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a10_r4_checks", false) == true
}

# jdg.micro.srodowisko.a10.r5: srodowisko_a10_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r5",
    "package": "jdg.micro.srodowisko",
    "priority": 220019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "srodowisko_exclusion_applies", false) == false
}

# jdg.micro.srodowisko.a10.r6: srodowisko_a10_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r6",
    "package": "jdg.micro.srodowisko",
    "priority": 220020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "srodowisko_exclusion_2", false) == false
}

# jdg.micro.srodowisko.a10.r7: srodowisko_a10_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r7",
    "package": "jdg.micro.srodowisko",
    "priority": 220021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "srodowisko_a10_exception", false) == true
}

# jdg.micro.srodowisko.a10.r8: srodowisko_a10_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r8",
    "package": "jdg.micro.srodowisko",
    "priority": 220022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "srodowisko_a10_exception_2", false) == true
}

# jdg.micro.srodowisko.a10.r9: srodowisko_a10_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r9",
    "package": "jdg.micro.srodowisko",
    "priority": 220023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_srodowisko", false) == true
}

# jdg.micro.srodowisko.a10.r10: srodowisko_a10_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a10.r10",
    "package": "jdg.micro.srodowisko",
    "priority": 220024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — ewidencja odpadów: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_srodowisko", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  srodowisko.a15 — BDO — sprawozdanie roczne (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.srodowisko.a15.r1: srodowisko_a15_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a15.r1",
    "package": "jdg.micro.srodowisko",
    "priority": 220025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — sprawozdanie roczne: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.srodowisko.a15.r2: srodowisko_a15_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a15.r2",
    "package": "jdg.micro.srodowisko",
    "priority": 220026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — sprawozdanie roczne: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "srodowisko_condition_met", false) == true
}

# jdg.micro.srodowisko.a15.r3: srodowisko_a15_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a15.r3",
    "package": "jdg.micro.srodowisko",
    "priority": 220027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — sprawozdanie roczne: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a15_r3_pass", false) == true
}

# jdg.micro.srodowisko.a15.r4: srodowisko_a15_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a15.r4",
    "package": "jdg.micro.srodowisko",
    "priority": 220028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — sprawozdanie roczne: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a15_r4_checks", false) == true
}

# jdg.micro.srodowisko.a15.r5: srodowisko_a15_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a15.r5",
    "package": "jdg.micro.srodowisko",
    "priority": 220029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — sprawozdanie roczne: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "srodowisko_exclusion_applies", false) == false
}

# jdg.micro.srodowisko.a15.r6: srodowisko_a15_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a15.r6",
    "package": "jdg.micro.srodowisko",
    "priority": 220030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — sprawozdanie roczne: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "srodowisko_exclusion_2", false) == false
}

# jdg.micro.srodowisko.a15.r7: srodowisko_a15_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a15.r7",
    "package": "jdg.micro.srodowisko",
    "priority": 220031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — sprawozdanie roczne: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "srodowisko_a15_exception", false) == true
}

# jdg.micro.srodowisko.a15.r8: srodowisko_a15_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a15.r8",
    "package": "jdg.micro.srodowisko",
    "priority": 220032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] BDO — sprawozdanie roczne: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "srodowisko_a15_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  srodowisko.a3s — SUP — opakowania jednorazowe (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.srodowisko.a3s.r1: srodowisko_a3s_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a3s.r1",
    "package": "jdg.micro.srodowisko",
    "priority": 220033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opakowania jednorazowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.srodowisko.a3s.r2: srodowisko_a3s_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a3s.r2",
    "package": "jdg.micro.srodowisko",
    "priority": 220034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opakowania jednorazowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "srodowisko_condition_met", false) == true
}

# jdg.micro.srodowisko.a3s.r3: srodowisko_a3s_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a3s.r3",
    "package": "jdg.micro.srodowisko",
    "priority": 220035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opakowania jednorazowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a3s_r3_pass", false) == true
}

# jdg.micro.srodowisko.a3s.r4: srodowisko_a3s_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a3s.r4",
    "package": "jdg.micro.srodowisko",
    "priority": 220036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opakowania jednorazowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a3s_r4_checks", false) == true
}

# jdg.micro.srodowisko.a3s.r5: srodowisko_a3s_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a3s.r5",
    "package": "jdg.micro.srodowisko",
    "priority": 220037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opakowania jednorazowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "srodowisko_exclusion_applies", false) == false
}

# jdg.micro.srodowisko.a3s.r6: srodowisko_a3s_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a3s.r6",
    "package": "jdg.micro.srodowisko",
    "priority": 220038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opakowania jednorazowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "srodowisko_exclusion_2", false) == false
}

# jdg.micro.srodowisko.a3s.r7: srodowisko_a3s_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a3s.r7",
    "package": "jdg.micro.srodowisko",
    "priority": 220039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opakowania jednorazowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "srodowisko_a3s_exception", false) == true
}

# jdg.micro.srodowisko.a3s.r8: srodowisko_a3s_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a3s.r8",
    "package": "jdg.micro.srodowisko",
    "priority": 220040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opakowania jednorazowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "srodowisko_a3s_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  srodowisko.a5s — SUP — opłata (6 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.srodowisko.a5s.r1: srodowisko_a5s_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a5s.r1",
    "package": "jdg.micro.srodowisko",
    "priority": 220041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opłata: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.srodowisko.a5s.r2: srodowisko_a5s_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a5s.r2",
    "package": "jdg.micro.srodowisko",
    "priority": 220042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opłata: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "srodowisko_condition_met", false) == true
}

# jdg.micro.srodowisko.a5s.r3: srodowisko_a5s_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a5s.r3",
    "package": "jdg.micro.srodowisko",
    "priority": 220043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opłata: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a5s_r3_pass", false) == true
}

# jdg.micro.srodowisko.a5s.r4: srodowisko_a5s_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a5s.r4",
    "package": "jdg.micro.srodowisko",
    "priority": 220044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opłata: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a5s_r4_checks", false) == true
}

# jdg.micro.srodowisko.a5s.r5: srodowisko_a5s_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a5s.r5",
    "package": "jdg.micro.srodowisko",
    "priority": 220045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opłata: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "srodowisko_exclusion_applies", false) == false
}

# jdg.micro.srodowisko.a5s.r6: srodowisko_a5s_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a5s.r6",
    "package": "jdg.micro.srodowisko",
    "priority": 220046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] SUP — opłata: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "srodowisko_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  srodowisko.a8 — CBAM — raportowanie (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.srodowisko.a8.r1: srodowisko_a8_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a8.r1",
    "package": "jdg.micro.srodowisko",
    "priority": 220047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] CBAM — raportowanie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.srodowisko.a8.r2: srodowisko_a8_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a8.r2",
    "package": "jdg.micro.srodowisko",
    "priority": 220048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] CBAM — raportowanie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "srodowisko_condition_met", false) == true
}

# jdg.micro.srodowisko.a8.r3: srodowisko_a8_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a8.r3",
    "package": "jdg.micro.srodowisko",
    "priority": 220049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] CBAM — raportowanie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a8_r3_pass", false) == true
}

# jdg.micro.srodowisko.a8.r4: srodowisko_a8_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a8.r4",
    "package": "jdg.micro.srodowisko",
    "priority": 220050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] CBAM — raportowanie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "srodowisko_a8_r4_checks", false) == true
}

# jdg.micro.srodowisko.a8.r5: srodowisko_a8_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a8.r5",
    "package": "jdg.micro.srodowisko",
    "priority": 220051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] CBAM — raportowanie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "srodowisko_exclusion_applies", false) == false
}

# jdg.micro.srodowisko.a8.r6: srodowisko_a8_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a8.r6",
    "package": "jdg.micro.srodowisko",
    "priority": 220052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] CBAM — raportowanie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "srodowisko_exclusion_2", false) == false
}

# jdg.micro.srodowisko.a8.r7: srodowisko_a8_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a8.r7",
    "package": "jdg.micro.srodowisko",
    "priority": 220053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] CBAM — raportowanie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "srodowisko_a8_exception", false) == true
}

# jdg.micro.srodowisko.a8.r8: srodowisko_a8_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.srodowisko.a8.r8",
    "package": "jdg.micro.srodowisko",
    "priority": 220054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), SUP, CBAM",
    "_warnings": ["[MICRO] CBAM — raportowanie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "srodowisko_a8_exception_2", false) == true
}
