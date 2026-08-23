# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa o PIT — 70 artykułów → ~910 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.pit
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pit

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pit.no_match",
    "package": "jdg.micro.pit",
    "priority": 999999
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a6 — Wspólne rozliczenie małżonków (10 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a6.r1: pit_a6_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r1",
    "package": "jdg.micro.pit",
    "priority": 60006,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a6.r2: pit_a6_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r2",
    "package": "jdg.micro.pit",
    "priority": 60007,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a6.r3: pit_a6_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r3",
    "package": "jdg.micro.pit",
    "priority": 60008,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a6_r3_pass", false) == true
}

# jdg.micro.pit.a6.r4: pit_a6_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r4",
    "package": "jdg.micro.pit",
    "priority": 60009,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a6_r4_checks", false) == true
}

# jdg.micro.pit.a6.r5: pit_a6_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r5",
    "package": "jdg.micro.pit",
    "priority": 60010,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a6.r6: pit_a6_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r6",
    "package": "jdg.micro.pit",
    "priority": 60011,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a6.r7: pit_a6_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r7",
    "package": "jdg.micro.pit",
    "priority": 60012,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a6_exception", false) == true
}

# jdg.micro.pit.a6.r8: pit_a6_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r8",
    "package": "jdg.micro.pit",
    "priority": 60013,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a6_exception_2", false) == true
}

# jdg.micro.pit.a6.r9: pit_a6_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r9",
    "package": "jdg.micro.pit",
    "priority": 60014,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a6.r10: pit_a6_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a6.r10",
    "package": "jdg.micro.pit",
    "priority": 60015,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wspólne rozliczenie małżonków: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a9 — Strata podatkowa (10 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a9.r1: pit_a9_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r1",
    "package": "jdg.micro.pit",
    "priority": 60016,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a9.r2: pit_a9_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r2",
    "package": "jdg.micro.pit",
    "priority": 60017,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a9.r3: pit_a9_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r3",
    "package": "jdg.micro.pit",
    "priority": 60018,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a9_r3_pass", false) == true
}

# jdg.micro.pit.a9.r4: pit_a9_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r4",
    "package": "jdg.micro.pit",
    "priority": 60019,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a9_r4_checks", false) == true
}

# jdg.micro.pit.a9.r5: pit_a9_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r5",
    "package": "jdg.micro.pit",
    "priority": 60020,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a9.r6: pit_a9_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r6",
    "package": "jdg.micro.pit",
    "priority": 60021,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a9.r7: pit_a9_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r7",
    "package": "jdg.micro.pit",
    "priority": 60022,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a9_exception", false) == true
}

# jdg.micro.pit.a9.r8: pit_a9_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r8",
    "package": "jdg.micro.pit",
    "priority": 60023,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a9_exception_2", false) == true
}

# jdg.micro.pit.a9.r9: pit_a9_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r9",
    "package": "jdg.micro.pit",
    "priority": 60024,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a9.r10: pit_a9_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9.r10",
    "package": "jdg.micro.pit",
    "priority": 60025,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Strata podatkowa: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a9a — Wybór formy opodatkowania (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a9a.r1: pit_a9a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r1",
    "package": "jdg.micro.pit",
    "priority": 60026,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a9a.r2: pit_a9a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r2",
    "package": "jdg.micro.pit",
    "priority": 60027,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a9a.r3: pit_a9a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r3",
    "package": "jdg.micro.pit",
    "priority": 60028,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a9a_r3_pass", false) == true
}

# jdg.micro.pit.a9a.r4: pit_a9a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r4",
    "package": "jdg.micro.pit",
    "priority": 60029,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a9a_r4_checks", false) == true
}

# jdg.micro.pit.a9a.r5: pit_a9a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r5",
    "package": "jdg.micro.pit",
    "priority": 60030,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a9a.r6: pit_a9a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r6",
    "package": "jdg.micro.pit",
    "priority": 60031,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a9a.r7: pit_a9a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r7",
    "package": "jdg.micro.pit",
    "priority": 60032,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a9a_exception", false) == true
}

# jdg.micro.pit.a9a.r8: pit_a9a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r8",
    "package": "jdg.micro.pit",
    "priority": 60033,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a9a_exception_2", false) == true
}

# jdg.micro.pit.a9a.r9: pit_a9a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r9",
    "package": "jdg.micro.pit",
    "priority": 60034,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a9a.r10: pit_a9a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r10",
    "package": "jdg.micro.pit",
    "priority": 60035,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a9a.r11: pit_a9a_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r11",
    "package": "jdg.micro.pit",
    "priority": 60036,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a9a.r12: pit_a9a_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a9a.r12",
    "package": "jdg.micro.pit",
    "priority": 60037,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Wybór formy opodatkowania",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wybór formy opodatkowania: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a9a_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a10 — Źródła przychodów (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a10.r1: pit_a10_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r1",
    "package": "jdg.micro.pit",
    "priority": 60038,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a10.r2: pit_a10_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r2",
    "package": "jdg.micro.pit",
    "priority": 60039,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a10.r3: pit_a10_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r3",
    "package": "jdg.micro.pit",
    "priority": 60040,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a10_r3_pass", false) == true
}

# jdg.micro.pit.a10.r4: pit_a10_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r4",
    "package": "jdg.micro.pit",
    "priority": 60041,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a10_r4_checks", false) == true
}

# jdg.micro.pit.a10.r5: pit_a10_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r5",
    "package": "jdg.micro.pit",
    "priority": 60042,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a10.r6: pit_a10_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r6",
    "package": "jdg.micro.pit",
    "priority": 60043,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a10.r7: pit_a10_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r7",
    "package": "jdg.micro.pit",
    "priority": 60044,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a10_exception", false) == true
}

# jdg.micro.pit.a10.r8: pit_a10_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r8",
    "package": "jdg.micro.pit",
    "priority": 60045,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a10_exception_2", false) == true
}

# jdg.micro.pit.a10.r9: pit_a10_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r9",
    "package": "jdg.micro.pit",
    "priority": 60046,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a10.r10: pit_a10_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r10",
    "package": "jdg.micro.pit",
    "priority": 60047,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a10.r11: pit_a10_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r11",
    "package": "jdg.micro.pit",
    "priority": 60048,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a10.r12: pit_a10_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a10.r12",
    "package": "jdg.micro.pit",
    "priority": 60049,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Źródła przychodów",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Źródła przychodów: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a10_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a14 — Przychody z działalności gospodarczej (20 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a14.r1: pit_a14_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r1",
    "package": "jdg.micro.pit",
    "priority": 60050,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a14.r2: pit_a14_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r2",
    "package": "jdg.micro.pit",
    "priority": 60051,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a14.r3: pit_a14_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r3",
    "package": "jdg.micro.pit",
    "priority": 60052,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a14_r3_pass", false) == true
}

# jdg.micro.pit.a14.r4: pit_a14_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r4",
    "package": "jdg.micro.pit",
    "priority": 60053,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a14_r4_checks", false) == true
}

# jdg.micro.pit.a14.r5: pit_a14_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r5",
    "package": "jdg.micro.pit",
    "priority": 60054,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a14.r6: pit_a14_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r6",
    "package": "jdg.micro.pit",
    "priority": 60055,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a14.r7: pit_a14_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r7",
    "package": "jdg.micro.pit",
    "priority": 60056,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a14_exception", false) == true
}

# jdg.micro.pit.a14.r8: pit_a14_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r8",
    "package": "jdg.micro.pit",
    "priority": 60057,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a14_exception_2", false) == true
}

# jdg.micro.pit.a14.r9: pit_a14_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r9",
    "package": "jdg.micro.pit",
    "priority": 60058,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a14.r10: pit_a14_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r10",
    "package": "jdg.micro.pit",
    "priority": 60059,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a14.r11: pit_a14_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r11",
    "package": "jdg.micro.pit",
    "priority": 60060,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a14.r12: pit_a14_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r12",
    "package": "jdg.micro.pit",
    "priority": 60061,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Przychody z działalności gospodarczej",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a14_violation", false) == true
}

# jdg.micro.pit.a14.r13: pit_a14_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r13",
    "package": "jdg.micro.pit",
    "priority": 60062,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a14_edge_case", false) == true
}

# jdg.micro.pit.a14.r14: pit_a14_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r14",
    "package": "jdg.micro.pit",
    "priority": 60063,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a14_edge_case_2", false) == true
}

# jdg.micro.pit.a14.r15: pit_a14_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r15",
    "package": "jdg.micro.pit",
    "priority": 60064,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# jdg.micro.pit.a14.r16: pit_a14_r16_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r16",
    "package": "jdg.micro.pit",
    "priority": 60065,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a14.r17: pit_a14_r17_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r17",
    "package": "jdg.micro.pit",
    "priority": 60066,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a14.r18: pit_a14_r18_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r18",
    "package": "jdg.micro.pit",
    "priority": 60067,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a14_r18_pass", false) == true
}

# jdg.micro.pit.a14.r19: pit_a14_r19_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r19",
    "package": "jdg.micro.pit",
    "priority": 60068,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a14_r19_checks", false) == true
}

# jdg.micro.pit.a14.r20: pit_a14_r20_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14.r20",
    "package": "jdg.micro.pit",
    "priority": 60069,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Przychody z działalności gospodarczej: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a14c — Różnice kursowe (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a14c.r1: pit_a14c_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r1",
    "package": "jdg.micro.pit",
    "priority": 60070,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a14c.r2: pit_a14c_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r2",
    "package": "jdg.micro.pit",
    "priority": 60071,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a14c.r3: pit_a14c_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r3",
    "package": "jdg.micro.pit",
    "priority": 60072,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a14c_r3_pass", false) == true
}

# jdg.micro.pit.a14c.r4: pit_a14c_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r4",
    "package": "jdg.micro.pit",
    "priority": 60073,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a14c_r4_checks", false) == true
}

# jdg.micro.pit.a14c.r5: pit_a14c_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r5",
    "package": "jdg.micro.pit",
    "priority": 60074,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a14c.r6: pit_a14c_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r6",
    "package": "jdg.micro.pit",
    "priority": 60075,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a14c.r7: pit_a14c_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r7",
    "package": "jdg.micro.pit",
    "priority": 60076,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a14c_exception", false) == true
}

# jdg.micro.pit.a14c.r8: pit_a14c_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r8",
    "package": "jdg.micro.pit",
    "priority": 60077,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a14c_exception_2", false) == true
}

# jdg.micro.pit.a14c.r9: pit_a14c_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r9",
    "package": "jdg.micro.pit",
    "priority": 60078,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a14c.r10: pit_a14c_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r10",
    "package": "jdg.micro.pit",
    "priority": 60079,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a14c.r11: pit_a14c_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r11",
    "package": "jdg.micro.pit",
    "priority": 60080,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a14c.r12: pit_a14c_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a14c.r12",
    "package": "jdg.micro.pit",
    "priority": 60081,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Różnice kursowe",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Różnice kursowe: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a14c_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a21 — Zwolnienia przedmiotowe PIT (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a21.r1: pit_a21_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r1",
    "package": "jdg.micro.pit",
    "priority": 60082,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a21.r2: pit_a21_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r2",
    "package": "jdg.micro.pit",
    "priority": 60083,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a21.r3: pit_a21_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r3",
    "package": "jdg.micro.pit",
    "priority": 60084,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21_r3_pass", false) == true
}

# jdg.micro.pit.a21.r4: pit_a21_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r4",
    "package": "jdg.micro.pit",
    "priority": 60085,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21_r4_checks", false) == true
}

# jdg.micro.pit.a21.r5: pit_a21_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r5",
    "package": "jdg.micro.pit",
    "priority": 60086,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a21.r6: pit_a21_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r6",
    "package": "jdg.micro.pit",
    "priority": 60087,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a21.r7: pit_a21_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r7",
    "package": "jdg.micro.pit",
    "priority": 60088,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a21_exception", false) == true
}

# jdg.micro.pit.a21.r8: pit_a21_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r8",
    "package": "jdg.micro.pit",
    "priority": 60089,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a21_exception_2", false) == true
}

# jdg.micro.pit.a21.r9: pit_a21_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r9",
    "package": "jdg.micro.pit",
    "priority": 60090,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a21.r10: pit_a21_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r10",
    "package": "jdg.micro.pit",
    "priority": 60091,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a21.r11: pit_a21_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r11",
    "package": "jdg.micro.pit",
    "priority": 60092,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a21.r12: pit_a21_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21.r12",
    "package": "jdg.micro.pit",
    "priority": 60093,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Zwolnienia przedmiotowe PIT",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zwolnienia przedmiotowe PIT: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22 — KUP — definicja ogólna (15 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22.r1: pit_a22_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r1",
    "package": "jdg.micro.pit",
    "priority": 60094,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22.r2: pit_a22_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r2",
    "package": "jdg.micro.pit",
    "priority": 60095,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22.r3: pit_a22_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r3",
    "package": "jdg.micro.pit",
    "priority": 60096,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22_r3_pass", false) == true
}

# jdg.micro.pit.a22.r4: pit_a22_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r4",
    "package": "jdg.micro.pit",
    "priority": 60097,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22_r4_checks", false) == true
}

# jdg.micro.pit.a22.r5: pit_a22_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r5",
    "package": "jdg.micro.pit",
    "priority": 60098,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22.r6: pit_a22_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r6",
    "package": "jdg.micro.pit",
    "priority": 60099,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a22.r7: pit_a22_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r7",
    "package": "jdg.micro.pit",
    "priority": 60100,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a22_exception", false) == true
}

# jdg.micro.pit.a22.r8: pit_a22_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r8",
    "package": "jdg.micro.pit",
    "priority": 60101,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a22_exception_2", false) == true
}

# jdg.micro.pit.a22.r9: pit_a22_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r9",
    "package": "jdg.micro.pit",
    "priority": 60102,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a22.r10: pit_a22_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r10",
    "package": "jdg.micro.pit",
    "priority": 60103,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a22.r11: pit_a22_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r11",
    "package": "jdg.micro.pit",
    "priority": 60104,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a22.r12: pit_a22_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r12",
    "package": "jdg.micro.pit",
    "priority": 60105,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie KUP — definicja ogólna",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22_violation", false) == true
}

# jdg.micro.pit.a22.r13: pit_a22_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r13",
    "package": "jdg.micro.pit",
    "priority": 60106,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a22_edge_case", false) == true
}

# jdg.micro.pit.a22.r14: pit_a22_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r14",
    "package": "jdg.micro.pit",
    "priority": 60107,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a22_edge_case_2", false) == true
}

# jdg.micro.pit.a22.r15: pit_a22_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22.r15",
    "package": "jdg.micro.pit",
    "priority": 60108,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] KUP — definicja ogólna: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22a — Amortyzacja — definicje (10 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22a.r1: pit_a22a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r1",
    "package": "jdg.micro.pit",
    "priority": 60109,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22a.r2: pit_a22a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r2",
    "package": "jdg.micro.pit",
    "priority": 60110,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22a.r3: pit_a22a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r3",
    "package": "jdg.micro.pit",
    "priority": 60111,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22a_r3_pass", false) == true
}

# jdg.micro.pit.a22a.r4: pit_a22a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r4",
    "package": "jdg.micro.pit",
    "priority": 60112,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22a_r4_checks", false) == true
}

# jdg.micro.pit.a22a.r5: pit_a22a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r5",
    "package": "jdg.micro.pit",
    "priority": 60113,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22a.r6: pit_a22a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r6",
    "package": "jdg.micro.pit",
    "priority": 60114,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a22a.r7: pit_a22a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r7",
    "package": "jdg.micro.pit",
    "priority": 60115,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a22a_exception", false) == true
}

# jdg.micro.pit.a22a.r8: pit_a22a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r8",
    "package": "jdg.micro.pit",
    "priority": 60116,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a22a_exception_2", false) == true
}

