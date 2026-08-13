# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Prawo Przedsiębiorców — 25 artykułów → ~250 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.pp
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pp

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pp.no_match",
    "package": "jdg.micro.pp",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a3 — Definicja przedsiębiorcy (10 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a3.r1: pp_a3_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r1",
    "package": "jdg.micro.pp",
    "priority": 130003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a3.r2: pp_a3_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r2",
    "package": "jdg.micro.pp",
    "priority": 130004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a3.r3: pp_a3_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r3",
    "package": "jdg.micro.pp",
    "priority": 130005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a3_r3_pass", false) == true
}

# jdg.micro.pp.a3.r4: pp_a3_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r4",
    "package": "jdg.micro.pp",
    "priority": 130006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a3_r4_checks", false) == true
}

# jdg.micro.pp.a3.r5: pp_a3_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r5",
    "package": "jdg.micro.pp",
    "priority": 130007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a3.r6: pp_a3_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r6",
    "package": "jdg.micro.pp",
    "priority": 130008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a3.r7: pp_a3_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r7",
    "package": "jdg.micro.pp",
    "priority": 130009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a3_exception", false) == true
}

# jdg.micro.pp.a3.r8: pp_a3_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r8",
    "package": "jdg.micro.pp",
    "priority": 130010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a3_exception_2", false) == true
}

# jdg.micro.pp.a3.r9: pp_a3_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r9",
    "package": "jdg.micro.pp",
    "priority": 130011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pp", false) == true
}

# jdg.micro.pp.a3.r10: pp_a3_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a3.r10",
    "package": "jdg.micro.pp",
    "priority": 130012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja przedsiębiorcy: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pp", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a4 — Definicja działalności gospodarczej (10 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a4.r1: pp_a4_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r1",
    "package": "jdg.micro.pp",
    "priority": 130013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a4.r2: pp_a4_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r2",
    "package": "jdg.micro.pp",
    "priority": 130014,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a4.r3: pp_a4_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r3",
    "package": "jdg.micro.pp",
    "priority": 130015,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a4_r3_pass", false) == true
}

# jdg.micro.pp.a4.r4: pp_a4_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r4",
    "package": "jdg.micro.pp",
    "priority": 130016,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a4_r4_checks", false) == true
}

# jdg.micro.pp.a4.r5: pp_a4_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r5",
    "package": "jdg.micro.pp",
    "priority": 130017,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a4.r6: pp_a4_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r6",
    "package": "jdg.micro.pp",
    "priority": 130018,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a4.r7: pp_a4_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r7",
    "package": "jdg.micro.pp",
    "priority": 130019,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a4_exception", false) == true
}

# jdg.micro.pp.a4.r8: pp_a4_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r8",
    "package": "jdg.micro.pp",
    "priority": 130020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a4_exception_2", false) == true
}

# jdg.micro.pp.a4.r9: pp_a4_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r9",
    "package": "jdg.micro.pp",
    "priority": 130021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pp", false) == true
}

# jdg.micro.pp.a4.r10: pp_a4_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a4.r10",
    "package": "jdg.micro.pp",
    "priority": 130022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Definicja działalności gospodarczej: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pp", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a5 — Działalność nieewidencjonowana (12 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a5.r1: pp_a5_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r1",
    "package": "jdg.micro.pp",
    "priority": 130023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a5.r2: pp_a5_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r2",
    "package": "jdg.micro.pp",
    "priority": 130024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a5.r3: pp_a5_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r3",
    "package": "jdg.micro.pp",
    "priority": 130025,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a5_r3_pass", false) == true
}

# jdg.micro.pp.a5.r4: pp_a5_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r4",
    "package": "jdg.micro.pp",
    "priority": 130026,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a5_r4_checks", false) == true
}

