# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ordynacja Podatkowa — 50 artykułów → ~650 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.ord
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.ord

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.ord.no_match",
    "package": "jdg.micro.ord",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a16 — Czynny żal (6 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a16.r1: ord_a16_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a16.r1",
    "package": "jdg.micro.ord",
    "priority": 70016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Czynny żal: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a16.r2: ord_a16_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a16.r2",
    "package": "jdg.micro.ord",
    "priority": 70017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Czynny żal: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a16.r3: ord_a16_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a16.r3",
    "package": "jdg.micro.ord",
    "priority": 70018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Czynny żal: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a16_r3_pass", false) == true
}

# jdg.micro.ord.a16.r4: ord_a16_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a16.r4",
    "package": "jdg.micro.ord",
    "priority": 70019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Czynny żal: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a16_r4_checks", false) == true
}

# jdg.micro.ord.a16.r5: ord_a16_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a16.r5",
    "package": "jdg.micro.ord",
    "priority": 70020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Czynny żal: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a16.r6: ord_a16_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a16.r6",
    "package": "jdg.micro.ord",
    "priority": 70021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Czynny żal: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a20 — Zaległość podatkowa (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a20.r1: ord_a20_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a20.r1",
    "package": "jdg.micro.ord",
    "priority": 70022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zaległość podatkowa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a20.r2: ord_a20_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a20.r2",
    "package": "jdg.micro.ord",
    "priority": 70023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zaległość podatkowa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a20.r3: ord_a20_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a20.r3",
    "package": "jdg.micro.ord",
    "priority": 70024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zaległość podatkowa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a20_r3_pass", false) == true
}

# jdg.micro.ord.a20.r4: ord_a20_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a20.r4",
    "package": "jdg.micro.ord",
    "priority": 70025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zaległość podatkowa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a20_r4_checks", false) == true
}

# jdg.micro.ord.a20.r5: ord_a20_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a20.r5",
    "package": "jdg.micro.ord",
    "priority": 70026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zaległość podatkowa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a21 — Nadpłata (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a21.r1: ord_a21_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a21.r1",
    "package": "jdg.micro.ord",
    "priority": 70027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a21.r2: ord_a21_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a21.r2",
    "package": "jdg.micro.ord",
    "priority": 70028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a21.r3: ord_a21_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a21.r3",
    "package": "jdg.micro.ord",
    "priority": 70029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a21_r3_pass", false) == true
}

# jdg.micro.ord.a21.r4: ord_a21_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a21.r4",
    "package": "jdg.micro.ord",
    "priority": 70030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a21_r4_checks", false) == true
}

# jdg.micro.ord.a21.r5: ord_a21_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a21.r5",
    "package": "jdg.micro.ord",
    "priority": 70031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a26 — Odpowiedzialność podatnika (8 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a26.r1: ord_a26_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a26.r1",
    "package": "jdg.micro.ord",
    "priority": 70032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność podatnika: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a26.r2: ord_a26_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a26.r2",
    "package": "jdg.micro.ord",
    "priority": 70033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność podatnika: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a26.r3: ord_a26_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a26.r3",
    "package": "jdg.micro.ord",
    "priority": 70034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność podatnika: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a26_r3_pass", false) == true
}

# jdg.micro.ord.a26.r4: ord_a26_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a26.r4",
    "package": "jdg.micro.ord",
    "priority": 70035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność podatnika: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a26_r4_checks", false) == true
}

# jdg.micro.ord.a26.r5: ord_a26_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a26.r5",
    "package": "jdg.micro.ord",
    "priority": 70036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność podatnika: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a26.r6: ord_a26_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a26.r6",
    "package": "jdg.micro.ord",
    "priority": 70037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność podatnika: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a26.r7: ord_a26_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a26.r7",
    "package": "jdg.micro.ord",
    "priority": 70038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność podatnika: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a26_exception", false) == true
}

# jdg.micro.ord.a26.r8: ord_a26_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a26.r8",
    "package": "jdg.micro.ord",
    "priority": 70039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność podatnika: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a26_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a27 — Odpowiedzialność małżonka (6 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a27.r1: ord_a27_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a27.r1",
    "package": "jdg.micro.ord",
    "priority": 70040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność małżonka: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a27.r2: ord_a27_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a27.r2",
    "package": "jdg.micro.ord",
    "priority": 70041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność małżonka: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a27.r3: ord_a27_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a27.r3",
    "package": "jdg.micro.ord",
    "priority": 70042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność małżonka: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a27_r3_pass", false) == true
}

# jdg.micro.ord.a27.r4: ord_a27_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a27.r4",
    "package": "jdg.micro.ord",
    "priority": 70043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność małżonka: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a27_r4_checks", false) == true
}

# jdg.micro.ord.a27.r5: ord_a27_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a27.r5",
    "package": "jdg.micro.ord",
    "priority": 70044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność małżonka: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a27.r6: ord_a27_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a27.r6",
    "package": "jdg.micro.ord",
    "priority": 70045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność małżonka: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a28 — Odpowiedzialność rozwiedzionego małżonka (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a28.r1: ord_a28_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a28.r1",
    "package": "jdg.micro.ord",
    "priority": 70046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność rozwiedzionego małżonka: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a28.r2: ord_a28_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a28.r2",
    "package": "jdg.micro.ord",
    "priority": 70047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność rozwiedzionego małżonka: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a28.r3: ord_a28_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a28.r3",
    "package": "jdg.micro.ord",
    "priority": 70048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność rozwiedzionego małżonka: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a28_r3_pass", false) == true
}

# jdg.micro.ord.a28.r4: ord_a28_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a28.r4",
    "package": "jdg.micro.ord",
    "priority": 70049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność rozwiedzionego małżonka: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a28_r4_checks", false) == true
}

# jdg.micro.ord.a28.r5: ord_a28_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a28.r5",
    "package": "jdg.micro.ord",
    "priority": 70050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odpowiedzialność rozwiedzionego małżonka: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a29 — Podatnicy, płatnicy, inkasenci (8 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a29.r1: ord_a29_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a29.r1",
    "package": "jdg.micro.ord",
    "priority": 70051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Podatnicy, płatnicy, inkasenci: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a29.r2: ord_a29_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a29.r2",
    "package": "jdg.micro.ord",
    "priority": 70052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Podatnicy, płatnicy, inkasenci: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a29.r3: ord_a29_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a29.r3",
    "package": "jdg.micro.ord",
    "priority": 70053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Podatnicy, płatnicy, inkasenci: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a29_r3_pass", false) == true
}

# jdg.micro.ord.a29.r4: ord_a29_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a29.r4",
    "package": "jdg.micro.ord",
    "priority": 70054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Podatnicy, płatnicy, inkasenci: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a29_r4_checks", false) == true
}

# jdg.micro.ord.a29.r5: ord_a29_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a29.r5",
    "package": "jdg.micro.ord",
    "priority": 70055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Podatnicy, płatnicy, inkasenci: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a29.r6: ord_a29_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a29.r6",
    "package": "jdg.micro.ord",
    "priority": 70056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Podatnicy, płatnicy, inkasenci: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a29.r7: ord_a29_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a29.r7",
    "package": "jdg.micro.ord",
    "priority": 70057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Podatnicy, płatnicy, inkasenci: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a29_exception", false) == true
}

# jdg.micro.ord.a29.r8: ord_a29_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a29.r8",
    "package": "jdg.micro.ord",
    "priority": 70058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Podatnicy, płatnicy, inkasenci: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a29_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a32 — Obowiązek składania deklaracji (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a32.r1: ord_a32_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a32.r1",
    "package": "jdg.micro.ord",
    "priority": 70059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek składania deklaracji: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a32.r2: ord_a32_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a32.r2",
    "package": "jdg.micro.ord",
    "priority": 70060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek składania deklaracji: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a32.r3: ord_a32_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a32.r3",
    "package": "jdg.micro.ord",
    "priority": 70061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek składania deklaracji: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a32_r3_pass", false) == true
}

# jdg.micro.ord.a32.r4: ord_a32_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a32.r4",
    "package": "jdg.micro.ord",
    "priority": 70062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek składania deklaracji: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a32_r4_checks", false) == true
}

# jdg.micro.ord.a32.r5: ord_a32_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a32.r5",
    "package": "jdg.micro.ord",
    "priority": 70063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek składania deklaracji: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a33 — Obowiązek zapłaty podatku (8 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a33.r1: ord_a33_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a33.r1",
    "package": "jdg.micro.ord",
    "priority": 70064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek zapłaty podatku: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a33.r2: ord_a33_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a33.r2",
    "package": "jdg.micro.ord",
    "priority": 70065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek zapłaty podatku: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a33.r3: ord_a33_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a33.r3",
    "package": "jdg.micro.ord",
    "priority": 70066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek zapłaty podatku: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a33_r3_pass", false) == true
}

# jdg.micro.ord.a33.r4: ord_a33_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a33.r4",
    "package": "jdg.micro.ord",
    "priority": 70067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek zapłaty podatku: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a33_r4_checks", false) == true
}

# jdg.micro.ord.a33.r5: ord_a33_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a33.r5",
    "package": "jdg.micro.ord",
    "priority": 70068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek zapłaty podatku: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a33.r6: ord_a33_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a33.r6",
    "package": "jdg.micro.ord",
    "priority": 70069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek zapłaty podatku: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a33.r7: ord_a33_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a33.r7",
    "package": "jdg.micro.ord",
    "priority": 70070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek zapłaty podatku: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a33_exception", false) == true
}

