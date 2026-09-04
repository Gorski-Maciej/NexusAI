# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P19 PCC / LOKALNE / BDO-CBAM ENTERPRISE (jdg.v3_p19_pcc_akcyza_bdo)
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match).
# Uruchomienie (z katalogu JDG/):
#   ../bin/opa test tests/rego/test_v3_p19_pcc_akcyza_bdo_enterprise.rego \
#       rules/v3_p19_pcc_akcyza_bdo_enterprise.rego rules/thresholds_jdg.rego
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p19

import future.keywords.in

import data.jdg.v3_p19_pcc_akcyza_bdo

_base := {"jdg_entrepreneur": {"v3_p19_check": true}}

_cases := {
    "pcc_matrix": {"analysis": "pcc_matrix", "transaction_type": "ALIEN_ARTIFACT",
                   "amount_pln": 5000.0},
    "pcc_matrix_ok": {"analysis": "pcc_matrix", "transaction_type": "SALE",
                      "amount_pln": 500000.0, "mpp_invoice": false,
                      "pcc3_filed": true, "days_left_to_deadline": 5},
    "gmina_rates_validator": {"analysis": "gmina_rates_validator",
                              "rate_type": "ALIEN", "gmina_rate_pln": 9.99,
                              "year": 2026},
    "gmina_rates_validator_ok": {"analysis": "gmina_rates_validator",
                                 "rate_type": "BUILDING_BUSINESS",
                                 "gmina_rate_pln": 10.0, "year": 2026},
    "mpp_pcc_exclusion": {"analysis": "mpp_pcc_exclusion", "invoice_mpp": true,
                          "pcc_declared": true, "asset_sale": false},
    "mpp_pcc_exclusion_ok": {"analysis": "mpp_pcc_exclusion", "invoice_mpp": true,
                             "pcc_declared": false, "asset_sale": false},
    "local_tax_calendar": {"analysis": "local_tax_calendar", "tax_type": "ALIEN_TAX",
                           "days_left": -3, "paid": false},
    "local_tax_calendar_ok": {"analysis": "local_tax_calendar", "tax_type": "TRANSPORT",
                              "days_left": 30, "paid": false},
    "bdo_qualifier": {"analysis": "bdo_qualifier", "waste_kg_year": 500.0,
                      "bdo_registered": false, "data_complete": true},
    "bdo_qualifier_ok": {"analysis": "bdo_qualifier", "waste_kg_year": 500.0,
                         "bdo_registered": true, "data_complete": true},
    "ewc_library": {"analysis": "ewc_library", "ewc_code": "17 01 01",
                    "code_in_library": true, "code_format_valid": false},
    "ewc_library_ok": {"analysis": "ewc_library", "ewc_code": "17 01 01",
                       "code_in_library": true, "code_format_valid": true},
    "waste_fee": {"analysis": "waste_fee", "waste_kg": -5.0, "fee_rate_per_kg": 0.0},
    "waste_fee_ok": {"analysis": "waste_fee", "waste_kg": 800.0, "fee_rate_per_kg": 0.0},
    "cbam_monitor": {"analysis": "cbam_monitor", "imported_goods": ["CEMENT"],
                     "cbam_registered": false},
    "cbam_monitor_ok": {"analysis": "cbam_monitor", "imported_goods": ["PAPIER_TOALETOWY"],
                        "cbam_registered": true},
    "golden_set": {"analysis": "golden_set", "case_id": "PCC-2026-002",
                   "in_golden_set": true, "golden_match": false, "boundary_case": false},
    "golden_set_ok": {"analysis": "golden_set", "case_id": "PCC-2026-001",
                      "in_golden_set": true, "golden_match": true, "boundary_case": false},
    "local_invariants": {"analysis": "local_invariants", "mpp_and_pcc": true,
                         "gmina_rate_exceeds_limit": false, "deadline_breached": false},
    "local_invariants_ok": {"analysis": "local_invariants", "mpp_and_pcc": false,
                            "gmina_rate_exceeds_limit": false, "deadline_breached": false},
    "instalment_reminder": {"analysis": "instalment_reminder",
                            "property_tax_year_pln": 4000.0, "instalments_paid": 1,
                            "days_left_to_next": -2, "next_instalment_paid": false},
    "instalment_reminder_ok": {"analysis": "instalment_reminder",
                               "property_tax_year_pln": 4000.0, "instalments_paid": 1,
                               "days_left_to_next": 5, "next_instalment_paid": false},
    "explanation_pack": {"analysis": "explanation_pack", "pack_type": "ALIEN_PACK",
                         "legal_basis_present": false, "docs_checklist_complete": false},
    "explanation_pack_ok": {"analysis": "explanation_pack", "pack_type": "BDO",
                            "legal_basis_present": true, "docs_checklist_complete": true},
}

_decide(case) = d {
    d := v3_p19_pcc_akcyza_bdo.decide with input as object.union(_base, {"v3_p19": _cases[case]})
}

# ── I01: PCC Matrix — nieznana czynność → BLOCK ──
test_p19_i01_unknown_block {
    d := _decide("pcc_matrix")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.pcc_matrix"
    d._routing == "BLOCK_AND_ALERT"
}