# jdg.micro.pp.a5.r5: pp_a5_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r5",
    "package": "jdg.micro.pp",
    "priority": 130027,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a5.r6: pp_a5_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r6",
    "package": "jdg.micro.pp",
    "priority": 130028,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a5.r7: pp_a5_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r7",
    "package": "jdg.micro.pp",
    "priority": 130029,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a5_exception", false) == true
}

# jdg.micro.pp.a5.r8: pp_a5_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r8",
    "package": "jdg.micro.pp",
    "priority": 130030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a5_exception_2", false) == true
}

# jdg.micro.pp.a5.r9: pp_a5_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r9",
    "package": "jdg.micro.pp",
    "priority": 130031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pp", false) == true
}

# jdg.micro.pp.a5.r10: pp_a5_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r10",
    "package": "jdg.micro.pp",
    "priority": 130032,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pp", false) == true
}

# jdg.micro.pp.a5.r11: pp_a5_r11_deadline
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r11",
    "package": "jdg.micro.pp",
    "priority": 130033,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: termin / procedura — sprawdź deadline"]
} {
    object.get(input.invoice, "pp_deadline_required", false) == true
}

# jdg.micro.pp.a5.r12: pp_a5_r12_sanction [SANKCJA]
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5.r12",
    "package": "jdg.micro.pp",
    "priority": 130034,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
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
    "sanction_base_amount_pln": 1000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: naruszenie Działalność nieewidencjonowana",
    "_legal_basis": "Art. 5 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Działalność nieewidencjonowana: SANKCJA KKS — naruszenie przepisu!"]
} {
    object.get(input.jdg_entrepreneur, "pp_a5_violation", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a14 — Prawa przedsiębiorcy (8 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a14.r1: pp_a14_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a14.r1",
    "package": "jdg.micro.pp",
    "priority": 130035,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Prawa przedsiębiorcy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a14.r2: pp_a14_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a14.r2",
    "package": "jdg.micro.pp",
    "priority": 130036,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Prawa przedsiębiorcy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a14.r3: pp_a14_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a14.r3",
    "package": "jdg.micro.pp",
    "priority": 130037,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Prawa przedsiębiorcy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a14_r3_pass", false) == true
}

# jdg.micro.pp.a14.r4: pp_a14_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a14.r4",
    "package": "jdg.micro.pp",
    "priority": 130038,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Prawa przedsiębiorcy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a14_r4_checks", false) == true
}

# jdg.micro.pp.a14.r5: pp_a14_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a14.r5",
    "package": "jdg.micro.pp",
    "priority": 130039,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Prawa przedsiębiorcy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a14.r6: pp_a14_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a14.r6",
    "package": "jdg.micro.pp",
    "priority": 130040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Prawa przedsiębiorcy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a14.r7: pp_a14_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a14.r7",
    "package": "jdg.micro.pp",
    "priority": 130041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Prawa przedsiębiorcy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a14_exception", false) == true
}

# jdg.micro.pp.a14.r8: pp_a14_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a14.r8",
    "package": "jdg.micro.pp",
    "priority": 130042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Prawa przedsiębiorcy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a14_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a17 — Obowiązki przedsiębiorcy (8 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a17.r1: pp_a17_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a17.r1",
    "package": "jdg.micro.pp",
    "priority": 130043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Obowiązki przedsiębiorcy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a17.r2: pp_a17_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a17.r2",
    "package": "jdg.micro.pp",
    "priority": 130044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Obowiązki przedsiębiorcy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a17.r3: pp_a17_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a17.r3",
    "package": "jdg.micro.pp",
    "priority": 130045,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Obowiązki przedsiębiorcy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a17_r3_pass", false) == true
}

# jdg.micro.pp.a17.r4: pp_a17_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a17.r4",
    "package": "jdg.micro.pp",
    "priority": 130046,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Obowiązki przedsiębiorcy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a17_r4_checks", false) == true
}

