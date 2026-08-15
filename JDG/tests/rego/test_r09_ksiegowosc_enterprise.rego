# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_09 — UoR / PKPiR / KSIĘGOWOŚĆ — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R09-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r08_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r09_ksiegowosc_pkpir_uor_innovations

import future.keywords.if

# ── R09-INN-01: UOR THRESHOLD SIMULATOR ───────────────────────────────────────

test_inn01_below_threshold_pkpir if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "uor_simulation": {
            "ytd_revenue_pln": 4500000,
            "monthly_avg_pln": 400000,
            "months_elapsed": 12,
        },
    }
    decide.rule_id == "jdg.r09_ksiegowosc_pkpir_uor_innovations.uor_threshold_simulator"
    decide.uos_current_eur == 1000000
    decide.uos_decision == "PKPiR"
    decide.uos_early_warning == false
    decide._routing == ""
}

test_inn01_above_threshold_uor if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "uor_simulation": {
            "ytd_revenue_pln": 13500000,
            "monthly_avg_pln": 1200000,
            "months_elapsed": 12,
        },
    }
    decide.uos_current_eur == 3000000
    decide.uos_decision == "UoR"
}

test_inn01_early_warning_triage if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "uor_simulation": {
            "ytd_revenue_pln": 7200000,
            "monthly_avg_pln": 600000,
            "months_elapsed": 12,
        },
    }
    # 7.2M PLN / 4.5 = 1.6M EUR = 80% progu -> early warning
    decide.uos_early_warning == true
    decide._routing == "TRIAGE_QUEUE"
    decide.uos_months_to_threshold > 0
}

test_inn01_no_input_no_match if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
    }
    decide.rule_id == "jdg.r09_ksiegowosc_pkpir_uor_innovations.no_match"
}

# ── R09-INN-02: PKPIR LEDGER RECONCILIATION ───────────────────────────────────

test_inn02_reconciled_three_way if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "ledger_reconciliation": {
            "pkpir_col7_sales_net": 100000,
            "vat_sales_base": 100000,
            "bank_inflows": 100000,
            "tolerance_pct": 1.0,
        },
    }
    decide.rule_id == "jdg.r09_ksiegowosc_pkpir_uor_innovations.pkpir_ledger_reconciliation"
    decide.lrecon_vat_ok == true
    decide.lrecon_bank_ok == true
    decide.lrecon_reconciled == true
    decide._routing == ""
    count(decide.lrecon_mismatches) == 0
}

test_inn02_vat_mismatch_triage if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "ledger_reconciliation": {
            "pkpir_col7_sales_net": 100000,
            "vat_sales_base": 85000,
            "bank_inflows": 100000,
            "tolerance_pct": 1.0,
        },
    }
    decide.lrecon_vat_ok == false
    decide.lrecon_bank_ok == true
    decide.lrecon_reconciled == false
    decide._routing == "TRIAGE_QUEUE"
    count(decide.lrecon_mismatches) == 1
}

# ── R09-INN-03: AMORTIZATION PLAN OPTIMIZER ───────────────────────────────────

test_inn03_one_off_eligible_small_taxpayer if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "asset_plan": {
            "asset_value": 200000,
            "kst_group": "3",
            "is_small_taxpayer": true,
            "is_electric": false,
        },
    }
    decide.rule_id == "jdg.r09_ksiegowosc_pkpir_uor_innovations.amortization_plan_optimizer"
    decide.plan_one_off_eligible == true
    decide.plan_best_method == "ONE_OFF"
}

test_inn03_not_small_taxpayer_no_one_off if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "asset_plan": {
            "asset_value": 200000,
            "kst_group": "3",
            "is_small_taxpayer": false,
            "is_electric": false,
        },
    }
    decide.plan_one_off_eligible == false
    decide.plan_linear_annual == 40000
    decide.plan_degressive_annual == 80000
    decide.plan_best_method == "DEGRESSIVE"
}

test_inn03_car_excess_triage if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "asset_plan": {
            "asset_value": 200000,
            "kst_group": "3",
            "is_small_taxpayer": false,
            "is_electric": false,
        },
    }
    decide.plan_car_excess_pln == 50000
    decide._routing == "TRIAGE_QUEUE"
}

# ── R09-INN-04: INVENTORY DEADLINE MONITOR ────────────────────────────────────

test_inn04_red_when_30_days if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "inventory_monitor": {
            "items": [
                {"label": "Środki pieniężne", "type": "CASH", "days_left": 30},
            ],
        },
    }
    decide.rule_id == "jdg.r09_ksiegowosc_pkpir_uor_innovations.inventory_deadline_monitor"
    decide.inv_red_count == 1
    decide._routing == "BLOCK_AND_ALERT"
    decide.inv_items[0].level == "RED"
}

test_inn04_amber_when_60_days if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "inventory_monitor": {
            "items": [
                {"label": "Zapasy", "type": "STOCK", "days_left": 60},
            ],
        },
    }
    decide.inv_items[0].level == "AMBER"
    decide._routing == "TRIAGE_QUEUE"
}

test_inn04_green_when_200_days if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "inventory_monitor": {
            "items": [
                {"label": "Środki trwałe", "type": "FIXED_ASSETS", "days_left": 200},
            ],
        },
    }
    decide.inv_items[0].level == "GREEN"
    decide._routing == ""
}

# ── R09-INN-05: FINANCIAL STATEMENT AUTOPACK ──────────────────────────────────

test_inn05_complete_ready if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "financial_statements": {
            "year": 2025,
            "has_balance_sheet": true,
            "has_rzis": true,
            "has_notes": true,
            "has_approval": true,
        },
    }
    decide.rule_id == "jdg.r09_ksiegowosc_pkpir_uor_innovations.financial_statement_autopack"
    decide.fs_ready == true
    count(decide.fs_missing) == 0
    decide._routing == ""
    decide.fs_retention_years == 5
}

test_inn05_missing_sections_triage if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "financial_statements": {
            "year": 2025,
            "has_balance_sheet": true,
            "has_rzis": false,
            "has_notes": false,
            "has_approval": false,
        },
    }
    decide.fs_ready == false
    count(decide.fs_missing) == 3
    decide._routing == "TRIAGE_QUEUE"
}

test_inn05_deadlines_computed if {
    decide := jdg.r09_ksiegowosc_pkpir_uor_innovations.decide with input as {
        "jdg_entrepreneur": {"r09_ksiegowosc_check": true},
        "financial_statements": {
            "year": 2025,
            "has_balance_sheet": true,
            "has_rzis": true,
            "has_notes": true,
            "has_approval": true,
        },
    }
    decide.fs_approval_deadline == "2026-03-31"
    decide.fs_filing_deadline == "2026-10-15"
    decide.fs_retention_until == "2031-12-31"
}
