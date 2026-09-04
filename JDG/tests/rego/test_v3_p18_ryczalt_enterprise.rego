# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P18 RYCZAŁT ENTERPRISE (jdg.v3_p18_ryczalt)
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match).
# Uruchomienie (z katalogu JDG/):
#   ../bin/opa test tests/rego/test_v3_p18_ryczalt_enterprise.rego \
#       rules/v3_p18_ryczalt_enterprise.rego rules/thresholds_jdg.rego
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p18

import future.keywords.in

import data.jdg.v3_p18_ryczalt

_base := {"jdg_entrepreneur": {"v3_p18_check": true}}

_cases := {
    "rates_matrix": {"analysis": "rates_matrix", "category": "COS_INNEGO",
                     "revenue_pln": 1000.0},
    "rates_matrix_ok": {"analysis": "rates_matrix", "category": "IT",
                        "revenue_pln": 200000.0, "rate_applied": 0.12},
    "rates_matrix_mismatch": {"analysis": "rates_matrix", "category": "USLUGI",
                              "revenue_pln": 1000.0, "rate_applied": 0.12},
    "exclusion_sentinel": {"analysis": "exclusion_sentinel", "client_data_complete": true,
                           "former_employer": true, "services_same_scope": true,
                           "ryczalt_used": true},
    "exclusion_sentinel_ok": {"analysis": "exclusion_sentinel", "client_data_complete": true,
                              "former_employer": false, "services_same_scope": false,
                              "ryczalt_used": true},
    "midyear_exclusion": {"analysis": "midyear_exclusion"},
    "midyear_exclusion_ok": {"analysis": "midyear_exclusion", "exclusion_from": "2026-09-15",
                             "months_affected": 4, "ryczalt_used_this_year": true,
                             "correction_planned": false},
    "four_form_advisor": {"analysis": "four_form_advisor"},
    "four_form_advisor_ok": {"analysis": "four_form_advisor", "revenue_12m_pln": 240000.0,
                             "costs_12m_pln": 60000.0, "category": "IT"},
    "rate_split": {"analysis": "rate_split",
                   "lines": [{"amount_pln": 1000.0, "rate": 0.99}]},
    "rate_split_ok": {"analysis": "rate_split",
                      "lines": [{"amount_pln": 10000.0, "rate": 0.085},
                                {"amount_pln": 5000.0, "rate": 0.12}]},
    "year_end_correction": {"analysis": "year_end_correction",
                            "correction_type": "PRZED_ZAKONCZENIEM", "year_closed": false,
                            "correction_event_id": "KOR-9", "already_applied": false,
                            "correction_audited": false},
    "year_end_correction_ok": {"analysis": "year_end_correction",
                               "correction_type": "PRZED_ZAKONCZENIEM", "year_closed": false,
                               "correction_event_id": "KOR-9", "already_applied": false,
                               "correction_audited": true},
    "pkpir_contract": {"analysis": "pkpir_contract", "ryczalt_revenue_pln": 100000.0,
                       "pkpir_revenue_pln": 90000.0, "records_reconciled": true},
    "pkpir_contract_ok": {"analysis": "pkpir_contract", "ryczalt_revenue_pln": 100000.0,
                          "pkpir_revenue_pln": 100000.0, "records_reconciled": true},
    "pit28_autogen": {"analysis": "pit28_autogen", "evidence_revenue_pln": 100000.0,
                      "declaration_revenue_pln": 99900.0, "records_fully_covered": true},
    "pit28_autogen_ok": {"analysis": "pit28_autogen", "evidence_revenue_pln": 100000.0,
                         "declaration_revenue_pln": 100000.0, "records_fully_covered": true},
    "exclusion_registry": {"analysis": "exclusion_registry", "client_id": "C-1",
                           "registry_entries": [{"client_id": "C-1", "exclusion": true}]},
    "exclusion_registry_ok": {"analysis": "exclusion_registry", "client_id": "C-7",
                              "registry_entries": [{"client_id": "C-7", "exclusion": false}]},
    "golden_set": {"analysis": "golden_set", "case_id": "G-9", "in_golden_set": true,
                   "golden_rate_match": false, "date_boundary": false},
    "golden_set_ok": {"analysis": "golden_set", "case_id": "G-1", "in_golden_set": true,
                      "golden_rate_match": true, "date_boundary": false},
    "invariants": {"analysis": "invariants", "applied_rate": 0.99,
                   "evidence_declaration_mismatch": false, "currency_rate_missing": false},
    "invariants_ok": {"analysis": "invariants", "applied_rate": 0.085,
                      "evidence_declaration_mismatch": false, "currency_rate_missing": false},
    "explanation": {"analysis": "explanation", "decision_type": "COS",
                    "legal_basis_present": true},
    "explanation_ok": {"analysis": "explanation", "decision_type": "RATE", "rate": 0.085,
                       "category": "USLUGI", "revenue_pln": 10000.0,
                       "legal_basis_present": true},
}

_decide(case) = d {
    d := v3_p18_ryczalt.decide with input as object.union(_base, {"v3_p18": _cases[case]})
}

# ── I01: Rates Matrix — nieznana kategoria → BLOCK ──
test_p18_i01_unknown_block {
    d := _decide("rates_matrix")
    d.rule_id == "jdg.v3_p18_ryczalt.rates_matrix"
    d._routing == "BLOCK_AND_ALERT"
    d.unknown_category == true
}

test_p18_i01_ok_suggest {
    d := _decide("rates_matrix_ok")
    d._routing == "SUGGEST"
    d.rate_expected == 0.12
    d.rate_mismatch == false
}

test_p18_i01_mismatch_triage {
    d := _decide("rates_matrix_mismatch")
    d._routing == "TRIAGE_QUEUE"
    d.rate_mismatch == true
}

