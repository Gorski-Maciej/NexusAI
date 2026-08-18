# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rozszerzenie Form Transition Simulator: TAX FORM OPTIMIZER
# ═══════════════════════════════════════════════════════════════════════════════
# METADATA
# title: JDG Tax Form Optimizer — Extension Pack
# description: Enterprise financial simulation for tax-form selection, thresholds and cash-flow.
# architecture: Enterprise Simulation Engine Extension
# legal_basis: Art. 9a, 27, 30c PIT; Ustawa o ryczałcie
# package: jdg.form_optimizer
# deprecated: false
#

package jdg.form_optimizer

import future.keywords.if

# Strict-compatible deterministic helpers.
lump_health_for(avg_wage, revenue) = value {
    revenue <= 60000
    value := floor(avg_wage * 0.60 * 0.09 * 100) / 100 * 12
} else = value {
    revenue > 60000
    revenue <= 300000
    value := floor(avg_wage * 1.00 * 0.09 * 100) / 100 * 12
} else = value {
    revenue > 300000
    value := floor(avg_wage * 1.80 * 0.09 * 100) / 100 * 12
}

best_form_for(scale, linear, lump) = result {
    scale <= linear
    scale <= lump
    result := {"form": "PIT_SCALE", "total": scale}
} else = result {
    linear < scale
    linear <= lump
    result := {"form": "LINEAR", "total": linear}
} else = result {
    lump < scale
    lump < linear
    result := {"form": "LUMP_SUM", "total": lump}
} else = result {
    result := {"form": "PIT_SCALE", "total": scale}
}

savings_pct_for(current, savings) = value {
    current > 0
    value := savings / current * 100
} else = 0 {
    current <= 0
}

simulation_routing_for(savings) = "TRIAGE_QUEUE" {
    savings > 5000
} else = "" {
    savings <= 5000
}

health_recommendation_for(profit, breakeven) = "✅ ZOSTAŃ NA SKALI — niższy PIT 12%% rekompensuje wyższą zdrowotną" {
    profit < breakeven
} else = "➡️ ROZWAŻ LINIOWY — mimo 19%% PIT, niższa składka zdrowotna (4.9%% vs 9%%) daje oszczędność!" {
    profit >= breakeven
}

warning_lump(profile, early_w) = [sprintf("⚠️ Ryczałt: %.0f PLN przychodu — %.0f%% limitu 2M EUR", [revenue, revenue / (2000000 * eur_pln) * 100])] if {
    revenue := object.get(profile, "annual_revenue_pln", 0)
    eur_pln := object.get(object.get(data.thresholds, "bounds", {}), "eur_pln", 4.50)
    revenue > object.get(early_w, "lump_sum_eur_80pct", 1600000) * eur_pln
} else = []

warning_pit0(profile, early_w) = [sprintf("⚠️ PIT-0: %.0f PLN dochodu — %.0f%% limitu 85 528 PLN", [income, income / 85528 * 100])] if {
    income := object.get(profile, "cumulative_income_current_year", 0)
    income > object.get(early_w, "pit0_80pct", 68422)
} else = []

warning_scale(profile, early_w) = [sprintf("⚠️ Próg skali 32%%: %.0f PLN dochodu — %.0f%% progu 120k PLN. Powyżej 120k = 32%% PIT!", [income, income / 120000 * 100])] if {
    income := object.get(profile, "cumulative_income_current_year", 0)
    income > object.get(early_w, "scale_threshold_80pct", 96000)
} else = []

warning_health(profile, early_w, health_limit) = [sprintf("⚠️ Odliczenie zdrowotnej: %.0f PLN — %.0f%% limitu %.0f PLN. Niewykorzystany limit przepada!", [used, used / health_limit * 100, health_limit])] if {
    used := object.get(profile, "health_annual_paid", 0)
    used > object.get(early_w, "health_deduction_80pct", 10320)
} else = []

threshold_warning_list(profile, early_w, health_limit) = array.concat(array.concat(warning_lump(profile, early_w), warning_pit0(profile, early_w)), array.concat(warning_scale(profile, early_w), warning_health(profile, early_w, health_limit)))

build_threshold_warnings(warnings) = lines {
    header := ["🚨 MONITOR LIMITÓW — WCZESNE OSTRZEGANIE", sprintf("   Wykryto %d ostrzeżeń:", [count(warnings)])]
    lines := array.concat(array.concat(header, warnings), ["", "💡 DZIAŁAJ ZANIM PRZEKROCZYSZ LIMIT — zaplanuj optymalizację przed końcem roku!"])
}