# jdg.micro.pp.a17.r5: pp_a17_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a17.r5",
    "package": "jdg.micro.pp",
    "priority": 130047,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Obowiązki przedsiębiorcy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a17.r6: pp_a17_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a17.r6",
    "package": "jdg.micro.pp",
    "priority": 130048,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Obowiązki przedsiębiorcy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a17.r7: pp_a17_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a17.r7",
    "package": "jdg.micro.pp",
    "priority": 130049,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Obowiązki przedsiębiorcy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a17_exception", false) == true
}

# jdg.micro.pp.a17.r8: pp_a17_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a17.r8",
    "package": "jdg.micro.pp",
    "priority": 130050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Obowiązki przedsiębiorcy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a17_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a22 — Zawieszenie działalności (10 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a22.r1: pp_a22_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r1",
    "package": "jdg.micro.pp",
    "priority": 130051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a22.r2: pp_a22_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r2",
    "package": "jdg.micro.pp",
    "priority": 130052,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a22.r3: pp_a22_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r3",
    "package": "jdg.micro.pp",
    "priority": 130053,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a22_r3_pass", false) == true
}

# jdg.micro.pp.a22.r4: pp_a22_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r4",
    "package": "jdg.micro.pp",
    "priority": 130054,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a22_r4_checks", false) == true
}

# jdg.micro.pp.a22.r5: pp_a22_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r5",
    "package": "jdg.micro.pp",
    "priority": 130055,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a22.r6: pp_a22_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r6",
    "package": "jdg.micro.pp",
    "priority": 130056,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a22.r7: pp_a22_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r7",
    "package": "jdg.micro.pp",
    "priority": 130057,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a22_exception", false) == true
}

# jdg.micro.pp.a22.r8: pp_a22_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r8",
    "package": "jdg.micro.pp",
    "priority": 130058,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a22_exception_2", false) == true
}

# jdg.micro.pp.a22.r9: pp_a22_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r9",
    "package": "jdg.micro.pp",
    "priority": 130059,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pp", false) == true
}

# jdg.micro.pp.a22.r10: pp_a22_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a22.r10",
    "package": "jdg.micro.pp",
    "priority": 130060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie działalności: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pp", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a23 — Zawieszenie — konsekwencje (8 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a23.r1: pp_a23_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a23.r1",
    "package": "jdg.micro.pp",
    "priority": 130061,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie — konsekwencje: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a23.r2: pp_a23_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a23.r2",
    "package": "jdg.micro.pp",
    "priority": 130062,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie — konsekwencje: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a23.r3: pp_a23_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a23.r3",
    "package": "jdg.micro.pp",
    "priority": 130063,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie — konsekwencje: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a23_r3_pass", false) == true
}

# jdg.micro.pp.a23.r4: pp_a23_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a23.r4",
    "package": "jdg.micro.pp",
    "priority": 130064,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie — konsekwencje: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a23_r4_checks", false) == true
}

# jdg.micro.pp.a23.r5: pp_a23_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a23.r5",
    "package": "jdg.micro.pp",
    "priority": 130065,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie — konsekwencje: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a23.r6: pp_a23_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a23.r6",
    "package": "jdg.micro.pp",
    "priority": 130066,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie — konsekwencje: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a23.r7: pp_a23_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a23.r7",
    "package": "jdg.micro.pp",
    "priority": 130067,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie — konsekwencje: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a23_exception", false) == true
}

# jdg.micro.pp.a23.r8: pp_a23_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a23.r8",
    "package": "jdg.micro.pp",
    "priority": 130068,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Zawieszenie — konsekwencje: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a23_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a25 — Wznowienie działalności (8 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a25.r1: pp_a25_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a25.r1",
    "package": "jdg.micro.pp",
    "priority": 130069,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 25 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Wznowienie działalności: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a25.r2: pp_a25_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a25.r2",
    "package": "jdg.micro.pp",
    "priority": 130070,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 25 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Wznowienie działalności: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a25.r3: pp_a25_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a25.r3",
    "package": "jdg.micro.pp",
    "priority": 130071,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 25 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Wznowienie działalności: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a25_r3_pass", false) == true
}

