# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for R05 GLM52 PIT — ENTERPRISE
# Package: jdg.r05_pit_enterprise_innovations
# Source: 05_PIT_ENTERPRISE.txt (prompty_glm52)
# Generated: 2026-08-14
# ═══════════════════════════════════════════════════════════════════════════════

package test_r05_pit_enterprise

import future.keywords.in

# ═══ DEFAULT: bez flagi r05_pit_enterprise_check → no_match ═══

test_default_no_match {
    result := data.jdg.r05_pit_enterprise_innovations.decide with input as {
        "jdg_entrepreneur": {"r05_pit_enterprise_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.r05_pit_enterprise_innovations.no_match"
}

# ═══ R05-INN-01: ANNUAL AUTOPILOT Z DECISION CERTIFICATE ═══

test_annual_autopilot_scale_ready {
    auto := data.jdg.r05_pit_enterprise_innovations.annual_autopilot with input as {
        "jdg_entrepreneur": {"r05_annual_autopilot_check": true},
        "annual_autopilot": {
            "tax_form": "SCALE",
            "annual_income": 80000,
            "advances_paid": 5000,
            "reliefs_used": ["IKZE"],
            "jpk_files_ready": true,
            "advances_reconciled": true,
            "bundle_version": "jdg-pite-bundle-v9.0.0",
            "threshold_version": "2026.1",
        },
    }
    auto.autopilot.expected_declaration == "PIT-36"
    auto.autopilot.ready == true
    auto.autopilot.decision_certificate.hash_algorithm == "sha256-canonical-json-v1"
    auto.autopilot.decision_certificate.bundle_version == "jdg-pite-bundle-v9.0.0"
    auto.autopilot.decision_certificate.threshold_version == "2026.1"
    auto.autopilot.balance_due == 4600
}

test_annual_autopilot_missing_items {
    auto := data.jdg.r05_pit_enterprise_innovations.annual_autopilot with input as {
        "jdg_entrepreneur": {"r05_annual_autopilot_check": true},
        "annual_autopilot": {
            "tax_form": "LINEAR",
            "annual_income": 100000,
            "advances_paid": 0,
            "reliefs_used": [],
            "jpk_files_ready": false,
        },
    }
    auto.autopilot.expected_declaration == "PIT-36L"
    auto.autopilot.ready == false
    "jpk_files" in auto.autopilot.missing
    "reliefs_documented" in auto.autopilot.missing
}

test_annual_autopilot_lump_pit28 {
    auto := data.jdg.r05_pit_enterprise_innovations.annual_autopilot with input as {
        "jdg_entrepreneur": {"r05_annual_autopilot_check": true},
        "annual_autopilot": {
            "tax_form": "LUMP_SUM",
            "annual_income": 60000,
            "advances_paid": 5100,
            "reliefs_used": ["IKZE"],
            "jpk_files_ready": true,
            "advances_reconciled": true,
        },
    }
    auto.autopilot.expected_declaration == "PIT-28"
    auto.autopilot.ready == true
    auto.autopilot.overpayment == 0
}

# ═══ R05-INN-02: FORM TRANSITION 3-YEAR FORECAST ═══

test_form_3y_linear_best_high_income {
    fc := data.jdg.r05_pit_enterprise_innovations.form_transition_3y with input as {
        "jdg_entrepreneur": {"r05_form_3y_check": true},
        "form_transition_3y": {
            "current_form": "SCALE",
            "year1_income": 400000,
            "growth_rate": 0.10,
        },
    }
    fc.forecast.income_projection.year2 == 440000
    fc.forecast.income_projection.year3 == 484000
    fc.forecast.best_form_3y == "LINEAR"
}

test_form_3y_lump_best_low_income {
    fc := data.jdg.r05_pit_enterprise_innovations.form_transition_3y with input as {
        "jdg_entrepreneur": {"r05_form_3y_check": true},
        "form_transition_3y": {
            "current_form": "SCALE",
            "year1_income": 50000,
            "growth_rate": 0.0,
        },
    }
    fc.forecast.best_form_3y == "LUMP_SUM"
}

test_form_3y_zero_growth_flat {
    fc := data.jdg.r05_pit_enterprise_innovations.form_transition_3y with input as {
        "jdg_entrepreneur": {"r05_form_3y_check": true},
        "form_transition_3y": {
            "current_form": "LINEAR",
            "year1_income": 200000,
            "growth_rate": 0.0,
        },
    }
    fc.forecast.income_projection.year1 == 200000
    fc.forecast.income_projection.year2 == 200000
    fc.forecast.income_projection.year3 == 200000
}

# ═══ R05-INN-03: STRATEGIC DECISION SCORING ═══

test_strategic_scoring_form_change {
    sc := data.jdg.r05_pit_enterprise_innovations.strategic_decision_score with input as {
        "jdg_entrepreneur": {"r05_strategic_decision_check": true},
        "strategic_decision": {"decision_type": "FORM_CHANGE", "context": {}},
    }
    sc.scoring.score_0_100 == 80
    sc.scoring.risk_level == "LOW"
    sc.scoring.legal_basis == "Art. 9a PIT (wybór formy opodatkowania)"
}

test_strategic_scoring_exit_medium {
    sc := data.jdg.r05_pit_enterprise_innovations.strategic_decision_score with input as {
        "jdg_entrepreneur": {"r05_strategic_decision_check": true},
        "strategic_decision": {"decision_type": "EXIT", "context": {}},
    }
    sc.scoring.score_0_100 == 55
    sc.scoring.risk_level == "MEDIUM"
    sc.scoring.legal_basis == "Art. 30da PIT + MDR (art. 86-86m Ordynacji)"
}

test_strategic_scoring_unknown_zero {
    sc := data.jdg.r05_pit_enterprise_innovations.strategic_decision_score with input as {
        "jdg_entrepreneur": {"r05_strategic_decision_check": true},
        "strategic_decision": {"decision_type": "UNKNOWN", "context": {}},
    }
    sc.scoring.score_0_100 == 0
    sc.scoring.risk_level == "HIGH"
}

# ═══ R05-INN-04: JPK HARMONIZATION ═══

test_jpk_harmonization_consistent {
    jh := data.jdg.r05_pit_enterprise_innovations.jpk_harmonization with input as {
        "jdg_entrepreneur": {"r05_jpk_harmonization_check": true},
        "jpk_harmonization": {
            "annual_revenue": 500000,
            "jpk_v7m_revenue": 500050,
            "jpk_cit_ready": true,
            "jpk_v7m_ready": true,
        },
    }
    jh.harmonization.revenue_delta == -50
    jh.harmonization.revenue_consistent == true
    jh.harmonization.all_jpk_ready == true
}

test_jpk_harmonization_mismatch_alert {
    jh := data.jdg.r05_pit_enterprise_innovations.jpk_harmonization with input as {
        "jdg_entrepreneur": {"r05_jpk_harmonization_check": true},
        "jpk_harmonization": {
            "annual_revenue": 500000,
            "jpk_v7m_revenue": 450000,
            "jpk_cit_ready": false,
            "jpk_v7m_ready": true,
        },
    }
    jh.harmonization.revenue_delta == 50000
    jh.harmonization.revenue_consistent == false
    jh.harmonization.all_jpk_ready == false
}

# ═══ RAPORT ENTERPRISE: aktywna flaga ═══

test_pit_enterprise_report {
    result := data.jdg.r05_pit_enterprise_innovations.decide with input as {
        "jdg_entrepreneur": {"r05_pit_enterprise_check": true},
        "annual_autopilot": {
            "tax_form": "SCALE",
            "annual_income": 80000,
            "advances_paid": 5000,
            "reliefs_used": ["IKZE"],
            "jpk_files_ready": true,
            "advances_reconciled": true,
        },
        "form_transition_3y": {"current_form": "SCALE", "year1_income": 400000, "growth_rate": 0.10},
        "strategic_decision": {"decision_type": "FORM_CHANGE", "context": {}},
        "jpk_harmonization": {
            "annual_revenue": 500000,
            "jpk_v7m_revenue": 500050,
            "jpk_cit_ready": true,
            "jpk_v7m_ready": true,
        },
    }
    result.matched == true
    result.rule_id == "jdg.r05_pit_enterprise_innovations.pit_enterprise_report"
    result._routing == "REPORT"
    result.pit_enterprise.annual_autopilot.expected_declaration == "PIT-36"
    result.pit_enterprise.form_3y_forecast.best_form_3y == "LINEAR"
    result.pit_enterprise.strategic_scoring.score_0_100 == 80
    result.pit_enterprise.jpk_harmonization.revenue_consistent == true
}
