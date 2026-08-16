# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: VAT MPP / SPLIT PAYMENT (PROMPT 02 — PRIORYTET)
# Generated: 2026-08-16 | Scenariusze: art. 108a-108f, Załącznik 15, próg 15 000 zł,
#              sankcja 30%, solidarna odpowiedzialność, biała lista (art. 96b)
# ═══════════════════════════════════════════════════════════════════════════════

package test_vat_mpp_split_payment

# ── Evidence: pakiet jdg.vat_mpp_split_payment załadowany ────────────────────

test_evidence_jdg_vat_mpp_loaded {
    data.vat_mpp_split_payment.decide
    json.marshal(data.vat_mpp_split_payment.decide)
}

# ── MP-01: próg MPP z thresholds (art. 108a ust. 1) — externalizacja ─────────

test_mpp_threshold_externalized {
    data.vat_mpp_split_payment.mpp_threshold >= 15000
}

# ── MP-02: auto-oznaczanie semantyczne — słowa-klucze załącznika 15 ──────────

test_mpp_semantic_keywords_nonempty {
    count(data.vat_mpp_split_payment.semantic_keywords) > 10
}

# ── MP-06: Załącznik 15 — mapa CN niepusta ───────────────────────────────────

test_mpp_annex15_cn_loaded {
    count(data.vat_mpp_split_payment.annex15_cn) >= 10
}

# ── MP-03: flagi sankcji 30% i solidarnej odpowiedzialności (art. 108b) ──────

test_mpp_sanction_flags_total {
    v := data.vat_mpp_split_payment.violation_detected_flag
    s := data.vat_mpp_split_payment.solidary_risk_flag
    is_boolean(v)
    is_boolean(s)
}

# ── Integracja: fraud detection i MPP współdziałają (cross-validation) ───────

test_mpp_fraud_cross_loaded {
    data.vat_mpp_split_payment.decide
    data.vat_fraud_detection.decide
}
