# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — P09 GLM52 ZUS MIKRO + ZASIŁKI
# Package: jdg.micro.zus_atomic_p09
# Rules tested: maly_zus_plus (a18c), tier_switch (a81c), korekta roczna
#               (a81d), zasiłki (a19/a29/a32/a33), terminy (a36/a47)
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_zus_micro

import data.jdg.micro.zus_atomic_p09

# ── 1. MAŁY ZUS PLUS (art. 18c ust. 1 SUS) ─────────────────────────────────────
test_positive_maly_zus_plus_eligibility {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "zus_relief_type": "MALY_ZUS_PLUS",
            "prior_year_income_pln": 100000,
            "maly_zus_plus_months_used": 10,
            "prior_year_activity_days": 200
        }
    } with data.jdg.thresholds as {"zus": {"maly_zus_plus_revenue_limit": 120000, "maly_zus_plus_months": 36}}
    result.matched == true
    result.rule_id == "jdg.micro.zus.a18c.maly_zus_plus_eligibility"
    result.zus_social_base_type == "MALY_ZUS_PLUS"
}

test_negative_maly_zus_plus_income_over_limit {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "zus_relief_type": "MALY_ZUS_PLUS",
            "prior_year_income_pln": 125000,
            "maly_zus_plus_months_used": 0,
            "prior_year_activity_days": 200
        }
    }
    result.rule_id != "jdg.micro.zus.a18c.maly_zus_plus_eligibility"
}

test_positive_maly_zus_plus_base_calc {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "zus_relief_type": "MALY_ZUS_PLUS",
            "prior_year_income_pln": 100000
        }
    } with data.jdg.thresholds as {"zus": {
        "preferential_base_30pct": 1440.00,
        "social_base_standard_60pct": 5460.00
    }}
    result.rule_id == "jdg.micro.zus.a18c.maly_zus_plus_base_calc.r1"
    result.zus_social_base_amount_pln == 5460.00
}

# ── 2. PRZEŁĄCZNIK PROGU ZDROWOTNEJ RYCZAŁT (art. 81 ust. 2e-2f u.ś.o.z.) ─────
test_positive_tier_switch_tier_i {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "health_tier_switch_check": true,
            "tax_form": "LUMP_SUM",
            "lump_sum_cumulative_revenue": 59999
        }
    } with data.jdg.thresholds as {"zus": {
        "health_lump_tier_1_limit": 60000,
        "health_lump_tier_2_limit": 300000,
        "health_lump_tier_1_amount": 491.40,
        "health_lump_tier_2_amount": 819.00,
        "health_lump_tier_3_amount": 1474.20
    }}
    result.matched == true
    result.rule_id == "jdg.micro.zdrowotna.a81c.tier_switch.r1"
    result.zus_health_tier == "TIER_I"
    result.zus_health_monthly_amount_pln == 491.40
}

test_positive_tier_switch_tier_ii_at_60000 {
    # Granica inkluzywna (INV-018, spójnie z makro): 60 000 → TIER_I
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "health_tier_switch_check": true,
            "tax_form": "LUMP_SUM",
            "lump_sum_cumulative_revenue": 60000
        }
    } with data.jdg.thresholds as {"zus": {
        "health_lump_tier_1_limit": 60000,
        "health_lump_tier_2_limit": 300000,
        "health_lump_tier_1_amount": 491.40,
        "health_lump_tier_2_amount": 819.00,
        "health_lump_tier_3_amount": 1474.20
    }}
    result.rule_id == "jdg.micro.zdrowotna.a81c.tier_switch.r1"
    result.zus_health_tier == "TIER_I"
}

test_positive_tier_switch_tier_ii_above_60000 {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "health_tier_switch_check": true,
            "tax_form": "LUMP_SUM",
            "lump_sum_cumulative_revenue": 60001
        }
    } with data.jdg.thresholds as {"zus": {
        "health_lump_tier_1_limit": 60000,
        "health_lump_tier_2_limit": 300000,
        "health_lump_tier_1_amount": 491.40,
        "health_lump_tier_2_amount": 819.00,
        "health_lump_tier_3_amount": 1474.20
    }}
    result.rule_id == "jdg.micro.zdrowotna.a81c.tier_switch.r2"
    result.zus_health_tier == "TIER_II"
    result.zus_health_monthly_amount_pln == 819.00
}

