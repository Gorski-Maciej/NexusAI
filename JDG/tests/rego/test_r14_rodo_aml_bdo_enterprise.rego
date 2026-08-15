# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_14 — RODO / AML-CBDD / BDO / ŚRODOWISKO — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R14-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r13_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r14_rodo_aml_bdo_innovations

import future.keywords.if

# ── R14-INN-01: RODO REGISTER MONITOR ────────────────────────────────────────

test_inn01_incomplete_register_triage if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "rodo_register": {"data_categories": ["dane osobowe"], "purposes": [], "recipients": [], "complete": false},
    }
    decide.rule_id == "jdg.r14_rodo_aml_bdo_innovations.rodo_register_monitor"
    decide.rg_incomplete == true
    decide._routing == "TRIAGE_QUEUE"
}

test_inn01_complete_register_ok if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "rodo_register": {"data_categories": ["dane osobowe"], "purposes": ["umowa"], "recipients": ["biuro rachunkowe"], "complete": true},
    }
    decide.rg_incomplete == false
    decide._routing == ""
}

# ── R14-INN-02: AML TRANSACTION RISK SCORER ──────────────────────────────────

test_inn02_high_risk_cash_over_threshold if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "aml_transaction": {"amount_eur": 20000, "cash": true, "high_risk_country": false},
    }
    decide.rule_id == "jdg.r14_rodo_aml_bdo_innovations.aml_transaction_risk_scorer"
    decide.at_over_threshold == true
    decide.at_risk_score == 2
    decide.at_high_risk == true
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn02_low_risk_below_threshold if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "aml_transaction": {"amount_eur": 5000, "cash": false, "high_risk_country": false},
    }
    decide.at_risk_score == 0
    decide.at_high_risk == false
    decide._routing == ""
}

# ── R14-INN-03: RODO SANCTION CALCULATOR ─────────────────────────────────────

test_inn03_upper_tier_critical if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "rodo_breach": {"severity": "CRITICAL", "intentional": true, "duration_months": 12},
    }
    decide.rule_id == "jdg.r14_rodo_aml_bdo_innovations.rodo_sanction_calculator"
    decide.rb_upper_tier == true
    decide.rb_max_sanction_eur == 20000000
    decide._routing == "TRIAGE_QUEUE"
}

test_inn03_lower_tier_minor if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "rodo_breach": {"severity": "MINOR", "intentional": false, "duration_months": 2},
    }
    decide.rb_upper_tier == false
    decide.rb_max_sanction_eur == 10000000
    decide._routing == ""
}

# ── R14-INN-04: STR GIJF DEADLINE MONITOR ────────────────────────────────────

test_inn04_red_when_1_day if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "str_monitor": {"items": [{"label": "STR", "days_left": 1, "filed": false}]},
    }
    decide.rule_id == "jdg.r14_rodo_aml_bdo_innovations.str_gijf_deadline_monitor"
    decide.sm_red_count == 1
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn04_amber_when_5_days if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "str_monitor": {"items": [{"label": "STR", "days_left": 5, "filed": false}]},
    }
    decide._routing == "TRIAGE_QUEUE"
}

# ── R14-INN-05: BDO OBLIGATION MONITOR ───────────────────────────────────────

test_inn05_red_when_3_days if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "bdo_monitor": {"items": [{"label": "Rejestracja BDO", "days_left": 3, "filed": false}]},
    }
    decide.rule_id == "jdg.r14_rodo_aml_bdo_innovations.bdo_obligation_monitor"
    decide.bd_red_count == 1
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn05_green_when_filed if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
        "bdo_monitor": {"items": [{"label": "KPO", "days_left": 20, "filed": true}]},
    }
    decide.bd_unfiled_count == 0
    decide._routing == ""
}

# ── no_match ─────────────────────────────────────────────────────────────────

test_inn_no_input_no_match if {
    decide := jdg.r14_rodo_aml_bdo_innovations.decide with input as {
        "jdg_entrepreneur": {"r14_rodo_aml_bdo_check": true},
    }
    decide.rule_id == "jdg.r14_rodo_aml_bdo_innovations.no_match"
}
