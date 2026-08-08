# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Tests: P04 VAT MACRO ENTERPRISE v9.0
# Sekcje 8-10: rozwiązania systemowe + genius ideas (INN-01..INN-14)
# Format: complete rules (test_foo { ... }) — poprawna składnia OPA v0.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p04_vat_macro_enterprise_test

import future.keywords.in

# ── SEKCJA 8: PROPORCJA (art. 90/91) ─────────────────────────────────────────

test_proportion_prefactor {
    result := data.jdg.p04_vat_macro_enterprise.proportion_calculator with input as {
        "jdg_entrepreneur": {"p04_proportion_check": true, "turnover_taxable_annual": 80000,
            "turnover_total_annual": 100000, "final_deduction_factor": 0.8, "input_vat_total": 1000},
        "asset": {"value_net": 100000, "deduction_factor_initial": 1.0, "deduction_factor_current": 0.8, "is_real_estate": false}
    }
    result.matched == true
    result.proportion.pre_factor == 0.8
    result.proportion.multi_year.period_years == 5
    result._routing == "REPORT"
}

test_proportion_real_estate_10y {
    result := data.jdg.p04_vat_macro_enterprise.proportion_calculator with input as {
        "jdg_entrepreneur": {"p04_proportion_check": true, "turnover_taxable_annual": 80000,
            "turnover_total_annual": 100000, "final_deduction_factor": 0.8, "input_vat_total": 1000},
        "asset": {"value_net": 100000, "deduction_factor_initial": 1.0, "deduction_factor_current": 0.8, "is_real_estate": true}
    }
    result.matched == true
    result.proportion.multi_year.period_years == 10
}

# ── SEKCJA 8: ZŁE DŁUGI (art. 89a/89b — 90 dni) ──────────────────────────────

test_bad_debt_90_days_creditor {
    result := data.jdg.p04_vat_macro_enterprise.bad_debt_tracker with input as {
        "invoice": {"days_overdue": 95, "debtor_notified": true, "vat_amount": 230},
        "jdg_entrepreneur": {"p04_bad_debt_check": true}
    }
    result.matched == true
    result.bad_debt.days_overdue == 95
    result.bad_debt.days_threshold == 90
    result.bad_debt.creditor_correction_allowed == true
    result._routing == "TRIAGE_QUEUE"
}

test_bad_debt_below_90_days {
    result := data.jdg.p04_vat_macro_enterprise.bad_debt_tracker with input as {
        "invoice": {"days_overdue": 30, "debtor_notified": false, "vat_amount": 230},
        "jdg_entrepreneur": {"p04_bad_debt_check": true}
    }
    result.bad_debt.creditor_correction_allowed == false
    result.bad_debt.debtor_sanction_30pct == false
}

test_bad_debt_debtor_sanction {
    result := data.jdg.p04_vat_macro_enterprise.bad_debt_tracker with input as {
        "invoice": {"days_overdue": 120, "debtor_notified": true, "debt_remains_unpaid": true,
            "debtor_did_not_correct": true, "vat_amount": 230},
        "jdg_entrepreneur": {"p04_bad_debt_check": true}
    }
    result.bad_debt.debtor_must_correct == true
    result.bad_debt.debtor_sanction_30pct == true
}

# ── SEKCJA 9: VAT DIGITAL TWIN (INN-01) ──────────────────────────────────────

test_digital_twin_rate_prediction {
    result := data.jdg.p04_vat_macro_enterprise.vat_digital_twin with input as {
        "jdg_entrepreneur": {"p04_digital_twin_check": true},
        "digital_twin": {"transaction": {"description": "Sprzedaż pieczywa i mleka", "amount_net": 1000, "vat_deductible": true}}
    }
    result.matched == true
    result.twin.simulated_rate == "5.00"
    result.twin.sandboxed == true
    result.twin.verdict_class == "SIMULATED"
}

test_digital_twin_mpp_sensitive_cn {
    result := data.jdg.p04_vat_macro_enterprise.vat_digital_twin with input as {
        "jdg_entrepreneur": {"p04_digital_twin_check": true},
        "digital_twin": {"transaction": {"description": "Dostawa stali", "cn_code": "7207.19", "amount_gross": 20000}}
    }
    result.twin.mpp_required == true
}

# ── SEKCJA 9: KARUZELA DETECTOR (INN-02) ─────────────────────────────────────

test_carousel_critical_mtic {
    result := data.jdg.p04_vat_macro_enterprise.carousel_detector with input as {
        "jdg_entrepreneur": {"p04_carousel_check": true},
        "fraud_graph": {"cycles": [["A", "B", "C"]], "missing_trader": true, "same_goods_circulation": true, "chain_repeat": 3}
    }
    result.matched == true
    result.carousel.mtic_risk == true
    result.carousel.risk_level == "CRITICAL"
    result._routing == "BLOCK_AND_ALERT"
}

