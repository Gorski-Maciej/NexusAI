# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Cumulative Revenue & Tier Transition Engine v8.0
# FIX v7.1 P31 — FAZA 3.13: Narastający licznik przychodu dla ryczałtu/skali
# INN-02: Tier Transition Smooth Engine (pełna implementacja)
# INN-04: Annual Health Reconciliation Auto-Engine (pełna implementacja)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.zus.cumulative_engine

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.zus.cumulative.no_match",
    "package": "jdg.zus.cumulative_engine", "priority": 99999
}

# ═══════════════════════════════════════════════════════════════════════════════
# CUM-100: Cumulative Revenue Tracker — Narastający przychód od stycznia
# Eliminuje Scenariusz 1: "1 grosz powyżej 60 000 PLN"
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true, "rule_id": "jdg.zus.cumulative.revenue_tracker",
    "_routing": "",
    "package": "jdg.zus.cumulative_engine", "priority": 100,
    "cumulative_revenue_pln": cum_rev,
    "cumulative_current_month": current_month,
    "cumulative_lump_tier": current_tier,
    "cumulative_lump_monthly_health_pln": monthly_health,
    "cumulative_tier_changed": tier_changed,
    "cumulative_tier_change_month": change_month,
    "_legal_basis": "Art. 81 ust. 2e-2f u.ś.o.z.",
    "_warnings": [sprintf("NARASTAJĄCO — %d mies.: %.2f PLN → próg %s → składka %.2f PLN/mies. %s",
        [current_month, cum_rev, current_tier, monthly_health, tier_msg])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    monthly_revenues := object.get(input.jdg_entrepreneur, "lump_sum_monthly_revenues", [])
    current_month := object.get(input.jdg_entrepreneur, "current_month", 1)
    cum_rev := helpers.cumulative_sum(monthly_revenues, current_month)
    # Progi 2026
    tier1_limit := 60000
    tier2_limit := 300000
    current_tier = "TIER_I" { cum_rev <= tier1_limit }
    current_tier = "TIER_II" { cum_rev > tier1_limit; cum_rev <= tier2_limit }
    current_tier = "TIER_III" { cum_rev > tier2_limit }
    # Kwoty miesięczne (9% od podstawy progowej, przeciętne 8190 PLN)
    monthly_health = 442.26 { current_tier == "TIER_I" }
    monthly_health = 737.10 { current_tier == "TIER_II" }
    monthly_health = 1326.78 { current_tier == "TIER_III" }
    # Detekcja zmiany progu
    prev_tier := object.get(input.jdg_entrepreneur, "lump_sum_previous_tier", "TIER_I")
    tier_changed := current_tier != prev_tier
    change_month = current_month { tier_changed }
    tier_msg = sprintf("ZMIANA PROGU w miesiącu %d! %s → %s", [change_month, prev_tier, current_tier]) { tier_changed }
    tier_msg = "" { not tier_changed }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CUM-200: Cumulative Income Tracker — Narastający dochód dla skali/liniowego
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true, "rule_id": "jdg.zus.cumulative.income_tracker",
    "_routing": "",
    "package": "jdg.zus.cumulative_engine", "priority": 200,
    "cumulative_income_pln": cum_income,
    "cumulative_income_months": current_month,
    "cumulative_estimated_annual_income": estimated_annual,
    "_legal_basis": "Art. 81 ust. 2 u.ś.o.z.",
    "_warnings": [sprintf("DOCHÓD NARASTAJĄCO — %d mies.: %.2f PLN (szac. rocznie: %.2f PLN)",
        [current_month, cum_income, estimated_annual])]
} {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form in {"PIT_SCALE", "LINEAR"}
    monthly_incomes := object.get(input.jdg_entrepreneur, "monthly_incomes_net", [])
    current_month := object.get(input.jdg_entrepreneur, "current_month", 1)
    cum_income := helpers.cumulative_sum(monthly_incomes, current_month)
    estimated_annual := cum_income * 12 / max([current_month, 1])
}

