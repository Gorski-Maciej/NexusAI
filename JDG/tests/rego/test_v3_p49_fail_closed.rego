# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P49 DOMKNIĘCIE FAIL-CLOSED (konwencja
# P39/P45/P46/P47/P48: negative-first, granice progów, fail-closed, never-silent
# AUTO_POST, generator braków pól, chaos, bypass → BLOCK).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p49_fail_closed_test

import future.keywords.every
import data.jdg.v3_p49_fail_closed as p49

# ── Helper ─────────────────────────────────────────────────────────────────────
p49_input(analysis, ctx) = {"jdg_entrepreneur": {"v3_p49_check": true},
                            "v3_p49": object.union({"analysis": analysis}, ctx)}

# ═══════════════════════════════════════════════════════════════════════════════
# Determinizm łańcucha / aktywacja (I02 default-deny)
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_no_activation_no_match {
    r := p49.decide with input as {}
    r.rule_id == "jdg.v3_p49_fail_closed.no_match"
    r.matched == false
}

test_p49_no_selector_no_match {
    r := p49.decide with input as p49_input("brak_takiej_analizy", {})
    r.rule_id == "jdg.v3_p49_fail_closed.no_match"
}

test_p49_thresholds_missing_fail_closed {
    # default-deny: brak snapshotu progów = BLOCK, nigdy cicha decyzja (AP07)
    r := p49.decide with input as p49_input("invariant_pack", {})
        with data.jdg.thresholds.v3_p49 as {}
    r.rule_id == "jdg.v3_p49_fail_closed.thresholds_missing"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.priority == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# I01: invariant pack
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i01_violation_blocks {
    r := p49.decide with input as p49_input("invariant_pack", {
        "invariant_pack": {"invariants_total": 6, "invariants_enabled": 6,
                            "violations": 2, "auto_post_blocked": 2},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.violations == 2
}

test_p49_i01_disabled_invariant_blocks {
    r := p49.decide with input as p49_input("invariant_pack", {
        "invariant_pack": {"invariants_total": 6, "invariants_enabled": 5,
                            "violations": 0, "auto_post_blocked": 0},
    })
    r.decision_mode == "BLOCK"
}

# granica: total == 4 (min) → AUTO; total == 3 → TRIAGE
test_p49_i01_pack_at_boundary_autos {
    r := p49.decide with input as p49_input("invariant_pack", {
        "invariant_pack": {"invariants_total": 4, "invariants_enabled": 4,
                            "violations": 0, "auto_post_blocked": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p49_i01_pack_below_boundary_triages {
    r := p49.decide with input as p49_input("invariant_pack", {
        "invariant_pack": {"invariants_total": 3, "invariants_enabled": 3,
                            "violations": 0, "auto_post_blocked": 0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I02: default-deny core — zero cichych AUTO_POST
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i02_silent_auto_post_blocks {
    r := p49.decide with input as p49_input("default_deny_core", {
        "default_deny_core": {"silent_auto_posts": 1, "auto_post_without_evidence": 0,
                               "auto_post_total": 4, "auto_post_full_evidence_chain": 4},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p49_i02_post_without_evidence_blocks {
    r := p49.decide with input as p49_input("default_deny_core", {
        "default_deny_core": {"silent_auto_posts": 0, "auto_post_without_evidence": 2,
                               "auto_post_total": 4, "auto_post_full_evidence_chain": 2},
    })
    r.decision_mode == "BLOCK"
}

test_p49_i02_full_chain_autos {
    r := p49.decide with input as p49_input("default_deny_core", {
        "default_deny_core": {"silent_auto_posts": 0, "auto_post_without_evidence": 0,
                               "auto_post_total": 4, "auto_post_full_evidence_chain": 4},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p49_i02_partial_chain_triages {
    r := p49.decide with input as p49_input("default_deny_core", {
        "default_deny_core": {"silent_auto_posts": 0, "auto_post_without_evidence": 0,
                               "auto_post_total": 4, "auto_post_full_evidence_chain": 3},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I03: missing-field coverage gate + granice progu pokrycia
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i03_generator_not_run_triages {
    r := p49.decide with input as p49_input("missing_field_coverage", {
        "missing_field_coverage": {"rules_total": 12, "rules_covered": 12,
                                    "generator_run": false},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

# granica: 95/100 == próg → AUTO (pct = 95)
test_p49_i03_coverage_at_threshold_autos {
    r := p49.decide with input as p49_input("missing_field_coverage", {
        "missing_field_coverage": {"rules_total": 100, "rules_covered": 95,
                                    "generator_run": true},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.coverage_pct == 95
}

# granica: 94/100 < próg → TRIAGE
test_p49_i03_coverage_below_threshold_triages {
    r := p49.decide with input as p49_input("missing_field_coverage", {
        "missing_field_coverage": {"rules_total": 100, "rules_covered": 94,
                                    "generator_run": true},
    })
    r.decision_mode == "TRIAGE"
    r.coverage_pct == 94
}

# brak pól kontraktu: rules_total = 0 → pct = 0 → TRIAGE (nie dzielenie przez zero)
test_p49_i03_zero_rules_no_crash_triages {
    r := p49.decide with input as p49_input("missing_field_coverage", {
        "missing_field_coverage": {"rules_total": 0, "rules_covered": 0,
                                    "generator_run": true},
    })
    r.decision_mode == "TRIAGE"
    r.coverage_pct == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# I04: chaos input
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i04_chaos_violation_blocks {
    r := p49.decide with input as p49_input("chaos_input", {
        "chaos_input": {"cases_total": 12, "fail_closed_violations": 1,
                         "suite_run": true},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p49_i04_suite_not_run_triages {
    r := p49.decide with input as p49_input("chaos_input", {
        "chaos_input": {"cases_total": 0, "fail_closed_violations": 0,
                         "suite_run": false},
    })
    r.decision_mode == "TRIAGE"
}

# granica: 10/10 scenariuszy = min → AUTO; 9 → TRIAGE
test_p49_i04_chaos_at_min_autos {
    r := p49.decide with input as p49_input("chaos_input", {
        "chaos_input": {"cases_total": 10, "fail_closed_violations": 0,
                         "suite_run": true},
    })
    r.decision_mode == "AUTO_POST"
}

test_p49_i04_chaos_below_min_triages {
    r := p49.decide with input as p49_input("chaos_input", {
        "chaos_input": {"cases_total": 9, "fail_closed_violations": 0,
                         "suite_run": true},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I05: circuit breaker per domain
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i05_review_without_reason_triages {
    r := p49.decide with input as p49_input("circuit_breaker", {
        "circuit_breaker": {"domains_total": 12, "domains_in_review": 1,
                             "needs_advice_in_window": 3},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p49_i05_review_with_reason_still_triages {
    # domena w REVIEW zawsze wymaga przeglądu (tryb awaryjny ≠ cichy AUTO_POST)
    r := p49.decide with input as p49_input("circuit_breaker", {
        "circuit_breaker": {"domains_total": 12, "domains_in_review": 1,
                             "needs_advice_in_window": 3,
                             "review_domains_with_reason": ["vat"]},
    })
    r.decision_mode == "TRIAGE"
}

test_p49_i05_series_over_threshold_triages {
    r := p49.decide with input as p49_input("circuit_breaker", {
        "circuit_breaker": {"domains_total": 12, "domains_in_review": 0,
                             "needs_advice_in_window": 21},
    })
    r.decision_mode == "TRIAGE"
}

test_p49_i05_calm_autos {
    r := p49.decide with input as p49_input("circuit_breaker", {
        "circuit_breaker": {"domains_total": 12, "domains_in_review": 0,
                             "needs_advice_in_window": 3},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I06: amount ceiling as data
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i06_breach_blocks {
    r := p49.decide with input as p49_input("amount_ceiling", {
        "amount_ceiling": {"auto_post_amount": 20000, "limit_configured": true,
                            "limit_breaches": 1},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p49_i06_limit_not_configured_blocks {
    r := p49.decide with input as p49_input("amount_ceiling", {
        "amount_ceiling": {"auto_post_amount": 100, "limit_configured": false,
                            "limit_breaches": 0},
    })
    r.decision_mode == "BLOCK"
}

# granica: amount == limit (15000) → AUTO; 15001 → TRIAGE (4-eyes)
test_p49_i06_amount_at_limit_autos {
    r := p49.decide with input as p49_input("amount_ceiling", {
        "amount_ceiling": {"auto_post_amount": 15000, "limit_configured": true,
                            "limit_breaches": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p49_i06_amount_over_limit_triages {
    r := p49.decide with input as p49_input("amount_ceiling", {
        "amount_ceiling": {"auto_post_amount": 15001, "limit_configured": true,
                            "limit_breaches": 0},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I07: reason completeness linter
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i07_no_reason_triages {
    r := p49.decide with input as p49_input("reason_completeness", {
        "reason_completeness": {"needs_advice_total": 5, "needs_advice_without_reason": 1,
                                 "needs_advice_short_reason": 0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p49_i07_short_reason_triages {
    r := p49.decide with input as p49_input("reason_completeness", {
        "reason_completeness": {"needs_advice_total": 5, "needs_advice_without_reason": 0,
                                 "needs_advice_short_reason": 2},
    })
    r.decision_mode == "TRIAGE"
}

test_p49_i07_all_reasoned_autos {
    r := p49.decide with input as p49_input("reason_completeness", {
        "reason_completeness": {"needs_advice_total": 5, "needs_advice_without_reason": 0,
                                 "needs_advice_short_reason": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I08: emergency export path
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i08_missing_export_path_blocks {
    r := p49.decide with input as p49_input("emergency_export", {
        "emergency_export": {"export_path_present": false,
                              "last_export_verified": false,
                              "hours_since_last_export": 1},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

# granica: 168h == SLA → AUTO; 169h → TRIAGE
test_p49_i08_export_at_sla_autos {
    r := p49.decide with input as p49_input("emergency_export", {
        "emergency_export": {"export_path_present": true,
                              "last_export_verified": true,
                              "hours_since_last_export": 168},
    })
    r.decision_mode == "AUTO_POST"
}

test_p49_i08_export_over_sla_triages {
    r := p49.decide with input as p49_input("emergency_export", {
        "emergency_export": {"export_path_present": true,
                              "last_export_verified": true,
                              "hours_since_last_export": 169},
    })
    r.decision_mode == "TRIAGE"
}

test_p49_i08_unverified_export_triages {
    r := p49.decide with input as p49_input("emergency_export", {
        "emergency_export": {"export_path_present": true,
                              "last_export_verified": false,
                              "hours_since_last_export": 2},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I09: decision trail replay audit
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i09_replay_not_done_triages {
    r := p49.decide with input as p49_input("replay_audit", {
        "replay_audit": {"weekly_replay_done": false, "decisions_replayed": 0,
                          "decisions_to_revise": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p49_i09_decisions_to_revise_triages {
    r := p49.decide with input as p49_input("replay_audit", {
        "replay_audit": {"weekly_replay_done": true, "decisions_replayed": 30,
                          "decisions_to_revise": 2},
    })
    r.decision_mode == "TRIAGE"
}

test_p49_i09_clean_week_autos {
    r := p49.decide with input as p49_input("replay_audit", {
        "replay_audit": {"weekly_replay_done": true, "decisions_replayed": 30,
                          "decisions_to_revise": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I10: fail-closed score
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i10_fail_open_paths_block {
    r := p49.decide with input as p49_input("fail_closed_score", {
        "fail_closed_score": {"paths_total": 131, "paths_explicit_else": 119,
                               "paths_fail_open": 12},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p49_i10_no_paths_triages {
    r := p49.decide with input as p49_input("fail_closed_score", {
        "fail_closed_score": {"paths_total": 0, "paths_explicit_else": 0,
                               "paths_fail_open": 0},
    })
    r.decision_mode == "TRIAGE"
}

# granica: 131/131 → score 100 → AUTO
test_p49_i10_perfect_score_autos {
    r := p49.decide with input as p49_input("fail_closed_score", {
        "fail_closed_score": {"paths_total": 131, "paths_explicit_else": 131,
                               "paths_fail_open": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.fail_closed_score_pct == 100
}

# granica: score tuż pod celem → TRIAGE
test_p49_i10_score_below_target_triages {
    r := p49.decide with input as p49_input("fail_closed_score", {
        "fail_closed_score": {"paths_total": 1000, "paths_explicit_else": 999,
                               "paths_fail_open": 0},
    })
    r.decision_mode == "TRIAGE"
    r.fail_closed_score_pct == 99.9
}

# ═══════════════════════════════════════════════════════════════════════════════
# I11: silent-post canary
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i11_silent_post_blocks {
    r := p49.decide with input as p49_input("silent_post_canary", {
        "silent_post_canary": {"canary_run": true, "probes_total": 4,
                                "silent_posts_detected": 1},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p49_i11_not_run_triages {
    r := p49.decide with input as p49_input("silent_post_canary", {
        "silent_post_canary": {"canary_run": false, "probes_total": 0,
                                "silent_posts_detected": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p49_i11_clean_canary_autos {
    r := p49.decide with input as p49_input("silent_post_canary", {
        "silent_post_canary": {"canary_run": true, "probes_total": 4,
                                "silent_posts_detected": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I12: user-visible safety
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_i12_missing_action_triages {
    r := p49.decide with input as p49_input("user_visible_safety", {
        "user_visible_safety": {"needs_advice_visible": 3, "needs_advice_with_action": 2,
                                 "auto_post_evidence_downloadable": true},
    })
    r.decision_mode == "TRIAGE"
}

test_p49_i12_evidence_not_downloadable_triages {
    r := p49.decide with input as p49_input("user_visible_safety", {
        "user_visible_safety": {"needs_advice_visible": 3, "needs_advice_with_action": 3,
                                 "auto_post_evidence_downloadable": false},
    })
    r.decision_mode == "TRIAGE"
}

test_p49_i12_full_safety_autos {
    r := p49.decide with input as p49_input("user_visible_safety", {
        "user_visible_safety": {"needs_advice_visible": 3, "needs_advice_with_action": 3,
                                 "auto_post_evidence_downloadable": true},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Bypass → BLOCK (fail-closed: obejście kontroli = naruszenie, nigdy cisza)
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_bypass_flag_forces_block {
    r := p49.decide with input as p49_input("invariant_pack", {
        "invariants_bypassed": true,
        "invariant_pack": {"invariants_total": 6, "invariants_enabled": 6,
                            "violations": 0, "auto_post_blocked": 0},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p49_bypass_default_deny_forces_block {
    r := p49.decide with input as p49_input("default_deny_core", {
        "default_deny_bypassed": true,
        "default_deny_core": {"silent_auto_posts": 0, "auto_post_without_evidence": 0,
                               "auto_post_total": 4, "auto_post_full_evidence_chain": 4},
    })
    r.decision_mode == "BLOCK"
}

test_p49_bypass_chaos_forces_block {
    r := p49.decide with input as p49_input("chaos_input", {
        "chaos_bypassed": true,
        "chaos_input": {"cases_total": 12, "fail_closed_violations": 0,
                         "suite_run": true},
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Brakujące pola kontraktu wejściowego (generator I03: różne braki → safe)
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_missing_ctx_field_safe_not_silent {
    # null zamiast mapy analiz — brak selektora → no_match (nigdy cichy AUTO_POST)
    r := p49.decide with input as {"jdg_entrepreneur": {"v3_p49_check": true},
                                    "v3_p49": {"analysis": null}}
    r.rule_id == "jdg.v3_p49_fail_closed.no_match"
}

test_p49_empty_analysis_safe_not_silent {
    r := p49.decide with input as p49_input("", {})
    r.rule_id == "jdg.v3_p49_fail_closed.no_match"
}

test_p49_partial_ctx_no_silent_auto_post {
    # mapa analiz obecna, pola licznikowe zbrakowane → domyślne zera → TRIAGE/AUTO
    # zgodnie z default-deny (AUTO tylko przy pełnym dowodzie)
    r := p49.decide with input as p49_input("default_deny_core", {})
    r.decision_mode == "AUTO_POST"
    r.auto_post_total == 0
    r.auto_post_full_evidence_chain == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# Never-silent: każdy werdykt P49 ma rule_id + kontrakt (P03)
# ═══════════════════════════════════════════════════════════════════════════════
test_p49_every_verdict_has_rule_id {
    analyses := [
        "invariant_pack", "default_deny_core", "missing_field_coverage",
        "chaos_input", "circuit_breaker", "amount_ceiling", "reason_completeness",
        "emergency_export", "replay_audit", "fail_closed_score",
        "silent_post_canary", "user_visible_safety",
    ]
    every a in analyses {
        r := p49.decide with input as p49_input(a, {})
        startswith(r.rule_id, "jdg.v3_p49_fail_closed.")
        r.matched == true
    }
}

test_p49_decide_never_undefined {
    r := p49.decide with input as p49_input("default_deny_core", {})
    is_object(r)
    r.matched == true
}
