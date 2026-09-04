# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P17 ORDYNACJA OBRONA ENTERPRISE (jdg.v3_p17_ordynacja_obrona)
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match).
# Uruchomienie (z katalogu JDG/):
#   ../bin/opa test tests/rego/test_v3_p17_ordynacja_obrona_enterprise.rego \
#       rules/v3_p17_ordynacja_obrona_enterprise.rego rules/thresholds_jdg.rego
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p17

import future.keywords.in

import data.jdg.v3_p17_ordynacja_obrona

_base := {"jdg_entrepreneur": {"v3_p17_check": true}}

_cases := {
    "interest_precision_engine": {"analysis": "interest_precision_engine",
                                  "principal_pln": 1000.0, "days": 60, "months": 2,
                                  "capitalization_active": true,
                                  "arrears_since": "2020-01-01"},
    "interest_precision_engine_ok": {"analysis": "interest_precision_engine",
                                     "principal_pln": 1000.0, "days": 60, "months": 2,
                                     "capitalization_active": true,
                                     "arrears_since": "2023-05-01"},
    "limitation_sentinel": {"analysis": "limitation_sentinel", "assessment_year": 2021,
                            "suspension_events": 1, "suspension_days": 0,
                            "days_left_to_end": -5},
    "limitation_sentinel_ok": {"analysis": "limitation_sentinel", "assessment_year": 2021,
                               "suspension_events": 1, "suspension_days": 0,
                               "days_left_to_end": 200},
    "limitation_sentinel_unknown": {"analysis": "limitation_sentinel"},
    "gaar_shield": {"analysis": "gaar_shield", "benefit_pln": 2500000.0,
                    "concealment": true, "substance_score": 90,
                    "value_added_documented": true, "business_rationale_documented": true,
                    "artificial_steps": 0},
    "gaar_shield_mae": {"analysis": "gaar_shield", "benefit_pln": 500000.0,
                        "concealment": false, "substance_score": 80,
                        "value_added_documented": true, "business_rationale_documented": true,
                        "artificial_steps": 0},
    "deadline_constitution": {"analysis": "deadline_constitution",
                              "deadline_type": "SKARGA_WSA_30", "days_left": 0,
                              "response_sent": false},
    "deadline_constitution_ok": {"analysis": "deadline_constitution",
                                 "deadline_type": "STANOWISKO_7", "days_left": 5,
                                 "response_sent": true},
    "deadline_constitution_unknown": {"analysis": "deadline_constitution",
                                      "deadline_type": "COS_INNEGO", "days_left": 5,
                                      "response_sent": false},
    "correction_advisor": {"analysis": "correction_advisor", "proceeding_started": false,
                           "correction_ready": true, "correction_filed": true,
                           "correction_audited": false, "deadline_days_left": 10},
    "correction_advisor_ok": {"analysis": "correction_advisor", "proceeding_started": false,
                              "correction_ready": true, "correction_filed": false,
                              "correction_audited": true, "deadline_days_left": 10},
    "aud_tracker": {"analysis": "aud_tracker", "disclosure_made": true,
                    "before_proceeding_started": false, "payment_completed": false,
                    "conditions_met": false, "benefit_claimed": true,
                    "violation_detected": false},
    "aud_tracker_ok": {"analysis": "aud_tracker", "disclosure_made": true,
                       "before_proceeding_started": true, "payment_completed": true,
                       "conditions_met": true, "benefit_claimed": true,
                       "violation_detected": false},
    "ruling_4eyes": {"analysis": "ruling_4eyes", "draft_complete": true,
                     "legal_basis_present": true, "facts_present": true,
                     "position_present": true, "fee_paid": true,
                     "reviewer_assigned": false, "submitted": true},
    "ruling_4eyes_ok": {"analysis": "ruling_4eyes", "draft_complete": true,
                        "legal_basis_present": true, "facts_present": true,
                        "position_present": true, "fee_paid": true,
                        "reviewer_assigned": true, "submitted": false},
    "proceeding_timeline": {"analysis": "proceeding_timeline", "stage": "POSTEPOWANIE",
                            "days_since_last_event": 9, "next_deadline_days": 14,
                            "evidence_attached": true, "response_sent": false},
    "proceeding_timeline_ok": {"analysis": "proceeding_timeline", "stage": "POSTEPOWANIE",
                               "days_since_last_event": 1, "next_deadline_days": 10,
                               "evidence_attached": true, "response_sent": true},
    "proceeding_timeline_unknown": {"analysis": "proceeding_timeline", "stage": "COS",
                                    "days_since_last_event": 1, "next_deadline_days": 10,
                                    "evidence_attached": true, "response_sent": true},
    "defense_packet": {"analysis": "defense_packet", "case_type": "APELACJA",
                       "response_drafted": true, "documents_collected": false,
                       "evidence_indexed": false, "advisor_reviewed": true,
                       "filing_ready": true},
    "defense_packet_ok": {"analysis": "defense_packet", "case_type": "APELACJA",
                          "response_drafted": true, "documents_collected": true,
                          "evidence_indexed": true, "advisor_reviewed": true,
                          "filing_ready": false},
    "interpretation_library": {"analysis": "interpretation_library",
                               "provision": "art. 119a OrdPU", "lookup_hit": true,
                               "interpretation_valid": true, "law_changed": true,
                               "ruling_id": "147-KD"},
    "interpretation_library_ok": {"analysis": "interpretation_library",
                                  "provision": "art. 119a OrdPU", "lookup_hit": true,
                                  "interpretation_valid": true, "law_changed": false,
                                  "ruling_id": "147-KD"},
    "ord_invariants": {"analysis": "ord_invariants", "computed_interest_pln": -2.0,
                       "limitation_end_year": 2025, "assessment_year": 2021,
                       "correction_present": true, "correction_audited": false},
    "ord_invariants_ok": {"analysis": "ord_invariants", "computed_interest_pln": 10.0,
                          "limitation_end_year": 2027, "assessment_year": 2021,
                          "correction_present": false, "correction_audited": true},
    "litigation_stress_lab": {"analysis": "litigation_stress_lab", "scenario": "last_day_appeal",
                              "days_left": 0, "response_sent": false},
    "litigation_stress_lab_ok": {"analysis": "litigation_stress_lab", "scenario": "interest_10y",
                                 "months": 120, "principal_pln": 10000.0},
    "litigation_stress_lab_unknown": {"analysis": "litigation_stress_lab",
                                      "scenario": "cos_nowego"},
}

