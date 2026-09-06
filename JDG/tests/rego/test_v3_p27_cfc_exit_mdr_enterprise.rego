# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P27 CFC, EXIT TAX, MDR I PRZEPŁYWY (jdg.v3_p27_cfc_exit_mdr)
# Pokrycie: 13 analiz I01-I13 — ścieżki fail-closed (BLOCK_AND_ALERT),
# NEEDS_ADVICE, TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice
# (2M/4M exit tax ±0,01, 30 dni MDR, T-7, human review, progi CFC, golden).
# Uruchomienie (z katalogu JDG/):
#   ../bin/opa test tests/rego/test_v3_p27_cfc_exit_mdr_enterprise.rego \
#       rules/v3_p27_cfc_exit_mdr_enterprise.rego rules/thresholds_jdg.rego
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p27

import data.jdg.v3_p27_cfc_exit_mdr

_base := {"jdg_entrepreneur": {"v3_p27_check": true}}

_cases := {
    # I01: rejestr decyzji
    "adr_ok": {"analysis": "architecture_decision_register"},

    # I02: exit tax signal monitor
    "et_residence": {"analysis": "exit_tax_signal_monitor",
                     "exit_tax_signal": "RESIDENCE",
                     "transferred_assets_value_pln": 3000000,
                     "assets_tax_value_pln": 1000000},
    "et_neutral": {"analysis": "exit_tax_signal_monitor",
                   "exit_tax_signal": "NEUTRAL"},

    # I03: threshold verifier
    "tv_ok": {"analysis": "exit_tax_threshold_verifier",
              "verified_property_threshold_pln": 2000000,
              "verified_total_threshold_pln": 4000000,
              "verifier_version": "v3p27-verify-2026.09"},
    "tv_drift_property": {"analysis": "exit_tax_threshold_verifier",
                          "verified_property_threshold_pln": 2000000.02,
                          "verified_total_threshold_pln": 4000000,
                          "verifier_version": "v3p27-verify-2026.09"},
    "tv_drift_total": {"analysis": "exit_tax_threshold_verifier",
                       "verified_property_threshold_pln": 2000000,
                       "verified_total_threshold_pln": 4000001,
                       "verifier_version": "v3p27-verify-2026.09"},
    "tv_stale_version": {"analysis": "exit_tax_threshold_verifier",
                         "verified_property_threshold_pln": 2000000,
                         "verified_total_threshold_pln": 4000000,
                         "verifier_version": "host-2025"},
    "tv_missing": {"analysis": "exit_tax_threshold_verifier"},

    # I04: MDR hallmark scorer v2
    "hm_unknown": {"analysis": "mdr_hallmark_scorer_v2",
                   "hallmark_category": "ALIEN", "hallmark_score": 90},
    "hm_block": {"analysis": "mdr_hallmark_scorer_v2",
                 "hallmark_category": "GENERIC_A", "hallmark_score": 90,
                 "mdr_human_approved": false},
    "hm_ok": {"analysis": "mdr_hallmark_scorer_v2",
              "hallmark_category": "GENERIC_A", "hallmark_score": 90,
              "mdr_human_approved": true},
    "hm_low": {"analysis": "mdr_hallmark_scorer_v2",
               "hallmark_category": "SPECIFIC_D", "hallmark_score": 30},

    # I05: MDR 30-day gate
    "md_overdue": {"analysis": "mdr_30day_gate",
                   "mdr_trigger_ts": 1757000000000000000,
                   "mdr_due_ts": 1756000000000000000},
    "md_warn": {"analysis": "mdr_30day_gate",
                "mdr_trigger_ts": 1757000000000000000,
                "mdr_due_ts": 1757040000000000000},
    "md_ok": {"analysis": "mdr_30day_gate",
              "mdr_trigger_ts": 1757000000000000000,
              "mdr_due_ts": 1760000000000000000},
    "md_no_data": {"analysis": "mdr_30day_gate"},

    # I06: MDR auxiliary function
    "af_aux_excl": {"analysis": "mdr_auxiliary_function",
                    "is_auxiliary_function": true},
    "af_below": {"analysis": "mdr_auxiliary_function",
                 "beneficiary_eur": 5000000, "arrangement_value_eur": 1000000},
    "af_above": {"analysis": "mdr_auxiliary_function",
                 "beneficiary_eur": 20000000, "arrangement_value_eur": 3000000},

    # I07: CFC signal detector
    "cf_none": {"analysis": "cfc_signal_detector",
                "foreign_ownership_pct": 10, "passive_income_pct": 20},
    "cf_eea": {"analysis": "cfc_signal_detector",
               "foreign_ownership_pct": 40, "passive_income_pct": 60,
               "small_taxpayer_eea_exemption": true},
    "cf_signal": {"analysis": "cfc_signal_detector",
                  "foreign_ownership_pct": 40, "passive_income_pct": 60},

    # I08: invariants pack
    "iv_mdr_auto": {"analysis": "international_invariants_pack",
                    "mdr_auto_report_attempt": true},
    "iv_exit_auto": {"analysis": "international_invariants_pack",
                     "exit_tax_auto_declaration_attempt": true},
    "iv_cfc_auto": {"analysis": "international_invariants_pack",
                    "cfc_auto_tax_calculation_attempt": true},
    "iv_ok": {"analysis": "international_invariants_pack"},

    # I09: exit tax documentation
    "dx_unknown_method": {"analysis": "exit_tax_documentation",
                          "valuation_method": "MAGIC"},
    "dx_incomplete": {"analysis": "exit_tax_documentation",
                      "valuation_method": "MARKET_COMPARABLE",
                      "valuation_docs_attached": true,
                      "expert_opinion_attached": false},
    "dx_ok": {"analysis": "exit_tax_documentation",
              "valuation_method": "MARKET_COMPARABLE",
              "valuation_docs_attached": true,
              "expert_opinion_attached": true},

    # I10: ruling path advisor
    "ru_none": {"analysis": "ruling_path_advisor"},
    "ru_considered": {"analysis": "ruling_path_advisor",
                      "ruling_request_considered": true},
    "ru_draft": {"analysis": "ruling_path_advisor",
                 "ruling_request_considered": true,
                 "ruling_draft_requested": true},

    # I11: golden international set
    "gs_unknown": {"analysis": "golden_international_set",
                   "golden_rows": [{"kind": "ALIEN_KIND", "value": 1}]},
    "gs_fail": {"analysis": "golden_international_set",
                "golden_rows": [{"kind": "EXIT_TAX_PROPERTY_2M", "value": 2000001},
                                {"kind": "EXIT_TAX_TOTAL_4M", "value": 4000000},
                                {"kind": "MDR_30D", "value": 30},
                                {"kind": "RESIDENCY_183D", "value": 183}]},
    "gs_ok": {"analysis": "golden_international_set",
              "golden_rows": [{"kind": "EXIT_TAX_PROPERTY_2M", "value": 2000000},
                              {"kind": "EXIT_TAX_TOTAL_4M", "value": 4000000},
                              {"kind": "MDR_30D", "value": 30},
                              {"kind": "RESIDENCY_183D", "value": 183},
                              {"kind": "CFC_DE_MINIMIS", "value": 250000}]},
    "gs_empty": {"analysis": "golden_international_set", "golden_rows": []},

    # I12: stress lab
    "sl_incomplete": {"analysis": "international_stress_lab",
                      "stress_results": [{"scenario": "RESIDENCE_MIDYEAR",
                                          "passed": true}]},
    "sl_failing": {"analysis": "international_stress_lab",
                   "stress_results": [{"scenario": "RESIDENCE_MIDYEAR", "passed": true},
                                      {"scenario": "MDR_DEADLINE_WEEKEND", "passed": true},
                                      {"scenario": "THRESHOLD_BOUNDARY", "passed": false}]},
    "sl_ok": {"analysis": "international_stress_lab",
              "stress_results": [{"scenario": "RESIDENCE_MIDYEAR", "passed": true},
                                 {"scenario": "MDR_DEADLINE_WEEKEND", "passed": true},
                                 {"scenario": "THRESHOLD_BOUNDARY", "passed": true}]},

    # I13: cross-domain flow gate
    "xf_gaps": {"analysis": "cross_domain_flow_gate"},
    "xf_ok": {"analysis": "cross_domain_flow_gate",
              "fx_d1_applied": true, "calendar_p25_linked": true,
              "p17_interest_engine_linked": true, "aml_p22_screened": true},
}

