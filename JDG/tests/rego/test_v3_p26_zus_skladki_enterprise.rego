# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P26 ZUS SKŁADKI ENTERPRISE (jdg.v3_p26_zus_skladki)
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice (grosze 4161,00,
# progi 60k/300k ±0,01, kolejność ulg, zawieszenie, cross-act).
# Uruchomienie (z katalogu JDG/):
#   ../bin/opa test tests/rego/test_v3_p26_zus_skladki_enterprise.rego \
#       rules/v3_p26_zus_skladki_enterprise.rego rules/thresholds_jdg.rego
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p26

import data.jdg.v3_p26_zus_skladki

_base := {"jdg_entrepreneur": {"v3_p26_check": true}}

_cases := {
    "cp_zero": {"analysis": "contribution_precision", "contribution_base": 0},
    "cp_below_min": {"analysis": "contribution_precision", "contribution_base": 3000},
    "cp_ok_4161": {"analysis": "contribution_precision", "contribution_base": 4161.00,
                   "expected_total": 1316.54, "relief_active": true},
    "cp_relief_low_ok": {"analysis": "contribution_precision", "contribution_base": 1440.00,
                         "relief_active": true},
    "ro_unknown": {"analysis": "relief_order", "relief_state": "ALIEN"},
    "ro_parallel": {"analysis": "relief_order", "relief_state": "PREFERENCYJNA",
                    "previous_state": "START", "relief_months_used": 10,
                    "parallel_reliefs": true},
    "ro_over_limit": {"analysis": "relief_order", "relief_state": "START",
                      "previous_state": "NONE", "relief_months_used": 7},
    "ro_bad_transition": {"analysis": "relief_order", "relief_state": "MALY_ZUS_PLUS",
                          "previous_state": "STANDARD", "relief_months_used": 10},
    "ro_ok": {"analysis": "relief_order", "relief_state": "PREFERENCYJNA",
              "previous_state": "START", "relief_months_used": 10},
    "ro_mzp_transition": {"analysis": "relief_order", "relief_state": "MALY_ZUS_PLUS",
                          "previous_state": "PREFERENCYJNA", "relief_months_used": 30},
    "ct_negative": {"analysis": "cumulative_tier", "cumulative_revenue_ytd": -1},
    "ct_tier_mismatch": {"analysis": "cumulative_tier", "cumulative_revenue_ytd": 45000,
                         "expected_tier": "TIER_2"},
    "ct_b1_below": {"analysis": "cumulative_tier", "cumulative_revenue_ytd": 59999.99},
    "ct_b1_exact": {"analysis": "cumulative_tier", "cumulative_revenue_ytd": 60000.00},
    "ct_b1_above": {"analysis": "cumulative_tier", "cumulative_revenue_ytd": 60000.01},
    "ct_b2_exact": {"analysis": "cumulative_tier", "cumulative_revenue_ytd": 300000.00},
    "ct_b2_above": {"analysis": "cumulative_tier", "cumulative_revenue_ytd": 300000.01},
    "ct_approach": {"analysis": "cumulative_tier", "cumulative_revenue_ytd": 57000},
    "ct_ok": {"analysis": "cumulative_tier", "cumulative_revenue_ytd": 20000},
    "hv_mismatch": {"analysis": "health_2026_verifier", "health_params_version": "host-2025",
                    "isap_verified": true},
    "hv_no_version": {"analysis": "health_2026_verifier", "isap_verified": true},
    "hv_unverified": {"analysis": "health_2026_verifier",
                      "health_params_version": "health-2026.09", "isap_verified": false},
    "hv_ok": {"analysis": "health_2026_verifier",
              "health_params_version": "health-2026.09", "isap_verified": true},
    "su_relief_no_pause": {"analysis": "suspension_handler", "suspended": true,
                           "relief_active": true, "relief_paused": false,
                           "suspension_months": 2, "health_contribution_days": 0},
    "su_health_days": {"analysis": "suspension_handler", "suspended": true,
                       "relief_active": false, "relief_paused": true,
                       "suspension_months": 2, "health_contribution_days": 5},
    "su_long": {"analysis": "suspension_handler", "suspended": true,
                "relief_active": false, "relief_paused": true,
                "suspension_months": 30, "health_contribution_days": 0},
    "su_ok": {"analysis": "suspension_handler", "suspended": true,
              "relief_active": false, "relief_paused": true,
              "suspension_months": 2, "health_contribution_days": 0},
    "dg_unknown": {"analysis": "dra_generator", "form_type": "ALIEN",
                   "required_fields_present": true, "payer_identified": true,
                   "declaration_period": "2026-01"},
    "dg_no_fields": {"analysis": "dra_generator", "form_type": "DRA",
                     "required_fields_present": false, "payer_identified": true,
                     "declaration_period": "2026-01"},
    "dg_no_ident": {"analysis": "dra_generator", "form_type": "DRA",
                    "required_fields_present": true, "payer_identified": false,
                    "declaration_period": "2026-01"},
    "dg_no_period": {"analysis": "dra_generator", "form_type": "DRA",
                     "required_fields_present": true, "payer_identified": true,
                     "declaration_period": ""},
    "dg_rca_triage": {"analysis": "dra_generator", "form_type": "DRA",
                      "required_fields_present": true, "payer_identified": true,
                      "declaration_period": "2026-01", "employees_count": 3},
    "dg_ok": {"analysis": "dra_generator", "form_type": "DRA",
              "required_fields_present": true, "payer_identified": true,
              "declaration_period": "2026-01"},
    "iv_negative": {"analysis": "invariants_pack",
                    "contributions": {"pension": -1}},
    "iv_range": {"analysis": "invariants_pack", "contribution_base": 100,
                 "relief_order_valid": true, "grosz_precision_ok": true},
    "iv_order": {"analysis": "invariants_pack", "relief_order_valid": false},
    "iv_precision": {"analysis": "invariants_pack", "grosz_precision_ok": false},
    "iv_ok": {"analysis": "invariants_pack", "contribution_base": 5204.40,
              "relief_order_valid": true, "grosz_precision_ok": true,
              "contributions": {"pension": 812.23}},
    "gs_mismatch": {"analysis": "golden_set", "case_id": "ZUS-2026-G01",
                    "in_golden_set": true, "expected_routing": "SUGGEST",
                    "actual_routing": "BLOCK_AND_ALERT"},
    "gs_no_expect": {"analysis": "golden_set", "case_id": "ZUS-2026-G02",
                     "in_golden_set": true, "expected_routing": "",
                     "actual_routing": "SUGGEST"},
    "gs_ok": {"analysis": "golden_set", "case_id": "ZUS-2026-G01",
              "in_golden_set": true, "expected_routing": "SUGGEST",
              "actual_routing": "SUGGEST"},
    "fc_over": {"analysis": "form_change_rescaler", "form_change_month": 4,
                "rescaled_periods": 5},
    "fc_partial": {"analysis": "form_change_rescaler", "form_change_month": 4,
                   "rescaled_periods": 2},
    "fc_ok": {"analysis": "form_change_rescaler", "form_change_month": 4,
              "rescaled_periods": 4},
    "fc_none": {"analysis": "form_change_rescaler", "form_change_month": 0,
                "rescaled_periods": 0},
    "mw_no_feed": {"analysis": "minimum_wage_integration", "minimum_wage_monthly": 0},
    "mw_drift": {"analysis": "minimum_wage_integration", "minimum_wage_monthly": 3000},
    "mw_ok": {"analysis": "minimum_wage_integration", "minimum_wage_monthly": 4800},
    "sl_incomplete": {"analysis": "stress_lab", "scenarios": [
        {"name": "S1", "expected_routing": "SUGGEST", "actual_routing": "SUGGEST"}]},
    "sl_failing": {"analysis": "stress_lab", "scenarios": [
        {"name": "S1", "expected_routing": "SUGGEST", "actual_routing": "BLOCK_AND_ALERT"},
        {"name": "S2", "expected_routing": "SUGGEST", "actual_routing": "SUGGEST"},
        {"name": "S3", "expected_routing": "SUGGEST", "actual_routing": "SUGGEST"}]},
    "sl_ok": {"analysis": "stress_lab", "scenarios": [
        {"name": "S1", "expected_routing": "SUGGEST", "actual_routing": "SUGGEST"},
        {"name": "S2", "expected_routing": "SUGGEST", "actual_routing": "SUGGEST"},
        {"name": "S3", "expected_routing": "SUGGEST", "actual_routing": "SUGGEST"}]},
    "xa_unknown": {"analysis": "cross_act_consistency", "tax_form": "ALIEN",
                   "pit_income": 100000, "health_contributed": 9000},
    "xa_missing": {"analysis": "cross_act_consistency", "tax_form": "SCALE",
                   "pit_income": 100000, "health_contributed": 0},
    "xa_drift": {"analysis": "cross_act_consistency", "tax_form": "SCALE",
                 "pit_income": 100000, "health_contributed": 8000},
    "xa_ok_scale": {"analysis": "cross_act_consistency", "tax_form": "SCALE",
                    "pit_income": 100000, "health_contributed": 9000},
    "xa_ok_linear": {"analysis": "cross_act_consistency", "tax_form": "LINEAR",
                     "pit_income": 100000, "health_contributed": 4900},
    "xa_ok_lump": {"analysis": "cross_act_consistency", "tax_form": "LUMP_SUM",
                   "health_tier": "TIER_1", "health_contributed": 491.40},
}

_decide(case) = d {
    d := v3_p26_zus_skladki.decide with input as object.union(_base, {"v3_p26": _cases[case]})
}

# ── Brak aktywacji → no_match ──
test_p26_no_match_without_flag {
    d := v3_p26_zus_skladki.decide with input as {"v3_p26": _cases["cp_ok_4161"]}
    d.rule_id == "jdg.v3_p26_zus_skladki.no_match"
}

# ── I01: Contribution Precision ──
test_p26_i01_zero_block {
    d := _decide("cp_zero")
    d.rule_id == "jdg.v3_p26_zus_skladki.contribution_precision"
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p26_i01_below_min_block {
    d := _decide("cp_below_min")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i01_penny_4161 {
    d := _decide("cp_ok_4161")
    d._routing == "SUGGEST"
    d.pension == 812.23
    d.disability == 332.88
    d.sickness == 101.94
    d.accident == 69.49
    d.total == 1316.54
}

test_p26_i01_relief_low_ok {
    d := _decide("cp_relief_low_ok")
    d._routing == "SUGGEST"
    d.pension == 281.09
}

# ── I02: Relief Order Automaton ──
test_p26_i02_unknown_block {
    d := _decide("ro_unknown")
    d.rule_id == "jdg.v3_p26_zus_skladki.relief_order_automaton"
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i02_parallel_block {
    d := _decide("ro_parallel")
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p26_i02_over_limit_block {
    d := _decide("ro_over_limit")
    d._routing == "BLOCK_AND_ALERT"
    d.months_limit == 6
}

test_p26_i02_bad_transition_block {
    d := _decide("ro_bad_transition")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i02_ok_suggest {
    d := _decide("ro_ok")
    d._routing == "SUGGEST"
    d.months_limit == 24
}

test_p26_i02_mzp_transition_triage {
    d := _decide("ro_mzp_transition")
    d._routing == "TRIAGE_QUEUE"
}

# ── I03: Cumulative Tier Sentinel — granice 60k/300k ±0,01 ──
test_p26_i03_negative_block {
    d := _decide("ct_negative")
    d.rule_id == "jdg.v3_p26_zus_skladki.cumulative_tier_sentinel"
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i03_mismatch_block {
    d := _decide("ct_tier_mismatch")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i03_boundary_below {
    d := _decide("ct_b1_below")
    d.tier == "TIER_1"
    d._routing == "TRIAGE_QUEUE"
    d.boundary_case == true
}

test_p26_i03_boundary_exact {
    d := _decide("ct_b1_exact")
    d.tier == "TIER_1"
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i03_boundary_above {
    d := _decide("ct_b1_above")
    d.tier == "TIER_2"
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i03_t2_exact {
    d := _decide("ct_b2_exact")
    d.tier == "TIER_2"
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i03_t2_above {
    d := _decide("ct_b2_above")
    d.tier == "TIER_3"
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i03_approach_alert {
    d := _decide("ct_approach")
    d.tier == "TIER_1"
    d._routing == "TRIAGE_QUEUE"
    d.boundary_case == false
}

test_p26_i03_ok_suggest {
    d := _decide("ct_ok")
    d._routing == "SUGGEST"
}

# ── I04: Health 2026 Verifier ──
test_p26_i04_mismatch_block {
    d := _decide("hv_mismatch")
    d.rule_id == "jdg.v3_p26_zus_skladki.health_2026_verifier"
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p26_i04_no_version_triage {
    d := _decide("hv_no_version")
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i04_unverified_triage {
    d := _decide("hv_unverified")
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i04_ok_suggest {
    d := _decide("hv_ok")
    d._routing == "SUGGEST"
}

# ── I05: Suspension Handler ──
test_p26_i05_relief_no_pause_block {
    d := _decide("su_relief_no_pause")
    d.rule_id == "jdg.v3_p26_zus_skladki.suspension_handler"
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i05_health_days_triage {
    d := _decide("su_health_days")
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i05_long_triage {
    d := _decide("su_long")
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i05_ok_suggest {
    d := _decide("su_ok")
    d._routing == "SUGGEST"
}

# ── I06: DRA Generator ──
test_p26_i06_unknown_block {
    d := _decide("dg_unknown")
    d.rule_id == "jdg.v3_p26_zus_skladki.dra_generator"
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i06_no_fields_block {
    d := _decide("dg_no_fields")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i06_no_ident_block {
    d := _decide("dg_no_ident")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i06_no_period_block {
    d := _decide("dg_no_period")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i06_rca_mismatch_triage {
    d := _decide("dg_rca_triage")
    d._routing == "TRIAGE_QUEUE"
    d.expected_form == "RCA"
}

test_p26_i06_ok_suggest {
    d := _decide("dg_ok")
    d._routing == "SUGGEST"
    d.expected_form == "DRA"
}

# ── I07: Invariants Pack ──
test_p26_i07_negative_block {
    d := _decide("iv_negative")
    d.rule_id == "jdg.v3_p26_zus_skladki.invariants_pack"
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p26_i07_range_block {
    d := _decide("iv_range")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i07_order_block {
    d := _decide("iv_order")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i07_precision_block {
    d := _decide("iv_precision")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i07_ok_suggest {
    d := _decide("iv_ok")
    d._routing == "SUGGEST"
    d.violation_count == 0
}

# ── I08: Golden Set ──
test_p26_i08_mismatch_block {
    d := _decide("gs_mismatch")
    d.rule_id == "jdg.v3_p26_zus_skladki.golden_set"
    d._routing == "BLOCK_AND_ALERT"
    d.golden_match == false
}

test_p26_i08_no_expect_triage {
    d := _decide("gs_no_expect")
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i08_ok_suggest {
    d := _decide("gs_ok")
    d._routing == "SUGGEST"
    d.golden_match == true
}

# ── I09: Form Change Rescaler ──
test_p26_i09_over_block {
    d := _decide("fc_over")
    d.rule_id == "jdg.v3_p26_zus_skladki.form_change_rescaler"
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i09_partial_triage {
    d := _decide("fc_partial")
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i09_ok_suggest {
    d := _decide("fc_ok")
    d._routing == "SUGGEST"
}

test_p26_i09_none_suggest {
    d := _decide("fc_none")
    d._routing == "SUGGEST"
}

# ── I10: Minimum Wage Integration ──
test_p26_i10_no_feed_block {
    d := _decide("mw_no_feed")
    d.rule_id == "jdg.v3_p26_zus_skladki.minimum_wage_integration"
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i10_drift_triage {
    d := _decide("mw_drift")
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i10_ok_suggest {
    d := _decide("mw_ok")
    d._routing == "SUGGEST"
    d.preferential_base == 1440.00
}

# ── I11: Stress Lab ──
test_p26_i11_incomplete_block {
    d := _decide("sl_incomplete")
    d.rule_id == "jdg.v3_p26_zus_skladki.stress_lab"
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i11_failing_block {
    d := _decide("sl_failing")
    d._routing == "BLOCK_AND_ALERT"
    d.fail_closed == true
}

test_p26_i11_ok_suggest {
    d := _decide("sl_ok")
    d._routing == "SUGGEST"
}

# ── I12: Cross-Act Consistency ──
test_p26_i12_unknown_form_block {
    d := _decide("xa_unknown")
    d.rule_id == "jdg.v3_p26_zus_skladki.cross_act_consistency"
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i12_missing_triage {
    d := _decide("xa_missing")
    d._routing == "TRIAGE_QUEUE"
}

test_p26_i12_drift_block {
    d := _decide("xa_drift")
    d._routing == "BLOCK_AND_ALERT"
}

test_p26_i12_scale_ok {
    d := _decide("xa_ok_scale")
    d._routing == "SUGGEST"
    d.health_expected == 9000
}

test_p26_i12_linear_ok {
    d := _decide("xa_ok_linear")
    d._routing == "SUGGEST"
    d.health_expected == 4900
}

test_p26_i12_lump_ok {
    d := _decide("xa_ok_lump")
    d._routing == "SUGGEST"
    d.health_expected == 491.40
}