# jdg.micro.pit.a22a.r9: pit_a22a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r9",
    "package": "jdg.micro.pit",
    "priority": 60117,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a22a.r10: pit_a22a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22a.r10",
    "package": "jdg.micro.pit",
    "priority": 60118,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — definicje: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22d — Amortyzacja — metody (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22d.r1: pit_a22d_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22d.r1",
    "package": "jdg.micro.pit",
    "priority": 60119,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — metody: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22d.r2: pit_a22d_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22d.r2",
    "package": "jdg.micro.pit",
    "priority": 60120,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — metody: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22d.r3: pit_a22d_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22d.r3",
    "package": "jdg.micro.pit",
    "priority": 60121,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — metody: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22d_r3_pass", false) == true
}

# jdg.micro.pit.a22d.r4: pit_a22d_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22d.r4",
    "package": "jdg.micro.pit",
    "priority": 60122,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — metody: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22d_r4_checks", false) == true
}

# jdg.micro.pit.a22d.r5: pit_a22d_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22d.r5",
    "package": "jdg.micro.pit",
    "priority": 60123,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — metody: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22d.r6: pit_a22d_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22d.r6",
    "package": "jdg.micro.pit",
    "priority": 60124,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — metody: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a22d.r7: pit_a22d_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22d.r7",
    "package": "jdg.micro.pit",
    "priority": 60125,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — metody: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a22d_exception", false) == true
}

# jdg.micro.pit.a22d.r8: pit_a22d_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22d.r8",
    "package": "jdg.micro.pit",
    "priority": 60126,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — metody: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a22d_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22e — Amortyzacja — jednorazowa (6 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22e.r1: pit_a22e_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22e.r1",
    "package": "jdg.micro.pit",
    "priority": 60127,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — jednorazowa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22e.r2: pit_a22e_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22e.r2",
    "package": "jdg.micro.pit",
    "priority": 60128,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — jednorazowa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22e.r3: pit_a22e_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22e.r3",
    "package": "jdg.micro.pit",
    "priority": 60129,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — jednorazowa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22e_r3_pass", false) == true
}

# jdg.micro.pit.a22e.r4: pit_a22e_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22e.r4",
    "package": "jdg.micro.pit",
    "priority": 60130,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — jednorazowa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22e_r4_checks", false) == true
}

# jdg.micro.pit.a22e.r5: pit_a22e_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22e.r5",
    "package": "jdg.micro.pit",
    "priority": 60131,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — jednorazowa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22e.r6: pit_a22e_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22e.r6",
    "package": "jdg.micro.pit",
    "priority": 60132,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — jednorazowa: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22f — Amortyzacja — używane (6 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22f.r1: pit_a22f_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22f.r1",
    "package": "jdg.micro.pit",
    "priority": 60133,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — używane: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22f.r2: pit_a22f_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22f.r2",
    "package": "jdg.micro.pit",
    "priority": 60134,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — używane: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22f.r3: pit_a22f_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22f.r3",
    "package": "jdg.micro.pit",
    "priority": 60135,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — używane: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22f_r3_pass", false) == true
}

# jdg.micro.pit.a22f.r4: pit_a22f_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22f.r4",
    "package": "jdg.micro.pit",
    "priority": 60136,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — używane: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22f_r4_checks", false) == true
}

# jdg.micro.pit.a22f.r5: pit_a22f_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22f.r5",
    "package": "jdg.micro.pit",
    "priority": 60137,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — używane: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22f.r6: pit_a22f_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22f.r6",
    "package": "jdg.micro.pit",
    "priority": 60138,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — używane: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22g — Amortyzacja — stawki (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22g.r1: pit_a22g_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22g.r1",
    "package": "jdg.micro.pit",
    "priority": 60139,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — stawki: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22g.r2: pit_a22g_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22g.r2",
    "package": "jdg.micro.pit",
    "priority": 60140,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — stawki: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22g.r3: pit_a22g_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22g.r3",
    "package": "jdg.micro.pit",
    "priority": 60141,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — stawki: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22g_r3_pass", false) == true
}

# jdg.micro.pit.a22g.r4: pit_a22g_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22g.r4",
    "package": "jdg.micro.pit",
    "priority": 60142,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — stawki: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22g_r4_checks", false) == true
}

# jdg.micro.pit.a22g.r5: pit_a22g_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22g.r5",
    "package": "jdg.micro.pit",
    "priority": 60143,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — stawki: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22g.r6: pit_a22g_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22g.r6",
    "package": "jdg.micro.pit",
    "priority": 60144,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — stawki: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a22g.r7: pit_a22g_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22g.r7",
    "package": "jdg.micro.pit",
    "priority": 60145,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — stawki: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a22g_exception", false) == true
}

# jdg.micro.pit.a22g.r8: pit_a22g_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22g.r8",
    "package": "jdg.micro.pit",
    "priority": 60146,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — stawki: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a22g_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22i — Amortyzacja — moment (6 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22i.r1: pit_a22i_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22i.r1",
    "package": "jdg.micro.pit",
    "priority": 60147,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — moment: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22i.r2: pit_a22i_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22i.r2",
    "package": "jdg.micro.pit",
    "priority": 60148,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — moment: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22i.r3: pit_a22i_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22i.r3",
    "package": "jdg.micro.pit",
    "priority": 60149,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — moment: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22i_r3_pass", false) == true
}

# jdg.micro.pit.a22i.r4: pit_a22i_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22i.r4",
    "package": "jdg.micro.pit",
    "priority": 60150,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — moment: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22i_r4_checks", false) == true
}

# jdg.micro.pit.a22i.r5: pit_a22i_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22i.r5",
    "package": "jdg.micro.pit",
    "priority": 60151,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — moment: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22i.r6: pit_a22i_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22i.r6",
    "package": "jdg.micro.pit",
    "priority": 60152,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — moment: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22j — Amortyzacja — ulepszenie (6 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22j.r1: pit_a22j_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22j.r1",
    "package": "jdg.micro.pit",
    "priority": 60153,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — ulepszenie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22j.r2: pit_a22j_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22j.r2",
    "package": "jdg.micro.pit",
    "priority": 60154,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — ulepszenie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22j.r3: pit_a22j_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22j.r3",
    "package": "jdg.micro.pit",
    "priority": 60155,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — ulepszenie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22j_r3_pass", false) == true
}

# jdg.micro.pit.a22j.r4: pit_a22j_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22j.r4",
    "package": "jdg.micro.pit",
    "priority": 60156,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — ulepszenie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22j_r4_checks", false) == true
}

# jdg.micro.pit.a22j.r5: pit_a22j_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22j.r5",
    "package": "jdg.micro.pit",
    "priority": 60157,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — ulepszenie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22j.r6: pit_a22j_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22j.r6",
    "package": "jdg.micro.pit",
    "priority": 60158,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — ulepszenie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22k — Amortyzacja — sprzedaż (6 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22k.r1: pit_a22k_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22k.r1",
    "package": "jdg.micro.pit",
    "priority": 60159,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — sprzedaż: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22k.r2: pit_a22k_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22k.r2",
    "package": "jdg.micro.pit",
    "priority": 60160,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — sprzedaż: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22k.r3: pit_a22k_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22k.r3",
    "package": "jdg.micro.pit",
    "priority": 60161,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — sprzedaż: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22k_r3_pass", false) == true
}

# jdg.micro.pit.a22k.r4: pit_a22k_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22k.r4",
    "package": "jdg.micro.pit",
    "priority": 60162,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — sprzedaż: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22k_r4_checks", false) == true
}

# jdg.micro.pit.a22k.r5: pit_a22k_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22k.r5",
    "package": "jdg.micro.pit",
    "priority": 60163,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — sprzedaż: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22k.r6: pit_a22k_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22k.r6",
    "package": "jdg.micro.pit",
    "priority": 60164,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — sprzedaż: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22l — Amortyzacja — WNiP (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22l.r1: pit_a22l_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22l.r1",
    "package": "jdg.micro.pit",
    "priority": 60165,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — WNiP: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22l.r2: pit_a22l_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22l.r2",
    "package": "jdg.micro.pit",
    "priority": 60166,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — WNiP: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22l.r3: pit_a22l_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22l.r3",
    "package": "jdg.micro.pit",
    "priority": 60167,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — WNiP: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22l_r3_pass", false) == true
}

# jdg.micro.pit.a22l.r4: pit_a22l_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22l.r4",
    "package": "jdg.micro.pit",
    "priority": 60168,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — WNiP: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22l_r4_checks", false) == true
}

# jdg.micro.pit.a22l.r5: pit_a22l_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22l.r5",
    "package": "jdg.micro.pit",
    "priority": 60169,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — WNiP: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22l.r6: pit_a22l_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22l.r6",
    "package": "jdg.micro.pit",
    "priority": 60170,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — WNiP: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a22l.r7: pit_a22l_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22l.r7",
    "package": "jdg.micro.pit",
    "priority": 60171,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — WNiP: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a22l_exception", false) == true
}

# jdg.micro.pit.a22l.r8: pit_a22l_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22l.r8",
    "package": "jdg.micro.pit",
    "priority": 60172,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — WNiP: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a22l_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22m — Amortyzacja — auto prywatne (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22m.r1: pit_a22m_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22m.r1",
    "package": "jdg.micro.pit",
    "priority": 60173,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — auto prywatne: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22m.r2: pit_a22m_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22m.r2",
    "package": "jdg.micro.pit",
    "priority": 60174,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — auto prywatne: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22m.r3: pit_a22m_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22m.r3",
    "package": "jdg.micro.pit",
    "priority": 60175,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — auto prywatne: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22m_r3_pass", false) == true
}

# jdg.micro.pit.a22m.r4: pit_a22m_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22m.r4",
    "package": "jdg.micro.pit",
    "priority": 60176,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — auto prywatne: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22m_r4_checks", false) == true
}

# jdg.micro.pit.a22m.r5: pit_a22m_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22m.r5",
    "package": "jdg.micro.pit",
    "priority": 60177,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — auto prywatne: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22m.r6: pit_a22m_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22m.r6",
    "package": "jdg.micro.pit",
    "priority": 60178,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — auto prywatne: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a22m.r7: pit_a22m_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22m.r7",
    "package": "jdg.micro.pit",
    "priority": 60179,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — auto prywatne: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a22m_exception", false) == true
}

# jdg.micro.pit.a22m.r8: pit_a22m_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22m.r8",
    "package": "jdg.micro.pit",
    "priority": 60180,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Amortyzacja — auto prywatne: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a22m_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22p — Limit płatności gotówkowych (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a22p.r1: pit_a22p_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22p.r1",
    "package": "jdg.micro.pit",
    "priority": 60181,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Limit płatności gotówkowych: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a22p.r2: pit_a22p_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22p.r2",
    "package": "jdg.micro.pit",
    "priority": 60182,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Limit płatności gotówkowych: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a22p.r3: pit_a22p_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22p.r3",
    "package": "jdg.micro.pit",
    "priority": 60183,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Limit płatności gotówkowych: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22p_r3_pass", false) == true
}

# jdg.micro.pit.a22p.r4: pit_a22p_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22p.r4",
    "package": "jdg.micro.pit",
    "priority": 60184,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Limit płatności gotówkowych: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a22p_r4_checks", false) == true
}

# jdg.micro.pit.a22p.r5: pit_a22p_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22p.r5",
    "package": "jdg.micro.pit",
    "priority": 60185,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Limit płatności gotówkowych: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a22p.r6: pit_a22p_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22p.r6",
    "package": "jdg.micro.pit",
    "priority": 60186,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Limit płatności gotówkowych: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a22p.r7: pit_a22p_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22p.r7",
    "package": "jdg.micro.pit",
    "priority": 60187,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Limit płatności gotówkowych: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a22p_exception", false) == true
}

# jdg.micro.pit.a22p.r8: pit_a22p_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a22p.r8",
    "package": "jdg.micro.pit",
    "priority": 60188,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Limit płatności gotówkowych: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a22p_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a23 — Wyłączenia z KUP (30 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a23.r1: pit_a23_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r1",
    "package": "jdg.micro.pit",
    "priority": 60189,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a23.r2: pit_a23_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r2",
    "package": "jdg.micro.pit",
    "priority": 60190,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a23.r3: pit_a23_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r3",
    "package": "jdg.micro.pit",
    "priority": 60191,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a23_r3_pass", false) == true
}

# jdg.micro.pit.a23.r4: pit_a23_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r4",
    "package": "jdg.micro.pit",
    "priority": 60192,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a23_r4_checks", false) == true
}

# jdg.micro.pit.a23.r5: pit_a23_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r5",
    "package": "jdg.micro.pit",
    "priority": 60193,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a23.r6: pit_a23_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r6",
    "package": "jdg.micro.pit",
    "priority": 60194,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a23.r7: pit_a23_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r7",
    "package": "jdg.micro.pit",
    "priority": 60195,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a23_exception", false) == true
}

# jdg.micro.pit.a23.r8: pit_a23_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r8",
    "package": "jdg.micro.pit",
    "priority": 60196,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a23_exception_2", false) == true
}

# jdg.micro.pit.a23.r9: pit_a23_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r9",
    "package": "jdg.micro.pit",
    "priority": 60197,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a23.r10: pit_a23_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r10",
    "package": "jdg.micro.pit",
    "priority": 60198,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a23.r11: pit_a23_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r11",
    "package": "jdg.micro.pit",
    "priority": 60199,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a23.r12: pit_a23_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r12",
    "package": "jdg.micro.pit",
    "priority": 60200,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Wyłączenia z KUP",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a23_violation", false) == true
}

# jdg.micro.pit.a23.r13: pit_a23_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r13",
    "package": "jdg.micro.pit",
    "priority": 60201,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a23_edge_case", false) == true
}

# jdg.micro.pit.a23.r14: pit_a23_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r14",
    "package": "jdg.micro.pit",
    "priority": 60202,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a23_edge_case_2", false) == true
}

# jdg.micro.pit.a23.r15: pit_a23_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r15",
    "package": "jdg.micro.pit",
    "priority": 60203,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# jdg.micro.pit.a23.r16: pit_a23_r16_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r16",
    "package": "jdg.micro.pit",
    "priority": 60204,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a23.r17: pit_a23_r17_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r17",
    "package": "jdg.micro.pit",
    "priority": 60205,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a23.r18: pit_a23_r18_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r18",
    "package": "jdg.micro.pit",
    "priority": 60206,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a23_r18_pass", false) == true
}

# jdg.micro.pit.a23.r19: pit_a23_r19_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r19",
    "package": "jdg.micro.pit",
    "priority": 60207,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a23_r19_checks", false) == true
}

# jdg.micro.pit.a23.r20: pit_a23_r20_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r20",
    "package": "jdg.micro.pit",
    "priority": 60208,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a23.r21: pit_a23_r21_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r21",
    "package": "jdg.micro.pit",
    "priority": 60209,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a23.r22: pit_a23_r22_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r22",
    "package": "jdg.micro.pit",
    "priority": 60210,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a23_exception", false) == true
}

# jdg.micro.pit.a23.r23: pit_a23_r23_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r23",
    "package": "jdg.micro.pit",
    "priority": 60211,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a23_exception_2", false) == true
}

# jdg.micro.pit.a23.r24: pit_a23_r24_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r24",
    "package": "jdg.micro.pit",
    "priority": 60212,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a23.r25: pit_a23_r25_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r25",
    "package": "jdg.micro.pit",
    "priority": 60213,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a23.r26: pit_a23_r26_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r26",
    "package": "jdg.micro.pit",
    "priority": 60214,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a23.r27: pit_a23_r27_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r27",
    "package": "jdg.micro.pit",
    "priority": 60215,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 50000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Wyłączenia z KUP",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a23_violation", false) == true
}

# jdg.micro.pit.a23.r28: pit_a23_r28_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r28",
    "package": "jdg.micro.pit",
    "priority": 60216,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a23_edge_case", false) == true
}

# jdg.micro.pit.a23.r29: pit_a23_r29_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r29",
    "package": "jdg.micro.pit",
    "priority": 60217,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a23_edge_case_2", false) == true
}