_decide(case) = d {
    d := v3_p27_cfc_exit_mdr.decide with input as object.union(_base, {"v3_p27": _cases[case]})
}

# ── Brak aktywacji → no_match ──
test_p27_no_match_without_flag {
    d := v3_p27_cfc_exit_mdr.decide with input as {"v3_p27": _cases["adr_ok"]}
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.no_match"
}

# ── I01: Architecture Decision Register ──
test_p27_i01_register {
    d := _decide("adr_ok")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.architecture_decision_register"
    d._routing == "SUGGEST"
    d.register.CFC.decision == "IN_SCOPE_JDG_AS_SIGNAL"
    d.register.EXIT_TAX.decision == "IN_SCOPE_JDG_AS_MONITORING"
    d.register.PAIN.decision == "OUT_OF_SCOPE_JDG"
    d.register.RULINGS.decision == "IN_SCOPE_JDG_AS_ADVISORY_PATH"
    d.register.MDR.decision == "IN_SCOPE_JDG_AS_CHECKLIST_HUMAN_REVIEW"
    d.p44_input == true
}

# ── I02: Exit Tax Signal Monitor — zawsze NEEDS_ADVICE ──
test_p27_i02_residence_needs_advice {
    d := _decide("et_residence")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.exit_tax_signal_monitor"
    d._routing == "NEEDS_ADVICE"
    d.auto_declaration == false
    d.property_threshold_pln == 2000000
    d.total_assets_threshold_pln == 4000000
    d.reinvestment_lock_years == 5
}

