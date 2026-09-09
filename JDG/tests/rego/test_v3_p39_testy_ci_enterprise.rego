# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P39 TESTY I CI (jdg.v3_p39_testy_ci) — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice progów
# (mutation 85%, act coverage 90%, benchmark 10%, impact map 7 dni).
# Uruchomienie (z katalogu repo):
#   ./bin/opa test JDG/tests/rego/test_v3_p39_testy_ci_enterprise.rego \
#       JDG/rules/v3_p39_testy_ci_enterprise.rego JDG/rules/thresholds_jdg.rego
#   ./bin/opa19 test --v0-compatible <te same pliki>
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p39

import future.keywords.in

import data.jdg.v3_p39_testy_ci

_base := {"jdg_entrepreneur": {"v3_p39_check": true}}

_cases := {
    # I01: test matrix from acts
    "tm_no_generator": {"analysis": "test_matrix",
                        "matrix_generator_missing": true,
                        "test_matrix": {"acts_without_boundary_cases": 0}},
    "tm_acts_without_cases": {"analysis": "test_matrix",
                              "test_matrix": {"acts_without_boundary_cases": 3}},
    "tm_ok": {"analysis": "test_matrix",
              "test_matrix": {"acts_without_boundary_cases": 0}},

    # I02: golden replay as PR gate
    "gr_regressions": {"analysis": "golden_replay_gate",
                       "golden_replay_gate": {"golden_regressions": 1,
                                               "golden_total": 27}},
    "gr_not_in_pr": {"analysis": "golden_replay_gate",
                     "golden_not_in_pr_gate": true,
                     "golden_replay_gate": {"golden_regressions": 0,
                                             "golden_total": 27}},
    "gr_ok": {"analysis": "golden_replay_gate",
              "golden_replay_gate": {"golden_regressions": 0,
                                      "golden_total": 27}},

    # I03: temporal pair tests
    "tp_no_generator": {"analysis": "temporal_pairs",
                        "temporal_pair_generator_missing": true,
                        "temporal_pairs": {"acts_without_temporal_pairs": 0}},
    "tp_missing": {"analysis": "temporal_pairs",
                   "temporal_pairs": {"acts_without_temporal_pairs": 2}},
    "tp_ok": {"analysis": "temporal_pairs",
              "temporal_pairs": {"acts_without_temporal_pairs": 0}},

    # I04: negative-first testing
    "nf_suites_without": {"analysis": "negative_first",
                          "negative_first": {"suites_without_negative_assertions": 1,
                                              "positive_tests_missing_negative_pair": 0}},
    "nf_missing_pairs": {"analysis": "negative_first",
                         "negative_first": {"suites_without_negative_assertions": 0,
                                             "positive_tests_missing_negative_pair": 5}},
    "nf_ok": {"analysis": "negative_first",
              "negative_first": {"suites_without_negative_assertions": 0,
                                  "positive_tests_missing_negative_pair": 0}},

    # I05: property invariants pack
    "pi_violation": {"analysis": "property_invariants",
                     "property_invariants": {"invariant_violations": 1,
                                              "cases_checked": 1000}},
    "pi_empty": {"analysis": "property_invariants",
                 "invariants_pack_empty": true,
                 "property_invariants": {"invariant_violations": 0,
                                          "cases_checked": 0}},
    "pi_ok": {"analysis": "property_invariants",
              "property_invariants": {"invariant_violations": 0,
                                       "cases_checked": 1000}},

    # I06: mutation testing rego
    "mt_low_score": {"analysis": "mutation_testing",
                     "mutation_testing": {"mutation_score_pct": 70}},
    "mt_not_run": {"analysis": "mutation_testing",
                   "mutation_testing_not_run": true,
                   "mutation_testing": {"mutation_score_pct": 100}},
    "mt_ok": {"analysis": "mutation_testing",
              "mutation_testing": {"mutation_score_pct": 90}},

    # I07: flake quarantine
    "fq_on_merge": {"analysis": "flake_quarantine",
                    "flake_quarantine": {"flaky_tests_on_merge_path": 1,
                                          "quarantined_without_deadline": 0}},
    "fq_no_deadline": {"analysis": "flake_quarantine",
                       "flake_quarantine": {"flaky_tests_on_merge_path": 0,
                                             "quarantined_without_deadline": 2}},
    "fq_ok": {"analysis": "flake_quarantine",
              "flake_quarantine": {"flaky_tests_on_merge_path": 0,
                                    "quarantined_without_deadline": 0}},

    # I08: contract version pinning
    "cv_breaking": {"analysis": "contract_pinning",
                    "contract_pinning": {"breaking_changes_without_migration_pr": 1,
                                          "contract_tests_without_pin": 0}},
    "cv_unpinned": {"analysis": "contract_pinning",
                    "contract_pinning": {"breaking_changes_without_migration_pr": 0,
                                          "contract_tests_without_pin": 3}},
    "cv_ok": {"analysis": "contract_pinning",
              "contract_pinning": {"breaking_changes_without_migration_pr": 0,
                                    "contract_tests_without_pin": 0}},

    # I09: coverage by legal act
    "ca_no_report": {"analysis": "coverage_by_act",
                     "act_coverage_report_missing": true,
                     "coverage_by_act": {"acts_below_coverage_threshold": 0}},
    "ca_below": {"analysis": "coverage_by_act",
                 "coverage_by_act": {"acts_below_coverage_threshold": 4}},
    "ca_ok": {"analysis": "coverage_by_act",
              "coverage_by_act": {"acts_below_coverage_threshold": 0}},

    # I10: performance budget CI
    "pb_regression": {"analysis": "performance_budget",
                      "performance_budget": {"benchmark_regression_pct": 15}},
    "pb_no_baseline": {"analysis": "performance_budget",
                       "benchmark_baseline_missing": true,
                       "performance_budget": {"benchmark_regression_pct": 0}},
    "pb_ok": {"analysis": "performance_budget",
              "performance_budget": {"benchmark_regression_pct": 3}},

    # I11: seed-replay determinism
    "sr_no_seed": {"analysis": "seed_replay",
                   "seed_replay": {"random_tests_without_seed": 1}},
    "sr_no_replay": {"analysis": "seed_replay",
                     "seed_replay_missing": true,
                     "seed_replay": {"random_tests_without_seed": 0}},
    "sr_ok": {"analysis": "seed_replay",
              "seed_replay": {"random_tests_without_seed": 0}},

    # I12: test impact map
    "im_missing": {"analysis": "impact_map",
                   "impact_map_missing": true,
                   "impact_map": {"map_stale_days": 0}},
    "im_stale": {"analysis": "impact_map",
                 "impact_map": {"map_stale_days": 9}},
    "im_ok": {"analysis": "impact_map",
              "impact_map": {"map_stale_days": 1}},
}

