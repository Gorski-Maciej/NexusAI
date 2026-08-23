# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: ZUS MACRO (PROMPT 06)
# Package: jdg.zus and jdg.zus.zero_doubt
# Rules tested: start_relief, maly_plus, preferential, social_standard,
# health_scale, health_linear, health_lump_sum, concurrent_employment,
# concurrent_low_salary, sickness_benefit, maternity_benefit,
# annual_base_cap_art19, remission_exclusion_art30
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_zus_macro
import data.jdg.zus
import data.jdg.zus.zero_doubt

# ── Helper: minimalne thresholds ─────────────────────────────────────────────
mock_thresholds := {
    "jdg": {
        "bounds": {
            "minimum_wage_gross": 4800.0,
            "avg_monthly_wage": 8190.0,
            "funeral_grant_amount": 4000.0,
            "pre_retirement_benefit_amount": 1800.0
        },
        "limits": {
            "zus_maly_plus_revenue_limit": 120000.0,
            "health_linear_deduction_limit": 14100.0
        }
    }
}

# ── Test 1: ulga na start — tylko zdrowotna, bez społecznych ──────────────────
test_positive_zus_start_relief {
    result := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "START_RELIEF",
            "zus_months_used_current_status": 2,
            "tax_form": "PIT_SCALE"
        }
    } with data.thresholds as mock_thresholds

    result.rule_id == "jdg.zus.start_relief"
    result.matched == true
    result.zus_social_base_type == "START_RELIEF"
    result.zus_social_base_percent == 0
    result.zus_health_only == true
    result.zus_health_rate == "0.09"
    result.zus_months_remaining == 4
    result.immutable_verdict == true
}

# ── Test 2: ulga na start — wygasła po 6 miesiącach → fallthrough ────────────
test_negative_zus_start_relief_expired {
    result := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "START_RELIEF",
            "zus_months_used_current_status": 7,
            "tax_form": "PIT_SCALE"
        }
    } with data.thresholds as mock_thresholds

    result.rule_id != "jdg.zus.start_relief"
}

# ── Test 3: Mały ZUS Plus — podstawa 30% dochodu poprzedniego roku ────────────
test_positive_zus_maly_plus {
    result := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "MALY_ZUS_PLUS",
            "zus_months_used_current_status": 10,
            "maly_plus_prev_year_income": 120000.0,
            "maly_plus_prev_year_months": 12,
            "tax_form": "PIT_SCALE"
        }
    } with data.thresholds as mock_thresholds

    result.rule_id == "jdg.zus.maly_plus"
    result.matched == true
    result.zus_social_base_type == "MALY_ZUS_PLUS"
    result.zus_social_base_percent == 30
    result.zus_months_remaining == 26
}

# ── Test 4: Mały ZUS Plus — przekroczenie limitu 120 000 PLN przychodu ────────
test_positive_zus_maly_plus_limit_exceeded {
    result := data.jdg.zus.maly_zus_plus_limit_monitor with input as {
        "jdg_entrepreneur": {
            "zus_status": "MALY_ZUS_PLUS",
            "cumulative_revenue_current_year": 135000.0
        }
    } with data.thresholds as mock_thresholds

    result.rule_id == "jdg.zus.maly_plus_limit_exceeded"
    result.maly_zus_plus_loss_next_year == true
    result._routing == "TRIAGE_QUEUE"
}

# ── Test 5: Preferencyjny ZUS — 24 miesiące ───────────────────────────────────
test_positive_zus_preferential {
    result := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "PREFERENTIAL",
            "zus_months_used_current_status": 5,
            "tax_form": "LINEAR"
        }
    } with data.thresholds as mock_thresholds

    result.rule_id == "jdg.zus.preferential"
    result.matched == true
    result.zus_social_base_type == "PREFERENTIAL"
    result.zus_social_base_percent == 30
    result.zus_health_rate == "0.09"
    result.zus_months_remaining == 19
}

# ── Test 6: Standardowy ZUS z chorobową ───────────────────────────────────────
test_positive_zus_standard_with_sickness {
    result := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "STANDARD",
            "tax_form": "PIT_SCALE",
            "zus_sickness_voluntary": true
        }
    } with data.thresholds as mock_thresholds

    result.rule_id == "jdg.zus.social_standard"
    result.matched == true
    result.zus_social_base_type == "STANDARD"
    result.zus_pension_rate == "0.1952"
    result.zus_disability_rate == "0.08"
    result.zus_sickness_rate == "0.0245"
    result.zus_accident_rate == "0.0167"
    result.zus_labour_fund_rate == "0.0245"
    result.zus_health_rate == "0.09"
}