# jdg.micro.ord.a33.r8: ord_a33_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a33.r8",
    "package": "jdg.micro.ord",
    "priority": 70071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Obowiązek zapłaty podatku: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a33_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a47 — Odsetki za zwłokę — stawka (8 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a47.r1: ord_a47_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a47.r1",
    "package": "jdg.micro.ord",
    "priority": 70072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki za zwłokę — stawka: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a47.r2: ord_a47_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a47.r2",
    "package": "jdg.micro.ord",
    "priority": 70073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki za zwłokę — stawka: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a47.r3: ord_a47_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a47.r3",
    "package": "jdg.micro.ord",
    "priority": 70074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki za zwłokę — stawka: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a47_r3_pass", false) == true
}

# jdg.micro.ord.a47.r4: ord_a47_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a47.r4",
    "package": "jdg.micro.ord",
    "priority": 70075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki za zwłokę — stawka: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a47_r4_checks", false) == true
}

# jdg.micro.ord.a47.r5: ord_a47_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a47.r5",
    "package": "jdg.micro.ord",
    "priority": 70076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki za zwłokę — stawka: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a47.r6: ord_a47_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a47.r6",
    "package": "jdg.micro.ord",
    "priority": 70077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki za zwłokę — stawka: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a47.r7: ord_a47_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a47.r7",
    "package": "jdg.micro.ord",
    "priority": 70078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki za zwłokę — stawka: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a47_exception", false) == true
}

# jdg.micro.ord.a47.r8: ord_a47_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a47.r8",
    "package": "jdg.micro.ord",
    "priority": 70079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki za zwłokę — stawka: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a47_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a48 — Odsetki — opłata prolongacyjna (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a48.r1: ord_a48_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a48.r1",
    "package": "jdg.micro.ord",
    "priority": 70080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — opłata prolongacyjna: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a48.r2: ord_a48_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a48.r2",
    "package": "jdg.micro.ord",
    "priority": 70081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — opłata prolongacyjna: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a48.r3: ord_a48_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a48.r3",
    "package": "jdg.micro.ord",
    "priority": 70082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — opłata prolongacyjna: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a48_r3_pass", false) == true
}

# jdg.micro.ord.a48.r4: ord_a48_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a48.r4",
    "package": "jdg.micro.ord",
    "priority": 70083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — opłata prolongacyjna: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a48_r4_checks", false) == true
}

# jdg.micro.ord.a48.r5: ord_a48_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a48.r5",
    "package": "jdg.micro.ord",
    "priority": 70084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — opłata prolongacyjna: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a51 — Umorzenie odsetek (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a51.r1: ord_a51_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a51.r1",
    "package": "jdg.micro.ord",
    "priority": 70085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Umorzenie odsetek: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a51.r2: ord_a51_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a51.r2",
    "package": "jdg.micro.ord",
    "priority": 70086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Umorzenie odsetek: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a51.r3: ord_a51_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a51.r3",
    "package": "jdg.micro.ord",
    "priority": 70087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Umorzenie odsetek: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a51_r3_pass", false) == true
}

# jdg.micro.ord.a51.r4: ord_a51_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a51.r4",
    "package": "jdg.micro.ord",
    "priority": 70088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Umorzenie odsetek: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a51_r4_checks", false) == true
}

# jdg.micro.ord.a51.r5: ord_a51_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a51.r5",
    "package": "jdg.micro.ord",
    "priority": 70089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Umorzenie odsetek: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a52 — Kolejność zaliczania wpłat (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a52.r1: ord_a52_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a52.r1",
    "package": "jdg.micro.ord",
    "priority": 70090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Kolejność zaliczania wpłat: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a52.r2: ord_a52_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a52.r2",
    "package": "jdg.micro.ord",
    "priority": 70091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Kolejność zaliczania wpłat: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a52.r3: ord_a52_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a52.r3",
    "package": "jdg.micro.ord",
    "priority": 70092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Kolejność zaliczania wpłat: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a52_r3_pass", false) == true
}

# jdg.micro.ord.a52.r4: ord_a52_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a52.r4",
    "package": "jdg.micro.ord",
    "priority": 70093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Kolejność zaliczania wpłat: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a52_r4_checks", false) == true
}

# jdg.micro.ord.a52.r5: ord_a52_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a52.r5",
    "package": "jdg.micro.ord",
    "priority": 70094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Kolejność zaliczania wpłat: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a53 — Odsetki — zasady ogólne (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a53.r1: ord_a53_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a53.r1",
    "package": "jdg.micro.ord",
    "priority": 70095,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — zasady ogólne: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a53.r2: ord_a53_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a53.r2",
    "package": "jdg.micro.ord",
    "priority": 70096,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — zasady ogólne: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a53.r3: ord_a53_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a53.r3",
    "package": "jdg.micro.ord",
    "priority": 70097,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — zasady ogólne: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a53_r3_pass", false) == true
}

# jdg.micro.ord.a53.r4: ord_a53_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a53.r4",
    "package": "jdg.micro.ord",
    "priority": 70098,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — zasady ogólne: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a53_r4_checks", false) == true
}

# jdg.micro.ord.a53.r5: ord_a53_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a53.r5",
    "package": "jdg.micro.ord",
    "priority": 70099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — zasady ogólne: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a54 — Odsetki — minimalna kwota (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a54.r1: ord_a54_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a54.r1",
    "package": "jdg.micro.ord",
    "priority": 70100,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — minimalna kwota: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a54.r2: ord_a54_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a54.r2",
    "package": "jdg.micro.ord",
    "priority": 70101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — minimalna kwota: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a54.r3: ord_a54_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a54.r3",
    "package": "jdg.micro.ord",
    "priority": 70102,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — minimalna kwota: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a54_r3_pass", false) == true
}

# jdg.micro.ord.a54.r4: ord_a54_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a54.r4",
    "package": "jdg.micro.ord",
    "priority": 70103,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — minimalna kwota: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a54_r4_checks", false) == true
}

# jdg.micro.ord.a54.r5: ord_a54_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a54.r5",
    "package": "jdg.micro.ord",
    "priority": 70104,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — minimalna kwota: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a56 — Odsetki — stawka podstawowa (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a56.r1: ord_a56_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56.r1",
    "package": "jdg.micro.ord",
    "priority": 70105,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — stawka podstawowa: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a56.r2: ord_a56_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56.r2",
    "package": "jdg.micro.ord",
    "priority": 70106,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — stawka podstawowa: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a56.r3: ord_a56_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56.r3",
    "package": "jdg.micro.ord",
    "priority": 70107,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — stawka podstawowa: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a56_r3_pass", false) == true
}

# jdg.micro.ord.a56.r4: ord_a56_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56.r4",
    "package": "jdg.micro.ord",
    "priority": 70108,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — stawka podstawowa: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a56_r4_checks", false) == true
}

# jdg.micro.ord.a56.r5: ord_a56_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56.r5",
    "package": "jdg.micro.ord",
    "priority": 70109,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki — stawka podstawowa: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a56b — Odsetki karne 150% (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a56b.r1: ord_a56b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56b.r1",
    "package": "jdg.micro.ord",
    "priority": 70110,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki karne 150%: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a56b.r2: ord_a56b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56b.r2",
    "package": "jdg.micro.ord",
    "priority": 70111,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki karne 150%: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a56b.r3: ord_a56b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56b.r3",
    "package": "jdg.micro.ord",
    "priority": 70112,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki karne 150%: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a56b_r3_pass", false) == true
}

# jdg.micro.ord.a56b.r4: ord_a56b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56b.r4",
    "package": "jdg.micro.ord",
    "priority": 70113,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki karne 150%: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a56b_r4_checks", false) == true
}

# jdg.micro.ord.a56b.r5: ord_a56b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a56b.r5",
    "package": "jdg.micro.ord",
    "priority": 70114,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odsetki karne 150%: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a67a — Ulgi w spłacie — rodzaje (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a67a.r1: ord_a67a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67a.r1",
    "package": "jdg.micro.ord",
    "priority": 70115,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi w spłacie — rodzaje: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a67a.r2: ord_a67a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67a.r2",
    "package": "jdg.micro.ord",
    "priority": 70116,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi w spłacie — rodzaje: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a67a.r3: ord_a67a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67a.r3",
    "package": "jdg.micro.ord",
    "priority": 70117,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi w spłacie — rodzaje: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67a_r3_pass", false) == true
}

# jdg.micro.ord.a67a.r4: ord_a67a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67a.r4",
    "package": "jdg.micro.ord",
    "priority": 70118,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi w spłacie — rodzaje: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67a_r4_checks", false) == true
}

# jdg.micro.ord.a67a.r5: ord_a67a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67a.r5",
    "package": "jdg.micro.ord",
    "priority": 70119,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi w spłacie — rodzaje: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a67b — Odroczenie / raty (8 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a67b.r1: ord_a67b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67b.r1",
    "package": "jdg.micro.ord",
    "priority": 70120,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odroczenie / raty: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a67b.r2: ord_a67b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67b.r2",
    "package": "jdg.micro.ord",
    "priority": 70121,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odroczenie / raty: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a67b.r3: ord_a67b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67b.r3",
    "package": "jdg.micro.ord",
    "priority": 70122,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odroczenie / raty: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67b_r3_pass", false) == true
}

