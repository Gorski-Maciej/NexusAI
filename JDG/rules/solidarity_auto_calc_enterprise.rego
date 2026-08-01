# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 14.2: Solidarity Levy Auto-Calculator
# v7.0 — BP-2: Amount field + quarterly forecasting + threshold alerts
# Package: jdg.enterprise.solidarity_auto_calc
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.solidarity_auto_calc

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# SAC-3050: Solidarity levy amount calculator (K30H-3 fix)
# Formula: max(0, total_income - social_zus - 1_000_000) * 4%
# ─────────────────────────────────────────────────────────────────────────────
sac_calculate_levy(input) = levy {
    total_income := object.get(input, "total_annual_income_pln", 0)
    social_zus := object.get(input, "social_zus_annual_pln", 0)
    foreign_income := object.get(input, "foreign_income_pln", 0)
    foreign_method := object.get(input, "foreign_method", "EXEMPTION")

    # v7.0 FIX (LUKA-K30H-3): Explicit solidarity levy amount calculation
    base := max([0, total_income - social_zus - 1000000])
    levy_rate := 0.04

    # Uwzględnienie dochodów zagranicznych
    foreign_addition := 0
    foreign_addition := foreign_income { foreign_method == "PROGRESSION" }
    foreign_addition := 0 { foreign_method == "EXEMPTION" }

    adjusted_base := base + foreign_addition
    levy_amount := max([0, adjusted_base * levy_rate])

    levy := {
        "total_income": total_income,
        "social_zus_deducted": social_zus,
        "foreign_income": foreign_income,
        "foreign_method": foreign_method,
        "base_after_deductions": base,
        "levy_rate_pct": levy_rate * 100,
        "solidarity_levy_amount_pln": levy_amount,
        "exceeds_threshold": total_income > 1000000,
        "legal_basis": "Art. 30h ust. 2 PIT",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# SAC-3060: Quarterly forecast + threshold proximity alerts
# ─────────────────────────────────────────────────────────────────────────────
sac_quarterly_forecast(input) = forecast {
    q1_income := object.get(input, "q1_income_pln", 0)
    q2_income := object.get(input, "q2_income_pln", 0)
    q3_income := object.get(input, "q3_income_pln", 0)
    q4_expected := object.get(input, "q4_expected_pln", 0)

    ytd := q1_income + q2_income + q3_income
    projected := ytd + q4_expected

    # Progi alertów
    alert_800k := projected > 800000 and projected <= 1000000
    alert_900k := projected > 900000 and projected <= 1000000
    alert_950k := projected > 950000 and projected <= 1000000
    exceeds_1m := projected > 1000000

    forecast_level := "BELOW_THRESHOLD" { projected <= 800000 }
    forecast_level := "APPROACHING_800K" { alert_800k }
    forecast_level := "APPROACHING_900K" { alert_900k }
    forecast_level := "CRITICAL_950K" { alert_950k }
    forecast_level := "EXCEEDS_1M" { exceeds_1m }

    action := "Przygotuj się na daninę: " + sprintf("%.0f PLN", [max([0, projected - 1000000]) * 0.04]) { exceeds_1m }
    action := "Optymalizuj dochód — rozważ przesunięcie przychodów/kosztów" { forecast_level == "CRITICAL_950K" }
    action := "Brak pilnych działań" { true }

    forecast := {
        "ytd_income": ytd,
        "q4_expected": q4_expected,
        "projected_annual": projected,
        "forecast_level": forecast_level,
        "threshold_1m": 1000000,
        "gap_to_threshold": max([1000000 - projected, 0]),
        "action": action,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# SAC-3070: Annual return integration (PIT-36 field)
# ─────────────────────────────────────────────────────────────────────────────
sac_pit36_integration(levy) = pit36 {
    levy_amount := object.get(levy, "solidarity_levy_amount_pln", 0)
    exceeds := object.get(levy, "exceeds_threshold", false)

    pit36 := {
        "form": "PIT-36",
        "field": "PIT-36 poz. 83 — Danina solidarnościowa",
        "amount_pln": levy_amount,
        "filing_required": exceeds,
        "deadline": "2027-04-30",
        "legal_basis": "Art. 30h ust. 1 PIT",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# SAC-3080: Build SAC warnings
# ─────────────────────────────────────────────────────────────────────────────
build_sac_warnings(levy, forecast, pit36) = warnings {
    levy_amount := object.get(levy, "solidarity_levy_amount_pln", 0)
    exceeds := object.get(levy, "exceeds_threshold", false)
    forecast_level := object.get(forecast, "forecast_level", "BELOW_THRESHOLD")

    base := ["💰 SOLIDARITY LEVY AUTO-CALCULATOR"]

    levy_warn := array.concat(base, [
        sprintf("   🏦 Danina solidarnościowa: %.2f PLN (4%% nadwyżki >1M PLN)", [levy_amount]),
        sprintf("   Podstawa: %s", [object.get(levy, "legal_basis", "")]),
    ]) { exceeds }

    levy_warn := array.concat(base, [
        sprintf("   ✅ Dochód poniżej 1M PLN — danina nie dotyczy (prognoza: %s)",
            [forecast_level]),
    ]) { not exceeds }

    forecast_warn := array.concat(levy_warn, [
        sprintf("   ⚠️ PROGNOZA: %.0f PLN rocznie — zbliżasz się do progu 1M!",
            [object.get(forecast, "projected_annual", 0)]),
    ]) { forecast_level != "BELOW_THRESHOLD" }

    forecast_warn := levy_warn { forecast_level == "BELOW_THRESHOLD" }

    warnings := forecast_warn
}
