# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PKPiR — §13-14 Kolumny przychodowe
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.pkpir_revenue
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pkpir_revenue

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pkpir_revenue.no_match",
    "package": "jdg.micro.pkpir_revenue",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pkpir.p13 — §13-14 Kolumny przychodowe 7-8 (10 reguł)                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pkpir_revenue.p13.r1: revenue_cash_method — przychód metodą kasową
decide := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r1",
    "package": "jdg.micro.pkpir_revenue", "priority": 80201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§13 rozporządzenia MF z 15.11.2025 r.",
    "_warnings": [sprintf("[MICRO] §13 PKPiR: Kol.7 — przychód %.2f PLN METODĄ KASOWĄ (data otrzymania zapłaty: %s)", [amount, payment_date])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "SALE"
    input.invoice.is_paid == true
    amount := object.get(input.invoice, "amount_net", 0)
    payment_date := object.get(input.invoice, "payment_date", "")
}

# jdg.micro.pkpir_revenue.p13.r2: revenue_not_paid — przychód jeszcze nieotrzymany
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r2",
    "package": "jdg.micro.pkpir_revenue", "priority": 80202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Przychód nieotrzymany — NIE wpisuj do PKPiR do momentu zapłaty!",
    "_legal_basis": "§13 ust. 1 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §13 PKPiR: Kol.7 — przychód %.2f PLN NIEOTRZYMANY. Metoda kasowa = wpisz dopiero po otrzymaniu zapłaty!", [amount])]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "SALE"
    input.invoice.is_paid == false
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_revenue.p13.r3: col_7_goods_services — kolumna 7: sprzedane towary/usługi
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r3",
    "package": "jdg.micro.pkpir_revenue", "priority": 80203,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§13 ust. 1 pkt 1 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §13 PKPiR: Kol.7 — sprzedaż towarów/usług: %.2f PLN netto (VAT czynny) / brutto (zw. VAT)", [amount])]
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"GOODS", "SERVICES", "MERCHANDISE", "IT_SERVICES"}
    input.invoice.is_paid == true
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_revenue.p13.r4: col_8_other_revenue — kolumna 8: pozostałe przychody
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r4",
    "package": "jdg.micro.pkpir_revenue", "priority": 80204,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§13 ust. 1 pkt 2 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §13 PKPiR: Kol.8 — pozostałe przychody: %.2f PLN (%s)", [amount, revenue_type])]
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"GRANTS", "REFUNDS", "OTHER_REVENUE", "COMPENSATION"}
    input.invoice.is_paid == true
    amount := object.get(input.invoice, "amount_net", 0)
    revenue_type := object.get(input.invoice, "category_code", "")
}

# jdg.micro.pkpir_revenue.p13.r5: col_9_description — kolumna 9: opis zdarzenia
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r5",
    "package": "jdg.micro.pkpir_revenue", "priority": 80205,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§14 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §14 PKPiR: Kol.9 — opis: %s", [description])]
} {
    description := object.get(input.invoice, "description", "")
    description != ""
}

# jdg.micro.pkpir_revenue.p13.r6: vat_active_net — VAT czynny = przychód netto
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r6",
    "package": "jdg.micro.pkpir_revenue", "priority": 80206,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 14 ust. 1 PIT w zw. z §13 PKPiR",
    "_warnings": [sprintf("[MICRO] §13 PKPiR × VAT: VAT czynny → przychód NETTO %.2f PLN. VAT %.2f PLN NIE jest przychodem JDG!", [net_amount, vat_amount])]
} {
    input.jdg_entrepreneur.is_vat_payer == true
    input.invoice.direction == "SALE"
    net_amount := object.get(input.invoice, "amount_net", 0)
    vat_amount := object.get(input.invoice, "vat_amount", 0)
    net_amount > 0
}

# jdg.micro.pkpir_revenue.p13.r7: vat_exempt_gross — zw. VAT = przychód brutto
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r7",
    "package": "jdg.micro.pkpir_revenue", "priority": 80207,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 14 ust. 1 PIT w zw. z §13 PKPiR",
    "_warnings": [sprintf("[MICRO] §13 PKPiR × VAT: Zwolniony z VAT → przychód BRUTTO %.2f PLN", [gross_amount])]
} {
    input.jdg_entrepreneur.is_vat_payer == false
    input.invoice.direction == "SALE"
    gross_amount := object.get(input.invoice, "amount_gross", 0)
    gross_amount > 0
}

# jdg.micro.pkpir_revenue.p13.r8: blocked_duplicate_entry — blokada zdublowanego wpisu
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r8",
    "package": "jdg.micro.pkpir_revenue", "priority": 80208,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("DUPLIKAT — faktura %s już zaksięgowana w PKPiR!", [doc_number]),
    "_legal_basis": "§13 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §13 PKPiR: BLOCK — faktura %s już istnieje w PKPiR pod LP %d!", [doc_number, lp_number])]
} {
    doc_number := object.get(input.invoice, "document_number", "")
    object.get(input.invoice, "is_duplicate_entry", false) == true
    lp_number := object.get(input.invoice, "existing_lp_number", 0)
}

# jdg.micro.pkpir_revenue.p13.r9: interaction_pit_advance — interakcja z zaliczką PIT
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r9",
    "package": "jdg.micro.pkpir_revenue", "priority": 80209,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§13 PKPiR w zw. z Art. 44 PIT",
    "_warnings": [sprintf("[MICRO] §13 PKPiR × PIT: Przychód %.2f PLN wpłynie na zaliczkę PIT. Suma miesięczna: %.2f PLN", [amount, monthly_sum])]
} {
    monthly_sum := object.get(input.jdg_entrepreneur, "pkpir_monthly_revenue", 0)
    monthly_sum > 0
    amount := object.get(input.invoice, "amount_net", 0)
}

# jdg.micro.pkpir_revenue.p13.r10: interaction_zus_health — interakcja ze składką zdrowotną
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.r10",
    "package": "jdg.micro.pkpir_revenue", "priority": 80210,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§13 PKPiR w zw. z Art. 81 ustawy o świadczeniach zdrowotnych",
    "_warnings": [sprintf("[MICRO] §13 PKPiR × ZUS: Przychód %.2f PLN → podstawa składki zdrowotnej %.2f PLN (%.0f%%)", [amount, health_base, health_rate])]
} {
    object.get(input.jdg_entrepreneur, "zus_health_annual_base", 0) > 0
    amount := object.get(input.invoice, "amount_net", 0)
    health_base := object.get(input.jdg_entrepreneur, "zus_health_annual_base_delta", 0)
    health_rate := object.get(input.jdg_entrepreneur, "zus_health_rate_pct", 9)
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_revenue.p13.fallback",
    "package": "jdg.micro.pkpir_revenue", "priority": 80299,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§13-14 rozporządzenia MF w sprawie PKPiR",
    "_warnings": ["[MICRO] PKPiR kolumny przychodowe — OK"]
} { true }