# jdg.micro.pit.a23.r30: pit_a23_r30_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a23.r30",
    "package": "jdg.micro.pit",
    "priority": 60218,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Wyłączenia z KUP: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a24 — Dochód i strata (15 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a24.r1: pit_a24_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r1",
    "package": "jdg.micro.pit",
    "priority": 60219,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a24.r2: pit_a24_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r2",
    "package": "jdg.micro.pit",
    "priority": 60220,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a24.r3: pit_a24_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r3",
    "package": "jdg.micro.pit",
    "priority": 60221,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a24_r3_pass", false) == true
}

# jdg.micro.pit.a24.r4: pit_a24_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r4",
    "package": "jdg.micro.pit",
    "priority": 60222,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a24_r4_checks", false) == true
}

# jdg.micro.pit.a24.r5: pit_a24_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r5",
    "package": "jdg.micro.pit",
    "priority": 60223,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a24.r6: pit_a24_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r6",
    "package": "jdg.micro.pit",
    "priority": 60224,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a24.r7: pit_a24_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r7",
    "package": "jdg.micro.pit",
    "priority": 60225,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a24_exception", false) == true
}

# jdg.micro.pit.a24.r8: pit_a24_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r8",
    "package": "jdg.micro.pit",
    "priority": 60226,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a24_exception_2", false) == true
}

# jdg.micro.pit.a24.r9: pit_a24_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r9",
    "package": "jdg.micro.pit",
    "priority": 60227,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a24.r10: pit_a24_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r10",
    "package": "jdg.micro.pit",
    "priority": 60228,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a24.r11: pit_a24_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r11",
    "package": "jdg.micro.pit",
    "priority": 60229,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a24.r12: pit_a24_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r12",
    "package": "jdg.micro.pit",
    "priority": 60230,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Dochód i strata",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a24_violation", false) == true
}

# jdg.micro.pit.a24.r13: pit_a24_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r13",
    "package": "jdg.micro.pit",
    "priority": 60231,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a24_edge_case", false) == true
}

# jdg.micro.pit.a24.r14: pit_a24_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r14",
    "package": "jdg.micro.pit",
    "priority": 60232,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a24_edge_case_2", false) == true
}

# jdg.micro.pit.a24.r15: pit_a24_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24.r15",
    "package": "jdg.micro.pit",
    "priority": 60233,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochód i strata: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a24a — Obowiązek PKPiR (10 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a24a.r1: pit_a24a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r1",
    "package": "jdg.micro.pit",
    "priority": 60234,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a24a.r2: pit_a24a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r2",
    "package": "jdg.micro.pit",
    "priority": 60235,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a24a.r3: pit_a24a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r3",
    "package": "jdg.micro.pit",
    "priority": 60236,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a24a_r3_pass", false) == true
}

# jdg.micro.pit.a24a.r4: pit_a24a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r4",
    "package": "jdg.micro.pit",
    "priority": 60237,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a24a_r4_checks", false) == true
}

# jdg.micro.pit.a24a.r5: pit_a24a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r5",
    "package": "jdg.micro.pit",
    "priority": 60238,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a24a.r6: pit_a24a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r6",
    "package": "jdg.micro.pit",
    "priority": 60239,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a24a.r7: pit_a24a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r7",
    "package": "jdg.micro.pit",
    "priority": 60240,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a24a_exception", false) == true
}

# jdg.micro.pit.a24a.r8: pit_a24a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r8",
    "package": "jdg.micro.pit",
    "priority": 60241,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a24a_exception_2", false) == true
}

# jdg.micro.pit.a24a.r9: pit_a24a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r9",
    "package": "jdg.micro.pit",
    "priority": 60242,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a24a.r10: pit_a24a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a24a.r10",
    "package": "jdg.micro.pit",
    "priority": 60243,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Obowiązek PKPiR: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a26 — Ulgi odliczane od dochodu (25 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a26.r1: pit_a26_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r1",
    "package": "jdg.micro.pit",
    "priority": 60244,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a26.r2: pit_a26_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r2",
    "package": "jdg.micro.pit",
    "priority": 60245,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a26.r3: pit_a26_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r3",
    "package": "jdg.micro.pit",
    "priority": 60246,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26_r3_pass", false) == true
}

# jdg.micro.pit.a26.r4: pit_a26_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r4",
    "package": "jdg.micro.pit",
    "priority": 60247,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26_r4_checks", false) == true
}

# jdg.micro.pit.a26.r5: pit_a26_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r5",
    "package": "jdg.micro.pit",
    "priority": 60248,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a26.r6: pit_a26_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r6",
    "package": "jdg.micro.pit",
    "priority": 60249,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a26.r7: pit_a26_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r7",
    "package": "jdg.micro.pit",
    "priority": 60250,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a26_exception", false) == true
}

# jdg.micro.pit.a26.r8: pit_a26_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r8",
    "package": "jdg.micro.pit",
    "priority": 60251,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a26_exception_2", false) == true
}

# jdg.micro.pit.a26.r9: pit_a26_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r9",
    "package": "jdg.micro.pit",
    "priority": 60252,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a26.r10: pit_a26_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r10",
    "package": "jdg.micro.pit",
    "priority": 60253,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a26.r11: pit_a26_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r11",
    "package": "jdg.micro.pit",
    "priority": 60254,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a26.r12: pit_a26_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r12",
    "package": "jdg.micro.pit",
    "priority": 60255,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Ulgi odliczane od dochodu",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26_violation", false) == true
}

# jdg.micro.pit.a26.r13: pit_a26_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r13",
    "package": "jdg.micro.pit",
    "priority": 60256,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a26_edge_case", false) == true
}

# jdg.micro.pit.a26.r14: pit_a26_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r14",
    "package": "jdg.micro.pit",
    "priority": 60257,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a26_edge_case_2", false) == true
}

# jdg.micro.pit.a26.r15: pit_a26_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r15",
    "package": "jdg.micro.pit",
    "priority": 60258,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# jdg.micro.pit.a26.r16: pit_a26_r16_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r16",
    "package": "jdg.micro.pit",
    "priority": 60259,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a26.r17: pit_a26_r17_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r17",
    "package": "jdg.micro.pit",
    "priority": 60260,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a26.r18: pit_a26_r18_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r18",
    "package": "jdg.micro.pit",
    "priority": 60261,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26_r18_pass", false) == true
}

# jdg.micro.pit.a26.r19: pit_a26_r19_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r19",
    "package": "jdg.micro.pit",
    "priority": 60262,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26_r19_checks", false) == true
}

# jdg.micro.pit.a26.r20: pit_a26_r20_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r20",
    "package": "jdg.micro.pit",
    "priority": 60263,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a26.r21: pit_a26_r21_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r21",
    "package": "jdg.micro.pit",
    "priority": 60264,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a26.r22: pit_a26_r22_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r22",
    "package": "jdg.micro.pit",
    "priority": 60265,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a26_exception", false) == true
}

# jdg.micro.pit.a26.r23: pit_a26_r23_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r23",
    "package": "jdg.micro.pit",
    "priority": 60266,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a26_exception_2", false) == true
}

# jdg.micro.pit.a26.r24: pit_a26_r24_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r24",
    "package": "jdg.micro.pit",
    "priority": 60267,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a26.r25: pit_a26_r25_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26.r25",
    "package": "jdg.micro.pit",
    "priority": 60268,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulgi odliczane od dochodu: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a26e — Ulga B+R (15 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a26e.r1: pit_a26e_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r1",
    "package": "jdg.micro.pit",
    "priority": 60269,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a26e.r2: pit_a26e_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r2",
    "package": "jdg.micro.pit",
    "priority": 60270,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a26e.r3: pit_a26e_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r3",
    "package": "jdg.micro.pit",
    "priority": 60271,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26e_r3_pass", false) == true
}

# jdg.micro.pit.a26e.r4: pit_a26e_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r4",
    "package": "jdg.micro.pit",
    "priority": 60272,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26e_r4_checks", false) == true
}

# jdg.micro.pit.a26e.r5: pit_a26e_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r5",
    "package": "jdg.micro.pit",
    "priority": 60273,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a26e.r6: pit_a26e_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r6",
    "package": "jdg.micro.pit",
    "priority": 60274,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a26e.r7: pit_a26e_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r7",
    "package": "jdg.micro.pit",
    "priority": 60275,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a26e_exception", false) == true
}

# jdg.micro.pit.a26e.r8: pit_a26e_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r8",
    "package": "jdg.micro.pit",
    "priority": 60276,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a26e_exception_2", false) == true
}

# jdg.micro.pit.a26e.r9: pit_a26e_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r9",
    "package": "jdg.micro.pit",
    "priority": 60277,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a26e.r10: pit_a26e_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r10",
    "package": "jdg.micro.pit",
    "priority": 60278,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a26e.r11: pit_a26e_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r11",
    "package": "jdg.micro.pit",
    "priority": 60279,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a26e.r12: pit_a26e_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r12",
    "package": "jdg.micro.pit",
    "priority": 60280,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Ulga B+R",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26e_violation", false) == true
}

# jdg.micro.pit.a26e.r13: pit_a26e_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r13",
    "package": "jdg.micro.pit",
    "priority": 60281,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a26e_edge_case", false) == true
}

# jdg.micro.pit.a26e.r14: pit_a26e_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r14",
    "package": "jdg.micro.pit",
    "priority": 60282,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a26e_edge_case_2", false) == true
}

# jdg.micro.pit.a26e.r15: pit_a26e_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26e.r15",
    "package": "jdg.micro.pit",
    "priority": 60283,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga B+R: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a26eb — Ulga na prototyp (6 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a26eb.r1: pit_a26eb_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26eb.r1",
    "package": "jdg.micro.pit",
    "priority": 60284,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na prototyp: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a26eb.r2: pit_a26eb_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26eb.r2",
    "package": "jdg.micro.pit",
    "priority": 60285,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na prototyp: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a26eb.r3: pit_a26eb_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26eb.r3",
    "package": "jdg.micro.pit",
    "priority": 60286,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na prototyp: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26eb_r3_pass", false) == true
}

# jdg.micro.pit.a26eb.r4: pit_a26eb_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26eb.r4",
    "package": "jdg.micro.pit",
    "priority": 60287,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na prototyp: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26eb_r4_checks", false) == true
}

# jdg.micro.pit.a26eb.r5: pit_a26eb_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26eb.r5",
    "package": "jdg.micro.pit",
    "priority": 60288,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na prototyp: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a26eb.r6: pit_a26eb_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26eb.r6",
    "package": "jdg.micro.pit",
    "priority": 60289,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na prototyp: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a26ec — Ulga na ekspansję (6 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a26ec.r1: pit_a26ec_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26ec.r1",
    "package": "jdg.micro.pit",
    "priority": 60290,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na ekspansję: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a26ec.r2: pit_a26ec_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26ec.r2",
    "package": "jdg.micro.pit",
    "priority": 60291,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na ekspansję: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a26ec.r3: pit_a26ec_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26ec.r3",
    "package": "jdg.micro.pit",
    "priority": 60292,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na ekspansję: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26ec_r3_pass", false) == true
}

# jdg.micro.pit.a26ec.r4: pit_a26ec_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26ec.r4",
    "package": "jdg.micro.pit",
    "priority": 60293,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na ekspansję: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26ec_r4_checks", false) == true
}

# jdg.micro.pit.a26ec.r5: pit_a26ec_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26ec.r5",
    "package": "jdg.micro.pit",
    "priority": 60294,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na ekspansję: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a26ec.r6: pit_a26ec_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26ec.r6",
    "package": "jdg.micro.pit",
    "priority": 60295,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na ekspansję: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a26gb — Ulga na robotyzację (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a26gb.r1: pit_a26gb_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26gb.r1",
    "package": "jdg.micro.pit",
    "priority": 60296,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na robotyzację: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a26gb.r2: pit_a26gb_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26gb.r2",
    "package": "jdg.micro.pit",
    "priority": 60297,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na robotyzację: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a26gb.r3: pit_a26gb_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26gb.r3",
    "package": "jdg.micro.pit",
    "priority": 60298,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na robotyzację: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26gb_r3_pass", false) == true
}

# jdg.micro.pit.a26gb.r4: pit_a26gb_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26gb.r4",
    "package": "jdg.micro.pit",
    "priority": 60299,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na robotyzację: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26gb_r4_checks", false) == true
}

# jdg.micro.pit.a26gb.r5: pit_a26gb_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26gb.r5",
    "package": "jdg.micro.pit",
    "priority": 60300,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na robotyzację: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a26gb.r6: pit_a26gb_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26gb.r6",
    "package": "jdg.micro.pit",
    "priority": 60301,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na robotyzację: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a26gb.r7: pit_a26gb_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26gb.r7",
    "package": "jdg.micro.pit",
    "priority": 60302,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na robotyzację: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a26gb_exception", false) == true
}

# jdg.micro.pit.a26gb.r8: pit_a26gb_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26gb.r8",
    "package": "jdg.micro.pit",
    "priority": 60303,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na robotyzację: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a26gb_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a26h — Ulga termomodernizacyjna (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a26h.r1: pit_a26h_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26h.r1",
    "package": "jdg.micro.pit",
    "priority": 60304,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga termomodernizacyjna: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a26h.r2: pit_a26h_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26h.r2",
    "package": "jdg.micro.pit",
    "priority": 60305,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga termomodernizacyjna: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a26h.r3: pit_a26h_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26h.r3",
    "package": "jdg.micro.pit",
    "priority": 60306,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga termomodernizacyjna: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26h_r3_pass", false) == true
}

# jdg.micro.pit.a26h.r4: pit_a26h_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26h.r4",
    "package": "jdg.micro.pit",
    "priority": 60307,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga termomodernizacyjna: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a26h_r4_checks", false) == true
}

# jdg.micro.pit.a26h.r5: pit_a26h_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26h.r5",
    "package": "jdg.micro.pit",
    "priority": 60308,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga termomodernizacyjna: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a26h.r6: pit_a26h_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26h.r6",
    "package": "jdg.micro.pit",
    "priority": 60309,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga termomodernizacyjna: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a26h.r7: pit_a26h_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26h.r7",
    "package": "jdg.micro.pit",
    "priority": 60310,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga termomodernizacyjna: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a26h_exception", false) == true
}

# jdg.micro.pit.a26h.r8: pit_a26h_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a26h.r8",
    "package": "jdg.micro.pit",
    "priority": 60311,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga termomodernizacyjna: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a26h_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a27 — Skala podatkowa 12%/32% (15 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a27.r1: pit_a27_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r1",
    "package": "jdg.micro.pit",
    "priority": 60312,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a27.r2: pit_a27_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r2",
    "package": "jdg.micro.pit",
    "priority": 60313,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a27.r3: pit_a27_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r3",
    "package": "jdg.micro.pit",
    "priority": 60314,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a27_r3_pass", false) == true
}

# jdg.micro.pit.a27.r4: pit_a27_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r4",
    "package": "jdg.micro.pit",
    "priority": 60315,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a27_r4_checks", false) == true
}

# jdg.micro.pit.a27.r5: pit_a27_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r5",
    "package": "jdg.micro.pit",
    "priority": 60316,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a27.r6: pit_a27_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r6",
    "package": "jdg.micro.pit",
    "priority": 60317,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a27.r7: pit_a27_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r7",
    "package": "jdg.micro.pit",
    "priority": 60318,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a27_exception", false) == true
}

# jdg.micro.pit.a27.r8: pit_a27_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r8",
    "package": "jdg.micro.pit",
    "priority": 60319,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a27_exception_2", false) == true
}

# jdg.micro.pit.a27.r9: pit_a27_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r9",
    "package": "jdg.micro.pit",
    "priority": 60320,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a27.r10: pit_a27_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r10",
    "package": "jdg.micro.pit",
    "priority": 60321,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a27.r11: pit_a27_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r11",
    "package": "jdg.micro.pit",
    "priority": 60322,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a27.r12: pit_a27_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r12",
    "package": "jdg.micro.pit",
    "priority": 60323,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Skala podatkowa 12%/32%",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a27_violation", false) == true
}

# jdg.micro.pit.a27.r13: pit_a27_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r13",
    "package": "jdg.micro.pit",
    "priority": 60324,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a27_edge_case", false) == true
}

