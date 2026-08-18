# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa zasiłkowa — 10 artykułów → ~100 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.zasilkowa
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.zasilkowa

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.zasilkowa.no_match",
    "package": "jdg.micro.zasilkowa",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  zasilkowa.a19 — Zasiłek chorobowy (10 reguł)                                    ║
# ║  Legal basis: Ustawa z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zasilkowa.a19.r1: zasilkowa_a19_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r1",
    "package": "jdg.micro.zasilkowa",
    "priority": 120019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zasilkowa.a19.r2: zasilkowa_a19_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r2",
    "package": "jdg.micro.zasilkowa",
    "priority": 120020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_condition_met", false) == true
}

# jdg.micro.zasilkowa.a19.r3: zasilkowa_a19_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r3",
    "package": "jdg.micro.zasilkowa",
    "priority": 120021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a19_r3_pass", false) == true
}

# jdg.micro.zasilkowa.a19.r4: zasilkowa_a19_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r4",
    "package": "jdg.micro.zasilkowa",
    "priority": 120022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a19_r4_checks", false) == true
}

# jdg.micro.zasilkowa.a19.r5: zasilkowa_a19_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r5",
    "package": "jdg.micro.zasilkowa",
    "priority": 120023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_applies", false) == false
}

# jdg.micro.zasilkowa.a19.r6: zasilkowa_a19_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r6",
    "package": "jdg.micro.zasilkowa",
    "priority": 120024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_2", false) == false
}

# jdg.micro.zasilkowa.a19.r7: zasilkowa_a19_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r7",
    "package": "jdg.micro.zasilkowa",
    "priority": 120025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zasilkowa_a19_exception", false) == true
}

# jdg.micro.zasilkowa.a19.r8: zasilkowa_a19_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r8",
    "package": "jdg.micro.zasilkowa",
    "priority": 120026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zasilkowa_a19_exception_2", false) == true
}

# jdg.micro.zasilkowa.a19.r9: zasilkowa_a19_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r9",
    "package": "jdg.micro.zasilkowa",
    "priority": 120027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_zasilkowa", false) == true
}

# jdg.micro.zasilkowa.a19.r10: zasilkowa_a19_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.r10",
    "package": "jdg.micro.zasilkowa",
    "priority": 120028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek chorobowy: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_zasilkowa", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  zasilkowa.a29 — Zasiłek macierzyński (10 reguł)                                    ║
# ║  Legal basis: Ustawa z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zasilkowa.a29.r1: zasilkowa_a29_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r1",
    "package": "jdg.micro.zasilkowa",
    "priority": 120029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zasilkowa.a29.r2: zasilkowa_a29_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r2",
    "package": "jdg.micro.zasilkowa",
    "priority": 120030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_condition_met", false) == true
}

# jdg.micro.zasilkowa.a29.r3: zasilkowa_a29_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r3",
    "package": "jdg.micro.zasilkowa",
    "priority": 120031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a29_r3_pass", false) == true
}

# jdg.micro.zasilkowa.a29.r4: zasilkowa_a29_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r4",
    "package": "jdg.micro.zasilkowa",
    "priority": 120032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a29_r4_checks", false) == true
}

# jdg.micro.zasilkowa.a29.r5: zasilkowa_a29_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r5",
    "package": "jdg.micro.zasilkowa",
    "priority": 120033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_applies", false) == false
}

# jdg.micro.zasilkowa.a29.r6: zasilkowa_a29_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r6",
    "package": "jdg.micro.zasilkowa",
    "priority": 120034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_2", false) == false
}

# jdg.micro.zasilkowa.a29.r7: zasilkowa_a29_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r7",
    "package": "jdg.micro.zasilkowa",
    "priority": 120035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zasilkowa_a29_exception", false) == true
}

# jdg.micro.zasilkowa.a29.r8: zasilkowa_a29_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r8",
    "package": "jdg.micro.zasilkowa",
    "priority": 120036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zasilkowa_a29_exception_2", false) == true
}

# jdg.micro.zasilkowa.a29.r9: zasilkowa_a29_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r9",
    "package": "jdg.micro.zasilkowa",
    "priority": 120037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_zasilkowa", false) == true
}