# jdg.micro.pp.a25.r4: pp_a25_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a25.r4",
    "package": "jdg.micro.pp",
    "priority": 130072,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 25 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Wznowienie działalności: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a25_r4_checks", false) == true
}

# jdg.micro.pp.a25.r5: pp_a25_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a25.r5",
    "package": "jdg.micro.pp",
    "priority": 130073,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 25 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Wznowienie działalności: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a25.r6: pp_a25_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a25.r6",
    "package": "jdg.micro.pp",
    "priority": 130074,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 25 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Wznowienie działalności: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a25.r7: pp_a25_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a25.r7",
    "package": "jdg.micro.pp",
    "priority": 130075,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 25 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Wznowienie działalności: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a25_exception", false) == true
}

# jdg.micro.pp.a25.r8: pp_a25_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a25.r8",
    "package": "jdg.micro.pp",
    "priority": 130076,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 25 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Wznowienie działalności: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a25_exception_2", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a34 — CEIDG — zmiana wpisu (10 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a34.r1: pp_a34_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r1",
    "package": "jdg.micro.pp",
    "priority": 130077,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a34.r2: pp_a34_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r2",
    "package": "jdg.micro.pp",
    "priority": 130078,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a34.r3: pp_a34_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r3",
    "package": "jdg.micro.pp",
    "priority": 130079,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a34_r3_pass", false) == true
}

# jdg.micro.pp.a34.r4: pp_a34_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r4",
    "package": "jdg.micro.pp",
    "priority": 130080,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a34_r4_checks", false) == true
}

# jdg.micro.pp.a34.r5: pp_a34_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r5",
    "package": "jdg.micro.pp",
    "priority": 130081,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a34.r6: pp_a34_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r6",
    "package": "jdg.micro.pp",
    "priority": 130082,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a34.r7: pp_a34_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r7",
    "package": "jdg.micro.pp",
    "priority": 130083,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a34_exception", false) == true
}

# jdg.micro.pp.a34.r8: pp_a34_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r8",
    "package": "jdg.micro.pp",
    "priority": 130084,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a34_exception_2", false) == true
}

# jdg.micro.pp.a34.r9: pp_a34_r9_interaction_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r9",
    "package": "jdg.micro.pp",
    "priority": 130085,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: interakcja z innymi przepisami — sprawdź zależności"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_pp", false) == true
}

# jdg.micro.pp.a34.r10: pp_a34_r10_interaction_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a34.r10",
    "package": "jdg.micro.pp",
    "priority": 130086,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] CEIDG — zmiana wpisu: druga interakcja — efekt kaskadowy"]
} {
    object.get(input.jdg_entrepreneur, "cross_rule_interaction_2_pp", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pp.a36 — Kontrola przedsiębiorcy (8 reguł)                                    ║
# ║  Legal basis: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a36.r1: pp_a36_r1_eligibility
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a36.r1",
    "package": "jdg.micro.pp",
    "priority": 130087,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Kontrola przedsiębiorcy: sprawdzenie czy przepis ma zastosowanie do JDG"]
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# jdg.micro.pp.a36.r2: pp_a36_r2_positive_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a36.r2",
    "package": "jdg.micro.pp",
    "priority": 130088,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Kontrola przedsiębiorcy: warunek pozytywny — potwierdzenie zastosowania"]
} {
    object.get(input.invoice, "pp_condition_met", false) == true
}

# jdg.micro.pp.a36.r3: pp_a36_r3_positive_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a36.r3",
    "package": "jdg.micro.pp",
    "priority": 130089,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Kontrola przedsiębiorcy: drugi warunek pozytywny spełniony"]
} {
    object.get(input.jdg_entrepreneur, "pp_a36_r3_pass", false) == true
}

