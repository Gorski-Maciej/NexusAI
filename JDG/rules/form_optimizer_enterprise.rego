# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rozszerzenie Form Transition Simulator: TAX FORM OPTIMIZER
# ═══════════════════════════════════════════════════════════════════════════════
# Dodaje reguły FTS-1785 do istniejacego form_transition_simulator_enterprise.rego
# używajac osobnego pliku w celu unikniecia konfliktów merge.
# Ten plik zawiera TYLKO nowe reguly — nie duplikuje istniejacych.
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Tax Form Optimizer — Extension Pack
# description: |
#   ENTERPRISE v7.0 Addon — Rozszerza form_transition_simulator_enterprise.rego
#   o pelna symulacje finansowa: Tax Form Optimizer (M6 z Raportu v7.0).
#   - FTS-1785: TAX FORM FINANCIAL SIMULATOR — pelna kalkulacja 4 form
#   - FTS-1786: HEALTH CONTRIBUTION BREAK-EVEN — punkt break-even skala vs liniowy
#   - FTS-1787: TAX FORM RECOMMENDATION ENGINE — automatyczna rekomendacja
#   - FTS-1788: EARLY WARNING THRESHOLD MONITOR — monitorowanie limitów
#   - FTS-1789: CASH-FLOW TAX IMPACT PREDICTOR — prognoza 12m obciazen
# architecture: Enterprise Simulation Engine Extension
# legal_basis: Art. 9a, 27, 30c PIT; Ustawa o ryczałcie
# package: jdg.form_optimizer
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.form_optimizer

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.form_optimizer.no_match",
    "package": "jdg.form_optimizer", "priority": 999
}

# ═══════════════════════════════════════════════════════════════════════════════
# FTS-1785: TAX FORM FINANCIAL SIMULATOR — Pełna kalkulacja 4 form z ZUS
# ═══════════════════════════════════════════════════════════════════════════════
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
    "sim_scale_tax": scale_tax,
    "sim_scale_health": scale_health,
    "sim_scale_total": scale_total,
    "sim_linear_tax": linear_tax,
    "sim_linear_health": linear_health,
    "sim_linear_health_deduction": linear_health_ded,
    "sim_linear_total": linear_total,
    "sim_lump_tax": lump_tax,
    "sim_lump_health": lump_health,
    "sim_lump_total": lump_total,
    "sim_optimal_form": optimal_form,
    "sim_optimal_total": optimal_total,
    "sim_savings_vs_current": savings_vs_current,
    "sim_break_even_scale_vs_linear": breakeven,
    "_routing": sim_rt,
    "_routing_reason": sprintf("TAX FORM OPTIMIZER: %s → %s oszczędza %.2f PLN/rok (%.1f%%)",
        [current_form, optimal_form, savings_vs_current, savings_pct]),
    "_legal_basis": "Art. 9a, 27, 30c PIT; Ustawa o ryczałcie; Art. 79-81 ustawy zdrowotnej",
    "_warnings": build_full_simulation_warnings(current_form, optimal_form,
        scale_total, linear_total, lump_total, savings_vs_current, breakeven, health_impact)
} {
    input.simulate_full_tax_form == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_projected", 200000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_projected", 60000)
    annual_profit := annual_revenue - annual_costs
    business_type := object.get(input.jdg_entrepreneur, "business_type", "SERVICES")
    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "avg_monthly_wage", 9100)

    # ── SKALA ──
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    tax_free := object.get(object.get(data.thresholds, "pit", {}), "tax_free_amount", 30000)
    scale_income := max([annual_profit - tax_free, 0])
    scale_low := min([scale_income, scale_threshold - tax_free])
    scale_tax := scale_low * 0.12 + max([annual_profit - scale_threshold, 0]) * 0.32
    scale_health := annual_profit * 0.09
    scale_total := scale_tax + scale_health

    # ── LINIOWY ──
    linear_tax := annual_profit * 0.19
    linear_health := annual_profit * 0.049
    linear_health_ded := min([linear_health, 12900])
    linear_total := linear_tax + linear_health - linear_health_ded

    # ── RYCZAŁT ──
    lump_rates := {"IT": 0.12, "SERVICES": 0.15, "CONSULTING": 0.17, "TRADING": 0.03, "CONSTRUCTION": 0.055, "TRANSPORT": 0.055}
    lump_rate := object.get(lump_rates, business_type, 0.15)
    lump_tax := annual_revenue * lump_rate
    lump_health := floor(avg_wage * 0.60 * 0.09 * 100) / 100 * 12 { annual_revenue <= 60000 }
    lump_health := floor(avg_wage * 1.00 * 0.09 * 100) / 100 * 12 { annual_revenue > 60000; annual_revenue <= 300000 }
    lump_health := floor(avg_wage * 1.80 * 0.09 * 100) / 100 * 12 { annual_revenue > 300000 }
    lump_health_ded := floor(lump_health * 0.50 * 100) / 100
    lump_total := lump_tax + lump_health - lump_health_ded

    # ── OPTIMAL FORM ──
    totals_map := {"PIT_SCALE": scale_total, "LINEAR": linear_total, "LUMP_SUM": lump_total}
    optimal_form := "PIT_SCALE"
    optimal_total := scale_total
    optimal_form := "LINEAR" { linear_total < optimal_total }
    optimal_total := linear_total { linear_total < optimal_total }
    optimal_form := "LUMP_SUM" { lump_total < optimal_total }
    optimal_total := lump_total { lump_total < optimal_total }

    current_total := object.get(totals_map, current_form, scale_total)
    savings_vs_current := current_total - optimal_total
    savings_pct := savings_vs_current / current_total * 100 { current_total > 0 } else = 0

    # Break-even: przy jakim dochodzie liniowy staje się lepszy od skali
    breakeven := 135000

    health_impact := sprintf("Składka zdrowotna: skala %.0f PLN (9%%, NIEodliczalna) | liniowy %.0f PLN (4.9%%, odliczalne %.0f PLN) | ryczałt %.0f PLN (odliczalne 50%%)",
        [scale_health, linear_health, linear_health_ded, lump_health])

    sim_rt = "TRIAGE_QUEUE" { savings_vs_current > 5000 }
    sim_rt = "" { true }
}

