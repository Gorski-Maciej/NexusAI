# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P28 HYPERKONTEKSTY PLAN44/45 I KRYTYCZNE ŚCIEŻKI
# (jdg.v3_p28_hyper_plan45) — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# NEEDS_ADVICE, TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice
# (siła wyższa max dni, próg podpisu kwalifikowanego, sanctions human review,
# crisis drill komplet, golden tolerancja).
# Uruchomienie (z katalogu JDG/):
#   ../bin/opa test tests/rego/test_v3_p28_hyper_plan45_enterprise.rego \
#       rules/v3_p28_hyper_plan45_enterprise.rego rules/thresholds_jdg.rego
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p28

import data.jdg.v3_p28_hyper_plan45

_base := {"jdg_entrepreneur": {"v3_p28_check": true}}

_cases := {
    # I01: mapa kontekstów
    "map_ok": {"analysis": "hyper_context_map"},

    # I02: duplicate detector
    "dup_unreported": {"analysis": "duplicate_detector",
                       "dup_fx_present": true},
    "dup_over": {"analysis": "duplicate_detector",
                 "duplicate_domains": ["fx", "limits", "unknown_x"]},
    "dup_ok": {"analysis": "duplicate_detector",
               "duplicate_domains": ["fx", "limits"],
               "declared_duplicates": ["fx", "limits"]},

    # I03: force majeure framework
    "fm_unknown_event": {"analysis": "force_majeure_framework",
                         "force_majeure_event": "MAGIC_STORM"},
    "fm_too_long": {"analysis": "force_majeure_framework",
                    "force_majeure_event": "FLOOD",
                    "force_majeure_start_ts": 1700000000000000000,
                    "force_majeure_end_ts": 1800000000000000000},
    "fm_deadline_in_window": {"analysis": "force_majeure_framework",
                              "force_majeure_event": "FLOOD",
                              "force_majeure_start_ts": 1700000000000,
                              "force_majeure_end_ts": 1702000000000,
                              "deadline_ts": 1701000000000},
    "fm_active_no_deadline": {"analysis": "force_majeure_framework",
                              "force_majeure_event": "EPIDEMIC",
                              "force_majeure_start_ts": 1700000000000000000,
                              "force_majeure_end_ts": 1701000000000000000},
    "fm_none": {"analysis": "force_majeure_framework"},

    # I04: sanctions gate
    "sg_listed_no_review": {"analysis": "sanctions_gate",
                            "counterparty_on_sanctions_list": true},
    "sg_listed_reviewed": {"analysis": "sanctions_gate",
                           "counterparty_on_sanctions_list": true,
                           "sanctions_human_review_done": true,
                           "aml_p22_screened": true},
    "sg_stale_list": {"analysis": "sanctions_gate",
                      "sanctions_list_version": "eu-un-2020"},
    "sg_no_aml": {"analysis": "sanctions_gate",
                  "sanctions_list_version": "eu-un-2026.09"},
    "sg_ok": {"analysis": "sanctions_gate",
              "sanctions_list_version": "eu-un-2026.09",
              "aml_p22_screened": true},

    # I05: marginal domain register
    "mdr_ok": {"analysis": "marginal_domain_register"},

    # I06: esig contract layer
    "es_bad_key": {"analysis": "esig_contract_layer",
                   "esig_doc_type": "DECLARATION",
                   "esig_document_value_pln": 20000,
                   "esig_key_type": "MAGIC"},
    "es_ok_qualified": {"analysis": "esig_contract_layer",
                        "esig_doc_type": "DECLARATION",
                        "esig_document_value_pln": 20000,
                        "esig_key_type": "QUALIFIED"},
    "es_no_value": {"analysis": "esig_contract_layer",
                    "esig_doc_type": "DECLARATION",
                    "esig_document_value_pln": 0,
                    "esig_key_type": "QUALIFIED"},
    "es_none": {"analysis": "esig_contract_layer"},

    # I07: crisis drill
    "cd_incomplete": {"analysis": "crisis_drill",
                      "crisis_results": [{"scenario": "FORCE_MAJEURE_ACTIVE",
                                          "passed": true}]},
    "cd_failing": {"analysis": "crisis_drill",
                   "crisis_results": [{"scenario": "FORCE_MAJEURE_ACTIVE", "passed": true},
                                      {"scenario": "KSEF_DOWN", "passed": true},
                                      {"scenario": "DEADLINE_TODAY", "passed": false}]},
    "cd_ok": {"analysis": "crisis_drill",
              "crisis_results": [{"scenario": "FORCE_MAJEURE_ACTIVE", "passed": true},
                                 {"scenario": "KSEF_DOWN", "passed": true},
                                 {"scenario": "DEADLINE_TODAY", "passed": true}]},

    # I08: network consistency gate
    "nc_gaps": {"analysis": "network_consistency_gate",
                "network_contexts_checked": 14,
                "network_gaps": ["fx:brak_kontraktu"]},
    "nc_incomplete": {"analysis": "network_consistency_gate",
                      "network_contexts_checked": 10},
    "nc_ok": {"analysis": "network_consistency_gate",
              "network_contexts_checked": 14,
              "network_gaps": []},

    # I09: hyper invariants pack
    "iv_sanctions_auto": {"analysis": "hyper_invariants_pack",
                          "sanctions_auto_transaction_attempt": true},
    "iv_fm_auto": {"analysis": "hyper_invariants_pack",
                   "force_majeure_auto_extension_attempt": true},
    "iv_fx_dup": {"analysis": "hyper_invariants_pack",
                  "fx_duplicate_engine_attempt": true},
    "iv_auto_post": {"analysis": "hyper_invariants_pack",
                     "hyper_auto_post_attempt": true},
    "iv_ok": {"analysis": "hyper_invariants_pack"},

    # I10: hyper golden set
    "gs_unknown": {"analysis": "golden_hyper_set",
                   "golden_rows": [{"kind": "ALIEN_KIND", "value": 1}]},
    "gs_fail": {"analysis": "golden_hyper_set",
                "golden_rows": [{"kind": "FM_MAX_DAYS", "value": 91},
                                {"kind": "ESIG_THRESHOLD", "value": 10000},
                                {"kind": "CRISIS_SCENARIOS", "value": 3}]},
    "gs_ok": {"analysis": "golden_hyper_set",
              "golden_rows": [{"kind": "FM_MAX_DAYS", "value": 90},
                              {"kind": "ESIG_THRESHOLD", "value": 10000},
                              {"kind": "CRISIS_SCENARIOS", "value": 3}]},
    "gs_empty": {"analysis": "golden_hyper_set", "golden_rows": []},

    # I11: marginal cleanup plan
    "cp_desert": {"analysis": "marginal_cleanup_plan",
                  "domains_with_tests": ["esig"]},
    "cp_ok": {"analysis": "marginal_cleanup_plan",
              "domains_with_tests": ["esig", "taxfree", "seasonal", "insurance",
                                     "advertising", "regulated", "procurement",
                                     "force_majeure", "fx"]},

    # I12: explanation engine
    "ex_unknown": {"analysis": "hyper_explanation_engine",
                   "explanation_topic": "MAGIC"},
    "ex_fm": {"analysis": "hyper_explanation_engine",
              "explanation_topic": "FORCE_MAJEURE"},
    "ex_none": {"analysis": "hyper_explanation_engine"},
}