# jdg.micro.pit.a27.r14: pit_a27_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r14",
    "package": "jdg.micro.pit",
    "priority": 60325,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a27_edge_case_2", false) == true
}

# jdg.micro.pit.a27.r15: pit_a27_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27.r15",
    "package": "jdg.micro.pit",
    "priority": 60326,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.12",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Skala podatkowa 12%/32%: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a27f — Ulga na dzieci (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a27f.r1: pit_a27f_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r1",
    "package": "jdg.micro.pit",
    "priority": 60327,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a27f.r2: pit_a27f_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r2",
    "package": "jdg.micro.pit",
    "priority": 60328,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a27f.r3: pit_a27f_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r3",
    "package": "jdg.micro.pit",
    "priority": 60329,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a27f_r3_pass", false) == true
}

# jdg.micro.pit.a27f.r4: pit_a27f_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r4",
    "package": "jdg.micro.pit",
    "priority": 60330,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a27f_r4_checks", false) == true
}

# jdg.micro.pit.a27f.r5: pit_a27f_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r5",
    "package": "jdg.micro.pit",
    "priority": 60331,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a27f.r6: pit_a27f_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r6",
    "package": "jdg.micro.pit",
    "priority": 60332,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a27f.r7: pit_a27f_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r7",
    "package": "jdg.micro.pit",
    "priority": 60333,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a27f_exception", false) == true
}

# jdg.micro.pit.a27f.r8: pit_a27f_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r8",
    "package": "jdg.micro.pit",
    "priority": 60334,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a27f_exception_2", false) == true
}

# jdg.micro.pit.a27f.r9: pit_a27f_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r9",
    "package": "jdg.micro.pit",
    "priority": 60335,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a27f.r10: pit_a27f_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r10",
    "package": "jdg.micro.pit",
    "priority": 60336,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a27f.r11: pit_a27f_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r11",
    "package": "jdg.micro.pit",
    "priority": 60337,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a27f.r12: pit_a27f_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a27f.r12",
    "package": "jdg.micro.pit",
    "priority": 60338,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Ulga na dzieci",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na dzieci: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a27f_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a30 — Ryczałt od kapitałów (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a30.r1: pit_a30_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r1",
    "package": "jdg.micro.pit",
    "priority": 60339,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a30.r2: pit_a30_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r2",
    "package": "jdg.micro.pit",
    "priority": 60340,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a30.r3: pit_a30_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r3",
    "package": "jdg.micro.pit",
    "priority": 60341,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30_r3_pass", false) == true
}

# jdg.micro.pit.a30.r4: pit_a30_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r4",
    "package": "jdg.micro.pit",
    "priority": 60342,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30_r4_checks", false) == true
}

# jdg.micro.pit.a30.r5: pit_a30_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r5",
    "package": "jdg.micro.pit",
    "priority": 60343,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a30.r6: pit_a30_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r6",
    "package": "jdg.micro.pit",
    "priority": 60344,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a30.r7: pit_a30_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r7",
    "package": "jdg.micro.pit",
    "priority": 60345,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a30_exception", false) == true
}

# jdg.micro.pit.a30.r8: pit_a30_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r8",
    "package": "jdg.micro.pit",
    "priority": 60346,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a30_exception_2", false) == true
}

# jdg.micro.pit.a30.r9: pit_a30_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r9",
    "package": "jdg.micro.pit",
    "priority": 60347,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a30.r10: pit_a30_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r10",
    "package": "jdg.micro.pit",
    "priority": 60348,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a30.r11: pit_a30_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r11",
    "package": "jdg.micro.pit",
    "priority": 60349,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a30.r12: pit_a30_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30.r12",
    "package": "jdg.micro.pit",
    "priority": 60350,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Ryczałt od kapitałów",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ryczałt od kapitałów: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a30a — Dochody kapitałowe (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a30a.r1: pit_a30a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r1",
    "package": "jdg.micro.pit",
    "priority": 60351,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a30a.r2: pit_a30a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r2",
    "package": "jdg.micro.pit",
    "priority": 60352,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a30a.r3: pit_a30a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r3",
    "package": "jdg.micro.pit",
    "priority": 60353,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30a_r3_pass", false) == true
}

# jdg.micro.pit.a30a.r4: pit_a30a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r4",
    "package": "jdg.micro.pit",
    "priority": 60354,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30a_r4_checks", false) == true
}

# jdg.micro.pit.a30a.r5: pit_a30a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r5",
    "package": "jdg.micro.pit",
    "priority": 60355,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a30a.r6: pit_a30a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r6",
    "package": "jdg.micro.pit",
    "priority": 60356,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a30a.r7: pit_a30a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r7",
    "package": "jdg.micro.pit",
    "priority": 60357,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a30a_exception", false) == true
}

# jdg.micro.pit.a30a.r8: pit_a30a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r8",
    "package": "jdg.micro.pit",
    "priority": 60358,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a30a_exception_2", false) == true
}

# jdg.micro.pit.a30a.r9: pit_a30a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r9",
    "package": "jdg.micro.pit",
    "priority": 60359,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a30a.r10: pit_a30a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r10",
    "package": "jdg.micro.pit",
    "priority": 60360,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a30a.r11: pit_a30a_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r11",
    "package": "jdg.micro.pit",
    "priority": 60361,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a30a.r12: pit_a30a_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30a.r12",
    "package": "jdg.micro.pit",
    "priority": 60362,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Dochody kapitałowe",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Dochody kapitałowe: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30a_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a30b — Sprzedaż nieruchomości (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a30b.r1: pit_a30b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r1",
    "package": "jdg.micro.pit",
    "priority": 60363,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a30b.r2: pit_a30b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r2",
    "package": "jdg.micro.pit",
    "priority": 60364,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a30b.r3: pit_a30b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r3",
    "package": "jdg.micro.pit",
    "priority": 60365,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30b_r3_pass", false) == true
}

# jdg.micro.pit.a30b.r4: pit_a30b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r4",
    "package": "jdg.micro.pit",
    "priority": 60366,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30b_r4_checks", false) == true
}

# jdg.micro.pit.a30b.r5: pit_a30b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r5",
    "package": "jdg.micro.pit",
    "priority": 60367,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a30b.r6: pit_a30b_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r6",
    "package": "jdg.micro.pit",
    "priority": 60368,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a30b.r7: pit_a30b_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r7",
    "package": "jdg.micro.pit",
    "priority": 60369,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a30b_exception", false) == true
}

# jdg.micro.pit.a30b.r8: pit_a30b_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r8",
    "package": "jdg.micro.pit",
    "priority": 60370,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a30b_exception_2", false) == true
}

# jdg.micro.pit.a30b.r9: pit_a30b_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r9",
    "package": "jdg.micro.pit",
    "priority": 60371,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a30b.r10: pit_a30b_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r10",
    "package": "jdg.micro.pit",
    "priority": 60372,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a30b.r11: pit_a30b_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r11",
    "package": "jdg.micro.pit",
    "priority": 60373,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a30b.r12: pit_a30b_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30b.r12",
    "package": "jdg.micro.pit",
    "priority": 60374,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Sprzedaż nieruchomości",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Sprzedaż nieruchomości: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30b_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a30c — Podatek liniowy 19% (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a30c.r1: pit_a30c_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r1",
    "package": "jdg.micro.pit",
    "priority": 60375,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a30c.r2: pit_a30c_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r2",
    "package": "jdg.micro.pit",
    "priority": 60376,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a30c.r3: pit_a30c_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r3",
    "package": "jdg.micro.pit",
    "priority": 60377,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30c_r3_pass", false) == true
}

# jdg.micro.pit.a30c.r4: pit_a30c_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r4",
    "package": "jdg.micro.pit",
    "priority": 60378,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30c_r4_checks", false) == true
}

# jdg.micro.pit.a30c.r5: pit_a30c_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r5",
    "package": "jdg.micro.pit",
    "priority": 60379,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a30c.r6: pit_a30c_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r6",
    "package": "jdg.micro.pit",
    "priority": 60380,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a30c.r7: pit_a30c_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r7",
    "package": "jdg.micro.pit",
    "priority": 60381,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a30c_exception", false) == true
}

# jdg.micro.pit.a30c.r8: pit_a30c_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r8",
    "package": "jdg.micro.pit",
    "priority": 60382,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a30c_exception_2", false) == true
}

# jdg.micro.pit.a30c.r9: pit_a30c_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r9",
    "package": "jdg.micro.pit",
    "priority": 60383,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a30c.r10: pit_a30c_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r10",
    "package": "jdg.micro.pit",
    "priority": 60384,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a30c.r11: pit_a30c_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r11",
    "package": "jdg.micro.pit",
    "priority": 60385,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a30c.r12: pit_a30c_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30c.r12",
    "package": "jdg.micro.pit",
    "priority": 60386,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Podatek liniowy 19%",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Podatek liniowy 19%: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30c_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a30ca — IP Box 5% (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a30ca.r1: pit_a30ca_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r1",
    "package": "jdg.micro.pit",
    "priority": 60387,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a30ca.r2: pit_a30ca_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r2",
    "package": "jdg.micro.pit",
    "priority": 60388,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a30ca.r3: pit_a30ca_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r3",
    "package": "jdg.micro.pit",
    "priority": 60389,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30ca_r3_pass", false) == true
}

# jdg.micro.pit.a30ca.r4: pit_a30ca_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r4",
    "package": "jdg.micro.pit",
    "priority": 60390,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30ca_r4_checks", false) == true
}

# jdg.micro.pit.a30ca.r5: pit_a30ca_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r5",
    "package": "jdg.micro.pit",
    "priority": 60391,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a30ca.r6: pit_a30ca_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r6",
    "package": "jdg.micro.pit",
    "priority": 60392,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a30ca.r7: pit_a30ca_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r7",
    "package": "jdg.micro.pit",
    "priority": 60393,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a30ca_exception", false) == true
}

# jdg.micro.pit.a30ca.r8: pit_a30ca_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r8",
    "package": "jdg.micro.pit",
    "priority": 60394,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a30ca_exception_2", false) == true
}

# jdg.micro.pit.a30ca.r9: pit_a30ca_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r9",
    "package": "jdg.micro.pit",
    "priority": 60395,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a30ca.r10: pit_a30ca_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r10",
    "package": "jdg.micro.pit",
    "priority": 60396,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a30ca.r11: pit_a30ca_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r11",
    "package": "jdg.micro.pit",
    "priority": 60397,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a30ca.r12: pit_a30ca_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30ca.r12",
    "package": "jdg.micro.pit",
    "priority": 60398,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.05",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie IP Box 5%",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] IP Box 5%: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30ca_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a30da — Exit Tax (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a30da.r1: pit_a30da_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r1",
    "package": "jdg.micro.pit",
    "priority": 60399,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a30da.r2: pit_a30da_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r2",
    "package": "jdg.micro.pit",
    "priority": 60400,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a30da.r3: pit_a30da_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r3",
    "package": "jdg.micro.pit",
    "priority": 60401,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30da_r3_pass", false) == true
}

# jdg.micro.pit.a30da.r4: pit_a30da_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r4",
    "package": "jdg.micro.pit",
    "priority": 60402,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30da_r4_checks", false) == true
}

# jdg.micro.pit.a30da.r5: pit_a30da_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r5",
    "package": "jdg.micro.pit",
    "priority": 60403,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a30da.r6: pit_a30da_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r6",
    "package": "jdg.micro.pit",
    "priority": 60404,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a30da.r7: pit_a30da_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r7",
    "package": "jdg.micro.pit",
    "priority": 60405,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a30da_exception", false) == true
}

# jdg.micro.pit.a30da.r8: pit_a30da_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r8",
    "package": "jdg.micro.pit",
    "priority": 60406,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a30da_exception_2", false) == true
}

# jdg.micro.pit.a30da.r9: pit_a30da_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r9",
    "package": "jdg.micro.pit",
    "priority": 60407,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a30da.r10: pit_a30da_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r10",
    "package": "jdg.micro.pit",
    "priority": 60408,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a30da.r11: pit_a30da_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r11",
    "package": "jdg.micro.pit",
    "priority": 60409,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a30da.r12: pit_a30da_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30da.r12",
    "package": "jdg.micro.pit",
    "priority": 60410,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.19",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Exit Tax",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Exit Tax: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30da_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a30f — CFC — zagraniczna spółka kontrolowana (15 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a30f.r1: pit_a30f_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r1",
    "package": "jdg.micro.pit",
    "priority": 60411,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a30f.r2: pit_a30f_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r2",
    "package": "jdg.micro.pit",
    "priority": 60412,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a30f.r3: pit_a30f_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r3",
    "package": "jdg.micro.pit",
    "priority": 60413,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30f_r3_pass", false) == true
}

# jdg.micro.pit.a30f.r4: pit_a30f_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r4",
    "package": "jdg.micro.pit",
    "priority": 60414,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30f_r4_checks", false) == true
}

# jdg.micro.pit.a30f.r5: pit_a30f_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r5",
    "package": "jdg.micro.pit",
    "priority": 60415,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a30f.r6: pit_a30f_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r6",
    "package": "jdg.micro.pit",
    "priority": 60416,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a30f.r7: pit_a30f_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r7",
    "package": "jdg.micro.pit",
    "priority": 60417,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a30f_exception", false) == true
}

# jdg.micro.pit.a30f.r8: pit_a30f_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r8",
    "package": "jdg.micro.pit",
    "priority": 60418,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a30f_exception_2", false) == true
}

# jdg.micro.pit.a30f.r9: pit_a30f_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r9",
    "package": "jdg.micro.pit",
    "priority": 60419,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a30f.r10: pit_a30f_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r10",
    "package": "jdg.micro.pit",
    "priority": 60420,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a30f.r11: pit_a30f_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r11",
    "package": "jdg.micro.pit",
    "priority": 60421,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a30f.r12: pit_a30f_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r12",
    "package": "jdg.micro.pit",
    "priority": 60422,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie CFC — zagraniczna spółka kontrolowana",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a30f_violation", false) == true
}

# jdg.micro.pit.a30f.r13: pit_a30f_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r13",
    "package": "jdg.micro.pit",
    "priority": 60423,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a30f_edge_case", false) == true
}

# jdg.micro.pit.a30f.r14: pit_a30f_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r14",
    "package": "jdg.micro.pit",
    "priority": 60424,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a30f_edge_case_2", false) == true
}

# jdg.micro.pit.a30f.r15: pit_a30f_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a30f.r15",
    "package": "jdg.micro.pit",
    "priority": 60425,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] CFC — zagraniczna spółka kontrolowana: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a31 — Zaliczki na podatek (25 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a31.r1: pit_a31_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r1",
    "package": "jdg.micro.pit",
    "priority": 60426,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a31.r2: pit_a31_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r2",
    "package": "jdg.micro.pit",
    "priority": 60427,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a31.r3: pit_a31_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r3",
    "package": "jdg.micro.pit",
    "priority": 60428,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a31_r3_pass", false) == true
}

# jdg.micro.pit.a31.r4: pit_a31_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r4",
    "package": "jdg.micro.pit",
    "priority": 60429,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a31_r4_checks", false) == true
}

# jdg.micro.pit.a31.r5: pit_a31_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r5",
    "package": "jdg.micro.pit",
    "priority": 60430,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a31.r6: pit_a31_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r6",
    "package": "jdg.micro.pit",
    "priority": 60431,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a31.r7: pit_a31_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r7",
    "package": "jdg.micro.pit",
    "priority": 60432,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a31_exception", false) == true
}

# jdg.micro.pit.a31.r8: pit_a31_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r8",
    "package": "jdg.micro.pit",
    "priority": 60433,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a31_exception_2", false) == true
}

# jdg.micro.pit.a31.r9: pit_a31_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r9",
    "package": "jdg.micro.pit",
    "priority": 60434,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a31.r10: pit_a31_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r10",
    "package": "jdg.micro.pit",
    "priority": 60435,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a31.r11: pit_a31_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r11",
    "package": "jdg.micro.pit",
    "priority": 60436,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a31.r12: pit_a31_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r12",
    "package": "jdg.micro.pit",
    "priority": 60437,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Zaliczki na podatek",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a31_violation", false) == true
}