build_full_simulation_warnings(_, optimal, scale, linear, lump, savings, optimal_total, be, health) = warnings {
    form_names := {"PIT_SCALE": "Skala 12%/32%", "LINEAR": "Liniowy 19%", "LUMP_SUM": "Ryczałt"}
    warnings := [
        "📊 TAX FORM OPTIMIZER — PEŁNA SYMULACJA",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("   Skala 12/32%%:     %10.0f PLN/rok", [scale]),
        sprintf("   Liniowy 19%%:      %10.0f PLN/rok", [linear]),
        sprintf("   Ryczałt:           %10.0f PLN/rok", [lump]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("   🏆 OPTYMALNIE: %s — %.0f PLN/rok", [object.get(form_names, optimal, ""), optimal_total]),
        sprintf("   💰 Oszczędność vs obecna forma: %.0f PLN/rok", [savings]),
        sprintf("   📍 Break-even skala vs liniowy: ~%.0f PLN dochodu", [be]),
        "",
        sprintf("   %s", [health])
    ]
}

cashflow_health_for_form(profit, form) = value {
    values := {
        "PIT_SCALE": profit * 0.09,
        "LINEAR": min([profit * 0.049, 12900]),
    }
    value := values[form]
}

pit_tax_for_cashflow(profit, form) = tax {
    values := {
        "PIT_SCALE": profit * 0.12 + max([profit - 120000, 0]) * 0.20,
        "LINEAR": profit * 0.19,
    }
    tax := values[form]
}

default decide := {"matched": false, "rule_id": "jdg.form_optimizer.no_match", "package": "jdg.form_optimizer", "priority": 999}
    "valid_from":"2024-01-01","valid_to":"9999-12-31","temporal_source":"Ustawa z dnia 26 lipca 1991 r. o podatku dochodowym od osob fizycznych"

decide := {
    "matched": true,
    "rule_id": "jdg.form_optimizer.financial_simulator",
    "package": "jdg.form_optimizer",
    "priority": 1785,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "sim_scale_tax": scale_tax, "sim_scale_health": scale_health, "sim_scale_total": scale_total,
    "sim_linear_tax": linear_tax, "sim_linear_health": linear_health,
    "sim_linear_health_deduction": linear_health_ded, "sim_linear_total": linear_total,
    "sim_lump_tax": lump_tax, "sim_lump_health": lump_health, "sim_lump_total": lump_total,
    "sim_optimal_form": optimal_form, "sim_optimal_total": optimal_total,
    "sim_savings_vs_current": savings_vs_current, "sim_break_even_scale_vs_linear": breakeven,
    "_routing": sim_rt,
    "_routing_reason": sprintf("TAX FORM OPTIMIZER: %s → %s oszczędza %.2f PLN/rok (%.1f%%)", [current_form, optimal_form, savings_vs_current, savings_pct]),
    "_legal_basis": "Art. 9a, 27, 30c PIT; Ustawa o ryczałcie; Art. 79-81 ustawy zdrowotnej",
    "_warnings": build_full_simulation_warnings(current_form, optimal_form, scale_total, linear_total, lump_total, savings_vs_current, optimal_total, breakeven, health_impact)
} if {
    input.simulate_full_tax_form == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_projected", 200000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_projected", 60000)
    annual_profit := annual_revenue - annual_costs
    business_type := object.get(input.jdg_entrepreneur, "business_type", "SERVICES")
    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "avg_monthly_wage", 9100)
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    tax_free := object.get(object.get(data.thresholds, "pit", {}), "tax_free_amount", 30000)
    scale_income := max([annual_profit - tax_free, 0])
    scale_low := min([scale_income, scale_threshold - tax_free])
    scale_tax := scale_low * 0.12 + max([annual_profit - scale_threshold, 0]) * 0.32
    scale_health := annual_profit * 0.09
    scale_total := scale_tax + scale_health
    linear_tax := annual_profit * 0.19
    linear_health := annual_profit * 0.049
    linear_health_ded := min([linear_health, data.thresholds.limits.health_linear_deduction_limit])
    linear_total := linear_tax + linear_health - linear_health_ded
    lump_rates := {"IT": 0.12, "SERVICES": 0.15, "CONSULTING": 0.17, "TRADING": 0.03, "CONSTRUCTION": 0.055, "TRANSPORT": 0.055}
    lump_rate := object.get(lump_rates, business_type, 0.15)
    lump_tax := annual_revenue * lump_rate
    lump_health := lump_health_for(avg_wage, annual_revenue)
    lump_health_ded := floor(lump_health * 0.50 * 100) / 100
    lump_total := lump_tax + lump_health - lump_health_ded
    best := best_form_for(scale_total, linear_total, lump_total)
    optimal_form := best.form
    optimal_total := best.total
    current_total := object.get({"PIT_SCALE": scale_total, "LINEAR": linear_total, "LUMP_SUM": lump_total}, current_form, scale_total)
    savings_vs_current := current_total - optimal_total
    savings_pct := savings_pct_for(current_total, savings_vs_current)
    breakeven := 135000
    health_impact := sprintf("Składka zdrowotna: skala %.0f PLN (9%%, NIEodliczalna) | liniowy %.0f PLN (4.9%%, odliczalne %.0f PLN) | ryczałt %.0f PLN (odliczalne 50%%)", [scale_health, linear_health, linear_health_ded, lump_health])
    sim_rt := simulation_routing_for(savings_vs_current)
}

