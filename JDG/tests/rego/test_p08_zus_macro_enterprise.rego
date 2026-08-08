# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Tests: P08 ZUS MACRO ENTERPRISE v9.0
# Sekcje 2-8: zdrowotna wg formy + społeczne + ulgi + zbiegi + zasiłki + innowacje
# Format: complete rules (test_foo { ... }) — poprawna składnia OPA v0.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p08_zus_macro_enterprise_test

import future.keywords.in

# ── SEKCJA 2: SKŁADKA ZDROWOTNA — SKALA 9% ───────────────────────────────────

test_health_scale_9pct {
    result := data.jdg.p08_zus_macro_enterprise.health_contribution_calculator with input as {
        "jdg_entrepreneur": {"p08_health_check": true},
        "zus_input": {"tax_form": "SCALE", "monthly_income": 10000,
            "annual_revenue": 0}
    } with data.jdg.thresholds as {
        "zus": {"health_scale_rate": 0.09, "health_linear_rate": 0.049,
            "health_linear_deduction_limit": 14100,
            "health_lump_tier_1_limit": 60000, "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40, "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20}
    }
    result.matched == true
    result.health.rate == 0.09
    result.health.base == 10000
    result.health.monthly_contribution == 900
    result.health.deductible_from_tax == false
    result._routing == "REPORT"
}

test_health_linear_4_9pct {
    result := data.jdg.p08_zus_macro_enterprise.health_contribution_calculator with input as {
        "jdg_entrepreneur": {"p08_health_check": true},
        "zus_input": {"tax_form": "LINEAR", "monthly_income": 10000,
            "annual_revenue": 0}
    } with data.jdg.thresholds as {
        "zus": {"health_scale_rate": 0.09, "health_linear_rate": 0.049,
            "health_linear_deduction_limit": 14100,
            "health_lump_tier_1_limit": 60000, "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40, "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20}
    }
    result.health.rate == 0.049
    result.health.monthly_contribution == 490
    result.health.deductible_from_tax == true
}

# ── SEKCJA 2: SKŁADKA ZDROWOTNA — RYCZAŁT PROGI ──────────────────────────────

test_health_lump_tier_1 {
    result := data.jdg.p08_zus_macro_enterprise.health_contribution_calculator with input as {
        "jdg_entrepreneur": {"p08_health_check": true},
        "zus_input": {"tax_form": "LUMP_SUM", "monthly_income": 0,
            "annual_revenue": 50000}
    } with data.jdg.thresholds as {
        "zus": {"health_scale_rate": 0.09, "health_linear_rate": 0.049,
            "health_linear_deduction_limit": 14100,
            "health_lump_tier_1_limit": 60000, "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40, "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20}
    }
    result.health.base == 491.40
    result.health.monthly_contribution == 24.08
}

test_health_lump_tier_2 {
    result := data.jdg.p08_zus_macro_enterprise.health_contribution_calculator with input as {
        "jdg_entrepreneur": {"p08_health_check": true},
        "zus_input": {"tax_form": "LUMP_SUM", "monthly_income": 0,
            "annual_revenue": 100000}
    } with data.jdg.thresholds as {
        "zus": {"health_scale_rate": 0.09, "health_linear_rate": 0.049,
            "health_linear_deduction_limit": 14100,
            "health_lump_tier_1_limit": 60000, "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40, "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20}
    }
    result.health.base == 819.00
}

test_health_lump_tier_3 {
    result := data.jdg.p08_zus_macro_enterprise.health_contribution_calculator with input as {
        "jdg_entrepreneur": {"p08_health_check": true},
        "zus_input": {"tax_form": "LUMP_SUM", "monthly_income": 0,
            "annual_revenue": 350000}
    } with data.jdg.thresholds as {
        "zus": {"health_scale_rate": 0.09, "health_linear_rate": 0.049,
            "health_linear_deduction_limit": 14100,
            "health_lump_tier_1_limit": 60000, "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40, "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20}
    }
    result.health.base == 1474.20
}

