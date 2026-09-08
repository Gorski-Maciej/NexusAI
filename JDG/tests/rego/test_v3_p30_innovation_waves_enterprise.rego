# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P30 FALE INNOWACJI — 24 GATE'Y RAPORTÓW R01–R24
# (jdg.v3_p30_innovation_waves) — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice
# (fałszywe DONE, adopt-rate, budżet wdrożeniowy, golden replay, 4-eyes).
# Uruchomienie (z katalogu repo):
#   ./bin/opa19 test JDG/tests/rego/test_v3_p30_innovation_waves_enterprise.rego \
#       JDG/rules/v3_p30_innovation_waves_enterprise.rego JDG/rules/thresholds_jdg.rego --v0-compatible
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p30

import data.jdg.v3_p30_innovation_waves

_base := {"jdg_entrepreneur": {"v3_p30_check": true}}

_cases := {
    # I01: deployment registry
    "rg_fake_done": {"analysis": "deployment_registry",
                     "deployment_registry": [{"rec": "R02-01", "status": "DONE",
                                              "evidence": {}},
                                             {"rec": "R02-02", "status": "DONE",
                                              "evidence": {"test_green": true,
                                                           "artifact": "rules/r02.rego"}}]},
    "rg_unknown_status": {"analysis": "deployment_registry",
                          "deployment_registry": [{"rec": "R02-01", "status": "MAGIC"}]},
    "rg_no_test": {"analysis": "deployment_registry",
                   "deployment_registry": [{"rec": "R02-01", "status": "DONE",
                                            "evidence": {"test_green": false,
                                                         "artifact": "rules/r02.rego"}}]},
    "rg_no_artifact": {"analysis": "deployment_registry",
                       "deployment_registry": [{"rec": "R02-01", "status": "DONE",
                                                "evidence": {"test_green": true,
                                                             "artifact": ""}}]},
    "rg_ok": {"analysis": "deployment_registry",
              "deployment_registry": [{"rec": "R02-01", "status": "DONE",
                                       "evidence": {"test_green": true,
                                                    "artifact": "rules/r02.rego"}},
                                      {"rec": "R02-02", "status": "OPEN"}]},

    # I02: adopt-rate dashboard
    "ar_low": {"analysis": "adopt_rate_dashboard",
               "domain_adopt": [{"domain": "VAT", "adopt_rate_pct": 40,
                                 "recommendations_total": 10}]},
    "ar_no_data": {"analysis": "adopt_rate_dashboard",
                   "domain_adopt": [{"domain": "PIT", "adopt_rate_pct": 90,
                                     "recommendations_total": 0}]},
    "ar_ok": {"analysis": "adopt_rate_dashboard",
              "domain_adopt": [{"domain": "VAT", "adopt_rate_pct": 90,
                                "recommendations_total": 10},
                               {"domain": "PIT", "adopt_rate_pct": 75,
                                "recommendations_total": 8}]},

    # I03: semantic deployment diff
    "sd_facade": {"analysis": "semantic_deployment_diff",
                  "semantic_diffs": [{"rec": "R03-01", "file_exists": true,
                                      "semantic_equivalent": false}]},
    "sd_missing": {"analysis": "semantic_deployment_diff",
                   "semantic_diffs": [{"rec": "R03-02", "file_exists": false,
                                       "semantic_equivalent": false}]},
    "sd_ok": {"analysis": "semantic_deployment_diff",
              "semantic_diffs": [{"rec": "R03-01", "file_exists": true,
                                  "semantic_equivalent": true}]},

    # I04: v4 selection contract
    "v4_no_score": {"analysis": "v4_selection_contract",
                    "v4_candidates": [{"rec": "R05-01"}]},
    "v4_ok": {"analysis": "v4_selection_contract",
              "v4_candidates": [{"rec": "R05-01", "roi_score": 90},
                                {"rec": "R05-02", "roi_score": 50}]},

    # I05: recommendation→pr traceability
    "pr_no_ref": {"analysis": "recommendation_pr_traceability",
                  "prs": [{"pr": 1, "recommendation_ids": []}],
                  "recommendations_total": 5},
    "pr_ok": {"analysis": "recommendation_pr_traceability",
              "prs": [{"pr": 1, "recommendation_ids": ["R06-01"]}],
              "recommendations_total": 5},

    # I06: facade wind-down
    "wd_dependents": {"analysis": "facade_wind_down",
                      "winddown_targets": [{"file": "stale.rego",
                                            "dependents": ["main.rego"]}]},
    "wd_ok": {"analysis": "facade_wind_down",
              "winddown_targets": [{"file": "stale.rego", "dependents": []}]},

    # I07: recommendation risk triage
    "rt_critical_unapproved": {"analysis": "recommendation_risk_triage",
                               "risk_classified": [{"rec": "R07-01",
                                                    "risk_class": "CRITICAL",
                                                    "human_approved": false}]},
    "rt_unknown": {"analysis": "recommendation_risk_triage",
                   "risk_classified": [{"rec": "R07-02", "risk_class": "MAGIC"}]},
    "rt_ok": {"analysis": "recommendation_risk_triage",
              "risk_classified": [{"rec": "R07-01", "risk_class": "CRITICAL",
                                   "human_approved": true},
                                  {"rec": "R07-02", "risk_class": "TRIVIAL"}]},

    # I08: golden replay
    "gr_fail": {"analysis": "golden_replay",
                "golden_replay": {"run": true, "verdicts_total": 26,
                                  "verdicts_failed": 1, "unverified": 0}},
    "gr_not_run": {"analysis": "golden_replay",
                   "golden_replay": {"run": false}},
    "gr_uver": {"analysis": "golden_replay",
                "golden_replay": {"run": true, "verdicts_total": 26,
                                  "verdicts_failed": 0, "unverified": 2}},
    "gr_ok": {"analysis": "golden_replay",
              "golden_replay": {"run": true, "verdicts_total": 26,
                                "verdicts_failed": 0, "unverified": 0}},

    # I09: deployment budget
    "db_over": {"analysis": "deployment_budget",
                "deployment_budget": {"rules_changed": 25}},
    "db_ok": {"analysis": "deployment_budget",
              "deployment_budget": {"rules_changed": 10}},

    # I10: data-driven changelog
    "cl_empty": {"analysis": "data_driven_changelog",
                 "changelog": {"entries": 0, "domains": []}},
    "cl_ok": {"analysis": "data_driven_changelog",
              "changelog": {"entries": 12, "domains": ["VAT", "PIT"]}},

    # I11: conflicting deployment detector
    "cd_conflict": {"analysis": "conflicting_deployment_detector",
                    "deployment_conflicts": ["fx: P15 vs hyper"]},
    "cd_ok": {"analysis": "conflicting_deployment_detector"},

    # I12: law radar loop closure
    "lr_unregistered": {"analysis": "law_radar_loop_closure",
                        "law_radar": {"recommendations": [{"rec": "LR-01",
                                                           "registry_created": false}]}},
    "lr_ok": {"analysis": "law_radar_loop_closure",
              "law_radar": {"recommendations": [{"rec": "LR-01",
                                                 "registry_created": true}]}},
}