_decide(case) = d {
    d := v3_p28_hyper_plan45.decide with input as object.union(_base, {"v3_p28": _cases[case]})
}

# ── Brak aktywacji → no_match ──
test_p28_no_match_without_flag {
    d := v3_p28_hyper_plan45.decide with input as {"v3_p28": _cases["map_ok"]}
    d.rule_id == "jdg.v3_p28_hyper_plan45.no_match"
}

# ── I01: Hyper Context Map ──
test_p28_i01_map {
    d := _decide("map_ok")
    d.rule_id == "jdg.v3_p28_hyper_plan45.hyper_context_map"
    d._routing == "SUGGEST"
    d.contexts_mapped == 14
    d.p44_input == true
    d.map.sanctions.contract == "sanctions_human_review"
    d.map.force_majeure.contract == "deadline_suspension"
    d.map.fx.contract == "fx_single_engine"
}

# ── I02: Duplicate Detector ──
test_p28_i02_unreported_triage {
    d := _decide("dup_unreported")
    d.rule_id == "jdg.v3_p28_hyper_plan45.duplicate_detector"
    d._routing == "TRIAGE_QUEUE"
    count(d.unreported) == 1
}

test_p28_i02_over_block {
    d := _decide("dup_over")
    d._routing == "BLOCK_AND_ALERT"
}