_decide(case) = d {
    d := v3_p17_ordynacja_obrona.decide with input as object.union(_base, {"v3_p17": _cases[case]})
}

# ── I01: Interest Precision Engine — retro przed valid_from → BLOCK ──
test_p17_i01_retro_block {
    d := _decide("interest_precision_engine")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.interest_precision_engine"
    d._routing == "BLOCK_AND_ALERT"
    d.retro_active == true
}

test_p17_i01_ok_suggest {
    d := _decide("interest_precision_engine_ok")
    d._routing == "SUGGEST"
    d.retro_active == false
    d.interest_rounded_pln > 0
    d.round_ok == true
}

# ── I02: Limitation Sentinel — przedawnienie minęło → BLOCK ──
test_p17_i02_expired_block {
    d := _decide("limitation_sentinel")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.limitation_sentinel"
    d._routing == "BLOCK_AND_ALERT"
    d.limitation_expired == true
}

test_p17_i02_ok_suggest {
    d := _decide("limitation_sentinel_ok")
    d._routing == "SUGGEST"
    d.statutory_end_year == 2026
    d.limitation_expired == false
}

test_p17_i02_unknown_block {
    d := _decide("limitation_sentinel_unknown")
    d._routing == "BLOCK_AND_ALERT"
    d.unknown == true
}

# ── I03: GAAR Shield — ukrycie + korzyść ≥ MAE → BLOCK (ochrona, nie wina) ──
test_p17_i03_concealment_block {
    d := _decide("gaar_shield")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.gaar_shield_framework"
    d._routing == "BLOCK_AND_ALERT"
    d.risk_score == 4
    d.protective == true
}

test_p17_i03_mae_suggest {
    d := _decide("gaar_shield_mae")
    d._routing == "SUGGEST"
    d.mae_excluded == true
}

# ── I04: Deadline Constitution — termin minął bez reakcji → BLOCK (zero ciszy) ──
test_p17_i04_breach_block {
    d := _decide("deadline_constitution")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.procedural_deadline_constitution"
    d._routing == "BLOCK_AND_ALERT"
    d.breached == true
}

test_p17_i04_ok_suggest {
    d := _decide("deadline_constitution_ok")
    d._routing == "SUGGEST"
    d.breached == false
}

test_p17_i04_unknown_block {
    d := _decide("deadline_constitution_unknown")
    d._routing == "BLOCK_AND_ALERT"
    d.unknown == true
}