# jdg.micro.ord.a67b.r4: ord_a67b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67b.r4",
    "package": "jdg.micro.ord",
    "priority": 70123,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odroczenie / raty: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67b_r4_checks", false) == true
}

# jdg.micro.ord.a67b.r5: ord_a67b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67b.r5",
    "package": "jdg.micro.ord",
    "priority": 70124,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odroczenie / raty: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a67b.r6: ord_a67b_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67b.r6",
    "package": "jdg.micro.ord",
    "priority": 70125,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odroczenie / raty: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a67b.r7: ord_a67b_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67b.r7",
    "package": "jdg.micro.ord",
    "priority": 70126,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odroczenie / raty: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a67b_exception", false) == true
}

# jdg.micro.ord.a67b.r8: ord_a67b_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67b.r8",
    "package": "jdg.micro.ord",
    "priority": 70127,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odroczenie / raty: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a67b_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a67c — Ulgi automatyczne (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a67c.r1: ord_a67c_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67c.r1",
    "package": "jdg.micro.ord",
    "priority": 70128,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi automatyczne: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a67c.r2: ord_a67c_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67c.r2",
    "package": "jdg.micro.ord",
    "priority": 70129,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi automatyczne: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a67c.r3: ord_a67c_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67c.r3",
    "package": "jdg.micro.ord",
    "priority": 70130,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi automatyczne: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67c_r3_pass", false) == true
}

# jdg.micro.ord.a67c.r4: ord_a67c_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67c.r4",
    "package": "jdg.micro.ord",
    "priority": 70131,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi automatyczne: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67c_r4_checks", false) == true
}

# jdg.micro.ord.a67c.r5: ord_a67c_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67c.r5",
    "package": "jdg.micro.ord",
    "priority": 70132,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Ulgi automatyczne: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a67d — Zabezpieczenie przy ulgach (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a67d.r1: ord_a67d_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67d.r1",
    "package": "jdg.micro.ord",
    "priority": 70133,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zabezpieczenie przy ulgach: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a67d.r2: ord_a67d_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67d.r2",
    "package": "jdg.micro.ord",
    "priority": 70134,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zabezpieczenie przy ulgach: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a67d.r3: ord_a67d_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67d.r3",
    "package": "jdg.micro.ord",
    "priority": 70135,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zabezpieczenie przy ulgach: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67d_r3_pass", false) == true
}

# jdg.micro.ord.a67d.r4: ord_a67d_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67d.r4",
    "package": "jdg.micro.ord",
    "priority": 70136,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zabezpieczenie przy ulgach: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67d_r4_checks", false) == true
}

# jdg.micro.ord.a67d.r5: ord_a67d_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67d.r5",
    "package": "jdg.micro.ord",
    "priority": 70137,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zabezpieczenie przy ulgach: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a67e — Odwołanie ulgi (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a67e.r1: ord_a67e_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67e.r1",
    "package": "jdg.micro.ord",
    "priority": 70138,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odwołanie ulgi: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a67e.r2: ord_a67e_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67e.r2",
    "package": "jdg.micro.ord",
    "priority": 70139,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odwołanie ulgi: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a67e.r3: ord_a67e_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67e.r3",
    "package": "jdg.micro.ord",
    "priority": 70140,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odwołanie ulgi: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67e_r3_pass", false) == true
}

# jdg.micro.ord.a67e.r4: ord_a67e_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67e.r4",
    "package": "jdg.micro.ord",
    "priority": 70141,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odwołanie ulgi: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a67e_r4_checks", false) == true
}

# jdg.micro.ord.a67e.r5: ord_a67e_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a67e.r5",
    "package": "jdg.micro.ord",
    "priority": 70142,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Odwołanie ulgi: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a70 — Przedawnienie zobowiązań (15 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a70.r1: ord_a70_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r1",
    "package": "jdg.micro.ord",
    "priority": 70143,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a70.r2: ord_a70_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r2",
    "package": "jdg.micro.ord",
    "priority": 70144,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a70.r3: ord_a70_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r3",
    "package": "jdg.micro.ord",
    "priority": 70145,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a70_r3_pass", false) == true
}

# jdg.micro.ord.a70.r4: ord_a70_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r4",
    "package": "jdg.micro.ord",
    "priority": 70146,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a70_r4_checks", false) == true
}

# jdg.micro.ord.a70.r5: ord_a70_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r5",
    "package": "jdg.micro.ord",
    "priority": 70147,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a70.r6: ord_a70_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r6",
    "package": "jdg.micro.ord",
    "priority": 70148,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a70.r7: ord_a70_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r7",
    "package": "jdg.micro.ord",
    "priority": 70149,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a70_exception", false) == true
}

# jdg.micro.ord.a70.r8: ord_a70_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r8",
    "package": "jdg.micro.ord",
    "priority": 70150,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a70_exception_2", false) == true
}

# jdg.micro.ord.a70.r9: ord_a70_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r9",
    "package": "jdg.micro.ord",
    "priority": 70151,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ord", false) == true
}

# jdg.micro.ord.a70.r10: ord_a70_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r10",
    "package": "jdg.micro.ord",
    "priority": 70152,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ord", false) == true
}

# jdg.micro.ord.a70.r11: ord_a70_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r11",
    "package": "jdg.micro.ord",
    "priority": 70153,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ord_deadline_required", false) == true
}

# jdg.micro.ord.a70.r12: ord_a70_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r12",
    "package": "jdg.micro.ord",
    "priority": 70154,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie Przedawnienie zobowiązań",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ord_a70_violation", false) == true
}

# jdg.micro.ord.a70.r13: ord_a70_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r13",
    "package": "jdg.micro.ord",
    "priority": 70155,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "ord_a70_edge_case", false) == true
}

# jdg.micro.ord.a70.r14: ord_a70_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r14",
    "package": "jdg.micro.ord",
    "priority": 70156,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "ord_a70_edge_case_2", false) == true
}

# jdg.micro.ord.a70.r15: ord_a70_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.r15",
    "package": "jdg.micro.ord",
    "priority": 70157,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przedawnienie zobowiązań: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "ord_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a71 — Przerwanie i zawieszenie przedawnienia (10 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a71.r1: ord_a71_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r1",
    "package": "jdg.micro.ord",
    "priority": 70158,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a71.r2: ord_a71_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r2",
    "package": "jdg.micro.ord",
    "priority": 70159,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a71.r3: ord_a71_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r3",
    "package": "jdg.micro.ord",
    "priority": 70160,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a71_r3_pass", false) == true
}

# jdg.micro.ord.a71.r4: ord_a71_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r4",
    "package": "jdg.micro.ord",
    "priority": 70161,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a71_r4_checks", false) == true
}

# jdg.micro.ord.a71.r5: ord_a71_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r5",
    "package": "jdg.micro.ord",
    "priority": 70162,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a71.r6: ord_a71_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r6",
    "package": "jdg.micro.ord",
    "priority": 70163,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a71.r7: ord_a71_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r7",
    "package": "jdg.micro.ord",
    "priority": 70164,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a71_exception", false) == true
}

# jdg.micro.ord.a71.r8: ord_a71_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r8",
    "package": "jdg.micro.ord",
    "priority": 70165,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a71_exception_2", false) == true
}

# jdg.micro.ord.a71.r9: ord_a71_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r9",
    "package": "jdg.micro.ord",
    "priority": 70166,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ord", false) == true
}

# jdg.micro.ord.a71.r10: ord_a71_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a71.r10",
    "package": "jdg.micro.ord",
    "priority": 70167,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przerwanie i zawieszenie przedawnienia: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ord", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a72 — Nadpłata — definicja (8 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a72.r1: ord_a72_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a72.r1",
    "package": "jdg.micro.ord",
    "priority": 70168,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — definicja: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a72.r2: ord_a72_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a72.r2",
    "package": "jdg.micro.ord",
    "priority": 70169,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — definicja: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a72.r3: ord_a72_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a72.r3",
    "package": "jdg.micro.ord",
    "priority": 70170,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — definicja: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a72_r3_pass", false) == true
}

# jdg.micro.ord.a72.r4: ord_a72_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a72.r4",
    "package": "jdg.micro.ord",
    "priority": 70171,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — definicja: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a72_r4_checks", false) == true
}

# jdg.micro.ord.a72.r5: ord_a72_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a72.r5",
    "package": "jdg.micro.ord",
    "priority": 70172,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — definicja: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a72.r6: ord_a72_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a72.r6",
    "package": "jdg.micro.ord",
    "priority": 70173,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — definicja: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a72.r7: ord_a72_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a72.r7",
    "package": "jdg.micro.ord",
    "priority": 70174,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — definicja: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a72_exception", false) == true
}

# jdg.micro.ord.a72.r8: ord_a72_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a72.r8",
    "package": "jdg.micro.ord",
    "priority": 70175,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — definicja: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a72_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a73 — Nadpłata — zaliczenie (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a73.r1: ord_a73_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a73.r1",
    "package": "jdg.micro.ord",
    "priority": 70176,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — zaliczenie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a73.r2: ord_a73_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a73.r2",
    "package": "jdg.micro.ord",
    "priority": 70177,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — zaliczenie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a73.r3: ord_a73_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a73.r3",
    "package": "jdg.micro.ord",
    "priority": 70178,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — zaliczenie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a73_r3_pass", false) == true
}