test_p28_i02_ok {
    d := _decide("dup_ok")
    d._routing == "SUGGEST"
}

# ── I03: Force Majeure Framework ──
test_p28_i03_unknown_event_block {
    d := _decide("fm_unknown_event")
    d.rule_id == "jdg.v3_p28_hyper_plan45.force_majeure_framework"
    d._routing == "BLOCK_AND_ALERT"
    d.event_known == false
}

test_p28_i03_too_long_block {
    d := _decide("fm_too_long")
    d._routing == "BLOCK_AND_ALERT"
}

test_p28_i03_deadline_in_window_needs_advice {
    d := _decide("fm_deadline_in_window")
    d._routing == "NEEDS_ADVICE"
    d.deadline_in_window == true
    d.calendar_p25_linked == true
}

test_p28_i03_active_needs_advice {
    d := _decide("fm_active_no_deadline")
    d._routing == "NEEDS_ADVICE"
}

test_p28_i03_none_suggest {
    d := _decide("fm_none")
    d._routing == "SUGGEST"
}

# ── I04: Sanctions Gate ──
test_p28_i04_listed_no_review_block {
    d := _decide("sg_listed_no_review")
    d.rule_id == "jdg.v3_p28_hyper_plan45.sanctions_gate"
    d._routing == "BLOCK_AND_ALERT"
    d.auto_transaction == false
    d.human_review_done == false
}

test_p28_i04_listed_reviewed_needs_advice {
    d := _decide("sg_listed_reviewed")
    d._routing == "NEEDS_ADVICE"
}

test_p28_i04_stale_list_triage {
    d := _decide("sg_stale_list")
    d._routing == "TRIAGE_QUEUE"
}

test_p28_i04_no_aml_triage {
    d := _decide("sg_no_aml")
    d._routing == "TRIAGE_QUEUE"
}

test_p28_i04_ok {
    d := _decide("sg_ok")
    d._routing == "SUGGEST"
}

# ── I05: Marginal Domain Register ──
test_p28_i05_register {
    d := _decide("mdr_ok")
    d.rule_id == "jdg.v3_p28_hyper_plan45.marginal_domain_register"
    d._routing == "SUGGEST"
    d.register.TAXFREE.decision == "IN_SCOPE_JDG_AS_INFO"
    d.register.SEASONAL.decision == "IN_SCOPE_JDG_AS_DATA"
    d.register.INSURANCE.decision == "IN_SCOPE_JDG_AS_COST"
    d.register.ADVERTISING.decision == "IN_SCOPE_JDG_AS_COST"
    d.register.REGULATED.decision == "OUT_OF_SCOPE_JDG"
    d.register.PROCUREMENT.decision == "OUT_OF_SCOPE_JDG"
    d.register.ESIG.decision == "IN_SCOPE_JDG_AS_CONTRACT"
    d.p44_input == true
}

# ── I06: ESIG Contract Layer ──
test_p28_i06_bad_key_block {
    d := _decide("es_bad_key")
    d.rule_id == "jdg.v3_p28_hyper_plan45.esig_contract_layer"
    d._routing == "BLOCK_AND_ALERT"
}

test_p28_i06_ok_qualified {
    d := _decide("es_ok_qualified")
    d._routing == "SUGGEST"
    d.qualified_required == true
    d.threshold_pln == 10000
    d.contract_p11_linked == true
    d.contract_p16_linked == true
}

