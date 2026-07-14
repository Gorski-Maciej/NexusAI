# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — PIT: KUP — wyłączenia i ograniczenia (P560-P582)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: PIT KUP — Deductible Costs: Exclusions, Limits, Bad Debt
# description: |
#   PAS 5b Multi-Pass. First-Match-Wins else-chain. Kolejność: najbardziej
#   restrykcyjne → najmniej: reprezentacja NKUP (P566), niezapłacone ZUS (P568),
#   auto >150k (P564), EV >225k (P565), mieszane prywatno-firmowe (P562),
#   składka zdrowotna liniowy max 12900 (P570), złe długi dłużnika 90 dni (P571),
#   ZUS społeczne KUP (P561), full KUP catch-all (P560).
# architecture: Multi-Pass PAS 5b (ADR-001)
# legal_basis: Art. 22-23, 30c PIT
# edge_cases:
#   - P564: amount_net > 150k → KUP ograniczony do 150k/amount*100%
#   - P571: dłużnik >90 dni → BLOCK_AND_ALERT, OBOWIĄZKOWE NKUP
# package: jdg.pit.kup
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
#
# First-Match-Wins else-chain
# Podstawa: Doc 34 Sec 4.6 + Doc 33 (Art. 22-23 PIT)
#
# Kolejność reguł: Od najbardziej restrykcyjnych (NKUP) do najmniej (pełny KUP)
# Pierwsze reguły to WYŁĄCZENIA z KUP (najpierw sprawdzamy czy NIE KUP)
# Ostatnia reguła to pełny KUP (catch-all)
#
# package: jdg.pit.kup
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.kup

import data.jdg.helpers

# ── Default ────────────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.pit.kup.no_match",
    "package": "jdg.pit.kup",
    "priority": 592
}

