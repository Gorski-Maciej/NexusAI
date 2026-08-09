# NexusAI JDG — Enterprise form transition simulator.
# Documentation is intentionally kept as ordinary comments; the legacy metadata
# block was not valid OPA annotation YAML.
# Package: jdg.form_transition
# Public rules: full comparison, restrictions, relief loss, JDG to sp. z o.o., health impact.

package jdg.form_transition

import future.keywords.if
import future.keywords.in
import data.jdg.thresholds as threshold_data

default decide := {
    "matched": false,
    "rule_id": "jdg.form_transition.no_match",
    "package": "jdg.form_transition",
    "priority": 9999,
}

# -----------------------------------------------------------------------------
# Shared deterministic helpers
# -----------------------------------------------------------------------------

threshold_limits := threshold_data.limits
threshold_bounds := threshold_data.bounds
threshold_pit := threshold_data.pit

health_linear_limit := object.get(threshold_limits, "health_linear_deduction_limit", 10000)
scale_threshold_default := object.get(threshold_pit, "scale_threshold", 120000)
tax_free_default := object.get(threshold_pit, "tax_free_amount", 30000)
average_wage_default := object.get(threshold_bounds, "average_wage", 8000)

lump_excluded(business_type) := object.get({
    "PHARMACY": true,
    "EXCHANGE": true,
    "GAMBLING": true,
    "FINANCIAL_INTERMEDIATION": true,
}, business_type, false)

lump_allowed(business_type) := object.get({
    "PHARMACY": false,
    "EXCHANGE": false,
    "GAMBLING": false,
    "FINANCIAL_INTERMEDIATION": false,
}, business_type, true)

both_true(a, b) := object.get({"true|true": true}, sprintf("%v|%v", [a, b]), false)

bool_not(value) := object.get({"true": false, "false": true}, sprintf("%v", [value]), false)

bool_text(value) := sprintf("%v", [value])

percentage(value, denominator) := value / denominator * 100 if {
    denominator > 0
} else := 0 if {
    denominator == 0
}

lump_rate_for(business_type) := object.get({
    "SERVICES": 0.15,
    "IT": 0.12,
    "CONSULTING": 0.17,
    "TRADING": 0.03,
    "CONSTRUCTION": 0.055,
    "TRANSPORT": 0.055,
    "MANUFACTURING": 0.055,
    "RENTAL": 0.085,
    "MEDICAL": 0.14,
    "LEGAL": 0.17,
    "EDUCATION": 0.085,
}, business_type, 0.15)

lump_health_for(revenue, wage) := floor(wage * 0.60 * 0.09 * 100) / 100 * 12 if {
    revenue <= 60000
} else := floor(wage * 1.00 * 0.09 * 100) / 100 * 12 if {
    revenue <= 300000
} else := floor(wage * 1.80 * 0.09 * 100) / 100 * 12 if {
    revenue > 300000
}

linear_health_for(profit) := profit * 0.049
linear_deduction_for(profit) := min([linear_health_for(profit), health_linear_limit])

scale_tax_for(profit, tax_free, threshold) := scale_low + scale_high if {
    taxable := max([profit - tax_free, 0])
    scale_low := min([taxable, max([threshold - tax_free, 0])]) * 0.12
    scale_high := max([profit - threshold, 0]) * 0.32
}

card_eligible(flag, employees, revenue) := object.get({
    "true|false|true": true,
}, sprintf("%v|%v|%v", [flag, employees, revenue < 200000]), false)

best_form(scale_total, linear_total, lump_total, card_total) := "TAX_CARD" if {
    card_total <= scale_total
    card_total <= linear_total
    card_total <= lump_total
} else := "LUMP_SUM" if {
    lump_total < card_total
    lump_total <= scale_total
    lump_total <= linear_total
} else := "LINEAR" if {
    linear_total < card_total
    linear_total < lump_total
    linear_total < scale_total
} else := "PIT_SCALE" if {
    true
}

