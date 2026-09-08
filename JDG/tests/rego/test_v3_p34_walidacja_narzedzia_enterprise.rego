# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P34 WALIDACJA NARZĘDZI (jdg.v3_p34_walidacja_narzedzia)
# — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice progów
# (fuzz min inputs, mirror unchecked, doc unanchored, heatmap stale/drop).
# Uruchomienie (z katalogu repo):
#   ./bin/opa test JDG/tests/rego/test_v3_p34_walidacja_narzedzia_enterprise.rego \
#       JDG/rules/v3_p34_walidacja_narzedzia_enterprise.rego \
#       JDG/rules/thresholds_jdg.rego
#   ./bin/opa19 test --v0-compatible <te same pliki>
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p34

import future.keywords.in

import data.jdg.v3_p34_walidacja_narzedzia

_base := {"jdg_entrepreneur": {"v3_p34_check": true}}

_cases := {
    # I01: validation DAG (L1-L5)
    "dg_no_order": {"analysis": "validation_dag",
                    "validation_dag": {"failed_levels": ["L3_tests"], "levels_order": []}},
    "dg_wrong_start": {"analysis": "validation_dag",
                       "validation_dag": {"failed_levels": ["L1_syntax"],
                                          "levels_order": ["L2_lint", "L3_tests"]}},
    "dg_failed": {"analysis": "validation_dag",
                  "validation_dag": {"failed_levels": ["L4_semantic"],
                                     "levels_order": ["L1_syntax", "L2_lint", "L3_tests"]}},
    "dg_incomplete": {"analysis": "validation_dag",
                      "validation_dag": {"failed_levels": [],
                                         "levels_order": ["L1_syntax"]}},
    "dg_ok": {"analysis": "validation_dag",
              "validation_dag": {"failed_levels": [],
                                 "levels_order": ["L1_syntax", "L2_lint", "L3_tests",
                                                  "L4_semantic", "L5_legal"]}},

    # I02: semantic diff
    "sd_no_smt": {"analysis": "semantic_diff",
                  "semantic_change_without_smt": true,
                  "semantic_diff": {"unclassified_changes": 0, "semantic_changes": 0}},
    "sd_unclassified": {"analysis": "semantic_diff",
                        "semantic_diff": {"unclassified_changes": 2, "semantic_changes": 0}},
    "sd_semantic": {"analysis": "semantic_diff",
                    "semantic_diff": {"unclassified_changes": 0, "semantic_changes": 1}},
    "sd_ok": {"analysis": "semantic_diff",
              "semantic_diff": {"unclassified_changes": 0, "semantic_changes": 0}},

    # I03: legal basis linter
    "lb_unverified": {"analysis": "legal_basis_linter",
                      "legal_basis_linter": {"unverified_basis": 1, "drift_detected": 0,
                                             "verified_basis": 5}},
    "lb_drift": {"analysis": "legal_basis_linter",
                 "legal_basis_linter": {"unverified_basis": 0, "drift_detected": 2,
                                        "verified_basis": 8}},
    "lb_ok": {"analysis": "legal_basis_linter",
              "legal_basis_linter": {"unverified_basis": 0, "drift_detected": 0,
                                     "verified_basis": 12}},

    # I04: tautology fuzzing
    "tf_found": {"analysis": "tautology_fuzzing",
                 "tautology_fuzzing": {"tautologies_found": 1, "inputs_generated": 5000}},
    "tf_too_few": {"analysis": "tautology_fuzzing",
                   "tautology_fuzzing": {"tautologies_found": 0, "inputs_generated": 500}},
    "tf_not_run": {"analysis": "tautology_fuzzing",
                   "fuzzing_scheduled": true,
                   "tautology_fuzzing": {"tautologies_found": 0, "inputs_generated": 0}},
    "tf_ok": {"analysis": "tautology_fuzzing",
              "tautology_fuzzing": {"tautologies_found": 0, "inputs_generated": 5000}},

    # I05: cross-write detector
    "cw_no_precedence": {"analysis": "cross_write_detector",
                         "cross_write_detector": {"cross_write_conflicts": 2,
                                                  "conflicts_without_precedence": 1}},
    "cw_with_precedence": {"analysis": "cross_write_detector",
                           "cross_write_detector": {"cross_write_conflicts": 1,
                                                    "conflicts_without_precedence": 0}},
    "cw_ok": {"analysis": "cross_write_detector",
              "cross_write_detector": {"cross_write_conflicts": 0,
                                       "conflicts_without_precedence": 0}},

    # I06: mirror semantic parity
    "mp_blocking": {"analysis": "mirror_semantic_parity",
                    "mirror_divergence_blocking": true,
                    "mirror_semantic_parity": {"divergent_rules": 0, "unchecked_rules": 0,
                                               "checked_rules": 10}},
    "mp_divergent": {"analysis": "mirror_semantic_parity",
                     "mirror_semantic_parity": {"divergent_rules": 2, "unchecked_rules": 0,
                                                "checked_rules": 20}},
    "mp_unchecked": {"analysis": "mirror_semantic_parity",
                     "mirror_semantic_parity": {"divergent_rules": 0, "unchecked_rules": 3,
                                                "checked_rules": 10}},
    "mp_ok": {"analysis": "mirror_semantic_parity",
              "mirror_semantic_parity": {"divergent_rules": 0, "unchecked_rules": 0,
                                         "checked_rules": 30}},

    # I07: doc-numbers invariant
    "dn_forged": {"analysis": "doc_numbers_invariant",
                  "doc_numbers_forged": true,
                  "doc_numbers_invariant": {"anchored_numbers": 5, "unanchored_numbers": 0}},
    "dn_declarations": {"analysis": "doc_numbers_invariant",
                        "doc_numbers_invariant": {"anchored_numbers": 5, "unanchored_numbers": 2}},
    "dn_ok": {"analysis": "doc_numbers_invariant",
              "doc_numbers_invariant": {"anchored_numbers": 15, "unanchored_numbers": 0}},

    # I08: auto-fix z 4-eyes
    "af_merged": {"analysis": "auto_fix_four_eyes",
                  "auto_fix_four_eyes": {"fixes_proposed": 3, "auto_merged_fixes": 1,
                                         "fixes_without_review": 0}},
    "af_unreviewed": {"analysis": "auto_fix_four_eyes",
                      "auto_fix_four_eyes": {"fixes_proposed": 3, "auto_merged_fixes": 0,
                                             "fixes_without_review": 2}},
    "af_ok": {"analysis": "auto_fix_four_eyes",
              "auto_fix_four_eyes": {"fixes_proposed": 3, "auto_merged_fixes": 0,
                                     "fixes_without_review": 0}},

    # I09: validation as a service
    "vs_unaudited": {"analysis": "validation_as_service",
                     "validation_as_service": {"ad_hoc_runs": 4, "runs_without_audit": 1}},
    "vs_idle": {"analysis": "validation_as_service",
                "service_deployed": true,
                "validation_as_service": {"ad_hoc_runs": 0, "runs_without_audit": 0}},
    "vs_ok": {"analysis": "validation_as_service",
              "validation_as_service": {"ad_hoc_runs": 7, "runs_without_audit": 0}},

    # I10: coverage heatmap ciągła
    "ch_critical_drop": {"analysis": "coverage_heatmap_continuous",
                         "coverage_heatmap_continuous": {"coverage_drop_points": 6,
                                                         "stale_days": 0}},
    "ch_drop": {"analysis": "coverage_heatmap_continuous",
                "coverage_heatmap_continuous": {"coverage_drop_points": 2, "stale_days": 0}},
    "ch_stale": {"analysis": "coverage_heatmap_continuous",
                 "coverage_heatmap_continuous": {"coverage_drop_points": 0, "stale_days": 3}},
    "ch_ok": {"analysis": "coverage_heatmap_continuous",
              "coverage_heatmap_continuous": {"coverage_drop_points": 0, "stale_days": 0}},

    # I11: validation snapshot
    "vn_missing": {"analysis": "validation_snapshot",
                   "validation_snapshot": {"decisions_without_validation_id": 3}},
    "vn_ok": {"analysis": "validation_snapshot",
              "validation_snapshot": {"decisions_without_validation_id": 0}},

    # I12: rejestr wyjątków
    "ex_expired": {"analysis": "exception_register",
                   "exception_register": {"exceptions_without_expiry": 0,
                                          "exceptions_without_owner": 0,
                                          "expired_exceptions": 2}},
    "ex_no_expiry": {"analysis": "exception_register",
                     "exception_register": {"exceptions_without_expiry": 1,
                                            "exceptions_without_owner": 0,
                                            "expired_exceptions": 0}},
    "ex_no_owner": {"analysis": "exception_register",
                    "exception_register": {"exceptions_without_expiry": 0,
                                           "exceptions_without_owner": 1,
                                           "expired_exceptions": 0}},
    "ex_ok": {"analysis": "exception_register",
              "exception_register": {"exceptions_without_expiry": 0,
                                     "exceptions_without_owner": 0,
                                     "expired_exceptions": 0,
                                     "active_exceptions": 4}},
}

