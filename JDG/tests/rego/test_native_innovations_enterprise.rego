# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: INNOVATIONS P05-P35 (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Domknięcie luk pokrycia pakietów innowacji (jdg.p05_innovations, jdg.p06_innovations,
# jdg.p07_innovations, jdg.p08_innovations, jdg.p09_innovations, jdg.p24.innovations,
# jdg.p34_innovations, jdg.p35_innovations) — warstwy ulepszeń per domena.
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_innovations

import data.jdg.p05_innovations
import data.jdg.p06_innovations
import data.jdg.p07_innovations
import data.jdg.p08_innovations
import data.jdg.p09_innovations
import data.jdg.p24.innovations
import data.jdg.p34_innovations
import data.jdg.p35_innovations

# ── P05: B+R (art. 26e PIT) — weryfikacja czasu pracownika ───────────────────
test_p05_rd_staff_time {
    r := p05_innovations.decide with input as {"rd_relief_requested": true}
    r.matched == true
    r.rule_id == "jdg.p05.rd.staff_time_verification"
}

test_p05_no_match {
    r := p05_innovations.decide with input as {"rd_relief_requested": false}
    r.matched == false
}

# ── P06: PIT micro — shard detector ───────────────────────────────────────────
test_p06_shard_detector {
    r := p06_innovations.decide with input as {"shard": {"detect": true}}
    r.matched == true
    r.rule_id == "jdg.p06_innovations.shard_detector"
    "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)" == r._legal_basis
}

test_p06_no_match {
    r := p06_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.p06_innovations.no_match"
}

# ── P07: ZUS — optymalizator składki zdrowotnej ───────────────────────────────
test_p07_health_optimizer {
    r := p07_innovations.decide with input as {"zus": {"health_optimization": true}}
    r.matched == true
    r.rule_id == "jdg.p07_innovations.health_insurance_optimizer"
}

test_p07_no_match {
    r := p07_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.p07_innovations.no_match"
}

# ── P08: ZUS micro — bramka (domyślna ścieżka) ────────────────────────────────
test_p08_gate_ok {
    r := p08_innovations.decide with input as {"zus": {"micro": true}}
    r.matched == true
}

test_p08_no_match {
    r := p08_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── P09: Księgowość — innowacje PKPiR/UoR ─────────────────────────────────────
test_p09_gate_ok {
    r := p09_innovations.decide with input as {"accounting": {"pkpir": true}}
    r.matched == true
}

test_p09_no_match {
    r := p09_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── P24: Audyt kompletny — innowacje ──────────────────────────────────────────
test_p24_gate_ok {
    r := innovations.decide with input as {"audit": {"complete": true}}
    r.matched == true
}

test_p24_no_match {
    r := innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── P34: Remaining fixes / innovations ────────────────────────────────────────
test_p34_gate_ok {
    r := p34_innovations.decide with input as {"p34": {"enabled": true}}
    r.matched == true
}

test_p34_no_match {
    r := p34_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}

# ── P35: Cross-act coherence / innovations ────────────────────────────────────
test_p35_gate_ok {
    r := p35_innovations.decide with input as {"p35": {"coherence": true}}
    r.matched == true
}

test_p35_no_match {
    r := p35_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
}