deadline_for(current, recommended, month) := sprintf("20.%02d.%d", [month + 1, 2026]) if {
    current != recommended
    month <= 12
} else := "N/A (jesteś na optymalnej formie)" if {
    current == recommended
} else := "N/A"

transition_possible(current, recommended, month) := object.get({
    "true|true": true,
}, sprintf("%v|%v", [current != recommended, month <= 12]), false)

simulation_routing(savings, can_change) := "TRIAGE_QUEUE" if {
    savings > 5000
    can_change
} else := ""

simulation_reason(current, recommended, savings, savings_pct, can_change) := sprintf("OPTYMALIZACJA: zmiana %s→%s oszczędza %.0f PLN/rok (%.0f%%)", [current, recommended, savings, savings_pct]) if {
    savings > 5000
    can_change
} else := "Jesteś na optymalnej formie opodatkowania" if {
    current == recommended
} else := ""

form_display(form) := object.get({
    "PIT_SCALE": "Skala",
    "LINEAR": "Liniowy",
    "LUMP_SUM": "Ryczałt",
    "TAX_CARD": "Karta",
}, form, "Nieznana")

build_simulation_warnings(curr, reco, scale, linear, lump, savings, pct, can_change, deadline) := [
    sprintf("📊 SYMULACJA ZMIANY FORMY OPODATKOWANIA", []),
    sprintf("   Obecnie: %s", [form_display(curr)]),
    sprintf("   Optymalnie: %s", [form_display(reco)]),
    sprintf("   💰 Oszczędność: %.0f PLN/rok (%.0f%%)", [savings, pct]),
    sprintf("   Skala 12/32%%: %.0f PLN; liniowy 19%%: %.0f PLN; ryczałt: %.0f PLN", [scale, linear, lump]),
    sprintf("⚠️ ZMIANA MOŻLIWA: %s", [object.get({"true": "TAK", "false": "NIE"}, sprintf("%v", [can_change]), "NIE")]),
    sprintf("📅 TERMIN: %s", [deadline]),
] if {
    savings > 0
} else := [sprintf("✅ Jesteś na optymalnej formie opodatkowania (%s).", [form_display(curr)])] if {
    true
}

# -----------------------------------------------------------------------------
# FTS-1750: full comparison simulation
# -----------------------------------------------------------------------------