# ═══════════════════════════════════════════════════════════════════════════════
# P566: kup_representation_none — Reprezentacja → NKUP
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.pit.kup.representation_none",
    "package": "jdg.pit.kup", "priority": 566,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "Reprezentacja → NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT",
    "_warnings": ["Wydatki na reprezentację — CAŁKOWICIE wyłączone z KUP"]
} {
    input.invoice.expense_type in {"REPRESENTATION", "ENTERTAINMENT", "LUXURY"}
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P568: kup_unpaid_zus_social — Niezapłacone składki ZUS → NKUP
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup.unpaid_zus_social",
    "package": "jdg.pit.kup", "priority": 568,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "Niezapłacone ZUS → NKUP",
    "_legal_basis": "Art. 22 ust. 6ba PIT",
    "_warnings": ["Niezapłacone składki ZUS społeczne — NIE stanowią KUP do momentu zapłaty"]
} {
    input.invoice.expense_type == "ZUS_SOCIAL_ENTREPRENEUR"
    input.invoice.is_paid == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P564: kup_car_over_150k_limit — Auto > 150k PLN → ograniczony KUP
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup.car_over_150k",
    "package": "jdg.pit.kup", "priority": 564,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "limited_car_150k", "kus_percent": ku_percent,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 47a PIT",
    "_warnings": [sprintf("Auto > limit KUP — ograniczenie %.0f PLN z %.0f PLN (%.0f%%)", [150000, amount_net, floor(150000/amount_net*100)])]
} {
    input.invoice.category_code == "CAR"
    input.invoice.amount_net > 150000
    amount_net := object.get(input.invoice, "amount_net", 0)
    ku_percent := floor(150000 / amount_net * 100)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P565: car_electric_225k_kup — Auto elektryczne → limit 225k PLN
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup.car_electric_225k",
    "package": "jdg.pit.kup", "priority": 565,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "limited_car_225k", "kus_percent": ku_percent,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 47a PIT (wyjątek EV)",
    "_warnings": []
} {
    input.invoice.category_code == "CAR"
    input.invoice.is_electric == true
    input.invoice.has_ev_subsidy == false
    input.invoice.amount_net > 225000
    amount_net := object.get(input.invoice, "amount_net", 0)
    ku_percent := floor(225000 / amount_net * 100)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P562: kup_private_mixed_jdg — Wydatki mieszane prywatno-firmowe
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup.private_mixed_jdg",
    "package": "jdg.pit.kup", "priority": 562,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "partial", "kus_percent": ku_percent,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 1 PIT",
    "_warnings": [sprintf("Wydatek mieszany — KUP %.0f%% (część firmowa)", [ku_percent])]
} {
    private_pct := object.get(input.invoice, "private_use_percent", 0)
    private_pct > 0
    private_pct < 100
    ku_percent := 100 - private_pct
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P570: kup_health_contrib_linear_deduction — Składka zdrowotna przy liniowym
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup.health_linear_deduction",
    "package": "jdg.pit.kup", "priority": 570,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "partial_health_limit", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "zus_health_annual_limit": 12900, "zus_health_deductible_from_income": true,
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 12900,
    "relief_deductible": min([health_paid, 12900]),
    "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 30c ust. 2 pkt 2 PIT",
    "_warnings": [sprintf("Składka zdrowotna liniowy — odliczenie od dochodu max 12 900 PLN (zapłacono %.2f)", [health_paid])]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    input.invoice.expense_type == "ZUS_HEALTH_ENTREPRENEUR"
    input.invoice.is_paid == true
    health_paid := object.get(input.jdg_entrepreneur, "cumulative_zus_health_paid", 0)
    health_paid > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P571: kup_bad_debt_pit_debtor — Złe długi PIT — OBOWIĄZEK dłużnika
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup.bad_debt_debtor",
    "package": "jdg.pit.kup", "priority": 571,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Niezapłacona faktura > 90 dni — OBOWIĄZEK wyłączenia z KUP",
    "_legal_basis": "Art. 22 ust. 8-10 PIT",
    "_warnings": ["Niezapłacona faktura > 90 dni — OBOWIĄZKOWE wyłączenie z KUP!"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.is_paid == false
    input.invoice.days_overdue >= 90
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P572: kup_direct_vs_indirect_timing — KUP bezpośrednie vs pośrednie
# Doc 26 §III: DIRECT = rok przychodu, INDIRECT = data poniesienia
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup.direct_vs_indirect",
    "package": "jdg.pit.kup", "priority": 572,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "full", "kus_percent": 100,
    "kup_timing": kup_timing,
    "kus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 5-5c PIT",
    "_warnings": [sprintf("KUP %s — potrącenie w %s", [kup_timing, timing_note])]
} {
    input.invoice.direction == "PURCHASE"
    expense_type := object.get(input.invoice, "expense_type", "")
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Wyklucz składki ZUS — obsługiwane przez P561 i P568
    expense_type not in {"ZUS_SOCIAL_ENTREPRENEUR", "ZUS_HEALTH_ENTREPRENEUR"}

    # DIRECT: Koszty bezpośrednio związane z przychodem (COGS, materiały, towary)
    is_direct = true { expense_type in {"COGS", "MATERIALS_DIRECT", "GOODS_FOR_RESALE"} }
    is_direct = false { expense_type not in {"COGS", "MATERIALS_DIRECT", "GOODS_FOR_RESALE"} }

    kup_timing = "REVENUE_YEAR" { is_direct == true }
    kup_timing = "INVOICE_YEAR" { is_direct == false }
    timing_note = "roku osiągnięcia odpowiadającego przychodu" { is_direct == true }
    timing_note = "dacie poniesienia (data faktury)" { is_direct == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P561: kup_zus_social_deductible — Składki ZUS społeczne → KUP
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup.zus_social_deductible",
    "package": "jdg.pit.kup", "priority": 561,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 1 w zw. z art. 23 ust. 1 pkt 37 PIT",
    "_warnings": []
} {
    input.invoice.expense_type == "ZUS_SOCIAL_ENTREPRENEUR"
    input.invoice.is_paid == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P560: kup_full_deductible — Pełny KUP (catch-all dla wydatków firmowych)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.kup.full_deductible",
    "package": "jdg.pit.kup", "priority": 560,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 1 PIT",
    "_warnings": []
} {
    input.invoice.direction == "PURCHASE"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}
