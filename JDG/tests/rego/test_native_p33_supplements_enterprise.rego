# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: P33 SUPPLEMENTS + RELIABILITY + LIFECYCLE
# (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Domknięcie luk pokrycia: p33_excise_supplement, p33_ordpu_kks_supplement,
# p33_uor_supplement, p33_pcc_complete, reliability_guarantee, rule_lifecycle,
# gaar_shield, interest_calculator, vida_drr_full, wdt_document_tracker.
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_p33_supplements

import data.jdg.p33_excise_supplement
import data.jdg.p33_ordpu_kks_supplement
import data.jdg.p33_uor_supplement
import data.jdg.p33_pcc_complete
import data.jdg.reliability_guarantee
import data.jdg.rule_lifecycle
import data.jdg.gaar_shield
import data.jdg.interest_calculator
import data.jdg.vida_drr_full
import data.jdg.wdt_document_tracker

# ── P33 supplements (micro plan33 — uzupełnienia domen) ──────────────────────
test_p33_excise_ok {
    r := p33_excise_supplement.decide with input as {"excise": {"supplement": true}}
    r.matched == true
}

test_p33_excise_no_match {
    r := p33_excise_supplement.decide with input as {"other": {"flag": true}}
    r.matched == false
}

test_p33_ordpu_kks_ok {
    r := p33_ordpu_kks_supplement.decide with input as {"ordpu": {"kks": true}}
    r.matched == true
}

test_p33_ordpu_kks_no_match {
    r := p33_ordpu_kks_supplement.decide with input as {"other": {"flag": true}}
    r.matched == false
}

test_p33_uor_ok {
    r := p33_uor_supplement.decide with input as {"uor": {"supplement": true}}
    r.matched == true
}

test_p33_uor_no_match {
    r := p33_uor_supplement.decide with input as {"other": {"flag": true}}
    r.matched == false
}

test_p33_pcc_ok {
    r := p33_pcc_complete.decide with input as {"pcc": {"complete": true}}
    r.matched == true
}

test_p33_pcc_no_match {
    r := p33_pcc_complete.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── Reliability guarantee ─────────────────────────────────────────────────────
test_reliability_ok {
    r := reliability_guarantee.decide with input as {"reliability": {"guarantee": true}}
    r.matched == true
}

test_reliability_no_match {
    r := reliability_guarantee.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── Rule lifecycle ────────────────────────────────────────────────────────────
test_rule_lifecycle_ok {
    r := rule_lifecycle.decide with input as {"lifecycle": {"rule": true}}
    r.matched == true
}

test_rule_lifecycle_no_match {
    r := rule_lifecycle.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── GAAR shield ───────────────────────────────────────────────────────────────
test_gaar_ok {
    r := gaar_shield.decide with input as {"gaar": {"shield": true}}
    r.matched == true
}

test_gaar_no_match {
    r := gaar_shield.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── Interest calculator ───────────────────────────────────────────────────────
test_interest_ok {
    r := interest_calculator.decide with input as {"interest": {"calculate": true}}
    r.matched == true
}

test_interest_no_match {
    r := interest_calculator.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── ViDA / DRR ────────────────────────────────────────────────────────────────
test_vida_ok {
    r := vida_drr_full.decide with input as {"vida": {"drr": true}}
    r.matched == true
}

test_vida_no_match {
    r := vida_drr_full.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── WDT document tracker ──────────────────────────────────────────────────────
test_wdt_ok {
    r := wdt_document_tracker.decide with input as {"wdt": {"document": true}}
    r.matched == true
}

test_wdt_no_match {
    r := wdt_document_tracker.decide with input as {"other": {"flag": true}}
    r.matched == false
}