decide := {
    "matched": true,
    "rule_id": "jdg.form_transition.full_comparison_simulation",
    "package": "jdg.form_transition",
    "priority": 1750,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "sim_current_form": current_form,
    "sim_recommended_form": recommended_form,
    "sim_scale_total_annual": scale_total,
    "sim_linear_total_annual": linear_total,
    "sim_lump_total_annual": lump_total,
    "sim_savings_vs_current": savings,
    "sim_savings_pct": savings_pct,
    "sim_transition_deadline": transition_deadline,
    "sim_transition_possible_now": can_transition_now,
    "_routing": trans_routing,
    "_routing_reason": trans_routing_reason,
    "_legal_basis": "Art. 9a ust. 1-5 PIT; Art. 27, 30c, 30ca PIT",
    "_warnings": build_simulation_warnings(current_form, recommended_form, scale_total, linear_total, lump_total, savings, savings_pct, can_transition_now, transition_deadline),
} if {
    input.simulate_form_transition == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_projected", 180000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_projected", 50000)
    annual_profit := annual_revenue - annual_costs
    business_type := object.get(input.jdg_entrepreneur, "business_type", "SERVICES")
    employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    card_flag := object.get(input.jdg_entrepreneur, "eligible_for_tax_card", false)
    tax_free := object.get(threshold_pit, "tax_free_amount", tax_free_default)
    scale_threshold := object.get(threshold_pit, "scale_threshold", scale_threshold_default)
    wage := object.get(threshold_bounds, "average_wage", average_wage_default)
    scale_tax := scale_tax_for(annual_profit, tax_free, scale_threshold)
    scale_health := annual_profit * 0.09
    zus := object.get(input.jdg_entrepreneur, "annual_zus_total", 21600)
    scale_total := scale_tax + scale_health + zus
    linear_tax := annual_profit * 0.19
    linear_health := linear_health_for(annual_profit)
    linear_total := linear_tax + linear_health + object.get(input.jdg_entrepreneur, "annual_zus_total_linear", zus)
    lump_health := lump_health_for(annual_revenue, wage)
    lump_total_base := annual_revenue * lump_rate_for(business_type) + lump_health * 0.50 + zus
    lump_total := object.get({"true": lump_total_base, "false": 999999}, bool_text(lump_allowed(business_type)), 999999)
    card_ok := card_eligible(card_flag, employees, annual_revenue)
    card_total := object.get({"true": 12000 + lump_health * 0.50 + zus, "false": 999999}, sprintf("%v", [card_ok]), 999999)
    recommended_form := best_form(scale_total, linear_total, lump_total, card_total)
    totals := {"PIT_SCALE": scale_total, "LINEAR": linear_total, "LUMP_SUM": lump_total, "TAX_CARD": card_total}
    current_total := object.get(totals, current_form, scale_total)
    optimal_total := object.get(totals, recommended_form, scale_total)
    savings := current_total - optimal_total
    savings_pct := percentage(savings, current_total)
    current_month := object.get(input, "current_month", 7)
    can_transition_now := transition_possible(current_form, recommended_form, current_month)
    transition_deadline := deadline_for(current_form, recommended_form, current_month)
    trans_routing := simulation_routing(savings, can_transition_now)
    trans_routing_reason := simulation_reason(current_form, recommended_form, savings, savings_pct, can_transition_now)
} else := {
    "matched": true,
    "rule_id": "jdg.form_transition.restrictions_check",
    "package": "jdg.form_transition",
    "priority": 1760,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "trans_eligible_for_target": target_possible,
    "trans_restrictions": restrictions,
    "trans_lockin_until": lockin_date,
    "_routing": restr_routing,
    "_routing_reason": restr_routing_reason,
    "_legal_basis": "Art. 9a ust. 1-5 PIT; Art. 6-8 ustawy o ryczałcie",
    "_warnings": build_restriction_warnings(target_possible, restrictions, lockin_date),
} if {
    input.simulate_transition_restrictions == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    target_form := object.get(input, "target_tax_form", "LINEAR")
    business_type := object.get(input.jdg_entrepreneur, "business_type", "SERVICES")
    employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 180000)
    changed_last_year := object.get(input.jdg_entrepreneur, "changed_form_last_year", false)
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    is_restricted_lump := both_true(target_form == "LUMP_SUM", lump_excluded(business_type))
    is_restricted_card_employee := both_true(target_form == "TAX_CARD", employees)
    is_restricted_card_revenue := both_true(target_form == "TAX_CARD", revenue > 200000)
    is_restricted_lockin := changed_last_year
    is_restricted_ipbox := both_true(uses_ip_box, target_form in {"LUMP_SUM", "TAX_CARD"})
    restrictions := [entry.message |
        some entry in [
            {"message": "Branża wykluczona z ryczałtu (apteka/finanse)", "active": is_restricted_lump},
            {"message": "Karta podatkowa nie dla pracodawców", "active": is_restricted_card_employee},
            {"message": "Limit 200k PLN dla karty podatkowej przekroczony", "active": is_restricted_card_revenue},
            {"message": "Zmiana formy była już w poprzednim roku podatkowym — lock-in!", "active": is_restricted_lockin},
            {"message": "IP Box dostępny tylko przy skali i liniowym — utrata IP Box!", "active": is_restricted_ipbox},
        ]
        entry.active == true
    ]
    target_possible := count(restrictions) == 0
    lockin_date := object.get({"true": "2027-01-01", "false": ""}, sprintf("%v", [changed_last_year]), "")
    restr_routing := object.get({"true": "BLOCK_AND_ALERT", "false": ""}, bool_text(bool_not(target_possible)), "")
    restr_routing_reason := object.get({"true": concat("; ", restrictions), "false": ""}, bool_text(bool_not(target_possible)), "")
} else := {
    "matched": true,
    "rule_id": "jdg.form_transition.relief_loss_calculator",
    "package": "jdg.form_transition",
    "priority": 1770,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": target_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "trans_reliefs_lost": lost_reliefs,
    "trans_reliefs_lost_value_pln": lost_value,
    "trans_reliefs_kept": kept_reliefs,
    "_routing": loss_routing,
    "_routing_reason": loss_routing_reason,
    "_legal_basis": "Art. 26-30ca PIT; Art. 18d-18dc CIT",
    "_warnings": build_relief_loss_warnings(lost_reliefs, lost_value, kept_reliefs),
} if {
    input.simulate_relief_loss == true
    target_form := object.get(input, "target_tax_form", "LINEAR")
    has_child := object.get(input.jdg_entrepreneur, "has_children_under_18", false)
    files_jointly := object.get(input.jdg_entrepreneur, "files_jointly_with_spouse", false)
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    ip_box_income := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 30000)
    lost_entries := [entry |
        some entry in [
            {"label": "Ulga na dziecko (1112 PLN/rok/dziecko)", "value": 1112, "active": both_true(target_form != "PIT_SCALE", has_child)},
            {"label": "Wspólne rozliczenie małżonków", "value": 2000, "active": both_true(target_form != "PIT_SCALE", files_jointly)},
            {"label": sprintf("IP Box (5%% na %.0f PLN dochodu)", [ip_box_income]), "value": ip_box_income * 0.14, "active": both_true(uses_ip_box, target_form in {"LUMP_SUM", "TAX_CARD"})},
            {"label": "Kwota wolna 30 000 PLN", "value": 3600, "active": target_form != "PIT_SCALE"},
        ]
        entry.active
    ]
    lost_reliefs := [entry.label | some entry in lost_entries]
    lost_value := sum([entry.value | some entry in lost_entries])
    kept_reliefs := object.get({
        "true": ["Ulga B+R", "Ulga na prototyp", "Ulga na ekspansję", "Ulga na robotyzację"],
        "false": ["Ulga IKZE", "Ulga związkowa"],
    }, sprintf("%v", [target_form in {"PIT_SCALE", "LINEAR"}]), [])
    loss_routing := object.get({"true": "TRIAGE_QUEUE", "false": ""}, bool_text(lost_value > 5000), "")
    loss_routing_reason := object.get({"true": sprintf("Przy zmianie na %s tracisz ulgi o wartości %.0f PLN/rok!", [target_form, lost_value]), "false": ""}, bool_text(lost_value > 5000), "")
} else := {
    "matched": true,
    "rule_id": "jdg.form_transition.jdg_to_spzoo_analysis",
    "package": "jdg.form_transition",
    "priority": 1775,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "sim_transition_to_spzoo_recommended": spzoo_recommended,
    "sim_spzoo_jdg_annual_cost": jdg_annual,
    "sim_spzoo_spzoo_annual_cost": spzoo_annual,
    "sim_spzoo_breakeven_months": breakeven_months,
    "_routing": spzoo_routing,
    "_routing_reason": spzoo_reason,
    "_legal_basis": "Art. 551-584 KSH; Art. 19 CIT; Art. 30c PIT",
    "_warnings": [
        "🏢 PRZEKSZTAŁCENIE JDG → SP. Z O.O.",
        sprintf("   JDG (obecnie): %.0f PLN/rok", [jdg_annual]),
        sprintf("   Sp. z o.o.: %.0f PLN/rok", [spzoo_annual]),
        sprintf("   💰 Oszczędność: %.0f PLN/rok", [jdg_annual - spzoo_annual]),
        sprintf("💡 %s", [spzoo_verdict]),
    ],
} if {
    input.simulate_spzoo_transition == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    profit := object.get(input.jdg_entrepreneur, "annual_profit_projected", 100000)
    employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    pit_tax := object.get({
        "LINEAR": profit * 0.19,
        "PIT_SCALE_LOW": max([profit - 30000, 0]) * 0.12,
        "PIT_SCALE_HIGH": profit * 0.19,
    }, object.get({"true": "PIT_SCALE_HIGH", "false": "PIT_SCALE_LOW"}, sprintf("%v", [profit > 120000]), "PIT_SCALE_LOW"), 0)
    health := object.get({"PIT_SCALE": profit * 0.09, "LINEAR": linear_health_for(profit)}, current_form, profit * 0.09)
    jdg_annual := pit_tax + health + 21600
    cit_estonski := bool_not(employees)
    cit_tax := object.get({"true": 0, "false": profit * 0.09}, bool_text(cit_estonski), 0)
    spzoo_annual := cit_tax + 21000
    annual_savings := jdg_annual - spzoo_annual
    spzoo_recommended := annual_savings > 15000
    breakeven_months := object.get({"true": floor(21000 / max([annual_savings / 12, 1])), "false": 99}, sprintf("%v", [annual_savings > 0]), 99)
    spzoo_routing := object.get({"true": "TRIAGE_QUEUE", "false": ""}, bool_text(spzoo_recommended), "")
    spzoo_reason := object.get({"true": sprintf("Przekształcenie w Sp. z o.o. opłacalne — oszczędność %.0f PLN/rok", [annual_savings]), "false": "Pozostań na JDG"}, bool_text(spzoo_recommended), "Pozostań na JDG")
    spzoo_verdict := object.get({"true": "PRZEKSZTAŁĆ — opłacalne finansowo", "false": "POZOSTAŃ NA JDG — obecna forma optymalna"}, bool_text(spzoo_recommended), "POZOSTAŃ NA JDG — obecna forma optymalna")
} else := {
    "matched": true,
    "rule_id": "jdg.form_transition.health_contribution_details",
    "package": "jdg.form_transition",
    "priority": 1780,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "trans_health_scale": health_scale,
    "trans_health_linear": health_linear,
    "trans_health_linear_deductible": health_linear_ded,
    "trans_health_lump": health_lump,
    "trans_health_lump_deductible": health_lump_ded,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 79-81 ustawy o świadczeniach zdrowotnych; Art. 30c PIT",
    "_warnings": [sprintf("🏥 SKŁADKA ZDROWOTNA: skala %.0f PLN; liniowy %.0f PLN; ryczałt %.0f PLN", [health_scale, health_linear, health_lump])],
} if {
    input.simulate_health_impact == true
    profit := object.get(input.jdg_entrepreneur, "annual_profit_projected", 96000)
    revenue := object.get(input.jdg_entrepreneur, "annual_revenue_projected", 180000)
    wage := object.get(threshold_bounds, "average_wage", average_wage_default)
    health_scale := profit * 0.09
    health_linear := linear_health_for(profit)
    health_linear_ded := linear_deduction_for(profit)
    health_lump := lump_health_for(revenue, wage)
    health_lump_ded := health_lump * 0.50
}

# -----------------------------------------------------------------------------
# Warning helpers
# -----------------------------------------------------------------------------

build_restriction_warnings(possible, restrictions, locked) := ["✅ Zmiana formy na wybraną jest możliwa — brak przeciwwskazań."] if {
    possible
} else := [sprintf("🔴 ZMIANA NIEMOŻLIWA: %s. LOCK-IN: %s", [concat(", ", restrictions), locked])] if {
    not possible
}

build_relief_loss_warnings(lost, value, kept) := [
    sprintf("⚠️ UTRATA ULG — wartość: %.0f PLN/rok", [value]),
    sprintf("   TRACISZ: %s", [concat("; ", lost)]),
    sprintf("   ZOSTAJE: %s", [concat("; ", kept)]),
] if {
    count(lost) > 0
} else := ["✅ Przy przejściu zachowujesz wszystkie ulgi."] if {
    true
}
