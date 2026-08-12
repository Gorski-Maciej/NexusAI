# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PKPiR — §15-20 Kolumny kosztowe
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.pkpir_costs
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pkpir_costs

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pkpir_costs.no_match",
    "package": "jdg.micro.pkpir_costs",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pkpir.p15 — §15-20 Kolumny kosztowe 10-13 (12 reguł)                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pkpir_costs.p15.r1: cost_date_rule — koszt w dacie poniesienia
decide := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r1",
    "package": "jdg.micro.pkpir_costs", "priority": 80301,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§15 rozporządzenia MF z 15.11.2025 r.",
    "_warnings": [sprintf("[MICRO] §15 PKPiR: Koszt %.2f PLN — data poniesienia = data faktury (%s)", [amount, invoice_date])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "PURCHASE"
    amount := object.get(input.invoice, "amount_net", 0)
    invoice_date := object.get(input.invoice, "issue_date", "")
    amount > 0
}

# jdg.micro.pkpir_costs.p15.r2: col_10_goods_materials — kolumna 10: zakup towarów
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r2",
    "package": "jdg.micro.pkpir_costs", "priority": 80302,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§16 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §16 PKPiR: Kol.10 — zakup towarów handlowych + materiałów podstawowych: %.2f PLN", [amount])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {"GOODS", "RAW_MATERIALS", "MERCHANDISE"}
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_costs.p15.r3: col_11_incidental — kolumna 11: koszty uboczne
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r3",
    "package": "jdg.micro.pkpir_costs", "priority": 80303,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§17 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §17 PKPiR: Kol.11 — koszty uboczne zakupu (transport, ubezpieczenie, cło): %.2f PLN", [amount])]
} {
    input.invoice.category_code in {"TRANSPORT_COST", "INSURANCE_COST", "CUSTOMS_DUTY"}
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_costs.p15.r4: col_12_salaries — kolumna 12: wynagrodzenia brutto
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r4",
    "package": "jdg.micro.pkpir_costs", "priority": 80304,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§18 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §18 PKPiR: Kol.12 — wynagrodzenie brutto %.2f PLN + składki ZUS pracodawcy. Wpis w dacie wypłaty.", [gross_amount])]
} {
    input.invoice.category_code in {"SALARY", "WAGES", "BONUS", "SALARY_GROSS"}
    gross_amount := object.get(input.invoice, "amount_gross", 0)
}

# jdg.micro.pkpir_costs.p15.r5: col_13_other_expenses — kolumna 13: pozostałe
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r5",
    "package": "jdg.micro.pkpir_costs", "priority": 80305,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§19 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §19 PKPiR: Kol.13 — pozostałe wydatki (czynsz, media, telefon, biuro): %.2f PLN", [amount])]
} {
    input.invoice.category_code in {"RENT", "UTILITIES", "TELECOM", "OFFICE", "IT_SERVICES", "ACCOUNTING", "LEGAL"}
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_costs.p15.r6: col_12_contributions — ZUS pracodawcy w kol.12
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r6",
    "package": "jdg.micro.pkpir_costs", "priority": 80306,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§18 ust. 2 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §18 PKPiR: Kol.12 — składki ZUS od wynagrodzeń (emerytalne, rentowe, wypadkowe, FP, FGŚP): %.2f PLN", [zus_contrib])]
} {
    zus_contrib := object.get(input.employment, "zus_employer_contributions", 0)
    zus_contrib > 0
}

# jdg.micro.pkpir_costs.p15.r7: blocked_private_expense — blokada wydatku osobistego
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r7",
    "package": "jdg.micro.pkpir_costs", "priority": 80307,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wydatek osobisty — NIE może być w kolumnach 10-13 PKPiR! Przenieś do kol. 14 (NKUP).",
    "_legal_basis": "Art. 23 PIT, §21 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §19 PKPiR: BLOCK — wydatek %s (%.2f PLN) NIEZWIĄZANY z działalnością → NKUP kol.14!", [category, amount])]
} {
    input.invoice.category_code in {"ALCOHOL", "ENTERTAINMENT", "LUXURY", "PERSONAL_EXPENSE"}
    input.invoice.direction == "PURCHASE"
    category := input.invoice.category_code
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_costs.p15.r8: blocked_cash_over_limit — blokada gotówki >15k
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r8",
    "package": "jdg.micro.pkpir_costs", "priority": 80308,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Płatność gotówkowa >15 000 PLN → NKUP (Art. 22p PIT)! Przenieś do kol.14.",
    "_legal_basis": "Art. 22p PIT, §19 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §19 PKPiR: BLOCK — gotówka %.2f PLN > 15k → NKUP kol.14! Przelew = KUP.", [amount])]
} {
    input.invoice.is_cash_payment == true
    amount := object.get(input.invoice, "amount_gross", 0)
    amount >= 15000
}

# jdg.micro.pkpir_costs.p15.r9: exception_suspension — wyjątek: koszty w zawieszeniu
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r9",
    "package": "jdg.micro.pkpir_costs", "priority": 80309,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_LIMITED", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "SUSPENDED", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§19 Rozp. MF PKPiR + Art. 22-25 Prawa przedsiębiorców",
    "_warnings": [sprintf("[MICRO] §19 PKPiR: WYJĄTEK — zawieszenie JDG. Tylko koszty stałe (czynsz, media) w kol.13. Kategoria: %s", [category])]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {"RENT", "UTILITIES", "SECURITY", "LEASE_EXISTING", "INSURANCE", "ACCOUNTING"}
    category := input.invoice.category_code
}

# jdg.micro.pkpir_costs.p15.r10: interaction_direct_indirect — koszty bezpośrednie vs pośrednie
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.r10",
    "package": "jdg.micro.pkpir_costs", "priority": 80310,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 5-5c PIT",
    "_warnings": [sprintf("[MICRO] PKPiR × PIT: Koszt %s %.2f PLN — %s. Data potrącenia: %s", [cost_type, amount, timing_rule, deduction_date])]
} {
    is_direct := object.get(input.invoice, "is_direct_cost", false)
    cost_type = "BEZPOŚREDNI" { is_direct == true }
    cost_type = "POŚREDNI" { is_direct == false }
    timing_rule = "w roku uzyskania przychodu" { is_direct == true }
    timing_rule = "w dacie poniesienia (faktury)" { is_direct == false }
    amount := object.get(input.invoice, "amount_net", 0)
    deduction_date := object.get(input.invoice, "deduction_date", "")
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_costs.p15.fallback",
    "package": "jdg.micro.pkpir_costs", "priority": 80399,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§15-20 rozporządzenia MF w sprawie PKPiR",
    "_warnings": ["[MICRO] PKPiR kolumny kosztowe — OK"]
} { true }
