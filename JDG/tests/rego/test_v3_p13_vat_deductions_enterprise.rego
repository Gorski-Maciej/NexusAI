# V3-P13 — native Rego tests for the VAT deductions/MPP enterprise layer (campaign V3).
# Scenariusze pokrywają innowacje I01–I12: deduction rights (art. 86-88), multi-year
# (art. 86c/86d), bad debt (art. 89a/89b), MPP (art. 108a-108d), zał. 15 jako dane,
# Biała Lista (art. 96b), fraud framework (P03 contract), proporcja (art. 90),
# invarianty salda VAT, stress lab, symetria korekt, safe-pay advisor.
package test_jdg_v3_p13_vat_deductions

base_input := {
    "jdg_entrepreneur": {"v3_p13_check": true},
    "v3_p13": {},
}

test_not_activated_no_match {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.v3_p13_vat_deductions.no_match"
}

# ── I01: DEDUCTION RIGHTS ENGINE (art. 86-88) ─────────────────────────────────
test_i01_deduction_rights_ok {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "deduction_rights",
                   "invoice_month": 8, "invoice_received_month": 8,
                   "has_invoice_document": true, "taxable_activity_link": true,
                   "deduction_category": "materialy"},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.deduction_rights_engine"
    result.deduction_rights.right_to_deduct == true
    result.fail_closed == false
}

test_i01_blocked_category_no_deduction {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "deduction_rights",
                   "invoice_month": 8, "invoice_received_month": 8,
                   "has_invoice_document": true, "taxable_activity_link": true,
                   "deduction_category": "paliwo_osobowe"},
    }
    result.deduction_rights.right_to_deduct == false
    result.deduction_rights.blocked_category == true
}

test_i01_car_mixed_use_half_ratio {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "deduction_rights",
                   "invoice_month": 8, "invoice_received_month": 8,
                   "has_invoice_document": true, "taxable_activity_link": true,
                   "deduction_category": "materialy",
                   "is_passenger_car": true, "car_mixed_use": true},
    }
    result.deduction_rights.car.ratio == 0.5
}

# ── I02: MULTI-YEAR CORRECTION PLANNER (art. 86c/86d) ─────────────────────────
test_i02_multi_year_real_estate {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "multi_year",
                   "asset_kind": "budynek", "acquisition_value_pln": 500000,
                   "correction_years": 10},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.multi_year_correction_planner"
    result.multi_year.asset_kind == "budynek"
}

# ── I03: BAD DEBT RADAR (art. 89a/89b) ────────────────────────────────────────
test_i03_bad_debt_overdue_triggers {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "bad_debt",
                   "invoice_brutto_pln": 20000, "days_overdue": 120,
                   "debtor_notified": true},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.bad_debt_radar"
    result.bad_debt.matured == true
    result.bad_debt.auto_in_minus_correction == true
}

# ── I04: MPP OBLIGATION DETECTOR (art. 108a-108d) ─────────────────────────────
test_i04_mpp_violation_flagged {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "mpp",
                   "invoice_brutto_pln": 20000, "cn_code": "271012",
                   "annex15_cn_match": true, "split_payment_used": false},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.mpp_obligation_detector"
    result.mpp.violation == true
    result._routing == "BLOCK_AND_ALERT"
}

# ── I05: ANNEX 15 AS VERSIONED DATA ───────────────────────────────────────────
test_i05_annex15_versioned {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "annex15", "cn_code": "271012"},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.annex15_as_versioned_data"
    result.annex15.data_complete == true
}

# ── I06: WHITE LIST GATE (art. 96b) ───────────────────────────────────────────
test_i06_whitelist_absent_blocks {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "whitelist",
                   "payment_amount_pln": 20000,
                   "counterparty_on_whitelist": false},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.white_list_gate"
    result.whitelist.counterparty_on_whitelist == false
    result.whitelist.violation == true
}

# ── I07: FRAUD SIGNAL FRAMEWORK ───────────────────────────────────────────────
test_i07_fraud_high_risk_human_review {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "fraud",
                   "counterparty_risk_score": 65,
                   "fraud_signals": ["round_amount", "shell_company"]},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.fraud_signal_framework"
    result.fraud.risk_level == "HIGH"
    result.fraud.human_review_required == true
    result.fraud.never_auto_conviction == true
}

# ── I08: PROPORTION PRECISION ENGINE (art. 90) ────────────────────────────────
test_i08_proportion_ratio {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "proportion",
                   "taxable_turnover_pln": 600000, "total_turnover_pln": 1000000},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.proportion_precision_engine"
    result.proportion.factor_rounded == 0.6
}

test_i08_proportion_new_taxpayer_pre {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "proportion",
                   "taxable_turnover_pln": 0, "total_turnover_pln": 0,
                   "is_new_taxpayer": true,
                   "planned_turnover_pln": 800000, "planned_exempt_pln": 200000},
    }
    result.proportion.is_new_taxpayer == true
    result.proportion.preliminary_correction == true
}

# ── I09: VAT BALANCE INVARIANTS ───────────────────────────────────────────────
test_i09_balance_invariants {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "vat_balance",
                   "input_vat_pln": 10000, "output_vat_pln": 15000},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.vat_balance_invariants"
    result.vat_invariants.deduction_le_due_ok == true
    result.vat_invariants.all_ok == true
}

# ── I10: VAT STRESS LAB ───────────────────────────────────────────────────────
test_i10_stress_scenario {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "stress",
                   "scenario_type": "audit", "stress_level": 5},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.vat_stress_lab"
    result.stress.scenario_type == "audit"
}

# ── I11: CORRECTION SYMMETRY GUARD ────────────────────────────────────────────
test_i11_correction_symmetry {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "correction_symmetry",
                   "correction_direction": "increase", "has_increase_doc": true},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.correction_symmetry_guard"
}

# ── I12: PAYMENT SAFE-PAY ADVISOR ─────────────────────────────────────────────
test_i12_safe_pay_ok {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "safe_pay",
                   "payment_amount_pln": 5000,
                   "payment_method": "split_payment",
                   "counterparty_on_whitelist": true},
    }
    result.rule_id == "jdg.v3_p13_vat_deductions.payment_safe_pay_advisor"
    result.safe_pay.safe_to_pay == true
}

test_i12_safe_pay_blocked_without_chain {
    result := data.jdg.v3_p13_vat_deductions.decide with input as {
        "jdg_entrepreneur": {"v3_p13_check": true},
        "v3_p13": {"analysis": "safe_pay",
                   "payment_amount_pln": 20000,
                   "payment_method": "traditional",
                   "counterparty_on_whitelist": false},
    }
    result.safe_pay.safe_to_pay == false
}