# jdg.micro.pp.a36.r4: pp_a36_r4_positive_3
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a36.r4",
    "package": "jdg.micro.pp",
    "priority": 130090,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Kontrola przedsiębiorcy: trzeci warunek pozytywny — walidacja"]
} {
    object.get(input.jdg_entrepreneur, "pp_a36_r4_checks", false) == true
}

# jdg.micro.pp.a36.r5: pp_a36_r5_negative_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a36.r5",
    "package": "jdg.micro.pp",
    "priority": 130091,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Kontrola przedsiębiorcy: wyłączenie — przepis NIE ma zastosowania"]
} {
    object.get(input.invoice, "pp_exclusion_applies", false) == false
}

# jdg.micro.pp.a36.r6: pp_a36_r6_negative_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a36.r6",
    "package": "jdg.micro.pp",
    "priority": 130092,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Kontrola przedsiębiorcy: drugie wyłączenie — sprawdź wyjątki"]
} {
    object.get(input.invoice, "pp_exclusion_2", false) == false
}

# jdg.micro.pp.a36.r7: pp_a36_r7_exception_1
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a36.r7",
    "package": "jdg.micro.pp",
    "priority": 130093,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Kontrola przedsiębiorcy: wyjątek — przepis ma zastosowanie mimo wyłączenia"]
} {
    object.get(input.invoice, "pp_a36_exception", false) == true
}