# jdg.micro.pit.a31.r13: pit_a31_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r13",
    "package": "jdg.micro.pit",
    "priority": 60438,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a31_edge_case", false) == true
}

# jdg.micro.pit.a31.r14: pit_a31_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r14",
    "package": "jdg.micro.pit",
    "priority": 60439,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a31_edge_case_2", false) == true
}

# jdg.micro.pit.a31.r15: pit_a31_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r15",
    "package": "jdg.micro.pit",
    "priority": 60440,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# jdg.micro.pit.a31.r16: pit_a31_r16_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r16",
    "package": "jdg.micro.pit",
    "priority": 60441,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a31.r17: pit_a31_r17_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r17",
    "package": "jdg.micro.pit",
    "priority": 60442,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a31.r18: pit_a31_r18_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r18",
    "package": "jdg.micro.pit",
    "priority": 60443,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a31_r18_pass", false) == true
}

# jdg.micro.pit.a31.r19: pit_a31_r19_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r19",
    "package": "jdg.micro.pit",
    "priority": 60444,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a31_r19_checks", false) == true
}

# jdg.micro.pit.a31.r20: pit_a31_r20_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r20",
    "package": "jdg.micro.pit",
    "priority": 60445,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a31.r21: pit_a31_r21_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r21",
    "package": "jdg.micro.pit",
    "priority": 60446,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a31.r22: pit_a31_r22_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r22",
    "package": "jdg.micro.pit",
    "priority": 60447,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a31_exception", false) == true
}

# jdg.micro.pit.a31.r23: pit_a31_r23_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r23",
    "package": "jdg.micro.pit",
    "priority": 60448,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a31_exception_2", false) == true
}

# jdg.micro.pit.a31.r24: pit_a31_r24_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r24",
    "package": "jdg.micro.pit",
    "priority": 60449,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a31.r25: pit_a31_r25_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a31.r25",
    "package": "jdg.micro.pit",
    "priority": 60450,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki na podatek: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a44 — Zaliczki uproszczone (12 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a44.r1: pit_a44_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r1",
    "package": "jdg.micro.pit",
    "priority": 60451,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a44.r2: pit_a44_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r2",
    "package": "jdg.micro.pit",
    "priority": 60452,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a44.r3: pit_a44_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r3",
    "package": "jdg.micro.pit",
    "priority": 60453,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a44_r3_pass", false) == true
}

# jdg.micro.pit.a44.r4: pit_a44_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r4",
    "package": "jdg.micro.pit",
    "priority": 60454,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a44_r4_checks", false) == true
}

# jdg.micro.pit.a44.r5: pit_a44_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r5",
    "package": "jdg.micro.pit",
    "priority": 60455,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a44.r6: pit_a44_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r6",
    "package": "jdg.micro.pit",
    "priority": 60456,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a44.r7: pit_a44_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r7",
    "package": "jdg.micro.pit",
    "priority": 60457,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a44_exception", false) == true
}

# jdg.micro.pit.a44.r8: pit_a44_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r8",
    "package": "jdg.micro.pit",
    "priority": 60458,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a44_exception_2", false) == true
}

# jdg.micro.pit.a44.r9: pit_a44_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r9",
    "package": "jdg.micro.pit",
    "priority": 60459,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a44.r10: pit_a44_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r10",
    "package": "jdg.micro.pit",
    "priority": 60460,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a44.r11: pit_a44_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r11",
    "package": "jdg.micro.pit",
    "priority": 60461,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a44.r12: pit_a44_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a44.r12",
    "package": "jdg.micro.pit",
    "priority": 60462,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Zaliczki uproszczone",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zaliczki uproszczone: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a44_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a45 — Zeznania roczne (15 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a45.r1: pit_a45_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r1",
    "package": "jdg.micro.pit",
    "priority": 60463,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a45.r2: pit_a45_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r2",
    "package": "jdg.micro.pit",
    "priority": 60464,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a45.r3: pit_a45_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r3",
    "package": "jdg.micro.pit",
    "priority": 60465,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a45_r3_pass", false) == true
}

# jdg.micro.pit.a45.r4: pit_a45_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r4",
    "package": "jdg.micro.pit",
    "priority": 60466,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a45_r4_checks", false) == true
}

# jdg.micro.pit.a45.r5: pit_a45_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r5",
    "package": "jdg.micro.pit",
    "priority": 60467,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a45.r6: pit_a45_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r6",
    "package": "jdg.micro.pit",
    "priority": 60468,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a45.r7: pit_a45_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r7",
    "package": "jdg.micro.pit",
    "priority": 60469,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a45_exception", false) == true
}

# jdg.micro.pit.a45.r8: pit_a45_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r8",
    "package": "jdg.micro.pit",
    "priority": 60470,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a45_exception_2", false) == true
}

# jdg.micro.pit.a45.r9: pit_a45_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r9",
    "package": "jdg.micro.pit",
    "priority": 60471,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a45.r10: pit_a45_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r10",
    "package": "jdg.micro.pit",
    "priority": 60472,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a45.r11: pit_a45_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r11",
    "package": "jdg.micro.pit",
    "priority": 60473,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a45.r12: pit_a45_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r12",
    "package": "jdg.micro.pit",
    "priority": 60474,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Zeznania roczne",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a45_violation", false) == true
}

# jdg.micro.pit.a45.r13: pit_a45_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r13",
    "package": "jdg.micro.pit",
    "priority": 60475,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a45_edge_case", false) == true
}

# jdg.micro.pit.a45.r14: pit_a45_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r14",
    "package": "jdg.micro.pit",
    "priority": 60476,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a45_edge_case_2", false) == true
}

# jdg.micro.pit.a45.r15: pit_a45_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45.r15",
    "package": "jdg.micro.pit",
    "priority": 60477,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Zeznania roczne: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a45a — Informacje PIT-11, IFT (15 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a45a.r1: pit_a45a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r1",
    "package": "jdg.micro.pit",
    "priority": 60478,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a45a.r2: pit_a45a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r2",
    "package": "jdg.micro.pit",
    "priority": 60479,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a45a.r3: pit_a45a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r3",
    "package": "jdg.micro.pit",
    "priority": 60480,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a45a_r3_pass", false) == true
}

# jdg.micro.pit.a45a.r4: pit_a45a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r4",
    "package": "jdg.micro.pit",
    "priority": 60481,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a45a_r4_checks", false) == true
}

# jdg.micro.pit.a45a.r5: pit_a45a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r5",
    "package": "jdg.micro.pit",
    "priority": 60482,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a45a.r6: pit_a45a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r6",
    "package": "jdg.micro.pit",
    "priority": 60483,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a45a.r7: pit_a45a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r7",
    "package": "jdg.micro.pit",
    "priority": 60484,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a45a_exception", false) == true
}

# jdg.micro.pit.a45a.r8: pit_a45a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r8",
    "package": "jdg.micro.pit",
    "priority": 60485,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a45a_exception_2", false) == true
}

# jdg.micro.pit.a45a.r9: pit_a45a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r9",
    "package": "jdg.micro.pit",
    "priority": 60486,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a45a.r10: pit_a45a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r10",
    "package": "jdg.micro.pit",
    "priority": 60487,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# jdg.micro.pit.a45a.r11: pit_a45a_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r11",
    "package": "jdg.micro.pit",
    "priority": 60488,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pit_deadline_required", false) == true
}

# jdg.micro.pit.a45a.r12: pit_a45a_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r12",
    "package": "jdg.micro.pit",
    "priority": 60489,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Informacje PIT-11, IFT",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pit_a45a_violation", false) == true
}

# jdg.micro.pit.a45a.r13: pit_a45a_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r13",
    "package": "jdg.micro.pit",
    "priority": 60490,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "pit_a45a_edge_case", false) == true
}

# jdg.micro.pit.a45a.r14: pit_a45a_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r14",
    "package": "jdg.micro.pit",
    "priority": 60491,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "pit_a45a_edge_case_2", false) == true
}

# jdg.micro.pit.a45a.r15: pit_a45a_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a45a.r15",
    "package": "jdg.micro.pit",
    "priority": 60492,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Informacje PIT-11, IFT: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "pit_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a21b — Ulga dla młodych PIT-0 (10 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a21b.r1: pit_a21b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r1",
    "package": "jdg.micro.pit",
    "priority": 60493,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a21b.r2: pit_a21b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r2",
    "package": "jdg.micro.pit",
    "priority": 60494,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a21b.r3: pit_a21b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r3",
    "package": "jdg.micro.pit",
    "priority": 60495,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21b_r3_pass", false) == true
}

# jdg.micro.pit.a21b.r4: pit_a21b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r4",
    "package": "jdg.micro.pit",
    "priority": 60496,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21b_r4_checks", false) == true
}

# jdg.micro.pit.a21b.r5: pit_a21b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r5",
    "package": "jdg.micro.pit",
    "priority": 60497,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a21b.r6: pit_a21b_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r6",
    "package": "jdg.micro.pit",
    "priority": 60498,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a21b.r7: pit_a21b_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r7",
    "package": "jdg.micro.pit",
    "priority": 60499,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a21b_exception", false) == true
}

# jdg.micro.pit.a21b.r8: pit_a21b_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r8",
    "package": "jdg.micro.pit",
    "priority": 60500,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a21b_exception_2", false) == true
}

# jdg.micro.pit.a21b.r9: pit_a21b_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r9",
    "package": "jdg.micro.pit",
    "priority": 60501,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pit", false) == true
}

# jdg.micro.pit.a21b.r10: pit_a21b_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21b.r10",
    "package": "jdg.micro.pit",
    "priority": 60502,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla młodych PIT-0: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pit", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a21c — Ulga na powrót (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a21c.r1: pit_a21c_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21c.r1",
    "package": "jdg.micro.pit",
    "priority": 60503,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na powrót: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a21c.r2: pit_a21c_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21c.r2",
    "package": "jdg.micro.pit",
    "priority": 60504,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na powrót: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a21c.r3: pit_a21c_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21c.r3",
    "package": "jdg.micro.pit",
    "priority": 60505,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na powrót: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21c_r3_pass", false) == true
}

# jdg.micro.pit.a21c.r4: pit_a21c_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21c.r4",
    "package": "jdg.micro.pit",
    "priority": 60506,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na powrót: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21c_r4_checks", false) == true
}

# jdg.micro.pit.a21c.r5: pit_a21c_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21c.r5",
    "package": "jdg.micro.pit",
    "priority": 60507,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na powrót: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a21c.r6: pit_a21c_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21c.r6",
    "package": "jdg.micro.pit",
    "priority": 60508,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na powrót: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a21c.r7: pit_a21c_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21c.r7",
    "package": "jdg.micro.pit",
    "priority": 60509,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na powrót: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a21c_exception", false) == true
}

# jdg.micro.pit.a21c.r8: pit_a21c_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21c.r8",
    "package": "jdg.micro.pit",
    "priority": 60510,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga na powrót: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a21c_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a21d — Ulga dla rodzin 4+ (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a21d.r1: pit_a21d_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21d.r1",
    "package": "jdg.micro.pit",
    "priority": 60511,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla rodzin 4+: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a21d.r2: pit_a21d_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21d.r2",
    "package": "jdg.micro.pit",
    "priority": 60512,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla rodzin 4+: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a21d.r3: pit_a21d_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21d.r3",
    "package": "jdg.micro.pit",
    "priority": 60513,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla rodzin 4+: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21d_r3_pass", false) == true
}

# jdg.micro.pit.a21d.r4: pit_a21d_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21d.r4",
    "package": "jdg.micro.pit",
    "priority": 60514,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla rodzin 4+: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21d_r4_checks", false) == true
}

# jdg.micro.pit.a21d.r5: pit_a21d_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21d.r5",
    "package": "jdg.micro.pit",
    "priority": 60515,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla rodzin 4+: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a21d.r6: pit_a21d_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21d.r6",
    "package": "jdg.micro.pit",
    "priority": 60516,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla rodzin 4+: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a21d.r7: pit_a21d_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21d.r7",
    "package": "jdg.micro.pit",
    "priority": 60517,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla rodzin 4+: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a21d_exception", false) == true
}

# jdg.micro.pit.a21d.r8: pit_a21d_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21d.r8",
    "package": "jdg.micro.pit",
    "priority": 60518,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla rodzin 4+: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a21d_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a21e — Ulga dla pracujących emerytów (8 reguł)                                    ║
# ║  Legal basis: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pit.a21e.r1: pit_a21e_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21e.r1",
    "package": "jdg.micro.pit",
    "priority": 60519,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla pracujących emerytów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pit.a21e.r2: pit_a21e_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21e.r2",
    "package": "jdg.micro.pit",
    "priority": 60520,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla pracujących emerytów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pit_condition_met", false) == true
}

# jdg.micro.pit.a21e.r3: pit_a21e_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21e.r3",
    "package": "jdg.micro.pit",
    "priority": 60521,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla pracujących emerytów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21e_r3_pass", false) == true
}

# jdg.micro.pit.a21e.r4: pit_a21e_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21e.r4",
    "package": "jdg.micro.pit",
    "priority": 60522,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla pracujących emerytów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pit_a21e_r4_checks", false) == true
}

# jdg.micro.pit.a21e.r5: pit_a21e_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21e.r5",
    "package": "jdg.micro.pit",
    "priority": 60523,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla pracujących emerytów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pit_exclusion_applies", false) == false
}

# jdg.micro.pit.a21e.r6: pit_a21e_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21e.r6",
    "package": "jdg.micro.pit",
    "priority": 60524,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla pracujących emerytów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pit_exclusion_2", false) == false
}

# jdg.micro.pit.a21e.r7: pit_a21e_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21e.r7",
    "package": "jdg.micro.pit",
    "priority": 60525,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla pracujących emerytów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pit_a21e_exception", false) == true
}

# jdg.micro.pit.a21e.r8: pit_a21e_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pit.a21e.r8",
    "package": "jdg.micro.pit",
    "priority": 60526,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Ulga dla pracujących emerytów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pit_a21e_exception_2", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (290 reguł)       ║
