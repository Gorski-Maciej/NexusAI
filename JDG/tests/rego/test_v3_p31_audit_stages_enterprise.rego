# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P31 ETAPY AUDYTÓW 12–28 (jdg.v3_p31_audit_stages)
# — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice
# (red team min 10, risk-of-fortress 30, dowód wygasły 90 dni, limity etapów).
# Uruchomienie (z katalogu repo):
#   ./bin/opa19 test JDG/tests/rego/test_v3_p31_audit_stages_enterprise.rego \
#       JDG/rules/v3_p31_audit_stages_enterprise.rego JDG/rules/thresholds_jdg.rego --v0-compatible
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p31

import data.jdg.v3_p31_audit_stages

_base := {"jdg_entrepreneur": {"v3_p31_check": true}}

_full_stages := {"etap12": {"status": "pass", "evidence": {"audit": "e1"}},
                 "etap13": {"status": "pass", "evidence": {"audit": "e2"}},
                 "etap14": {"status": "pass", "evidence": {"audit": "e3"}},
                 "etap15": {"status": "pass", "evidence": {"audit": "e4"}},
                 "etap16": {"status": "pass", "evidence": {"audit": "e5"}},
                 "etap17": {"status": "pass", "evidence": {"audit": "e6"}},
                 "etap18": {"status": "pass", "evidence": {"audit": "e7"}},
                 "etap19": {"status": "pass", "evidence": {"audit": "e8"}},
                 "etap20": {"status": "pass", "evidence": {"audit": "e9"}},
                 "etap21": {"status": "pass", "evidence": {"audit": "e10"}},
                 "etap22": {"status": "pass", "evidence": {"audit": "e11"}},
                 "etap23": {"status": "pass", "evidence": {"audit": "e12"}},
                 "etap24": {"status": "pass", "evidence": {"audit": "e13"}},
                 "etap25": {"status": "pass", "evidence": {"audit": "e14"}},
                 "etap26": {"status": "pass", "evidence": {"audit": "e15"}},
                 "etap27": {"status": "pass", "evidence": {"audit": "e16"}},
                 "etap28": {"status": "pass", "evidence": {"audit": "e17"}}}

