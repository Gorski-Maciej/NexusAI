# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Tests: P05 PIT MACRO ENTERPRISE v9.0
# Sekcje: 1 (formy opodatkowania), 2 (ulgi — PRIORYTET), 3 (KUP/NKUP),
#         4 (zaliczki/zeznanie), 5 (Art. 21), 6 (thresholdy temporalne),
#         7 (genius ideas)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p05_pit_macro_enterprise_test

import future.keywords.in

# ── SEKCJA 1: FORMY OPODATKOWANIA ─────────────────────────────────────────────

test_form_audit_report := {
    result := data.jdg.p05_pit_macro_innovations.form_audit_report
    result.forms.SCALE.threshold == 120000
    result.forms.LINEAR.joint_filing == "BLOCKED"
    result.change_ok == true
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_form_check": true, "tax_form": "SCALE", "form_change_deadline_ok": true}
} with data.jdg.thresholds as {
    "rates": {"pit_scale_low": 0.12, "pit_scale_high": 0.32, "pit_linear": 0.19},
    "scale_threshold": 120000,
    "pit_relief_shared_limit": 85528
}

test_form_change_simulator := {
    result := data.jdg.p05_pit_macro_innovations.form_change_simulator
    result.simulation.linear.tax < result.simulation.scale.tax
    result.simulation.recommendation == "LINEAR"
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_form_sim_check": true, "forecast_annual_income": 300000}
} with data.jdg.thresholds as {
    "rates": {"pit_scale_low": 0.12, "pit_scale_high": 0.32, "pit_linear": 0.19},
    "scale_threshold": 120000,
    "pit_relief_shared_limit": 85528
}

# ── SEKCJA 2: AUDYT ULG (PRIORYTET) ───────────────────────────────────────────

test_relief_audit_report := {
    result := data.jdg.p05_pit_macro_innovations.relief_audit_report
    result.audit.registry_count == 8
    result.audit.pit0_within_limit == true
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_relief_check": true, "br_costs": 10000, "br_eligible": true,
        "pit0_income": 50000}
} with data.jdg.thresholds as {
    "rates": {"pit_scale_low": 0.12, "pit_scale_high": 0.32, "pit_linear": 0.19},
    "scale_threshold": 120000,
    "pit_relief_shared_limit": 85528
}

test_unused_relief_detector := {
    result := data.jdg.p05_pit_macro_innovations.unused_relief_detector
    result.detected.unused_count >= 1
    "THERMO" in result.detected.unused
    result._routing == "TRIAGE_QUEUE"
} with input as {
    "jdg_entrepreneur": {"p05_relief_check": true, "br_costs": 10000, "br_eligible": true,
        "br_claimed": true, "thermo_costs": 20000, "thermo_eligible": true, "thermo_claimed": false}
} with data.jdg.thresholds as {
    "rates": {"pit_scale_low": 0.12, "pit_scale_high": 0.32, "pit_linear": 0.19},
    "scale_threshold": 120000,
    "pit_relief_shared_limit": 85528,
    "relief_limits": {"BR_MULTIPLIER": 1.0, "IP_BOX_RATE": 0.05, "THERMO_LIMIT": 53000,
        "PROTOTYPE_RATE": 0.30, "ROBOTICS_RATE": 0.50, "EXPANSION_RATE": 0.30,
        "LOSS_CARRY_YEARS": 5, "LOSS_DEDUCTION_CAP": 0.5, "PIT0_SHARED_LIMIT": 85528}
}

test_relief_what_if := {
    result := data.jdg.p05_pit_macro_innovations.relief_what_if
    result.simulation.best.id == "IP_BOX"
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_relief_check": true, "what_if_relief": "IP_BOX",
        "ip_box_income": 100000, "ip_box_eligible": true, "br_costs": 1000, "thermo_costs": 1000}
} with data.jdg.thresholds as {
    "rates": {"pit_scale_low": 0.12, "pit_scale_high": 0.32, "pit_linear": 0.19},
    "scale_threshold": 120000,
    "pit_relief_shared_limit": 85528
}

# ── SEKCJA 3: KUP / NKUP ──────────────────────────────────────────────────────

test_kup_audit_creator := {
    result := data.jdg.p05_pit_macro_innovations.kup_audit_report
    result.audit.kup_rate == 0.50
    result.audit.standard_rate == 0.20
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_kup_check": true, "is_copyright_creator": true}
}

