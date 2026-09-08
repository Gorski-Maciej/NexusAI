# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P32 AUTOMATYZACJA KSIĘGOWOŚCI (jdg.v3_p32_ksiegowosc_automation)
# — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice
# (pewność 95, kolejka NEEDS_ADVICE, dryf replay, 4-eyes, granice groszowe).
# Uruchomienie (z katalogu repo):
#   ./bin/opa19 test JDG/tests/rego/test_v3_p32_ksiegowosc_automation_enterprise.rego \
#       JDG/rules/v3_p32_ksiegowosc_automation_enterprise.rego \
#       JDG/rules/thresholds_jdg.rego --v0-compatible
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p32

import data.jdg.v3_p32_ksiegowosc_automation

_base := {"jdg_entrepreneur": {"v3_p32_check": true}}

_cases := {
    # I01: auto-booking z decision certificate
    "ab_uncertified": {"analysis": "auto_booking_pipeline",
                       "auto_booking": {"transactions": [
                           {"id": "T1", "decision_certificate": "", "confidence": 99},
                           {"id": "T2", "decision_certificate": "", "confidence": 99}]}},
    "ab_low_conf": {"analysis": "auto_booking_pipeline",
                    "auto_booking": {"transactions": [
                        {"id": "T1", "decision_certificate": "CERT-1", "confidence": 80}]}},
    "ab_ok": {"analysis": "auto_booking_pipeline",
              "auto_booking": {"transactions": [
                  {"id": "T1", "decision_certificate": "CERT-1", "confidence": 97}]}},

    # I02: idempotency keys
    "id_double_posted": {"analysis": "idempotency",
                         "idempotency": {"duplicates_detected": 2, "double_posted": 1}},
    "id_dupes_only": {"analysis": "idempotency",
                      "idempotency": {"duplicates_detected": 3, "double_posted": 0}},
    "id_ok": {"analysis": "idempotency",
              "idempotency": {"duplicates_detected": 0, "double_posted": 0}},

    # I03: two-phase close month
    "cm_commit_mismatch": {"analysis": "close_month",
                           "close_month": {"phase": "commit",
                                           "ledger_mismatches": ["pkpir_vs_vat"],
                                           "approved": true}},
    "cm_commit_unapproved": {"analysis": "close_month",
                             "close_month": {"phase": "commit",
                                             "ledger_mismatches": [],
                                             "approved": false}},
    "cm_prepare_mismatch": {"analysis": "close_month",
                            "close_month": {"phase": "prepare",
                                            "ledger_mismatches": ["uor_diff"],
                                            "approved": false}},
    "cm_unknown": {"analysis": "close_month",
                   "close_month": {"phase": "unknown",
                                   "ledger_mismatches": [],
                                   "approved": false}},
    "cm_ok": {"analysis": "close_month",
              "close_month": {"phase": "commit",
                              "ledger_mismatches": [],
                              "approved": true}},

    # I04: kolejka NEEDS_ADVICE
    "na_overflow": {"analysis": "needs_advice_queue",
                    "needs_advice_queue": {"pending": 250, "clustered": true,
                                           "max_age_days": 3}},
    "na_unclustered": {"analysis": "needs_advice_queue",
                       "needs_advice_queue": {"pending": 5, "clustered": false,
                                              "max_age_days": 3}},
    "na_aged": {"analysis": "needs_advice_queue",
                "needs_advice_queue": {"pending": 5, "clustered": true,
                                       "max_age_days": 30}},
    "na_ok": {"analysis": "needs_advice_queue",
              "needs_advice_queue": {"pending": 5, "clustered": true,
                                     "max_age_days": 3}},

    # I05: reconciliation z wyciągiem bankowym
    "br_unmatched": {"analysis": "bank_reconciliation",
                     "bank_reconciliation": {"unmatched_payments": ["P1", "P2"],
                                             "amount_gap": 0}},
    "br_gap": {"analysis": "bank_reconciliation",
               "bank_reconciliation": {"unmatched_payments": [],
                                       "amount_gap": 0.05}},
    "br_ok": {"analysis": "bank_reconciliation",
              "bank_reconciliation": {"unmatched_payments": [],
                                      "amount_gap": 0}},

    # I06: granice groszowe
    "pb_hardcode": {"analysis": "penny_boundaries",
                    "penny_boundary_hardcode": true,
                    "penny_boundaries": {"calc_rules_total": 5,
                                         "rules_with_boundary_tests": 5}},
    "pb_partial": {"analysis": "penny_boundaries",
                   "penny_boundaries": {"calc_rules_total": 5,
                                        "rules_with_boundary_tests": 3}},
    "pb_ok": {"analysis": "penny_boundaries",
              "penny_boundaries": {"calc_rules_total": 5,
                                   "rules_with_boundary_tests": 5}},

    # I07: replay sezonowy
    "sr_drift_big": {"analysis": "seasonal_replay",
                     "seasonal_replay": {"decisions_total": 100, "drifted_decisions": 5}},
    "sr_drift_small": {"analysis": "seasonal_replay",
                       "seasonal_replay": {"decisions_total": 100, "drifted_decisions": 1}},
    "sr_ok": {"analysis": "seasonal_replay",
              "seasonal_replay": {"decisions_total": 100, "drifted_decisions": 0}},

    # I08: korekty pre-deadline
    "pc_window_unfixed": {"analysis": "pre_deadline_corrections",
                          "pre_deadline_corrections": {"errors_detected": 3,
                                                       "corrections_proposed": 1,
                                                       "days_to_deadline": 5}},
    "pc_window_noprop": {"analysis": "pre_deadline_corrections",
                         "pre_deadline_corrections": {"errors_detected": 2,
                                                      "corrections_proposed": 0,
                                                      "days_to_deadline": 5}},
    "pc_ok": {"analysis": "pre_deadline_corrections",
              "pre_deadline_corrections": {"errors_detected": 2,
                                           "corrections_proposed": 2,
                                           "days_to_deadline": 5}},

    # I09: przepływ 4-eyes
    "fe_unapproved": {"analysis": "four_eyes",
                      "four_eyes": {"events": [
                          {"id": "E1", "approval_second_person": false}]}},
    "fe_ok": {"analysis": "four_eyes",
              "four_eyes": {"events": [
                  {"id": "E1", "approval_second_person": true}]}},

    # I10: traceability dokument → decyzja → archiwum
    "dt_broken": {"analysis": "document_traceability",
                  "document_traceability": {"documents": [
                      {"id": "D1", "stages_complete": false}]}},
    "dt_ok": {"analysis": "document_traceability",
              "document_traceability": {"documents": [
                  {"id": "D1", "stages_complete": true}]}},

    # I11: limity automatyzacji jako dane
    "al_hardcode": {"analysis": "automation_limits",
                    "automation_hardcode_detected": true,
                    "automation_limits": {"auto_domains_configured": 4}},
    "al_empty": {"analysis": "automation_limits",
                 "automation_limits": {"auto_domains_configured": 0}},
    "al_ok": {"analysis": "automation_limits",
              "automation_limits": {"auto_domains_configured": 4}},

    # I12: backpressure na awarie zewnętrzne
    "bp_risk_online": {"analysis": "external_backpressure",
                       "external_backpressure": {"offline_mode": false,
                                                 "queued_items": 0,
                                                 "deadline_risk_items": 3}},
    "bp_offline_noqueue": {"analysis": "external_backpressure",
                           "external_backpressure": {"offline_mode": true,
                                                     "queued_items": 0,
                                                     "deadline_risk_items": 3}},
    "bp_offline_noreport": {"analysis": "external_backpressure",
                            "external_backpressure": {"offline_mode": true,
                                                      "queued_items": 10,
                                                      "deadline_risk_items": 2,
                                                      "compliance_report_generated": false}},
    "bp_ok": {"analysis": "external_backpressure",
              "external_backpressure": {"offline_mode": true,
                                        "queued_items": 10,
                                        "deadline_risk_items": 2,
                                        "compliance_report_generated": true}},
}

