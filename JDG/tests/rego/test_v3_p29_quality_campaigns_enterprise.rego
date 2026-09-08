# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P29 KAMPANIE JAKOŚCI V3 — 8 BRAMEK (jdg.v3_p29_quality_campaigns)
# — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# NEEDS_ADVICE, TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice
# (mutation score, dług P1, heatmapa RED/AMBER, fasady, seed, dryf profilu).
# Uruchomienie (z katalogu repo):
#   ./bin/opa19 test JDG/tests/rego/test_v3_p29_quality_campaigns_enterprise.rego \
#       JDG/rules/v3_p29_quality_campaigns_enterprise.rego JDG/rules/thresholds_jdg.rego --v0-compatible
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p29

import data.jdg.v3_p29_quality_campaigns

_base := {"jdg_entrepreneur": {"v3_p29_check": true}}

_cases := {
    # I01: composite quality gate
    "cg_missing": {"analysis": "composite_quality_gate",
                   "gate_results": {"v3_13": {"passed": true}}},
    "cg_failed": {"analysis": "composite_quality_gate",
                  "gate_results": {"v3_13": {"passed": true}, "v3_14": {"passed": true},
                                   "v3_15": {"passed": true}, "v3_16": {"passed": true},
                                   "v3_17": {"passed": false}, "v3_18": {"passed": true},
                                   "v3_19": {"passed": true}, "v3_20": {"passed": true}}},
    "cg_ok": {"analysis": "composite_quality_gate",
              "gate_results": {"v3_13": {"passed": true}, "v3_14": {"passed": true},
                               "v3_15": {"passed": true}, "v3_16": {"passed": true},
                               "v3_17": {"passed": true}, "v3_18": {"passed": true},
                               "v3_19": {"passed": true}, "v3_20": {"passed": true}}},

    # I02: mutation testing
    "mt_low_score": {"analysis": "mutation_testing",
                     "mutations_total": 100, "mutations_killed": 60},
    "mt_no_run": {"analysis": "mutation_testing"},
    "mt_ok": {"analysis": "mutation_testing",
              "mutations_total": 100, "mutations_killed": 90},

    # I03: quality debt ledger
    "dl_p1_open": {"analysis": "quality_debt_ledger",
                   "quality_debts": [{"status": "OPEN", "criticality": "P1"},
                                     {"status": "OPEN", "criticality": "P1"}]},
    "dl_overdue": {"analysis": "quality_debt_ledger",
                   "evaluation_date": "2026-09-08",
                   "quality_debts": [{"status": "OPEN", "criticality": "P2",
                                      "repay_by": "2026-09-01"}]},
    "dl_ok": {"analysis": "quality_debt_ledger",
              "quality_debts": [{"status": "REPAID", "criticality": "P1"}]},

    # I04: deterministic seed
    "sc_no_seed": {"analysis": "deterministic_seed",
                   "random_tests": [{"name": "fuzz_a"}, {"name": "fuzz_b", "seed": 7}]},
    "sc_ok": {"analysis": "deterministic_seed",
              "random_tests": [{"name": "fuzz_a", "seed": 42}, {"name": "fuzz_b", "seed": 7}]},

    # I05: gate performance profiler
    "pp_over_limit": {"analysis": "gate_performance_profiler",
                      "gate_timings": [{"gate": "v3_13", "actual_seconds": 200}]},
    "pp_drift": {"analysis": "gate_performance_profiler",
                 "gate_timings": [{"gate": "v3_17", "baseline_seconds": 10,
                                   "actual_seconds": 20}]},
    "pp_ok": {"analysis": "gate_performance_profiler",
              "gate_timings": [{"gate": "v3_13", "baseline_seconds": 10,
                                "actual_seconds": 12}]},

    # I06: gate-as-data
    "gd_hardcode": {"analysis": "gate_as_data", "gate_hardcode_detected": true},
    "gd_ok": {"analysis": "gate_as_data"},

    # I07: merge block comment
    "mc_silent_block": {"analysis": "merge_block_comment",
                        "merge_block_events": [{"blocked": true, "comment_lines": []}]},
    "mc_ok": {"analysis": "merge_block_comment",
              "merge_block_events": [{"blocked": true,
                                      "comment_lines": ["L120: próg bez data.thresholds"]}]},

    # I08: domain quality heatmap
    "hm_red": {"analysis": "domain_quality_heatmap",
               "domain_scores": [{"domain": "VAT", "score": 40},
                                 {"domain": "PIT", "score": 90}]},
    "hm_amber": {"analysis": "domain_quality_heatmap",
                 "domain_scores": [{"domain": "ZUS", "score": 70}]},
    "hm_ok": {"analysis": "domain_quality_heatmap",
              "domain_scores": [{"domain": "VAT", "score": 95},
                                {"domain": "PIT", "score": 85}]},

    # I09: facade assertion detector
    "fd_blocking": {"analysis": "facade_assertion_detector",
                    "facade_tests": [{"test": "t1", "is_merge_blocking": true}]},
    "fd_nonblocking": {"analysis": "facade_assertion_detector",
                       "facade_tests": [{"test": "t2", "is_merge_blocking": false}]},
    "fd_ok": {"analysis": "facade_assertion_detector", "facade_tests": []},

    # I10: gate-to-certificate binding
    "cb_issued_missing": {"analysis": "gate_to_certificate",
                          "certificate_issued": true,
                          "certificate_gate_versions": {"v3_13": "1"}},
    "cb_pending": {"analysis": "gate_to_certificate",
                   "certificate_gate_versions": {}},
    "cb_ok": {"analysis": "gate_to_certificate",
              "certificate_issued": true,
              "certificate_gate_versions": {"v3_13": "1", "v3_14": "1", "v3_15": "1",
                                            "v3_16": "1", "v3_17": "1", "v3_18": "1",
                                            "v3_19": "1", "v3_20": "1"}},

    # I11: test upgrade pipeline
    "up_missing": {"analysis": "test_upgrade_pipeline",
                   "lifecycle_candidates": [{"rule": "r1",
                                             "boundary_tests_generated": false}]},
    "up_ok": {"analysis": "test_upgrade_pipeline",
              "lifecycle_candidates": [{"rule": "r1",
                                        "boundary_tests_generated": true}]},

    # I12: holy documents compliance
    "hc_conflict": {"analysis": "holy_documents_compliance",
                    "holy_document_conflicts": ["V1 §bramki CI vs cicha bramka"]},
    "hc_ok": {"analysis": "holy_documents_compliance"},
}