_decide(case) = d {
    d := v3_p39_testy_ci.decide with input as object.union(_base, {"v3_p39": _cases[case]})
}

# ── Oczekiwane routingi (fail-closed: BLOCK > TRIAGE > SUGGEST) ───────────────
expected := {
    "tm_no_generator": "BLOCK_AND_ALERT", "tm_acts_without_cases": "TRIAGE_QUEUE", "tm_ok": "SUGGEST",
    "gr_regressions": "BLOCK_AND_ALERT", "gr_not_in_pr": "BLOCK_AND_ALERT", "gr_ok": "SUGGEST",
    "tp_no_generator": "BLOCK_AND_ALERT", "tp_missing": "TRIAGE_QUEUE", "tp_ok": "SUGGEST",
    "nf_suites_without": "BLOCK_AND_ALERT", "nf_missing_pairs": "TRIAGE_QUEUE", "nf_ok": "SUGGEST",
    "pi_violation": "BLOCK_AND_ALERT", "pi_empty": "BLOCK_AND_ALERT", "pi_ok": "SUGGEST",
    "mt_low_score": "TRIAGE_QUEUE", "mt_not_run": "TRIAGE_QUEUE", "mt_ok": "SUGGEST",
    "fq_on_merge": "BLOCK_AND_ALERT", "fq_no_deadline": "TRIAGE_QUEUE", "fq_ok": "SUGGEST",
    "cv_breaking": "BLOCK_AND_ALERT", "cv_unpinned": "TRIAGE_QUEUE", "cv_ok": "SUGGEST",
    "ca_no_report": "BLOCK_AND_ALERT", "ca_below": "TRIAGE_QUEUE", "ca_ok": "SUGGEST",
    "pb_regression": "BLOCK_AND_ALERT", "pb_no_baseline": "BLOCK_AND_ALERT", "pb_ok": "SUGGEST",
    "sr_no_seed": "BLOCK_AND_ALERT", "sr_no_replay": "TRIAGE_QUEUE", "sr_ok": "SUGGEST",
    "im_missing": "TRIAGE_QUEUE", "im_stale": "TRIAGE_QUEUE", "im_ok": "SUGGEST",
}

