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
# ║  Legal basis: ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)                                                   ║
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
    "_legal_basis": "Art. 3 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: sprawdzenie czy przepis ma zastosowanie do JDG"],
    "valid_from": "2018-11-19",
    "valid_to": null,
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
    "_legal_basis": "Art. 3 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 3 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 3 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 3 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 3 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 3 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 3 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[MICRO] Zarządca sukcesyjny: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sukcesja_a3_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a12 — Obowiązki zarządcy (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)                                                   ║
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[MICRO] Obowiązki zarządcy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sukcesja_a12_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a14 — Kontynuacja działalności (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)                                                   ║
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
    "_legal_basis": "Art. 14 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 14 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 14 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 14 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 14 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 14 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 14 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 14 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[MICRO] Kontynuacja działalności: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sukcesja_a14_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a21 — Zakończenie zarządu (8 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)                                                   ║
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
    "_legal_basis": "Art. 21 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 21 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[MICRO] Zakończenie zarządu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "sukcesja_a21_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a24 — Odpowiedzialność zarządcy (6 reguł)                                    ║
# ║  Legal basis: ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)                                                   ║
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
    "_legal_basis": "Art. 24 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 24 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 24 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 24 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 24 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 24 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[MICRO] Odpowiedzialność zarządcy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "sukcesja_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a19 — Okres zarządu sukcesyjnego (5 reguł) P24 L-SUK-1            ║
# ║  Legal basis: Art. 19 ustawy o zarządzie sukcesyjnym                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.a19.r1: sukcesja_a19_r1_period_2_years
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a19.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 150041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Okres zarządu sukcesyjnego: 2 lata od dnia śmierci przedsiębiorcy",
    "_legal_basis": "Art. 19 ust. 1 ustawy o zarządzie sukcesyjnym",
    "_warnings": ["[MICRO] L-SUK-1: Zarząd sukcesyjny trwa 2 lata od dnia śmierci przedsiębiorcy. Po tym okresie zarząd wygasa z mocy prawa."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.jdg_entrepreneur, "succession_days_elapsed", 0) > 730
}

# jdg.micro.sukcesja.a19.r2: sukcesja_a19_r2_extension_court
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a19.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 150042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Przedłużenie zarządu sukcesyjnego przez sąd do 5 lat",
    "_legal_basis": "Art. 19 ust. 2 ustawy o zarządzie sukcesyjnym",
    "_warnings": ["[MICRO] L-SUK-1: Sąd może przedłużyć zarząd sukcesyjny maksymalnie do 5 lat od dnia śmierci. Wymagany wniosek zarządcy."]
} {
    object.get(input.jdg_entrepreneur, "succession_court_extension_granted", false) == true
    object.get(input.jdg_entrepreneur, "succession_days_elapsed", 0) > 1825
}

# jdg.micro.sukcesja.a19.r3: sukcesja_a19_r3_expiry_automatic
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a19.r3",
    "package": "jdg.micro.sukcesja",
    "priority": 150043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Zarząd sukcesyjny wygasł — obowiązek zgłoszenia wykreślenia do CEIDG",
    "_legal_basis": "Art. 19 ust. 3 ustawy o zarządzie sukcesyjnym",
    "_warnings": ["[MICRO] L-SUK-1: Zarząd sukcesyjny WYGASŁ! Zgłoś wykreślenie do CEIDG w ciągu 7 dni. Sporządź sprawozdanie końcowe."]
} {
    object.get(input.jdg_entrepreneur, "succession_expired", false) == true
    object.get(input.jdg_entrepreneur, "succession_expiry_ceidg_reported", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a22g — Kontynuacja amortyzacji przez sukcesora (5 reguł) P24 L-SUK-2 ║
# ║  Legal basis: Art. 22g ust. 12 PIT                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.a22g.r1: sukcesja_a22g_r1_depreciation_continuation
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a22g.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 150044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Kontynuacja amortyzacji — sukcesor kontynuuje odpisy amortyzacyjne od środków trwałych",
    "_legal_basis": "Art. 22g ust. 12 ustawy o PIT",
    "_warnings": ["[MICRO] L-SUK-2: Sukcesor KONTYNUUJE odpisy amortyzacyjne od środków trwałych przedsiębiorstwa. Wartość początkowa i metoda amortyzacji bez zmian."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.jdg_entrepreneur, "fixed_assets_exist", false) == true
}

# jdg.micro.sukcesja.a22g.r2: sukcesja_a22g_r2_same_method
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a22g.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 150045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Metoda amortyzacji — sukcesor stosuje tę samą metodę i stawkę co przedsiębiorca",
    "_legal_basis": "Art. 22g ust. 12 w zw. z art. 22h-22m PIT",
    "_warnings": ["[MICRO] L-SUK-2: Sukcesor nie może ZMIENIĆ metody amortyzacji — obowiązuje metoda wybrana przez zmarłego przedsiębiorcę."]
} {
    object.get(input.jdg_entrepreneur, "succession_depreciation_method_changed", false) == true
}

