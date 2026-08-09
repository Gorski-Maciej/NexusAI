# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — EXIT TAX INTEREST CALCULATOR (P13 Priority 2)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.exit_tax_interest_calculator
# Purpose: Calculate exit-tax installments, interest and alternatives.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.exit_tax_interest_calculator

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.exit_tax_interest_calculator.no_match",
    "package": "jdg.exit_tax_interest_calculator",
    "priority": 999999,
}

exit_tax_base_for(gain) = gain {
    gain > 0
} else = 0 {
    gain <= 0
}

exit_tax_for_base(base) = tax {
    tax := floor(base * 0.19 * 100) / 100
}

installments_for(deferral_available) = 5 {
    deferral_available == true
} else = 1 {
    deferral_available == false
}

installment_principal_for(tax, installments) = principal {
    tax > 0
    principal := floor(tax / installments * 100) / 100
} else = 0 {
    tax <= 0
}

remaining_balance_for(tax, ratio) = balance {
    tax > 0
    balance := floor(tax * ratio * 100) / 100
} else = 0 {
    tax <= 0
}

interest_for(balance, annual_rate) = interest {
    interest := floor(balance * annual_rate * 100) / 100
}

routing_for(tax, deferral_available) = "TRIAGE_QUEUE" {
    tax > 0
    deferral_available == true
} else = "BLOCK_AND_ALERT" {
    tax > 0
    deferral_available == false
} else = "" {
    tax == 0
}

schedule_entry(tax, annual_rate, year, ratio, include) = [] {
    include == false
} else = [{
    "year": year,
    "principal": floor(tax * 0.20 * 100) / 100,
    "remaining_balance": remaining_balance_for(tax, ratio),
    "interest_accrued": interest_for(remaining_balance_for(tax, ratio), annual_rate),
    "total_due": floor((tax * 0.20 + interest_for(remaining_balance_for(tax, ratio), annual_rate)) * 100) / 100,
}] {
    include == true
}

schedule_for(tax, annual_rate, installments) = schedule {
    y1 := schedule_entry(tax, annual_rate, 1, 1.00, installments >= 1)
    y2 := schedule_entry(tax, annual_rate, 2, 0.80, installments >= 2)
    y3 := schedule_entry(tax, annual_rate, 3, 0.60, installments >= 3)
    y4 := schedule_entry(tax, annual_rate, 4, 0.40, installments >= 4)
    y5 := schedule_entry(tax, annual_rate, 5, 0.20, installments >= 5)
    schedule := array.concat(array.concat(array.concat(array.concat(y1, y2), y3), y4), y5)
}

total_interest_for(tax, annual_rate, installments) = total {
    y1 := interest_for(remaining_balance_for(tax, 1.00), annual_rate)
    y2 := interest_for(remaining_balance_for(tax, 0.80), annual_rate)
    y3 := interest_for(remaining_balance_for(tax, 0.60), annual_rate)
    y4 := interest_for(remaining_balance_for(tax, 0.40), annual_rate)
    y5 := interest_for(remaining_balance_for(tax, 0.20), annual_rate)
    total := y1 + y2 * bool_number(installments >= 2) + y3 * bool_number(installments >= 3) + y4 * bool_number(installments >= 4) + y5 * bool_number(installments >= 5)
}

bool_number(value) = 1 {
    value == true
} else = 0 {
    value == false
}

recommendation_for(exit_tax) = "INSTALLMENTS" {
    exit_tax > 100000
    exit_tax < 4000000
} else = "LUMP_SUM" {
    exit_tax <= 100000
} else = "INSTALLMENTS" {
    exit_tax >= 4000000
}

optimal_method_for(fmv, gain, tax19, tax3) = "19pct_of_gain" {
    gain > 0
    tax19 < tax3
} else = "3pct_of_fmv" {
    fmv < 4000000
    tax3 < tax19
} else = "19pct_only" {
    fmv >= 4000000
} else = "none" {
    fmv == 0
    gain <= 0
}

optimal_amount_for(method, tax19, tax3) = tax19 {
    method in {"19pct_of_gain", "19pct_only"}
} else = tax3 {
    method == "3pct_of_fmv"
} else = 0 {
    method == "none"
}

savings_for(method, tax19, tax3, optimal) = savings {
    method == "3pct_of_fmv"
    savings := floor((tax19 + tax3 - optimal * 2 + 0.01) * 100) / 100
} else = savings {
    method == "19pct_of_gain"
    savings := floor((-1) * (optimal - tax3) * 100) / 100
} else = 0 {
    method in {"19pct_only", "none"}
}