_decide(case) = d {
    d := v3_p34_walidacja_narzedzia.decide with input as object.union(_base, {"v3_p34": _cases[case]})
}

# ── Oczekiwane routingi (fail-closed: BLOCK > TRIAGE > SUGGEST) ───────────────
expected := {
    "dg_no_order": "BLOCK_AND_ALERT", "dg_wrong_start": "BLOCK_AND_ALERT",
    "dg_failed": "TRIAGE_QUEUE", "dg_incomplete": "TRIAGE_QUEUE", "dg_ok": "SUGGEST",
    "sd_no_smt": "BLOCK_AND_ALERT", "sd_unclassified": "TRIAGE_QUEUE",
    "sd_semantic": "TRIAGE_QUEUE", "sd_ok": "SUGGEST",
    "lb_unverified": "BLOCK_AND_ALERT", "lb_drift": "TRIAGE_QUEUE", "lb_ok": "SUGGEST",
    "tf_found": "BLOCK_AND_ALERT", "tf_too_few": "TRIAGE_QUEUE",
    "tf_not_run": "TRIAGE_QUEUE", "tf_ok": "SUGGEST",
    "cw_no_precedence": "BLOCK_AND_ALERT", "cw_with_precedence": "TRIAGE_QUEUE",
    "cw_ok": "SUGGEST",
    "mp_blocking": "BLOCK_AND_ALERT", "mp_divergent": "TRIAGE_QUEUE",
    "mp_unchecked": "TRIAGE_QUEUE", "mp_ok": "SUGGEST",
    "dn_forged": "BLOCK_AND_ALERT", "dn_declarations": "TRIAGE_QUEUE", "dn_ok": "SUGGEST",
    "af_merged": "BLOCK_AND_ALERT", "af_unreviewed": "TRIAGE_QUEUE", "af_ok": "SUGGEST",
    "vs_unaudited": "BLOCK_AND_ALERT", "vs_idle": "TRIAGE_QUEUE", "vs_ok": "SUGGEST",
    "ch_critical_drop": "BLOCK_AND_ALERT", "ch_drop": "TRIAGE_QUEUE",
    "ch_stale": "TRIAGE_QUEUE", "ch_ok": "SUGGEST",
    "vn_missing": "BLOCK_AND_ALERT", "vn_ok": "SUGGEST",
    "ex_expired": "BLOCK_AND_ALERT", "ex_no_expiry": "BLOCK_AND_ALERT",
    "ex_no_owner": "TRIAGE_QUEUE", "ex_ok": "SUGGEST",
}

