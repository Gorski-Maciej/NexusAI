# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — JPK_CIT: JPK_KR + JPK_ST dla JDG na CIT (v7.0 NEW)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Raport v7.0 LUKA: JPK_CIT dla JDG na CIT (Estoński CIT, CIT liniowy) NIEOBSŁUŻONE.
# Ten pakiet wypełnia tę lukę.
#
# Obsługuje:
# - JPK_KR (Księgi Rachunkowe) — dla JDG na pełnej księgowości
# - JPK_ST (Środki Trwałe) — ewidencja środków trwałych
# - CIT należny z odliczeniami (darowizny, IP Box, straty)
# - Estoński CIT (20% od wypłaconego zysku)
# - Mały podatnik CIT (9%)
#
# v7.0 UWARUNKOWANIE (P18): JDG jako osoba fizyczna płaci PIT — formy CIT (CIT, CIT_LINEAR,
# ESTONIAN_CIT, CIT_SMALL) nie występują dla JDG w praktyce. Moduł modeluje scenariusze
# hipotetyczne. REALNE znaczenie ma JPK_KR/JPK_ST na żądanie dla JDG prowadzącej pełną
# księgowość (przychody >2 mln EUR rocznie) — art. 193a OrdPU.
# TODO: Powiązanie modułu z księgami rachunkowymi (generator JPK_KR/ST).
#
# package: jdg.jpk_cit
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.jpk_cit

import data.jdg.helpers
import data.jdg.thresholds
import future.keywords.in

# Deterministic value helpers keep conditional routing outside rule bodies.
cit_routing_value(to_pay, advances) = "BLOCK_AND_ALERT" {
    to_pay > object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_cit_payment_tier_high_pln", 10000)
    advances == 0
} else = "TRIAGE_QUEUE" {
    to_pay > object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_cit_payment_tier_low_pln", 5000)
} else = "" {
    to_pay <= object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_cit_payment_tier_low_pln", 5000)
}

cit_routing_reason_value(to_pay, advances) = "CIT do zapłaty >10k bez zaliczek" {
    to_pay > object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_cit_payment_tier_high_pln", 10000)
    advances == 0
} else = reason {
    to_pay > object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_cit_payment_tier_low_pln", 5000)
    reason := sprintf("CIT do zapłaty: %.2f PLN", [to_pay])
} else = "" {
    to_pay <= object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_cit_payment_tier_low_pln", 5000)
}

threshold_ok_value(revenue_eur) = true {
    revenue_eur < object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_cit_revenue_eur_limit", 2000000)
} else = false {
    revenue_eur >= object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_cit_revenue_eur_limit", 2000000)
}

default decide := {
    "matched": false,
    "rule_id": "jdg.jpk_cit.no_match",
    "package": "jdg.jpk_cit",
    "priority": 1999
}

# ══════ JC-010: cit_calculation_standard — CIT liniowy 19% (v7.0 FIX: merged with applicability) ══════
decide := {
    "matched": true,
    "rule_id": "jdg.jpk_cit.cit_calculation_standard",
    "package": "jdg.jpk_cit",
    "priority": 10,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "CIT", "pit_rate": "0.19", "pit_bracket": "", "pit_annual_return_type": "CIT-8",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cit_revenue": cit_revenue,
    "cit_costs": cit_costs,
    "cit_income": cit_income,
    "cit_tax_due": cit_tax_due,
    "cit_advances_paid": cit_advances_paid,
    "cit_to_pay": cit_to_pay,
    "_routing": cit_routing,
    "_routing_reason": cit_routing_reason,
    "_legal_basis": "Art. 19 CIT",
    "_warnings": [sprintf("CIT 19%%: dochód %.2f PLN × 19%% = %.2f PLN. Zaliczki: %.2f PLN. Do zapłaty: %.2f PLN.", [cit_income, cit_tax_due, cit_advances_paid, cit_to_pay])]
} {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form in {"CIT", "CIT_LINEAR"}

    cit_revenue := object.get(input.jdg_entrepreneur, "annual_revenue", 0)
    cit_costs := object.get(input.jdg_entrepreneur, "annual_costs_deductible", 0)
    nkup_total := object.get(input.jdg_entrepreneur, "nkup_total", 0)
    cit_income_raw := cit_revenue - cit_costs + nkup_total
    cit_income := max([cit_income_raw, 0])

    donations := object.get(input.jdg_entrepreneur, "donations_total", 0)
    max_donation := cit_income * 0.10
    donation_deduction := min([donations, max_donation])

    ip_box_income := object.get(input.jdg_entrepreneur, "ip_box_income", 0)
    ip_box_deduction := ip_box_income * 0.05

    past_losses := object.get(input.jdg_entrepreneur, "past_tax_losses", 0)
    max_loss := cit_income * 0.50
    loss_deduction := min([past_losses, max_loss])

    taxable_base_raw := cit_income - donation_deduction - ip_box_deduction - loss_deduction
    taxable_base := max([taxable_base_raw, 0])

    cit_tax_due := taxable_base * 0.19
    cit_advances_paid := object.get(input.jdg_entrepreneur, "cit_advances_paid", 0)
    cit_to_pay := max([cit_tax_due - cit_advances_paid, 0])

    cit_routing := cit_routing_value(cit_to_pay, cit_advances_paid)
    cit_routing_reason := cit_routing_reason_value(cit_to_pay, cit_advances_paid)
}