_decide(case) = d {
    d := v3_p30_innovation_waves.decide with input as object.union(_base, {"v3_p30": _cases[case]})
}

# ── Brak aktywacji → no_match ──
test_p30_no_match_without_flag {
    d := v3_p30_innovation_waves.decide with input as {"v3_p30": _cases["rg_ok"]}
    d.rule_id == "jdg.v3_p30_innovation_waves.no_match"
}

# ── I01: Deployment Registry ──
test_p30_i01_fake_done_block {
    d := _decide("rg_fake_done")
    d.rule_id == "jdg.v3_p30_innovation_waves.deployment_registry"
    d._routing == "BLOCK_AND_ALERT"
    d.fake_done == 1
}

test_p30_i01_unknown_status_block {
    d := _decide("rg_unknown_status")
    d._routing == "BLOCK_AND_ALERT"
}

test_p30_i01_no_test_triage {
    d := _decide("rg_no_test")
    d._routing == "TRIAGE_QUEUE"
    d.done_without_test == 1
}

test_p30_i01_no_artifact_triage {
    d := _decide("rg_no_artifact")
    d._routing == "TRIAGE_QUEUE"
}

test_p30_i01_ok {
    d := _decide("rg_ok")
    d._routing == "SUGGEST"
    d.registry_total == 2
    d.done_total == 1
}

# ── I02: Adopt-Rate Dashboard ──
test_p30_i02_low_triage {
    d := _decide("ar_low")
    d.rule_id == "jdg.v3_p30_innovation_waves.adopt_rate_dashboard"
    d._routing == "TRIAGE_QUEUE"
    d.domains_below_threshold == 1
}

test_p30_i02_no_data_triage {
    d := _decide("ar_no_data")
    d._routing == "TRIAGE_QUEUE"
}

test_p30_i02_ok {
    d := _decide("ar_ok")
    d._routing == "SUGGEST"
    d.domains_total == 2
}

# ── I03: Semantic Deployment Diff ──
test_p30_i03_facade_block {
    d := _decide("sd_facade")
    d.rule_id == "jdg.v3_p30_innovation_waves.semantic_deployment_diff"
    d._routing == "BLOCK_AND_ALERT"
    d.facades == 1
}

test_p30_i03_missing_triage {
    d := _decide("sd_missing")
    d._routing == "TRIAGE_QUEUE"
}

