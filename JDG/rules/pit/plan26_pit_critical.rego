# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Plan 26 PIT: Critical Rules (P30 Audit Gap Fix)
# ═══════════════════════════════════════════════════════════════════════════════
# METADATA
# title: PIT Critical Rules — Plan 26 Extended Implementation (P30)
# description: |
#   Rozszerza plan26_detailed.rego (2 reguły → pełna warstwa)
#   + pokrywa luki P30: L3 (NKUP 57 pkt), L4 (Exit Tax 4M),
#   L7 (rehabilitacyjna), L8 (prototyp/ekspansja/robotyzacja),
#   L9 (kwota zmniejszająca 3 600), L10 (ulga prorodzinna),
#   L11 (mały podatnik PIT), L16 (CFC agregacja)
# package: jdg.pit.plan26_critical
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.plan26_critical

import future.keywords.in
import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.pit.plan26_critical.no_match",
    "package": "jdg.pit.plan26_critical",
    "priority": 999
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-1: Tax Bracket Precision Engine — Skala 12%/32% z kwotą zmniejszającą
# Art. 27 PIT: degresja kwoty wolnej 30k-120k, kwota zmniejszająca 3 600 PLN
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.tax_bracket_precision",
    "package": "jdg.pit.plan26_critical", "priority": 1,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "TAX_BRACKET_PRECISION",
    "pit_form": "PIT_SCALE", "pit_rate": "",
    "pit_bracket": bracket_label,
    "pit_annual_return_type": "PIT_36",
    "pit_tax_calculated": tax_amount,
    "pit_reducing_amount": reducing_amount,
    "pit_tax_free_degression_applied": degression_applied,
    "tax_free_degression_start": thresholds.pit.tax_free_amount_degression_start,
    "tax_free_degression_end": thresholds.pit.tax_free_amount_degression_end,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 27 PIT",
    "_warnings": warnings
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)

    tax_free_amount := thresholds.pit.tax_free_amount
    scale_threshold := thresholds.pit.scale_threshold
    reducing_base := thresholds.pit.tax_reducing_amount

    # Degresja kwoty zmniejszającej: 3 600 przy 30 000 → 0 przy 120 000
    degression_applied = true { annual_income > tax_free_amount; annual_income < scale_threshold }
    degression_applied = false { annual_income <= tax_free_amount }

    reducing_amount = reducing_base { annual_income <= tax_free_amount }
    reducing_amount = reducing_base * (scale_threshold - annual_income) / (scale_threshold - tax_free_amount) { degression_applied }
    reducing_amount = 0 { annual_income >= scale_threshold }

    # Obliczenie podatku: 12% do 120k, 32% powyżej
    tax_low := annual_income * thresholds.pit.scale_low_rate { annual_income <= scale_threshold }
    tax_low := scale_threshold * thresholds.pit.scale_low_rate { annual_income > scale_threshold }
    tax_high := (annual_income - scale_threshold) * thresholds.pit.scale_high_rate { annual_income > scale_threshold }
    tax_high := 0 { annual_income <= scale_threshold }

    tax_before_reduction := tax_low + tax_high
    tax_amount := tax_before_reduction - reducing_amount { tax_before_reduction > reducing_amount }
    tax_amount := 0 { tax_before_reduction <= reducing_amount }

    bracket_label = "LOW (12%)" { annual_income <= scale_threshold }
    bracket_label = sprintf("HIGH (12%% do %d PLN + 32%% powyżej)", [scale_threshold]) { annual_income > scale_threshold }

    routing = "TRIAGE_QUEUE" { annual_income > scale_threshold - 100; annual_income < scale_threshold + 100 }
    routing = "" { annual_income <= scale_threshold - 100 }
    routing = "" { annual_income >= scale_threshold + 100 }
    routing_reason = sprintf("PRÓG SKALI %.2f PLN ≈ %d PLN — weryfikuj stawki", [annual_income, scale_threshold]) { annual_income > scale_threshold - 100; annual_income < scale_threshold + 100 }
    routing_reason = "" { annual_income <= scale_threshold - 100 }

    warnings = [sprintf("SKALA PIT — dochód %.2f PLN, próg %d PLN, podatek %.2f PLN, kwota zmniejszająca %.2f PLN, degresja: %s", [annual_income, scale_threshold, tax_amount, reducing_amount, to_string(degression_applied)])]
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-2: Exit Tax 4M Threshold + Kalkulacja (P30 L4, L17)
# Art. 30da PIT: 19% od niezrealizowanych zysków > 4 000 000 PLN
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.exit_tax_4m_threshold",
    "package": "jdg.pit.plan26_critical", "priority": 2,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "EXIT_TAX_CHECK",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "exit_tax_applicable": tax_applicable,
    "exit_tax_market_value": market_value,
    "exit_tax_threshold_4m": thresholds.pit.exit_tax_threshold,
    "exit_tax_amount_19pct": tax_amount,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 30da PIT",
    "_warnings": warnings
} {
    input.jdg_entrepreneur.has_asset_transfer_abroad == true
    market_value := object.get(input.jdg_entrepreneur, "asset_transfer_market_value", 0)
    tax_threshold := thresholds.pit.exit_tax_threshold
    tax_rate := thresholds.pit.exit_tax_rate

    tax_applicable = true { market_value > tax_threshold }
    tax_applicable = false { market_value <= tax_threshold }

    unrealized_gains := object.get(input.jdg_entrepreneur, "asset_unrealized_gains", 0)
    tax_amount = unrealized_gains * tax_rate { tax_applicable }
    tax_amount = 0 { not tax_applicable }

    routing = "BLOCK_AND_ALERT" { tax_applicable }
    routing = "" { not tax_applicable }
    routing_reason = sprintf("EXIT TAX — wartość rynkowa %.2f PLN > %.0f PLN. Podatek 19%% = %.2f PLN. Obowiązek zgłoszenia przed przeniesieniem!", [market_value, tax_threshold, tax_amount]) { tax_applicable }
    routing_reason = "" { not tax_applicable }

    warnings = [sprintf("EXIT TAX Art. 30da — przeniesienie aktywów %.2f PLN (próg %.0f PLN). Podatek: %.2f PLN (19%% od %.2f PLN niezrealizowanych zysków).", [market_value, tax_threshold, tax_amount, unrealized_gains])] { tax_applicable }
    warnings = [] { not tax_applicable }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-3: NKUP Extended — Punkty 30-57 + niewypłacone wynagrodzenia (P30 L3, S16)
# Art. 23 ust. 1 PIT: rozszerzona lista NKUP (brakujące punkty)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.nkup_extended_points",
    "package": "jdg.pit.plan26_critical", "priority": 3,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "NKUP_EXTENDED_CHECK",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "nkup_point": nkup_point,
    "nkup_reason": nkup_reason,
    "nkup_blocked": nkup_blocked,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 23 ust. 1 PIT",
    "_warnings": warnings
} {
    input.invoice.expense_type == "COST"
    category := object.get(input.invoice, "nkup_category", "")

    # Rozszerzona mapa NKUP (brakujące punkty 30-57 z P30 L3)
    nkup_extended := {
        "unpaid_wages_p55": {"point": "55", "desc": "Niewypłacone wynagrodzenia po terminie (Art. 23 ust. 1 pkt 55)"},
        "unpaid_zus_p57": {"point": "57", "desc": "Nieopłacone składki ZUS (Art. 23 ust. 1 pkt 57)"},
        "private_car_no_km_p46": {"point": "46", "desc": "Samochód prywatny bez ewidencji — tylko 20% (Art. 23 ust. 1 pkt 46)"},
        "fines_penalties_p16": {"point": "16", "desc": "Kary i grzywny sądowe/administracyjne (Art. 23 ust. 1 pkt 16)"},
        "alcohol_entertainment_p17": {"point": "17", "desc": "Alkohol na cele reprezentacji (Art. 23 ust. 1 pkt 17)"},
        "depreciation_write_off_p21": {"point": "21", "desc": "Odpisy amortyzacyjne od wartości niematerialnych (Art. 23 ust. 1 pkt 21)"},
        "training_non_qualifying_p23": {"point": "23", "desc": "Szkolenia niekwalifikowane jako B+R (Art. 23 ust. 1 pkt 23)"},
    }

    nkup_point := nkup_extended[category].point
    nkup_reason := nkup_extended[category].desc
    nkup_blocked = true

    routing = "BLOCK_AND_ALERT"
    routing_reason = sprintf("NKUP — Art. 23 ust. 1 pkt %s: %s", [nkup_point, nkup_reason])
    warnings = [sprintf("⚠️ NKUP Art. 23 ust. 1 pkt %s — %s. Wydatek %.2f PLN NIE stanowi kosztu uzyskania przychodu.", [nkup_point, nkup_reason, amount])]

    amount := object.get(input.invoice, "amount_net", 0)
    category in nkup_extended
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-4: Ulga rehabilitacyjna Art. 26 (P30 L7) — 9 rodzajów wydatków
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.rehabilitation_relief_art26",
    "package": "jdg.pit.plan26_critical", "priority": 4,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "REHABILITATION_RELIEF",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT_36",
    "rehab_relief_type": relief_type,
    "rehab_relief_amount": relief_amount,
    "rehab_relief_limited": relief_capped,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 pkt 6 PIT",
    "_warnings": [sprintf("ULGA REHABILITACYJNA — %s, kwota %.2f PLN (limit: %.2f PLN)", [relief_type, relief_amount, relief_limit])]
} {
    input.jdg_entrepreneur.has_disability_certificate == true
    expense_type := object.get(input.invoice, "rehab_expense_type", "")

    rehab_types := {
        "REHAB_DRUGS": {"limit": 2280, "desc": "Leki (różnica ponad 100 PLN/mies)"},
        "REHAB_ADAPTATION": {"limit": 15000, "desc": "Adaptacja mieszkania/pojazdu"},
        "REHAB_CARE": {"limit": 2280, "desc": "Opieka pielęgniarska"},
        "REHAB_TRANSPORT": {"limit": 2280, "desc": "Przejazdy na zabiegi"},
        "REHAB_EQUIPMENT": {"limit": 5000, "desc": "Sprzęt rehabilitacyjny"},
        "REHAB_TURNUS": {"limit": 2280, "desc": "Turnus rehabilitacyjny"},
        "REHAB_GUIDE_DOG": {"limit": 2280, "desc": "Pies przewodnik"},
        "REHAB_JOURNALS": {"limit": 760, "desc": "Prenumerata specjalistyczna"},
        "REHAB_INTERPRETER": {"limit": 5000, "desc": "Tłumacz języka migowego"},
    }

    relief_limit := rehab_types[expense_type].limit
    relief_type := rehab_types[expense_type].desc
    relief_amount_raw := object.get(input.invoice, "amount_net", 0)
    relief_capped = true { relief_amount_raw > relief_limit }
    relief_capped = false { relief_amount_raw <= relief_limit }
    relief_amount = relief_limit { relief_capped }
    relief_amount = relief_amount_raw { not relief_capped }

    expense_type in rehab_types
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-5: Ulgi innowacyjne: Prototyp (26eb/30%), Robotyzacja (26gb/50%), Ekspansja (26ec)
# P30 L8
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.innovation_reliefs",
    "package": "jdg.pit.plan26_critical", "priority": 5,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "INNOVATION_RELIEFS",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT_36",
    "innovation_relief_type": relief_type,
    "innovation_relief_rate": relief_rate,
    "innovation_relief_amount": relief_amount,
    "innovation_relief_max": relief_max,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26eb/26ec/26gb PIT",
    "_warnings": [sprintf("ULGA INNOWACYJNA — %s, stawka %.0f%%, kwota %.2f PLN (max %.2f PLN)", [relief_type, relief_rate*100, relief_amount, relief_max])]
} {
    input.invoice.expense_type == "COST"
    innovation_type := object.get(input.invoice, "innovation_relief_type", "")

    # Ulga na prototyp (Art. 26eb): 30% kosztów kwalifikowanych
    # Ulga na ekspansję (Art. 26ec): wzrost przychodów ze sprzedaży
    # Ulga na robotyzację (Art. 26gb): 50% kosztów
    innovation_reliefs := {
        "PROTOTYPE": {"rate": thresholds.pit.prototype_relief_rate, "max": 0, "desc": "Ulga na prototyp (Art. 26eb)"},
        "ROBOTIZATION": {"rate": thresholds.pit.robotization_relief_rate, "max": 0, "desc": "Ulga na robotyzację (Art. 26gb)"},
        "EXPANSION": {"rate": 1.0, "max": thresholds.pit.expansion_relief_max_costs, "desc": "Ulga na ekspansję (Art. 26ec)"},
    }

    relief_rate := innovation_reliefs[innovation_type].rate
    relief_max := innovation_reliefs[innovation_type].max
    relief_type := innovation_reliefs[innovation_type].desc

    qualifying_costs := object.get(input.invoice, "amount_net", 0)
    relief_amount = qualifying_costs * relief_rate { relief_max == 0 }
    relief_amount = qualifying_costs * relief_rate { qualifying_costs <= relief_max; relief_max > 0 }
    relief_amount = relief_max * relief_rate { qualifying_costs > relief_max; relief_max > 0 }

    innovation_type in innovation_reliefs
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-6: Ulga prorodzinna Art. 27f — kwota 1 112.04 PLN/dziecko (P30 L10)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.family_relief_art27f",
    "package": "jdg.pit.plan26_critical", "priority": 6,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "FAMILY_RELIEF",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT_36",
    "family_relief_children": children_count,
    "family_relief_per_child": per_child_amount,
    "family_relief_total": total_relief,
    "family_relief_income_limit": income_limit_check,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 27f PIT",
    "_warnings": [sprintf("ULGA PRORODZINNA — %d dzieci × %.2f PLN = %.2f PLN odliczenia od podatku", [children_count, per_child_amount, total_relief])]
} {
    input.jdg_entrepreneur.has_children == true
    children_count := object.get(input.jdg_entrepreneur, "children_count", 0)
    per_child_amount := thresholds.pit.family_relief_amount_per_child
    total_relief := children_count * per_child_amount

    children_count > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-7: Mały podatnik PIT (Art. 5a pkt 20, P30 L11)
# Limit 2 000 000 EUR przychodu rocznego
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.small_taxpayer_pit",
    "package": "jdg.pit.plan26_critical", "priority": 7,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "SMALL_TAXPAYER_CHECK",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "small_taxpayer_status": taxpayer_status,
    "small_taxpayer_revenue_eur": revenue_eur,
    "small_taxpayer_revenue_pln": revenue_pln,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 5a pkt 20 PIT",
    "_warnings": [sprintf("MAŁY PODATNIK PIT — przychód %.2f EUR (%.2f PLN), limit 2M EUR. Status: %s", [revenue_eur, revenue_pln, taxpayer_status])]
} {
    input.jdg_entrepreneur.tax_form in {"PIT_SCALE", "LINEAR"}

    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_net", 0)
    eur_rate := thresholds.bounds.eur_pln

    revenue_eur = annual_revenue / eur_rate { eur_rate > 0 }
    revenue_eur = annual_revenue / 4.50 { eur_rate == 0 }
    revenue_pln = annual_revenue

    threshold_eur := thresholds.pit.small_taxpayer_pit_limit_eur
    taxpayer_status = "SMALL" { revenue_eur <= threshold_eur }
    taxpayer_status = "REGULAR" { revenue_eur > threshold_eur }

    routing = "TRIAGE_QUEUE" { revenue_eur > threshold_eur * 0.95; revenue_eur <= threshold_eur }
    routing = "" { revenue_eur <= threshold_eur * 0.95 }
    routing = "" { revenue_eur > threshold_eur }
    routing_reason = sprintf("MAŁY PODATNIK PIT — blisko limitu 2M EUR: %.2f EUR (%.1f%%)", [revenue_eur, revenue_eur / threshold_eur * 100]) { revenue_eur > threshold_eur * 0.95; revenue_eur <= threshold_eur }
    routing_reason = "" { revenue_eur <= threshold_eur * 0.95 }
    routing_reason = "" { revenue_eur > threshold_eur }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-8: CFC Agregacja + Odliczenie podatku zagranicznego (P30 L16)
# Art. 30f ust. 6-7 PIT: agregacja kilku spółek CFC
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.cfc_aggregation",
    "package": "jdg.pit.plan26_critical", "priority": 8,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "CFC_AGGREGATION",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "cfc_entities_count": entities_count,
    "cfc_passive_income_aggregated": total_passive_income,
    "cfc_foreign_tax_credit": foreign_tax_credit,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 30f ust. 6-7 PIT",
    "_warnings": [sprintf("CFC — %d spółek, łączny dochód pasywny %.2f PLN, kredyt podatkowy %.2f PLN", [entities_count, total_passive_income, foreign_tax_credit])]
} {
    input.jdg_entrepreneur.has_cfc_entities == true
    cfc_entities := object.get(input.jdg_entrepreneur, "cfc_entities", [])

    entities_count := count(cfc_entities)

    # Agregacja pasywnego dochodu ze wszystkich CFC
    total_passive_income := sum([e.passive_income | some e in cfc_entities])

    # Odliczenie podatku zapłaconego za granicą (Art. 30f ust. 7)
    foreign_tax_paid := sum([e.foreign_tax_paid | some e in cfc_entities])
    foreign_tax_credit = foreign_tax_paid { foreign_tax_paid > 0 }
    foreign_tax_credit = 0 { foreign_tax_paid == 0 }

    routing = "TRIAGE_QUEUE" { entities_count > 0 }
    routing = "" { entities_count == 0 }
    routing_reason = sprintf("CFC — %d spółek zagranicznych. Dochód pasywny: %.2f PLN. Podatek zagraniczny: %.2f PLN.", [entities_count, total_passive_income, foreign_tax_credit]) { entities_count > 0 }
    routing_reason = "" { entities_count == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-9: Reprezentacja — NKUP w całości w PIT (P30 L5, S13)
# Art. 23 ust. 1 pkt 28 PIT: wydatki reprezentacyjne są NKUP w CAŁOŚCI
# (limit 0.25% dotyczy CIT, NIE PIT!)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.representation_nkup_full",
    "package": "jdg.pit.plan26_critical", "priority": 9,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "REPRESENTATION_NKUP_CHECK",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "representation_amount": amount,
    "representation_nkup_full": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "REPREZENTACJA — NKUP w całości w PIT (Art. 23 ust. 1 pkt 28). Limit 0.25% dotyczy TYLKO CIT!",
    "_legal_basis": "Art. 23 ust. 1 pkt 28 PIT",
    "_warnings": [sprintf("⚠️ REPREZENTACJA PIT — %.2f PLN NKUP w całości! Art. 23 ust. 1 pkt 28 PIT: reprezentacja zawsze NKUP. Limit 0.25%% dotyczy CIT (Art. 16 ust. 1 pkt 28a CIT), NIE PIT.", [amount])]
} {
    input.invoice.expense_type == "COST"
    input.invoice.category_code in {"REPRESENTATION", "ENTERTAINMENT", "BUSINESS_MEALS"}
    amount := object.get(input.invoice, "amount_net", 0)
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-10: Art. 3 — Rezydencja podatkowa (183 dni, P30 Art. 3 luka)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.tax_residency_art3",
    "package": "jdg.pit.plan26_critical", "priority": 10,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "TAX_RESIDENCY_CHECK",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "residency_days_in_pl": days_in_pl,
    "residency_183_days_exceeded": days_exceeded,
    "residency_status": residency_status,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 3 ust. 1a-2a PIT",
    "_warnings": [sprintf("REZYDENCJA PODATKOWA — %d dni w PL, próg 183 dni: %s, status: %s", [days_in_pl, to_string(days_exceeded), residency_status])]
} {
    input.jdg_entrepreneur.has_foreign_connections == true
    days_in_pl := object.get(input.jdg_entrepreneur, "days_in_poland_current_year", 0)

    days_exceeded = true { days_in_pl >= 183 }
    days_exceeded = false

    residency_status = "PL_TAX_RESIDENT" { days_exceeded }
    residency_status = "NON_RESIDENT" { not days_exceeded }

    routing = "TRIAGE_QUEUE" { days_in_pl >= 170; days_in_pl < 183 }
    routing = "" { days_in_pl < 170 }
    routing = "" { days_in_pl >= 183 }
    routing_reason = sprintf("REZYDENCJA — %d dni w PL, blisko progu 183 dni (Art. 3 PIT)", [days_in_pl]) { days_in_pl >= 170; days_in_pl < 183 }
    routing_reason = "" { days_in_pl < 170 }
    routing_reason = "" { days_in_pl >= 183 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-11: Ulga termomodernizacyjna — limit 53k + 2 przedsięwzięcia / 3 lata (P30 L19)
# Art. 26h PIT: max 53 000 PLN, max 2 przedsięwzięcia, okno 3-letnie
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.thermo_relief_3year_window",
    "package": "jdg.pit.plan26_critical", "priority": 11,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "THERMO_RELIEF_3Y_CHECK",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT_36",
    "thermo_total_limit_53000": total_limit,
    "thermo_projects_in_window": project_count,
    "thermo_max_projects_2": max_projects,
    "thermo_window_years": window_years,
    "thermo_relief_spent": total_spent,
    "thermo_remaining": remaining_cap,
    "thermo_exceeded": cap_exceeded,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 26h PIT",
    "_warnings": warnings
} {
    input.jdg_entrepreneur.has_thermo_relief == true
    thermo_projects := object.get(input.jdg_entrepreneur, "thermo_projects", [])

    total_limit := 53000
    max_projects := 2
    window_years := 3

    project_count := count(thermo_projects)
    total_spent := sum([p.amount | some p in thermo_projects])

    cap_exceeded = true { total_spent > total_limit }
    cap_exceeded = false { total_spent <= total_limit }

    remaining_cap = total_limit - total_spent { total_spent <= total_limit }
    remaining_cap = 0 { total_spent > total_limit }

    project_limit_exceeded := project_count > max_projects

    routing = "BLOCK_AND_ALERT" { cap_exceeded }
    routing = "TRIAGE_QUEUE" { project_limit_exceeded; not cap_exceeded }
    routing = "" { not cap_exceeded; not project_limit_exceeded }
    routing_reason = sprintf("TERMO — przekroczony limit 53 000 PLN! Wydano: %.2f PLN.", [total_spent]) { cap_exceeded }
    routing_reason = sprintf("TERMO — %d przedsięwzięć (max 2 w 3 lata). Nadmiarowe nie podlegają odliczeniu.", [project_count]) { project_limit_exceeded; not cap_exceeded }
    routing_reason = "" { not cap_exceeded; not project_limit_exceeded }

    warnings = [sprintf("ULGA TERMOMODERNIZACYJNA Art. 26h — %d przedsięwzięć, %.2f PLN z limitu 53 000 PLN. Okno 3-letnie. Pozostało: %.2f PLN.", [project_count, total_spent, remaining_cap])]
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-12: Darowizny na cele kultu religijnego (P30 L18)
# Art. 26 ust. 1 pkt 9 PIT: darowizny na cele kultu religijnego —
# odliczane w odrębnych limitach (6% dochodu, max łącznie z innymi darowiznami)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.religious_donation_relief",
    "package": "jdg.pit.plan26_critical", "priority": 12,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "RELIGIOUS_DONATION_CHECK",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT_36",
    "donation_type": donation_type,
    "donation_amount": donation_amount,
    "donation_6pct_limit": max_donation,
    "donation_exceeds_limit": exceeds_limit,
    "donation_deductible_amount": deductible_amount,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 26 ust. 1 pkt 9 PIT",
    "_warnings": warnings
} {
    input.invoice.category_code in {"RELIGIOUS_DONATION", "CHURCH_DONATION"}
    donation_amount := object.get(input.invoice, "amount_net", 0)
    annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)

    max_donation := annual_income * 0.06
    exceeds_limit := donation_amount > max_donation
    deductible_amount = donation_amount { not exceeds_limit }
    deductible_amount = max_donation { exceeds_limit }

    donation_type = "CEL KULTU RELIGIJNEGO"

    routing = "TRIAGE_QUEUE" { exceeds_limit }
    routing = "" { not exceeds_limit }
    routing_reason = sprintf("DAROWIZNA RELIGIJNA — %.2f PLN przekracza 6%% dochodu (limit %.2f PLN). Odliczysz tylko %.2f PLN.", [donation_amount, max_donation, deductible_amount]) { exceeds_limit }
    routing_reason = "" { not exceeds_limit }

    warnings = [sprintf("DAROWIZNA NA CELE KULTU RELIGIJNEGO Art. 26 ust. 1 pkt 9 — %.2f PLN (limit 6%% = %.2f PLN). Odliczenie: %.2f PLN.", [donation_amount, max_donation, deductible_amount])]
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-13: Klasyfikator PKWiU e-usług dla PIT (P30 L14)
# Rozszerza elearning.rego o pełną klasyfikację PKWiU usług cyfrowych w PIT:
# ryczałt 8.5%, 12%, 15% w zależności od PKWiU, IP Box dla oprogramowania
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.plan26_critical.pkwiu_e_service_classifier",
    "package": "jdg.pit.plan26_critical", "priority": 13,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PKWIU_E_SERVICE_CLASSIFIER",
    "pit_form": "", "pit_rate": pkwiu_pit_rate,
    "pit_bracket": "", "pit_annual_return_type": "",
    "pkwiu_code": pkwiu_code,
    "pkwiu_category": pkwiu_category,
    "pkwiu_lump_sum_rate": pkwiu_pit_rate,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 12 ustawy o ryczałcie",
    "_warnings": [sprintf("PKWiU e-usługa — %s (PKWiU %s), stawka ryczałtu: %s", [pkwiu_category, pkwiu_code, pkwiu_pit_rate])]
} {
    input.invoice.is_digital_service == true
    pkwiu_code := object.get(input.invoice, "pkwiu_code", "")

    # Pelna mapa PKWiU dla e-uslug w PIT (ryczalt)
    pkwiu_service_map := {
        "58.29.1": {"category": "Oprogramowanie — pakiety (IP Box)", "pit_rate": "5% (IP Box)"},
        "58.29.2": {"category": "Oprogramowanie — download", "pit_rate": "5% (IP Box)"},
        "58.29.3": {"category": "Oprogramowanie — SaaS/cloud", "pit_rate": "5% (IP Box)"},
        "62.01.1": {"category": "Uslugi programistyczne", "pit_rate": "5% (IP Box) lub 15%"},
        "62.02.1": {"category": "Doradztwo IT", "pit_rate": "15%"},
        "62.03.1": {"category": "Zarzadzanie sieciami", "pit_rate": "15%"},
        "63.11.1": {"category": "Przetwarzanie danych/hosting", "pit_rate": "8.5%"},
        "63.12.1": {"category": "Portale internetowe", "pit_rate": "8.5%"},
        "73.11.1": {"category": "Reklama online", "pit_rate": "15%"},
        "73.12.1": {"category": "Posrednictwo reklamowe online", "pit_rate": "15%"},
        "74.10.1": {"category": "Projektowanie graficzne", "pit_rate": "8.5%"},
        "74.20.1": {"category": "Fotografia cyfrowa", "pit_rate": "8.5%"},
        "74.90.1": {"category": "Tlumaczenia online", "pit_rate": "8.5%"},
        "85.51.1": {"category": "Kursy sportowe online", "pit_rate": "8.5%"},
        "85.52.1": {"category": "Kursy artystyczne online", "pit_rate": "8.5%"},
        "85.59.A": {"category": "E-learning — kursy jezykowe", "pit_rate": "8.5%"},
        "85.59.B": {"category": "E-learning — kursy IT", "pit_rate": "8.5%"},
        "85.60.1": {"category": "Wsparcie edukacyjne online", "pit_rate": "8.5%"},
        "96.09.1": {"category": "Uslugi cyfrowe — pozostale", "pit_rate": "15%"},
    }

    pkwiu_code in pkwiu_service_map
    pkwiu_category := pkwiu_service_map[pkwiu_code].category
    pkwiu_pit_rate := pkwiu_service_map[pkwiu_code].pit_rate
}