test_p28_i06_no_value_triage {
    d := _decide("es_no_value")
    d._routing == "TRIAGE_QUEUE"
}

test_p28_i06_none_suggest {
    d := _decide("es_none")
    d._routing == "SUGGEST"
}

# ── I07: Crisis Drill ──
test_p28_i07_incomplete_triage {
    d := _decide("cd_incomplete")
    d.rule_id == "jdg.v3_p28_hyper_plan45.crisis_drill"
    d._routing == "TRIAGE_QUEUE"
}

test_p28_i07_failing_block {
    d := _decide("cd_failing")
    d._routing == "BLOCK_AND_ALERT"
    d.failed == 1
}

test_p28_i07_ok {
    d := _decide("cd_ok")
    d._routing == "SUGGEST"
    d.results == 3
    d.failed == 0
    d.scenarios_known == 3
}

# ── I08: Network Consistency Gate ──
test_p28_i08_gaps_block {
    d := _decide("nc_gaps")
    d.rule_id == "jdg.v3_p28_hyper_plan45.network_consistency_gate"
    d._routing == "BLOCK_AND_ALERT"
    count(d.gaps) == 1
}

test_p28_i08_incomplete_triage {
    d := _decide("nc_incomplete")
    d._routing == "TRIAGE_QUEUE"
}

test_p28_i08_ok {
    d := _decide("nc_ok")
    d._routing == "SUGGEST"
    d.contexts_checked == 14
}

# ── I09: Hyper Invariants Pack ──
test_p28_i09_sanctions_auto_block {
    d := _decide("iv_sanctions_auto")
    d.rule_id == "jdg.v3_p28_hyper_plan45.hyper_invariants_pack"
    d._routing == "BLOCK_AND_ALERT"
    count(d.violations) == 1
}

test_p28_i09_fm_auto_block {
    d := _decide("iv_fm_auto")
    d._routing == "BLOCK_AND_ALERT"
}

test_p28_i09_fx_dup_block {
    d := _decide("iv_fx_dup")
    d._routing == "BLOCK_AND_ALERT"
}

test_p28_i09_auto_post_block {
    d := _decide("iv_auto_post")
    d._routing == "BLOCK_AND_ALERT"
}

test_p28_i09_ok {
    d := _decide("iv_ok")
    d._routing == "SUGGEST"
    count(d.violations) == 0
}

# ── I10: Hyper Golden Set ──
test_p28_i10_unknown_triage {
    d := _decide("gs_unknown")
    d.rule_id == "jdg.v3_p28_hyper_plan45.hyper_golden_set"
    d._routing == "TRIAGE_QUEUE"
}

test_p28_i10_mismatch_block {
    d := _decide("gs_fail")
    d._routing == "BLOCK_AND_ALERT"
    d.rows_failed == 1
}

test_p28_i10_ok {
    d := _decide("gs_ok")
    d._routing == "SUGGEST"
    d.rows_checked == 3
    d.rows_failed == 0
}

test_p28_i10_empty_triage {
    d := _decide("gs_empty")
    d._routing == "TRIAGE_QUEUE"
}

# ── I11: Marginal Cleanup Plan ──
test_p28_i11_desert_block {
    d := _decide("cp_desert")
    d.rule_id == "jdg.v3_p28_hyper_plan45.marginal_cleanup_plan"
    d._routing == "BLOCK_AND_ALERT"
    count(d.untested) == 8
}

test_p28_i11_ok {
    d := _decide("cp_ok")
    d._routing == "SUGGEST"
    count(d.untested) == 0
}

# ── I12: Hyper Explanation Engine ──
test_p28_i12_unknown_triage {
    d := _decide("ex_unknown")
    d.rule_id == "jdg.v3_p28_hyper_plan45.hyper_explanation_engine"
    d._routing == "TRIAGE_QUEUE"
}

test_p28_i12_fm_explained {
    d := _decide("ex_fm")
    d._routing == "SUGGEST"
    contains(d.explanation, "SIŁA WYŻSZA")
}

test_p28_i12_none_suggest {
    d := _decide("ex_none")
    d._routing == "SUGGEST"
}
