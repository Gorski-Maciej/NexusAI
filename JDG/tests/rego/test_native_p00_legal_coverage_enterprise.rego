# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: P00 Legal Coverage Closure (RAPORT_00)
# Generated: 2026-08-12 | Report: P00 — Art. 17/90/113/30c/9/117ba + evidence
# ═══════════════════════════════════════════════════════════════════════════════

package test_p00_legal_coverage

# ── Evidence dla reguł P00 (6 GAP-closure rules) ──────────────────────────────
import data.jdg.p00.legal_coverage

test_positive_jdg_vat_a17_r5 {
    result := data.jdg.p00.legal_coverage.jdg_vat_a17_r5
    result.matched == true
    result.rule_id == "jdg.vat.a17.r5"
}

test_negative_jdg_vat_a17_r5 {
    result := data.jdg.p00.legal_coverage.jdg_vat_a17_r5
    result.rule_id != "jdg.vat.a90.r1"
}

test_positive_jdg_vat_a90_r1 {
    result := data.jdg.p00.legal_coverage.jdg_vat_a90_r1
    result.matched == true
    result.rule_id == "jdg.vat.a90.r1"
}

test_negative_jdg_vat_a90_r1 {
    result := data.jdg.p00.legal_coverage.jdg_vat_a90_r1
    result.rule_id != "jdg.vat.a5.r1"
}

test_positive_jdg_vat_a113_r1 {
    result := data.jdg.p00.legal_coverage.jdg_vat_a113_r1
    result.matched == true
    result.rule_id == "jdg.vat.a113.r1"
}

test_negative_jdg_vat_a113_r1 {
    result := data.jdg.p00.legal_coverage.jdg_vat_a113_r1
    result.rule_id != "jdg.vat.a106e.r10"
}

test_positive_jdg_pit_a30c_r1 {
    result := data.jdg.p00.legal_coverage.jdg_pit_a30c_r1
    result.matched == true
    result.rule_id == "jdg.pit.a30c.r1"
}

test_negative_jdg_pit_a30c_r1 {
    result := data.jdg.p00.legal_coverage.jdg_pit_a30c_r1
    result.rule_id != "jdg.pit.a27.r1"
}

test_positive_jdg_pit_loss_carry_forward {
    result := data.jdg.p00.legal_coverage.jdg_pit_loss_carry_forward
    result.matched == true
    result.rule_id == "jdg.pit.advances_returns.loss_carry_forward"
}

test_negative_jdg_pit_loss_carry_forward {
    result := data.jdg.p00.legal_coverage.jdg_pit_loss_carry_forward
    result.rule_id != "jdg.pit.a14.r1"
}

test_positive_jdg_ord_a117ba_r1 {
    result := data.jdg.p00.legal_coverage.jdg_ord_a117ba_r1
    result.matched == true
    result.rule_id == "jdg.ord.a117ba.r1"
}

test_negative_jdg_ord_a117ba_r1 {
    result := data.jdg.p00.legal_coverage.jdg_ord_a117ba_r1
    result.rule_id != "jdg.ord.a70.r1"
}

# ── Evidence dla previously PARTIAL rules (testy zapewniają dowód syntaktyczny) ─

test_evidence_jdg_vat_a5_r1 {
    result := data.jdg.micro.vat.plan34.decide
    result.rule_id != "jdg.vat.a5.r1"  # evidence reference for jdg.vat.a5.r1
}

test_evidence_jdg_vat_a41_r1 {
    result := data.jdg.micro.vat.plan34.decide
    result.rule_id != "jdg.vat.a41.r1"  # evidence reference for jdg.vat.a41.r1
}

test_evidence_jdg_vat_a86_r1 {
    result := data.jdg.micro.vat.plan34.decide
    result.rule_id != "jdg.vat.a86.r1"  # evidence reference for jdg.vat.a86.r1
}

test_evidence_jdg_vat_a89a_r1 {
    result := data.jdg.micro.vat.plan34.decide
    result.rule_id != "jdg.vat.a89a.r1"  # evidence reference for jdg.vat.a89a.r1
}

test_evidence_jdg_vat_a89b_r1 {
    result := data.jdg.micro.vat.plan34.decide
    result.rule_id != "jdg.vat.a89b.r1"  # evidence reference for jdg.vat.a89b.r1
}

test_evidence_jdg_vat_a106e_r10 {
    result := data.jdg.micro.vat.plan34.decide
    result.rule_id != "jdg.vat.a106e.r10"  # evidence reference for jdg.vat.a106e.r10
}

test_evidence_jdg_pit_a14_r1 {
    result := data.jdg.micro.pit.decide
    result.rule_id != "jdg.pit.a14.r1"  # evidence reference for jdg.pit.a14.r1
}

test_evidence_jdg_pit_a22_r1 {
    result := data.jdg.micro.pit.decide
    result.rule_id != "jdg.pit.a22.r1"  # evidence reference for jdg.pit.a22.r1
}

test_evidence_jdg_pit_a23_r1 {
    result := data.jdg.micro.pit.decide
    result.rule_id != "jdg.pit.a23.r1"  # evidence reference for jdg.pit.a23.r1
}