test_p30_i03_ok {
    d := _decide("sd_ok")
    d._routing == "SUGGEST"
}

# ── I04: V4 Selection Contract ──
test_p30_i04_no_score_triage {
    d := _decide("v4_no_score")
    d.rule_id == "jdg.v3_p30_innovation_waves.v4_selection_contract"
    d._routing == "TRIAGE_QUEUE"
    d.candidates_without_score == 1
}

test_p30_i04_ok {
    d := _decide("v4_ok")
    d._routing == "SUGGEST"
    d.candidates_high_roi == 1
    d.high_roi_min == 80
}

# ── I05: Recommendation→PR Traceability ──
test_p30_i05_no_ref_triage {
    d := _decide("pr_no_ref")
    d.rule_id == "jdg.v3_p30_innovation_waves.recommendation_pr_traceability"
    d._routing == "TRIAGE_QUEUE"
    d.prs_without_ref == 1
}

test_p30_i05_ok {
    d := _decide("pr_ok")
    d._routing == "SUGGEST"
}

# ── I06: Facade Wind-Down ──
test_p30_i06_dependents_triage {
    d := _decide("wd_dependents")
    d.rule_id == "jdg.v3_p30_innovation_waves.facade_wind_down"
    d._routing == "TRIAGE_QUEUE"
    d.with_dependents == 1
}

test_p30_i06_ok {
    d := _decide("wd_ok")
    d._routing == "SUGGEST"
}

# ── I07: Recommendation Risk Triage ──
test_p30_i07_critical_unapproved_block {
    d := _decide("rt_critical_unapproved")
    d.rule_id == "jdg.v3_p30_innovation_waves.recommendation_risk_triage"
    d._routing == "BLOCK_AND_ALERT"
    d.critical_unapproved == 1
}

test_p30_i07_unknown_triage {
    d := _decide("rt_unknown")
    d._routing == "TRIAGE_QUEUE"
}

test_p30_i07_ok {
    d := _decide("rt_ok")
    d._routing == "SUGGEST"
}

# ── I08: Golden Replay ──
test_p30_i08_fail_block {
    d := _decide("gr_fail")
    d.rule_id == "jdg.v3_p30_innovation_waves.golden_replay"
    d._routing == "BLOCK_AND_ALERT"
    d.verdicts_failed == 1
}

test_p30_i08_not_run_triage {
    d := _decide("gr_not_run")
    d._routing == "TRIAGE_QUEUE"
}

test_p30_i08_uver_triage {
    d := _decide("gr_uver")
    d._routing == "TRIAGE_QUEUE"
}

test_p30_i08_ok {
    d := _decide("gr_ok")
    d._routing == "SUGGEST"
    d.verdicts_total == 26
}

# ── I09: Deployment Budget ──
test_p30_i09_over_block {
    d := _decide("db_over")
    d.rule_id == "jdg.v3_p30_innovation_waves.deployment_budget"
    d._routing == "BLOCK_AND_ALERT"
    d.rules_changed == 25
}

test_p30_i09_ok {
    d := _decide("db_ok")
    d._routing == "SUGGEST"
    d.max_rules_per_deployment == 20
}

# ── I10: Data-Driven Changelog ──
test_p30_i10_empty_triage {
    d := _decide("cl_empty")
    d.rule_id == "jdg.v3_p30_innovation_waves.data_driven_changelog"
    d._routing == "TRIAGE_QUEUE"
}

test_p30_i10_ok {
    d := _decide("cl_ok")
    d._routing == "SUGGEST"
    d.changelog_entries == 12
}

# ── I11: Conflicting Deployment Detector ──
test_p30_i11_conflict_block {
    d := _decide("cd_conflict")
    d.rule_id == "jdg.v3_p30_innovation_waves.conflicting_deployment_detector"
    d._routing == "BLOCK_AND_ALERT"
    d.conflicts_total == 1
}

test_p30_i11_ok {
    d := _decide("cd_ok")
    d._routing == "SUGGEST"
}

# ── I12: Law Radar Loop Closure ──
test_p30_i12_unregistered_triage {
    d := _decide("lr_unregistered")
    d.rule_id == "jdg.v3_p30_innovation_waves.law_radar_loop_closure"
    d._routing == "TRIAGE_QUEUE"
    d.unregistered == 1
}

test_p30_i12_ok {
    d := _decide("lr_ok")
    d._routing == "SUGGEST"
}

# ── Fail-closed: brak snapshotu progów ──
test_p30_fail_closed_no_snapshot {
    d := v3_p30_innovation_waves.decide with input as object.union(_base, {"v3_p30": _cases["rg_ok"]}) with data.jdg.thresholds.v3_p30 as {}
    d.rule_id == "jdg.v3_p30_innovation_waves.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}