# ── I02: Exclusion Sentinel — usługi dla b. pracodawcy → BLOCKER ──
test_p18_i02_exclusion_block {
    d := _decide("exclusion_sentinel")
    d.rule_id == "jdg.v3_p18_ryczalt.exclusion_sentinel"
    d._routing == "BLOCK_AND_ALERT"
    d.exclusion_detected == true
    d.violation == true
}

test_p18_i02_ok_suggest {
    d := _decide("exclusion_sentinel_ok")
    d._routing == "SUGGEST"
    d.exclusion_detected == false
}

# ── I03: Mid-Year Exclusion — brak danych → BLOCK ──
test_p18_i03_unknown_block {
    d := _decide("midyear_exclusion")
    d.rule_id == "jdg.v3_p18_ryczalt.midyear_exclusion_handler"
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p18_i03_path_triage {
    d := _decide("midyear_exclusion_ok")
    d._routing == "TRIAGE_QUEUE"
    d.months_affected == 4
}

# ── I04: Four-Form Advisor — brak danych → BLOCK ──
test_p18_i04_no_data_block {
    d := _decide("four_form_advisor")
    d.rule_id == "jdg.v3_p18_ryczalt.four_form_advisor"
    d._routing == "BLOCK_AND_ALERT"
}

test_p18_i04_ok_recommendation {
    d := _decide("four_form_advisor_ok")
    d._routing in {"SUGGEST", "TRIAGE_QUEUE"}
    d.recommendation != ""
}

# ── I05: Rate Split — obca stawka → BLOCK ──
test_p18_i05_bad_rate_block {
    d := _decide("rate_split")
    d.rule_id == "jdg.v3_p18_ryczalt.rate_split_engine"
    d._routing == "BLOCK_AND_ALERT"
    d.unknown_rate == true
}

test_p18_i05_ok_split {
    d := _decide("rate_split_ok")
    d._routing == "SUGGEST"
    d.lines_count == 2
    d.total_revenue_pln == 15000.0
}

# ── I06: Year-End Correction — korekta bez audytu → BLOCK ──
test_p18_i06_no_audit_block {
    d := _decide("year_end_correction")
    d.rule_id == "jdg.v3_p18_ryczalt.year_end_correction_lab"
    d._routing == "BLOCK_AND_ALERT"
}

test_p18_i06_ok_suggest {
    d := _decide("year_end_correction_ok")
    d._routing == "SUGGEST"
    d.correction_audited == true
}

# ── I07: Ryczałt-PKPiR Contract — rozjazd → BLOCK ──
test_p18_i07_mismatch_block {
    d := _decide("pkpir_contract")
    d.rule_id == "jdg.v3_p18_ryczalt.pkpir_contract"
    d._routing == "BLOCK_AND_ALERT"
    d.mismatch == true
}

test_p18_i07_ok_suggest {
    d := _decide("pkpir_contract_ok")
    d._routing == "SUGGEST"
    d.mismatch == false
}

# ── I08: PIT-28 Autogen — rozjazd ewidencja ↔ deklaracja → BLOCK ──
test_p18_i08_mismatch_block {
    d := _decide("pit28_autogen")
    d.rule_id == "jdg.v3_p18_ryczalt.pit28_autogen"
    d._routing == "BLOCK_AND_ALERT"
}

test_p18_i08_ok_suggest {
    d := _decide("pit28_autogen_ok")
    d._routing == "SUGGEST"
    d.difference_pln == 0
}

# ── I09: Exclusion Registry — aktywny wpis → BLOCK ──
test_p18_i09_active_block {
    d := _decide("exclusion_registry")
    d.rule_id == "jdg.v3_p18_ryczalt.exclusion_registry"
    d._routing == "BLOCK_AND_ALERT"
    d.active_exclusion == true
}

test_p18_i09_ok_suggest {
    d := _decide("exclusion_registry_ok")
    d._routing == "SUGGEST"
    d.active_exclusion == false
}

# ── I10: Golden Set — rozjazd z oracle → BLOCK ──
test_p18_i10_violation_block {
    d := _decide("golden_set")
    d.rule_id == "jdg.v3_p18_ryczalt.golden_set"
    d._routing == "BLOCK_AND_ALERT"
}

test_p18_i10_ok_suggest {
    d := _decide("golden_set_ok")
    d._routing == "SUGGEST"
    d.golden_rate_match == true
}

# ── I11: Ryczałt Invariants Pack — naruszenie → BLOCK ──
test_p18_i11_violations_block {
    d := _decide("invariants")
    d.rule_id == "jdg.v3_p18_ryczalt.invariants_pack"
    d._routing == "BLOCK_AND_ALERT"
    "RYC_INV-001" in d.violations
}

test_p18_i11_ok_suggest {
    d := _decide("invariants_ok")
    d._routing == "SUGGEST"
    count(d.violations) == 0
}

# ── I12: Explanation Engine — nieznany typ → BLOCK ──
test_p18_i12_unknown_block {
    d := _decide("explanation")
    d.rule_id == "jdg.v3_p18_ryczalt.explanation_engine"
    d._routing == "BLOCK_AND_ALERT"
}

test_p18_i12_ok_suggest {
    d := _decide("explanation_ok")
    d._routing == "SUGGEST"
    d.explanation_complete == true
}

# ── Brak aktywacji → no_match (fail-closed, nigdy cichy AUTO_POST) ──
test_p18_not_activated_no_match {
    d := v3_p18_ryczalt.decide with input as {"jdg_entrepreneur": {"v3_p18_check": false}}
    d.matched == false
    d.rule_id == "jdg.v3_p18_ryczalt.no_match"
}