# ── I05: Active Correction Advisor — korekta bez audytu → BLOCK (invariant) ──
test_p17_i05_no_audit_block {
    d := _decide("correction_advisor")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.active_correction_advisor"
    d._routing == "BLOCK_AND_ALERT"
}

test_p17_i05_ok_suggest {
    d := _decide("correction_advisor_ok")
    d._routing == "SUGGEST"
    d.correction_filed == false
}

# ── I06: AUD Benefit Tracker — benefit bez warunków → BLOCK ──
test_p17_i06_unjustified_block {
    d := _decide("aud_tracker")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.aud_benefit_tracker"
    d._routing == "BLOCK_AND_ALERT"
}

test_p17_i06_ok_suggest {
    d := _decide("aud_tracker_ok")
    d._routing == "SUGGEST"
    d.benefit_active == true
}

# ── I07: Ruling Autodrafter 4-Eyes — wysyłka bez review → BLOCK ──
test_p17_i07_no_4eyes_block {
    d := _decide("ruling_4eyes")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.ruling_autodrafter_4eyes"
    d._routing == "BLOCK_AND_ALERT"
}

test_p17_i07_ok_suggest {
    d := _decide("ruling_4eyes_ok")
    d._routing == "SUGGEST"
    d.formal_complete == true
    d.submitted == false
}

# ── I08: Proceeding Timeline — cisza → BLOCK (zero ciszy) ──
test_p17_i08_silence_block {
    d := _decide("proceeding_timeline")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.proceeding_timeline"
    d._routing == "BLOCK_AND_ALERT"
    d.silence_breach == true
}

test_p17_i08_ok_suggest {
    d := _decide("proceeding_timeline_ok")
    d._routing == "SUGGEST"
    d.stage_known == true
}

test_p17_i08_unknown_block {
    d := _decide("proceeding_timeline_unknown")
    d._routing == "BLOCK_AND_ALERT"
    d.stage_known == false
}

# ── I09: Defense Packet — wysyłka niekompletnej paczki → BLOCK ──
test_p17_i09_incomplete_block {
    d := _decide("defense_packet")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.defense_packet_generator"
    d._routing == "BLOCK_AND_ALERT"
    d.packet_complete == false
}

test_p17_i09_ok_suggest {
    d := _decide("defense_packet_ok")
    d._routing == "SUGGEST"
    d.packet_complete == true
}

# ── I10: Interpretation Library — zmiana prawa → TRIAGE (utrata ochrony) ──
test_p17_i10_law_change_triage {
    d := _decide("interpretation_library")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.interpretation_library"
    d._routing == "TRIAGE_QUEUE"
    d.protection_active == false
}

test_p17_i10_ok_suggest {
    d := _decide("interpretation_library_ok")
    d._routing == "SUGGEST"
    d.protection_active == true
}

# ── I11: ORD Invariants Pack — naruszenie invariantu → BLOCK ──
test_p17_i11_violations_block {
    d := _decide("ord_invariants")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.ord_invariants_pack"
    d._routing == "BLOCK_AND_ALERT"
    "ORD_INV-001" in d.violations
    "ORD_INV-003" in d.violations
}

test_p17_i11_ok_suggest {
    d := _decide("ord_invariants_ok")
    d._routing == "SUGGEST"
    count(d.violations) == 0
}

# ── I12: Litigation Stress Lab — apelacja w ostatnim dniu bez reakcji → BLOCK ──
test_p17_i12_last_day_block {
    d := _decide("litigation_stress_lab")
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.litigation_stress_lab"
    d._routing == "BLOCK_AND_ALERT"
    d.last_day_appeal_blocked == true
}

test_p17_i12_ok_suggest {
    d := _decide("litigation_stress_lab_ok")
    d._routing == "SUGGEST"
    d.interest_10y_ok == true
}

test_p17_i12_unknown_block {
    d := _decide("litigation_stress_lab_unknown")
    d._routing == "BLOCK_AND_ALERT"
    d.scenario_known == false
}

# ── Brak aktywacji → no_match (fail-closed, nigdy cichy AUTO_POST) ──
test_p17_not_activated_no_match {
    d := v3_p17_ordynacja_obrona.decide with input as {"jdg_entrepreneur": {"v3_p17_check": false}}
    d.matched == false
    d.rule_id == "jdg.v3_p17_ordynacja_obrona.no_match"
}
