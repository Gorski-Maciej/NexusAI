# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: ZUS MICRO (PROMPT 07)
# Packages: jdg.micro.zus, jdg.micro.sus, jdg.micro.zdrowotna,
# jdg.micro.zus_atomic_p09
# Rules tested: a18c eligibility, tier_switch, annual_reconciliation,
# benefit_base, waiting_period, limit_tracker, benefit_rate,
# base_standard_preferential, reporting_deadline, payment_deadline,
# annual_cap, scale_calculation, remission, nadplata, zaleglosc
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_zus_micro
import data.jdg.micro.zus_atomic_p09
import data.jdg.micro.sus
import data.jdg.micro.zdrowotna
import data.jdg.micro.zus

mock_thresholds := {
    "zus": {
        "maly_zus_plus_revenue_limit": 120000.0,
        "maly_zus_plus_months": 36,
        "maly_zus_plus_months_window": 60,
        "maly_zus_plus_base_pct": 30,
        "maly_zus_plus_base_cap_pct": 60,
        "preferential_base_30pct": 1440.00,
        "social_base_standard_60pct": 5204.40,
        "health_min_base_standard": 4800.00,
        "health_min_base_first_year": 3600.00,
        "health_lump_tier_1_limit": 60000,
        "health_lump_tier_2_limit": 300000,
        "health_lump_tier_1_amount": 491.40,
        "health_lump_tier_2_amount": 819.00,
        "health_lump_tier_3_amount": 1474.20,
        "health_lump_tier_1_multiplier": 0.60,
        "health_lump_tier_2_multiplier": 1.00,
        "health_lump_tier_3_multiplier": 1.80,
        "health_scale_rate": 0.09,
        "health_linear_rate": 0.049,
        "sickness_waiting_days_voluntary": 90,
        "sickness_max_days_standard": 182,
        "sickness_benefit_rate": 0.80,
        "sickness_hospital_rate": 0.70,
        "sickness_benefit_base_months": 12,
        "sickness_benefit_daily_divisor": 30,
        "payment_deadline_social": 10,
        "payment_deadline_social_employees": 15,
        "payment_deadline_health": 10,
        "reporting_deadline_days": 7,
        "avg_monthly_wage": 8190.00,
        "annual_cap_multiplier": 30,
        "zus_interest_rate": 0.145,
    }
}

# ── Test 1: Mały ZUS Plus — eligibility ───────────────────────────────────────
test_positive_maly_zus_plus_eligibility {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "zus_relief_type": "MALY_ZUS_PLUS",
            "prior_year_income_pln": 90000.0,
            "maly_zus_plus_months_used": 10,
            "prior_year_activity_days": 365
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zus.a18c.maly_zus_plus_eligibility"
    result.matched == true
    result.zus_social_base_type == "MALY_ZUS_PLUS"
    result.micro_rule_active == true
}

# ── Test 2: Tier switch TIER_I (≤60k) ─────────────────────────────────────────
test_positive_tier_switch_tier1 {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "health_tier_switch_check": true,
            "tax_form": "LUMP_SUM",
            "lump_sum_cumulative_revenue": 45000
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zdrowotna.a81c.tier_switch.r1"
    result.pit_form == "LUMP_SUM"
    result.zus_health_tier == "TIER_I"
    result.zus_health_monthly_amount_pln == 491.40
}

# ── Test 3: Tier switch TIER_II (60k-300k) ────────────────────────────────────
test_positive_tier_switch_tier2 {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "health_tier_switch_check": true,
            "tax_form": "LUMP_SUM",
            "lump_sum_cumulative_revenue": 150000
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zdrowotna.a81c.tier_switch.r2"
    result.zus_health_tier == "TIER_II"
    result.zus_health_monthly_amount_pln == 819.00
}

# ── Test 4: Tier switch TIER_III (>300k) ──────────────────────────────────────
test_positive_tier_switch_tier3 {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "health_tier_switch_check": true,
            "tax_form": "LUMP_SUM",
            "lump_sum_cumulative_revenue": 450000
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zdrowotna.a81c.tier_switch.r3"
    result.zus_health_tier == "TIER_III"
}

# ── Test 5: Annual reconciliation — health ────────────────────────────────────
test_positive_annual_reconciliation {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "health_annual_reconciliation_check": true,
            "tax_form": "LUMP_SUM",
            "annual_revenue_pln": 130000.0,
            "health_contributions_paid_pln": 11000.0
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zdrowotna.a81d.annual_reconciliation"
    result.zus_health_annual_due_pln > 0
}