test_p27_i02_neutral_suggest {
    d := _decide("et_neutral")
    d._routing == "SUGGEST"
}

# ── I03: Threshold Verifier — granice ±0,01 / drift ──
test_p27_i03_ok {
    d := _decide("tv_ok")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.exit_tax_threshold_verifier"
    d._routing == "SUGGEST"
}

test_p27_i03_drift_property_block {
    d := _decide("tv_drift_property")
    d._routing == "BLOCK_AND_ALERT"
    d.property_diff > 0
    d.property_diff < 1
}

test_p27_i03_drift_total_block {
    d := _decide("tv_drift_total")
    d._routing == "BLOCK_AND_ALERT"
}

test_p27_i03_stale_version_triage {
    d := _decide("tv_stale_version")
    d._routing == "TRIAGE_QUEUE"
}

test_p27_i03_missing_triage {
    d := _decide("tv_missing")
    d._routing == "TRIAGE_QUEUE"
}

# ── I04: MDR Hallmark Scorer v2 — human review ──
test_p27_i04_unknown_triage {
    d := _decide("hm_unknown")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.mdr_hallmark_scorer_v2"
    d._routing == "TRIAGE_QUEUE"
}

test_p27_i04_no_human_block {
    d := _decide("hm_block")
    d._routing == "BLOCK_AND_ALERT"
    d.auto_report == false
    d.human_review_required == true
}

test_p27_i04_human_ok {
    d := _decide("hm_ok")
    d._routing == "SUGGEST"
}

test_p27_i04_low_score {
    d := _decide("hm_low")
    d._routing == "SUGGEST"
    d.human_review_required == false
}

# ── I05: MDR 30-Day Gate ──
test_p27_i05_overdue_block {
    d := _decide("md_overdue")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.mdr_30day_gate"
    d._routing == "BLOCK_AND_ALERT"
}

test_p27_i05_t7_warn_triage {
    d := _decide("md_warn")
    d._routing == "TRIAGE_QUEUE"
}

test_p27_i05_ok_suggest {
    d := _decide("md_ok")
    d._routing == "SUGGEST"
    d.deadline_window_days == 30
}

test_p27_i05_no_data_triage {
    d := _decide("md_no_data")
    d._routing == "TRIAGE_QUEUE"
}

# ── I06: MDR Auxiliary Function ──
test_p27_i06_auxiliary_needs_advice {
    d := _decide("af_aux_excl")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.mdr_auxiliary_function"
    d._routing == "NEEDS_ADVICE"
}

