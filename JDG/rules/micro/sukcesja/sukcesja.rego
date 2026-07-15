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


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (84 reguł)       ║
# ║  Priorytety: 50000-50083                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.suk.a10.u1.p2 — `suk_a10_u1_p2`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a10.u1.p2",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a10_u1_p2_check", false) == true
}
# jdg.suk.a10.u2.p3 — `suk_a10_u2_p3`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a10.u2.p3",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a10_u2_p3_check", false) == true
}
# jdg.suk.a10.u3.p4 — `suk_a10_u3_p4`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a10.u3.p4",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a10_u3_p4_check", false) == true
}
# jdg.suk.a10.u4.p1 — `suk_a10_u4_p1`: Art. 10 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a10.u4.p1",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 10: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a10_u4_p1_check", false) == true
}
# jdg.suk.a11.u1.p3 — `suk_a11_u1_p3`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a11.u1.p3",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a11_u1_p3_check", false) == true
}
# jdg.suk.a11.u2.p4 — `suk_a11_u2_p4`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a11.u2.p4",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a11_u2_p4_check", false) == true
}
# jdg.suk.a11.u3.p1 — `suk_a11_u3_p1`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a11.u3.p1",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a11_u3_p1_check", false) == true
}
# jdg.suk.a11.u5.p2 — `suk_a11_u5_p2`: Art. 11 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a11.u5.p2",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 11: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a11_u5_p2_check", false) == true
}
# jdg.suk.a12.u1.p1 — `suk_a12_u1_p1`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a12.u1.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a12_u1_p1_check", false) == true
}
# jdg.suk.a12.u1.p4 — `suk_a12_u1_p4`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a12.u1.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a12_u1_p4_check", false) == true
}
# jdg.suk.a12.u2.p1 — `suk_a12_u2_p1`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a12.u2.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a12_u2_p1_check", false) == true
}
# jdg.suk.a12.u2.p2 — `suk_a12_u2_p2`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a12.u2.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 12 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a12_u2_p2_check", false) == true
}
# jdg.suk.a12.u4.p2 — `suk_a12_u4_p2`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a12.u4.p2",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a12_u4_p2_check", false) == true
}
# jdg.suk.a12.u5.p3 — `suk_a12_u5_p3`: Art. 12 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a12.u5.p3",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 12: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a12_u5_p3_check", false) == true
}
# jdg.suk.a13.u1.p1 — `suk_a13_u1_p1`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a13.u1.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a13_u1_p1_check", false) == true
}
# jdg.suk.a13.u1.p2 — `suk_a13_u1_p2`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a13.u1.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a13_u1_p2_check", false) == true
}
# jdg.suk.a13.u3.p2 — `suk_a13_u3_p2`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a13.u3.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a13_u3_p2_check", false) == true
}
# jdg.suk.a13.u3.p3 — `suk_a13_u3_p3`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a13.u3.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a13_u3_p3_check", false) == true
}
# jdg.suk.a13.u4.p3 — `suk_a13_u4_p3`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a13.u4.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a13_u4_p3_check", false) == true
}
# jdg.suk.a13.u4.p4 — `suk_a13_u4_p4`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a13.u4.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 13 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a13_u4_p4_check", false) == true
}
# jdg.suk.a13.u5.p1 — `suk_a13_u5_p1`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a13.u5.p1",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a13_u5_p1_check", false) == true
}
# jdg.suk.a13.u5.p4 — `suk_a13_u5_p4`: Art. 13 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a13.u5.p4",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 13: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a13_u5_p4_check", false) == true
}
# jdg.suk.a14.u2.p2 — `suk_a14_u2_p2`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a14.u2.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a14_u2_p2_check", false) == true
}
# jdg.suk.a14.u2.p3 — `suk_a14_u2_p3`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a14.u2.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a14_u2_p3_check", false) == true
}
# jdg.suk.a14.u3.p3 — `suk_a14_u3_p3`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a14.u3.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a14_u3_p3_check", false) == true
}
# jdg.suk.a14.u3.p4 — `suk_a14_u3_p4`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a14.u3.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a14_u3_p4_check", false) == true
}
# jdg.suk.a14.u4.p1 — `suk_a14_u4_p1`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a14.u4.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a14_u4_p1_check", false) == true
}
# jdg.suk.a14.u4.p4 — `suk_a14_u4_p4`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a14.u4.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 14 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a14_u4_p4_check", false) == true
}
# jdg.suk.a14.u5.p1 — `suk_a14_u5_p1`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a14.u5.p1",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a14_u5_p1_check", false) == true
}
# jdg.suk.a14.u5.p2 — `suk_a14_u5_p2`: Art. 14 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a14.u5.p2",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 14: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a14_u5_p2_check", false) == true
}
# jdg.suk.a15.u1.p2 — `suk_a15_u1_p2`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a15.u1.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a15_u1_p2_check", false) == true
}
# jdg.suk.a15.u1.p3 — `suk_a15_u1_p3`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a15.u1.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a15_u1_p3_check", false) == true
}
# jdg.suk.a15.u2.p3 — `suk_a15_u2_p3`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a15.u2.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a15_u2_p3_check", false) == true
}
# jdg.suk.a15.u2.p4 — `suk_a15_u2_p4`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a15.u2.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a15_u2_p4_check", false) == true
}
# jdg.suk.a15.u3.p1 — `suk_a15_u3_p1`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a15.u3.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a15_u3_p1_check", false) == true
}
# jdg.suk.a15.u3.p4 — `suk_a15_u3_p4`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a15.u3.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 15 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a15_u3_p4_check", false) == true
}
# jdg.suk.a15.u4.p1 — `suk_a15_u4_p1`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a15.u4.p1",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a15_u4_p1_check", false) == true
}
# jdg.suk.a15.u4.p2 — `suk_a15_u4_p2`: Art. 15 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a15.u4.p2",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 15: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a15_u4_p2_check", false) == true
}
# jdg.suk.a16.u1.p3 — `suk_a16_u1_p3`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a16.u1.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a16_u1_p3_check", false) == true
}
# jdg.suk.a16.u1.p4 — `suk_a16_u1_p4`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a16.u1.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a16_u1_p4_check", false) == true
}
# jdg.suk.a16.u2.p1 — `suk_a16_u2_p1`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a16.u2.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a16_u2_p1_check", false) == true
}
# jdg.suk.a16.u2.p4 — `suk_a16_u2_p4`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a16.u2.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a16_u2_p4_check", false) == true
}
# jdg.suk.a16.u3.p1 — `suk_a16_u3_p1`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a16.u3.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a16_u3_p1_check", false) == true
}
# jdg.suk.a16.u3.p2 — `suk_a16_u3_p2`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a16.u3.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 16 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a16_u3_p2_check", false) == true
}
# jdg.suk.a16.u5.p2 — `suk_a16_u5_p2`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a16.u5.p2",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a16_u5_p2_check", false) == true
}
# jdg.suk.a16.u5.p3 — `suk_a16_u5_p3`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a16.u5.p3",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a16_u5_p3_check", false) == true
}
# jdg.suk.a17.u1.p1 — `suk_a17_u1_p1`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a17.u1.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a17_u1_p1_check", false) == true
}
# jdg.suk.a17.u1.p4 — `suk_a17_u1_p4`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a17.u1.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a17_u1_p4_check", false) == true
}
# jdg.suk.a17.u2.p1 — `suk_a17_u2_p1`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a17.u2.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a17_u2_p1_check", false) == true
}
# jdg.suk.a17.u2.p2 — `suk_a17_u2_p2`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a17.u2.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a17_u2_p2_check", false) == true
}
# jdg.suk.a17.u4.p2 — `suk_a17_u4_p2`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a17.u4.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a17_u4_p2_check", false) == true
}
# jdg.suk.a17.u4.p3 — `suk_a17_u4_p3`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a17.u4.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 17 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a17_u4_p3_check", false) == true
}
# jdg.suk.a17.u5.p3 — `suk_a17_u5_p3`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a17.u5.p3",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a17_u5_p3_check", false) == true
}
# jdg.suk.a17.u5.p4 — `suk_a17_u5_p4`: Art. 17 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a17.u5.p4",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 17: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a17_u5_p4_check", false) == true
}
# jdg.suk.a18.u1.p1 — `suk_a18_u1_p1`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a18.u1.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a18_u1_p1_check", false) == true
}
# jdg.suk.a18.u1.p2 — `suk_a18_u1_p2`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a18.u1.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a18_u1_p2_check", false) == true
}
# jdg.suk.a18.u3.p2 — `suk_a18_u3_p2`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a18.u3.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a18_u3_p2_check", false) == true
}
# jdg.suk.a18.u3.p3 — `suk_a18_u3_p3`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a18.u3.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a18_u3_p3_check", false) == true
}
# jdg.suk.a18.u4.p3 — `suk_a18_u4_p3`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a18.u4.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a18_u4_p3_check", false) == true
}
# jdg.suk.a18.u4.p4 — `suk_a18_u4_p4`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a18.u4.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 18 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a18_u4_p4_check", false) == true
}
# jdg.suk.a18.u5.p1 — `suk_a18_u5_p1`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a18.u5.p1",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a18_u5_p1_check", false) == true
}
# jdg.suk.a18.u5.p4 — `suk_a18_u5_p4`: Art. 18 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a18.u5.p4",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 18: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a18_u5_p4_check", false) == true
}
# jdg.suk.a19.u2.p2 — `suk_a19_u2_p2`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a19.u2.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a19_u2_p2_check", false) == true
}
# jdg.suk.a19.u2.p3 — `suk_a19_u2_p3`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a19.u2.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a19_u2_p3_check", false) == true
}
# jdg.suk.a19.u3.p3 — `suk_a19_u3_p3`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a19.u3.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a19_u3_p3_check", false) == true
}
# jdg.suk.a19.u3.p4 — `suk_a19_u3_p4`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a19.u3.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 19 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a19_u3_p4_check", false) == true
}
# jdg.suk.a19.u4.p1 — `suk_a19_u4_p1`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a19.u4.p1",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a19_u4_p1_check", false) == true
}
# jdg.suk.a19.u4.p4 — `suk_a19_u4_p4`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a19.u4.p4",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a19_u4_p4_check", false) == true
}
# jdg.suk.a19.u5.p1 — `suk_a19_u5_p1`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a19.u5.p1",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a19_u5_p1_check", false) == true
}
# jdg.suk.a19.u5.p2 — `suk_a19_u5_p2`: Art. 19 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a19.u5.p2",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 19: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a19_u5_p2_check", false) == true
}
# jdg.suk.a20.u1.p2 — `suk_a20_u1_p2`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a20.u1.p2",
    "package": "jdg.micro.sukcesja",
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
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a20_u1_p2_check", false) == true
}
# jdg.suk.a20.u2.p3 — `suk_a20_u2_p3`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a20.u2.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a20_u2_p3_check", false) == true
}
# jdg.suk.a20.u3.p4 — `suk_a20_u3_p4`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a20.u3.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a20_u3_p4_check", false) == true
}
# jdg.suk.a20.u4.p1 — `suk_a20_u4_p1`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a20.u4.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 20 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a20_u4_p1_check", false) == true
}
# jdg.suk.a21.u1.p3 — `suk_a21_u1_p3`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a21.u1.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a21_u1_p3_check", false) == true
}
# jdg.suk.a21.u2.p4 — `suk_a21_u2_p4`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a21.u2.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a21_u2_p4_check", false) == true
}
# jdg.suk.a21.u3.p1 — `suk_a21_u3_p1`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a21.u3.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a21_u3_p1_check", false) == true
}
# jdg.suk.a21.u5.p2 — `suk_a21_u5_p2`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a21.u5.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 21 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a21_u5_p2_check", false) == true
}
# jdg.suk.a22.u4.p2 — `suk_a22_u4_p2`: Art. 22 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a22.u4.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 22 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 22: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a22_u4_p2_check", false) == true
}
# jdg.suk.a8.u1.p1 — `suk_a8_u1_p1`: Art. 8 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a8.u1.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 8 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 8: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a8_u1_p1_check", false) == true
}
# jdg.suk.a9.u2.p2 — `suk_a9_u2_p2`: Art. 9 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a9.u2.p2",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 9 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 9: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a9_u2_p2_check", false) == true
}
# jdg.suk.a9.u3.p3 — `suk_a9_u3_p3`: Art. 9 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a9.u3.p3",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 9 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 9: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a9_u3_p3_check", false) == true
}
# jdg.suk.a9.u4.p4 — `suk_a9_u4_p4`: Art. 9 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a9.u4.p4",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 9 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 9: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a9_u4_p4_check", false) == true
}
# jdg.suk.a9.u5.p1 — `suk_a9_u5_p1`: Art. 9 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.suk.a9.u5.p1",
    "package": "jdg.micro.sukcesja",
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
    "_routing_reason": "[MICRO] Art. 9 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym z 5.07.2018 (Dz.U. 2018 poz. 1629)",
    "_warnings": ["[MICRO] Art. 9: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a9_u5_p1_check", false) == true
}