# ══════ JC-020: cit_calculation_estonian — Estoński CIT 20% od wypłaconego zysku ══════
else := {
    "matched": true,
    "rule_id": "jdg.jpk_cit.cit_calculation_estonian",
    "package": "jdg.jpk_cit",
    "priority": 20,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "ESTONIAN_CIT", "pit_rate": "0.20", "pit_bracket": "", "pit_annual_return_type": "CIT-8E",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cit_estonian_distributed_profit": distributed_profit,
    "cit_estonian_tax_due": estonian_tax_due,
    "cit_estonian_reinvested": reinvested,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28c-28t CIT (Estoński CIT)",
    "_warnings": [sprintf("Estoński CIT: wypłacony zysk %.2f PLN × 20%% = %.2f PLN. Reinwestowane: %.2f PLN (opodatkowanie odroczone).", [distributed_profit, estonian_tax_due, reinvested])]
} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit", 0)
    distributed_profit := object.get(input.jdg_entrepreneur, "distributed_profit", 0)
    estonian_tax_due := distributed_profit * 0.20
    reinvested := annual_profit - distributed_profit
}

# ══════ JC-030: cit_small_taxpayer — Mały podatnik CIT 9% ══════
else := {
    "matched": true,
    "rule_id": "jdg.jpk_cit.cit_calculation_small",
    "package": "jdg.jpk_cit",
    "priority": 30,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "CIT_SMALL", "pit_rate": "0.09", "pit_bracket": "", "pit_annual_return_type": "CIT-8",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cit_small_revenue_eur": revenue_eur,
    "cit_small_tax_due": cit_tax_due,
    "cit_small_threshold_ok": threshold_ok,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 19 ust. 1 pkt 2 CIT",
    "_warnings": [sprintf("Mały podatnik CIT 9%%: dochód %.2f PLN × 9%% = %.2f PLN. Przychody EUR: %.0f (limit 2M).", [cit_income, cit_tax_due, revenue_eur])]
} {
    input.jdg_entrepreneur.tax_form == "CIT_SMALL"
    cit_income := object.get(input.jdg_entrepreneur, "cit_taxable_income", 0)
    revenue_eur := object.get(input.jdg_entrepreneur, "annual_revenue_eur", 0)
    threshold_ok := threshold_ok_value(revenue_eur)
    cit_tax_due := cit_income * 0.09
}

# ══════ JC-100: jpk_cit_deadline — Terminy JPK_CIT ══════
else := {
    "matched": true,
    "rule_id": "jdg.jpk_cit.cit_deadline",
    "package": "jdg.jpk_cit",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cit_deadlines_upcoming": deadlines,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 27 CIT, Art. 193a OrdPU",
    "_warnings": ["JPK_CIT deadline: JPK_KR do 10. dnia miesiąca, CIT-8 rocznie do 31.03. Zaliczki do 20. dnia miesiąca."]
} {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form in {"CIT", "CIT_LINEAR", "ESTONIAN_CIT", "CIT_SMALL"}

    deadlines := [
        {"name": "CIT-8", "date": "2027-03-31", "desc": "Zeznanie roczne CIT-8 za 2026"},
        {"name": "JPK_KR", "date": "M+10", "desc": "JPK_KR miesięcznie do 10. dnia"},
        {"name": "CIT_ADVANCE", "date": "M+20", "desc": "Zaliczka CIT do 20. dnia"},
    ]

    routing := ""
    routing_reason := ""
}