# EIC-001: 5-year installment schedule with interest.
decide := verdict {
    object.get(input.jdg_entrepreneur, "planning_migration", false) == true

    asset_fmv := object.get(input.jdg_entrepreneur, "asset_fmv_total", 0)
    asset_basis := object.get(input.jdg_entrepreneur, "asset_tax_basis_total", 0)
    destination := object.get(input.jdg_entrepreneur, "migration_destination", "N/A")
    unrealized_gain := asset_fmv - asset_basis
    exit_tax_base := exit_tax_base_for(unrealized_gain)
    exit_tax_19pct := exit_tax_for_base(exit_tax_base)

    eu_eea := {"AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IS", "IE", "IT", "LV", "LI", "LT", "LU", "MT", "NL", "NO", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "CH"}
    deferral_available := destination in eu_eea
    installments := installments_for(deferral_available)
    annual_interest_rate := 0.08
    monthly_interest_rate := annual_interest_rate / 12
    installment_principal := installment_principal_for(exit_tax_19pct, installments)
    schedule := schedule_for(exit_tax_19pct, annual_interest_rate, installments)
    total_interest := total_interest_for(exit_tax_19pct, annual_interest_rate, installments)
    total_with_interest := floor((exit_tax_19pct + total_interest) * 100) / 100
    routing := routing_for(exit_tax_19pct, deferral_available)

    verdict := {
        "matched": true,
        "rule_id": "jdg.exit_tax_interest_calculator.interest_schedule",
        "package": "jdg.exit_tax_interest_calculator",
        "priority": 18201,
        "eic_exit_tax_19pct": exit_tax_19pct,
        "eic_installments": installments,
        "eic_deferral_available": deferral_available,
        "eic_annual_interest_rate_pct": annual_interest_rate * 100,
        "eic_monthly_interest_rate_pct": floor(monthly_interest_rate * 100 * 100) / 100,
        "eic_installment_principal": installment_principal,
        "eic_installment_schedule": schedule,
        "eic_total_interest": total_interest,
        "eic_total_with_interest": total_with_interest,
        "eic_destination": destination,
        "eic_pit_nz_due": "7. dzień miesiąca po miesiącu przeniesienia aktywów",
        "_routing": routing,
        "_routing_reason": sprintf("Exit Tax Interest: %.0f PLN in %d installments + %.0f PLN interest = %.0f PLN total. Rate: %.0f%%/yr. Deferral: %s", [exit_tax_19pct, installments, total_interest, total_with_interest, annual_interest_rate * 100, deferral_available]),
        "_legal_basis": "Art. 30da-30db PIT; Art. 56 OrdPU",
        "_description": "EIC-001: Exit Tax interest calculator — 5-year installment schedule with compound interest at 8%/yr",
    }
}

# EIC-002: lump-sum versus installment comparison.
else := verdict {
    object.get(input.jdg_entrepreneur, "planning_migration", false) == true
    asset_fmv := object.get(input.jdg_entrepreneur, "asset_fmv_total", 0)
    unrealized_gain := asset_fmv - object.get(input.jdg_entrepreneur, "asset_tax_basis_total", 0)
    exit_tax := exit_tax_for_base(exit_tax_base_for(unrealized_gain))
    lump_sum_total := exit_tax
    interest_rate := 0.08
    installment_total := floor(exit_tax * (1 + interest_rate * 2.5) * 100) / 100
    savings_lump := floor((installment_total - lump_sum_total) * 100) / 100
    recommendation := recommendation_for(exit_tax)

    verdict := {
        "matched": true,
        "rule_id": "jdg.exit_tax_interest_calculator.comparison",
        "package": "jdg.exit_tax_interest_calculator",
        "priority": 18202,
        "eic_lump_sum_total": lump_sum_total,
        "eic_installment_total_estimated": installment_total,
        "eic_savings_lump_vs_installments": savings_lump,
        "eic_recommendation": recommendation,
        "_routing": "",
        "_routing_reason": sprintf("Exit Tax Comparison: Lump sum %.0f PLN vs Installments ~%.0f PLN → Recommend: %s", [lump_sum_total, installment_total, recommendation]),
        "_legal_basis": "Art. 30da-30db PIT",
        "_description": "EIC-002: Exit Tax payment comparison — lump sum vs 5-year installments",
    }
}

# EIC-003: 3% FMV alternative for assets below 4M PLN.
else := verdict {
    object.get(input.jdg_entrepreneur, "planning_migration", false) == true
    asset_fmv := object.get(input.jdg_entrepreneur, "asset_fmv_total", 0)
    asset_basis := object.get(input.jdg_entrepreneur, "asset_tax_basis_total", 0)
    unrealized_gain := asset_fmv - asset_basis
    exit_tax_19pct := exit_tax_for_base(exit_tax_base_for(unrealized_gain))
    exit_tax_3pct := 0.03 * asset_fmv
    optimal_method := optimal_method_for(asset_fmv, unrealized_gain, exit_tax_19pct, exit_tax_3pct)
    optimal_amount := optimal_amount_for(optimal_method, exit_tax_19pct, exit_tax_3pct)
    savings := savings_for(optimal_method, exit_tax_19pct, exit_tax_3pct, optimal_amount)

    verdict := {
        "matched": true,
        "rule_id": "jdg.exit_tax_interest_calculator.alternative_3pct",
        "package": "jdg.exit_tax_interest_calculator",
        "priority": 18203,
        "eic_asset_fmv": asset_fmv,
        "eic_unrealized_gain": unrealized_gain,
        "eic_exit_tax_19pct": exit_tax_19pct,
        "eic_exit_tax_3pct": exit_tax_3pct,
        "eic_optimal_method": optimal_method,
        "eic_optimal_amount": optimal_amount,
        "eic_savings": savings,
        "eic_threshold_4m": 4000000,
        "_routing": "",
        "_routing_reason": sprintf("Exit Tax Optimization: 19%%=%.0f PLN vs 3%%=%.0f PLN → Optimal: %s = %.0f PLN", [exit_tax_19pct, exit_tax_3pct, optimal_method, optimal_amount]),
        "_legal_basis": "Art. 30da ust. 2 PIT",
        "_description": "EIC-003: Exit Tax alternative — 3% of FMV vs 19% of unrealized gain optimization",
    }
}