test_p27_i06_below_criteria {
    d := _decide("af_below")
    d._routing == "SUGGEST"
    d.below_qualified_beneficiary == true
}

test_p27_i06_above_criteria {
    d := _decide("af_above")
    d._routing == "NEEDS_ADVICE"
}

# ── I07: CFC Signal Detector — tylko NEEDS_ADVICE ──
test_p27_i07_no_signal {
    d := _decide("cf_none")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.cfc_signal_detector"
    d._routing == "SUGGEST"
    d.auto_tax_calculation == false
}

test_p27_i07_eea_exemption {
    d := _decide("cf_eea")
    d._routing == "SUGGEST"
}

test_p27_i07_signal_needs_advice {
    d := _decide("cf_signal")
    d._routing == "NEEDS_ADVICE"
    d.auto_tax_calculation == false
}

# ── I08: International Invariants Pack ──
test_p27_i08_mdr_auto_block {
    d := _decide("iv_mdr_auto")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.international_invariants_pack"
    d._routing == "BLOCK_AND_ALERT"
}

test_p27_i08_exit_auto_block {
    d := _decide("iv_exit_auto")
    d._routing == "BLOCK_AND_ALERT"
}

test_p27_i08_cfc_auto_block {
    d := _decide("iv_cfc_auto")
    d._routing == "BLOCK_AND_ALERT"
}

test_p27_i08_ok {
    d := _decide("iv_ok")
    d._routing == "SUGGEST"
    count(d.invariants) == 4
}

# ── I09: Exit Tax Documentation ──
test_p27_i09_unknown_method_triage {
    d := _decide("dx_unknown_method")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.exit_tax_documentation"
    d._routing == "TRIAGE_QUEUE"
}

test_p27_i09_incomplete_needs_advice {
    d := _decide("dx_incomplete")
    d._routing == "NEEDS_ADVICE"
    d.checklist_complete == false
}

test_p27_i09_ok {
    d := _decide("dx_ok")
    d._routing == "SUGGEST"
    d.checklist_complete == true
}

# ── I10: Ruling Path Advisor ──
test_p27_i10_none {
    d := _decide("ru_none")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.ruling_path_advisor"
    d._routing == "SUGGEST"
    d.auto_filing == false
}

test_p27_i10_considered {
    d := _decide("ru_considered")
    d._routing == "NEEDS_ADVICE"
}

test_p27_i10_draft {
    d := _decide("ru_draft")
    d._routing == "SUGGEST"
}

# ── I11: Golden International Set ──
test_p27_i11_unknown_triage {
    d := _decide("gs_unknown")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.international_golden_set"
    d._routing == "TRIAGE_QUEUE"
}

test_p27_i11_mismatch_block {
    d := _decide("gs_fail")
    d._routing == "BLOCK_AND_ALERT"
    d.rows_failed == 1
}

test_p27_i11_ok {
    d := _decide("gs_ok")
    d._routing == "SUGGEST"
    d.rows_checked == 5
    d.rows_failed == 0
}

test_p27_i11_empty_triage {
    d := _decide("gs_empty")
    d._routing == "TRIAGE_QUEUE"
}

# ── I12: International Stress Lab ──
test_p27_i12_incomplete_triage {
    d := _decide("sl_incomplete")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.international_stress_lab"
    d._routing == "TRIAGE_QUEUE"
}

test_p27_i12_failing_block {
    d := _decide("sl_failing")
    d._routing == "BLOCK_AND_ALERT"
    d.failed == 1
}

test_p27_i12_ok {
    d := _decide("sl_ok")
    d._routing == "SUGGEST"
    d.results == 3
    d.failed == 0
    d.scenarios_known == 3
}

# ── I13: Cross-Domain Flow Gate ──
test_p27_i13_gaps_triage {
    d := _decide("xf_gaps")
    d.rule_id == "jdg.v3_p27_cfc_exit_mdr.cross_domain_flow_gate"
    d._routing == "TRIAGE_QUEUE"
    count(d.harmonization_gaps) == 4
}

test_p27_i13_ok {
    d := _decide("xf_ok")
    d._routing == "SUGGEST"
    count(d.harmonization_gaps) == 0
}
