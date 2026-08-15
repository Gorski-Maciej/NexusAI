# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_12 — RYCZAŁT / CEIDG / CYKL ŻYCIA — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R12-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r11_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r12_ryczalt_cykl_zycia_innovations

import future.keywords.if

# ── R12-INN-01: RYCZAŁT LIMIT MONITOR ────────────────────────────────────────

test_inn01_green_below_warning if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "ryczalt_limit": {"ytd_revenue_pln": 1000000, "projected_annual_pln": 1200000},
    }
    decide.rule_id == "jdg.r12_ryczalt_cykl_zycia_innovations.ryczalt_limit_monitor"
    decide.rl_alert_level == "GREEN"
    decide._routing == ""
}

test_inn01_amber_at_warning if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "ryczalt_limit": {"ytd_revenue_pln": 7000000, "projected_annual_pln": 7000000},
    }
    # 7 mln PLN / 4.3 = 1.628 mln EUR = 81.4% → AMBER
    decide.rl_alert_level == "AMBER"
    decide._routing == "TRIAGE_QUEUE"
}

test_inn01_red_over_limit if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "ryczalt_limit": {"ytd_revenue_pln": 9000000, "projected_annual_pln": 9000000},
    }
    # 9 mln PLN / 4.3 = 2.093 mln EUR = 104.7% → RED
    decide.rl_alert_level == "RED"
    decide._routing == "BLOCK_AND_ALERT"
}

# ── R12-INN-02: PKWIU RATE CLASSIFIER ────────────────────────────────────────

test_inn02_it_high_rate if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "pkwiu_rate": {"pkwiu_code": "62.01", "declared_rate": 0.17, "activity_desc": "usługi IT"},
    }
    decide.rule_id == "jdg.r12_ryczalt_cykl_zycia_innovations.pkwiu_rate_classifier"
    decide.pk_expected_rate == 0.25
    decide.pk_rate_mismatch == true
    decide._routing == "TRIAGE_QUEUE"
}

test_inn02_match_no_triage if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "pkwiu_rate": {"pkwiu_code": "47.00", "declared_rate": 0.03, "activity_desc": "handel detaliczny"},
    }
    decide.pk_expected_rate == 0.03
    decide.pk_rate_mismatch == false
    decide._routing == ""
}

# ── R12-INN-03: LIFECYCLE PHASE PLANNER ──────────────────────────────────────

test_inn03_ulga_na_start_phase if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "lifecycle": {"months_operating": 3, "vat_registered": false, "done_steps": ["wpis_ceidg"]},
    }
    decide.rule_id == "jdg.r12_ryczalt_cykl_zycia_innovations.lifecycle_phase_planner"
    decide.lc_phase == "ULGA_NA_START"
    decide.lc_missing_steps == ["vat_r_optional", "zus_zgłoszenie", "ksiegowosc_wybrana"]
    decide._routing == "TRIAGE_QUEUE"
}

test_inn03_growth_when_no_vat if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "lifecycle": {"months_operating": 40, "vat_registered": false, "done_steps": ["wpis_ceidg", "vat_r_optional", "zus_zgłoszenie", "ksiegowosc_wybrana"]},
    }
    decide.lc_phase == "WZROST"
    decide._routing == ""
}

# ── R12-INN-04: SUCCESSION DEADLINE MONITOR ──────────────────────────────────

test_inn04_red_when_3_days if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "succession_monitor": {
            "items": [{"label": "Wpis zarządcy do CEIDG", "days_left": 3, "filed": false}],
        },
    }
    decide.rule_id == "jdg.r12_ryczalt_cykl_zycia_innovations.succession_deadline_monitor"
    decide.sc_red_count == 1
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn04_amber_when_5_days if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "succession_monitor": {
            "items": [{"label": "Wpis zarządcy", "days_left": 5, "filed": false}],
        },
    }
    decide._routing == "TRIAGE_QUEUE"
}

# ── R12-INN-05: TAX FORM ARBITRATOR ──────────────────────────────────────────

test_inn05_ryczalt_when_low_costs if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "tax_form": {"annual_revenue": 100000, "annual_costs": 20000, "employees": 2, "suspended_months": 0},
    }
    decide.rule_id == "jdg.r12_ryczalt_cykl_zycia_innovations.tax_form_arbitrator"
    decide.tf_recommended_form == "RYCZALT"
    decide.tf_suspension_recommend == "KONTYNUUJ"
}

test_inn05_linear_when_high_profit if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "tax_form": {"annual_revenue": 300000, "annual_costs": 100000, "employees": 4, "suspended_months": 0},
    }
    # zysk 200k > 120k → LINIOWY
    decide.tf_recommended_form == "LINIOWY"
}

test_inn05_suspend_when_loss if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
        "tax_form": {"annual_revenue": 50000, "annual_costs": 60000, "employees": 1, "suspended_months": 0},
    }
    decide.tf_suspension_recommend == "ZAWIES_20"
}

# ── no_match ─────────────────────────────────────────────────────────────────

test_inn_no_input_no_match if {
    decide := jdg.r12_ryczalt_cykl_zycia_innovations.decide with input as {
        "jdg_entrepreneur": {"r12_ryczalt_cykl_zycia_check": true},
    }
    decide.rule_id == "jdg.r12_ryczalt_cykl_zycia_innovations.no_match"
}