# FTS-1786: HEALTH CONTRIBUTION BREAK-EVEN
else := {
    "matched": true, "rule_id": "jdg.form_optimizer.health_breakeven", "package": "jdg.form_optimizer", "priority": 1786,
    "opt_breakeven_income": breakeven_income, "opt_breakeven_analysis": analysis, "opt_recommendation": recommendation,
    "_routing": "", "_routing_reason": sprintf("Break-even skala vs liniowy: %.0f PLN dochodu. %s", [breakeven_income, recommendation]),
    "_legal_basis": "Art. 27, 30c PIT; Art. 79-81 ustawy zdrowotnej",
    "_warnings": [sprintf("⚖️ BREAK-EVEN SKALA vs LINIOWY — dochód %.0f PLN → %s", [annual_profit, recommendation])]
} if {
    input.simulate_health_breakeven == true
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_projected", 100000)
    breakeven_income := 110000
    analysis := sprintf("Przy dochodzie %.0f PLN:", [annual_profit])
    recommendation := health_recommendation_for(annual_profit, breakeven_income)
}

# FTS-1788: EARLY WARNING THRESHOLD MONITOR
else := {
    "matched": true, "rule_id": "jdg.form_optimizer.threshold_monitor", "package": "jdg.form_optimizer", "priority": 1788,
    "opt_warnings": active_warnings, "opt_warning_count": count(active_warnings), "_routing": monitor_rt,
    "_routing_reason": sprintf("Monitor limitów: %d ostrzeżeń", [count(active_warnings)]),
    "_legal_basis": "Art. 9a PIT; Art. 6 ustawy o ryczałcie; Art. 18c SUS", "_warnings": build_threshold_warnings(active_warnings)
} if {
    input.monitor_thresholds == true
    active_warnings := threshold_warning_list(input.jdg_entrepreneur, object.get(data.thresholds, "early_warning", {}), data.thresholds.limits.health_linear_deduction_limit)
    monitor_rt := simulation_routing_for(count(active_warnings) * 5001)
}

# FTS-1789: CASH-FLOW TAX IMPACT PREDICTOR
else := {
    "matched": true, "rule_id": "jdg.form_optimizer.cashflow_predictor", "package": "jdg.form_optimizer", "priority": 1789,
    "cf_annual_tax_burden": annual_burden, "cf_monthly_average": monthly_avg,
    "cf_highest_burden_month": highest_month, "cf_highest_burden_amount": highest_amount,
    "cf_recommended_monthly_reserve": monthly_reserve, "_routing": cf_rt,
    "_routing_reason": sprintf("Cash-Flow Predictor: %.0f PLN/rok obciążeń, ~%.0f PLN/mies. Rezerwa: %.0f PLN/mies", [annual_burden, monthly_avg, monthly_reserve]),
    "_legal_basis": "Art. 44 PIT; Art. 79 ustawy zdrowotnej; Art. 18 SUS",
    "_warnings": [sprintf("💵 CASH-FLOW TAX IMPACT PREDICTOR — roczne obciążenia %.0f PLN, rezerwa %.0f PLN/mies", [annual_burden, monthly_reserve])]
} if {
    input.simulate_cashflow_impact == true
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_projected", 200000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_projected", 60000)
    annual_profit := annual_revenue - annual_costs
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_tax := pit_tax_for_cashflow(annual_profit, tax_form)
    health := cashflow_health_for_form(annual_profit, tax_form)
    zus_annual := 1800 * 12
    annual_burden := pit_tax + health + zus_annual
    monthly_avg := floor(annual_burden / 12)
    monthly_reserve := floor(monthly_avg * 1.2)
    highest_month := "kwiecień/maj (PIT roczny + ZUS)"
    highest_amount := floor(monthly_avg * 2.5)
    cf_rt := simulation_routing_for(monthly_reserve)
}

# Fallback
else := {
    "matched": true, "rule_id": "jdg.form_optimizer.fallback", "package": "jdg.form_optimizer", "priority": 999,
    "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 9a, 27, 30c PIT",
    "_warnings": ["Tax Form Optimizer — porównaj formy opodatkowania finansowo (z uwzględnieniem składki zdrowotnej!), monitoruj limity, planuj cash-flow."]
} if { true }