# jdg.micro.sukcesja.a22g.r3: sukcesja_a22g_r3_initial_value_unchanged
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a22g.r3",
    "package": "jdg.micro.sukcesja",
    "priority": 150046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Wartość początkowa bez zmian — sukcesor przyjmuje wartość początkową sprzed śmierci",
    "_legal_basis": "Art. 22g ust. 12 PIT — kontynuacja wartości początkowej",
    "_warnings": ["[MICRO] L-SUK-2: Wartość początkowa środków trwałych pozostaje BEZ ZMIAN. Nie przeszacowuj — US zakwestionuje."]
} {
    object.get(input.jdg_entrepreneur, "succession_asset_revalued", false) == true
}

# jdg.micro.sukcesja.a22g.r4: sukcesja_a22g_r4_kpir_entry
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a22g.r4",
    "package": "jdg.micro.sukcesja",
    "priority": 150047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "KPiR — sukcesor kontynuuje ewidencję środków trwałych i odpisów",
    "_legal_basis": "Art. 22g ust. 12 w zw. z art. 22n PIT (ewidencja środków trwałych)",
    "_warnings": ["[MICRO] L-SUK-2: Prowadź ewidencję środków trwałych i odpisów amortyzacyjnych jako sukcesor. Odpisy = KUP sukcesora (art. 22 ust. 1 PIT)."]
} {
    object.get(input.jdg_entrepreneur, "succession_depreciation_kpir_maintained", false) == false
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
}

# jdg.micro.sukcesja.a22g.r5: sukcesja_a22g_r5_tax_deduction
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a22g.r5",
    "package": "jdg.micro.sukcesja",
    "priority": 150048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Odpisy amortyzacyjne sukcesora = KUP — odliczenie w PIT",
    "_legal_basis": "Art. 22 ust. 1 PIT w zw. z art. 22g ust. 12 PIT",
    "_warnings": ["[MICRO] L-SUK-2: Odpisy amortyzacyjne od przejętych środków trwałych są KOSZTEM UZYSKANIA PRZYCHODU sukcesora. Pominięcie = nadpłata PIT."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.invoice, "depreciation_deduction_claimed_successor", false) == false
    object.get(input.jdg_entrepreneur, "fixed_assets_exist", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.a12zus — Zgłoszenie zarządcy do ZUS (3 reguły) P24 L-SUK-3        ║
# ║  Legal basis: Art. 12 ust. 1 ustawy o zarządzie sukcesyjnym                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.a12zus.r1: sukcesja_a12zus_r1_zus_notification_7_days
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12zus.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 150049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Zgłoszenie zarządcy do ZUS — termin 7 dni od powołania",
    "_legal_basis": "Art. 12 ust. 1 ustawy o zarządzie sukcesyjnym",
    "_warnings": ["[MICRO] L-SUK-3: Zarządca sukcesyjny musi zgłosić się do ZUS (ZUS ZUA) w ciągu 7 DNI od powołania. Brak zgłoszenia = zaległe składki + odsetki."]
} {
    object.get(input.jdg_entrepreneur, "succession_manager_appointed_date", "") != ""
    object.get(input.jdg_entrepreneur, "succession_zus_notification_days", 999) > 7
    object.get(input.jdg_entrepreneur, "succession_zus_notified", false) == false
}

