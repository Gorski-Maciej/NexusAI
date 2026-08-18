# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PKPiR — §9 Chronologia zapisów
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.pkpir
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pkpir

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pkpir.no_match",
    "package": "jdg.micro.pkpir",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pkpir.p9 — §9 Chronologia zapisów (10 reguł)                            ║
# ║  Legal basis: Rozp. MF z 15.11.2025 r. w sprawie PKPiR                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pkpir.p9.r1: pkpir_p9_r1_eligibility — JDG na skali/liniowym
decide := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r1",
    "package": "jdg.micro.pkpir", "priority": 80001,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO] §9 PKPiR: sprawdzenie czy JDG prowadzi PKPiR"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
}

# jdg.micro.pkpir.p9.r2: pkpir_p9_r2_chronological_order — zapis chronologiczny
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r2",
    "package": "jdg.micro.pkpir", "priority": 80002,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 1 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO] §9 PKPiR: zapisy muszą być chronologiczne — data bieżąca ≥ data ostatniego wpisu"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    object.get(input.invoice, "pkpir_date_chronological", true) == true
}

# jdg.micro.pkpir.p9.r3: pkpir_p9_r3_no_gaps — brak pustych wierszy
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r3",
    "package": "jdg.micro.pkpir", "priority": 80003,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 1 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO] §9 PKPiR: brak pustych wierszy między zapisami"]
} {
    object.get(input.jdg_entrepreneur, "pkpir_no_gaps", true) == true
}

# jdg.micro.pkpir.p9.r4: pkpir_p9_r4_no_erasures — zakaz przeróbek/wymazywania
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r4",
    "package": "jdg.micro.pkpir", "priority": 80004,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 2 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO] §9 PKPiR: zakaz przeróbek, wymazywania, wyskrobywania — błędy poprawiaj przez STORNO"]
} {
    object.get(input.jdg_entrepreneur, "pkpir_no_erasures", true) == true
}

# jdg.micro.pkpir.p9.r5: pkpir_p9_r5_blocked_dates — data nie może być wcześniejsza niż ostatni wpis
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r5",
    "package": "jdg.micro.pkpir", "priority": 80005,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Data wcześniejsza niż ostatni zapis PKPiR — naruszenie chronologii",
    "_legal_basis": "§9 ust. 1 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": [sprintf("[MICRO] §9 PKPiR: data %s jest wcześniejsza niż ostatni zapis %s — NARUSZENIE CHRONOLOGII!", [entry_date, last_date])]
} {
    entry_date := object.get(input.invoice, "transaction_date", "")
    last_date := object.get(input.jdg_entrepreneur, "pkpir_last_entry_date", "2000-01-01")
    entry_date < last_date
    entry_date != ""
}

# jdg.micro.pkpir.p9.r6: pkpir_p9_r6_page_summary — podsumowanie strony
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r6",
    "package": "jdg.micro.pkpir", "priority": 80006,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 3 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO] §9 PKPiR: podsumowanie strony — suma kolumn na dole strony + przeniesienie na następną"]
} {
    input.invoice.end_of_day_summary == true
}

# jdg.micro.pkpir.p9.r7: pkpir_p9_r7_exception_correction_year — wyjątek: korekta roku poprzedniego
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r7",
    "package": "jdg.micro.pkpir", "priority": 80007,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 2 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO] §9 PKPiR: wyjątek — korekta roku poprzedniego może mieć wcześniejszą datę"]
} {
    input.invoice.correction_for_previous_year == true
}

# jdg.micro.pkpir.p9.r8: pkpir_p9_r8_exception_storno — wyjątek: storno czerwone
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r8",
    "package": "jdg.micro.pkpir", "priority": 80008,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 2 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO] §9 PKPiR: storno czerwone — kwota ujemna w nowym wierszu, nie przekreślać oryginału"]
} {
    input.invoice.correction_type == "STORNO"
}

# jdg.micro.pkpir.p9.r9: pkpir_p9_r9_interaction_vat — interakcja z ewidencją VAT
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r9",
    "package": "jdg.micro.pkpir", "priority": 80009,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 w zw. z Art. 109 VAT",
    "_warnings": ["[MICRO] §9 PKPiR: interakcja z ewidencją VAT — dane muszą być spójne z JPK_V7"]
} {
    input.jdg_entrepreneur.is_vat_payer == true
    object.get(input.jdg_entrepreneur, "pkpir_vat_consistent", true) == false
}

# jdg.micro.pkpir.p9.r10: pkpir_p9_r10_interaction_jpk — interakcja z JPK
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.r10",
    "package": "jdg.micro.pkpir", "priority": 80010,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów + Art. 193a OrdPU",
    "_warnings": ["[MICRO] §9 PKPiR: JPK na żądanie — PKPiR musi być elektronicznie odtwarzalna"]
} {
    object.get(input.jdg_entrepreneur, "jpk_na_zadanie_requested", false) == true
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir.p9.fallback",
    "package": "jdg.micro.pkpir", "priority": 80099,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO] §9 PKPiR: zapis chronologiczny — OK, brak naruszeń"]
} {
    true
}