# jdg.micro.ord.a73.r4: ord_a73_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a73.r4",
    "package": "jdg.micro.ord",
    "priority": 70179,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — zaliczenie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a73_r4_checks", false) == true
}

# jdg.micro.ord.a73.r5: ord_a73_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a73.r5",
    "package": "jdg.micro.ord",
    "priority": 70180,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — zaliczenie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a74 — Nadpłata — wniosek o zwrot (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a74.r1: ord_a74_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a74.r1",
    "package": "jdg.micro.ord",
    "priority": 70181,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — wniosek o zwrot: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a74.r2: ord_a74_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a74.r2",
    "package": "jdg.micro.ord",
    "priority": 70182,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — wniosek o zwrot: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a74.r3: ord_a74_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a74.r3",
    "package": "jdg.micro.ord",
    "priority": 70183,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — wniosek o zwrot: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a74_r3_pass", false) == true
}

# jdg.micro.ord.a74.r4: ord_a74_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a74.r4",
    "package": "jdg.micro.ord",
    "priority": 70184,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — wniosek o zwrot: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a74_r4_checks", false) == true
}

# jdg.micro.ord.a74.r5: ord_a74_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a74.r5",
    "package": "jdg.micro.ord",
    "priority": 70185,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — wniosek o zwrot: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a75 — Nadpłata po przedawnieniu (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a75.r1: ord_a75_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a75.r1",
    "package": "jdg.micro.ord",
    "priority": 70186,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata po przedawnieniu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a75.r2: ord_a75_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a75.r2",
    "package": "jdg.micro.ord",
    "priority": 70187,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata po przedawnieniu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a75.r3: ord_a75_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a75.r3",
    "package": "jdg.micro.ord",
    "priority": 70188,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata po przedawnieniu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a75_r3_pass", false) == true
}

# jdg.micro.ord.a75.r4: ord_a75_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a75.r4",
    "package": "jdg.micro.ord",
    "priority": 70189,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata po przedawnieniu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a75_r4_checks", false) == true
}

# jdg.micro.ord.a75.r5: ord_a75_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a75.r5",
    "package": "jdg.micro.ord",
    "priority": 70190,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata po przedawnieniu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a76 — Nadpłata — minimum 5 PLN (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a76.r1: ord_a76_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a76.r1",
    "package": "jdg.micro.ord",
    "priority": 70191,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — minimum 5 PLN: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a76.r2: ord_a76_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a76.r2",
    "package": "jdg.micro.ord",
    "priority": 70192,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — minimum 5 PLN: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a76.r3: ord_a76_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a76.r3",
    "package": "jdg.micro.ord",
    "priority": 70193,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — minimum 5 PLN: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a76_r3_pass", false) == true
}

# jdg.micro.ord.a76.r4: ord_a76_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a76.r4",
    "package": "jdg.micro.ord",
    "priority": 70194,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — minimum 5 PLN: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a76_r4_checks", false) == true
}

# jdg.micro.ord.a76.r5: ord_a76_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a76.r5",
    "package": "jdg.micro.ord",
    "priority": 70195,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — minimum 5 PLN: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a77 — Nadpłata — dziedziczenie (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a77.r1: ord_a77_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a77.r1",
    "package": "jdg.micro.ord",
    "priority": 70196,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — dziedziczenie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a77.r2: ord_a77_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a77.r2",
    "package": "jdg.micro.ord",
    "priority": 70197,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — dziedziczenie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a77.r3: ord_a77_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a77.r3",
    "package": "jdg.micro.ord",
    "priority": 70198,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — dziedziczenie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a77_r3_pass", false) == true
}

# jdg.micro.ord.a77.r4: ord_a77_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a77.r4",
    "package": "jdg.micro.ord",
    "priority": 70199,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — dziedziczenie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a77_r4_checks", false) == true
}

# jdg.micro.ord.a77.r5: ord_a77_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a77.r5",
    "package": "jdg.micro.ord",
    "priority": 70200,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — dziedziczenie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a78 — Nadpłata — termin korekty (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a78.r1: ord_a78_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a78.r1",
    "package": "jdg.micro.ord",
    "priority": 70201,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — termin korekty: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a78.r2: ord_a78_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a78.r2",
    "package": "jdg.micro.ord",
    "priority": 70202,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — termin korekty: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a78.r3: ord_a78_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a78.r3",
    "package": "jdg.micro.ord",
    "priority": 70203,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — termin korekty: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a78_r3_pass", false) == true
}

# jdg.micro.ord.a78.r4: ord_a78_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a78.r4",
    "package": "jdg.micro.ord",
    "priority": 70204,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — termin korekty: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a78_r4_checks", false) == true
}

# jdg.micro.ord.a78.r5: ord_a78_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a78.r5",
    "package": "jdg.micro.ord",
    "priority": 70205,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — termin korekty: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a79 — Nadpłata — korekta przed/po kontroli (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a79.r1: ord_a79_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a79.r1",
    "package": "jdg.micro.ord",
    "priority": 70206,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — korekta przed/po kontroli: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a79.r2: ord_a79_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a79.r2",
    "package": "jdg.micro.ord",
    "priority": 70207,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — korekta przed/po kontroli: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a79.r3: ord_a79_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a79.r3",
    "package": "jdg.micro.ord",
    "priority": 70208,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — korekta przed/po kontroli: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a79_r3_pass", false) == true
}

# jdg.micro.ord.a79.r4: ord_a79_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a79.r4",
    "package": "jdg.micro.ord",
    "priority": 70209,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — korekta przed/po kontroli: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a79_r4_checks", false) == true
}

# jdg.micro.ord.a79.r5: ord_a79_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a79.r5",
    "package": "jdg.micro.ord",
    "priority": 70210,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — korekta przed/po kontroli: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a80 — Nadpłata — waluta obca (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a80.r1: ord_a80_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a80.r1",
    "package": "jdg.micro.ord",
    "priority": 70211,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — waluta obca: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a80.r2: ord_a80_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a80.r2",
    "package": "jdg.micro.ord",
    "priority": 70212,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — waluta obca: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a80.r3: ord_a80_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a80.r3",
    "package": "jdg.micro.ord",
    "priority": 70213,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — waluta obca: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a80_r3_pass", false) == true
}

# jdg.micro.ord.a80.r4: ord_a80_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a80.r4",
    "package": "jdg.micro.ord",
    "priority": 70214,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — waluta obca: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a80_r4_checks", false) == true
}

# jdg.micro.ord.a80.r5: ord_a80_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a80.r5",
    "package": "jdg.micro.ord",
    "priority": 70215,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Nadpłata — waluta obca: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a81 — Korekta deklaracji (10 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a81.r1: ord_a81_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r1",
    "package": "jdg.micro.ord",
    "priority": 70216,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a81.r2: ord_a81_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r2",
    "package": "jdg.micro.ord",
    "priority": 70217,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a81.r3: ord_a81_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r3",
    "package": "jdg.micro.ord",
    "priority": 70218,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a81_r3_pass", false) == true
}

# jdg.micro.ord.a81.r4: ord_a81_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r4",
    "package": "jdg.micro.ord",
    "priority": 70219,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a81_r4_checks", false) == true
}

# jdg.micro.ord.a81.r5: ord_a81_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r5",
    "package": "jdg.micro.ord",
    "priority": 70220,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a81.r6: ord_a81_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r6",
    "package": "jdg.micro.ord",
    "priority": 70221,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a81.r7: ord_a81_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r7",
    "package": "jdg.micro.ord",
    "priority": 70222,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a81_exception", false) == true
}

# jdg.micro.ord.a81.r8: ord_a81_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r8",
    "package": "jdg.micro.ord",
    "priority": 70223,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a81_exception_2", false) == true
}

# jdg.micro.ord.a81.r9: ord_a81_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r9",
    "package": "jdg.micro.ord",
    "priority": 70224,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ord", false) == true
}

# jdg.micro.ord.a81.r10: ord_a81_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81.r10",
    "package": "jdg.micro.ord",
    "priority": 70225,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta deklaracji: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ord", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a81b — Korekta w trakcie kontroli (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a81b.r1: ord_a81b_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81b.r1",
    "package": "jdg.micro.ord",
    "priority": 70226,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta w trakcie kontroli: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a81b.r2: ord_a81b_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81b.r2",
    "package": "jdg.micro.ord",
    "priority": 70227,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta w trakcie kontroli: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a81b.r3: ord_a81b_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81b.r3",
    "package": "jdg.micro.ord",
    "priority": 70228,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta w trakcie kontroli: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a81b_r3_pass", false) == true
}

# jdg.micro.ord.a81b.r4: ord_a81b_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81b.r4",
    "package": "jdg.micro.ord",
    "priority": 70229,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta w trakcie kontroli: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a81b_r4_checks", false) == true
}

# jdg.micro.ord.a81b.r5: ord_a81b_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81b.r5",
    "package": "jdg.micro.ord",
    "priority": 70230,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Korekta w trakcie kontroli: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a86 — Przechowywanie dokumentów (8 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a86.r1: ord_a86_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a86.r1",
    "package": "jdg.micro.ord",
    "priority": 70231,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a86.r2: ord_a86_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a86.r2",
    "package": "jdg.micro.ord",
    "priority": 70232,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a86.r3: ord_a86_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a86.r3",
    "package": "jdg.micro.ord",
    "priority": 70233,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a86_r3_pass", false) == true
}