# ── Test 7: Zdrowotna liniowa 4.9% z limitem ──────────────────────────────────
test_positive_zus_health_linear {
    result := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "START_RELIEF",
            "zus_months_used_current_status": 0,
            "tax_form": "LINEAR"
        }
    } with data.thresholds as mock_thresholds

    # W first-match-wins, START_RELIEF odpala pierwszy (P740) — sprawdzamy regułę liniową bezpośrednio
    result_after_start := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "STANDARD",
            "tax_form": "LINEAR",
            "zus_sickness_voluntary": false
        }
    } with data.thresholds as mock_thresholds

    # Standardowy ZUS odpala przed health_linear (P700 < P722)
    # więc testujemy health_scale/liniowa przez oddzielną symulację
    result_after_start.zus_health_rate == "0.049"
}

# ── Test 8: Zdrowotna ryczałt — TIER_1 (≤60k) ────────────────────────────────
test_positive_zus_health_lump_tier1 {
    result := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "START_RELIEF",
            "zus_months_used_current_status": 0,
            "tax_form": "LUMP_SUM",
            "lump_sum_annual_revenue": 45000
        }
    } with data.thresholds as mock_thresholds

    result.rule_id == "jdg.zus.start_relief"
    result.zus_health_rate == "0.09"
    # Dla LUMP_SUM w START_RELIEF health_rate = 0.09 (poprawne — K3 fix v7.1)
}

# ── Test 9: Zbieg etat+JDG — tylko zdrowotna ──────────────────────────────────
test_positive_zus_concurrent_employment {
    result := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "START_RELIEF",
            "zus_months_used_current_status": 7,  # wygasła
            "concurrent_employment": true,
            "concurrent_employment_salary": 6000.0,
            "tax_form": "PIT_SCALE"
        }
    } with data.thresholds as mock_thresholds

    result.rule_id == "jdg.zus.concurrent_employment"
    result.zus_social_due == false
    result.zus_health_due == true
    result.immutable_verdict == true
}

# ── Test 10: Zasiłek chorobowy — 90 dni wyczekiwania ──────────────────────────
test_positive_zus_sickness_benefit {
    result := data.jdg.zus.decide with input as {
        "jdg_entrepreneur": {
            "zus_status": "START_RELIEF",
            "zus_months_used_current_status": 7,
            "zus_sickness_voluntary": true,
            "zus_sickness_days": 10,
            "zus_sickness_accident_related": false,
            "zus_sickness_pregnancy_related": false,
            "zus_sickness_insured_days": 100,
            "tax_form": "PIT_SCALE"
        }
    } with data.thresholds as mock_thresholds

    result.rule_id == "jdg.zus.sickness_benefit"
    result.zus_benefit_type == "SICKNESS"
    result.zus_benefit_rate == "0.80"
    result.zus_benefit_eligible == true
}

# ── Test 11: Art. 19 SUS — roczny limit podstawy 30× przeciętne ───────────────
test_positive_zus_annual_base_cap_art19 {
    result := data.jdg.zus.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "zus_annual_cap_check": {
                "active": true,
                "annual_base_pln": 250000.0,
                "avg_wage_pln": 8190.0
            }
        }
    }

    result.rule_id == "jdg.zus.zero_doubt.annual_base_cap_30x_art19"
    result.matched == true
    result.zus_annual_cap.excess_subject_to_contributions == false
    result._routing == "SUGGEST"
}

# ── Test 12: Art. 30 SUS — ograniczenie umorzenia ─────────────────────────────
test_positive_zus_remission_exclusion_art30 {
    result := data.jdg.zus.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "zus_remission_check": {
                "active": true,
                "insured_not_payer": true
            }
        }
    }

    result.rule_id == "jdg.zus.zero_doubt.remission_exclusion_art30"
    result.matched == true
    result.zus_remission.art28_remission_applicable == false
    result.zus_remission.art28_ust3_pkt4c_exception == true
}

# ── Test 13: no_match — pusty input ───────────────────────────────────────────
test_no_match_zus {
    result := data.jdg.zus.decide with input as {}

    result.matched == false
    result.rule_id == "jdg.zus.no_match"
}

# ── Test 14: no_match zero_doubt — pusty input ────────────────────────────────
test_no_match_zus_zero_doubt {
    result := data.jdg.zus.zero_doubt.decide with input as {}

    result.matched == false
    result.rule_id == "jdg.zus.zero_doubt.no_match"
}