# ── Główna asercja: routing każdej ścieżki zgodny z oczekiwanym ───────────────
_routing_violations := {name |
    some name in object.keys(expected)
    expected[name] != _decide(name)._routing
}

test_p39_routing_matrix {
    count(_routing_violations) == 0
}

# ── I01: brak generatora matrycy = BLOCK; akty bez granic = TRIAGE ────────────
test_p39_i01_no_generator_block {
    d := _decide("tm_no_generator")
    d.matrix_generator_missing == true
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i01_acts_without_cases_triage {
    d := _decide("tm_acts_without_cases")
    d.acts_without_boundary_cases == 3
    d._routing == "TRIAGE_QUEUE"
}

# ── I02: regresja golden = BLOCK; brak bramki PR = BLOCK ──────────────────────
test_p39_i02_regression_block {
    d := _decide("gr_regressions")
    d.golden_regressions == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i02_not_in_pr_block {
    d := _decide("gr_not_in_pr")
    d.golden_not_in_pr_gate == true
    d._routing == "BLOCK_AND_ALERT"
}

# ── I03: brak generatora par = BLOCK; akty bez par = TRIAGE ───────────────────
test_p39_i03_no_generator_block {
    d := _decide("tp_no_generator")
    d.temporal_pair_generator_missing == true
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i03_missing_pairs_triage {
    d := _decide("tp_missing")
    d.acts_without_temporal_pairs == 2
    d._routing == "TRIAGE_QUEUE"
}

# ── I04: suita bez negatywnych = BLOCK; brak par = TRIAGE ─────────────────────
test_p39_i04_suites_without_negative_block {
    d := _decide("nf_suites_without")
    d.suites_without_negative_assertions == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i04_missing_pairs_triage {
    d := _decide("nf_missing_pairs")
    d.positive_tests_missing_negative_pair == 5
    d._routing == "TRIAGE_QUEUE"
}

# ── I05: naruszenie niezmiennika = BLOCK; pusty pakiet = BLOCK ────────────────
test_p39_i05_violation_block {
    d := _decide("pi_violation")
    d.invariant_violations == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i05_empty_pack_block {
    d := _decide("pi_empty")
    d.invariants_pack_empty == true
    d._routing == "BLOCK_AND_ALERT"
}

# ── I06: czułość mutacyjna < 85% = TRIAGE; nie uruchomiony = TRIAGE ───────────
test_p39_i06_low_score_triage {
    d := _decide("mt_low_score")
    d.mutation_score_pct == 70
    d.mutation_score_min_pct == 85
    d._routing == "TRIAGE_QUEUE"
}

test_p39_i06_not_run_triage {
    d := _decide("mt_not_run")
    d.mutation_testing_not_run == true
    d._routing == "TRIAGE_QUEUE"
}

# ── I07: flak na ścieżce merge = BLOCK; kwarantanna bez terminu = TRIAGE ──────
test_p39_i07_flaky_on_merge_block {
    d := _decide("fq_on_merge")
    d.flaky_tests_on_merge_path == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i07_no_deadline_triage {
    d := _decide("fq_no_deadline")
    d.quarantined_without_deadline == 2
    d._routing == "TRIAGE_QUEUE"
}

# ── I08: breaking bez PR migracyjnego = BLOCK; brak pinu = TRIAGE ─────────────
test_p39_i08_breaking_block {
    d := _decide("cv_breaking")
    d.breaking_changes_without_migration_pr == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i08_unpinned_triage {
    d := _decide("cv_unpinned")
    d.contract_tests_without_pin == 3
    d._routing == "TRIAGE_QUEUE"
}

# ── I09: brak raportu pokrycia aktów = BLOCK; poniżej progu = TRIAGE ──────────
test_p39_i09_no_report_block {
    d := _decide("ca_no_report")
    d.act_coverage_report_missing == true
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i09_below_threshold_triage {
    d := _decide("ca_below")
    d.acts_below_coverage_threshold == 4
    d._routing == "TRIAGE_QUEUE"
}

# ── I10: regresja benchmarku > 10% = BLOCK; brak baseline = BLOCK ─────────────
test_p39_i10_regression_block {
    d := _decide("pb_regression")
    d.benchmark_regression_pct == 15
    d.benchmark_regression_max_pct == 10
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i10_no_baseline_block {
    d := _decide("pb_no_baseline")
    d.benchmark_baseline_missing == true
    d._routing == "BLOCK_AND_ALERT"
}

# ── I11: test losowy bez seeda = BLOCK; brak replay = TRIAGE ──────────────────
test_p39_i11_no_seed_block {
    d := _decide("sr_no_seed")
    d.random_tests_without_seed == 1
    d._routing == "BLOCK_AND_ALERT"
}

test_p39_i11_no_replay_triage {
    d := _decide("sr_no_replay")
    d.seed_replay_missing == true
    d._routing == "TRIAGE_QUEUE"
}

# ── I12: brak impact map = TRIAGE; nieświeża > 7 dni = TRIAGE ─────────────────
test_p39_i12_missing_triage {
    d := _decide("im_missing")
    d.impact_map_missing == true
    d._routing == "TRIAGE_QUEUE"
}

test_p39_i12_stale_triage {
    d := _decide("im_stale")
    d.map_stale_days == 9
    d.impact_map_max_stale_days == 7
    d._routing == "TRIAGE_QUEUE"
}

# ── Certyfikat werdyktu zgodny z kontraktem P03 ────────────────────────────────
test_p39_certificate_fields {
    d := _decide("tm_ok")
    d.matched == true
    d["package"] == "jdg.v3_p39_testy_ci"
    d.priority == 439001
    d.threshold_version == "testy-ci-v3p39-2026.09"
    d.legal_basis_version == "testy-ci-legal-2026.09"
    d.valid_from == "2026-01-01"
}

# ── Brak aktywacji: no_match ──────────────────────────────────────────────────
test_p39_no_match_without_flag {
    d := v3_p39_testy_ci.decide with input as {"v3_p39": _cases["tm_ok"]}
    d.matched == false
    d.rule_id == "jdg.v3_p39_testy_ci.no_match"
}

# ── Fail-closed: brak snapshotu progów = BLOCK ────────────────────────────────
test_p39_fail_closed_no_snapshot {
    d := v3_p39_testy_ci.decide with input as object.union(_base, {"v3_p39": _cases["tm_ok"]}) with data.jdg.thresholds.v3_p39 as {}
    d.rule_id == "jdg.v3_p39_testy_ci.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}

# ── Parametry jako dane (ADR-002) ─────────────────────────────────────────────
test_p39_thresholds_snapshot_complete {
    s := data.jdg.thresholds.v3_p39
    s.v3_p39_matrix_coverage_min_pct == 80
    s.v3_p39_mutation_score_min_pct == 85
    s.v3_p39_act_coverage_min_pct == 90
    s.v3_p39_benchmark_regression_max_pct == 10
    s.v3_p39_impact_map_max_stale_days == 7
    s.v3_p39_threshold_version == "testy-ci-v3p39-2026.09"
    s.valid_from == "2026-01-01"
}

# ── Audytowalność: reason i legal_basis w każdej decyzji; priorytety unikalne ─
_reason_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._routing_reason) <= 10
}

test_p39_routing_reasons_present {
    count(_reason_violations) == 0
}

_basis_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._legal_basis) == 0
}

test_p39_legal_basis_in_all_decisions {
    count(_basis_violations) == 0
}

_priority_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    d.priority != 439001
    d.priority != 439002
    d.priority != 439003
    d.priority != 439004
    d.priority != 439005
    d.priority != 439006
    d.priority != 439007
    d.priority != 439008
    d.priority != 439009
    d.priority != 439010
    d.priority != 439011
    d.priority != 439012
}

test_p39_unique_priorities {
    count(_priority_violations) == 0
}