# jdg.micro.ord.a86.r4: ord_a86_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a86.r4",
    "package": "jdg.micro.ord",
    "priority": 70234,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a86_r4_checks", false) == true
}

# jdg.micro.ord.a86.r5: ord_a86_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a86.r5",
    "package": "jdg.micro.ord",
    "priority": 70235,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a86.r6: ord_a86_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a86.r6",
    "package": "jdg.micro.ord",
    "priority": 70236,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a86.r7: ord_a86_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a86.r7",
    "package": "jdg.micro.ord",
    "priority": 70237,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a86_exception", false) == true
}

# jdg.micro.ord.a86.r8: ord_a86_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a86.r8",
    "package": "jdg.micro.ord",
    "priority": 70238,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Przechowywanie dokumentów: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a86_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a87 — Zwrot nadpłaty — 45 dni (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a87.r1: ord_a87_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a87.r1",
    "package": "jdg.micro.ord",
    "priority": 70239,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zwrot nadpłaty — 45 dni: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a87.r2: ord_a87_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a87.r2",
    "package": "jdg.micro.ord",
    "priority": 70240,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zwrot nadpłaty — 45 dni: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a87.r3: ord_a87_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a87.r3",
    "package": "jdg.micro.ord",
    "priority": 70241,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zwrot nadpłaty — 45 dni: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a87_r3_pass", false) == true
}

# jdg.micro.ord.a87.r4: ord_a87_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a87.r4",
    "package": "jdg.micro.ord",
    "priority": 70242,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zwrot nadpłaty — 45 dni: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a87_r4_checks", false) == true
}

# jdg.micro.ord.a87.r5: ord_a87_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a87.r5",
    "package": "jdg.micro.ord",
    "priority": 70243,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Zwrot nadpłaty — 45 dni: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a119a — Klauzula GAAR (10 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a119a.r1: ord_a119a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r1",
    "package": "jdg.micro.ord",
    "priority": 70244,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a119a.r2: ord_a119a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r2",
    "package": "jdg.micro.ord",
    "priority": 70245,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a119a.r3: ord_a119a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r3",
    "package": "jdg.micro.ord",
    "priority": 70246,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a119a_r3_pass", false) == true
}

# jdg.micro.ord.a119a.r4: ord_a119a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r4",
    "package": "jdg.micro.ord",
    "priority": 70247,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a119a_r4_checks", false) == true
}

# jdg.micro.ord.a119a.r5: ord_a119a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r5",
    "package": "jdg.micro.ord",
    "priority": 70248,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a119a.r6: ord_a119a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r6",
    "package": "jdg.micro.ord",
    "priority": 70249,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a119a.r7: ord_a119a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r7",
    "package": "jdg.micro.ord",
    "priority": 70250,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a119a_exception", false) == true
}

# jdg.micro.ord.a119a.r8: ord_a119a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r8",
    "package": "jdg.micro.ord",
    "priority": 70251,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a119a_exception_2", false) == true
}

# jdg.micro.ord.a119a.r9: ord_a119a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r9",
    "package": "jdg.micro.ord",
    "priority": 70252,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ord", false) == true
}

# jdg.micro.ord.a119a.r10: ord_a119a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.r10",
    "package": "jdg.micro.ord",
    "priority": 70253,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Klauzula GAAR: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ord", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a120 — Postępowanie — wszczęcie (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a120.r1: ord_a120_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a120.r1",
    "package": "jdg.micro.ord",
    "priority": 70254,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — wszczęcie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a120.r2: ord_a120_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a120.r2",
    "package": "jdg.micro.ord",
    "priority": 70255,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — wszczęcie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a120.r3: ord_a120_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a120.r3",
    "package": "jdg.micro.ord",
    "priority": 70256,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — wszczęcie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a120_r3_pass", false) == true
}

# jdg.micro.ord.a120.r4: ord_a120_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a120.r4",
    "package": "jdg.micro.ord",
    "priority": 70257,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — wszczęcie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a120_r4_checks", false) == true
}

# jdg.micro.ord.a120.r5: ord_a120_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a120.r5",
    "package": "jdg.micro.ord",
    "priority": 70258,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — wszczęcie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a121 — Postępowanie — strona (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a121.r1: ord_a121_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a121.r1",
    "package": "jdg.micro.ord",
    "priority": 70259,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — strona: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a121.r2: ord_a121_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a121.r2",
    "package": "jdg.micro.ord",
    "priority": 70260,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — strona: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a121.r3: ord_a121_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a121.r3",
    "package": "jdg.micro.ord",
    "priority": 70261,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — strona: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a121_r3_pass", false) == true
}

# jdg.micro.ord.a121.r4: ord_a121_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a121.r4",
    "package": "jdg.micro.ord",
    "priority": 70262,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — strona: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a121_r4_checks", false) == true
}

# jdg.micro.ord.a121.r5: ord_a121_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a121.r5",
    "package": "jdg.micro.ord",
    "priority": 70263,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — strona: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a122 — Postępowanie — pełnomocnik (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a122.r1: ord_a122_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a122.r1",
    "package": "jdg.micro.ord",
    "priority": 70264,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — pełnomocnik: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a122.r2: ord_a122_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a122.r2",
    "package": "jdg.micro.ord",
    "priority": 70265,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — pełnomocnik: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a122.r3: ord_a122_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a122.r3",
    "package": "jdg.micro.ord",
    "priority": 70266,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — pełnomocnik: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a122_r3_pass", false) == true
}

# jdg.micro.ord.a122.r4: ord_a122_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a122.r4",
    "package": "jdg.micro.ord",
    "priority": 70267,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — pełnomocnik: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a122_r4_checks", false) == true
}

# jdg.micro.ord.a122.r5: ord_a122_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a122.r5",
    "package": "jdg.micro.ord",
    "priority": 70268,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — pełnomocnik: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a123 — Postępowanie — dowody (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a123.r1: ord_a123_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a123.r1",
    "package": "jdg.micro.ord",
    "priority": 70269,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — dowody: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a123.r2: ord_a123_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a123.r2",
    "package": "jdg.micro.ord",
    "priority": 70270,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — dowody: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a123.r3: ord_a123_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a123.r3",
    "package": "jdg.micro.ord",
    "priority": 70271,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — dowody: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a123_r3_pass", false) == true
}

# jdg.micro.ord.a123.r4: ord_a123_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a123.r4",
    "package": "jdg.micro.ord",
    "priority": 70272,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — dowody: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a123_r4_checks", false) == true
}

# jdg.micro.ord.a123.r5: ord_a123_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a123.r5",
    "package": "jdg.micro.ord",
    "priority": 70273,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — dowody: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a124 — Postępowanie — terminy (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a124.r1: ord_a124_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a124.r1",
    "package": "jdg.micro.ord",
    "priority": 70274,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — terminy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a124.r2: ord_a124_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a124.r2",
    "package": "jdg.micro.ord",
    "priority": 70275,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — terminy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a124.r3: ord_a124_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a124.r3",
    "package": "jdg.micro.ord",
    "priority": 70276,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — terminy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a124_r3_pass", false) == true
}

# jdg.micro.ord.a124.r4: ord_a124_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a124.r4",
    "package": "jdg.micro.ord",
    "priority": 70277,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — terminy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a124_r4_checks", false) == true
}

# jdg.micro.ord.a124.r5: ord_a124_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a124.r5",
    "package": "jdg.micro.ord",
    "priority": 70278,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — terminy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a125 — Postępowanie — decyzja (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a125.r1: ord_a125_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a125.r1",
    "package": "jdg.micro.ord",
    "priority": 70279,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — decyzja: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a125.r2: ord_a125_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a125.r2",
    "package": "jdg.micro.ord",
    "priority": 70280,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — decyzja: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a125.r3: ord_a125_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a125.r3",
    "package": "jdg.micro.ord",
    "priority": 70281,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — decyzja: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a125_r3_pass", false) == true
}

# jdg.micro.ord.a125.r4: ord_a125_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a125.r4",
    "package": "jdg.micro.ord",
    "priority": 70282,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — decyzja: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a125_r4_checks", false) == true
}

# jdg.micro.ord.a125.r5: ord_a125_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a125.r5",
    "package": "jdg.micro.ord",
    "priority": 70283,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — decyzja: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a126 — Postępowanie — odwołanie (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a126.r1: ord_a126_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a126.r1",
    "package": "jdg.micro.ord",
    "priority": 70284,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — odwołanie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a126.r2: ord_a126_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a126.r2",
    "package": "jdg.micro.ord",
    "priority": 70285,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — odwołanie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a126.r3: ord_a126_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a126.r3",
    "package": "jdg.micro.ord",
    "priority": 70286,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — odwołanie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a126_r3_pass", false) == true
}

# jdg.micro.ord.a126.r4: ord_a126_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a126.r4",
    "package": "jdg.micro.ord",
    "priority": 70287,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — odwołanie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a126_r4_checks", false) == true
}

# jdg.micro.ord.a126.r5: ord_a126_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a126.r5",
    "package": "jdg.micro.ord",
    "priority": 70288,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — odwołanie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a127 — Postępowanie — skarga do WSA (5 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a127.r1: ord_a127_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a127.r1",
    "package": "jdg.micro.ord",
    "priority": 70289,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — skarga do WSA: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a127.r2: ord_a127_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a127.r2",
    "package": "jdg.micro.ord",
    "priority": 70290,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — skarga do WSA: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a127.r3: ord_a127_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a127.r3",
    "package": "jdg.micro.ord",
    "priority": 70291,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — skarga do WSA: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a127_r3_pass", false) == true
}