test_lump_tier_verifier_tier2 {
    result := data.jdg.p08_zus_macro_enterprise.lump_sum_tier_verifier with input as {
        "jdg_entrepreneur": {"p08_lump_tier_check": true},
        "zus_input": {"tax_form": "LUMP_SUM", "annual_revenue": 150000}
    } with data.jdg.thresholds as {
        "zus": {"health_scale_rate": 0.09, "health_linear_rate": 0.049,
            "health_linear_deduction_limit": 14100,
            "health_lump_tier_1_limit": 60000, "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40, "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20}
    }
    result.matched == true
    result.verifier.tier == "TIER_2"
    result.verifier.tier_multiplier_note == "100% przeciętnego wynagrodzenia"
    result.verifier.base_amount == 819.00
}

# ── SEKCJA 3: SKŁADKI SPOŁECZNE ──────────────────────────────────────────────

test_social_contributions {
    result := data.jdg.p08_zus_macro_enterprise.social_contribution_calculator with input as {
        "jdg_entrepreneur": {"p08_social_check": true},
        "zus_input": {"declared_base": 5460.00, "voluntary_sickness": true}
    } with data.jdg.thresholds as {
        "zus": {"pension_rate": 0.1952, "disability_rate": 0.08,
            "sickness_voluntary_rate": 0.0245, "accident_rate": 0.0167,
            "social_base_standard": 5460.00}
    }
    result.matched == true
    result.social.base == 5460.00
    result.social.pension == 1065.79
    result.social.disability == 436.80
    result.social.sickness == 133.77
    result.social.accident == 91.18
}

test_social_contributions_default_base {
    result := data.jdg.p08_zus_macro_enterprise.social_contribution_calculator with input as {
        "jdg_entrepreneur": {"p08_social_check": true},
        "zus_input": {"declared_base": 0, "voluntary_sickness": false}
    } with data.jdg.thresholds as {
        "zus": {"pension_rate": 0.1952, "disability_rate": 0.08,
            "sickness_voluntary_rate": 0.0245, "accident_rate": 0.0167,
            "social_base_standard": 5460.00}
    }
    result.social.base == 5460.00
    result.social.total_monthly > 1700
}

test_30x_annual_limit {
    result := data.jdg.p08_zus_macro_enterprise.annual_base_limit with input as {
        "jdg_entrepreneur": {"p08_30x_check": true},
        "zus_input": {"projected_annual_base": 200000}
    } with data.jdg.thresholds as {
        "zus": {"social_base_standard": 5460.00}
    }
    result.matched == true
    result.limit.thirty_fold_base == 163800
    result.limit.exceeded == true
}

# ── SEKCJA 3: KALENDARZ TERMINÓW ─────────────────────────────────────────────

test_payment_calendar_physical {
    result := data.jdg.p08_zus_macro_enterprise.payment_calendar with input as {
        "jdg_entrepreneur": {"p08_calendar_check": true},
        "zus_input": {"payer_type": "PHYSICAL"}
    }
    result.matched == true
    result.calendar.deadline == 15
    result.calendar.deadline_note == "15. dzień miesiąca (osoby fizyczne)"
}

test_payment_calendar_employer {
    result := data.jdg.p08_zus_macro_enterprise.payment_calendar with input as {
        "jdg_entrepreneur": {"p08_calendar_check": true},
        "zus_input": {"payer_type": "EMPLOYER_5PLUS"}
    }
    result.calendar.deadline == 20
}

# ── SEKCJA 4: ULGI ───────────────────────────────────────────────────────────

