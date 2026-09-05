# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P25 KALENDARZ ZBIORCZY ENTERPRISE (jdg.v3_p25_kalendarz_zbiorczy)
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice (dzień 0,
# eskalacja, przeniesienia per obowiązek).
# Uruchomienie (z katalogu JDG/):
#   ../bin/opa test tests/rego/test_v3_p25_kalendarz_zbiorczy_enterprise.rego \
#       rules/v3_p25_kalendarz_zbiorczy_enterprise.rego rules/thresholds_jdg.rego
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p25

import future.keywords.in

import data.jdg.v3_p25_kalendarz_zbiorczy

_base := {"jdg_entrepreneur": {"v3_p25_check": true}}

_cases := {
    "mdt_unknown": {"analysis": "master_deadline_table", "obligation": "ALIEN_OBLIGATION"},
    "mdt_ok": {"analysis": "master_deadline_table", "obligation": "VAT_JPK_MONTHLY"},
    "wr_unknown": {"analysis": "weekend_rollover", "obligation": "ALIEN_OBLIGATION",
                   "expected_rollover": "NEXT_BUSINESS_DAY"},
    "wr_mismatch": {"analysis": "weekend_rollover", "obligation": "VAT_JPK_MONTHLY",
                    "expected_rollover": "PREV_BUSINESS_DAY"},
    "wr_ok_shift": {"analysis": "weekend_rollover", "obligation": "ZUS_DRA_NO_EMPLOYEES",
                    "weekend_shift_detected": true},
    "wr_ok_plain": {"analysis": "weekend_rollover", "obligation": "PIT_ADVANCE_MONTHLY",
                    "weekend_shift_detected": false},
    "zs_breach": {"analysis": "zero_silence", "obligation": "VAT_JPK_MONTHLY",
                  "days_left": 0, "completed": false},
    "zs_alert1": {"analysis": "zero_silence", "obligation": "VAT_JPK_MONTHLY",
                  "days_left": 1, "completed": false},
    "zs_alert3": {"analysis": "zero_silence", "obligation": "VAT_JPK_MONTHLY",
                  "days_left": 3, "completed": false},
    "zs_alert7": {"analysis": "zero_silence", "obligation": "VAT_JPK_MONTHLY",
                  "days_left": 7, "completed": false},
    "zs_ok": {"analysis": "zero_silence", "obligation": "VAT_JPK_MONTHLY",
              "days_left": 20, "completed": false},
    "zs_constitution": {"analysis": "zero_silence", "obligation": "VAT_JPK_MONTHLY",
                        "days_left": -5, "completed": false, "block_emitted": false},
    "yr_ok": {"analysis": "year_rollover_rig", "rig_days_generated": 365,
              "missing_deadlines": 0, "rollover_count": 52, "expected_rollover_count": 52,
              "rig_complete": true},
    "yr_missing": {"analysis": "year_rollover_rig", "rig_days_generated": 365,
                   "missing_deadlines": 2, "rollover_count": 52,
                   "expected_rollover_count": 52, "rig_complete": true},
    "yr_incomplete": {"analysis": "year_rollover_rig", "rig_days_generated": 100,
                      "missing_deadlines": 0, "rollover_count": 15,
                      "expected_rollover_count": 52, "rig_complete": false},
    "sc_unknown": {"analysis": "deadline_schema", "obligation": "ALIEN_OBLIGATION"},
    "sc_ok": {"analysis": "deadline_schema", "obligation": "PIT_ANNUAL_RETURN"},
    "dd_unknown": {"analysis": "dedup_gate", "obligation": "ALIEN_OBLIGATION",
                   "source_base_day": 25},
    "dd_conflict": {"analysis": "dedup_gate", "obligation": "VAT_JPK_MONTHLY",
                    "source_base_day": 20},
    "dd_ok": {"analysis": "dedup_gate", "obligation": "VAT_JPK_MONTHLY",
              "source_base_day": 25},
    "tn_unknown": {"analysis": "tenant_calendar", "obligation": "ALIEN_OBLIGATION",
                   "tenant_id": "T1", "tenant_tax_form": "SCALE"},
    "tn_no_tenant": {"analysis": "tenant_calendar", "obligation": "VAT_JPK_MONTHLY",
                     "tenant_id": "", "tenant_tax_form": "SCALE"},
    "tn_bad_form": {"analysis": "tenant_calendar", "obligation": "VAT_JPK_MONTHLY",
                    "tenant_id": "T1", "tenant_tax_form": "ALIEN_FORM"},
    "tn_ok": {"analysis": "tenant_calendar", "obligation": "PIT_ADVANCE_MONTHLY",
              "tenant_id": "T1", "tenant_tax_form": "LUMP_SUM"},
    "wf_overload": {"analysis": "workload_forecaster", "upcoming_deadlines": 9,
                    "horizon_days": 14, "overload_threshold_pct": 80,
                    "capacity_deadlines_per_period": 10},
    "wf_ok": {"analysis": "workload_forecaster", "upcoming_deadlines": 4,
              "horizon_days": 14, "overload_threshold_pct": 80,
              "capacity_deadlines_per_period": 10},
    "ck_unknown": {"analysis": "completion_checklist", "obligation": "ALIEN_OBLIGATION",
                   "checklist_items": ["JPK_V7"]},
    "ck_partial": {"analysis": "completion_checklist", "obligation": "VAT_JPK_MONTHLY",
                   "checklist_items": ["JPK_V7"]},
    "ck_ok": {"analysis": "completion_checklist", "obligation": "VAT_JPK_MONTHLY",
              "checklist_items": ["JPK_V7", "ZAPLATA"]},
    "cl_unknown": {"analysis": "close_the_loop", "obligation": "ALIEN_OBLIGATION",
                   "loop_status": "PENDING", "days_left": 10},
    "cl_lapsed": {"analysis": "close_the_loop", "obligation": "VAT_JPK_MONTHLY",
                  "loop_status": "ACTION_SENT", "days_left": -2},
    "cl_action": {"analysis": "close_the_loop", "obligation": "VAT_JPK_MONTHLY",
                  "loop_status": "PENDING", "days_left": 2},
    "cl_done": {"analysis": "close_the_loop", "obligation": "VAT_JPK_MONTHLY",
                "loop_status": "CONFIRMED", "days_left": 10},
    "hs_nodata": {"analysis": "compliance_score", "deadlines_on_time": 0,
                  "deadlines_total": 0, "score_trend": "FLAT"},
    "hs_declining": {"analysis": "compliance_score", "deadlines_on_time": 80,
                     "deadlines_total": 100, "score_trend": "DECLINING"},
    "hs_low": {"analysis": "compliance_score", "deadlines_on_time": 85,
               "deadlines_total": 100, "score_trend": "FLAT"},
    "hs_ok": {"analysis": "compliance_score", "deadlines_on_time": 95,
              "deadlines_total": 100, "score_trend": "RISING"},
    "gs_mismatch": {"analysis": "calendar_golden_set", "case_id": "CAL-2026-002",
                    "in_golden_set": true, "expected_routing": "TRIAGE_QUEUE",
                    "actual_routing": "SUGGEST"},
    "gs_ok": {"analysis": "calendar_golden_set", "case_id": "CAL-2026-001",
              "in_golden_set": true, "expected_routing": "SUGGEST",
              "actual_routing": "SUGGEST"},
}

_decide(case) = d {
    d := v3_p25_kalendarz_zbiorczy.decide with input as object.union(_base, {"v3_p25": _cases[case]})
}

# ── Brak aktywacji → no_match ──
test_p25_no_match_without_flag {
    d := v3_p25_kalendarz_zbiorczy.decide with input as {"v3_p25": _cases["mdt_ok"]}
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.no_match"
}

# ── I01: Master Deadline Table ──
test_p25_i01_unknown_block {
    d := _decide("mdt_unknown")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.master_deadline_table"
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p25_i01_ok_suggest {
    d := _decide("mdt_ok")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.master_deadline_table"
    d._routing == "SUGGEST"
    d.master_rows == 17
    d.row.checklist == ["JPK_V7", "ZAPLATA"]
}

# ── I02: Weekend Rollover per obowiązek ──
test_p25_i02_unknown_block {
    d := _decide("wr_unknown")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.weekend_rollover"
    d._routing == "BLOCK_AND_ALERT"
}

test_p25_i02_mismatch_block {
    d := _decide("wr_mismatch")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.weekend_rollover"
    d._routing == "BLOCK_AND_ALERT"
    d.rollover_mismatch == true
}

test_p25_i02_zus_shift_triage {
    d := _decide("wr_ok_shift")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.weekend_rollover"
    d._routing == "TRIAGE_QUEUE"
    d.registered_rollover == "PREV_BUSINESS_DAY"
}

test_p25_i02_ok_suggest {
    d := _decide("wr_ok_plain")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.weekend_rollover"
    d._routing == "SUGGEST"
}

# ── I03: Zero-Silence — granice 0/1/3/7 ──
test_p25_i03_breach_block {
    d := _decide("zs_breach")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.zero_silence"
    d._routing == "BLOCK_AND_ALERT"
    d.breached == true
    d.fail_closed == true
}

test_p25_i03_alert1_triage {
    d := _decide("zs_alert1")
    d._routing == "TRIAGE_QUEUE"
    d.alert_1 == true
}

test_p25_i03_alert3_triage {
    d := _decide("zs_alert3")
    d._routing == "TRIAGE_QUEUE"
}

test_p25_i03_alert7_suggest {
    d := _decide("zs_alert7")
    d._routing == "SUGGEST"
    d.alert_7 == true
}

test_p25_i03_far_ok {
    d := _decide("zs_ok")
    d._routing == "SUGGEST"
    d.breached == false
}

test_p25_i03_constitution_violation_block {
    d := _decide("zs_constitution")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.zero_silence"
    d._routing == "BLOCK_AND_ALERT"
}

# ── I04: Year Rollover Test Rig ──
test_p25_i04_year_ok {
    d := _decide("yr_ok")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.year_rollover_rig"
    d._routing == "SUGGEST"
    d.fail_closed == false
}

test_p25_i04_missing_block {
    d := _decide("yr_missing")
    d._routing == "BLOCK_AND_ALERT"
    d.missing_deadlines == 2
}

test_p25_i04_incomplete_triage {
    d := _decide("yr_incomplete")
    d._routing == "TRIAGE_QUEUE"
}

# ── I05: Deadline Schema v1 ──
test_p25_i05_unknown_block {
    d := _decide("sc_unknown")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.deadline_schema"
    d._routing == "BLOCK_AND_ALERT"
}

test_p25_i05_ok_suggest {
    d := _decide("sc_ok")
    d._routing == "SUGGEST"
    d.schema_valid == true
    d.frequency == "ANNUAL"
}

# ── I06: Dedup Gate ──
test_p25_i06_unknown_block {
    d := _decide("dd_unknown")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.dedup_gate"
    d._routing == "BLOCK_AND_ALERT"
}

test_p25_i06_conflict_triage {
    d := _decide("dd_conflict")
    d._routing == "TRIAGE_QUEUE"
    d.day_conflict == true
}

test_p25_i06_ok_suggest {
    d := _decide("dd_ok")
    d._routing == "SUGGEST"
}

# ── I07: Tenant Calendar Layer ──
test_p25_i07_unknown_block {
    d := _decide("tn_unknown")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.tenant_calendar"
    d._routing == "BLOCK_AND_ALERT"
}

test_p25_i07_no_tenant_block {
    d := _decide("tn_no_tenant")
    d._routing == "BLOCK_AND_ALERT"
}

test_p25_i07_bad_form_block {
    d := _decide("tn_bad_form")
    d._routing == "BLOCK_AND_ALERT"
}

test_p25_i07_ok_suggest {
    d := _decide("tn_ok")
    d._routing == "SUGGEST"
    d.tenant_tax_form == "LUMP_SUM"
}

# ── I08: Workload Forecaster ──
test_p25_i08_overload_triage {
    d := _decide("wf_overload")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.workload_forecaster"
    d._routing == "TRIAGE_QUEUE"
    d.overload == true
}

test_p25_i08_ok_suggest {
    d := _decide("wf_ok")
    d._routing == "SUGGEST"
    d.load_pct == 40
}

# ── I09: Completion Checklists ──
test_p25_i09_unknown_block {
    d := _decide("ck_unknown")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.completion_checklist"
    d._routing == "BLOCK_AND_ALERT"
}

test_p25_i09_partial_triage {
    d := _decide("ck_partial")
    d._routing == "TRIAGE_QUEUE"
    d.missing_items == ["ZAPLATA"]
}

test_p25_i09_ok_suggest {
    d := _decide("ck_ok")
    d._routing == "SUGGEST"
    d.complete == true
}

# ── I10: Close-the-Loop ──
test_p25_i10_unknown_block {
    d := _decide("cl_unknown")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.close_the_loop"
    d._routing == "BLOCK_AND_ALERT"
}

test_p25_i10_lapsed_block {
    d := _decide("cl_lapsed")
    d._routing == "BLOCK_AND_ALERT"
    d.lapsed_unconfirmed == true
}

test_p25_i10_pending_action_triage {
    d := _decide("cl_action")
    d._routing == "TRIAGE_QUEUE"
}

test_p25_i10_done_suggest {
    d := _decide("cl_done")
    d._routing == "SUGGEST"
    d.confirmed == true
}

# ── I11: Compliance Score History ──
test_p25_i11_nodata_triage {
    d := _decide("hs_nodata")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.compliance_score"
    d._routing == "TRIAGE_QUEUE"
}

test_p25_i11_declining_triage {
    d := _decide("hs_declining")
    d._routing == "TRIAGE_QUEUE"
    d.score_pct == 80
}

test_p25_i11_below_target_triage {
    d := _decide("hs_low")
    d._routing == "TRIAGE_QUEUE"
}

test_p25_i11_ok_suggest {
    d := _decide("hs_ok")
    d._routing == "SUGGEST"
    d.score_pct == 95
}

# ── I12: Calendar Golden Set ──
test_p25_i12_mismatch_block {
    d := _decide("gs_mismatch")
    d.rule_id == "jdg.v3_p25_kalendarz_zbiorczy.calendar_golden_set"
    d._routing == "BLOCK_AND_ALERT"
    d.golden_match == false
}

test_p25_i12_ok_suggest {
    d := _decide("gs_ok")
    d._routing == "SUGGEST"
    d.golden_match == true
}

# ── Kontrakt certyfikatu (V2 F4) na przykładzie I03 ──
test_p25_certificate_fields_present {
    d := _decide("zs_breach")
    d["package"] == "jdg.v3_p25_kalendarz_zbiorczy"
    d.threshold_version == "kalendarz-v3p25-2026.09"
    d.priority == 425103
    d.matched == true
}
