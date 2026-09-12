# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P52 GRANICE GROSZOWE (konwencja P39/P45–P51:
# negative-first, granice progów, fail-closed, never-silent AUTO_POST,
# bypass → BLOCK, determinizm else-chain).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p52_penny_granularity_test

import data.jdg.v3_p52_penny_granularity as p52

# ── Helper ─────────────────────────────────────────────────────────────────────
p52_input(analysis, ctx) = {"jdg_entrepreneur": {"v3_p52_check": true},
                            "v3_p52": object.union({"analysis": analysis}, ctx)}

# ═══════════════════════════════════════════════════════════════════════════════
# Determinizm łańcucha / aktywacja
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_no_activation_no_match {
    r := p52.decide with input as {}
    r.rule_id == "jdg.v3_p52_penny_granularity.no_match"
    r.matched == false
}

test_p52_no_selector_no_match {
    r := p52.decide with input as p52_input("brak_takiej_analizy", {})
    r.rule_id == "jdg.v3_p52_penny_granularity.no_match"
}

test_p52_thresholds_missing_fail_closed {
    # default-deny: brak snapshotu progów = BLOCK, nigdy cicha decyzja (AP07)
    r := p52.decide with input as p52_input("standards_register", {})
        with data.jdg.thresholds.v3_p52 as {}
    r.rule_id == "jdg.v3_p52_penny_granularity.thresholds_missing"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.priority == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# I01: standards register (noncompliant_max=0)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i01_all_compliant_autos {
    r := p52.decide with input as p52_input("standards_register", {
        "standards_register": {"tools_total": 9, "tools_noncompliant": 0,
                               "rego_round2_duplicates": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.tools_noncompliant == 0
}

test_p52_i01_one_noncompliant_blocks {
    # operacja poza standardem art. 107 OP = kwota niereprodukowalna → BLOCK
    r := p52.decide with input as p52_input("standards_register", {
        "standards_register": {"tools_total": 9, "tools_noncompliant": 1,
                               "rego_round2_duplicates": 6},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.tools_noncompliant == 1
}

test_p52_i01_empty_register_triage {
    r := p52.decide with input as p52_input("standards_register", {
        "standards_register": {"tools_total": 0, "tools_noncompliant": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i01_standards_bypass_blocks {
    r := p52.decide with input as p52_input("standards_register", {
        "standards_register": {"tools_total": 9, "tools_noncompliant": 0},
        "standards_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I02: penny boundary matrix (thresholds_min=4)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i02_full_matrix_autos {
    r := p52.decide with input as p52_input("penny_boundary_matrix", {
        "penny_boundary_matrix": {"cases_total": 20, "thresholds_covered": 4},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i02_partial_matrix_triage {
    r := p52.decide with input as p52_input("penny_boundary_matrix", {
        "penny_boundary_matrix": {"cases_total": 5, "thresholds_covered": 2},
    })
    r.decision_mode == "TRIAGE"
    r.thresholds_required == 3
}

test_p52_i02_zero_cases_triage {
    r := p52.decide with input as p52_input("penny_boundary_matrix", {
        "penny_boundary_matrix": {"cases_total": 0, "thresholds_covered": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i02_boundary_bypass_blocks {
    r := p52.decide with input as p52_input("penny_boundary_matrix", {
        "penny_boundary_matrix": {"cases_total": 20, "thresholds_covered": 4},
        "boundary_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I03: rate provenance (AP09)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i03_all_fx_with_provenance_autos {
    r := p52.decide with input as p52_input("rate_provenance", {
        "rate_provenance": {"tools_with_fx": 3, "tools_with_provenance": 3,
                            "rego_provenance_required": true},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i03_fx_without_provenance_triage {
    r := p52.decide with input as p52_input("rate_provenance", {
        "rate_provenance": {"tools_with_fx": 3, "tools_with_provenance": 0,
                            "rego_provenance_required": true},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p52_i03_rego_no_provenance_triage {
    r := p52.decide with input as p52_input("rate_provenance", {
        "rate_provenance": {"tools_with_fx": 0, "tools_with_provenance": 0,
                            "rego_provenance_required": false},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i03_provenance_bypass_blocks {
    r := p52.decide with input as p52_input("rate_provenance", {
        "rate_provenance": {"tools_with_fx": 0, "tools_with_provenance": 0,
                            "rego_provenance_required": true},
        "provenance_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I04: weekend/holiday rate path (holidays_min=20)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i04_path_tested_autos {
    r := p52.decide with input as p52_input("weekend_rate_path", {
        "weekend_rate_path": {"cases_total": 26, "no_table_days": 10,
                              "holidays_registered": 25},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i04_calendar_incomplete_triage {
    r := p52.decide with input as p52_input("weekend_rate_path", {
        "weekend_rate_path": {"cases_total": 10, "no_table_days": 4,
                              "holidays_registered": 13},
    })
    r.decision_mode == "TRIAGE"
    r.holidays_min == 20
}

test_p52_i04_zero_cases_triage {
    r := p52.decide with input as p52_input("weekend_rate_path", {
        "weekend_rate_path": {"cases_total": 0, "no_table_days": 0,
                              "holidays_registered": 25},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i04_weekend_bypass_blocks {
    r := p52.decide with input as p52_input("weekend_rate_path", {
        "weekend_rate_path": {"cases_total": 26, "no_table_days": 10,
                              "holidays_registered": 25},
        "weekend_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I05: sum invariants (checks_min=100)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i05_clean_invariants_autos {
    r := p52.decide with input as p52_input("sum_invariants", {
        "sum_invariants": {"checks_run": 200, "violations": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i05_violation_triage {
    r := p52.decide with input as p52_input("sum_invariants", {
        "sum_invariants": {"checks_run": 200, "violations": 3},
    })
    r.decision_mode == "TRIAGE"
    r.violations == 3
}

test_p52_i05_insufficient_checks_triage {
    r := p52.decide with input as p52_input("sum_invariants", {
        "sum_invariants": {"checks_run": 10, "violations": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i05_invariants_bypass_blocks {
    r := p52.decide with input as p52_input("sum_invariants", {
        "sum_invariants": {"checks_run": 200, "violations": 0},
        "invariants_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I06: determinism hash (dryf = BLOCKER)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i06_deterministic_with_hash_autos {
    r := p52.decide with input as p52_input("determinism_hash", {
        "determinism_hash": {"trials": 50, "determinism_failures": 0,
                             "tools_with_hash": 2},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i06_determinism_drift_blocks {
    # dwa wyniki na ten sam input = deklaracja niereprodukowalna = BLOCKER
    r := p52.decide with input as p52_input("determinism_hash", {
        "determinism_hash": {"trials": 50, "determinism_failures": 1,
                             "tools_with_hash": 2},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.determinism_failures == 1
}

test_p52_i06_no_hash_tools_triage {
    r := p52.decide with input as p52_input("determinism_hash", {
        "determinism_hash": {"trials": 50, "determinism_failures": 0,
                             "tools_with_hash": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i06_determinism_bypass_blocks {
    r := p52.decide with input as p52_input("determinism_hash", {
        "determinism_hash": {"trials": 50, "determinism_failures": 0,
                             "tools_with_hash": 2},
        "determinism_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I07: rounding interactions (drifts_max=0)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i07_no_drifts_autos {
    r := p52.decide with input as p52_input("rounding_interactions", {
        "rounding_interactions": {"trials": 100, "path_drifts": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i07_drifts_triage {
    r := p52.decide with input as p52_input("rounding_interactions", {
        "rounding_interactions": {"trials": 100, "path_drifts": 64},
    })
    r.decision_mode == "TRIAGE"
    r.path_drifts == 64
    r.drifts_max == 0
}

test_p52_i07_zero_trials_triage {
    r := p52.decide with input as p52_input("rounding_interactions", {
        "rounding_interactions": {"trials": 0, "path_drifts": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i07_rounding_bypass_blocks {
    r := p52.decide with input as p52_input("rounding_interactions", {
        "rounding_interactions": {"trials": 100, "path_drifts": 0},
        "rounding_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I08: negative amount paths (symetria half-up)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i08_symmetric_negatives_autos {
    r := p52.decide with input as p52_input("negative_paths", {
        "negative_paths": {"cases_total": 10,
                           "naive_vs_symmetric_mismatch": 0,
                           "tools_with_negative_paths": 9,
                           "tools_total": 9},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i08_mismatch_triage {
    r := p52.decide with input as p52_input("negative_paths", {
        "negative_paths": {"cases_total": 10,
                           "naive_vs_symmetric_mismatch": 2,
                           "tools_with_negative_paths": 9,
                           "tools_total": 9},
    })
    r.decision_mode == "TRIAGE"
    r.naive_vs_symmetric_mismatch == 2
}

test_p52_i08_tools_without_negative_paths_triage {
    r := p52.decide with input as p52_input("negative_paths", {
        "negative_paths": {"cases_total": 10,
                           "naive_vs_symmetric_mismatch": 0,
                           "tools_with_negative_paths": 3,
                           "tools_total": 9},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i08_zero_cases_triage {
    r := p52.decide with input as p52_input("negative_paths", {
        "negative_paths": {"cases_total": 0,
                           "naive_vs_symmetric_mismatch": 0,
                           "tools_with_negative_paths": 9,
                           "tools_total": 9},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i08_negative_bypass_blocks {
    r := p52.decide with input as p52_input("negative_paths", {
        "negative_paths": {"cases_total": 10,
                           "naive_vs_symmetric_mismatch": 0,
                           "tools_with_negative_paths": 9,
                           "tools_total": 9},
        "negative_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I09: threshold calendar audit (annual_min=3)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i09_annual_audit_ok_autos {
    r := p52.decide with input as p52_input("threshold_calendar", {
        "threshold_calendar": {"thresholds_params_total": 8,
                               "calendar_candidates": 2,
                               "annual_rules_detected": 20},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i09_few_annual_rules_triage {
    r := p52.decide with input as p52_input("threshold_calendar", {
        "threshold_calendar": {"thresholds_params_total": 8,
                               "calendar_candidates": 2,
                               "annual_rules_detected": 1},
    })
    r.decision_mode == "TRIAGE"
    r.annual_min == 3
}

test_p52_i09_zero_params_triage {
    r := p52.decide with input as p52_input("threshold_calendar", {
        "threshold_calendar": {"thresholds_params_total": 0,
                               "calendar_candidates": 0,
                               "annual_rules_detected": 20},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i09_calendar_bypass_blocks {
    r := p52.decide with input as p52_input("threshold_calendar", {
        "threshold_calendar": {"thresholds_params_total": 8,
                               "calendar_candidates": 2,
                               "annual_rules_detected": 20},
        "calendar_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I10: drift telemetry (target=0)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i10_zero_drift_autos {
    r := p52.decide with input as p52_input("drift_telemetry", {
        "drift_telemetry": {"penny_drift_total": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.penny_drift_total == 0
}

test_p52_i10_drift_over_target_triage {
    r := p52.decide with input as p52_input("drift_telemetry", {
        "drift_telemetry": {"penny_drift_total": 64},
    })
    r.decision_mode == "TRIAGE"
    r.penny_drift_total == 64
    r.target == 0
}

test_p52_i10_unknown_drift_triage {
    # brak pomiaru (drift<0) = TRIAGE, nie AUTO
    r := p52.decide with input as p52_input("drift_telemetry", {
        "drift_telemetry": {"penny_drift_total": -1},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i10_drift_bypass_blocks {
    r := p52.decide with input as p52_input("drift_telemetry", {
        "drift_telemetry": {"penny_drift_total": 0},
        "drift_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I11: currency fuzz (trials_min=100)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i11_fuzz_clean_autos {
    r := p52.decide with input as p52_input("currency_fuzz", {
        "currency_fuzz": {"trials": 300, "violations": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i11_fuzz_violations_triage {
    r := p52.decide with input as p52_input("currency_fuzz", {
        "currency_fuzz": {"trials": 300, "violations": 2},
    })
    r.decision_mode == "TRIAGE"
    r.violations == 2
}

test_p52_i11_insufficient_trials_triage {
    r := p52.decide with input as p52_input("currency_fuzz", {
        "currency_fuzz": {"trials": 50, "violations": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i11_fuzz_bypass_blocks {
    r := p52.decide with input as p52_input("currency_fuzz", {
        "currency_fuzz": {"trials": 300, "violations": 0},
        "fuzz_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I12: doomsday suite (failures lub missing div-zero path = BLOCK)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_i12_doomsday_clean_autos {
    r := p52.decide with input as p52_input("doomsday", {
        "doomsday": {"cases_total": 6, "failures": 0,
                     "div_zero_path": "NEEDS_ADVICE"},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p52_i12_arithmetic_failure_blocks {
    # silnik wysypał się na arytmetyce = BLOCK (nigdy cichy AUTO_POST)
    r := p52.decide with input as p52_input("doomsday", {
        "doomsday": {"cases_total": 6, "failures": 1,
                     "div_zero_path": "NEEDS_ADVICE"},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.failures == 1
}

test_p52_i12_missing_div_zero_path_blocks {
    r := p52.decide with input as p52_input("doomsday", {
        "doomsday": {"cases_total": 6, "failures": 0,
                     "div_zero_path": "MISSING"},
    })
    r.decision_mode == "BLOCK"
}

test_p52_i12_zero_cases_triage {
    r := p52.decide with input as p52_input("doomsday", {
        "doomsday": {"cases_total": 0, "failures": 0,
                     "div_zero_path": "NEEDS_ADVICE"},
    })
    r.decision_mode == "TRIAGE"
}

test_p52_i12_doomsday_bypass_blocks {
    r := p52.decide with input as p52_input("doomsday", {
        "doomsday": {"cases_total": 6, "failures": 0,
                     "div_zero_path": "NEEDS_ADVICE"},
        "doomsday_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Spójność kontraktu: wersje snapshotu w certyfikacie (F4)
# ═══════════════════════════════════════════════════════════════════════════════
test_p52_certificate_carries_threshold_version {
    r := p52.decide with input as p52_input("standards_register", {
        "standards_register": {"tools_total": 9, "tools_noncompliant": 0},
    })
    r.threshold_version == "penny-v3p52-2026.09"
    r.legal_basis_version == "lb-penny-v3p52-2026.09"
    r.valid_from == "2026-01-01"
}

test_p52_decide_is_deterministic {
    a := p52.decide with input as p52_input("drift_telemetry", {
        "drift_telemetry": {"penny_drift_total": 5},
    })
    b := p52.decide with input as p52_input("drift_telemetry", {
        "drift_telemetry": {"penny_drift_total": 5},
    })
    a == b
}

test_p52_no_silent_auto_post_with_open_findings {
    # symetria dowodu: jakiekolwiek otwarte naruszenie arytmetyczne →
    # nigdy AUTO_POST (fail-closed precyzji finansowej)
    r := p52.decide with input as p52_input("drift_telemetry", {
        "drift_telemetry": {"penny_drift_total": 1},
    })
    r.decision_mode != "AUTO_POST"
}
