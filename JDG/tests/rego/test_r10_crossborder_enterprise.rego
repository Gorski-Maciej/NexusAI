# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_10 — CROSS-BORDER / TP / MDR-DAC6 / CFC — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R10-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r09_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r10_crossborder_innovations

import future.keywords.if

# ── R10-INN-01: WDT DEADLINE ALERT MONITOR ────────────────────────────────────

test_inn01_red_when_5_days_no_docs if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "wdt_monitor": {
            "items": [
                {"label": "Dowód wywozu F-2026-01", "days_left": 5, "docs_received": false},
            ],
        },
    }
    decide.rule_id == "jdg.r10_crossborder_innovations.wdt_deadline_alert_monitor"
    decide.wdt_red_count == 1
    decide.wdt_missing_count == 1
    decide._routing == "BLOCK_AND_ALERT"
    decide.wdt_items[0].level == "RED"
}

test_inn01_amber_when_10_days if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "wdt_monitor": {
            "items": [
                {"label": "Dowód wywozu F-2026-02", "days_left": 10, "docs_received": false},
            ],
        },
    }
    decide.wdt_items[0].level == "AMBER"
    decide._routing == "TRIAGE_QUEUE"
}

test_inn01_green_when_docs_received if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "wdt_monitor": {
            "items": [
                {"label": "Dowód wywozu F-2026-03", "days_left": 25, "docs_received": true},
            ],
        },
    }
    decide.wdt_items[0].level == "GREEN"
    decide.wdt_missing_count == 0
    decide._routing == ""
}

# ── R10-INN-02: MDR RISK SCORER ───────────────────────────────────────────────

test_inn02_high_risk_crossborder_a if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "mdr_assessment": {"hallmark": "A", "cross_border": true, "main_benefit": true},
    }
    decide.rule_id == "jdg.r10_crossborder_innovations.mdr_risk_scorer"
    decide.mdr_risk_score == 100
    decide._routing == "BLOCK_AND_ALERT"
    decide.mdr_confidence == "HIGH"
}

test_inn02_low_risk_domestic_e if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "mdr_assessment": {"hallmark": "E", "cross_border": false, "main_benefit": false},
    }
    decide.mdr_risk_score == 20
    decide._routing == ""
}

test_inn02_medium_risk_triage if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "mdr_assessment": {"hallmark": "C", "cross_border": true, "main_benefit": false},
    }
    # 30 + 30 + 0 = 60
    decide.mdr_risk_score == 60
    decide._routing == "TRIAGE_QUEUE"
}

# ── R10-INN-03: TP THRESHOLD SIMULATOR ────────────────────────────────────────

test_inn03_local_required_over_500k if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "tp_simulation": {
            "transactions_value_pln": 750000,
            "related_parties": true,
            "group_revenue_pln": 50000000,
            "monthly_avg_pln": 100000,
        },
    }
    decide.rule_id == "jdg.r10_crossborder_innovations.tp_threshold_simulator"
    decide.tp_local_required == true
    decide.tp_master_required == false
    decide._routing == "TRIAGE_QUEUE"
}

test_inn03_below_threshold_no_obligation if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "tp_simulation": {
            "transactions_value_pln": 200000,
            "related_parties": true,
            "group_revenue_pln": 10000000,
            "monthly_avg_pln": 50000,
        },
    }
    decide.tp_local_required == false
    decide._routing == ""
    decide.tp_months_to_local > 0
}

test_inn03_master_required_over_200m if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "tp_simulation": {
            "transactions_value_pln": 750000,
            "related_parties": true,
            "group_revenue_pln": 300000000,
            "monthly_avg_pln": 100000,
        },
    }
    decide.tp_master_required == true
}

# ── R10-INN-04: CFC PROFIT ATTRIBUTION ────────────────────────────────────────

test_inn04_cfc_applies_and_attribution if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "cfc_attribution": {
            "ownership_pct": 0.60,
            "passive_income_pln": 500000,
            "foreign_tax_rate_pct": 0.10,
        },
    }
    decide.rule_id == "jdg.r10_crossborder_innovations.cfc_profit_attribution"
    decide.cfc_applies == true
    decide.cfc_attributed_base_pln == 300000
    decide._routing == "TRIAGE_QUEUE"
}

test_inn04_no_cfc_when_high_foreign_tax if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "cfc_attribution": {
            "ownership_pct": 0.60,
            "passive_income_pln": 500000,
            "foreign_tax_rate_pct": 0.20,
        },
    }
    decide.cfc_applies == false
    decide.cfc_attributed_base_pln == 0
    decide._routing == ""
}

# ── R10-INN-05: FX TIME TRAVEL RECONCILER ─────────────────────────────────────

test_inn05_fx_schedule_computed if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
        "fx_schedule": {
            "amount_foreign": 10000,
            "currency": "EUR",
            "periods": [
                {"from": "2025-01-01", "to": "2025-03-31", "rate": 4.5},
                {"from": "2025-04-01", "to": "2025-06-30", "rate": 4.4},
            ],
            "settlement_rate": 4.6,
        },
    }
    decide.rule_id == "jdg.r10_crossborder_innovations.fx_time_travel_reconciler"
    count(decide.fx_schedule) == 2
    decide.fx_latest_rate == 4.4
    decide.fx_realized_diff_pln == 2000
    decide._routing == "TRIAGE_QUEUE"
}

test_inn05_no_input_no_match if {
    decide := jdg.r10_crossborder_innovations.decide with input as {
        "jdg_entrepreneur": {"r10_crossborder_check": true},
    }
    decide.rule_id == "jdg.r10_crossborder_innovations.no_match"
}
