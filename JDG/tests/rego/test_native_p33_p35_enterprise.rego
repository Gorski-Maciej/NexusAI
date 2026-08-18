# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: P33/P35 + STRATEGIC + MDR + JPK_CIT + CBAM
# (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Domknięcie luk pokrycia: p33_*_supplement, p35_* (cross-act coherence),
# jdg.strategic, jdg.mdr_auto_generator, jdg.jpk_cit, jdg.cbam_full,
# jdg.cfc_auto_classifier, jdg.dac8_report_generator, jdg.exit_tax_interest_calculator,
# jdg.gtu_checker, jdg.pkpir_to_uor_transformer, jdg.form_transition.
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_p33_p35

import data.jdg.p35_gaps
import data.jdg.p35_coherence
import data.jdg.p3233_innovations
import data.jdg.strategic
import data.jdg.mdr_auto_generator
import data.jdg.jpk_cit
import data.jdg.cbam_full
import data.jdg.cfc_auto_classifier
import data.jdg.dac8_report_generator
import data.jdg.exit_tax_interest_calculator
import data.jdg.gtu_checker
import data.jdg.pkpir_to_uor_transformer
import data.jdg.form_transition

# ── P35: cross-act coherence / gaps ───────────────────────────────────────────
test_p35_gaps_ok {
    r := p35_gaps.decide with input as {"p35": {"gap": true}}
    r.matched == true
}

test_p35_gaps_no_match {
    r := p35_gaps.decide with input as {"other": {"flag": true}}
    r.matched == false
}

test_p35_coherence_ok {
    r := p35_coherence.decide with input as {"p35": {"coherence": true}}
    r.matched == true
}

test_p35_coherence_no_match {
    r := p35_coherence.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── P32/33: innovations ───────────────────────────────────────────────────────
test_p3233_ok {
    r := p3233_innovations.decide with input as {"p33": {"innovation": true}}
    r.matched == true
}

test_p3233_no_match {
    r := p3233_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── Strategic advisor ─────────────────────────────────────────────────────────
test_strategic_ok {
    r := strategic.decide with input as {"strategy": {"requested": true}}
    r.matched == true
}

test_strategic_no_match {
    r := strategic.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── MDR auto-generator ────────────────────────────────────────────────────────
test_mdr_auto_ok {
    r := mdr_auto_generator.decide with input as {"mdr": {"scheme": true}}
    r.matched == true
}

test_mdr_auto_no_match {
    r := mdr_auto_generator.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── JPK CIT ───────────────────────────────────────────────────────────────────
test_jpk_cit_ok {
    r := jpk_cit.decide with input as {"jpk": {"cit": true}}
    r.matched == true
}

test_jpk_cit_no_match {
    r := jpk_cit.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── CBAM ──────────────────────────────────────────────────────────────────────
test_cbam_ok {
    r := cbam_full.decide with input as {"cbam": {"import": true}}
    r.matched == true
}

test_cbam_no_match {
    r := cbam_full.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── CFC auto-classifier ───────────────────────────────────────────────────────
test_cfc_ok {
    r := cfc_auto_classifier.decide with input as {"cfc": {"foreign_company": true}}
    r.matched == true
}

test_cfc_no_match {
    r := cfc_auto_classifier.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── DAC8 ──────────────────────────────────────────────────────────────────────
test_dac8_ok {
    r := dac8_report_generator.decide with input as {"dac8": {"report": true}}
    r.matched == true
}

test_dac8_no_match {
    r := dac8_report_generator.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── Exit tax interest ─────────────────────────────────────────────────────────
test_exit_tax_interest_ok {
    r := exit_tax_interest_calculator.decide with input as {"exit_tax": {"interest": true}}
    r.matched == true
}

test_exit_tax_interest_no_match {
    r := exit_tax_interest_calculator.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── GTU checker ───────────────────────────────────────────────────────────────
test_gtu_ok {
    r := gtu_checker.decide with input as {"gtu": {"check": true}}
    r.matched == true
}

test_gtu_no_match {
    r := gtu_checker.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── PKPiR → UoR transformer ───────────────────────────────────────────────────
test_pkpir_uor_ok {
    r := pkpir_to_uor_transformer.decide with input as {"transform": {"pkpir_to_uor": true}}
    r.matched == true
}

test_pkpir_uor_no_match {
    r := pkpir_to_uor_transformer.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── Form transition ───────────────────────────────────────────────────────────
test_form_transition_ok {
    r := form_transition.decide with input as {"form": {"transition": true}}
    r.matched == true
}

test_form_transition_no_match {
    r := form_transition.decide with input as {"other": {"flag": true}}
    r.matched == false
}
