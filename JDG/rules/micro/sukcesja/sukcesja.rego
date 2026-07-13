# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa o zarządzie sukcesyjnym — 15 artykułów → ~150 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.sukcesja
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.sukcesja

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.sukcesja.no_match",
    "package": "jdg.micro.sukcesja",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a3 — Zarządca sukcesyjny (8 reguł)                                    ║
# ║  Legal basis: Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.a3.r1: sukcesja_a3_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a3.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 150003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.sukcesja.a3.r2: sukcesja_a3_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a3.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 150004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "sukcesja_condition_met", false) == true
}

# jdg.micro.sukcesja.a3.r3: sukcesja_a3_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a3.r3",
    "package": "jdg.micro.sukcesja",
    "priority": 150005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a3_r3_pass", false) == true
}

# jdg.micro.sukcesja.a3.r4: sukcesja_a3_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a3.r4",
    "package": "jdg.micro.sukcesja",
    "priority": 150006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a3_r4_checks", false) == true
}

# jdg.micro.sukcesja.a3.r5: sukcesja_a3_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a3.r5",
    "package": "jdg.micro.sukcesja",
    "priority": 150007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "sukcesja_exclusion_applies", false) == false
}

# jdg.micro.sukcesja.a3.r6: sukcesja_a3_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a3.r6",
    "package": "jdg.micro.sukcesja",
    "priority": 150008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "sukcesja_exclusion_2", false) == false
}

# jdg.micro.sukcesja.a3.r7: sukcesja_a3_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a3.r7",
    "package": "jdg.micro.sukcesja",
    "priority": 150009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "sukcesja_a3_exception", false) == true
}

# jdg.micro.sukcesja.a3.r8: sukcesja_a3_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a3.r8",
    "package": "jdg.micro.sukcesja",
    "priority": 150010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sukcesja_a3_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a12 — Obowiązki zarządcy (8 reguł)                                    ║
# ║  Legal basis: Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.a12.r1: sukcesja_a12_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 150011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Obowiązki zarządcy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.sukcesja.a12.r2: sukcesja_a12_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 150012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Obowiązki zarządcy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "sukcesja_condition_met", false) == true
}

# jdg.micro.sukcesja.a12.r3: sukcesja_a12_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12.r3",
    "package": "jdg.micro.sukcesja",
    "priority": 150013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Obowiązki zarządcy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a12_r3_pass", false) == true
}

# jdg.micro.sukcesja.a12.r4: sukcesja_a12_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12.r4",
    "package": "jdg.micro.sukcesja",
    "priority": 150014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Obowiązki zarządcy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a12_r4_checks", false) == true
}

# jdg.micro.sukcesja.a12.r5: sukcesja_a12_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12.r5",
    "package": "jdg.micro.sukcesja",
    "priority": 150015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Obowiązki zarządcy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "sukcesja_exclusion_applies", false) == false
}

# jdg.micro.sukcesja.a12.r6: sukcesja_a12_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12.r6",
    "package": "jdg.micro.sukcesja",
    "priority": 150016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Obowiązki zarządcy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "sukcesja_exclusion_2", false) == false
}

# jdg.micro.sukcesja.a12.r7: sukcesja_a12_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12.r7",
    "package": "jdg.micro.sukcesja",
    "priority": 150017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Obowiązki zarządcy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "sukcesja_a12_exception", false) == true
}

# jdg.micro.sukcesja.a12.r8: sukcesja_a12_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12.r8",
    "package": "jdg.micro.sukcesja",
    "priority": 150018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Obowiązki zarządcy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sukcesja_a12_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a14 — Kontynuacja działalności (8 reguł)                                    ║
# ║  Legal basis: Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.a14.r1: sukcesja_a14_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a14.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 150019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Kontynuacja działalności: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.sukcesja.a14.r2: sukcesja_a14_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a14.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 150020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Kontynuacja działalności: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "sukcesja_condition_met", false) == true
}

# jdg.micro.sukcesja.a14.r3: sukcesja_a14_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a14.r3",
    "package": "jdg.micro.sukcesja",
    "priority": 150021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Kontynuacja działalności: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a14_r3_pass", false) == true
}