test_positive_tier_switch_tier_iii {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "health_tier_switch_check": true,
            "tax_form": "LUMP_SUM",
            "lump_sum_cumulative_revenue": 300001
        }
    } with data.jdg.thresholds as {"zus": {
        "health_lump_tier_1_limit": 60000,
        "health_lump_tier_2_limit": 300000,
        "health_lump_tier_1_amount": 491.40,
        "health_lump_tier_2_amount": 819.00,
        "health_lump_tier_3_amount": 1474.20
    }}
    result.rule_id == "jdg.micro.zdrowotna.a81c.tier_switch.r3"
    result.zus_health_tier == "TIER_III"
    result.zus_health_monthly_amount_pln == 1474.20
}

# ── 3. KOREKTA ROCZNA (art. 81 ust. 2g-2h u.ś.o.z.) ────────────────────────────
test_positive_annual_reconciliation {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "health_annual_reconciliation_check": true,
            "tax_form": "LUMP_SUM",
            "annual_revenue_pln": 120000,
            "health_contributions_paid_pln": 9828.00
        }
    } with data.jdg.thresholds as {"zus": {"health_scale_rate": 0.09}}
    result.matched == true
    result.rule_id == "jdg.micro.zdrowotna.a81d.annual_reconciliation"
    result.zus_health_annual_due_pln == 10800.00
    result.zus_health_annual_diff_pln == 972.00
}

# ── 4. ZASIŁKI (ustawa zasiłkowa) ──────────────────────────────────────────────
test_positive_benefit_base_12m {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "sickness_contribution_bases_12m": [8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000]
        }
    }
    result.rule_id == "jdg.micro.zasilkowa.a19.benefit_base"
    result.sickness_benefit_base_pln == 8000.00
    result.sickness_benefit_daily_pln == 266.67
}

test_positive_waiting_period_90d_voluntary {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "zus_sickness_voluntary": true,
            "sickness_insurance_days": 90
        }
    }
    result.rule_id == "jdg.micro.zasilkowa.a29.waiting_period"
    result.sickness_waiting_met == true
}

test_negative_waiting_period_not_met {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "zus_sickness_voluntary": true,
            "sickness_insurance_days": 85
        }
    }
    result.rule_id != "jdg.micro.zasilkowa.a29.waiting_period"
}

test_positive_limit_tracker_alert {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "sickness_days_used": 170
        }
    } with data.jdg.thresholds as {"zus": {"sickness_max_days_standard": 182, "sickness_max_days_tb": 270}}
    result.rule_id == "jdg.micro.zasilkowa.a32.limit_tracker"
    result.sickness_days_limit == 182
    result.sickness_days_remaining == 12
}

test_positive_benefit_rate_80pct {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "sickness_benefit_daily_pln": 266.67,
            "sickness_hospitalization": false
        }
    } with data.jdg.thresholds as {"zus": {"sickness_benefit_rate": 0.80, "sickness_hospital_rate": 0.70}}
    result.rule_id == "jdg.micro.zasilkowa.a33.benefit_rate"
    result.sickness_benefit_rate == 0.80
    result.sickness_benefit_daily_pln == 213.34
}

# ── 5. TERMINY (art. 36/47 SUS) ────────────────────────────────────────────────
test_positive_payment_deadline_10 {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "zus_payment_check": true,
            "has_employees": false
        }
    } with data.jdg.thresholds as {"zus": {"payment_deadline_social": 10, "payment_deadline_social_employees": 15}}
    result.rule_id == "jdg.micro.sus.a47.payment_deadline.r1"
    result.zus_payment_deadline_day == 10
}

test_positive_payment_deadline_15_with_employees {
    result := zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "zus_payment_check": true,
            "has_employees": true
        }
    } with data.jdg.thresholds as {"zus": {"payment_deadline_social": 10, "payment_deadline_social_employees": 15}}
    result.rule_id == "jdg.micro.sus.a47.payment_deadline.r2"
    result.zus_payment_deadline_day == 15
}

# ── 6. NO_MATCH (default — brak dopasowania) ───────────────────────────────────
test_no_match_empty_input {
    result := zus_atomic_p09.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.micro.zus_atomic_p09.no_match"
}