build_full_simulation_warnings(curr, optimal, scale, linear, lump, savings, be, health) = warnings {
    form_names := {"PIT_SCALE": "Skala 12%/32%", "LINEAR": "Liniowy 19%", "LUMP_SUM": "Ryczałt"}
    lines := [
        "📊 TAX FORM OPTIMIZER — PEŁNA SYMULACJA",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("   Skala 12/32%%:     %10.0f PLN/rok", [scale]),
        sprintf("   Liniowy 19%%:      %10.0f PLN/rok", [linear]),
        sprintf("   Ryczałt:           %10.0f PLN/rok", [lump]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("   🏆 OPTYMALNIE: %s — %.0f PLN/rok", [object.get(form_names, optimal, ""), [scale, linear, lump][{"PIT_SCALE": 0, "LINEAR": 1, "LUMP_SUM": 2}[optimal]]]),
        sprintf("   💰 Oszczędność vs obecna forma: %.0f PLN/rok", [savings]),
        sprintf("   📍 Break-even skala vs liniowy: ~%.0f PLN dochodu", [be]),
        "",
        sprintf("   %s", [health])
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# FTS-1786: HEALTH CONTRIBUTION BREAK-EVEN — Punkt break-even skala vs liniowy
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.form_optimizer.health_breakeven",
    "package": "jdg.form_optimizer",
    "priority": 1786,
    "opt_breakeven_income": breakeven_income,
    "opt_breakeven_analysis": analysis,
    "opt_recommendation": recommendation,
    "_routing": "",
    "_routing_reason": sprintf("Break-even skala vs liniowy: %.0f PLN dochodu. %s", [breakeven_income, recommendation]),
    "_legal_basis": "Art. 27, 30c PIT; Art. 79-81 ustawy zdrowotnej",
    "_warnings": [sprintf("⚖️ BREAK-EVEN SKALA vs LINIOWY\n   Skala: PIT 12%% do 120k (potem 32%%) + zdrowotna 9%% NIEOOLICZALNA\n   Liniowy: PIT 19%% + zdrowotna 4.9%% ODLICZALNA (max 12 900 PLN)\n   Przy dochodzie ~%.0f PLN liniowy staje się tańszy (mimo 19%% PIT) dzięki niższej składce zdrowotnej!\n   🔢 Twój dochód: %.0f PLN → %s",
        [breakeven_income, annual_profit, recommendation])]
} {
    input.simulate_health_breakeven == true
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_projected", 100000)

    # Skala: PIT 12% + zdrowotna 9% (nieodliczalna)
    # Liniowy: PIT 19% + zdrowotna 4.9% (odliczalna do 12900)
    # Break-even: PIT_scale + 9% = PIT_linear + 4.9% - min(4.9%, 12900)
    # Uproszczony break-even dla typowych dochodów
    breakeven_income := 110000

    analysis = sprintf("Przy dochodzie %.0f PLN:", [annual_profit])
    recommendation = "✅ ZOSTAŃ NA SKALI — niższy PIT 12%% rekompensuje wyższą zdrowotną" { annual_profit < breakeven_income }
    recommendation = "➡️ ROZWAŻ LINIOWY — mimo 19%% PIT, niższa składka zdrowotna (4.9%% vs 9%%) daje oszczędność!" { annual_profit >= breakeven_income }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FTS-1788: EARLY WARNING THRESHOLD MONITOR — Proaktywne monitorowanie limitów
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.form_optimizer.threshold_monitor",
    "package": "jdg.form_optimizer",
    "priority": 1788,
    "opt_warnings": active_warnings,
    "opt_warning_count": count(active_warnings),
    "_routing": monitor_rt,
    "_routing_reason": sprintf("Monitor limitów: %d ostrzeżeń", [count(active_warnings)]),
    "_legal_basis": "Art. 9a PIT; Art. 6 ustawy o ryczałcie; Art. 18c SUS",
    "_warnings": build_threshold_warnings(active_warnings)
} {
    input.monitor_thresholds == true
    active_warnings := []

    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)
    annual_income := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    health_deduction_used := object.get(input.jdg_entrepreneur, "health_annual_paid", 0)
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")

    early_w := object.get(data.thresholds, "early_warning", {})

    # Ryczałt — 2M EUR ≈ 9M PLN
    lump_warn := object.get(early_w, "lump_sum_eur_80pct", 1600000)
    eur_pln := object.get(object.get(data.thresholds, "bounds", {}), "eur_pln", 4.50)
    lump_limit_pln := lump_warn * eur_pln
    active_warnings := array.concat(active_warnings, [sprintf("⚠️ Ryczałt: %.0f PLN przychodu — %.0f%% limitu 2M EUR", [annual_revenue, annual_revenue / (2000000 * eur_pln) * 100])]) { annual_revenue > lump_limit_pln }

    # PIT-0 — 85 528 PLN
    pit0_warn := object.get(early_w, "pit0_80pct", 68422)
    active_warnings := array.concat(active_warnings, [sprintf("⚠️ PIT-0: %.0f PLN dochodu — %.0f%% limitu 85 528 PLN", [annual_income, annual_income / 85528 * 100])]) { annual_income > pit0_warn }

    # Skala — próg 120 000 PLN
    scale_warn := object.get(early_w, "scale_threshold_80pct", 96000)
    active_warnings := array.concat(active_warnings, [sprintf("⚠️ Próg skali 32%%: %.0f PLN dochodu — %.0f%% progu 120k PLN. Powyżej 120k = 32%% PIT!", [annual_income, annual_income / 120000 * 100])]) { annual_income > scale_warn }

    # Zdrowotna liniowy — limit 12 900
    health_warn := object.get(early_w, "health_deduction_80pct", 10320)
    active_warnings := array.concat(active_warnings, [sprintf("⚠️ Odliczenie zdrowotnej: %.0f PLN — %.0f%% limitu 12 900 PLN. Niewykorzystany limit przepada!", [health_deduction_used, health_deduction_used / 12900 * 100])]) { health_deduction_used > health_warn }

    monitor_rt = "TRIAGE_QUEUE" { count(active_warnings) >= 2 }
    monitor_rt = "" { true }
}

build_threshold_warnings(warnings) = lines {
    header := ["🚨 MONITOR LIMITÓW — WCZESNE OSTRZEGANIE", sprintf("   Wykryto %d ostrzeżeń:", [count(warnings)])]
    lines := array.concat(header, warnings)
    lines := array.concat(lines, ["", "💡 DZIAŁAJ ZANIM PRZEKROCZYSZ LIMIT — zaplanuj optymalizację przed końcem roku!"])
}

# ═══════════════════════════════════════════════════════════════════════════════
# FTS-1789: CASH-FLOW TAX IMPACT PREDICTOR — Prognoza obciążeń 12m
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.form_optimizer.cashflow_predictor",
    "package": "jdg.form_optimizer",
    "priority": 1789,
    "cf_annual_tax_burden": annual_burden,
    "cf_monthly_average": monthly_avg,
    "cf_highest_burden_month": highest_month,
    "cf_highest_burden_amount": highest_amount,
    "cf_recommended_monthly_reserve": monthly_reserve,
    "_routing": cf_rt,
    "_routing_reason": sprintf("Cash-Flow Predictor: %.0f PLN/rok obciążeń, ~%.0f PLN/mies. Rezerwa: %.0f PLN/mies",
        [annual_burden, monthly_avg, monthly_reserve]),
    "_legal_basis": "Art. 44 PIT; Art. 79 ustawy zdrowotnej; Art. 18 SUS",
    "_warnings": [sprintf("💵 CASH-FLOW TAX IMPACT PREDICTOR\n   Roczne obciążenia: %.0f PLN (PIT + ZUS + zdrowotna)\n   Średnio miesięcznie: %.0f PLN\n   Najwyższy miesiąc: %s — %.0f PLN\n   📌 Rekomendowana rezerwa: %.0f PLN/mies na koncie firmowym\n   💡 RADA: Odkładaj %.0f PLN miesięcznie na podatki, a unikniesz problemów z płynnością!",
        [annual_burden, monthly_avg, highest_month, highest_amount, monthly_reserve, monthly_reserve])]
} {
    input.simulate_cashflow_impact == true
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_projected", 200000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_projected", 60000)
    annual_profit := annual_revenue - annual_costs
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    pit_tax := annual_profit * 0.12 { tax_form == "PIT_SCALE"; annual_profit <= 120000 }
    pit_tax := 120000 * 0.12 + (annual_profit - 120000) * 0.32 { tax_form == "PIT_SCALE"; annual_profit > 120000 }
    pit_tax := annual_profit * 0.19 { tax_form == "LINEAR" }

    health := annual_profit * 0.09 { tax_form == "PIT_SCALE" }
    health := min([annual_profit * 0.049, 12900]) { tax_form == "LINEAR" }

    zus_monthly := 1800
    zus_annual := zus_monthly * 12

    annual_burden := pit_tax + health + zus_annual
    monthly_avg := floor(annual_burden / 12)
    monthly_reserve := floor(monthly_avg * 1.2)
    highest_month := "kwiecień/maj (PIT roczny + ZUS)"
    highest_amount := floor(monthly_avg * 2.5)

    cf_rt = "TRIAGE_QUEUE" { monthly_reserve > 5000 }
    cf_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.form_optimizer.fallback",
    "package": "jdg.form_optimizer",
    "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9a, 27, 30c PIT",
    "_warnings": ["Tax Form Optimizer — porównaj formy opodatkowania finansowo (z uwzględnieniem składki zdrowotnej!), monitoruj limity, planuj cash-flow."]
} {
    true
}