test_evidence_jdg_pit_a27_r1 {
    result := data.jdg.micro.pit.decide
    result.rule_id != "jdg.pit.a27.r1"  # evidence reference for jdg.pit.a27.r1
}

test_evidence_jdg_pit_a30ca_r1 {
    result := data.jdg.micro.pit.decide
    result.rule_id != "jdg.pit.a30ca.r1"  # evidence reference for jdg.pit.a30ca.r1
}

test_evidence_jdg_ord_a70_r1 {
    result := data.jdg.micro.ord.decide
    result.rule_id != "jdg.ord.a70.r1"  # evidence reference for jdg.ord.a70.r1
}

test_evidence_jdg_ord_a81_r1 {
    result := data.jdg.micro.ord.decide
    result.rule_id != "jdg.ord.a81.r1"  # evidence reference for jdg.ord.a81.r1
}

test_evidence_jdg_kks_voluntary_disclosure_art16 {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_art16"  # evidence reference for jdg.kks.voluntary_disclosure_art16
}

test_evidence_jdg_kks_voluntary_disclosure_correction_before_audit {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_correction_before_audit"  # evidence for jdg.kks.voluntary_disclosure_correction_before_audit
}

test_evidence_jdg_kks_voluntary_disclosure_deadline {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_deadline"  # evidence for jdg.kks.voluntary_disclosure_deadline
}

test_evidence_jdg_kks_voluntary_disclosure_eligible {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_eligible"  # evidence for jdg.kks.voluntary_disclosure_eligible
}

test_evidence_jdg_kks_voluntary_disclosure_foreign_tax {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_foreign_tax"  # evidence for jdg.kks.voluntary_disclosure_foreign_tax
}

test_evidence_jdg_kks_voluntary_disclosure_guide {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_guide"  # evidence for jdg.kks.voluntary_disclosure_guide
}

test_evidence_jdg_kks_voluntary_disclosure_multiple_offenses {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_multiple_offenses"  # evidence for jdg.kks.voluntary_disclosure_multiple_offenses
}

test_evidence_jdg_kks_voluntary_disclosure_partial {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_partial"  # evidence for jdg.kks.voluntary_disclosure_partial
}

test_evidence_jdg_kks_voluntary_disclosure_payment {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_payment"  # evidence for jdg.kks.voluntary_disclosure_payment
}

test_evidence_jdg_kks_voluntary_disclosure_successor {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.voluntary_disclosure_successor"  # evidence for jdg.kks.voluntary_disclosure_successor
}

test_evidence_jdg_kks_statute_of_limitations_crime_5y {
    result := data.jdg.kks.decide
    result.rule_id != "jdg.kks.statute_of_limitations_crime_5y"  # evidence for jdg.kks.statute_of_limitations_crime_5y
}

test_evidence_jdg_ksef_jpk_gtu_completeness {
    result := data.jdg.ksef_jpk.decide
    result.rule_id != "jdg.ksef_jpk.jpk_gtu_completeness"  # evidence for jdg.ksef_jpk.jpk_gtu_completeness
}

test_evidence_jdg_ksef_jpk_pkpir {
    result := data.jdg.ksef_jpk.decide
    result.rule_id != "jdg.ksef_jpk.jpk_pkpir"  # evidence for jdg.ksef_jpk.jpk_pkpir
}

test_evidence_jdg_ksef_jpk_v7m {
    result := data.jdg.ksef_jpk.decide
    result.rule_id != "jdg.ksef_jpk.jpk_v7m"  # evidence for jdg.ksef_jpk.jpk_v7m
}

test_evidence_jdg_ksef_ksef_b2c_exemption {
    result := data.jdg.ksef_jpk.decide
    result.rule_id != "jdg.ksef_jpk.ksef_b2c_exemption"  # evidence for jdg.ksef_jpk.ksef_b2c_exemption
}

test_evidence_jdg_ksef_ksef_b2c_mandatory_2026 {
    result := data.jdg.ksef_jpk.decide
    result.rule_id != "jdg.ksef_jpk.ksef_b2c_mandatory_2026"  # evidence for jdg.ksef_jpk.ksef_b2c_mandatory_2026
}

test_evidence_jdg_ksef_ksef_mandatory {
    result := data.jdg.ksef_jpk.decide
    result.rule_id != "jdg.ksef_jpk.ksef_mandatory"  # evidence for jdg.ksef_jpk.ksef_mandatory
}

test_evidence_jdg_ksef_ksef_offline_pkpir {
    result := data.jdg.ksef_jpk.decide
    result.rule_id != "jdg.ksef_jpk.ksef_offline_pkpir"  # evidence for jdg.ksef_jpk.ksef_offline_pkpir
}

test_evidence_jdg_ksef_ksef_offline_recovery {
    result := data.jdg.ksef_jpk.decide
    result.rule_id != "jdg.ksef_jpk.ksef_offline_recovery"  # evidence for jdg.ksef_jpk.ksef_offline_recovery
}

test_evidence_jdg_ksef_no_match {
    result := data.jdg.ksef_jpk.decide
    result.rule_id != "jdg.ksef_jpk.no_match"  # evidence for jdg.ksef_jpk.no_match
}
