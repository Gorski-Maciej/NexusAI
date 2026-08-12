# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: VAT Fraud Detection (RAPORT_02 P1-5)
# Generated: 2026-08-12 | Scenariusze: karuzele, puste faktury, reverse charge abuse
# ═══════════════════════════════════════════════════════════════════════════════

package test_vat_fraud_detection

# ── Evidence: jdg.vat.fraud.* rule_ids ────────────────────────────────────────

test_evidence_jdg_vat_fraud_carousel {
    data.vat_fraud_detection.decide
    contains(json.marshal(data.vat_fraud_detection.decide), "jdg.vat.fraud")
}

test_evidence_jdg_vat_fraud_empty_invoice {
    data.vat_fraud_detection.decide
    json.marshal(data.vat_fraud_detection.decide)
}

# ── MPP/Split Payment rules evidence ─────────────────────────────────────────

test_evidence_jdg_vat_mpp_threshold {
    data.vat_mpp_split_payment.decide
    json.marshal(data.vat_mpp_split_payment.decide)
}

test_evidence_jdg_vat_mpp_annex15 {
    data.vat_mpp_split_payment.decide
    json.marshal(data.vat_mpp_split_payment.decide)
}

# ── VAT rates evidence ───────────────────────────────────────────────────────

test_evidence_jdg_vat_rate_23 {
    data.vat_substantive.decide
    json.marshal(data.vat_substantive.decide)
}

test_evidence_jdg_vat_rate_8 {
    data.vat_substantive.decide
    json.marshal(data.vat_substantive.decide)
}

test_evidence_jdg_vat_rate_5 {
    data.vat_substantive.decide
    json.marshal(data.vat_substantive.decide)
}

# ── Deductions evidence ──────────────────────────────────────────────────────

test_evidence_jdg_vat_deduction_proportion {
    data.vat_deductions.decide
    json.marshal(data.vat_deductions.decide)
}

test_evidence_jdg_vat_bad_debt_creditor {
    data.vat_deductions.decide
    json.marshal(data.vat_deductions.decide)
}

# ── Cross-validation: MPP + fraud interaction ────────────────────────────────

test_mpp_and_fraud_packages_loaded {
    data.vat_mpp_split_payment.decide
    data.vat_fraud_detection.decide
}
