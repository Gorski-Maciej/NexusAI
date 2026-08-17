# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — P08 GLM52 ZUS MAKRO + ZDROWOTNA
# Package: jdg.zus.health_contribution / jdg.zus / jdg.zus.precision_engine
# Rules tested: tier_switch (art. 81 ust. 2e-2f u.ś.o.z.), lump_sum_tiers,
#               maly_zus_plus_formula (art. 18c ust. 4-5 SUS),
#               tier_transition (INN-02), scale/linear health
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_zus_macro

import data.jdg.zus.health_contribution
import data.jdg.zus
import data.jdg.zus.precision_engine

# ── 1. TIER SWITCH (P08 — art. 81 ust. 2e-2f u.ś.o.z.) ─────────────────────────
test_positive_tier_switch_tier2 {
    result := health_contribution.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "LUMP_SUM",
            "health_tier_switch_check": true,
            "lump_sum_cumulative_revenue": 150000,
            "lump_sum_previous_tier": "TIER_I"
        }
    } with data.jdg.thresholds as {
        "zus": {
            "health_lump_tier_1_limit": 60000,
            "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40,
            "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20
        }
    }
    result.matched == true
    result.rule_id == "jdg.zus.health.tier_switch"
    result.zus_health_tier_switch_detected == true
    result.zus_health_tier_previous == "TIER_I"
    result.zus_health_tier_current == "TIER_II"
    result.zus_health_monthly_previous_pln == 491.40
    result.zus_health_monthly_current_pln == 819.00
}

test_tier_switch_no_change_tier1 {
    result := health_contribution.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "LUMP_SUM",
            "health_tier_switch_check": true,
            "lump_sum_cumulative_revenue": 40000,
            "lump_sum_previous_tier": "TIER_I"
        }
    } with data.jdg.thresholds as {
        "zus": {
            "health_lump_tier_1_limit": 60000,
            "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40,
            "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20
        }
    }
    result.rule_id == "jdg.zus.health.tier_switch"
    result.zus_health_tier_switch_detected == false
    result.zus_health_tier_current == "TIER_I"
}

test_tier_switch_tier3 {
    result := health_contribution.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "LUMP_SUM",
            "health_tier_switch_check": true,
            "lump_sum_cumulative_revenue": 350000,
            "lump_sum_previous_tier": "TIER_II"
        }
    } with data.jdg.thresholds as {
        "zus": {
            "health_lump_tier_1_limit": 60000,
            "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40,
            "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20
        }
    }
    result.rule_id == "jdg.zus.health.tier_switch"
    result.zus_health_tier_current == "TIER_III"
    result.zus_health_monthly_current_pln == 1474.20
    result._routing == "TRIAGE_QUEUE"
}

test_tier_switch_not_triggered_without_check {
    result := health_contribution.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "LUMP_SUM",
            "lump_sum_cumulative_revenue": 150000,
            "lump_sum_previous_tier": "TIER_I"
        }
    }
    result.rule_id != "jdg.zus.health.tier_switch"
}

# ── 2. LUMP SUM TIERS (art. 81 ust. 2e u.ś.o.z.) ───────────────────────────────
test_lump_sum_tier2_amount {
    result := health_contribution.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "LUMP_SUM",
            "health_contribution_active": true,
            "annual_revenue_pln": 150000
        }
    } with data.jdg.thresholds as {
        "zus": {
            "health_lump_tier_1_limit": 60000,
            "health_lump_tier_2_limit": 300000,
            "health_lump_tier_1_amount": 491.40,
            "health_lump_tier_2_amount": 819.00,
            "health_lump_tier_3_amount": 1474.20
        }
    }
    result.rule_id == "jdg.zus.health.lump_sum_tiers"
    result.zus_health_tier == "II (60k-300k)"
    result.zus_health_monthly_pln == 819.00
}

# ── 3. MAŁY ZUS PLUS (art. 18c ust. 4-5 SUS) — jdg.zus.precision_engine ───────
test_positive_maly_plus_formula {
    result := precision_engine.maly_zus_plus_formula with input as {
        "jdg_entrepreneur": {
            "zus_status": "MALY_ZUS_PLUS",
            "maly_plus_prev_year_income": 120000,
            "maly_plus_prev_year_months": 12
        }
    } with data.jdg.zus.precision_engine.health_precision_data as {
        "version": "test", "valid_from": "2026-01-01",
        "minimum_wage_gross": 4800,
        "average_wage_gross": 8190,
        "health_rates": {},
        "lump_sum_tiers": {"TIER_I": {"max_revenue": 60000, "monthly_pln": 491.40},
                           "TIER_II": {"max_revenue": 300000, "monthly_pln": 819.00},
                           "TIER_III": {"max_revenue": 999999999, "monthly_pln": 1474.20}}
    }
    result.rule_id == "jdg.zus.precision.maly_plus_formula"
    result.maly_plus_prev_year_monthly_income == 10000
    result.maly_plus_raw_base_30pct == 3000
    result.maly_plus_min_bound == 1440
    result.maly_plus_max_bound == 4914
    result.maly_plus_final_base == 3000
}

# ── 4. TIER TRANSITION (INN-02 — cumulative revenue) ──────────────────────────
test_positive_tier_transition {
    result := precision_engine.tier_transition with input as {
        "jdg_entrepreneur": {
            "tax_form": "LUMP_SUM",
            "lump_sum_monthly_revenues": [10000, 20000, 20000, 20000],
            "current_month": 4,
            "lump_sum_previous_tier": "TIER_I"
        }
    } with data.jdg.zus.precision_engine.health_precision_data as {
        "version": "test", "valid_from": "2026-01-01",
        "minimum_wage_gross": 4800,
        "average_wage_gross": 8190,
        "health_rates": {},
        "lump_sum_tiers": {"TIER_I": {"max_revenue": 60000, "monthly_pln": 491.40},
                           "TIER_II": {"max_revenue": 300000, "monthly_pln": 819.00},
                           "TIER_III": {"max_revenue": 999999999, "monthly_pln": 1474.20}}
    }
    result.rule_id == "jdg.zus.precision.tier_transition"
    result.lump_sum_cumulative_revenue == 70000
    result.lump_sum_current_tier == "TIER_II"
    result.lump_sum_tier_changed_this_month == true
    result.lump_sum_monthly_health_pln == 819.00
}

# ── 5. HEALTH SCALE 9% (art. 81 ust. 1 u.ś.o.z.) — przez jdg.zus ──────────────
test_health_scale_via_zus {
    result := zus.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "health_contribution_active": true,
            "monthly_income": 10000
        }
    }
    result.matched == true
}

# ── 6. NIEMUTOWALNOŚĆ — werdykt ZUS w allowliście (kontrakt P01) ──────────────
test_zus_package_has_immutable_rules {
    # werdykty ZUS z immutable_verdict=true nie mogą być nadpisane (main_jdg)
    result := zus.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "LUMP_SUM",
            "lump_sum_annual_revenue": 100000
        }
    }
    result.matched == true
    result.rule_id == "jdg.zus.health_lump_sum"
    result.immutable_verdict == true
}
