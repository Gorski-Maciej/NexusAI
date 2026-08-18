# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: INNOVATIONS P10-P13 + MPIPS + P34 REMAINING
# (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Domknięcie kolejnych luk pokrycia pakietów innowacji domenowych.
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_innovations2

import data.jdg.p10_innovations
import data.jdg.p11_innovations
import data.jdg.p12_innovations
import data.jdg.p13_innovations
import data.jdg.mpips
import data.jdg.p34_remaining

# ── P10: Księgowość / UoR ─────────────────────────────────────────────────────
test_p10_gate_ok {
    r := p10_innovations.decide with input as {"uor": {"double_entry": true}}
    r.matched == true
}

test_p10_no_match {
    r := p10_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── P11: KKS / Ordynacja ──────────────────────────────────────────────────────
test_p11_gate_ok {
    r := p11_innovations.decide with input as {"kks": {"defense": true}}
    r.matched == true
}

test_p11_no_match {
    r := p11_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── P12: Cross-border / MDR ───────────────────────────────────────────────────
test_p12_gate_ok {
    r := p12_innovations.decide with input as {"mdr": {"hallmark": true}}
    r.matched == true
}

test_p12_no_match {
    r := p12_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── P13: Ryczałt / cykl życia ─────────────────────────────────────────────────
test_p13_gate_ok {
    r := p13_innovations.decide with input as {"ryczalt": {"limit": true}}
    r.matched == true
}

test_p13_no_match {
    r := p13_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── MPIPS (Ministerstwo Rodziny — świadczenia) ────────────────────────────────
test_mpips_gate_ok {
    r := mpips.decide with input as {"mpips": {"benefit": true}}
    r.matched == true
}

test_mpips_no_match {
    r := mpips.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── P34 remaining fixes ───────────────────────────────────────────────────────
test_p34_remaining_gate_ok {
    r := p34_remaining.decide with input as {"p34": {"fix": true}}
    r.matched == true
}

test_p34_remaining_no_match {
    r := p34_remaining.decide with input as {"other": {"flag": true}}
    r.matched == false
}