# jdg.micro.zasilkowa.a29.r10: zasilkowa_a29_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.r10",
    "package": "jdg.micro.zasilkowa",
    "priority": 120038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek macierzyński: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_zasilkowa", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  zasilkowa.a32 — Zasiłek opiekuńczy (10 reguł)                                    ║
# ║  Legal basis: Ustawa z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zasilkowa.a32.r1: zasilkowa_a32_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r1",
    "package": "jdg.micro.zasilkowa",
    "priority": 120039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zasilkowa.a32.r2: zasilkowa_a32_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r2",
    "package": "jdg.micro.zasilkowa",
    "priority": 120040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_condition_met", false) == true
}

# jdg.micro.zasilkowa.a32.r3: zasilkowa_a32_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r3",
    "package": "jdg.micro.zasilkowa",
    "priority": 120041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a32_r3_pass", false) == true
}

# jdg.micro.zasilkowa.a32.r4: zasilkowa_a32_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r4",
    "package": "jdg.micro.zasilkowa",
    "priority": 120042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a32_r4_checks", false) == true
}

# jdg.micro.zasilkowa.a32.r5: zasilkowa_a32_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r5",
    "package": "jdg.micro.zasilkowa",
    "priority": 120043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_applies", false) == false
}

# jdg.micro.zasilkowa.a32.r6: zasilkowa_a32_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r6",
    "package": "jdg.micro.zasilkowa",
    "priority": 120044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_2", false) == false
}

# jdg.micro.zasilkowa.a32.r7: zasilkowa_a32_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r7",
    "package": "jdg.micro.zasilkowa",
    "priority": 120045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zasilkowa_a32_exception", false) == true
}

# jdg.micro.zasilkowa.a32.r8: zasilkowa_a32_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r8",
    "package": "jdg.micro.zasilkowa",
    "priority": 120046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zasilkowa_a32_exception_2", false) == true
}

# jdg.micro.zasilkowa.a32.r9: zasilkowa_a32_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r9",
    "package": "jdg.micro.zasilkowa",
    "priority": 120047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_zasilkowa", false) == true
}

# jdg.micro.zasilkowa.a32.r10: zasilkowa_a32_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.r10",
    "package": "jdg.micro.zasilkowa",
    "priority": 120048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek opiekuńczy: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_zasilkowa", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  zasilkowa.a33 — Zasiłek rehabilitacyjny (8 reguł)                                    ║
# ║  Legal basis: Ustawa z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zasilkowa.a33.r1: zasilkowa_a33_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r1",
    "package": "jdg.micro.zasilkowa",
    "priority": 120049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.zasilkowa.a33.r2: zasilkowa_a33_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r2",
    "package": "jdg.micro.zasilkowa",
    "priority": 120050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_condition_met", false) == true
}

# jdg.micro.zasilkowa.a33.r3: zasilkowa_a33_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r3",
    "package": "jdg.micro.zasilkowa",
    "priority": 120051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a33_r3_pass", false) == true
}

# jdg.micro.zasilkowa.a33.r4: zasilkowa_a33_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r4",
    "package": "jdg.micro.zasilkowa",
    "priority": 120052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "zasilkowa_a33_r4_checks", false) == true
}

# jdg.micro.zasilkowa.a33.r5: zasilkowa_a33_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r5",
    "package": "jdg.micro.zasilkowa",
    "priority": 120053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_applies", false) == false
}

# jdg.micro.zasilkowa.a33.r6: zasilkowa_a33_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r6",
    "package": "jdg.micro.zasilkowa",
    "priority": 120054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "zasilkowa_exclusion_2", false) == false
}

# jdg.micro.zasilkowa.a33.r7: zasilkowa_a33_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r7",
    "package": "jdg.micro.zasilkowa",
    "priority": 120055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "zasilkowa_a33_exception", false) == true
}

# jdg.micro.zasilkowa.a33.r8: zasilkowa_a33_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.r8",
    "package": "jdg.micro.zasilkowa",
    "priority": 120056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO] Zasiłek rehabilitacyjny: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "zasilkowa_a33_exception_2", false) == true
}