# jdg.micro.ord.a127.r4: ord_a127_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a127.r4",
    "package": "jdg.micro.ord",
    "priority": 70292,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — skarga do WSA: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a127_r4_checks", false) == true
}

# jdg.micro.ord.a127.r5: ord_a127_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a127.r5",
    "package": "jdg.micro.ord",
    "priority": 70293,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Postępowanie — skarga do WSA: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a138a — Pełnomocnictwa podatkowe (30 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a138a.r1: ord_a138a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r1",
    "package": "jdg.micro.ord",
    "priority": 70294,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a138a.r2: ord_a138a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r2",
    "package": "jdg.micro.ord",
    "priority": 70295,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a138a.r3: ord_a138a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r3",
    "package": "jdg.micro.ord",
    "priority": 70296,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a138a_r3_pass", false) == true
}

# jdg.micro.ord.a138a.r4: ord_a138a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r4",
    "package": "jdg.micro.ord",
    "priority": 70297,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a138a_r4_checks", false) == true
}

# jdg.micro.ord.a138a.r5: ord_a138a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r5",
    "package": "jdg.micro.ord",
    "priority": 70298,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a138a.r6: ord_a138a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r6",
    "package": "jdg.micro.ord",
    "priority": 70299,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a138a.r7: ord_a138a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r7",
    "package": "jdg.micro.ord",
    "priority": 70300,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a138a_exception", false) == true
}

# jdg.micro.ord.a138a.r8: ord_a138a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r8",
    "package": "jdg.micro.ord",
    "priority": 70301,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a138a_exception_2", false) == true
}

# jdg.micro.ord.a138a.r9: ord_a138a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r9",
    "package": "jdg.micro.ord",
    "priority": 70302,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ord", false) == true
}

# jdg.micro.ord.a138a.r10: ord_a138a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r10",
    "package": "jdg.micro.ord",
    "priority": 70303,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ord", false) == true
}

# jdg.micro.ord.a138a.r11: ord_a138a_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r11",
    "package": "jdg.micro.ord",
    "priority": 70304,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ord_deadline_required", false) == true
}

# jdg.micro.ord.a138a.r12: ord_a138a_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r12",
    "package": "jdg.micro.ord",
    "priority": 70305,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie Pełnomocnictwa podatkowe",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ord_a138a_violation", false) == true
}

# jdg.micro.ord.a138a.r13: ord_a138a_r13_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r13",
    "package": "jdg.micro.ord",
    "priority": 70306,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "ord_a138a_edge_case", false) == true
}

# jdg.micro.ord.a138a.r14: ord_a138a_r14_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r14",
    "package": "jdg.micro.ord",
    "priority": 70307,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "ord_a138a_edge_case_2", false) == true
}

# jdg.micro.ord.a138a.r15: ord_a138a_r15_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r15",
    "package": "jdg.micro.ord",
    "priority": 70308,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "ord_validation_required", false) == true
}

# jdg.micro.ord.a138a.r16: ord_a138a_r16_eligibility
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r16",
    "package": "jdg.micro.ord",
    "priority": 70309,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a138a.r17: ord_a138a_r17_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r17",
    "package": "jdg.micro.ord",
    "priority": 70310,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a138a.r18: ord_a138a_r18_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r18",
    "package": "jdg.micro.ord",
    "priority": 70311,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a138a_r18_pass", false) == true
}

# jdg.micro.ord.a138a.r19: ord_a138a_r19_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r19",
    "package": "jdg.micro.ord",
    "priority": 70312,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a138a_r19_checks", false) == true
}

# jdg.micro.ord.a138a.r20: ord_a138a_r20_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r20",
    "package": "jdg.micro.ord",
    "priority": 70313,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a138a.r21: ord_a138a_r21_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r21",
    "package": "jdg.micro.ord",
    "priority": 70314,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a138a.r22: ord_a138a_r22_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r22",
    "package": "jdg.micro.ord",
    "priority": 70315,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a138a_exception", false) == true
}

# jdg.micro.ord.a138a.r23: ord_a138a_r23_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r23",
    "package": "jdg.micro.ord",
    "priority": 70316,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a138a_exception_2", false) == true
}

# jdg.micro.ord.a138a.r24: ord_a138a_r24_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r24",
    "package": "jdg.micro.ord",
    "priority": 70317,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ord", false) == true
}

# jdg.micro.ord.a138a.r25: ord_a138a_r25_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r25",
    "package": "jdg.micro.ord",
    "priority": 70318,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ord", false) == true
}

# jdg.micro.ord.a138a.r26: ord_a138a_r26_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r26",
    "package": "jdg.micro.ord",
    "priority": 70319,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "ord_deadline_required", false) == true
}

# jdg.micro.ord.a138a.r27: ord_a138a_r27_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r27",
    "package": "jdg.micro.ord",
    "priority": 70320,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "_routing_reason": "Sankcja KKS: naruszenie Pełnomocnictwa podatkowe",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "ord_a138a_violation", false) == true
}

# jdg.micro.ord.a138a.r28: ord_a138a_r28_edge_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r28",
    "package": "jdg.micro.ord",
    "priority": 70321,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: edge case — nietypowa sytuacja wymagająca uwagi"]
} {
    object.get(input.invoice, "ord_a138a_edge_case", false) == true
}

# jdg.micro.ord.a138a.r29: ord_a138a_r29_edge_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r29",
    "package": "jdg.micro.ord",
    "priority": 70322,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: drugi edge case — rzadki scenariusz"]
} {
    object.get(input.invoice, "ord_a138a_edge_case_2", false) == true
}

# jdg.micro.ord.a138a.r30: ord_a138a_r30_validation
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a138a.r30",
    "package": "jdg.micro.ord",
    "priority": 70323,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Pełnomocnictwa podatkowe: walidacja formalna — sprawdź dokumenty"]
} {
    object.get(input.invoice, "ord_validation_required", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ord.a193a — JPK na żądanie (10 reguł)                                    ║
# ║  Legal basis: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a193a.r1: ord_a193a_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r1",
    "package": "jdg.micro.ord",
    "priority": 70324,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.ord.a193a.r2: ord_a193a_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r2",
    "package": "jdg.micro.ord",
    "priority": 70325,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "ord_condition_met", false) == true
}

# jdg.micro.ord.a193a.r3: ord_a193a_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r3",
    "package": "jdg.micro.ord",
    "priority": 70326,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "ord_a193a_r3_pass", false) == true
}

# jdg.micro.ord.a193a.r4: ord_a193a_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r4",
    "package": "jdg.micro.ord",
    "priority": 70327,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "ord_a193a_r4_checks", false) == true
}

# jdg.micro.ord.a193a.r5: ord_a193a_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r5",
    "package": "jdg.micro.ord",
    "priority": 70328,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "ord_exclusion_applies", false) == false
}

# jdg.micro.ord.a193a.r6: ord_a193a_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r6",
    "package": "jdg.micro.ord",
    "priority": 70329,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "ord_exclusion_2", false) == false
}

# jdg.micro.ord.a193a.r7: ord_a193a_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r7",
    "package": "jdg.micro.ord",
    "priority": 70330,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "ord_a193a_exception", false) == true
}

# jdg.micro.ord.a193a.r8: ord_a193a_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r8",
    "package": "jdg.micro.ord",
    "priority": 70331,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "ord_a193a_exception_2", false) == true
}

# jdg.micro.ord.a193a.r9: ord_a193a_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r9",
    "package": "jdg.micro.ord",
    "priority": 70332,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_ord", false) == true
}

# jdg.micro.ord.a193a.r10: ord_a193a_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.r10",
    "package": "jdg.micro.ord",
    "priority": 70333,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] JPK na żądanie: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_ord", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (105 reguł)       ║