# jdg.micro.sukcesja.a12zus.r2: sukcesja_a12zus_r2_employee_continuation
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.a12zus.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 150050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Kontynuacja zatrudnienia — zarządca przejmuje obowiązki płatnika składek ZUS",
    "_legal_basis": "Art. 12 ust. 2 ustawy o zarządzie sukcesyjnym",
    "_warnings": ["[MICRO] L-SUK-3: Zarządca sukcesyjny przejmuje obowiązki płatnika składek ZUS za pracowników. Zgłoszenie ZUS ZWUA/ZUA dla pracowników."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.jdg_entrepreneur, "has_employees", false) == true
    object.get(input.jdg_entrepreneur, "succession_employee_zus_reported", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  sukcesja.ksef — Interakcja sukcesora z KSeF/JPK (3 reguły) P24 L-SUK-4     ║
# ║  Legal basis: Art. 14 ustawy o zarządzie sukcesyjnym, Art. 106ga VAT         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.ksef.r1: sukcesja_ksef_r1_vat_obligation_transfer
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.ksef.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 150051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "Przejęcie obowiązków VAT — sukcesor kontynuuje JPK_V7 i KSeF",
    "_legal_basis": "Art. 14 ustawy o zarządzie sukcesyjnym, Art. 106ga VAT",
    "_warnings": ["[MICRO] L-SUK-4: Sukcesor PRZEJMUJE obowiązki VAT: JPK_V7, KSeF, faktury, deklaracje. NIP przedsiębiorstwa zostaje ten sam (z dopiskiem 'w zarządzie sukcesyjnym')."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    input.jdg_entrepreneur.is_vat_payer == true
}

# jdg.micro.sukcesja.ksef.r2: sukcesja_ksef_r2_ksef_continuation
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.ksef.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 150052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "KSeF — sukcesor wysyła faktury przez KSeF w imieniu przedsiębiorstwa",
    "_legal_basis": "Art. 106ga-106gf VAT — KSeF",
    "_warnings": ["[MICRO] L-SUK-4: Faktury KSeF nadal wysyłane z NIP-em przedsiębiorstwa (z dopiskiem). Sukcesor NIE zakłada nowego konta KSeF — korzysta z istniejącego."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.invoice, "ksef_sent_under_succession", false) == false
    object.get(input.invoice, "ksef_required", false) == true
}

# jdg.micro.sukcesja.ksef.r3: sukcesja_ksef_r3_jpk_v7_transition
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.ksef.r3",
    "package": "jdg.micro.sukcesja",
    "priority": 150053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "JPK_V7 — sukcesor składa JPK_V7 za okresy od dnia śmierci przedsiębiorcy",
    "_legal_basis": "Art. 109 ust. 3 VAT, Art. 14 ustawy o zarządzie sukcesyjnym",
    "_warnings": ["[MICRO] L-SUK-4: JPK_V7 za okres po śmierci przedsiębiorcy składa zarządca sukcesyjny. Okres przed śmiercią — wg dotychczasowych zasad."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.jdg_entrepreneur, "succession_jpk_v7_filing_deadline_approaching", false) == true
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
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
    "_legal_basis": "Art. 12 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[MICRO] Art. 9: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "suk_a9_u5_p1_check", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  L-SUK-3: Zgłoszenie zarządcy do ZUS (7 dni) + L-SUK-4: KSeF interakcja   ║