# jdg.micro.sukcesja.a14.r4: sukcesja_a14_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a14.r4",
    "package": "jdg.micro.sukcesja",
    "priority": 150022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Kontynuacja działalności: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a14_r4_checks", false) == true
}

# jdg.micro.sukcesja.a14.r5: sukcesja_a14_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a14.r5",
    "package": "jdg.micro.sukcesja",
    "priority": 150023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Kontynuacja działalności: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "sukcesja_exclusion_applies", false) == false
}

# jdg.micro.sukcesja.a14.r6: sukcesja_a14_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a14.r6",
    "package": "jdg.micro.sukcesja",
    "priority": 150024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Kontynuacja działalności: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "sukcesja_exclusion_2", false) == false
}

# jdg.micro.sukcesja.a14.r7: sukcesja_a14_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a14.r7",
    "package": "jdg.micro.sukcesja",
    "priority": 150025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Kontynuacja działalności: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "sukcesja_a14_exception", false) == true
}

# jdg.micro.sukcesja.a14.r8: sukcesja_a14_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a14.r8",
    "package": "jdg.micro.sukcesja",
    "priority": 150026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Kontynuacja działalności: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sukcesja_a14_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a21 — Zakończenie zarządu (8 reguł)                                    ║
# ║  Legal basis: Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.a21.r1: sukcesja_a21_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a21.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 150027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zakończenie zarządu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.sukcesja.a21.r2: sukcesja_a21_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a21.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 150028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zakończenie zarządu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "sukcesja_condition_met", false) == true
}

# jdg.micro.sukcesja.a21.r3: sukcesja_a21_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a21.r3",
    "package": "jdg.micro.sukcesja",
    "priority": 150029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zakończenie zarządu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a21_r3_pass", false) == true
}

# jdg.micro.sukcesja.a21.r4: sukcesja_a21_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a21.r4",
    "package": "jdg.micro.sukcesja",
    "priority": 150030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zakończenie zarządu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a21_r4_checks", false) == true
}

# jdg.micro.sukcesja.a21.r5: sukcesja_a21_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a21.r5",
    "package": "jdg.micro.sukcesja",
    "priority": 150031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zakończenie zarządu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "sukcesja_exclusion_applies", false) == false
}

# jdg.micro.sukcesja.a21.r6: sukcesja_a21_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a21.r6",
    "package": "jdg.micro.sukcesja",
    "priority": 150032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zakończenie zarządu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "sukcesja_exclusion_2", false) == false
}

# jdg.micro.sukcesja.a21.r7: sukcesja_a21_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a21.r7",
    "package": "jdg.micro.sukcesja",
    "priority": 150033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zakończenie zarządu: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "sukcesja_a21_exception", false) == true
}

# jdg.micro.sukcesja.a21.r8: sukcesja_a21_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a21.r8",
    "package": "jdg.micro.sukcesja",
    "priority": 150034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Zakończenie zarządu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sukcesja_a21_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a24 — Odpowiedzialność zarządcy (6 reguł)                                    ║
# ║  Legal basis: Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.a24.r1: sukcesja_a24_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a24.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 150035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Odpowiedzialność zarządcy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.sukcesja.a24.r2: sukcesja_a24_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a24.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 150036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Odpowiedzialność zarządcy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "sukcesja_condition_met", false) == true
}

# jdg.micro.sukcesja.a24.r3: sukcesja_a24_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a24.r3",
    "package": "jdg.micro.sukcesja",
    "priority": 150037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Odpowiedzialność zarządcy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a24_r3_pass", false) == true
}

# jdg.micro.sukcesja.a24.r4: sukcesja_a24_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a24.r4",
    "package": "jdg.micro.sukcesja",
    "priority": 150038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Odpowiedzialność zarządcy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "sukcesja_a24_r4_checks", false) == true
}

# jdg.micro.sukcesja.a24.r5: sukcesja_a24_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a24.r5",
    "package": "jdg.micro.sukcesja",
    "priority": 150039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Odpowiedzialność zarządcy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "sukcesja_exclusion_applies", false) == false
}

# jdg.micro.sukcesja.a24.r6: sukcesja_a24_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a24.r6",
    "package": "jdg.micro.sukcesja",
    "priority": 150040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Odpowiedzialność zarządcy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "sukcesja_exclusion_2", false) == false
}
