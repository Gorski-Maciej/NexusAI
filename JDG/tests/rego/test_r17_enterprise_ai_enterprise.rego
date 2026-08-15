# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_17 — ENTERPRISE AI (inteligencja systemu) — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R17-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r16_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r17_enterprise_ai_innovations

import future.keywords.if

# ── R17-INN-01: ADAPTIVE TRUST MONITOR ───────────────────────────────────────

test_inn01_auto_post_high_trust if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "adaptive_trust": {"trust_score": 0.95, "feedback_count": 40},
    }
    decide.rule_id == "jdg.r17_enterprise_ai_innovations.adaptive_trust_monitor"
    decide.at_mode == "AUTO_POST"
    decide._routing == ""
}

test_inn01_suggest_mid_trust if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "adaptive_trust": {"trust_score": 0.8, "feedback_count": 10},
    }
    decide.at_mode == "SUGGEST"
}

test_inn01_ask_user_low_trust if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "adaptive_trust": {"trust_score": 0.6, "feedback_count": 2},
    }
    decide.at_mode == "ASK_USER"
    decide._routing == "BLOCK_AND_ALERT"
}

# ── R17-INN-02: NEURAL MESH CONFIDENCE MONITOR ───────────────────────────────

test_inn02_conflict_block if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "neural_mesh": {"confidence": 0.6, "conflict_count": 2},
    }
    decide.rule_id == "jdg.r17_enterprise_ai_innovations.neural_mesh_confidence_monitor"
    decide.nm_reliable == false
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn02_reliable_ok if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "neural_mesh": {"confidence": 0.8, "conflict_count": 0},
    }
    decide.nm_reliable == true
    decide._routing == ""
}

# ── R17-INN-03: CASHFLOW FORECAST MONITOR ────────────────────────────────────

test_inn03_gap_block if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "cashflow": {"forecast_days": 90, "liquidity_gap_pln": 5000, "buffer_pct": 30},
    }
    decide.rule_id == "jdg.r17_enterprise_ai_innovations.cashflow_forecast_monitor"
    decide.cf_gap_alert == true
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn03_low_buffer_triage if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "cashflow": {"forecast_days": 90, "liquidity_gap_pln": 0, "buffer_pct": 5},
    }
    decide.cf_buffer_ok == false
    decide._routing == "TRIAGE_QUEUE"
}

test_inn03_healthy_ok if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "cashflow": {"forecast_days": 90, "liquidity_gap_pln": 0, "buffer_pct": 40},
    }
    decide._routing == ""
}

# ── R17-INN-04: BANKING PSD2 MONITOR ─────────────────────────────────────────

test_inn04_invalid_iban_block if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "banking": {"split_payment_amount_pln": 5000, "iban_valid": false, "batch_size": 10},
    }
    decide.rule_id == "jdg.r17_enterprise_ai_innovations.banking_psd2_monitor"
    decide.bk_iban_valid == false
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn04_split_payment_required if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "banking": {"split_payment_amount_pln": 20000, "iban_valid": true, "batch_size": 10},
    }
    decide.bk_split_required == true
    decide._routing == "TRIAGE_QUEUE"
}

test_inn04_standard_payment_ok if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "banking": {"split_payment_amount_pln": 5000, "iban_valid": true, "batch_size": 10},
    }
    decide._routing == ""
}

# ── R17-INN-05: LEGISLATIVE CHANGE MONITOR ───────────────────────────────────

test_inn05_alert_block if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "legislative": {"days_until_effective": 5, "impact_score": 80, "vacatio_compliant": false},
    }
    decide.rule_id == "jdg.r17_enterprise_ai_innovations.legislative_change_monitor"
    decide.lg_alert == true
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn05_high_impact_triage if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "legislative": {"days_until_effective": 30, "impact_score": 85, "vacatio_compliant": true},
    }
    decide.lg_high_impact == true
    decide._routing == "TRIAGE_QUEUE"
}

test_inn05_low_risk_ok if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
        "legislative": {"days_until_effective": 60, "impact_score": 20, "vacatio_compliant": true},
    }
    decide._routing == ""
}

# ── no_match ─────────────────────────────────────────────────────────────────

test_inn_no_input_no_match if {
    decide := jdg.r17_enterprise_ai_innovations.decide with input as {
        "jdg_entrepreneur": {"r17_enterprise_ai_check": true},
    }
    decide.rule_id == "jdg.r17_enterprise_ai_innovations.no_match"
}