_decide(case) = d {
    d := v3_p32_ksiegowosc_automation.decide with input as object.union(_base, {"v3_p32": _cases[case]})
}

# ── Brak aktywacji → no_match ──
test_p32_no_match_without_flag {
    d := v3_p32_ksiegowosc_automation.decide with input as {"v3_p32": _cases["ab_ok"]}
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.no_match"
}

# ── I01: Auto-Booking Pipeline ──
test_p32_i01_uncertified_block {
    d := _decide("ab_uncertified")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.auto_booking_pipeline"
    d._routing == "BLOCK_AND_ALERT"
    d.transactions_uncertified == 2
}

test_p32_i01_low_confidence_triage {
    d := _decide("ab_low_conf")
    d._routing == "TRIAGE_QUEUE"
    d.transactions_low_confidence == 1
}

test_p32_i01_ok {
    d := _decide("ab_ok")
    d._routing == "SUGGEST"
    d.transactions_total == 1
}

# ── I02: Idempotency Keys ──
test_p32_i02_double_posted_block {
    d := _decide("id_double_posted")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.idempotency_keys"
    d._routing == "BLOCK_AND_ALERT"
    d.double_posted == 1
}

test_p32_i02_dupes_triage {
    d := _decide("id_dupes_only")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i02_ok {
    d := _decide("id_ok")
    d._routing == "SUGGEST"
}

# ── I03: Two-Phase Close Month ──
test_p32_i03_commit_mismatch_block {
    d := _decide("cm_commit_mismatch")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.two_phase_close_month"
    d._routing == "BLOCK_AND_ALERT"
}

test_p32_i03_commit_unapproved_block {
    d := _decide("cm_commit_unapproved")
    d._routing == "BLOCK_AND_ALERT"
}

test_p32_i03_prepare_mismatch_triage {
    d := _decide("cm_prepare_mismatch")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i03_unknown_phase_triage {
    d := _decide("cm_unknown")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i03_ok {
    d := _decide("cm_ok")
    d._routing == "SUGGEST"
    d.phase == "commit"
}

# ── I04: Kolejka NEEDS_ADVICE ──
test_p32_i04_overflow_block {
    d := _decide("na_overflow")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.needs_advice_queue"
    d._routing == "BLOCK_AND_ALERT"
}

test_p32_i04_unclustered_triage {
    d := _decide("na_unclustered")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i04_aged_triage {
    d := _decide("na_aged")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i04_ok {
    d := _decide("na_ok")
    d._routing == "SUGGEST"
}

# ── I05: Reconciliation z wyciągiem bankowym ──
test_p32_i05_unmatched_block {
    d := _decide("br_unmatched")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.bank_reconciliation"
    d._routing == "BLOCK_AND_ALERT"
}

test_p32_i05_gap_triage {
    d := _decide("br_gap")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i05_ok {
    d := _decide("br_ok")
    d._routing == "SUGGEST"
}

# ── I06: Granice groszowe ──
test_p32_i06_hardcode_block {
    d := _decide("pb_hardcode")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.penny_boundary_tests"
    d._routing == "BLOCK_AND_ALERT"
}

test_p32_i06_partial_triage {
    d := _decide("pb_partial")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i06_ok {
    d := _decide("pb_ok")
    d._routing == "SUGGEST"
}

# ── I07: Replay sezonowy ──
test_p32_i07_big_drift_block {
    d := _decide("sr_drift_big")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.seasonal_replay"
    d._routing == "BLOCK_AND_ALERT"
}

# granica TRIAGE: dryf > limitu, ale ≤ 10× limitu (limit podbity do 1)
test_p32_i07_small_drift_triage {
    d := data.jdg.v3_p32_ksiegowosc_automation.decide with input as object.union(_base, {"v3_p32": _cases["sr_drift_big"]}) with data.jdg.thresholds.v3_p32 as {"v3_p32_replay_drift_max": 1}
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i07_ok {
    d := _decide("sr_ok")
    d._routing == "SUGGEST"
}

# ── I08: Korekty pre-deadline ──
test_p32_i08_unfixed_triage {
    d := _decide("pc_window_unfixed")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.pre_deadline_corrections"
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i08_no_proposals_triage {
    d := _decide("pc_window_noprop")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i08_ok {
    d := _decide("pc_ok")
    d._routing == "SUGGEST"
}

# ── I09: Przepływ 4-eyes ──
test_p32_i09_unapproved_block {
    d := _decide("fe_unapproved")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.four_eyes_flow"
    d._routing == "BLOCK_AND_ALERT"
    d.threshold_amount == 5000
}

test_p32_i09_ok {
    d := _decide("fe_ok")
    d._routing == "SUGGEST"
}

# ── I10: Traceability dokument → decyzja → archiwum ──
# granica BLOCK: limit 0 — każdy zerwany łańcuch = BLOCK (domyślny próg)
test_p32_i10_broken_block {
    d := _decide("dt_broken")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.document_traceability"
    d._routing == "BLOCK_AND_ALERT"
}

# granica TRIAGE: limit podbity do 2 — jeden zerwany łańcuch = TRIAGE
test_p32_i10_broken_triage {
    d := data.jdg.v3_p32_ksiegowosc_automation.decide with input as object.union(_base, {"v3_p32": _cases["dt_broken"]}) with data.jdg.thresholds.v3_p32 as {"v3_p32_trace_broken_max": 2}
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i10_ok {
    d := _decide("dt_ok")
    d._routing == "SUGGEST"
}

# ── I11: Limity automatyzacji jako dane ──
test_p32_i11_hardcode_block {
    d := _decide("al_hardcode")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.automation_limits"
    d._routing == "BLOCK_AND_ALERT"
}

test_p32_i11_empty_triage {
    d := _decide("al_empty")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i11_ok {
    d := _decide("al_ok")
    d._routing == "SUGGEST"
}

# ── I12: Backpressure na awarie zewnętrzne ──
test_p32_i12_risk_online_block {
    d := _decide("bp_risk_online")
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.external_backpressure"
    d._routing == "BLOCK_AND_ALERT"
}

test_p32_i12_offline_noqueue_triage {
    d := _decide("bp_offline_noqueue")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i12_offline_noreport_triage {
    d := _decide("bp_offline_noreport")
    d._routing == "TRIAGE_QUEUE"
}

test_p32_i12_ok {
    d := _decide("bp_ok")
    d._routing == "SUGGEST"
}

# ── Fail-closed: brak snapshotu progów ──
test_p32_fail_closed_no_snapshot {
    d := data.jdg.v3_p32_ksiegowosc_automation.decide with input as {"jdg_entrepreneur": {"v3_p32_check": true}, "v3_p32": _cases["ab_ok"]} with data.jdg.thresholds.v3_p32 as {}
    d.rule_id == "jdg.v3_p32_ksiegowosc_automation.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}