test_carousel_medium {
    result := data.jdg.p04_vat_macro_enterprise.carousel_detector with input as {
        "jdg_entrepreneur": {"p04_carousel_check": true},
        "fraud_graph": {"cycles": [["A", "B"]], "missing_trader": false, "same_goods_circulation": false, "chain_repeat": 1}
    }
    result.carousel.risk_level == "MEDIUM"
    result._routing == "TRIAGE_QUEUE"
}

# ── SEKCJA 9: ZERO-DEFECT VAT (INN-04) ───────────────────────────────────────

test_zero_defect_clean {
    result := data.jdg.p04_vat_macro_enterprise.zero_defect_vat with input as {
        "jdg_entrepreneur": {"p04_zero_defect_check": true},
        "verdict_under_test": {
            "vat": {"rate": "23.00", "legal_basis": "Art. 41 ust. 1 VAT"},
            "mpp": {"required": false, "marked": true},
            "invoice": {"number": "FV/2026/001", "sensitive_goods": false, "gtu_code": "GTU_06"}
        }
    }
    result.matched == true
    result.clean == true
    result.defect_count == 0
}

test_zero_defect_defects_detected {
    result := data.jdg.p04_vat_macro_enterprise.zero_defect_vat with input as {
        "jdg_entrepreneur": {"p04_zero_defect_check": true},
        "verdict_under_test": {
            "vat": {"rate": "99.00", "legal_basis": ""},
            "mpp": {"required": false, "marked": true},
            "invoice": {"number": "FV/2026/001", "sensitive_goods": false, "gtu_code": "GTU_06"}
        }
    }
    result.clean == false
    result.defect_count >= 2
    ids := {d.id | some d in result.defects}
    "RATE_NOT_IN_SET" in ids
    "NO_LEGAL_BASIS" in ids
}

# ── SEKCJA 9: REKONCYLACJA VAT↔PIT↔ZUS (INN-05) ──────────────────────────────

test_reconciliation_mismatch {
    result := data.jdg.p04_vat_macro_enterprise.reconciliation_engine with input as {
        "jdg_entrepreneur": {"p04_recon_check": true},
        "recon": {"vat_turnover_net": 120000, "pit_revenue": 100000, "vat_purchases_net": 50000,
            "kup_value": 48000, "zus_base": 20000, "pit_income": 25000, "tolerance": 0.01}
    }
    result.matched == true
    result.reconciliation.vat_revenue_vs_pit_revenue.mismatch == true
    result._routing == "TRIAGE_QUEUE"
}

test_reconciliation_consistent {
    result := data.jdg.p04_vat_macro_enterprise.reconciliation_engine with input as {
        "jdg_entrepreneur": {"p04_recon_check": true},
        "recon": {"vat_turnover_net": 100000, "pit_revenue": 100000, "vat_purchases_net": 50000,
            "kup_value": 50000, "zus_base": 20000, "pit_income": 30000, "tolerance": 0.01}
    }
    result.reconciliation.vat_revenue_vs_pit_revenue.mismatch == false
}

# ── SEKCJA 9: AUTO-MPP SYSTEM (INN-06) ───────────────────────────────────────

test_auto_mpp_annex15_cn {
    result := data.jdg.p04_vat_macro_enterprise.auto_mpp_system with input as {
        "invoice": {"direction": "PURCHASE", "cn_code": "7207.19", "amount_gross": 20000,
            "split_payment_used": false, "vat_amount": 4600, "gtu_code": "GTU_10"},
        "jdg_entrepreneur": {"p04_mpp_system_check": true}
    }
    result.matched == true
    result.mpp.trigger == "ANNEX15_CN"
    result.mpp.above_threshold == true
    result.mpp.violation == true
    result._routing == "BLOCK_AND_ALERT"
}

test_auto_mpp_gtu_sensitive {
    result := data.jdg.p04_vat_macro_enterprise.auto_mpp_system with input as {
        "invoice": {"direction": "PURCHASE", "cn_code": "", "gtu_code": "GTU_08",
            "amount_gross": 30000, "split_payment_used": true, "vat_amount": 6900},
        "jdg_entrepreneur": {"p04_mpp_system_check": true}
    }
    result.mpp.trigger == "GTU_SENSITIVE"
}

# ── SEKCJA 9: BIAŁA LISTA GUARD (INN-07) ─────────────────────────────────────