# ║  Priorytety: 50000-50104                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.ord.a100.u1.p1 — `ord_a100_u1_p1`: Art. 100 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a100.u1.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 100 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 100: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a100_u1_p1_check", false) == true
}
# jdg.ord.a100.u2.p2 — `ord_a100_u2_p2`: Art. 100 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a100.u2.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 100 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 100: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a100_u2_p2_check", false) == true
}
# jdg.ord.a101.u1.p2 — `ord_a101_u1_p2`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a101.u1.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a101_u1_p2_check", false) == true
}
# jdg.ord.a101.u3.p3 — `ord_a101_u3_p3`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a101.u3.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a101_u3_p3_check", false) == true
}
# jdg.ord.a101.u4.p4 — `ord_a101_u4_p4`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a101.u4.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a101_u4_p4_check", false) == true
}
# jdg.ord.a101.u5.p1 — `ord_a101_u5_p1`: Art. 101 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a101.u5.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 101 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 101: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a101_u5_p1_check", false) == true
}
# jdg.ord.a102.u2.p3 — `ord_a102_u2_p3`: Art. 102 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a102.u2.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 102 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 102: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a102_u2_p3_check", false) == true
}
# jdg.ord.a102.u3.p4 — `ord_a102_u3_p4`: Art. 102 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a102.u3.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 102 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 102: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a102_u3_p4_check", false) == true
}
# jdg.ord.a102.u4.p1 — `ord_a102_u4_p1`: Art. 102 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a102.u4.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 102 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 102: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a102_u4_p1_check", false) == true
}
# jdg.ord.a102.u5.p2 — `ord_a102_u5_p2`: Art. 102 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a102.u5.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 102 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 102: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a102_u5_p2_check", false) == true
}
# jdg.ord.a103.u1.p3 — `ord_a103_u1_p3`: Art. 103 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a103.u1.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 103 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 103: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a103_u1_p3_check", false) == true
}
# jdg.ord.a103.u2.p4 — `ord_a103_u2_p4`: Art. 103 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a103.u2.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 103 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 103: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a103_u2_p4_check", false) == true
}
# jdg.ord.a103.u3.p1 — `ord_a103_u3_p1`: Art. 103 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a103.u3.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 103 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 103: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a103_u3_p1_check", false) == true
}
# jdg.ord.a103.u4.p2 — `ord_a103_u4_p2`: Art. 103 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a103.u4.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 103 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 103: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a103_u4_p2_check", false) == true
}
# jdg.ord.a104.u1.p4 — `ord_a104_u1_p4`: Art. 104 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a104.u1.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 104 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 104: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a104_u1_p4_check", false) == true
}
# jdg.ord.a104.u2.p1 — `ord_a104_u2_p1`: Art. 104 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a104.u2.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 104 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 104: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a104_u2_p1_check", false) == true
}
# jdg.ord.a104.u3.p2 — `ord_a104_u3_p2`: Art. 104 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a104.u3.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 104 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 104: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a104_u3_p2_check", false) == true
}
# jdg.ord.a104.u5.p3 — `ord_a104_u5_p3`: Art. 104 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a104.u5.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 104 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 104: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a104_u5_p3_check", false) == true
}
# jdg.ord.a105.u1.p1 — `ord_a105_u1_p1`: Art. 105 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a105.u1.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 105 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 105: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a105_u1_p1_check", false) == true
}
# jdg.ord.a105.u2.p2 — `ord_a105_u2_p2`: Art. 105 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a105.u2.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 105 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 105: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a105_u2_p2_check", false) == true
}
# jdg.ord.a105.u4.p3 — `ord_a105_u4_p3`: Art. 105 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a105.u4.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 105 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 105: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a105_u4_p3_check", false) == true
}
# jdg.ord.a105.u5.p4 — `ord_a105_u5_p4`: Art. 105 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a105.u5.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 105 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 105: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a105_u5_p4_check", false) == true
}
# jdg.ord.a106.u1.p2 — `ord_a106_u1_p2`: Art. 106 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a106.u1.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 106 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 106: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a106_u1_p2_check", false) == true
}
# jdg.ord.a106.u3.p3 — `ord_a106_u3_p3`: Art. 106 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a106.u3.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 106 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 106: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a106_u3_p3_check", false) == true
}
# jdg.ord.a106.u4.p4 — `ord_a106_u4_p4`: Art. 106 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a106.u4.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 106 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 106: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a106_u4_p4_check", false) == true
}
# jdg.ord.a106.u5.p1 — `ord_a106_u5_p1`: Art. 106 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a106.u5.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 106 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 106: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a106_u5_p1_check", false) == true
}
# jdg.ord.a107.u2.p3 — `ord_a107_u2_p3`: Art. 107 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a107.u2.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 107 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 107: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a107_u2_p3_check", false) == true
}
# jdg.ord.a107.u3.p4 — `ord_a107_u3_p4`: Art. 107 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a107.u3.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 107 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 107: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a107_u3_p4_check", false) == true
}
# jdg.ord.a107.u4.p1 — `ord_a107_u4_p1`: Art. 107 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a107.u4.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 107 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 107: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a107_u4_p1_check", false) == true
}
# jdg.ord.a107.u5.p2 — `ord_a107_u5_p2`: Art. 107 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a107.u5.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 107 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 107: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a107_u5_p2_check", false) == true
}
# jdg.ord.a108.u1.p3 — `ord_a108_u1_p3`: Art. 108 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a108.u1.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 108 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 108: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a108_u1_p3_check", false) == true
}
# jdg.ord.a108.u2.p4 — `ord_a108_u2_p4`: Art. 108 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a108.u2.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 108 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 108: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a108_u2_p4_check", false) == true
}
# jdg.ord.a108.u3.p1 — `ord_a108_u3_p1`: Art. 108 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a108.u3.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 108 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 108: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a108_u3_p1_check", false) == true
}
# jdg.ord.a108.u4.p2 — `ord_a108_u4_p2`: Art. 108 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a108.u4.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 108 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 108: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a108_u4_p2_check", false) == true
}
# jdg.ord.a109.u1.p4 — `ord_a109_u1_p4`: Art. 109 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a109.u1.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 109 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 109: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a109_u1_p4_check", false) == true
}
# jdg.ord.a109.u2.p1 — `ord_a109_u2_p1`: Art. 109 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a109.u2.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 109 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 109: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a109_u2_p1_check", false) == true
}
# jdg.ord.a109.u3.p2 — `ord_a109_u3_p2`: Art. 109 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a109.u3.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 109 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 109: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a109_u3_p2_check", false) == true
}
# jdg.ord.a109.u5.p3 — `ord_a109_u5_p3`: Art. 109 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a109.u5.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 109 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 109: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a109_u5_p3_check", false) == true
}
# jdg.ord.a110.u1.p1 — `ord_a110_u1_p1`: Art. 110 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a110.u1.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 110 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 110: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a110_u1_p1_check", false) == true
}
# jdg.ord.a110.u2.p2 — `ord_a110_u2_p2`: Art. 110 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a110.u2.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 110 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 110: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a110_u2_p2_check", false) == true
}
# jdg.ord.a110.u4.p3 — `ord_a110_u4_p3`: Art. 110 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a110.u4.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 110 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 110: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a110_u4_p3_check", false) == true
}
# jdg.ord.a110.u5.p4 — `ord_a110_u5_p4`: Art. 110 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a110.u5.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 110 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 110: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a110_u5_p4_check", false) == true
}
# jdg.ord.a111.u1.p2 — `ord_a111_u1_p2`: Art. 111 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a111.u1.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 111 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 111: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a111_u1_p2_check", false) == true
}
# jdg.ord.a111.u3.p3 — `ord_a111_u3_p3`: Art. 111 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a111.u3.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 111 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 111: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a111_u3_p3_check", false) == true
}
# jdg.ord.a111.u4.p4 — `ord_a111_u4_p4`: Art. 111 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a111.u4.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 111 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 111: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a111_u4_p4_check", false) == true
}
# jdg.ord.a111.u5.p1 — `ord_a111_u5_p1`: Art. 111 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a111.u5.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 111 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 111: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a111_u5_p1_check", false) == true
}
# jdg.ord.a112.u2.p3 — `ord_a112_u2_p3`: Art. 112 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a112.u2.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 112 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 112: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a112_u2_p3_check", false) == true
}
# jdg.ord.a112.u3.p4 — `ord_a112_u3_p4`: Art. 112 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a112.u3.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 112 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 112: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a112_u3_p4_check", false) == true
}
# jdg.ord.a112.u4.p1 — `ord_a112_u4_p1`: Art. 112 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a112.u4.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 112 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 112: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a112_u4_p1_check", false) == true
}
# jdg.ord.a112.u5.p2 — `ord_a112_u5_p2`: Art. 112 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a112.u5.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 112 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 112: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a112_u5_p2_check", false) == true
}
# jdg.ord.a113.u1.p3 — `ord_a113_u1_p3`: Art. 113 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a113.u1.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 113 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 113: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a113_u1_p3_check", false) == true
}
# jdg.ord.a113.u2.p4 — `ord_a113_u2_p4`: Art. 113 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a113.u2.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 113 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 113: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a113_u2_p4_check", false) == true
}
# jdg.ord.a113.u3.p1 — `ord_a113_u3_p1`: Art. 113 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a113.u3.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 113 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 113: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a113_u3_p1_check", false) == true
}
# jdg.ord.a113.u4.p2 — `ord_a113_u4_p2`: Art. 113 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a113.u4.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 113 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 113: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a113_u4_p2_check", false) == true
}
# jdg.ord.a114.u1.p4 — `ord_a114_u1_p4`: Art. 114 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a114.u1.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 114 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 114: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a114_u1_p4_check", false) == true
}
# jdg.ord.a114.u2.p1 — `ord_a114_u2_p1`: Art. 114 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a114.u2.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 114 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 114: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a114_u2_p1_check", false) == true
}
# jdg.ord.a114.u3.p2 — `ord_a114_u3_p2`: Art. 114 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a114.u3.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 114 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 114: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a114_u3_p2_check", false) == true
}
# jdg.ord.a114.u5.p3 — `ord_a114_u5_p3`: Art. 114 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a114.u5.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 114 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 114: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a114_u5_p3_check", false) == true
}
# jdg.ord.a115.u1.p1 — `ord_a115_u1_p1`: Art. 115 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a115.u1.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 115 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 115: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a115_u1_p1_check", false) == true
}
# jdg.ord.a115.u2.p2 — `ord_a115_u2_p2`: Art. 115 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a115.u2.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 115 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 115: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a115_u2_p2_check", false) == true
}
# jdg.ord.a115.u4.p3 — `ord_a115_u4_p3`: Art. 115 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a115.u4.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 115 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 115: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a115_u4_p3_check", false) == true
}
# jdg.ord.a115.u5.p4 — `ord_a115_u5_p4`: Art. 115 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a115.u5.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 115 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 115: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a115_u5_p4_check", false) == true
}
# jdg.ord.a116.u1.p2 — `ord_a116_u1_p2`: Art. 116 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a116.u1.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 116 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 116: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a116_u1_p2_check", false) == true
}
# jdg.ord.a116.u3.p3 — `ord_a116_u3_p3`: Art. 116 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a116.u3.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 116 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 116: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a116_u3_p3_check", false) == true
}
# jdg.ord.a116.u4.p4 — `ord_a116_u4_p4`: Art. 116 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a116.u4.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 116 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 116: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a116_u4_p4_check", false) == true
}
# jdg.ord.a116.u5.p1 — `ord_a116_u5_p1`: Art. 116 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a116.u5.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 116 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 116: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a116_u5_p1_check", false) == true
}
# jdg.ord.a117.u2.p3 — `ord_a117_u2_p3`: Art. 117 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a117.u2.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 117 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 117: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a117_u2_p3_check", false) == true
}
# jdg.ord.a117.u3.p4 — `ord_a117_u3_p4`: Art. 117 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a117.u3.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 117 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 117: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a117_u3_p4_check", false) == true
}
# jdg.ord.a117.u4.p1 — `ord_a117_u4_p1`: Art. 117 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a117.u4.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 117 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 117: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a117_u4_p1_check", false) == true
}
# jdg.ord.a117.u5.p2 — `ord_a117_u5_p2`: Art. 117 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a117.u5.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 117 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 117: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a117_u5_p2_check", false) == true
}
# jdg.ord.a118.u1.p3 — `ord_a118_u1_p3`: Art. 118 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a118.u1.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 118 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 118: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a118_u1_p3_check", false) == true
}
# jdg.ord.a118.u2.p4 — `ord_a118_u2_p4`: Art. 118 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a118.u2.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 118 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 118: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a118_u2_p4_check", false) == true
}
# jdg.ord.a118.u3.p1 — `ord_a118_u3_p1`: Art. 118 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a118.u3.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 118 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 118: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a118_u3_p1_check", false) == true
}
# jdg.ord.a118.u4.p2 — `ord_a118_u4_p2`: Art. 118 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a118.u4.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 118 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 118: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a118_u4_p2_check", false) == true
}
# jdg.ord.a119.u1.p4 — `ord_a119_u1_p4`: Art. 119 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a119.u1.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 119 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 119: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a119_u1_p4_check", false) == true
}
# jdg.ord.a119.u2.p1 — `ord_a119_u2_p1`: Art. 119 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a119.u2.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 119 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 119: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a119_u2_p1_check", false) == true
}
# jdg.ord.a119.u3.p2 — `ord_a119_u3_p2`: Art. 119 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a119.u3.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 119 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 119: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a119_u3_p2_check", false) == true
}
# jdg.ord.a119.u5.p3 — `ord_a119_u5_p3`: Art. 119 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a119.u5.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 119 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 119: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a119_u5_p3_check", false) == true
}
# jdg.ord.a120.u1.p1 — `ord_a120_u1_p1`: Art. 120 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a120.u1.p1",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 120 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 120: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a120_u1_p1_check", false) == true
}
# jdg.ord.a120.u2.p2 — `ord_a120_u2_p2`: Art. 120 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a120.u2.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 120 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 120: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a120_u2_p2_check", false) == true
}
# jdg.ord.a120.u4.p3 — `ord_a120_u4_p3`: Art. 120 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a120.u4.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 120 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 120: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a120_u4_p3_check", false) == true
}
# jdg.ord.a120.u5.p4 — `ord_a120_u5_p4`: Art. 120 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a120.u5.p4",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 120 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 120: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a120_u5_p4_check", false) == true
}
# jdg.ord.a121.u1.p2 — `ord_a121_u1_p2`: Art. 121 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a121.u1.p2",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 121 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 121: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a121_u1_p2_check", false) == true
}
# jdg.ord.a121.u3.p3 — `ord_a121_u3_p3`: Art. 121 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a121.u3.p3",
    "package": "jdg.micro.ord",
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
    "_routing_reason": "[MICRO] Art. 121 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 121: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a121_u3_p3_check", false) == true
}
# jdg.ord.a121.u4.p4 — `ord_a121_u4_p4`: Art. 121 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a121.u4.p4",
    "package": "jdg.micro.ord",
    "priority": 50084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 121 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 121: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a121_u4_p4_check", false) == true
}
# jdg.ord.a121.u5.p1 — `ord_a121_u5_p1`: Art. 121 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a121.u5.p1",
    "package": "jdg.micro.ord",
    "priority": 50085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 121 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 121: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a121_u5_p1_check", false) == true
}
# jdg.ord.a122.u2.p3 — `ord_a122_u2_p3`: Art. 122 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a122.u2.p3",
    "package": "jdg.micro.ord",
    "priority": 50086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 122 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 122: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a122_u2_p3_check", false) == true
}
# jdg.ord.a122.u3.p4 — `ord_a122_u3_p4`: Art. 122 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a122.u3.p4",
    "package": "jdg.micro.ord",
    "priority": 50087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 122 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 122: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a122_u3_p4_check", false) == true
}
# jdg.ord.a122.u4.p1 — `ord_a122_u4_p1`: Art. 122 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a122.u4.p1",
    "package": "jdg.micro.ord",
    "priority": 50088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 122 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 122: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a122_u4_p1_check", false) == true
}
# jdg.ord.a122.u5.p2 — `ord_a122_u5_p2`: Art. 122 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a122.u5.p2",
    "package": "jdg.micro.ord",
    "priority": 50089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 122 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 122: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a122_u5_p2_check", false) == true
}
# jdg.ord.a123.u1.p3 — `ord_a123_u1_p3`: Art. 123 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a123.u1.p3",
    "package": "jdg.micro.ord",
    "priority": 50090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 123 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 123: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a123_u1_p3_check", false) == true
}
# jdg.ord.a123.u2.p4 — `ord_a123_u2_p4`: Art. 123 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a123.u2.p4",
    "package": "jdg.micro.ord",
    "priority": 50091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 123 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 123: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a123_u2_p4_check", false) == true
}
# jdg.ord.a123.u3.p1 — `ord_a123_u3_p1`: Art. 123 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a123.u3.p1",
    "package": "jdg.micro.ord",
    "priority": 50092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 123 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 123: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a123_u3_p1_check", false) == true
}
# jdg.ord.a123.u4.p2 — `ord_a123_u4_p2`: Art. 123 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a123.u4.p2",
    "package": "jdg.micro.ord",
    "priority": 50093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 123 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 123: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a123_u4_p2_check", false) == true
}
# jdg.ord.a124.u1.p4 — `ord_a124_u1_p4`: Art. 124 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a124.u1.p4",
    "package": "jdg.micro.ord",
    "priority": 50094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 124 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 124: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a124_u1_p4_check", false) == true
}
# jdg.ord.a124.u2.p1 — `ord_a124_u2_p1`: Art. 124 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a124.u2.p1",
    "package": "jdg.micro.ord",
    "priority": 50095,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 124 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 124: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a124_u2_p1_check", false) == true
}
# jdg.ord.a124.u3.p2 — `ord_a124_u3_p2`: Art. 124 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a124.u3.p2",
    "package": "jdg.micro.ord",
    "priority": 50096,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 124 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 124: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a124_u3_p2_check", false) == true
}
# jdg.ord.a124.u5.p3 — `ord_a124_u5_p3`: Art. 124 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a124.u5.p3",
    "package": "jdg.micro.ord",
    "priority": 50097,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 124 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 124: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a124_u5_p3_check", false) == true
}
# jdg.ord.a125.u4.p3 — `ord_a125_u4_p3`: Art. 125 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a125.u4.p3",
    "package": "jdg.micro.ord",
    "priority": 50098,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 125 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 125: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a125_u4_p3_check", false) == true
}
# jdg.ord.a125.u5.p4 — `ord_a125_u5_p4`: Art. 125 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a125.u5.p4",
    "package": "jdg.micro.ord",
    "priority": 50099,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 125 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 125: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a125_u5_p4_check", false) == true
}
# jdg.ord.a16.r1 — `ord_a16_r1`: Art. 16 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a16.r1",
    "package": "jdg.micro.ord",
    "priority": 50100,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 16: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a16_r1_check", false) == true
}
# jdg.ord.a16a.r1 — `ord_a16a_r1`: Art. 16a → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a16a.r1",
    "package": "jdg.micro.ord",
    "priority": 50101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 16a — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 16a: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a16a_r1_check", false) == true
}
# jdg.ord.a20.r1 — `ord_a20_r1`: Art. 20 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a20.r1",
    "package": "jdg.micro.ord",
    "priority": 50102,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 20: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a20_r1_check", false) == true
}
# jdg.ord.a21.r1 — `ord_a21_r1`: Art. 21 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a21.r1",
    "package": "jdg.micro.ord",
    "priority": 50103,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
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
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 21: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a21_r1_check", false) == true
}
# jdg.ord.a67a.r1 — `ord_a67a_r1`: Art. 67a → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.ord.a67a.r1",
    "package": "jdg.micro.ord",
    "priority": 50104,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 67a — walidacja szczegółowa dla JDG",
    "_legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "_warnings": ["[MICRO] Art. 67a: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "ord_a67a_r1_check", false) == true
}