# ── Test 6: Benefit base — średnia 12 mies. ───────────────────────────────────
test_positive_benefit_base {
    months := [5000, 5000, 5000, 5200, 5200, 5200, 5200, 5200, 5200, 5500, 5500, 5500]
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "sickness_contribution_bases_12m": months,
            "tax_form": "PIT_SCALE"
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zasilkowa.a19.benefit_base"
    result.sickness_benefit_base_pln > 0
}

# ── Test 7: Waiting period met (90 dni) ───────────────────────────────────────
test_positive_waiting_period_met {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "zus_sickness_voluntary": true,
            "sickness_insurance_days": 120,
            "tax_form": "PIT_SCALE"
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zasilkowa.a29.waiting_period"
    result.sickness_waiting_met == true
    result.sickness_waiting_period_days == 90
}

# ── Test 8: Sickness limit tracker ─────────────────────────────────────────────
test_positive_sickness_limit {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "sickness_days_used": 150,
            "sickness_tuberculosis": false,
            "tax_form": "PIT_SCALE"
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zasilkowa.a32.limit_tracker"
    result.sickness_days_limit == 182
    result.sickness_days_remaining == 32
}

# ── Test 9: Benefit rate — standard 80% ───────────────────────────────────────
test_positive_benefit_rate_standard {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "sickness_benefit_daily_pln": 200.0,
            "sickness_hospitalization": false,
            "tax_form": "PIT_SCALE"
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zasilkowa.a33.benefit_rate"
    result.sickness_benefit_rate == 0.80
}

# ── Test 10: Zgłoszenie do ZUS — 7 dni ────────────────────────────────────────
test_positive_registration_deadline {
    result := data.jdg.micro.zus.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "business_status": "ACTIVE",
            "zus_registration_required": true,
            "days_since_business_start": 5
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zus.a8.zgloszenie"
    result.zus_registration_deadline_days == 7
}

# ── Test 11: Termin płatności — JDG bez pracowników (10 dzień) ────────────────
test_positive_payment_deadline_jdg {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "zus_payment_check": true,
            "has_employees": false,
            "tax_form": "PIT_SCALE"
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.sus.a47.payment_deadline.r1"
    result.zus_payment_deadline_day == 10
}

# ── Test 12: Termin płatności — z pracownikami (15 dzień) ─────────────────────
test_positive_payment_deadline_employees {
    result := data.jdg.micro.zus_atomic_p09.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "ziel_relief_type": "STANDARD",
            "zus_payment_check": true,
            "has_employees": true,
            "tax_form": "PIT_SCALE"
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.sus.a47.payment_deadline.r2"
    result.zus_payment_deadline_day == 15
}

# ── Test 13: Annual cap a19 — przekroczenie limitu ────────────────────────────
test_positive_annual_cap_exceeded {
    result := data.jdg.micro.sus.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "zus_annual_cap_check": true,
            "zus_annual_base_pln": 260000.0
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.sus.a19.annual_cap_calculation"
    result.zus_annual_cap_exceeded == true
}

# ── Test 14: Składka zdrowotna skala — a79 ────────────────────────────────────
test_positive_health_scale_a79 {
    result := data.jdg.micro.zdrowotna.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "tax_form": "PIT_SCALE",
            "monthly_income_pln": 10000.0
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zdrowotna.a79.scale_calculation"
    result.zus_health_rate == "0.09"
    result.zus_health_deductible_from_tax == false
    result.zus_health_monthly_pln == 900.00
}

# ── Test 15: Nadpłata składek — a24 ───────────────────────────────────────────
test_positive_nadplata_a24 {
    result := data.jdg.micro.zus.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "zus_total_paid_pln": 15000.0,
            "zus_total_due_pln": 12000.0
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zus.a24.nadplata"
    result.zus_overpayment_pln == 3000.00
}

# ── Test 16: Zaległość składek — a24 ──────────────────────────────────────────
test_positive_zaleglosc_a24 {
    result := data.jdg.micro.zus.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "zus_total_paid_pln": 8000.0,
            "zus_total_due_pln": 12000.0,
            "zus_days_late": 30
        }
    } with data.jdg.thresholds as mock_thresholds

    result.rule_id == "jdg.micro.zus.a24.zaleglosc"
    result.zus_underpayment_pln == 4000.00
    result._routing == "TRIAGE_QUEUE"
}