# ═══════════════════════════════════════════════════════════════════════════════
# CUM-300: Annual Reconciliation — Roczne uzgodnienie składki zdrowotnej
# INN-04 pełna implementacja: obsługa zmiany formy w trakcie roku (W7)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true, "rule_id": "jdg.zus.cumulative.annual_reconciliation",
    "_routing": "",
    "package": "jdg.zus.cumulative_engine", "priority": 300,
    "annual_health_paid_pln": total_paid,
    "annual_health_due_pln": total_due,
    "annual_health_diff_pln": diff,
    "annual_health_diff_type": diff_type,
    "annual_tax_form_changed": form_changed,
    "annual_proportional_deduction_limit": proportional_limit,
    "_legal_basis": "Art. 81 ust. 2f-2h u.ś.o.z., Art. 30c ust. 2 PIT",
    "_warnings": [sprintf("ROCZNE ROZLICZENIE — %s: %.2f PLN. %s. Termin: %s. %s",
        [diff_type, abs(diff), form_change_msg, deadline, action])]
} {
    input.jdg_entrepreneur.health_annual_settlement == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    total_paid := object.get(input.jdg_entrepreneur, "health_annual_paid", 0)
    total_due := object.get(input.jdg_entrepreneur, "health_annual_due", total_paid)
    diff := total_paid - total_due
    diff_type = "NADPŁATA" { diff > 0 }
    diff_type = "NIEDOPŁATA" { diff < 0 }
    diff_type = "ZGODNE" { diff == 0 }
    # Terminy
    deadline = "22 maja" { pit_form == "LUMP_SUM" }
    deadline = "30 kwietnia" { pit_form in {"PIT_SCALE", "LINEAR"} }
    deadline = "31 stycznia" { pit_form == "TAX_CARD" }
    action = "ZUS zwróci nadpłatę" { diff > 0 }
    action = "Wpłać niedopłatę do ZUS!" { diff < 0 }
    action = "OK" { diff == 0 }
    # Obsługa zmiany formy w trakcie roku (W7)
    form_changed := object.get(input.jdg_entrepreneur, "tax_form_changed_this_year", false)
    months_linear := object.get(input.jdg_entrepreneur, "months_on_linear", 0)
    months_scale := object.get(input.jdg_entrepreneur, "months_on_scale", 12)
    full_limit := 14100
    proportional_limit := full_limit * months_linear / max([months_linear + months_scale, 1])
    form_change_msg = sprintf("Zmiana formy! Limit odliczenia liniowego proporcjonalnie: %.0f PLN (%d/12 mies.)",
        [proportional_limit, months_linear]) { form_changed }
    form_change_msg = "" { not form_changed }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CUM-400: Form Transition Handler — Zmiana formy opodatkowania w trakcie roku
# Scenariusz 2 fix
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true, "rule_id": "jdg.zus.cumulative.form_transition",
    "_routing": "",
    "package": "jdg.zus.cumulative_engine", "priority": 400,
    "tax_form_previous": prev_form,
    "tax_form_current": curr_form,
    "tax_form_transition_month": transition_month,
    "tax_form_proportional_limit": proportional_limit,
    "tax_form_dual_declaration_required": dual_declaration,
    "_legal_basis": "Art. 81 ust. 2f-2h, Art. 30c ust. 2 PIT",
    "_warnings": [sprintf("ZMIANA FORMY PIT — %s → %s (miesiąc %d). %s. Limit odliczenia: %.0f PLN. %s",
        [prev_form, curr_form, transition_month, dual_note, proportional_limit, form_alert])]
} {
    prev_form := object.get(input.jdg_entrepreneur, "tax_form_previous", "")
    curr_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    prev_form != ""; prev_form != curr_form
    transition_month := object.get(input.jdg_entrepreneur, "tax_form_change_month", 1)
    months_linear := 12 - transition_month + 1
    full_limit := 14100
    proportional_limit := full_limit * months_linear / 12
    dual_declaration := prev_form in {"PIT_SCALE"} and curr_form in {"LINEAR"}
    dual_note = "WYMAGANE DWIE DEKLARACJE: PIT-36 + PIT-36L" { dual_declaration }
    dual_note = "Deklaracja roczna wg nowej formy" { not dual_declaration }
    form_alert = "UWAGA: składka liczona od nowej formy od miesiąca zmiany. Brak przeliczenia wstecz!" { true }
}