test_whitelist_violation {
    result := data.jdg.p04_vat_macro_enterprise.whitelist_guard with input as {
        "invoice": {"direction": "PURCHASE", "amount_gross": 25000, "payment_to_whitelisted_account": false},
        "vendor": {"on_whitelist": true},
        "jdg_entrepreneur": {"p04_whitelist_check": true}
    }
    result.matched == true
    result.whitelist.violation == true
    result.whitelist.kup_denied == true
    result.whitelist.solidary_liability == true
    result._routing == "BLOCK_AND_ALERT"
}

test_whitelist_ok {
    result := data.jdg.p04_vat_macro_enterprise.whitelist_guard with input as {
        "invoice": {"direction": "PURCHASE", "amount_gross": 25000, "payment_to_whitelisted_account": true},
        "vendor": {"on_whitelist": true},
        "jdg_entrepreneur": {"p04_whitelist_check": true}
    }
    result.whitelist.violation == false
}

test_whitelist_non_vat_vendor_no_violation {
    # Art. 96b: płatność nie-VAT-owskiemu dostawcy NIE jest naruszeniem —
    # Biała Lista dotyczy tylko VAT-owskich kontrahentów.
    result := data.jdg.p04_vat_macro_enterprise.whitelist_guard with input as {
        "invoice": {"direction": "PURCHASE", "amount_gross": 25000, "payment_to_whitelisted_account": false},
        "vendor": {"on_whitelist": false},
        "jdg_entrepreneur": {"p04_whitelist_check": true}
    }
    result.matched == true
    result.whitelist.violation == false
    result.whitelist.kup_denied == false
    result.whitelist.solidary_liability == false
}

# ── SEKCJA 9: RATE DRIFT GUARD (INN-10) ──────────────────────────────────────

test_rate_drift_mismatch {
    result := data.jdg.p04_vat_macro_enterprise.rate_drift_guard with input as {
        "invoice": {"category_code": "ELECTRONICS", "vat_rate": "8.00"},
        "jdg_entrepreneur": {"p04_rate_drift_check": true}
    }
    result.matched == true
    result.drift.mismatch == true
    result.drift.expected_rate == "23.00"
    result._routing == "TRIAGE_QUEUE"
}

# ── SEKCJA 9: SANKCJE KALKULATOR (INN-11) ────────────────────────────────────

test_sanctions_calculator {
    result := data.jdg.p04_vat_macro_enterprise.sanctions_calculator with input as {
        "jdg_entrepreneur": {"p04_sanctions_check": true},
        "sanction_input": {"understated_vat": 1000, "mpp_vat": 500, "wrong_rate_vat": 200, "ksef_underreported_vat": 3000}
    }
    result.matched == true
    result.sanctions.understatement_sanction == 300.0
    result.sanctions.mpp_sanction == 150.0
}

# ── SEKCJA 9: FAKTURY KORYGUJĄCE (INN-12) ────────────────────────────────────

test_correcting_invoice_detected {
    result := data.jdg.p04_vat_macro_enterprise.correcting_invoice_detector with input as {
        "invoice": {"is_correcting": true, "correction_type": "IN_MINUS",
            "original_invoice_number": "FV/2026/010", "correction_reason": "Błąd w stawce"},
        "jdg_entrepreneur": {"p04_correcting_check": true},
        "evaluation_datetime": "2026-06-01"
    }
    result.matched == true
    result.correcting.direction == "IN_MINUS"
    result.correcting.ksef_correction_required == true
    result._routing == "REPORT"
}

# ── SEKCJA 8: KASOWA MONITOR (INN-14) ────────────────────────────────────────

test_kasowa_eligible {
    result := data.jdg.p04_vat_macro_enterprise.kasowa_monitor with input as {
        "jdg_entrepreneur": {"p04_kasowa_check": true, "turnover_prev_year_pln": 1500000,
            "kasowa_method": true, "kasowa_limit_pln": 8600000}
    }
    result.matched == true
    result.kasowa.eligible == true
    result._routing == "REPORT"
}

# ── GŁÓWNY RAPORT P04 ────────────────────────────────────────────────────────

test_p04_main_report {
    result := data.jdg.p04_vat_macro_enterprise.decide with input as {
        "jdg_entrepreneur": {"p04_vat_macro_check": true}
    }
    result.matched == true
    result.rule_id == "jdg.p04_vat_macro_enterprise.report"
    result._routing == "REPORT"
    count(result.p04_vat_macro.section9_genius) == 14
    result.p04_vat_macro.dependencies.P17_KSEF_JPK == "ksef_micro"
}

test_p04_no_match_default {
    result := data.jdg.p04_vat_macro_enterprise.decide with input as {
        "jdg_entrepreneur": {"p04_vat_macro_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.p04_vat_macro_enterprise.no_match"
}
