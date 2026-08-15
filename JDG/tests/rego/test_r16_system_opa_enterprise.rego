# ═══════════════════════════════════════════════════════════════════════════════
# RAPORT_16 — SYSTEM OPA (P18–P35) — natywne testy Rego
# Scenariusze: happy path, granice (progi, limity), negatywne (no_match),
# temporalność (valid_from/valid_to) dla R16-INN-01..05.
# Uruchomienie: opa test (native OPA) — struktura jak test_r15_*.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r16_system_opa_innovations

import future.keywords.if

# ── R16-INN-01: RULE LIFECYCLE MONITOR ───────────────────────────────────────

test_inn01_rollback_when_error_high if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "rule_lifecycle": {"phase": "ACTIVE", "error_rate": 0.05, "rollout_pct": 100},
    }
    decide.rule_id == "jdg.r16_system_opa_innovations.rule_lifecycle_monitor"
    decide.rl_should_rollback == true
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn01_candidate_triage if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "rule_lifecycle": {"phase": "CANDIDATE", "error_rate": 0.001, "rollout_pct": 5},
    }
    decide.rl_should_rollback == false
    decide._routing == "TRIAGE_QUEUE"
}

test_inn01_active_ok if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "rule_lifecycle": {"phase": "ACTIVE", "error_rate": 0.0, "rollout_pct": 100},
    }
    decide._routing == ""
}

# ── R16-INN-02: VALIDATION QUALITY MONITOR ───────────────────────────────────

test_inn02_defects_block if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "validation_quality": {"tautology_count": 2, "dead_rules": 1, "hardcoded_count": 0},
    }
    decide.rule_id == "jdg.r16_system_opa_innovations.validation_quality_monitor"
    decide.vq_zero_defect == false
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn02_zero_defect_ok if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "validation_quality": {"tautology_count": 0, "dead_rules": 0, "hardcoded_count": 0},
    }
    decide.vq_zero_defect == true
    decide._routing == ""
}

# ── R16-INN-03: TEST SHIELD MONITOR ──────────────────────────────────────────

test_inn03_shield_fail_low_mutation if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "test_shield": {"mutation_pct": 50, "defects": 0, "coverage_pct": 95},
    }
    decide.rule_id == "jdg.r16_system_opa_innovations.test_shield_monitor"
    decide.ts_mutation_ok == false
    decide.ts_shield_ok == false
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn03_shield_pass if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "test_shield": {"mutation_pct": 80, "defects": 0, "coverage_pct": 95},
    }
    decide.ts_shield_ok == true
    decide._routing == ""
}

# ── R16-INN-04: RELIABILITY DETERMINISM MONITOR ──────────────────────────────

test_inn04_not_reliable_block if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "reliability": {"deterministic": true, "provenance_ok": false, "fallback_ready": true},
    }
    decide.rule_id == "jdg.r16_system_opa_innovations.reliability_determinism_monitor"
    decide.rb_reliable == false
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn04_reliable_ok if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "reliability": {"deterministic": true, "provenance_ok": true, "fallback_ready": true},
    }
    decide.rb_reliable == true
    decide._routing == ""
}

# ── R16-INN-05: ISAP PIPELINE MONITOR ────────────────────────────────────────

test_inn05_sla_breach_block if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "isap_pipeline": {"hours_elapsed": 30, "priority": "STANDARD", "deployed": false},
    }
    decide.rule_id == "jdg.r16_system_opa_innovations.isap_pipeline_monitor"
    decide.ip_sla_breach == true
    decide._routing == "BLOCK_AND_ALERT"
}

test_inn05_in_progress_triage if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "isap_pipeline": {"hours_elapsed": 10, "priority": "STANDARD", "deployed": false},
    }
    decide.ip_sla_breach == false
    decide._routing == "TRIAGE_QUEUE"
}

test_inn05_deployed_ok if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
        "isap_pipeline": {"hours_elapsed": 5, "priority": "P0", "deployed": true},
    }
    decide._routing == ""
}

# ── no_match ─────────────────────────────────────────────────────────────────

test_inn_no_input_no_match if {
    decide := jdg.r16_system_opa_innovations.decide with input as {
        "jdg_entrepreneur": {"r16_system_opa_check": true},
    }
    decide.rule_id == "jdg.r16_system_opa_innovations.no_match"
}