_decide(case) = d {
    d := v3_p29_quality_campaigns.decide with input as object.union(_base, {"v3_p29": _cases[case]})
}

# ── Brak aktywacji → no_match ──
test_p29_no_match_without_flag {
    d := v3_p29_quality_campaigns.decide with input as {"v3_p29": _cases["cg_ok"]}
    d.rule_id == "jdg.v3_p29_quality_campaigns.no_match"
}

# ── I01: Composite Quality Gate ──
test_p29_i01_missing_block {
    d := _decide("cg_missing")
    d.rule_id == "jdg.v3_p29_quality_campaigns.composite_quality_gate"
    d._routing == "BLOCK_AND_ALERT"
    count(d.gates_missing) == 7
}

test_p29_i01_failed_block {
    d := _decide("cg_failed")
    d._routing == "BLOCK_AND_ALERT"
    count(d.gates_failed) == 1
}

test_p29_i01_ok {
    d := _decide("cg_ok")
    d._routing == "SUGGEST"
    d.gates_reported == 8
    d.expected_gates == 8
}

# ── I02: Mutation Testing ──
test_p29_i02_low_score_block {
    d := _decide("mt_low_score")
    d.rule_id == "jdg.v3_p29_quality_campaigns.mutation_testing"
    d._routing == "BLOCK_AND_ALERT"
    d.mutation_score == 60
    d.mutations_survived == 40
}

test_p29_i02_no_run_triage {
    d := _decide("mt_no_run")
    d._routing == "TRIAGE_QUEUE"
}

test_p29_i02_ok {
    d := _decide("mt_ok")
    d._routing == "SUGGEST"
    d.mutation_score == 90
}

# ── I03: Quality Debt Ledger ──
test_p29_i03_p1_open_block {
    d := _decide("dl_p1_open")
    d.rule_id == "jdg.v3_p29_quality_campaigns.quality_debt_ledger"
    d._routing == "BLOCK_AND_ALERT"
    d.debts_p1_open == 2
}

test_p29_i03_overdue_triage {
    d := _decide("dl_overdue")
    d._routing == "TRIAGE_QUEUE"
}

test_p29_i03_ok {
    d := _decide("dl_ok")
    d._routing == "SUGGEST"
}

# ── I04: Deterministic Seed ──
test_p29_i04_no_seed_triage {
    d := _decide("sc_no_seed")
    d.rule_id == "jdg.v3_p29_quality_campaigns.deterministic_seed"
    d._routing == "TRIAGE_QUEUE"
    d.tests_without_seed == 1
}

test_p29_i04_ok {
    d := _decide("sc_ok")
    d._routing == "SUGGEST"
    d.random_tests_total == 2
}

