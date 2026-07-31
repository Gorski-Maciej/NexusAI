# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — EXIT TAX INTEREST CALCULATOR (P13 Priority 2)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.exit_tax_interest_calculator
# Report:      RAPORT_P13 Section 7 — Priority 2
# Purpose:     Calculate interest on exit tax installments (Art. 30db PIT)
#              5-year installments with daily compound interest tracking
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.exit_tax_interest_calculator

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.exit_tax_interest_calculator.no_match",
    "package": "jdg.exit_tax_interest_calculator",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# EIC-001: EXIT TAX INTEREST CALCULATOR — 5 rat × odsetki
# Kalkulacja harmonogramu rat z odsetkami od zaległości podatkowych
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "planning_migration", false) == true

    asset_fmv := object.get(input.jdg_entrepreneur, "asset_fmv_total", 0)
    asset_basis := object.get(input.jdg_entrepreneur, "asset_tax_basis_total", 0)
    destination := object.get(input.jdg_entrepreneur, "migration_destination", "N/A")

    unrealized_gain := asset_fmv - asset_basis
    exit_tax_base := unrealized_gain { unrealized_gain > 0 }
    exit_tax_base := 0 { unrealized_gain <= 0 }

    exit_tax_19pct := floor(exit_tax_base * 0.19 * 100) / 100

    eu_eea := {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IS","IE","IT","LV","LI","LT","LU","MT","NL","NO","PL","PT","RO","SK","SI","ES","SE","CH"}
    deferral_available := destination in eu_eea
    installments := 5 { deferral_available }
    installments := 1 { not deferral_available }

    # Current NBP reference rate + 2% margin = ~8% (standard for tax arrears)
    annual_interest_rate := 0.08
    monthly_interest_rate := annual_interest_rate / 12

    installment_principal := floor(exit_tax_19pct / installments * 100) / 100 { exit_tax_19pct > 0 }
    installment_principal := 0 { exit_tax_19pct <= 0 }

    # Calculate interest for each installment (compounding annually)
    total_interest := 0.0
    schedule := []

    # Year 1: full amount × 8%
    interest_y1 := floor(exit_tax_19pct * annual_interest_rate * 100) / 100 { exit_tax_19pct > 0 }
    interest_y1 := 0 { exit_tax_19pct <= 0 }
    schedule := array.concat(schedule, [{
        "year": 1,
        "principal": floor(exit_tax_19pct * 0.20 * 100) / 100,
        "remaining_balance": exit_tax_19pct,
        "interest_accrued": interest_y1,
        "total_due_year1": floor((exit_tax_19pct * 0.20 + interest_y1) * 100) / 100
    }]) { exit_tax_19pct > 0; installments >= 1 }
    total_interest := total_interest + interest_y1

    # Year 2: remaining 80% × 8%
    remaining_y2 := floor(exit_tax_19pct * 0.80 * 100) / 100 { exit_tax_19pct > 0 }
    remaining_y2 := 0 { exit_tax_19pct <= 0 }
    interest_y2 := floor(remaining_y2 * annual_interest_rate * 100) / 100
    schedule := array.concat(schedule, [{
        "year": 2,
        "principal": floor(exit_tax_19pct * 0.20 * 100) / 100,
        "remaining_balance": remaining_y2,
        "interest_accrued": interest_y2,
        "total_due_year2": floor((exit_tax_19pct * 0.20 + interest_y2) * 100) / 100
    }]) { installments >= 2 }
    total_interest := total_interest + interest_y2

    # Year 3: remaining 60% × 8%
    remaining_y3 := floor(exit_tax_19pct * 0.60 * 100) / 100 { exit_tax_19pct > 0 }
    remaining_y3 := 0 { exit_tax_19pct <= 0 }
    interest_y3 := floor(remaining_y3 * annual_interest_rate * 100) / 100
    schedule := array.concat(schedule, [{
        "year": 3,
        "principal": floor(exit_tax_19pct * 0.20 * 100) / 100,
        "remaining_balance": remaining_y3,
        "interest_accrued": interest_y3,
        "total_due_year3": floor((exit_tax_19pct * 0.20 + interest_y3) * 100) / 100
    }]) { installments >= 3 }
    total_interest := total_interest + interest_y3

    # Year 4: remaining 40% × 8%
    remaining_y4 := floor(exit_tax_19pct * 0.40 * 100) / 100 { exit_tax_19pct > 0 }
    remaining_y4 := 0 { exit_tax_19pct <= 0 }
    interest_y4 := floor(remaining_y4 * annual_interest_rate * 100) / 100
    schedule := array.concat(schedule, [{
        "year": 4,
        "principal": floor(exit_tax_19pct * 0.20 * 100) / 100,
        "remaining_balance": remaining_y4,
        "interest_accrued": interest_y4,
        "total_due_year4": floor((exit_tax_19pct * 0.20 + interest_y4) * 100) / 100
    }]) { installments >= 4 }
    total_interest := total_interest + interest_y4

    # Year 5: remaining 20% × 8%
    remaining_y5 := floor(exit_tax_19pct * 0.20 * 100) / 100 { exit_tax_19pct > 0 }
    remaining_y5 := 0 { exit_tax_19pct <= 0 }
    interest_y5 := floor(remaining_y5 * annual_interest_rate * 100) / 100
    schedule := array.concat(schedule, [{
        "year": 5,
        "principal": floor(exit_tax_19pct * 0.20 * 100) / 100,
        "remaining_balance": 0,
        "interest_accrued": interest_y5,
        "total_due_year5": floor((exit_tax_19pct * 0.20 + interest_y5) * 100) / 100
    }]) { installments >= 5 }
    total_interest := total_interest + interest_y5

    total_with_interest := floor((exit_tax_19pct + total_interest) * 100) / 100

    routing := "TRIAGE_QUEUE" { exit_tax_19pct > 0 and deferral_available }
    routing := "BLOCK_AND_ALERT" { exit_tax_19pct > 0 and not deferral_available }
    routing := "" { exit_tax_19pct == 0 }

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
        "eic_installment_schedule": schedule,
        "eic_total_interest": total_interest,
        "eic_total_with_interest": total_with_interest,
        "eic_destination": destination,
        "eic_pit_nz_due": "7. dzień miesiąca po miesiącu przeniesienia aktywów",
        "_routing": routing,
        "_routing_reason": sprintf("Exit Tax Interest: %.0f PLN in %d installments + %.0f PLN interest = %.0f PLN total. Rate: %.0f%%/yr. Deferral: %s", [exit_tax_19pct, installments, total_interest, total_with_interest, annual_interest_rate * 100, deferral_available]),
        "_legal_basis": "Art. 30da-30db PIT; Art. 56 OrdPU (odsetki od zaległości podatkowych)",
        "_description": "EIC-001: Exit Tax interest calculator — 5-year installment schedule with compound interest at 8%/yr"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EIC-002: EXIT TAX COMPARISON — jednorazowo vs raty
# Porównanie kosztów: płatność jednorazowa vs ratalna
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "planning_migration", false) == true

    asset_fmv := object.get(input.jdg_entrepreneur, "asset_fmv_total", 0)
    unrealized_gain := asset_fmv - object.get(input.jdg_entrepreneur, "asset_tax_basis_total", 0)
    exit_tax := floor(unrealized_gain * 0.19 * 100) / 100 { unrealized_gain > 0 }
    exit_tax := 0 { unrealized_gain <= 0 }

    lump_sum_total := exit_tax
    interest_rate := 0.08
    installment_total := floor(exit_tax * (1 + interest_rate * 2.5) * 100) / 100  # avg 2.5 years × 8%

    savings_lump := floor(installment_total - lump_sum_total * 100) / 100
    recommendation := "INSTALLMENTS" { exit_tax > 100000; exit_tax < 4000000 }
    recommendation := "LUMP_SUM" { exit_tax <= 100000 }
    recommendation := "INSTALLMENTS" { exit_tax >= 4000000 }

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
        "_description": "EIC-002: Exit Tax payment comparison — lump sum vs 5-year installments"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# EIC-003: EXIT TAX 3% ALTERNATIVE (dla FMV < 4M PLN)