_cases := {
    # I01: unified audit schema
    "us_missing": {"analysis": "unified_audit_schema",
                   "stage_results": {"etap12": {"status": "pass", "evidence": {"a": 1}}}},
    "us_fail": {"analysis": "unified_audit_schema",
                "stage_results": object.union(_full_stages, {"etap14": {"status": "fail", "evidence": {"a": 1}}})},
    "us_no_evidence": {"analysis": "unified_audit_schema",
                       # object.union robi deep-merge — usuwamy etap15 z bazy, żeby evidence={} nie odziedziczył "audit": "e4"
                       "stage_results": object.union(object.remove(_full_stages, ["etap15"]),
                                                     {"etap15": {"status": "pass", "evidence": {}}})},
    "us_partial": {"analysis": "unified_audit_schema",
                   "stage_results": object.union(_full_stages, {"etap16": {"status": "partial", "evidence": {"a": 1}}})},
    "us_ok": {"analysis": "unified_audit_schema", "stage_results": _full_stages},

    # I02: cross-etap conflict detector
    "cc_unresolved": {"analysis": "cross_etap_conflict_detector",
                      "stage_conflicts": [{"stages": ["etap13", "etap22"], "resolved": false}]},
    "cc_resolved": {"analysis": "cross_etap_conflict_detector",
                    "stage_conflicts": [{"stages": ["etap13", "etap22"], "resolved": true}]},
    "cc_ok": {"analysis": "cross_etap_conflict_detector"},

    # I03: red team pack
    "rt_failed": {"analysis": "red_team_pack",
                  "red_team_attacks": [{"attack": "missing_fields", "fail_closed_ok": false}]},
    "rt_too_few": {"analysis": "red_team_pack",
                   "red_team_attacks": [{"attack": "a1", "fail_closed_ok": true},
                                        {"attack": "a2", "fail_closed_ok": true}]},
    "rt_ok": {"analysis": "red_team_pack",
              "red_team_attacks": [{"attack": "a1", "fail_closed_ok": true},
                                   {"attack": "a2", "fail_closed_ok": true},
                                   {"attack": "a3", "fail_closed_ok": true},
                                   {"attack": "a4", "fail_closed_ok": true},
                                   {"attack": "a5", "fail_closed_ok": true},
                                   {"attack": "a6", "fail_closed_ok": true},
                                   {"attack": "a7", "fail_closed_ok": true},
                                   {"attack": "a8", "fail_closed_ok": true},
                                   {"attack": "a9", "fail_closed_ok": true},
                                   {"attack": "a10", "fail_closed_ok": true}]},

    # I04: risk-of-fortress score
    "rf_over": {"analysis": "risk_of_fortress_score", "risk_of_fortress": {"score": 50}},
    "rf_warn": {"analysis": "risk_of_fortress_score", "risk_of_fortress": {"score": 25}},
    "rf_ok": {"analysis": "risk_of_fortress_score", "risk_of_fortress": {"score": 10}},

    # I05: stages as data
    "ed_hardcode": {"analysis": "stages_as_data", "audit_hardcode_detected": true},
    "ed_ok": {"analysis": "stages_as_data"},

    # I06: auto-rerun po nowelizacji
    "ar_missing": {"analysis": "auto_rerun_after_amendment",
                   "amendments": [{"act": "ZUS", "affected_stages_rerun": false}]},
    "ar_ok": {"analysis": "auto_rerun_after_amendment",
              "amendments": [{"act": "ZUS", "affected_stages_rerun": true}]},

    # I07: worm audit trail
    "wt_missing": {"analysis": "worm_audit_trail",
                   "stage_runs": [{"stage": "etap14", "worm_archived": false}]},
    "wt_ok": {"analysis": "worm_audit_trail",
              "stage_runs": [{"stage": "etap14", "worm_archived": true}]},

    # I08: frontier matrix
    "fm_stale": {"analysis": "frontier_matrix",
                 "frontier_matrix": [{"stage": "etap20", "days_since_evidence": 120}]},
    "fm_ok": {"analysis": "frontier_matrix",
              "frontier_matrix": [{"stage": "etap20", "days_since_evidence": 30}]},

    # I09: conflict resolution
    "cr_missing_reason": {"analysis": "conflict_resolution",
                          "mediation_register": [{"conflict": "C01", "reason": ""}]},
    "cr_ok": {"analysis": "conflict_resolution",
              "mediation_register": [{"conflict": "C01", "reason": "nowszy dowód etap22"}]},

    # I10: certification pack generator
    "cp_not_ready": {"analysis": "certification_pack_generator",
                     "certification_pack": {"ready": false}},
    "cp_no_synthesis": {"analysis": "certification_pack_generator",
                        "certification_pack": {"ready": true, "synthesis_present": false,
                                               "p0p1_gaps_present": true}},
    "cp_no_gaps": {"analysis": "certification_pack_generator",
                   "certification_pack": {"ready": true, "synthesis_present": true,
                                          "p0p1_gaps_present": false}},
    "cp_ok": {"analysis": "certification_pack_generator",
              "certification_pack": {"ready": true, "synthesis_present": true,
                                     "p0p1_gaps_present": true}},

    # I11: stage closure campaign
    "sc_over": {"analysis": "stage_closure_campaign",
                "closure_plan": {"stages_without_evidence": ["etap20", "etap21"]}},
    "sc_some": {"analysis": "stage_closure_campaign",
                "closure_plan": {"stages_without_evidence": []}},
    "sc_ok": {"analysis": "stage_closure_campaign",
              "closure_plan": {"stages_without_evidence": []}},

    # I12: p30 feed
    "pf_empty": {"analysis": "p30_feed", "p30_feed": {"entries": 0, "registry_synced": false}},
    "pf_unsync": {"analysis": "p30_feed", "p30_feed": {"entries": 17, "registry_synced": false}},
    "pf_ok": {"analysis": "p30_feed", "p30_feed": {"entries": 17, "registry_synced": true}},
}

_decide(case) = d {
    d := v3_p31_audit_stages.decide with input as object.union(_base, {"v3_p31": _cases[case]})
}

# ── Brak aktywacji → no_match ──
test_p31_no_match_without_flag {
    d := v3_p31_audit_stages.decide with input as {"v3_p31": _cases["us_ok"]}
    d.rule_id == "jdg.v3_p31_audit_stages.no_match"
}

# ── I01: Unified Audit Schema ──
test_p31_i01_missing_block {
    d := _decide("us_missing")
    d.rule_id == "jdg.v3_p31_audit_stages.unified_audit_schema"
    d._routing == "BLOCK_AND_ALERT"
    count(d.stages_missing) == 16
}

test_p31_i01_fail_block {
    d := _decide("us_fail")
    d._routing == "BLOCK_AND_ALERT"
    count(d.stages_failed) == 1
}

test_p31_i01_no_evidence_triage {
    d := _decide("us_no_evidence")
    d._routing == "TRIAGE_QUEUE"
    d.stages_no_evidence == 1
}

test_p31_i01_partial_triage {
    d := _decide("us_partial")
    d._routing == "TRIAGE_QUEUE"
    count(d.stages_partial) == 1
}

test_p31_i01_ok {
    d := _decide("us_ok")
    d._routing == "SUGGEST"
    d.stages_reported == 17
}

# ── I02: Cross-Etap Conflict Detector ──
test_p31_i02_unresolved_block {
    d := _decide("cc_unresolved")
    d.rule_id == "jdg.v3_p31_audit_stages.cross_etap_conflict_detector"
    d._routing == "BLOCK_AND_ALERT"
    d.conflicts_unresolved == 1
}

test_p31_i02_resolved_triage {
    d := _decide("cc_resolved")
    d._routing == "TRIAGE_QUEUE"
}

test_p31_i02_ok {
    d := _decide("cc_ok")
    d._routing == "SUGGEST"
}

# ── I03: Red Team Pack ──
test_p31_i03_failed_block {
    d := _decide("rt_failed")
    d.rule_id == "jdg.v3_p31_audit_stages.red_team_pack"
    d._routing == "BLOCK_AND_ALERT"
    d.attacks_failed == 1
}