# jdg.micro.pp.a36.r8: pp_a36_r8_exception_2
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a36.r8",
    "package": "jdg.micro.pp",
    "priority": 130094,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Kontrola przedsiębiorcy: drugi wyjątek — szczególna sytuacja"]
} {
    object.get(input.invoice, "pp_a36_exception_2", false) == true
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PLAN OPA/50 — KLASA B — Wygenerowane masowo (50 reguł)       ║
# ║  Priorytety: 50000-50049                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.pp.a40.u1.p1 — `pp_a40_u1_p1`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a40.u1.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a40_u1_p1_check", false) == true
}
# jdg.pp.a40.u2.p2 — `pp_a40_u2_p2`: Art. 40 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a40.u2.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 40 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 40: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a40_u2_p2_check", false) == true
}
# jdg.pp.a41.u1.p2 — `pp_a41_u1_p2`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a41.u1.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a41_u1_p2_check", false) == true
}
# jdg.pp.a41.u3.p3 — `pp_a41_u3_p3`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a41.u3.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a41_u3_p3_check", false) == true
}
# jdg.pp.a41.u4.p4 — `pp_a41_u4_p4`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a41.u4.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a41_u4_p4_check", false) == true
}
# jdg.pp.a41.u5.p1 — `pp_a41_u5_p1`: Art. 41 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a41.u5.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 41 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 41: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a41_u5_p1_check", false) == true
}
# jdg.pp.a42.u2.p3 — `pp_a42_u2_p3`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a42.u2.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a42_u2_p3_check", false) == true
}
# jdg.pp.a42.u3.p4 — `pp_a42_u3_p4`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a42.u3.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a42_u3_p4_check", false) == true
}
# jdg.pp.a42.u4.p1 — `pp_a42_u4_p1`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a42.u4.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a42_u4_p1_check", false) == true
}
# jdg.pp.a42.u5.p2 — `pp_a42_u5_p2`: Art. 42 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a42.u5.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 42 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 42: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a42_u5_p2_check", false) == true
}
# jdg.pp.a43.u1.p3 — `pp_a43_u1_p3`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a43.u1.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a43_u1_p3_check", false) == true
}
# jdg.pp.a43.u2.p4 — `pp_a43_u2_p4`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a43.u2.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a43_u2_p4_check", false) == true
}
# jdg.pp.a43.u3.p1 — `pp_a43_u3_p1`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a43.u3.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a43_u3_p1_check", false) == true
}
# jdg.pp.a43.u4.p2 — `pp_a43_u4_p2`: Art. 43 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a43.u4.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 43 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 43: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a43_u4_p2_check", false) == true
}
# jdg.pp.a44.u1.p4 — `pp_a44_u1_p4`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a44.u1.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a44_u1_p4_check", false) == true
}
# jdg.pp.a44.u2.p1 — `pp_a44_u2_p1`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a44.u2.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a44_u2_p1_check", false) == true
}
# jdg.pp.a44.u3.p2 — `pp_a44_u3_p2`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a44.u3.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a44_u3_p2_check", false) == true
}
# jdg.pp.a44.u5.p3 — `pp_a44_u5_p3`: Art. 44 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a44.u5.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 44 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 44: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a44_u5_p3_check", false) == true
}
# jdg.pp.a45.u1.p1 — `pp_a45_u1_p1`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a45.u1.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a45_u1_p1_check", false) == true
}
# jdg.pp.a45.u2.p2 — `pp_a45_u2_p2`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a45.u2.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a45_u2_p2_check", false) == true
}
# jdg.pp.a45.u4.p3 — `pp_a45_u4_p3`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a45.u4.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a45_u4_p3_check", false) == true
}
# jdg.pp.a45.u5.p4 — `pp_a45_u5_p4`: Art. 45 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a45.u5.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 45 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 45: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a45_u5_p4_check", false) == true
}
# jdg.pp.a46.u1.p2 — `pp_a46_u1_p2`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a46.u1.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a46_u1_p2_check", false) == true
}
# jdg.pp.a46.u3.p3 — `pp_a46_u3_p3`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a46.u3.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a46_u3_p3_check", false) == true
}
# jdg.pp.a46.u4.p4 — `pp_a46_u4_p4`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a46.u4.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a46_u4_p4_check", false) == true
}
# jdg.pp.a46.u5.p1 — `pp_a46_u5_p1`: Art. 46 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a46.u5.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 46 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 46: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a46_u5_p1_check", false) == true
}
# jdg.pp.a47.u2.p3 — `pp_a47_u2_p3`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a47.u2.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a47_u2_p3_check", false) == true
}
# jdg.pp.a47.u3.p4 — `pp_a47_u3_p4`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a47.u3.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a47_u3_p4_check", false) == true
}
# jdg.pp.a47.u4.p1 — `pp_a47_u4_p1`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a47.u4.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a47_u4_p1_check", false) == true
}
# jdg.pp.a47.u5.p2 — `pp_a47_u5_p2`: Art. 47 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a47.u5.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 47 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 47: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a47_u5_p2_check", false) == true
}
# jdg.pp.a48.u1.p3 — `pp_a48_u1_p3`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a48.u1.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a48_u1_p3_check", false) == true
}
# jdg.pp.a48.u2.p4 — `pp_a48_u2_p4`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a48.u2.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a48_u2_p4_check", false) == true
}
# jdg.pp.a48.u3.p1 — `pp_a48_u3_p1`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a48.u3.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a48_u3_p1_check", false) == true
}
# jdg.pp.a48.u4.p2 — `pp_a48_u4_p2`: Art. 48 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a48.u4.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 48 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 48: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a48_u4_p2_check", false) == true
}
# jdg.pp.a49.u1.p4 — `pp_a49_u1_p4`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a49.u1.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a49_u1_p4_check", false) == true
}
# jdg.pp.a49.u2.p1 — `pp_a49_u2_p1`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a49.u2.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a49_u2_p1_check", false) == true
}
# jdg.pp.a49.u3.p2 — `pp_a49_u3_p2`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a49.u3.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a49_u3_p2_check", false) == true
}
# jdg.pp.a49.u5.p3 — `pp_a49_u5_p3`: Art. 49 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a49.u5.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 49 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 49: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a49_u5_p3_check", false) == true
}
# jdg.pp.a50.u1.p1 — `pp_a50_u1_p1`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a50.u1.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a50_u1_p1_check", false) == true
}
# jdg.pp.a50.u2.p2 — `pp_a50_u2_p2`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a50.u2.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a50_u2_p2_check", false) == true
}
# jdg.pp.a50.u4.p3 — `pp_a50_u4_p3`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a50.u4.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a50_u4_p3_check", false) == true
}
# jdg.pp.a50.u5.p4 — `pp_a50_u5_p4`: Art. 50 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a50.u5.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 50 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 50: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a50_u5_p4_check", false) == true
}
# jdg.pp.a51.u1.p2 — `pp_a51_u1_p2`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a51.u1.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a51_u1_p2_check", false) == true
}
# jdg.pp.a51.u3.p3 — `pp_a51_u3_p3`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a51.u3.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a51_u3_p3_check", false) == true
}
# jdg.pp.a51.u4.p4 — `pp_a51_u4_p4`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a51.u4.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a51_u4_p4_check", false) == true
}
# jdg.pp.a51.u5.p1 — `pp_a51_u5_p1`: Art. 51 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a51.u5.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 51 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 51: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a51_u5_p1_check", false) == true
}
# jdg.pp.a52.u2.p3 — `pp_a52_u2_p3`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a52.u2.p3",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a52_u2_p3_check", false) == true
}
# jdg.pp.a52.u3.p4 — `pp_a52_u3_p4`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a52.u3.p4",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a52_u3_p4_check", false) == true
}
# jdg.pp.a52.u4.p1 — `pp_a52_u4_p1`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a52.u4.p1",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a52_u4_p1_check", false) == true
}
# jdg.pp.a52.u5.p2 — `pp_a52_u5_p2`: Art. 52 → Punkt kontrolny
else := {
    "matched": true,
    "rule_id": "jdg.pp.a52.u5.p2",
    "package": "jdg.micro.pp",
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
    "_routing_reason": "[MICRO] Art. 52 — walidacja szczegółowa dla JDG",
    "_legal_basis": "Art. 36 Prawo Przedsiębiorców z 6.03.2018 (Dz.U. 2018 poz. 646)",
    "_warnings": ["[MICRO] Art. 52: punkt kontrolny — reguła wygenerowana z Plan OPA/50. Wymaga walidacji z ISAP."]
} {
    object.get(input.jdg_entrepreneur, "pp_a52_u5_p2_check", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  L-PP-2: Auto-indeksacja limitu działalności nieewidencjonowanej (5 reguł) ║
# ║  Legal basis: Art. 5 ustawy Prawo przedsiębiorców — 75% płacy minimalnej   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pp.a5index.r1: pp_a5index_r1_limit_auto_indexation_2026
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5index.r1",
    "package": "jdg.micro.pp",
    "priority": 270500,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "UNREGISTERED",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "min_wage_2026_pln": 4800,
    "limit_75pct_2026_pln": 3499.50,
    "auto_indexation": true,
    "_routing": "",
    "_routing_reason": "L-PP-2: Limit działalności nieewidencjonowanej 2026 = 3 499,50 PLN (75% z 4 666 PLN)",
    "_legal_basis": "Art. 5 ustawy Prawo przedsiębiorców — 75% minimalnego wynagrodzenia miesięcznego",
    "_warnings": ["[MICRO] L-PP-2: Limit działalności nieewidencjonowanej: 3 499,50 PLN miesięcznie w 2026 roku (75% z 4 666 PLN płacy minimalnej). Limit ZMIENIA SIĘ automatycznie z każdą zmianą płacy minimalnej! W 2025: 3 499,50 PLN (z 4 666 PLN). W 2024: 3 225 PLN (z 4 300 PLN)."]
} {
    object.get(input.jdg_entrepreneur, "is_unregistered_activity", false) == true
}

# jdg.micro.pp.a5index.r2: pp_a5index_r2_historical_limits_comparison
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5index.r2",
    "package": "jdg.micro.pp",
    "priority": 270501,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "historical_limits": [
        {"year": 2023, "min_wage": 3490, "limit": 2617.50},
        {"year": 2024, "min_wage": 4300, "limit": 3225.00},
        {"year": 2025, "min_wage": 4666, "limit": 3499.50},
        {"year": 2026, "min_wage": 4800, "limit": 3499.50}
    ],
    "_routing": "",
    "_routing_reason": "L-PP-2: Historyczne limity dla działalności nieewidencjonowanej",
    "_legal_basis": "Art. 5 PP + Obwieszczenia MRPiPS ws. minimalnego wynagrodzenia",
    "_warnings": ["[MICRO] L-PP-2: Historia limitów: 2023=2 617,50 PLN, 2024=3 225 PLN, 2025-2026=3 499,50 PLN. Limit rośnie — sprawdzaj corocznie!"]
} {
    object.get(input.jdg_entrepreneur, "unregistered_activity_limit_history_requested", false) == true
}