test_p19_i01_ok_suggest {
    d := _decide("pcc_matrix_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.pcc_matrix"
    d._routing == "SUGGEST"
    d.fail_closed == false
}

# ── I02: Gmina Rates Validator — nieznany typ / przekroczenie → BLOCK ──
test_p19_i02_unknown_block {
    d := _decide("gmina_rates_validator")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.gmina_rates_validator"
    d._routing == "BLOCK_AND_ALERT"
    d.unknown_type == true
}

test_p19_i02_ok_suggest {
    d := _decide("gmina_rates_validator_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.gmina_rates_validator"
    d._routing == "SUGGEST"
    d.exceeds_statutory_max == false
}

# ── I03: MPP-PCC Exclusion Gate — podwójne opodatkowanie → BLOCK ──
test_p19_i03_double_block {
    d := _decide("mpp_pcc_exclusion")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.mpp_pcc_exclusion_gate"
    d._routing == "BLOCK_AND_ALERT"
    d.double_taxation == true
}

test_p19_i03_ok_suggest {
    d := _decide("mpp_pcc_exclusion_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.mpp_pcc_exclusion_gate"
    d._routing == "SUGGEST"
    d.double_taxation == false
}

# ── I04: Local Tax Calendar — nieznany typ / minięty termin → BLOCK ──
test_p19_i04_unknown_block {
    d := _decide("local_tax_calendar")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.local_tax_calendar_pack"
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p19_i04_ok_suggest {
    d := _decide("local_tax_calendar_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.local_tax_calendar_pack"
    d._routing == "SUGGEST"
}

# ── I05: BDO Qualifier — obowiązek bez rejestracji → BLOCK ──
test_p19_i05_unregistered_block {
    d := _decide("bdo_qualifier")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.bdo_qualifier"
    d._routing == "BLOCK_AND_ALERT"
}

test_p19_i05_ok_suggest {
    d := _decide("bdo_qualifier_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.bdo_qualifier"
    d._routing == "SUGGEST"
}

# ── I06: EWC Code Library — zły format → BLOCK ──
test_p19_i06_bad_format_block {
    d := _decide("ewc_library")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.ewc_code_library"
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p19_i06_ok_suggest {
    d := _decide("ewc_library_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.ewc_code_library"
    d._routing == "SUGGEST"
}

# ── I07: Waste Fee — masa ujemna → BLOCK ──
test_p19_i07_bad_mass_block {
    d := _decide("waste_fee")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.waste_fee_calculator"
    d._routing == "BLOCK_AND_ALERT"
}

test_p19_i07_ok_suggest {
    d := _decide("waste_fee_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.waste_fee_calculator"
    d._routing == "SUGGEST"
}

# ── I08: CBAM — import w katalogu → TRIAGE (decyzja architektoniczna) ──
test_p19_i08_in_scope_triage {
    d := _decide("cbam_monitor")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.cbam_architectural_decision"
    d._routing == "TRIAGE_QUEUE"
    d.in_cbam_catalogue == true
}

test_p19_i08_ok_suggest {
    d := _decide("cbam_monitor_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.cbam_architectural_decision"
    d._routing == "SUGGEST"
    d.in_cbam_catalogue == false
}

# ── I09: Golden Set — rozjazd z golden → BLOCK ──
test_p19_i09_drift_block {
    d := _decide("golden_set")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.pcc_golden_set"
    d._routing == "BLOCK_AND_ALERT"
}

test_p19_i09_ok_suggest {
    d := _decide("golden_set_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.pcc_golden_set"
    d._routing == "SUGGEST"
}

# ── I10: Local Tax Invariants — PCC+VAT jednocześnie → BLOCK ──
test_p19_i10_invariant_block {
    d := _decide("local_invariants")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.local_tax_invariants"
    d._routing == "BLOCK_AND_ALERT"
}

test_p19_i10_ok_suggest {
    d := _decide("local_invariants_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.local_tax_invariants"
    d._routing == "SUGGEST"
}

# ── I11: Instalment Reminder — rata minięta → BLOCK ──
test_p19_i11_breach_block {
    d := _decide("instalment_reminder")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.instalment_reminder"
    d._routing == "BLOCK_AND_ALERT"
}

test_p19_i11_reminder_triage {
    d := _decide("instalment_reminder_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.instalment_reminder"
    d._routing == "TRIAGE_QUEUE"
}

# ── I12: Explanation Pack — nieznany typ paczki → BLOCK ──
test_p19_i12_unknown_block {
    d := _decide("explanation_pack")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.explanation_pack"
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p19_i12_ok_suggest {
    d := _decide("explanation_pack_ok")
    d.rule_id == "jdg.v3_p19_pcc_akcyza_bdo.explanation_pack"
    d._routing == "SUGGEST"
}

# ── Aktywacja: bez flagi v3_p19_check → no_match (fail-closed globalny) ──
test_p19_no_activation_no_match {
    d := v3_p19_pcc_akcyza_bdo.decide with input as {"v3_p19": {"analysis": "pcc_matrix"}}
    d.matched == false
    endswith(d.rule_id, "no_match")
}