test_kup_audit_standard := {
    result := data.jdg.p05_pit_macro_innovations.kup_audit_report
    result.audit.kup_rate == 0.20
} with input as {
    "jdg_entrepreneur": {"p05_kup_check": true, "is_copyright_creator": false}
}

# ── SEKCJA 4: ZALICZKI (art. 44) I ZEZNANIE (art. 45) ─────────────────────────

test_advance_audit := {
    result := data.jdg.p05_pit_macro_innovations.advance_audit_report
    result.audit.deadline_ok == true
    result.audit.annual_returns["PIT-36"] == "Skala — do 30 kwietnia"
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_advance_check": true, "advance_payment_day": 18}
}

# ── SEKCJA 5: ZWOLNIENIA ART. 21 ──────────────────────────────────────────────

test_art21_audit := {
    result := data.jdg.p05_pit_macro_innovations.art21_audit_report
    result.audit.active_category == "YOUNG"
    result.audit.shared_limit == 85528
    result.audit.within_limit == true
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_art21_check": true, "pit0_category": "YOUNG", "pit0_income": 40000}
} with data.jdg.thresholds as {
    "pit_relief_shared_limit": 85528
}

# ── SEKCJA 6: THRESHOLDY TEMPORALNE ───────────────────────────────────────────

test_thresholds_snapshot := {
    result := data.jdg.p05_pit_macro_innovations.pit_thresholds_snapshot
    result.scale_threshold == 120000
    result.linear_rate == 0.19
    result.source == "data.jdg.thresholds (ADR-002) — zero hardcode, hot-reload per novelizacja"
} with data.jdg.thresholds as {
    "rates": {"pit_scale_low": 0.12, "pit_scale_high": 0.32, "pit_linear": 0.19},
    "scale_threshold": 120000,
    "pit_relief_shared_limit": 85528
}

# ── SEKCJA 7: GENIALNE POMYSŁY ────────────────────────────────────────────────

test_zaliczka_recommendation := {
    result := data.jdg.p05_pit_macro_innovations.zaliczka_recommendation
    result.recommendation.strategy == "SIMPLIFIED_IF_LIQUIDITY_RISK"
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_zaliczka_check": true, "prev_year_income": 120000}
}

test_loss_optimizer := {
    result := data.jdg.p05_pit_macro_innovations.loss_optimizer
    result.optimization.carry_years == 5
    result.optimization.annual_cap == 0.5
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_relief_check": true, "loss_to_use": 20000, "loss_eligible": true}
} with data.jdg.thresholds as {
    "relief_limits": {"BR_MULTIPLIER": 1.0, "IP_BOX_RATE": 0.05, "THERMO_LIMIT": 53000,
        "PROTOTYPE_RATE": 0.30, "ROBOTICS_RATE": 0.50, "EXPANSION_RATE": 0.30,
        "LOSS_CARRY_YEARS": 5, "LOSS_DEDUCTION_CAP": 0.5, "PIT0_SHARED_LIMIT": 85528}
}

# ── GŁÓWNY RAPORT P05 ─────────────────────────────────────────────────────────

test_p05_main_decide := {
    result := data.jdg.p05_pit_macro_innovations.decide
    result.matched == true
    result.rule_id == "jdg.p05_pit_macro_innovations.report"
    result.p05_pit_macro.section2_reliefs.registry_count == 8
    result.p05_pit_macro.section7_innovations.INN15_audit_trail == true
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p05_pit_macro_check": true, "pit0_income": 40000}
} with data.jdg.thresholds as {
    "rates": {"pit_scale_low": 0.12, "pit_scale_high": 0.32, "pit_linear": 0.19},
    "scale_threshold": 120000,
    "pit_relief_shared_limit": 85528
}

# ── DOMYŚLNE no_match (normalny ruch bez flag P05) ────────────────────────────

test_p05_default_no_match := {
    data.jdg.p05_pit_macro_innovations.decide.matched == false
    data.jdg.p05_pit_macro_innovations.decide.rule_id == "jdg.p05_pit_macro_innovations.no_match"
} with input as {
    "invoice": {"direction": "SALE", "amount_net": 1000},
    "jdg_entrepreneur": {"tax_form": "SCALE"}
}