# ║  Priorytety: 50000-50289                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.pit.a100.u1.p1 — `pit_a100_u1_p1`: Art. 100 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a100.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50000,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 100 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 100: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a100_u1_p1_check", false) == true
}
# jdg.pit.a100.u2.p2 — `pit_a100_u2_p2`: Art. 100 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a100.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50001,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 100 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 100: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a100_u2_p2_check", false) == true
}
# jdg.pit.a100.u3.p3 — `pit_a100_u3_p3`: Art. 100 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a100.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50002,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 100 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 100: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a100_u3_p3_check", false) == true
}
# jdg.pit.a100.u5.p4 — `pit_a100_u5_p4`: Art. 100 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a100.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50003,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 100 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 100: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a100_u5_p4_check", false) == true
}
# jdg.pit.a101.u1.p2 — `pit_a101_u1_p2`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a101.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50004,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a101_u1_p2_check", false) == true
}
# jdg.pit.a101.u2.p3 — `pit_a101_u2_p3`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a101.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50005,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a101_u2_p3_check", false) == true
}
# jdg.pit.a101.u4.p4 — `pit_a101_u4_p4`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a101.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50006,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a101_u4_p4_check", false) == true
}
# jdg.pit.a101.u5.p1 — `pit_a101_u5_p1`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a101.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50007,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a101_u5_p1_check", false) == true
}
# jdg.pit.a102.u3.p4 — `pit_a102_u3_p4`: Art. 102 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a102.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50008,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 102 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 102: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a102_u3_p4_check", false) == true
}
# jdg.pit.a22p.r1 — `pit_a22p_r1`: Art. 22p → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a22p.r1",
    "package": "jdg.micro.pit",
    "priority": 50009,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 22p — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 22p: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a22p_r1_check", false) == true
}
# jdg.pit.a30.u1.p1 — `pit_a30_u1_p1`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a30.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50010,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a30_u1_p1_check", false) == true
}
# jdg.pit.a30.u2.p2 — `pit_a30_u2_p2`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a30.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50011,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a30_u2_p2_check", false) == true
}
# jdg.pit.a30.u3.p3 — `pit_a30_u3_p3`: Art. 30 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a30.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50012,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 30 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 30: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a30_u3_p3_check", false) == true
}
# jdg.pit.a31.u1.p2 — `pit_a31_u1_p2`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a31.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50013,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a31_u1_p2_check", false) == true
}
# jdg.pit.a31.u2.p3 — `pit_a31_u2_p3`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a31.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50014,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a31_u2_p3_check", false) == true
}
# jdg.pit.a31.u4.p4 — `pit_a31_u4_p4`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a31.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50015,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a31_u4_p4_check", false) == true
}
# jdg.pit.a31.u5.p1 — `pit_a31_u5_p1`: Art. 31 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a31.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50016,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 31 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 31: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a31_u5_p1_check", false) == true
}
# jdg.pit.a32.u1.p3 — `pit_a32_u1_p3`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a32.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50017,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a32_u1_p3_check", false) == true
}
# jdg.pit.a32.u3.p4 — `pit_a32_u3_p4`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a32.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50018,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a32_u3_p4_check", false) == true
}
# jdg.pit.a32.u4.p1 — `pit_a32_u4_p1`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a32.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50019,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a32_u4_p1_check", false) == true
}
# jdg.pit.a32.u5.p2 — `pit_a32_u5_p2`: Art. 32 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a32.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50020,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 32 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 32: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a32_u5_p2_check", false) == true
}
# jdg.pit.a33.u2.p4 — `pit_a33_u2_p4`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a33.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50021,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a33_u2_p4_check", false) == true
}
# jdg.pit.a33.u3.p1 — `pit_a33_u3_p1`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a33.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50022,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a33_u3_p1_check", false) == true
}
# jdg.pit.a33.u4.p2 — `pit_a33_u4_p2`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a33.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50023,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a33_u4_p2_check", false) == true
}
# jdg.pit.a33.u5.p3 — `pit_a33_u5_p3`: Art. 33 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a33.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50024,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 33 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 33: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a33_u5_p3_check", false) == true
}
# jdg.pit.a34.u1.p4 — `pit_a34_u1_p4`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a34.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50025,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a34_u1_p4_check", false) == true
}
# jdg.pit.a34.u2.p1 — `pit_a34_u2_p1`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a34.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50026,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a34_u2_p1_check", false) == true
}
# jdg.pit.a34.u3.p2 — `pit_a34_u3_p2`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a34.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50027,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a34_u3_p2_check", false) == true
}
# jdg.pit.a34.u4.p3 — `pit_a34_u4_p3`: Art. 34 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a34.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50028,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 34 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 34: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a34_u4_p3_check", false) == true
}
# jdg.pit.a35.u1.p1 — `pit_a35_u1_p1`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a35.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50029,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a35_u1_p1_check", false) == true
}
# jdg.pit.a35.u2.p2 — `pit_a35_u2_p2`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a35.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50030,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a35_u2_p2_check", false) == true
}
# jdg.pit.a35.u3.p3 — `pit_a35_u3_p3`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a35.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50031,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a35_u3_p3_check", false) == true
}
# jdg.pit.a35.u5.p4 — `pit_a35_u5_p4`: Art. 35 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a35.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50032,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 35 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 35: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a35_u5_p4_check", false) == true
}
# jdg.pit.a36.u1.p2 — `pit_a36_u1_p2`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a36.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50033,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a36_u1_p2_check", false) == true
}
# jdg.pit.a36.u2.p3 — `pit_a36_u2_p3`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a36.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50034,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a36_u2_p3_check", false) == true
}
# jdg.pit.a36.u4.p4 — `pit_a36_u4_p4`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a36.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50035,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a36_u4_p4_check", false) == true
}
# jdg.pit.a36.u5.p1 — `pit_a36_u5_p1`: Art. 36 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a36.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50036,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 36 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 36: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a36_u5_p1_check", false) == true
}
# jdg.pit.a37.u1.p3 — `pit_a37_u1_p3`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a37.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50037,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a37_u1_p3_check", false) == true
}
# jdg.pit.a37.u3.p4 — `pit_a37_u3_p4`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a37.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50038,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a37_u3_p4_check", false) == true
}
# jdg.pit.a37.u4.p1 — `pit_a37_u4_p1`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a37.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50039,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a37_u4_p1_check", false) == true
}
# jdg.pit.a37.u5.p2 — `pit_a37_u5_p2`: Art. 37 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a37.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50040,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 37 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 37: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a37_u5_p2_check", false) == true
}
# jdg.pit.a38.u2.p4 — `pit_a38_u2_p4`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a38.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50041,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a38_u2_p4_check", false) == true
}
# jdg.pit.a38.u3.p1 — `pit_a38_u3_p1`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a38.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50042,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a38_u3_p1_check", false) == true
}
# jdg.pit.a38.u4.p2 — `pit_a38_u4_p2`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a38.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50043,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a38_u4_p2_check", false) == true
}
# jdg.pit.a38.u5.p3 — `pit_a38_u5_p3`: Art. 38 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a38.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50044,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 38 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 38: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a38_u5_p3_check", false) == true
}
# jdg.pit.a39.u1.p4 — `pit_a39_u1_p4`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a39.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50045,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a39_u1_p4_check", false) == true
}
# jdg.pit.a39.u2.p1 — `pit_a39_u2_p1`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a39.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50046,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a39_u2_p1_check", false) == true
}
# jdg.pit.a39.u3.p2 — `pit_a39_u3_p2`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a39.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50047,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a39_u3_p2_check", false) == true
}
# jdg.pit.a39.u4.p3 — `pit_a39_u4_p3`: Art. 39 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a39.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50048,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 39 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 39: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a39_u4_p3_check", false) == true
}
# jdg.pit.a40.u1.p1 — `pit_a40_u1_p1`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a40.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50049,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a40_u1_p1_check", false) == true
}
# jdg.pit.a40.u2.p2 — `pit_a40_u2_p2`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a40.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50050,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a40_u2_p2_check", false) == true
}
# jdg.pit.a40.u3.p3 — `pit_a40_u3_p3`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a40.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50051,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a40_u3_p3_check", false) == true
}
# jdg.pit.a40.u5.p4 — `pit_a40_u5_p4`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a40.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50052,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a40_u5_p4_check", false) == true
}
# jdg.pit.a41.u1.p2 — `pit_a41_u1_p2`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a41.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50053,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a41_u1_p2_check", false) == true
}
# jdg.pit.a41.u2.p3 — `pit_a41_u2_p3`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a41.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50054,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a41_u2_p3_check", false) == true
}
# jdg.pit.a41.u4.p4 — `pit_a41_u4_p4`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a41.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50055,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a41_u4_p4_check", false) == true
}
# jdg.pit.a41.u5.p1 — `pit_a41_u5_p1`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a41.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50056,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a41_u5_p1_check", false) == true
}
# jdg.pit.a42.u1.p3 — `pit_a42_u1_p3`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a42.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50057,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a42_u1_p3_check", false) == true
}
# jdg.pit.a42.u3.p4 — `pit_a42_u3_p4`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a42.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50058,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a42_u3_p4_check", false) == true
}
# jdg.pit.a42.u4.p1 — `pit_a42_u4_p1`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a42.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50059,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a42_u4_p1_check", false) == true
}
# jdg.pit.a42.u5.p2 — `pit_a42_u5_p2`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a42.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50060,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a42_u5_p2_check", false) == true
}
# jdg.pit.a43.u2.p4 — `pit_a43_u2_p4`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a43.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50061,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a43_u2_p4_check", false) == true
}
# jdg.pit.a43.u3.p1 — `pit_a43_u3_p1`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a43.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50062,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a43_u3_p1_check", false) == true
}
# jdg.pit.a43.u4.p2 — `pit_a43_u4_p2`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a43.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50063,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a43_u4_p2_check", false) == true
}
# jdg.pit.a43.u5.p3 — `pit_a43_u5_p3`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a43.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50064,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a43_u5_p3_check", false) == true
}
# jdg.pit.a44.u1.p4 — `pit_a44_u1_p4`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a44.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50065,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a44_u1_p4_check", false) == true
}
# jdg.pit.a44.u2.p1 — `pit_a44_u2_p1`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a44.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50066,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a44_u2_p1_check", false) == true
}
# jdg.pit.a44.u3.p2 — `pit_a44_u3_p2`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a44.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50067,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a44_u3_p2_check", false) == true
}
# jdg.pit.a44.u4.p3 — `pit_a44_u4_p3`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a44.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50068,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a44_u4_p3_check", false) == true
}
# jdg.pit.a45.u1.p1 — `pit_a45_u1_p1`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a45.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50069,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a45_u1_p1_check", false) == true
}
# jdg.pit.a45.u2.p2 — `pit_a45_u2_p2`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a45.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50070,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a45_u2_p2_check", false) == true
}
# jdg.pit.a45.u3.p3 — `pit_a45_u3_p3`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a45.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50071,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a45_u3_p3_check", false) == true
}
# jdg.pit.a45.u5.p4 — `pit_a45_u5_p4`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a45.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50072,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a45_u5_p4_check", false) == true
}
# jdg.pit.a46.u1.p2 — `pit_a46_u1_p2`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a46.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50073,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a46_u1_p2_check", false) == true
}
# jdg.pit.a46.u2.p3 — `pit_a46_u2_p3`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a46.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50074,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a46_u2_p3_check", false) == true
}
# jdg.pit.a46.u4.p4 — `pit_a46_u4_p4`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a46.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50075,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a46_u4_p4_check", false) == true
}
# jdg.pit.a46.u5.p1 — `pit_a46_u5_p1`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a46.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50076,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a46_u5_p1_check", false) == true
}
# jdg.pit.a47.u1.p3 — `pit_a47_u1_p3`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a47.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50077,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a47_u1_p3_check", false) == true
}
# jdg.pit.a47.u3.p4 — `pit_a47_u3_p4`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a47.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50078,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a47_u3_p4_check", false) == true
}
# jdg.pit.a47.u4.p1 — `pit_a47_u4_p1`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a47.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50079,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a47_u4_p1_check", false) == true
}
# jdg.pit.a47.u5.p2 — `pit_a47_u5_p2`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a47.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50080,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a47_u5_p2_check", false) == true
}
# jdg.pit.a48.u2.p4 — `pit_a48_u2_p4`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a48.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50081,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a48_u2_p4_check", false) == true
}
# jdg.pit.a48.u3.p1 — `pit_a48_u3_p1`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a48.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50082,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a48_u3_p1_check", false) == true
}
# jdg.pit.a48.u4.p2 — `pit_a48_u4_p2`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a48.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50083,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a48_u4_p2_check", false) == true
}
# jdg.pit.a48.u5.p3 — `pit_a48_u5_p3`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a48.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50084,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a48_u5_p3_check", false) == true
}
# jdg.pit.a49.u1.p4 — `pit_a49_u1_p4`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a49.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50085,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a49_u1_p4_check", false) == true
}
# jdg.pit.a49.u2.p1 — `pit_a49_u2_p1`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a49.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50086,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a49_u2_p1_check", false) == true
}
# jdg.pit.a49.u3.p2 — `pit_a49_u3_p2`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a49.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50087,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a49_u3_p2_check", false) == true
}
# jdg.pit.a49.u4.p3 — `pit_a49_u4_p3`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a49.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50088,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a49_u4_p3_check", false) == true
}
# jdg.pit.a50.u1.p1 — `pit_a50_u1_p1`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a50.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50089,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a50_u1_p1_check", false) == true
}
# jdg.pit.a50.u2.p2 — `pit_a50_u2_p2`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a50.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50090,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a50_u2_p2_check", false) == true
}
# jdg.pit.a50.u3.p3 — `pit_a50_u3_p3`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a50.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50091,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a50_u3_p3_check", false) == true
}
# jdg.pit.a50.u5.p4 — `pit_a50_u5_p4`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a50.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50092,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a50_u5_p4_check", false) == true
}
# jdg.pit.a51.u1.p2 — `pit_a51_u1_p2`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a51.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50093,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a51_u1_p2_check", false) == true
}
# jdg.pit.a51.u2.p3 — `pit_a51_u2_p3`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a51.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50094,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a51_u2_p3_check", false) == true
}
# jdg.pit.a51.u4.p4 — `pit_a51_u4_p4`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a51.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50095,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a51_u4_p4_check", false) == true
}
# jdg.pit.a51.u5.p1 — `pit_a51_u5_p1`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a51.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50096,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a51_u5_p1_check", false) == true
}
# jdg.pit.a52.u1.p3 — `pit_a52_u1_p3`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a52.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50097,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a52_u1_p3_check", false) == true
}
# jdg.pit.a52.u3.p4 — `pit_a52_u3_p4`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a52.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50098,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a52_u3_p4_check", false) == true
}
# jdg.pit.a52.u4.p1 — `pit_a52_u4_p1`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a52.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50099,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a52_u4_p1_check", false) == true
}
# jdg.pit.a52.u5.p2 — `pit_a52_u5_p2`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a52.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50100,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a52_u5_p2_check", false) == true
}
# jdg.pit.a53.u2.p4 — `pit_a53_u2_p4`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a53.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50101,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a53_u2_p4_check", false) == true
}
# jdg.pit.a53.u3.p1 — `pit_a53_u3_p1`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a53.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50102,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a53_u3_p1_check", false) == true
}
# jdg.pit.a53.u4.p2 — `pit_a53_u4_p2`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a53.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50103,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a53_u4_p2_check", false) == true
}
# jdg.pit.a53.u5.p3 — `pit_a53_u5_p3`: Art. 53 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a53.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50104,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 53 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 53: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a53_u5_p3_check", false) == true
}
# jdg.pit.a54.u1.p4 — `pit_a54_u1_p4`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a54.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50105,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a54_u1_p4_check", false) == true
}
# jdg.pit.a54.u2.p1 — `pit_a54_u2_p1`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a54.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50106,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a54_u2_p1_check", false) == true
}
# jdg.pit.a54.u3.p2 — `pit_a54_u3_p2`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a54.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50107,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a54_u3_p2_check", false) == true
}
# jdg.pit.a54.u4.p3 — `pit_a54_u4_p3`: Art. 54 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a54.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50108,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 54 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 54: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a54_u4_p3_check", false) == true
}
# jdg.pit.a55.u1.p1 — `pit_a55_u1_p1`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a55.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50109,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a55_u1_p1_check", false) == true
}
# jdg.pit.a55.u2.p2 — `pit_a55_u2_p2`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a55.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50110,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a55_u2_p2_check", false) == true
}
# jdg.pit.a55.u3.p3 — `pit_a55_u3_p3`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a55.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50111,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a55_u3_p3_check", false) == true
}
# jdg.pit.a55.u5.p4 — `pit_a55_u5_p4`: Art. 55 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a55.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50112,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 55 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 55: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a55_u5_p4_check", false) == true
}
# jdg.pit.a56.u1.p2 — `pit_a56_u1_p2`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a56.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50113,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a56_u1_p2_check", false) == true
}
# jdg.pit.a56.u2.p3 — `pit_a56_u2_p3`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a56.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50114,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a56_u2_p3_check", false) == true
}
# jdg.pit.a56.u4.p4 — `pit_a56_u4_p4`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a56.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50115,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a56_u4_p4_check", false) == true
}
# jdg.pit.a56.u5.p1 — `pit_a56_u5_p1`: Art. 56 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a56.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50116,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 56 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 56: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a56_u5_p1_check", false) == true
}
# jdg.pit.a57.u1.p3 — `pit_a57_u1_p3`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a57.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50117,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a57_u1_p3_check", false) == true
}
# jdg.pit.a57.u3.p4 — `pit_a57_u3_p4`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a57.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50118,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a57_u3_p4_check", false) == true
}
# jdg.pit.a57.u4.p1 — `pit_a57_u4_p1`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a57.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50119,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a57_u4_p1_check", false) == true
}
# jdg.pit.a57.u5.p2 — `pit_a57_u5_p2`: Art. 57 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a57.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50120,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 57 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 57: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a57_u5_p2_check", false) == true
}
# jdg.pit.a58.u2.p4 — `pit_a58_u2_p4`: Art. 58 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a58.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50121,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 58 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 58: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a58_u2_p4_check", false) == true
}
# jdg.pit.a58.u3.p1 — `pit_a58_u3_p1`: Art. 58 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a58.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50122,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 58 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 58: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a58_u3_p1_check", false) == true
}
# jdg.pit.a58.u4.p2 — `pit_a58_u4_p2`: Art. 58 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a58.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50123,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 58 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 58: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a58_u4_p2_check", false) == true
}
# jdg.pit.a58.u5.p3 — `pit_a58_u5_p3`: Art. 58 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a58.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50124,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 58 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 58: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a58_u5_p3_check", false) == true
}
# jdg.pit.a59.u1.p4 — `pit_a59_u1_p4`: Art. 59 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a59.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50125,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 59 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 59: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a59_u1_p4_check", false) == true
}
# jdg.pit.a59.u2.p1 — `pit_a59_u2_p1`: Art. 59 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a59.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50126,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 59 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 59: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a59_u2_p1_check", false) == true
}
# jdg.pit.a59.u3.p2 — `pit_a59_u3_p2`: Art. 59 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a59.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50127,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 59 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 59: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a59_u3_p2_check", false) == true
}
# jdg.pit.a59.u4.p3 — `pit_a59_u4_p3`: Art. 59 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a59.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50128,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 59 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 59: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a59_u4_p3_check", false) == true
}
# jdg.pit.a60.u1.p1 — `pit_a60_u1_p1`: Art. 60 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a60.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50129,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 60 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 60: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a60_u1_p1_check", false) == true
}
# jdg.pit.a60.u2.p2 — `pit_a60_u2_p2`: Art. 60 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a60.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50130,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 60 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 60: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a60_u2_p2_check", false) == true
}
# jdg.pit.a60.u3.p3 — `pit_a60_u3_p3`: Art. 60 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a60.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50131,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 60 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 60: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a60_u3_p3_check", false) == true
}
# jdg.pit.a60.u5.p4 — `pit_a60_u5_p4`: Art. 60 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a60.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50132,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 60 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 60: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a60_u5_p4_check", false) == true
}
# jdg.pit.a61.u1.p2 — `pit_a61_u1_p2`: Art. 61 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a61.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50133,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 61 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 61: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a61_u1_p2_check", false) == true
}
# jdg.pit.a61.u2.p3 — `pit_a61_u2_p3`: Art. 61 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a61.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50134,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 61 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 61: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a61_u2_p3_check", false) == true
}
# jdg.pit.a61.u4.p4 — `pit_a61_u4_p4`: Art. 61 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a61.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50135,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 61 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 61: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a61_u4_p4_check", false) == true
}
# jdg.pit.a61.u5.p1 — `pit_a61_u5_p1`: Art. 61 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a61.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50136,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 61 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 61: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a61_u5_p1_check", false) == true
}
# jdg.pit.a62.u1.p3 — `pit_a62_u1_p3`: Art. 62 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a62.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50137,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 62 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 62: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a62_u1_p3_check", false) == true
}
# jdg.pit.a62.u3.p4 — `pit_a62_u3_p4`: Art. 62 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a62.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50138,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 62 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 62: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a62_u3_p4_check", false) == true
}
# jdg.pit.a62.u4.p1 — `pit_a62_u4_p1`: Art. 62 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a62.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50139,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 62 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 62: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a62_u4_p1_check", false) == true
}
# jdg.pit.a62.u5.p2 — `pit_a62_u5_p2`: Art. 62 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a62.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50140,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 62 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 62: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a62_u5_p2_check", false) == true
}
# jdg.pit.a63.u2.p4 — `pit_a63_u2_p4`: Art. 63 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a63.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50141,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 63 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 63: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a63_u2_p4_check", false) == true
}
# jdg.pit.a63.u3.p1 — `pit_a63_u3_p1`: Art. 63 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a63.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50142,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 63 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 63: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a63_u3_p1_check", false) == true
}
# jdg.pit.a63.u4.p2 — `pit_a63_u4_p2`: Art. 63 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a63.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50143,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 63 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 63: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a63_u4_p2_check", false) == true
}
# jdg.pit.a63.u5.p3 — `pit_a63_u5_p3`: Art. 63 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a63.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50144,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 63 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 63: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a63_u5_p3_check", false) == true
}
# jdg.pit.a64.u1.p4 — `pit_a64_u1_p4`: Art. 64 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a64.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50145,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 64 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 64: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a64_u1_p4_check", false) == true
}
# jdg.pit.a64.u2.p1 — `pit_a64_u2_p1`: Art. 64 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a64.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50146,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 64 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 64: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a64_u2_p1_check", false) == true
}
# jdg.pit.a64.u3.p2 — `pit_a64_u3_p2`: Art. 64 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a64.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50147,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 64 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 64: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a64_u3_p2_check", false) == true
}
# jdg.pit.a64.u4.p3 — `pit_a64_u4_p3`: Art. 64 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a64.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50148,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 64 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 64: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a64_u4_p3_check", false) == true
}
# jdg.pit.a65.u1.p1 — `pit_a65_u1_p1`: Art. 65 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a65.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50149,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 65 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 65: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a65_u1_p1_check", false) == true
}
# jdg.pit.a65.u2.p2 — `pit_a65_u2_p2`: Art. 65 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a65.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50150,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 65 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 65: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a65_u2_p2_check", false) == true
}
# jdg.pit.a65.u3.p3 — `pit_a65_u3_p3`: Art. 65 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a65.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50151,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 65 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 65: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a65_u3_p3_check", false) == true
}
# jdg.pit.a65.u5.p4 — `pit_a65_u5_p4`: Art. 65 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a65.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50152,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 65 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 65: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a65_u5_p4_check", false) == true
}
# jdg.pit.a66.u1.p2 — `pit_a66_u1_p2`: Art. 66 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a66.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50153,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 66 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 66: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a66_u1_p2_check", false) == true
}
# jdg.pit.a66.u2.p3 — `pit_a66_u2_p3`: Art. 66 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a66.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50154,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 66 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 66: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a66_u2_p3_check", false) == true
}
# jdg.pit.a66.u4.p4 — `pit_a66_u4_p4`: Art. 66 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a66.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50155,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 66 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 66: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a66_u4_p4_check", false) == true
}
# jdg.pit.a66.u5.p1 — `pit_a66_u5_p1`: Art. 66 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a66.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50156,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 66 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 66: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a66_u5_p1_check", false) == true
}
# jdg.pit.a67.u1.p3 — `pit_a67_u1_p3`: Art. 67 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a67.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50157,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 67 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 67: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a67_u1_p3_check", false) == true
}
# jdg.pit.a67.u3.p4 — `pit_a67_u3_p4`: Art. 67 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a67.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50158,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 67 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 67: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a67_u3_p4_check", false) == true
}
# jdg.pit.a67.u4.p1 — `pit_a67_u4_p1`: Art. 67 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a67.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50159,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 67 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 67: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a67_u4_p1_check", false) == true
}
# jdg.pit.a67.u5.p2 — `pit_a67_u5_p2`: Art. 67 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a67.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50160,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 67 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 67: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a67_u5_p2_check", false) == true
}
# jdg.pit.a68.u2.p4 — `pit_a68_u2_p4`: Art. 68 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a68.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50161,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 68 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 68: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a68_u2_p4_check", false) == true
}
# jdg.pit.a68.u3.p1 — `pit_a68_u3_p1`: Art. 68 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a68.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50162,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 68 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 68: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a68_u3_p1_check", false) == true
}
# jdg.pit.a68.u4.p2 — `pit_a68_u4_p2`: Art. 68 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a68.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50163,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 68 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 68: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a68_u4_p2_check", false) == true
}
# jdg.pit.a68.u5.p3 — `pit_a68_u5_p3`: Art. 68 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a68.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50164,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 68 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 68: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a68_u5_p3_check", false) == true
}
# jdg.pit.a69.u1.p4 — `pit_a69_u1_p4`: Art. 69 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a69.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50165,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 69 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 69: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a69_u1_p4_check", false) == true
}
# jdg.pit.a69.u2.p1 — `pit_a69_u2_p1`: Art. 69 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a69.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50166,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 69 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 69: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a69_u2_p1_check", false) == true
}
# jdg.pit.a69.u3.p2 — `pit_a69_u3_p2`: Art. 69 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a69.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50167,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 69 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 69: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a69_u3_p2_check", false) == true
}
# jdg.pit.a69.u4.p3 — `pit_a69_u4_p3`: Art. 69 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a69.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50168,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 69 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 69: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a69_u4_p3_check", false) == true
}
# jdg.pit.a70.u1.p1 — `pit_a70_u1_p1`: Art. 70 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a70.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50169,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 70 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 70: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a70_u1_p1_check", false) == true
}
# jdg.pit.a70.u2.p2 — `pit_a70_u2_p2`: Art. 70 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a70.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50170,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 70 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 70: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a70_u2_p2_check", false) == true
}
# jdg.pit.a70.u3.p3 — `pit_a70_u3_p3`: Art. 70 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a70.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50171,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 70 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 70: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a70_u3_p3_check", false) == true
}
# jdg.pit.a70.u5.p4 — `pit_a70_u5_p4`: Art. 70 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a70.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50172,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 70 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 70: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a70_u5_p4_check", false) == true
}
# jdg.pit.a71.u1.p2 — `pit_a71_u1_p2`: Art. 71 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a71.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50173,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 71 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 71: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a71_u1_p2_check", false) == true
}
# jdg.pit.a71.u2.p3 — `pit_a71_u2_p3`: Art. 71 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a71.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50174,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 71 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 71: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a71_u2_p3_check", false) == true
}
# jdg.pit.a71.u4.p4 — `pit_a71_u4_p4`: Art. 71 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a71.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50175,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 71 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 71: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a71_u4_p4_check", false) == true
}
# jdg.pit.a71.u5.p1 — `pit_a71_u5_p1`: Art. 71 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a71.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50176,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 71 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 71: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a71_u5_p1_check", false) == true
}
# jdg.pit.a72.u1.p3 — `pit_a72_u1_p3`: Art. 72 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a72.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50177,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 72 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 72: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a72_u1_p3_check", false) == true
}
# jdg.pit.a72.u3.p4 — `pit_a72_u3_p4`: Art. 72 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a72.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50178,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 72 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 72: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a72_u3_p4_check", false) == true
}
# jdg.pit.a72.u4.p1 — `pit_a72_u4_p1`: Art. 72 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a72.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50179,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 72 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 72: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a72_u4_p1_check", false) == true
}
# jdg.pit.a72.u5.p2 — `pit_a72_u5_p2`: Art. 72 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a72.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50180,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 72 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 72: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a72_u5_p2_check", false) == true
}
# jdg.pit.a73.u2.p4 — `pit_a73_u2_p4`: Art. 73 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a73.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50181,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 73 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 73: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a73_u2_p4_check", false) == true
}
# jdg.pit.a73.u3.p1 — `pit_a73_u3_p1`: Art. 73 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a73.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50182,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 73 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 73: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a73_u3_p1_check", false) == true
}
# jdg.pit.a73.u4.p2 — `pit_a73_u4_p2`: Art. 73 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a73.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50183,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 73 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 73: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a73_u4_p2_check", false) == true
}
# jdg.pit.a73.u5.p3 — `pit_a73_u5_p3`: Art. 73 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a73.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50184,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 73 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 73: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a73_u5_p3_check", false) == true
}
# jdg.pit.a74.u1.p4 — `pit_a74_u1_p4`: Art. 74 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a74.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50185,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 74 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 74: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a74_u1_p4_check", false) == true
}
# jdg.pit.a74.u2.p1 — `pit_a74_u2_p1`: Art. 74 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a74.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50186,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 74 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 74: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a74_u2_p1_check", false) == true
}
# jdg.pit.a74.u3.p2 — `pit_a74_u3_p2`: Art. 74 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a74.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50187,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 74 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 74: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a74_u3_p2_check", false) == true
}
# jdg.pit.a74.u4.p3 — `pit_a74_u4_p3`: Art. 74 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a74.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50188,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 74 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 74: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a74_u4_p3_check", false) == true
}
# jdg.pit.a75.u1.p1 — `pit_a75_u1_p1`: Art. 75 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a75.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50189,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 75 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 75: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a75_u1_p1_check", false) == true
}
# jdg.pit.a75.u2.p2 — `pit_a75_u2_p2`: Art. 75 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a75.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50190,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 75 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 75: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a75_u2_p2_check", false) == true
}
# jdg.pit.a75.u3.p3 — `pit_a75_u3_p3`: Art. 75 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a75.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50191,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 75 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 75: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a75_u3_p3_check", false) == true
}
# jdg.pit.a75.u5.p4 — `pit_a75_u5_p4`: Art. 75 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a75.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50192,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 75 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 75: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a75_u5_p4_check", false) == true
}
# jdg.pit.a76.u1.p2 — `pit_a76_u1_p2`: Art. 76 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a76.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50193,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 76 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 76: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a76_u1_p2_check", false) == true
}
# jdg.pit.a76.u2.p3 — `pit_a76_u2_p3`: Art. 76 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a76.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50194,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 76 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 76: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a76_u2_p3_check", false) == true
}
# jdg.pit.a76.u4.p4 — `pit_a76_u4_p4`: Art. 76 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a76.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50195,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 76 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 76: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a76_u4_p4_check", false) == true
}
# jdg.pit.a76.u5.p1 — `pit_a76_u5_p1`: Art. 76 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a76.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50196,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 76 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 76: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a76_u5_p1_check", false) == true
}
# jdg.pit.a77.u1.p3 — `pit_a77_u1_p3`: Art. 77 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a77.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50197,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 77 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 77: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a77_u1_p3_check", false) == true
}
# jdg.pit.a77.u3.p4 — `pit_a77_u3_p4`: Art. 77 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a77.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50198,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 77 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 77: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a77_u3_p4_check", false) == true
}
# jdg.pit.a77.u4.p1 — `pit_a77_u4_p1`: Art. 77 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a77.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50199,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 77 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 77: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a77_u4_p1_check", false) == true
}
# jdg.pit.a77.u5.p2 — `pit_a77_u5_p2`: Art. 77 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a77.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50200,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 77 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 77: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a77_u5_p2_check", false) == true
}
# jdg.pit.a78.u2.p4 — `pit_a78_u2_p4`: Art. 78 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a78.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50201,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 78 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 78: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a78_u2_p4_check", false) == true
}
# jdg.pit.a78.u3.p1 — `pit_a78_u3_p1`: Art. 78 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a78.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50202,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 78 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 78: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a78_u3_p1_check", false) == true
}
# jdg.pit.a78.u4.p2 — `pit_a78_u4_p2`: Art. 78 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a78.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50203,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 78 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 78: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a78_u4_p2_check", false) == true
}
# jdg.pit.a78.u5.p3 — `pit_a78_u5_p3`: Art. 78 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a78.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50204,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 78 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 78: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a78_u5_p3_check", false) == true
}
# jdg.pit.a79.u1.p4 — `pit_a79_u1_p4`: Art. 79 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a79.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50205,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 79 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 79: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a79_u1_p4_check", false) == true
}
# jdg.pit.a79.u2.p1 — `pit_a79_u2_p1`: Art. 79 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a79.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50206,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 79 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 79: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a79_u2_p1_check", false) == true
}
# jdg.pit.a79.u3.p2 — `pit_a79_u3_p2`: Art. 79 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a79.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50207,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 79 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 79: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a79_u3_p2_check", false) == true
}
# jdg.pit.a79.u4.p3 — `pit_a79_u4_p3`: Art. 79 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a79.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50208,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 79 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 79: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a79_u4_p3_check", false) == true
}
# jdg.pit.a80.u1.p1 — `pit_a80_u1_p1`: Art. 80 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a80.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50209,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 80 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 80: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a80_u1_p1_check", false) == true
}
# jdg.pit.a80.u2.p2 — `pit_a80_u2_p2`: Art. 80 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a80.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50210,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 80 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 80: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a80_u2_p2_check", false) == true
}
# jdg.pit.a80.u3.p3 — `pit_a80_u3_p3`: Art. 80 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a80.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50211,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 80 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 80: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a80_u3_p3_check", false) == true
}
# jdg.pit.a80.u5.p4 — `pit_a80_u5_p4`: Art. 80 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a80.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50212,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 80 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 80: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a80_u5_p4_check", false) == true
}
# jdg.pit.a81.u1.p2 — `pit_a81_u1_p2`: Art. 81 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a81.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50213,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 81 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 81: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a81_u1_p2_check", false) == true
}
# jdg.pit.a81.u2.p3 — `pit_a81_u2_p3`: Art. 81 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a81.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50214,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 81 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 81: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a81_u2_p3_check", false) == true
}
# jdg.pit.a81.u4.p4 — `pit_a81_u4_p4`: Art. 81 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a81.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50215,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 81 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 81: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a81_u4_p4_check", false) == true
}
# jdg.pit.a81.u5.p1 — `pit_a81_u5_p1`: Art. 81 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a81.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50216,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 81 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 81: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a81_u5_p1_check", false) == true
}
# jdg.pit.a82.u1.p3 — `pit_a82_u1_p3`: Art. 82 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a82.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50217,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 82 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 82: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a82_u1_p3_check", false) == true
}
# jdg.pit.a82.u3.p4 — `pit_a82_u3_p4`: Art. 82 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a82.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50218,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 82 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 82: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a82_u3_p4_check", false) == true
}
# jdg.pit.a82.u4.p1 — `pit_a82_u4_p1`: Art. 82 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a82.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50219,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 82 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 82: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a82_u4_p1_check", false) == true
}
# jdg.pit.a82.u5.p2 — `pit_a82_u5_p2`: Art. 82 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a82.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50220,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 82 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 82: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a82_u5_p2_check", false) == true
}
# jdg.pit.a83.u2.p4 — `pit_a83_u2_p4`: Art. 83 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a83.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50221,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 83 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 83: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a83_u2_p4_check", false) == true
}
# jdg.pit.a83.u3.p1 — `pit_a83_u3_p1`: Art. 83 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a83.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50222,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 83 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 83: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a83_u3_p1_check", false) == true
}
# jdg.pit.a83.u4.p2 — `pit_a83_u4_p2`: Art. 83 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a83.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50223,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 83 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 83: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a83_u4_p2_check", false) == true
}
# jdg.pit.a83.u5.p3 — `pit_a83_u5_p3`: Art. 83 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a83.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50224,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 83 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 83: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a83_u5_p3_check", false) == true
}
# jdg.pit.a84.u1.p4 — `pit_a84_u1_p4`: Art. 84 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a84.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50225,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 84 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 84: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a84_u1_p4_check", false) == true
}
# jdg.pit.a84.u2.p1 — `pit_a84_u2_p1`: Art. 84 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a84.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50226,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 84 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 84: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a84_u2_p1_check", false) == true
}
# jdg.pit.a84.u3.p2 — `pit_a84_u3_p2`: Art. 84 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a84.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50227,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 84 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 84: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a84_u3_p2_check", false) == true
}
# jdg.pit.a84.u4.p3 — `pit_a84_u4_p3`: Art. 84 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a84.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50228,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 84 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 84: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a84_u4_p3_check", false) == true
}
# jdg.pit.a85.u1.p1 — `pit_a85_u1_p1`: Art. 85 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a85.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50229,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 85 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 85: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a85_u1_p1_check", false) == true
}
# jdg.pit.a85.u2.p2 — `pit_a85_u2_p2`: Art. 85 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a85.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50230,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 85 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 85: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a85_u2_p2_check", false) == true
}
# jdg.pit.a85.u3.p3 — `pit_a85_u3_p3`: Art. 85 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a85.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50231,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 85 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 85: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a85_u3_p3_check", false) == true
}
# jdg.pit.a85.u5.p4 — `pit_a85_u5_p4`: Art. 85 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a85.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50232,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 85 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 85: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a85_u5_p4_check", false) == true
}
# jdg.pit.a86.u1.p2 — `pit_a86_u1_p2`: Art. 86 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a86.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50233,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 86 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 86: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a86_u1_p2_check", false) == true
}
# jdg.pit.a86.u2.p3 — `pit_a86_u2_p3`: Art. 86 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a86.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50234,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 86 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 86: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a86_u2_p3_check", false) == true
}
# jdg.pit.a86.u4.p4 — `pit_a86_u4_p4`: Art. 86 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a86.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50235,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 86 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 86: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a86_u4_p4_check", false) == true
}
# jdg.pit.a86.u5.p1 — `pit_a86_u5_p1`: Art. 86 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a86.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50236,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 86 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 86: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a86_u5_p1_check", false) == true
}
# jdg.pit.a87.u1.p3 — `pit_a87_u1_p3`: Art. 87 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a87.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50237,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 87 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 87: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a87_u1_p3_check", false) == true
}
# jdg.pit.a87.u3.p4 — `pit_a87_u3_p4`: Art. 87 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a87.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50238,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 87 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 87: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a87_u3_p4_check", false) == true
}
# jdg.pit.a87.u4.p1 — `pit_a87_u4_p1`: Art. 87 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a87.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50239,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 87 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 87: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a87_u4_p1_check", false) == true
}
# jdg.pit.a87.u5.p2 — `pit_a87_u5_p2`: Art. 87 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a87.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50240,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 87 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 87: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a87_u5_p2_check", false) == true
}
# jdg.pit.a88.u2.p4 — `pit_a88_u2_p4`: Art. 88 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a88.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50241,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 88 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 88: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a88_u2_p4_check", false) == true
}
# jdg.pit.a88.u3.p1 — `pit_a88_u3_p1`: Art. 88 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a88.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50242,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 88 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 88: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a88_u3_p1_check", false) == true
}
# jdg.pit.a88.u4.p2 — `pit_a88_u4_p2`: Art. 88 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a88.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50243,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 88 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 88: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a88_u4_p2_check", false) == true
}
# jdg.pit.a88.u5.p3 — `pit_a88_u5_p3`: Art. 88 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a88.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50244,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 88 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 88: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a88_u5_p3_check", false) == true
}
# jdg.pit.a89.u1.p4 — `pit_a89_u1_p4`: Art. 89 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a89.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50245,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 89 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 89: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a89_u1_p4_check", false) == true
}
# jdg.pit.a89.u2.p1 — `pit_a89_u2_p1`: Art. 89 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a89.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50246,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 89 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 89: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a89_u2_p1_check", false) == true
}
# jdg.pit.a89.u3.p2 — `pit_a89_u3_p2`: Art. 89 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a89.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50247,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 89 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 89: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a89_u3_p2_check", false) == true
}
# jdg.pit.a89.u4.p3 — `pit_a89_u4_p3`: Art. 89 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a89.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50248,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 89 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 89: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a89_u4_p3_check", false) == true
}
# jdg.pit.a90.u1.p1 — `pit_a90_u1_p1`: Art. 90 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a90.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50249,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 90 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 90: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a90_u1_p1_check", false) == true
}
# jdg.pit.a90.u2.p2 — `pit_a90_u2_p2`: Art. 90 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a90.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50250,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 90 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 90: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a90_u2_p2_check", false) == true
}
# jdg.pit.a90.u3.p3 — `pit_a90_u3_p3`: Art. 90 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a90.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50251,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 90 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 90: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a90_u3_p3_check", false) == true
}
# jdg.pit.a90.u5.p4 — `pit_a90_u5_p4`: Art. 90 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a90.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50252,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 90 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 90: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a90_u5_p4_check", false) == true
}
# jdg.pit.a91.u1.p2 — `pit_a91_u1_p2`: Art. 91 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a91.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50253,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 91 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 91: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a91_u1_p2_check", false) == true
}
# jdg.pit.a91.u2.p3 — `pit_a91_u2_p3`: Art. 91 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a91.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50254,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 91 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 91: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a91_u2_p3_check", false) == true
}
# jdg.pit.a91.u4.p4 — `pit_a91_u4_p4`: Art. 91 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a91.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50255,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 91 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 91: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a91_u4_p4_check", false) == true
}
# jdg.pit.a91.u5.p1 — `pit_a91_u5_p1`: Art. 91 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a91.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50256,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 91 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 91: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a91_u5_p1_check", false) == true
}
# jdg.pit.a92.u1.p3 — `pit_a92_u1_p3`: Art. 92 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a92.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50257,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 92 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 92: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a92_u1_p3_check", false) == true
}
# jdg.pit.a92.u3.p4 — `pit_a92_u3_p4`: Art. 92 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a92.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50258,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 92 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 92: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a92_u3_p4_check", false) == true
}
# jdg.pit.a92.u4.p1 — `pit_a92_u4_p1`: Art. 92 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a92.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50259,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 92 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 92: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a92_u4_p1_check", false) == true
}
# jdg.pit.a92.u5.p2 — `pit_a92_u5_p2`: Art. 92 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a92.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50260,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 92 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 92: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a92_u5_p2_check", false) == true
}
# jdg.pit.a93.u2.p4 — `pit_a93_u2_p4`: Art. 93 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a93.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50261,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 93 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 93: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a93_u2_p4_check", false) == true
}
# jdg.pit.a93.u3.p1 — `pit_a93_u3_p1`: Art. 93 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a93.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50262,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 93 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 93: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a93_u3_p1_check", false) == true
}
# jdg.pit.a93.u4.p2 — `pit_a93_u4_p2`: Art. 93 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a93.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50263,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 93 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 93: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a93_u4_p2_check", false) == true
}
# jdg.pit.a93.u5.p3 — `pit_a93_u5_p3`: Art. 93 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a93.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50264,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 93 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 93: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a93_u5_p3_check", false) == true
}
# jdg.pit.a94.u1.p4 — `pit_a94_u1_p4`: Art. 94 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a94.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50265,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 94 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 94: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a94_u1_p4_check", false) == true
}
# jdg.pit.a94.u2.p1 — `pit_a94_u2_p1`: Art. 94 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a94.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50266,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 94 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 94: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a94_u2_p1_check", false) == true
}
# jdg.pit.a94.u3.p2 — `pit_a94_u3_p2`: Art. 94 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a94.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50267,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 94 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 94: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a94_u3_p2_check", false) == true
}
# jdg.pit.a94.u4.p3 — `pit_a94_u4_p3`: Art. 94 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a94.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50268,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 94 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 94: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a94_u4_p3_check", false) == true
}
# jdg.pit.a95.u1.p1 — `pit_a95_u1_p1`: Art. 95 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a95.u1.p1",
    "package": "jdg.micro.pit",
    "priority": 50269,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 95 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 95: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a95_u1_p1_check", false) == true
}
# jdg.pit.a95.u2.p2 — `pit_a95_u2_p2`: Art. 95 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a95.u2.p2",
    "package": "jdg.micro.pit",
    "priority": 50270,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 95 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 95: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a95_u2_p2_check", false) == true
}
# jdg.pit.a95.u3.p3 — `pit_a95_u3_p3`: Art. 95 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a95.u3.p3",
    "package": "jdg.micro.pit",
    "priority": 50271,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 95 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 95: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a95_u3_p3_check", false) == true
}
# jdg.pit.a95.u5.p4 — `pit_a95_u5_p4`: Art. 95 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a95.u5.p4",
    "package": "jdg.micro.pit",
    "priority": 50272,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 95 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 95: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a95_u5_p4_check", false) == true
}
# jdg.pit.a96.u1.p2 — `pit_a96_u1_p2`: Art. 96 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a96.u1.p2",
    "package": "jdg.micro.pit",
    "priority": 50273,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 96 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 96: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a96_u1_p2_check", false) == true
}
# jdg.pit.a96.u2.p3 — `pit_a96_u2_p3`: Art. 96 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a96.u2.p3",
    "package": "jdg.micro.pit",
    "priority": 50274,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 96 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 96: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a96_u2_p3_check", false) == true
}
# jdg.pit.a96.u4.p4 — `pit_a96_u4_p4`: Art. 96 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a96.u4.p4",
    "package": "jdg.micro.pit",
    "priority": 50275,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 96 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 96: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a96_u4_p4_check", false) == true
}
# jdg.pit.a96.u5.p1 — `pit_a96_u5_p1`: Art. 96 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a96.u5.p1",
    "package": "jdg.micro.pit",
    "priority": 50276,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 96 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 96: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a96_u5_p1_check", false) == true
}
# jdg.pit.a97.u1.p3 — `pit_a97_u1_p3`: Art. 97 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a97.u1.p3",
    "package": "jdg.micro.pit",
    "priority": 50277,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 97 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 97: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a97_u1_p3_check", false) == true
}
# jdg.pit.a97.u3.p4 — `pit_a97_u3_p4`: Art. 97 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a97.u3.p4",
    "package": "jdg.micro.pit",
    "priority": 50278,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 97 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 97: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a97_u3_p4_check", false) == true
}
# jdg.pit.a97.u4.p1 — `pit_a97_u4_p1`: Art. 97 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a97.u4.p1",
    "package": "jdg.micro.pit",
    "priority": 50279,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 97 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 97: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a97_u4_p1_check", false) == true
}
# jdg.pit.a97.u5.p2 — `pit_a97_u5_p2`: Art. 97 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a97.u5.p2",
    "package": "jdg.micro.pit",
    "priority": 50280,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 97 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 97: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a97_u5_p2_check", false) == true
}
# jdg.pit.a98.u2.p4 — `pit_a98_u2_p4`: Art. 98 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a98.u2.p4",
    "package": "jdg.micro.pit",
    "priority": 50281,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 98 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 98: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a98_u2_p4_check", false) == true
}
# jdg.pit.a98.u3.p1 — `pit_a98_u3_p1`: Art. 98 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a98.u3.p1",
    "package": "jdg.micro.pit",
    "priority": 50282,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 98 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 98: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a98_u3_p1_check", false) == true
}
# jdg.pit.a98.u4.p2 — `pit_a98_u4_p2`: Art. 98 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a98.u4.p2",
    "package": "jdg.micro.pit",
    "priority": 50283,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 98 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 98: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a98_u4_p2_check", false) == true
}
# jdg.pit.a98.u5.p3 — `pit_a98_u5_p3`: Art. 98 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a98.u5.p3",
    "package": "jdg.micro.pit",
    "priority": 50284,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 98 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 98: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a98_u5_p3_check", false) == true
}
# jdg.pit.a99.u1.p4 — `pit_a99_u1_p4`: Art. 99 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a99.u1.p4",
    "package": "jdg.micro.pit",
    "priority": 50285,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 99 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 99: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a99_u1_p4_check", false) == true
}
# jdg.pit.a99.u2.p1 — `pit_a99_u2_p1`: Art. 99 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a99.u2.p1",
    "package": "jdg.micro.pit",
    "priority": 50286,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 99 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 99: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a99_u2_p1_check", false) == true
}
# jdg.pit.a99.u3.p2 — `pit_a99_u3_p2`: Art. 99 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a99.u3.p2",
    "package": "jdg.micro.pit",
    "priority": 50287,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 99 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 99: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a99_u3_p2_check", false) == true
}
# jdg.pit.a99.u4.p3 — `pit_a99_u4_p3`: Art. 99 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.a99.u4.p3",
    "package": "jdg.micro.pit",
    "priority": 50288,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 99 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] Art. 99: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_a99_u4_p3_check", false) == true
}
# jdg.pit.nkup.r46a — `pit_nkup_r46a`: przepis szczegółowy → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pit.nkup.r46a",
    "package": "jdg.micro.pit",
    "priority": 50289,
    "micro_rule_active": true,
    "valid_from": "1992-01-01",
    "valid_to": null,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] jdg.pit.nkup.r46a — punkt kontrolny OPA dla JDG",
    "_legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "_warnings": ["[MICRO] jdg.pit.nkup.r46a: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pit_nkup_r46a_check", false) == true
}