test_start_relief_active {
    result := data.jdg.p08_zus_macro_enterprise.relief_simulator with input as {
        "jdg_entrepreneur": {"p08_relief_check": true},
        "zus_input": {"first_activity": true, "start_relief_months_used": 3,
            "preferential_months_used": 0, "no_social_in_last_5_years": false,
            "maly_zus_plus_months_used": 0, "prev_year_income": 0,
            "prev_year_revenue": 0, "unregistered_activity": false,
            "monthly_revenue_unregistered": 0}
    } with data.jdg.thresholds as {
        "zus": {"start_relief_months": 6, "preferential_months": 24,
            "maly_zus_plus_months": 36, "maly_zus_plus_income_limit": 60000,
            "maly_zus_plus_revenue_limit": 120000}
    }
    result.matched == true
    result.reliefs.start_relief == true
}

test_maly_zus_plus_eligible {
    result := data.jdg.p08_zus_macro_enterprise.relief_simulator with input as {
        "jdg_entrepreneur": {"p08_relief_check": true},
        "zus_input": {"first_activity": false, "start_relief_months_used": 0,
            "preferential_months_used": 10, "no_social_in_last_5_years": true,
            "maly_zus_plus_months_used": 0, "prev_year_income": 30000,
            "prev_year_revenue": 80000, "unregistered_activity": false,
            "monthly_revenue_unregistered": 0}
    } with data.jdg.thresholds as {
        "zus": {"start_relief_months": 6, "preferential_months": 24,
            "maly_zus_plus_months": 36, "maly_zus_plus_income_limit": 60000,
            "maly_zus_plus_revenue_limit": 120000}
    }
    result.reliefs.preferential == true
    result.reliefs.maly_zus_plus == true
}

test_maly_zus_plus_revenue_exceeded {
    result := data.jdg.p08_zus_macro_enterprise.relief_simulator with input as {
        "jdg_entrepreneur": {"p08_relief_check": true},
        "zus_input": {"first_activity": false, "start_relief_months_used": 0,
            "preferential_months_used": 30, "no_social_in_last_5_years": true,
            "maly_zus_plus_months_used": 0, "prev_year_income": 50000,
            "prev_year_revenue": 200000, "unregistered_activity": false,
            "monthly_revenue_unregistered": 0}
    } with data.jdg.thresholds as {
        "zus": {"start_relief_months": 6, "preferential_months": 24,
            "maly_zus_plus_months": 36, "maly_zus_plus_income_limit": 60000,
            "maly_zus_plus_revenue_limit": 120000}
    }
    result.reliefs.preferential == false
    result.reliefs.maly_zus_plus == false
}

# ── SEKCJA 5: ZBIEGI TYTUŁÓW ─────────────────────────────────────────────────

test_collision_employment_plus_jdg {
    result := data.jdg.p08_zus_macro_enterprise.title_collision_detector with input as {
        "jdg_entrepreneur": {"p08_collision_check": true},
        "zus_input": {"employment": true, "pensioner": false, "mandate_contract": false}
    }
    result.matched == true
    result.collision.employment_plus_jdg == true
    result.collision.social_from_jdg_required == false
    result.collision.health_from_jdg_always == true
}

test_collision_none {
    result := data.jdg.p08_zus_macro_enterprise.title_collision_detector with input as {
        "jdg_entrepreneur": {"p08_collision_check": true},
        "zus_input": {"employment": false, "pensioner": false, "mandate_contract": false}
    }
    result.collision.social_from_jdg_required == true
}

# ── SEKCJA 6: ZASIŁKI ────────────────────────────────────────────────────────

test_benefits_sickness_80 {
    result := data.jdg.p08_zus_macro_enterprise.benefits_calculator with input as {
        "jdg_entrepreneur": {"p08_benefits_check": true},
        "zus_input": {"sickness_days": 30, "sickness_reason": "ILLNESS",
            "caregiver_days": 5}
    }
    result.matched == true
    result.benefits.sickness_rate == 0.80
    result.benefits.sickness_period_note == "OK (do 182 dni)"
}

test_benefits_sickness_100_hospital {
    result := data.jdg.p08_zus_macro_enterprise.benefits_calculator with input as {
        "jdg_entrepreneur": {"p08_benefits_check": true},
        "zus_input": {"sickness_days": 10, "sickness_reason": "HOSPITAL",
            "caregiver_days": 0}
    }
    result.benefits.sickness_rate == 1.00
}