# Dla wartości aktywów < 4M PLN: podatek 3% od FMV zamiast 19% od zysku
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "planning_migration", false) == true

    asset_fmv := object.get(input.jdg_entrepreneur, "asset_fmv_total", 0)
    asset_basis := object.get(input.jdg_entrepreneur, "asset_tax_basis_total", 0)
    unrealized_gain := asset_fmv - asset_basis

    exit_tax_19pct := floor(unrealized_gain * 0.19 * 100) / 100 { unrealized_gain > 0 }
    exit_tax_19pct := 0 { unrealized_gain <= 0 }

    exit_tax_3pct := floor(asset_fmv * 0.03 * 100) / 100 { asset_fmv < 4000000 }
    exit_tax_3pct := 0 { asset_fmv >= 4000000 }

    optimal_method := "19pct_of_gain" { unrealized_gain > 0 and exit_tax_19pct < exit_tax_3pct }
    optimal_method := "3pct_of_fmv" { asset_fmv < 4000000 and exit_tax_3pct < exit_tax_19pct }
    optimal_method := "19pct_only" { asset_fmv >= 4000000 }
    optimal_method := "none" { asset_fmv == 0 and unrealized_gain <= 0 }

    optimal_amount := exit_tax_19pct { optimal_method == "19pct_of_gain" or optimal_method == "19pct_only" }
    optimal_amount := exit_tax_3pct { optimal_method == "3pct_of_fmv" }
    optimal_amount := 0 { optimal_method == "none" }

    savings := floor((exit_tax_19pct + exit_tax_3pct - optimal_amount * 2 + 0.01) * 100) / 100 { optimal_method == "3pct_of_fmv" }
    savings := floor(((-1) * (optimal_amount - exit_tax_3pct)) * 100) / 100 { optimal_method == "19pct_of_gain" }
    savings := 0 { true }

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
        "eic_threshold_4m": 4000000,
        "_routing": "",
        "_routing_reason": sprintf("Exit Tax Optimization: 19%%=%.0f PLN vs 3%%=%.0f PLN → Optimal: %s = %.0f PLN", [exit_tax_19pct, exit_tax_3pct, optimal_method, optimal_amount]),
        "_legal_basis": "Art. 30da ust. 2 PIT",
        "_description": "EIC-003: Exit Tax alternative — 3% of FMV vs 19% of unrealized gain optimization"
    }
}