# ── Główna asercja: routing każdej ścieżki zgodny z oczekiwanym ───────────────
_routing_violations := {name |
    some name in object.keys(expected)
    expected[name] != _decide(name)._routing
}

test_p34_routing_matrix {
    count(_routing_violations) == 0
}

# ── I01: DAG — pierwszy zepsuty poziom = BLOCK (czym wcześniej przerwać PR) ───
test_p34_i01_broken_order_block {
    d := _decide("dg_wrong_start")
    d.rule_id == "jdg.v3_p34_walidacja_narzedzia.validation_dag"
    d._routing == "BLOCK_AND_ALERT"
}

test_p34_i01_ok_suggest {
    d := _decide("dg_ok")
    d._routing == "SUGGEST"
    d.levels_order == 5
}

# ── I02: zmiana semantyczna bez SMT = BLOCK ───────────────────────────────────
test_p34_i02_no_smt_block {
    d := _decide("sd_no_smt")
    d._routing == "BLOCK_AND_ALERT"
}

# ── I03: podstawa prawna bez weryfikacji na PR = BLOCK ────────────────────────
test_p34_i03_unverified_block {
    d := _decide("lb_unverified")
    d.unverified_basis == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I04: tautologia = BLOCK (AP01); granica min inputów ───────────────────────
test_p34_i04_tautology_block {
    d := _decide("tf_found")
    d.tautologies_found == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p34_i04_min_inputs_boundary {
    d := _decide("tf_too_few")
    d._routing == "TRIAGE_QUEUE"
    d.min_inputs == 1000
    d.inputs_generated == 500
}

# ── I05: konflikt zapisu bez precedence = BLOCK (AP08) ────────────────────────
test_p34_i05_no_precedence_block {
    d := _decide("cw_no_precedence")
    d.conflicts_without_precedence == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I06: mirror parity — dryf = TRIAGE, blocking flag = BLOCK (AP11) ──────────
test_p34_i06_divergent_triage {
    d := _decide("mp_divergent")
    d.divergent_rules == 2
    d._routing == "TRIAGE_QUEUE"
}

test_p34_i06_blocking_flag_block {
    d := _decide("mp_blocking")
    d._routing == "BLOCK_AND_ALERT"
}

# ── I07: sfabrykowane liczby = BLOCK; [DEKLARACJA] ponad limit = TRIAGE ───────
test_p34_i07_forged_block {
    d := _decide("dn_forged")
    d._routing == "BLOCK_AND_ALERT"
}

test_p34_i07_declarations_triage {
    d := _decide("dn_declarations")
    d.unanchored_numbers == 2
    d._routing == "TRIAGE_QUEUE"
}

# ── I08: auto-merge poprawki = BLOCK (4-eyes) ─────────────────────────────────
test_p34_i08_auto_merge_block {
    d := _decide("af_merged")
    d.auto_merged_fixes == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I09: run walidacji bez audytu = BLOCK ─────────────────────────────────────
test_p34_i09_unaudited_block {
    d := _decide("vs_unaudited")
    d.runs_without_audit == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I10: heatmapa — granica spadku 5/6 i niemłodość ───────────────────────────
test_p34_i10_critical_drop_block {
    d := _decide("ch_critical_drop")
    d.coverage_drop_points == 6
    d._routing == "BLOCK_AND_ALERT"
}

test_p34_i10_drop_triage {
    d := _decide("ch_drop")
    d._routing == "TRIAGE_QUEUE"
}

test_p34_i10_stale_triage {
    d := _decide("ch_stale")
    d.stale_days == 3
    d.max_stale_days == 1
    d._routing == "TRIAGE_QUEUE"
}

# ── I11: decyzja bez ID walidacji = BLOCK (provenance) ────────────────────────
test_p34_i11_missing_id_block {
    d := _decide("vn_missing")
    d.decisions_without_validation_id == 3
    d._routing == "BLOCK_AND_ALERT"
}

# ── I12: wyjątki — wygasły/bez expiry = BLOCK, bez ownera = TRIAGE ────────────
test_p34_i12_expired_block {
    d := _decide("ex_expired")
    d.expired_exceptions == 2
    d._routing == "BLOCK_AND_ALERT"
}

test_p34_i12_no_expiry_block {
    d := _decide("ex_no_expiry")
    d._routing == "BLOCK_AND_ALERT"
}

test_p34_i12_no_owner_triage {
    d := _decide("ex_no_owner")
    d._routing == "TRIAGE_QUEUE"
}

# ── Certyfikat werdyktu zgodny z kontraktem P03 ────────────────────────────────
test_p34_certificate_fields {
    d := _decide("dg_ok")
    d.matched == true
    d["package"] == "jdg.v3_p34_walidacja_narzedzia"
    d.priority == 434001
    d.threshold_version == "walidacja-v3p34-2026.09"
    d.legal_basis_version == "walidacja-legal-2026.09"
    d.valid_from == "2026-01-01"
}

# ── Brak aktywacji: no_match ──────────────────────────────────────────────────
test_p34_no_match_without_flag {
    d := v3_p34_walidacja_narzedzia.decide with input as {"v3_p34": _cases["dg_ok"]}
    d.matched == false
    d.rule_id == "jdg.v3_p34_walidacja_narzedzia.no_match"
}

# ── Fail-closed: brak snapshotu progów = BLOCK ────────────────────────────────
test_p34_fail_closed_no_snapshot {
    d := v3_p34_walidacja_narzedzia.decide with input as object.union(_base, {"v3_p34": _cases["dg_ok"]}) with data.jdg.thresholds.v3_p34 as {}
    d.rule_id == "jdg.v3_p34_walidacja_narzedzia.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}

# ── Parametry jako dane (ADR-002) ─────────────────────────────────────────────
test_p34_thresholds_snapshot_complete {
    s := data.jdg.thresholds.v3_p34
    count(s.v3_p34_dag_levels) == 5
    s.v3_p34_dag_levels[0] == "L1_syntax"
    s.v3_p34_dag_levels[4] == "L5_legal"
    s.v3_p34_fuzz_min_inputs == 1000
    s.v3_p34_mirror_unchecked_max == 0
    s.v3_p34_doc_unanchored_max == 0
    s.v3_p34_heatmap_max_stale_days == 1
    s.v3_p34_coverage_drop_block == 5
    s.v3_p34_threshold_version == "walidacja-v3p34-2026.09"
    s.valid_from == "2026-01-01"
}

# ── Audytowalność: reason i legal_basis w każdej decyzji; priorytety unikalne ─
_reason_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._routing_reason) <= 10
}

test_p34_routing_reasons_present {
    count(_reason_violations) == 0
}

_basis_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._legal_basis) == 0
}

test_p34_legal_basis_in_all_decisions {
    count(_basis_violations) == 0
}

_priority_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    d.priority != 434001
    d.priority != 434002
    d.priority != 434003
    d.priority != 434004
    d.priority != 434005
    d.priority != 434006
    d.priority != 434007
    d.priority != 434008
    d.priority != 434009
    d.priority != 434010
    d.priority != 434011
    d.priority != 434012
}

test_p34_unique_priorities {
    count(_priority_violations) == 0
}