# ── I05: Gate Performance Profiler ──
test_p29_i05_over_limit_triage {
    d := _decide("pp_over_limit")
    d.rule_id == "jdg.v3_p29_quality_campaigns.gate_performance_profiler"
    d._routing == "TRIAGE_QUEUE"
    d.gates_over_limit == 1
}

test_p29_i05_drift_triage {
    d := _decide("pp_drift")
    d._routing == "TRIAGE_QUEUE"
    d.gates_drifted == 1
}

test_p29_i05_ok {
    d := _decide("pp_ok")
    d._routing == "SUGGEST"
}

# ── I06: Gate-as-Data ──
test_p29_i06_hardcode_block {
    d := _decide("gd_hardcode")
    d.rule_id == "jdg.v3_p29_quality_campaigns.gate_as_data"
    d._routing == "BLOCK_AND_ALERT"
    d.hardcode_detected == true
}

test_p29_i06_ok {
    d := _decide("gd_ok")
    d._routing == "SUGGEST"
    d.registry_entries == 8
    count(d.registry_missing) == 0
}

# ── I07: Merge Block Comment ──
test_p29_i07_silent_block {
    d := _decide("mc_silent_block")
    d.rule_id == "jdg.v3_p29_quality_campaigns.merge_block_comment"
    d._routing == "BLOCK_AND_ALERT"
    d.blocks_without_comment == 1
}

test_p29_i07_ok {
    d := _decide("mc_ok")
    d._routing == "SUGGEST"
    d.block_events == 1
}

# ── I08: Domain Quality Heatmap ──
test_p29_i08_red_block {
    d := _decide("hm_red")
    d.rule_id == "jdg.v3_p29_quality_campaigns.domain_quality_heatmap"
    d._routing == "BLOCK_AND_ALERT"
    count(d.domains_red) == 1
}

test_p29_i08_amber_triage {
    d := _decide("hm_amber")
    d._routing == "TRIAGE_QUEUE"
    count(d.domains_amber) == 1
}

test_p29_i08_ok {
    d := _decide("hm_ok")
    d._routing == "SUGGEST"
    d.domains_total == 2
}

# ── I09: Facade Assertion Detector ──
test_p29_i09_blocking_facade_block {
    d := _decide("fd_blocking")
    d.rule_id == "jdg.v3_p29_quality_campaigns.facade_assertion_detector"
    d._routing == "BLOCK_AND_ALERT"
    d.facades_blocking == 1
}

test_p29_i09_nonblocking_triage {
    d := _decide("fd_nonblocking")
    d._routing == "TRIAGE_QUEUE"
}

test_p29_i09_ok {
    d := _decide("fd_ok")
    d._routing == "SUGGEST"
}

# ── I10: Gate-to-Certificate Binding ──
test_p29_i10_issued_missing_block {
    d := _decide("cb_issued_missing")
    d.rule_id == "jdg.v3_p29_quality_campaigns.gate_to_certificate"
    d._routing == "BLOCK_AND_ALERT"
    count(d.gate_versions_missing) == 7
}

test_p29_i10_pending_triage {
    d := _decide("cb_pending")
    d._routing == "TRIAGE_QUEUE"
}

test_p29_i10_ok {
    d := _decide("cb_ok")
    d._routing == "SUGGEST"
    d.certificate_gate_versions_present == 8
}

# ── I11: Test Upgrade Pipeline ──
test_p29_i11_missing_tests_block {
    d := _decide("up_missing")
    d.rule_id == "jdg.v3_p29_quality_campaigns.test_upgrade_pipeline"
    d._routing == "BLOCK_AND_ALERT"
    d.candidates_without_tests == 1
}

test_p29_i11_ok {
    d := _decide("up_ok")
    d._routing == "SUGGEST"
    d.candidates_total == 1
}

# ── I12: Holy Documents Compliance ──
test_p29_i12_conflict_block {
    d := _decide("hc_conflict")
    d.rule_id == "jdg.v3_p29_quality_campaigns.holy_documents_compliance"
    d._routing == "BLOCK_AND_ALERT"
    d.conflicts_total == 1
}

test_p29_i12_ok {
    d := _decide("hc_ok")
    d._routing == "SUGGEST"
}

# ── Fail-closed: brak snapshotu progów ──
test_p29_fail_closed_no_snapshot {
    d := v3_p29_quality_campaigns.decide with input as object.union(_base, {"v3_p29": _cases["cg_ok"]}) with data.jdg.thresholds.v3_p29 as {}
    d.rule_id == "jdg.v3_p29_quality_campaigns.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}