test_p31_i03_too_few_triage {
    d := _decide("rt_too_few")
    d._routing == "TRIAGE_QUEUE"
    d.min_attacks == 10
}

test_p31_i03_ok {
    d := _decide("rt_ok")
    d._routing == "SUGGEST"
    d.attacks_total == 10
}

# ── I04: Risk-of-Fortress Score ──
test_p31_i04_over_block {
    d := _decide("rf_over")
    d.rule_id == "jdg.v3_p31_audit_stages.risk_of_fortress_score"
    d._routing == "BLOCK_AND_ALERT"
    d.score == 50
}

test_p31_i04_warn_triage {
    d := _decide("rf_warn")
    d._routing == "TRIAGE_QUEUE"
}

test_p31_i04_ok {
    d := _decide("rf_ok")
    d._routing == "SUGGEST"
    d.max_score == 30
}

# ── I05: Stages as Data ──
test_p31_i05_hardcode_block {
    d := _decide("ed_hardcode")
    d.rule_id == "jdg.v3_p31_audit_stages.stages_as_data"
    d._routing == "BLOCK_AND_ALERT"
    d.hardcode_detected == true
}

test_p31_i05_ok {
    d := _decide("ed_ok")
    d._routing == "SUGGEST"
    d.registry_entries == 17
    count(d.registry_missing) == 0
}

# ── I06: Auto-Rerun po Nowelizacji ──
test_p31_i06_missing_triage {
    d := _decide("ar_missing")
    d.rule_id == "jdg.v3_p31_audit_stages.auto_rerun_after_amendment"
    d._routing == "TRIAGE_QUEUE"
    d.amendments_without_rerun == 1
}

test_p31_i06_ok {
    d := _decide("ar_ok")
    d._routing == "SUGGEST"
}

# ── I07: WORM Audit Trail ──
test_p31_i07_missing_triage {
    d := _decide("wt_missing")
    d.rule_id == "jdg.v3_p31_audit_stages.worm_audit_trail"
    d._routing == "TRIAGE_QUEUE"
    d.runs_without_worm == 1
}

test_p31_i07_ok {
    d := _decide("wt_ok")
    d._routing == "SUGGEST"
}

# ── I08: Frontier Matrix ──
test_p31_i08_stale_triage {
    d := _decide("fm_stale")
    d.rule_id == "jdg.v3_p31_audit_stages.frontier_matrix"
    d._routing == "TRIAGE_QUEUE"
    d.cells_stale == 1
    d.stale_days == 90
}

test_p31_i08_ok {
    d := _decide("fm_ok")
    d._routing == "SUGGEST"
}

# ── I09: Conflict Resolution ──
test_p31_i09_missing_reason_triage {
    d := _decide("cr_missing_reason")
    d.rule_id == "jdg.v3_p31_audit_stages.conflict_resolution"
    d._routing == "TRIAGE_QUEUE"
    d.mediations_missing_reason == 1
}

test_p31_i09_ok {
    d := _decide("cr_ok")
    d._routing == "SUGGEST"
}

# ── I10: Certification Pack Generator ──
test_p31_i10_not_ready_triage {
    d := _decide("cp_not_ready")
    d.rule_id == "jdg.v3_p31_audit_stages.certification_pack_generator"
    d._routing == "TRIAGE_QUEUE"
}

test_p31_i10_no_synthesis_triage {
    d := _decide("cp_no_synthesis")
    d._routing == "TRIAGE_QUEUE"
}

test_p31_i10_no_gaps_triage {
    d := _decide("cp_no_gaps")
    d._routing == "TRIAGE_QUEUE"
}

test_p31_i10_ok {
    d := _decide("cp_ok")
    d._routing == "SUGGEST"
}

# ── I11: Stage Closure Campaign ──
test_p31_i11_over_block {
    d := _decide("sc_over")
    d.rule_id == "jdg.v3_p31_audit_stages.stage_closure_campaign"
    d._routing == "BLOCK_AND_ALERT"
    d.stages_without_evidence == 2
}

test_p31_i11_ok {
    d := _decide("sc_ok")
    d._routing == "SUGGEST"
    d.max_allowed == 0
}

# ── I12: P30 Feed ──
test_p31_i12_empty_triage {
    d := _decide("pf_empty")
    d.rule_id == "jdg.v3_p31_audit_stages.p30_feed"
    d._routing == "TRIAGE_QUEUE"
}

test_p31_i12_unsync_triage {
    d := _decide("pf_unsync")
    d._routing == "TRIAGE_QUEUE"
}

test_p31_i12_ok {
    d := _decide("pf_ok")
    d._routing == "SUGGEST"
    d.feed_entries == 17
}

# ── Fail-closed: brak snapshotu progów ──
test_p31_fail_closed_no_snapshot {
    d := v3_p31_audit_stages.decide with input as object.union(_base, {"v3_p31": _cases["us_ok"]}) with data.jdg.thresholds.v3_p31 as {}
    d.rule_id == "jdg.v3_p31_audit_stages.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}
