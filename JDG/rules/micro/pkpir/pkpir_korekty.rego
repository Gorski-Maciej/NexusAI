# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PKPiR — Korekty i storna
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.pkpir_corrections
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pkpir_corrections

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pkpir_corrections.no_match",
    "package": "jdg.micro.pkpir_corrections",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pkpir.corrections — Korekty i storna w PKPiR (10 reguł)                  ║
# ║  Legal basis: §9 ust. 2 Rozp. MF PKPiR, Art. 81-81c OrdPU                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pkpir_corrections.c1.r1: storno_red_definition — definicja storna czerwonego
decide := {
    "matched": true, "rule_id": "jdg.micro.pkpir_corrections.c1.r1",
    "package": "jdg.micro.pkpir_corrections", "priority": 80601,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 2 Rozp. MF z 15.11.2025 r.",
    "_warnings": ["[MICRO] PKPiR Korekty: Storno czerwone = NOWY wiersz z kwotą ujemną. NIE przekreślać oryginału!"]
} { input.jdg_entrepreneur.uses_pkpir == true }

# jdg.micro.pkpir_corrections.c1.r2: storno_formal_requirements — wymogi formalne storna
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_corrections.c1.r2",
    "package": "jdg.micro.pkpir_corrections", "priority": 80602,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 2 Rozp. MF PKPiR",
    "_warnings": [sprintf("[MICRO] PKPiR Korekty: Storno pozycji %s — nowy wiersz LP=%d, kwota %.2f PLN (minus), kol.17: 'korekta poz. %s'", [original_lp, new_lp, amount, original_lp])]
} {
    input.invoice.correction_type == "STORNO"
    original_lp := object.get(input.invoice, "corrected_entry_id", "")
    new_lp := object.get(input.invoice, "pkpir_entry_number", 0)
    amount := object.get(input.invoice, "amount_net", 0)
    original_lp != ""
}

# jdg.micro.pkpir_corrections.c1.r3: blocked_erasure — blokada wymazywania/wyskrobywania
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_corrections.c1.r3",
    "package": "jdg.micro.pkpir_corrections", "priority": 80603,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Próba wymazania/wyskrobania wpisu PKPiR — NIEDOZWOLONE! Użyj storna!",
    "_legal_basis": "§9 ust. 2 Rozp. MF PKPiR",
    "_warnings": [sprintf("[MICRO] PKPiR Korekty: BLOCK — próba fizycznego usunięcia wpisu LP=%d. UŻYJ STORNA CZERWONEGO! Kol.17: wyjaśnij przyczynę.", [lp_number])]
} {
    object.get(input.invoice, "pkpir_erasure_attempted", false) == true
    lp_number := object.get(input.invoice, "pkpir_entry_number", 0)
}

# jdg.micro.pkpir_corrections.c1.r4: correction_revenue_down — korekta przychodu in minus
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_corrections.c1.r4",
    "package": "jdg.micro.pkpir_corrections", "priority": 80604,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 2 Rozp. MF PKPiR + Art. 14 PIT",
    "_warnings": [sprintf("[MICRO] PKPiR Korekty: Korekta przychodu -%.2f PLN (kol.7/8) — storno od zwrotu towaru/rabatu. Faktura korygująca: %s", [amount, kor_number])]
} {
    input.invoice.direction == "SALE"
    input.invoice.correction_type == "REVENUE_DOWN"
    amount := object.get(input.invoice, "amount_net", 0)
    kor_number := object.get(input.invoice, "correction_invoice_number", "")
}

# jdg.micro.pkpir_corrections.c1.r5: correction_cost_down — korekta kosztu in minus
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_corrections.c1.r5",
    "package": "jdg.micro.pkpir_corrections", "priority": 80605,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 ust. 2 Rozp. MF PKPiR + Art. 22 PIT",
    "_warnings": [sprintf("[MICRO] PKPiR Korekty: Korekta kosztu -%.2f PLN (kol.10-13) — storno przy otrzymaniu faktury korygującej od dostawcy", [amount])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.correction_type == "COST_DOWN"
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_corrections.c1.r6: correction_previous_year — korekta roku poprzedniego
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_corrections.c1.r6",
    "package": "jdg.micro.pkpir_corrections", "priority": 80606,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Korekta roku %d — wpisz w bieżącym PKPiR z datą bieżącą. Złóż korektę PIT!", [corrected_year]),
    "_legal_basis": "Art. 81-81c OrdPU, §9 ust. 2 PKPiR",
    "_warnings": [sprintf("[MICRO] PKPiR Korekty: Korekta za rok %d — %.2f PLN. (1) Wpisz w bieżącym PKPiR, (2) Kol.17: 'korekta za %d', (3) Złóż korektę zeznania PIT!", [corrected_year, amount, corrected_year])]
} {
    input.invoice.correction_for_previous_year == true
    corrected_year := object.get(input.invoice, "corrected_year", 2025)
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_corrections.c1.r7: correction_vat_impact — korekta a VAT
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_corrections.c1.r7",
    "package": "jdg.micro.pkpir_corrections", "priority": 80607,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 PKPiR + Art. 86 VAT",
    "_warnings": [sprintf("[MICRO] PKPiR × VAT: Korekta PKPiR %.2f PLN → wymaga korekty JPK_V7 za okres %s", [amount, vat_period])]
} {
    input.invoice.correction_type != ""
    input.jdg_entrepreneur.is_vat_payer == true
    amount := object.get(input.invoice, "amount_net", 0)
    vat_period := object.get(input.invoice, "vat_correction_period", "bieżący")
}

# jdg.micro.pkpir_corrections.c1.r8: exception_immaterial — wyjątek: nieistotna kwota
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_corrections.c1.r8",
    "package": "jdg.micro.pkpir_corrections", "priority": 80608,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 81 OrdPU (istotność)",
    "_warnings": [sprintf("[MICRO] PKPiR Korekty: WYJĄTEK — kwota %.2f PLN < 5 PLN. Można pominąć (nieistotna).", [amount])]
} {
    amount := object.get(input.invoice, "amount_net", 0)
    amount < 5.0
    amount > 0
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_corrections.c1.fallback",
    "package": "jdg.micro.pkpir_corrections", "priority": 80699,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§9 Rozp. MF PKPiR",
    "_warnings": ["[MICRO] PKPiR korekty — brak korekty dla tej transakcji"]
} { true }