test_benefits_sickness_period_exceeded {
    result := data.jdg.p08_zus_macro_enterprise.benefits_calculator with input as {
        "jdg_entrepreneur": {"p08_benefits_check": true},
        "zus_input": {"sickness_days": 200, "sickness_reason": "ILLNESS",
            "caregiver_days": 0}
    }
    result.benefits.sickness_period_note == "PRZEKROCZONY 182 dni — wymagany rehab (90-180 dni)"
}

# ── SEKCJA 7: DIGITAL TWIN + REKOMENDACJA ────────────────────────────────────

test_digital_twin {
    result := data.jdg.p08_zus_macro_enterprise.zus_digital_twin with input as {
        "jdg_entrepreneur": {"p08_twin_check": true},
        "zus_input": {"tax_form": "SCALE", "monthly_income": 10000,
            "annual_revenue": 0, "declared_base": 5460.00}
    } with data.jdg.thresholds as {
        "zus": {"health_scale_rate": 0.09, "health_linear_rate": 0.049,
            "health_linear_deduction_limit": 14100,
            "health_lump_tier_1_limit": 60000, "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40, "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20,
            "pension_rate": 0.1952, "disability_rate": 0.08,
            "sickness_voluntary_rate": 0.0245, "accident_rate": 0.0167,
            "social_base_standard": 5460.00}
    }
    result.matched == true
    result.twin.health == 900
    result.twin.total_monthly > 2600
}

test_zus_reconciliation_consistent {
    result := data.jdg.p08_zus_macro_enterprise.zus_reconciliation with input as {
        "jdg_entrepreneur": {"p08_recon_check": true},
        "zus_input": {"zus_paid": 3000, "pit_deducted": 3000}
    }
    result.matched == true
    result.recon.consistent == true
}

# ── SEKCJA 1+8: MAPA POKRYCIA + GŁÓWNY RAPORT ────────────────────────────────

test_coverage_with_audit_data {
    result := data.jdg.p08_zus_macro_enterprise.coverage_status with data.jdg.zus_micro_audit as {
        "coverage": {"6": "COMPLETE", "18a": "COMPLETE", "82": "MISSING"},
        "duplicate_count": 301, "total_stubs": 0
    }
    result.total_articles == 3
    result.complete_count == 2
    result.missing_count == 1
    result.duplicate_count == 301
}

test_p08_main_report {
    result := data.jdg.p08_zus_macro_enterprise.decide with input as {
        "jdg_entrepreneur": {"p08_zus_macro_check": true}
    } with data.jdg.thresholds as {
        "zus": {"health_scale_rate": 0.09, "health_linear_rate": 0.049,
            "health_linear_deduction_limit": 14100,
            "health_lump_tier_1_limit": 60000, "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40, "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20,
            "pension_rate": 0.1952, "disability_rate": 0.08,
            "sickness_voluntary_rate": 0.0245, "accident_rate": 0.0167,
            "social_base_standard": 5460.00, "start_relief_months": 6,
            "preferential_months": 24, "maly_zus_plus_months": 36,
            "maly_zus_plus_income_limit": 60000, "maly_zus_plus_revenue_limit": 120000}
    }
    result.matched == true
    result.rule_id == "jdg.p08_zus_macro_enterprise.report"
    result._routing == "REPORT"
    count(result.p08_zus_macro.section7_genius) == 14
    result.p08_zus_macro.section2_health.linear_rate == 0.049
    result.p08_zus_macro.dependencies.P13_RYCZALT == "zdrowotna 4.9% ryczałt — progi"
}

test_p08_no_match_default {
    result := data.jdg.p08_zus_macro_enterprise.decide with input as {
        "jdg_entrepreneur": {"p08_zus_macro_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.p08_zus_macro_enterprise.no_match"
}
