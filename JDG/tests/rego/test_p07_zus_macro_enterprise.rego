# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P07 ZUS/SUS Macro Enterprise — testy rego (RAPORT P07 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p07_zus_macro

import future.keywords.in

# ── 1. Audyt składki zdrowotnej (PRIORYTET) ───────────────────────────────────
test_health_contribution_audit {
    result := data.jdg.p07_zus_macro_innovations.health_contribution_audit with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "tax_form": "skala", "monthly_income": 10000, "annual_revenue": 100000}}
    result.matched == true
    result.form == "skala"
    result.scale_9pct == 900.0
    result.linear_4p9pct == 490.0
    result.lump_current == 819.0
    result.minimum_monthly == 432.0
}

# ── 2. Kalkulator realtime — najniższa składka (INN-01) ───────────────────────
test_health_optimizer_realtime {
    result := data.jdg.p07_zus_macro_innovations.health_optimizer_realtime with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "monthly_income": 5000, "annual_revenue": 30000}}
    result.matched == true
    result.comparison.skala_9pct == 450.0
    result.comparison.liniowy_4p9pct == 245.0
    result.comparison.ryczałt == 491.40
    result.cheapest_form == "liniowy"
}

# ── 3. Predykcja roczna + symulator zmiany formy (INN-02/03) ──────────────────
test_health_annual_prediction {
    result := data.jdg.p07_zus_macro_innovations.health_annual_prediction with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "monthly_income": 10000, "annual_revenue": 200000}}
    result.annual_scale == 10800.0
    result.annual_linear == 5880.0
    result.annual_lump == 9828.0
}

test_health_form_change_simulator {
    result := data.jdg.p07_zus_macro_innovations.health_form_change_simulator with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "tax_form": "skala", "simulated_form": "liniowy", "monthly_income": 10000, "annual_revenue": 100000}}
    result.monthly_before == 900.0
    result.monthly_after == 490.0
    result.monthly_delta == -410.0
}

# ── 4. Korekta roczna składki zdrowotnej ───────────────────────────────────────
test_health_annual_reconciliation {
    result := data.jdg.p07_zus_macro_innovations.health_annual_reconciliation with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "annual_income": 120000, "health_advances_paid": 10000}}
    result.due == 10800.0
    result.difference == 800.0
}

# ── 5. Audyt składek społecznych (standard/preferencyjny/MZP) ─────────────────
test_social_contribution_audit {
    result := data.jdg.p07_zus_macro_innovations.social_contribution_audit with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "months_since_start": 12}}
    result.matched == true
    result.standard_monthly.emerytalna == round(5204.40 * 0.1952 * 100) / 100
    result.preferential_base == 1440.0
    result.relief_phase == "preferencyjny"
    result.deadline == "10/15/20 dzień miesiąca"
}

# ── 6. Monitor limitu 30-krotności (INN-04) ───────────────────────────────────
test_thirtyx_limit_monitor {
    result := data.jdg.p07_zus_macro_innovations.thirtyx_limit_monitor with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "cumulative_zus_base": 400000}}
    result.exceeded == true
    result.excess == 81400.0
}

# ── 7. Ulga na start / Mały ZUS Plus / preferencyjny (INN-05/06/07) ───────────
test_ulga_start_tracker {
    result := data.jdg.p07_zus_macro_innovations.ulga_start_tracker with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "months_since_start": 3}}
    result.ulga_active == true
    result.months_left == 3
}

test_maly_zus_plus_audit {
    result := data.jdg.p07_zus_macro_innovations.maly_zus_plus_audit with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "income_last_year": 40000, "revenue_last_year": 90000}}
    result.eligible == true
    result.base == 1440.0
}

test_preferential_zus_audit {
    result := data.jdg.p07_zus_macro_innovations.preferential_zus_audit with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "preferential_months_used": 10}}
    result.within_limit == true
    result.months_left == 14
}

# ── 8. Audyt zasiłków (Sekcja 3) ──────────────────────────────────────────────
test_benefits_audit {
    result := data.jdg.p07_zus_macro_innovations.benefits_audit with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "benefit_base": 5204.40, "insured_months": 6}}
    result.waiting_period_ok == true
    # sickness_benefit_calculator: round2(daily) potem round2(daily*rate) — zgodnie z praktyką ZUS
    result.sickness_80pct_daily == round(round(5204.40 / 30 * 100) / 100 * 0.80 * 100) / 100
    result.maternity_20wks_days == 140
}

test_sickness_waiting_tracker {
    result := data.jdg.p07_zus_macro_innovations.sickness_waiting_tracker with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "insured_months": 1}}
    result.eligible == false
    result.months_to_go == 2
}

# ── 9. PPK/PFRON/FS (Sekcja 4) ────────────────────────────────────────────────
test_ppk_pfron_solidarity_audit {
    result := data.jdg.p07_zus_macro_innovations.ppk_pfron_solidarity_audit with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "employees_count": 30}}
    result.matched == true
    result.pfron_obliged == true
    result.pfron.threshold_employees == 25
}

# ── 10. Zbiegi tytułów (Sekcja 5) ─────────────────────────────────────────────
test_concurrent_title_engine {
    result := data.jdg.p07_zus_macro_innovations.concurrent_title_engine with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "concurrent_title": "etat_jdg"}}
    result.obligation.social == false
    result.obligation.health == true
}

test_etat_jdg_health_only {
    result := data.jdg.p07_zus_macro_innovations.etat_jdg_health_only with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "has_employment": true}}
    result.social_skipped == true
    result.health_paid == true
}

# ── 11. Thresholdy temporalne (Sekcja 6) ──────────────────────────────────────
test_zus_thresholds_snapshot {
    result := data.jdg.p07_zus_macro_innovations.zus_thresholds_snapshot with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "tax_year": 2026}}
    result.year == 2026
    result.snapshot.minimum_wage_gross == 4800
    result.snapshot.social_base_standard == 5204.40
    result.snapshot.health_lump_tier_2 == 819.00
}

# ── 12. Główny decide (P07) + no_match ────────────────────────────────────────
test_p07_main_decide {
    result := data.jdg.p07_zus_macro_innovations.decide with
        input as {"jdg_entrepreneur": {"p07_zus_macro_check": true, "tax_form": "ryczałt", "monthly_income": 15000, "annual_revenue": 250000}}
    result.matched == true
    result.rule_id == "jdg.p07_zus_macro_innovations.report"
    result._routing == "REPORT"
    result.health_contribution.form == "ryczałt"
}

test_p07_default_no_match {
    result := data.jdg.p07_zus_macro_innovations.decide with input as {"jdg_entrepreneur": {"monthly_income": 10000}}
    result.matched == false
    result.rule_id == "jdg.p07_zus_macro_innovations.no_match"
}