# jdg.micro.pp.a5index.r3: pp_a5index_r3_limit_exceeded_consequences
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5index.r3",
    "package": "jdg.micro.pp",
    "priority": 270502,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
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
    "_routing_reason": "L-PP-2: Limit przekroczony — obowiązek rejestracji CEIDG + sankcje KKS",
    "_legal_basis": "Art. 5 ust. 3 PP — utrata prawa do działalności nieewidencjonowanej",
    "_warnings": ["[MICRO] L-PP-2: PRZEKROCZENIE limitu = obowiązek NATYCHMIASTOWEJ rejestracji w CEIDG! Konsekwencje: (1) CEIDG-1 w 7 dni, (2) ZUS ZUA od dnia przekroczenia, (3) Korekta rozliczeń PIT, (4) Sankcja KKS 2 000-5 000 PLN za niezarejestrowaną działalność."]
} {
    object.get(input.jdg_entrepreneur, "unregistered_monthly_revenue_pln", 0) > 3499.50
}

# jdg.micro.pp.a5index.r4: pp_a5index_r4_annual_review_reminder
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5index.r4",
    "package": "jdg.micro.pp",
    "priority": 270503,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "next_review_date": "2027-01-01",
    "_routing": "",
    "_routing_reason": "L-PP-2: Coroczny przegląd limitu — styczeń 2027",
    "_legal_basis": "Art. 5 PP + Obwieszczenie MRPiPS o minimalnym wynagrodzeniu na 2027",
    "_warnings": ["[MICRO] L-PP-2: Pamiętaj o corocznym przeglądzie limitu! Od 1 stycznia każdego roku minimalne wynagrodzenie może się zmienić — limit automatycznie się aktualizuje. Sprawdź obwieszczenie MRPiPS na 2027."]
} {
    object.get(input, "evaluation_datetime", "") >= "2027-01-01"
    object.get(input.jdg_entrepreneur, "is_unregistered_activity", false) == true
}

# jdg.micro.pp.a5index.r5: pp_a5index_r5_spousal_income_cumulation
else := {
    "matched": true,
    "rule_id": "jdg.micro.pp.a5index.r5",
    "package": "jdg.micro.pp",
    "priority": 270504,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "L-PP-2: Kumulacja przychodów małżonków — limit łączny",
    "_legal_basis": "Art. 5 ust. 2 PP — limit dotyczy łącznych przychodów",
    "_warnings": ["[MICRO] L-PP-2: UWAGA! Limit 75% płacy minimalnej dotyczy ŁĄCZNYCH przychodów z działalności nieewidencjonowanej — Twoich i małżonka (jeśli oboje prowadzicie). Kumulacja = ryzyko przekroczenia."]
} {
    object.get(input.jdg_entrepreneur, "spouse_also_unregistered_activity", false) == true
}