# ║  P24 gap closures — 5 reguł                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sukcesja.zus.r1: sukcesja_zus_r1_manager_zus_registration_7days
decide := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.zus.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 210600,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "ZARZADCA_SUKCESYJNY",
    "zus_health_rate": "",
    "business_status": "IN_SUCCESSIO",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "L-SUK-3: Zarządca sukcesyjny — zgłoszenie ZUS ZUA w 7 dni od powołania",
    "_legal_basis": "Art. 12 ust. 1 ustawy o zarządzie sukcesyjnym — zgłoszenie do ZUS",
    "_warnings": ["[MICRO] L-SUK-3: Zarządca sukcesyjny MUSI zgłosić się do ZUS (ZUS ZUA) w ciągu 7 DNI od dnia powołania. Brak zgłoszenia = brak ubezpieczenia = ryzyko osobistej odpowiedzialności!"]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.jdg_entrepreneur, "succession_manager_zus_registered", false) == false
    object.get(input.jdg_entrepreneur, "days_since_manager_appointed", 0) > 7
}

# jdg.micro.sukcesja.zus.r2: sukcesja_zus_r2_employer_obligations_continue
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.zus.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 210601,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "PRACOWNICY_SUKCESJA",
    "zus_health_rate": "",
    "business_status": "IN_SUCCESSIO",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "L-SUK-3: Obowiązki płatnika ZUS kontynuowane przez zarządcę",
    "_legal_basis": "Art. 14 ustawy o zarządzie sukcesyjnym",
    "_warnings": ["[MICRO] L-SUK-3: Zarządca sukcesyjny przejmuje obowiązki płatnika ZUS za pracowników. DRA, RCA, RSA składane bez zmian. Odpowiedzialność solidarna."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.jdg_entrepreneur, "has_employees", false) == true
}

# jdg.micro.sukcesja.ksef.r1: sukcesja_ksef_r1_vat_ksef_continuity
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.ksef_plan26.r1",
    "package": "jdg.micro.sukcesja",
    "priority": 210602,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "IN_SUCCESSIO",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "L-SUK-4: Obowiązki KSeF/VAT kontynuowane — sukcesor przejmuje NIP",
    "_legal_basis": "Art. 14 ustawy o zarządzie sukcesyjnym, Art. 96-106 VAT",
    "_warnings": ["[MICRO] L-SUK-4: NIP przedsiębiorstwa pozostaje AKTYWNY w okresie zarządu sukcesyjnego. Faktury KSeF wystawiane w imieniu przedsiębiorstwa w spadku. JPK_V7 i JPK_VAT składane bez przerw. Wyrejestrowanie VAT dopiero po wygaśnięciu zarządu."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
}

# jdg.micro.sukcesja.ksef.r2: sukcesja_ksef_r2_jpk_continuity
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.ksef_plan26.r2",
    "package": "jdg.micro.sukcesja",
    "priority": 210603,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "IN_SUCCESSIO",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "L-SUK-4: JPK/księgi kontynuowane — zarządca prowadzi PKPiR/księgi",
    "_legal_basis": "Art. 14-15 ustawy o zarządzie sukcesyjnym",
    "_warnings": ["[MICRO] L-SUK-4: Zarządca sukcesyjny prowadzi PKPiR/księgi rachunkowe przedsiębiorstwa BEZ ZMIAN. Rok podatkowy NIE ulega przerwaniu. Zeznanie roczne składa zarządca."]
} {
    object.get(input.jdg_entrepreneur, "succession_active", false) == true
}

# jdg.micro.sukcesja.ksef.r3: sukcesja_ksef_r3_termination_vat_deregistration
else := {
    "matched": true,
    "rule_id": "jdg.micro.sukcesja.ksef_plan26.r3",
    "package": "jdg.micro.sukcesja",
    "priority": 210604,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "L-SUK-4: Wygaśnięcie zarządu — obowiązek wyrejestrowania VAT i CEIDG",
    "_legal_basis": "Art. 21 ustawy o zarządzie sukcesyjnym, Art. 96 VAT",
    "_warnings": ["[MICRO] L-SUK-4: Po wygaśnięciu zarządu sukcesyjnego: VAT-Z (wyrejestrowanie VAT), CEIDG-WY (wykreślenie z CEIDG), remanent likwidacyjny (10% PIT), zamknięcie ksiąg. Termin: 7 dni od wygaśnięcia."]
} {
    object.get(input.jdg_entrepreneur, "succession_terminated", false) == true
    object.get(input.jdg_entrepreneur, "vat_deregistered", false) == false
}