# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Tests: P03 VAT MACRO ENTERPRISE v9.0
# Sekcje: 1 (stawki/zwolnienia), 3 (odliczenia/korekty), 4 (MPP priorytet),
#         6 (fraud), 2/5/7/8 (POS/KSeF/pipeline/genius ideas)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p03_vat_macro_enterprise_test

import future.keywords.in

# ── SEKCJA 1: STAWI I ZWOLNIENIA ─────────────────────────────────────────────

test_rate_mismatch_detected := {
    result := data.jdg.vat_rates_audit.rate_mismatch
    result.mismatch == true
    result.expected_rate == "23.00"
    result.invoice_rate == "8.00"
    result._routing == "TRIAGE_QUEUE"
} with input as {
    "invoice": {"category_code": "ELECTRONICS", "vat_rate": "8.00", "amount_net": 1000},
    "vendor": {"country": "PL"},
    "jdg_entrepreneur": {"vat_rates_check": true}
}

test_midyear_breach := {
    result := data.jdg.vat_rates_audit.midyear_breach
    result.exemption_ended == true
    result.breach_month == "2026-09"
    result._routing == "BLOCK_AND_ALERT"
} with input as {
    "jdg_entrepreneur": {"vat_exemption_check": true, "is_vat_payer": false,
        "annual_turnover_net": 210000, "breach_month": "2026-09"}
}

test_startup_proportional_limit := {
    result := data.jdg.vat_rates_audit.startup_limit_report
    result.startup == true
    result.within_limit == true
    result.proportional_limit > 0
} with input as {
    "jdg_entrepreneur": {"vat_exemption_check": true, "is_vat_payer": false,
        "ceidg_entry_month": "7", "annual_turnover_net": 80000}
}

# ── SEKCJA 3: ODLICZENIA I KOREKTY ───────────────────────────────────────────

test_deduction_blocked_fuel := {
    result := data.jdg.vat_deductions_audit.deduction_blocked
    "FUEL_PASSENGER_CAR" in result.blocked_reasons
    result._routing == "BLOCK_AND_ALERT"
} with input as {
    "invoice": {"direction": "PURCHASE", "category_code": "FUEL", "vat_deducted": true,
        "car_type": "PASSENGER", "car_registered_for_business": false, "vat_amount": 230},
    "jdg_entrepreneur": {"vat_deductions_check": true}
}

test_preproportion_report := {
    result := data.jdg.vat_deductions_audit.preproportion_report
    result.preproportion.final_factor == 0.8
    result.preproportion.adjustment_direction == "IN_MINUS"
} with input as {
    "jdg_entrepreneur": {"vat_deductions_check": true, "initial_deduction_factor": 1.0,
        "turnover_taxable_annual": 80000, "turnover_total_annual": 100000}
}

# ── SEKCJA 4: MPP / SPLIT PAYMENT (PRIORYTET) ────────────────────────────────

test_mpp_auto_mark_annex15 := {
    result := data.jdg.vat_mpp_split_payment.mp_auto_mark
    result.mpp.required == true
    result.mpp.trigger == "ANNEX15_CN"
} with input as {
    "invoice": {"direction": "PURCHASE", "cn_code": "72071210", "amount_gross": 20000},
    "jdg_entrepreneur": {"vat_mpp_check": true}
}

test_mpp_violation := {
    result := data.jdg.vat_mpp_split_payment.mpp_violation
    result.violation.required == true
    result.violation.split_payment_used == false
    result._routing == "BLOCK_AND_ALERT"
} with input as {
    "invoice": {"direction": "PURCHASE", "cn_code": "72071210", "amount_gross": 20000,
        "split_payment_used": false, "vat_amount": 4600},
    "jdg_entrepreneur": {"vat_mpp_check": true}
}

test_mpp_ok_voluntary := {
    # Faktura poniżej progu → brak naruszenia (brak decide violation)
    not data.jdg.vat_mpp_split_payment.mpp_violation
} with input as {
    "invoice": {"direction": "PURCHASE", "cn_code": "72071210", "amount_gross": 5000,
        "split_payment_used": false, "vat_amount": 1150},
    "jdg_entrepreneur": {"vat_mpp_check": true}
}

# ── SEKCJA 6: FRAUD DETECTION ────────────────────────────────────────────────

test_fraud_high_score := {
    result := data.jdg.vat_fraud_detection.fraud_score_decision
    result == "HIGH"
} with input as {
    "vendor": {"on_sanctions_list": true, "is_vat_active": false, "on_whitelist": false},
    "invoice": {"is_fraud_graph_match": true, "amount_net": 5000},
    "jdg_entrepreneur": {"vat_fraud_check": true}
}

test_empty_invoice := {
    result := data.jdg.vat_fraud_detection.empty_invoice_detection
    result.fraud.type == "EMPTY_INVOICE"
    result._routing == "BLOCK_AND_ALERT"
} with input as {
    "vendor": {"is_vat_active": false},
    "invoice": {"has_delivery_evidence": false, "category_code": "GOODS",
        "has_transport_evidence": false, "price_below_market_pct": 40},
    "jdg_entrepreneur": {"vat_fraud_check": true}
}

# ── SEKCJE 2/5/7/8: POS / KSEF / PIPELINE / GENIUS IDEAS ────────────────────

test_oss_analysis := {
    result := data.jdg.p03_vat_macro_innovations.oss_analysis
    result.oss.oss_required == true
    result.oss.oss_threshold_eur == 10000
} with input as {
    "jdg_entrepreneur": {"vat_pos_check": true, "eu_b2c_services_value_eur": 15000}
}

test_ksef_readiness_block := {
    result := data.jdg.p03_vat_macro_innovations.ksef_readiness
    result.ksef.mandatory_from == "2026-02-01"
    result.ksef.compliance_gap == true
    result._routing == "BLOCK_AND_ALERT"
} with input as {
    "evaluation_datetime": "2026-08-02",
    "jdg_entrepreneur": {"vat_ksef_check": true, "is_vat_payer": true},
    "invoice": {"is_efaktura_ksef": false}
}

test_refund_forecast_25d := {
    result := data.jdg.p03_vat_macro_innovations.refund_forecast
    result.refund.expected_days == 25
    result.refund.path == "STANDARD_25D"
} with input as {
    "jdg_entrepreneur": {"vat_refund_check": true, "has_tax_arrears": false,
        "under_control": false, "vat_registered_months": 36, "excess_input_vat": 5000}
}

test_auto_gtu := {
    result := data.jdg.p03_vat_macro_innovations.auto_gtu
    result.gtu.auto_detected == "GTU_10"
    result.gtu.declared == "GTU_01"
    result._routing == "TRIAGE_QUEUE"
} with input as {
    "jdg_entrepreneur": {"vat_gtu_check": true},
    "invoice": {"description": "sprzedaż stali konstrukcyjnej", "gtu_code": "GTU_01"}
}
