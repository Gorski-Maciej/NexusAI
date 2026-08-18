# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: RODO ATOMIC (GLM52 P15)
# Testy reguł atomowych rodo_aml_bdo_atomic_p15 (RODO): rejestr art. 30,
# erasure art. 17 (30 dni), DPA art. 28, naruszenia art. 33 (72 h),
# DPIA art. 35, sankcje art. 83 (20 mln EUR).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_rodo

import data.jdg.micro.rodo_aml_bdo_atomic_p15 as atomic

# ── Rejestr czynności (art. 30) ────────────────────────────────────────────────
test_rodo_register_required {
    r := atomic.decide with input as {"rodo": {"register_required": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_register.r1"
    r._routing == "rodo_register"
    "Art. 30" in r._legal_basis
}

test_rodo_register_not_required {
    r := atomic.decide with input as {"rodo": {"register_required": false}}
    r.matched == false
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.no_match"
}

# ── Erasure (art. 17 — 30 dni) ─────────────────────────────────────────────────
test_rodo_erasure_requested {
    r := atomic.decide with input as {"rodo": {"erasure_requested": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_erasure.r1"
    r.erasure_deadline_days == 30
    r._routing == "rodo_erasure"
}

test_rodo_erasure_not_requested {
    r := atomic.decide with input as {"rodo": {"erasure_requested": false}}
    r.matched == false
}

# ── Podprocesorzy (art. 28 — DPA) ─────────────────────────────────────────────
test_rodo_processor_dpa_missing {
    r := atomic.decide with input as {"rodo": {"processor_engaged": true, "dpa_signed": false}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_processor.r1"
    r._routing == "rodo_processor"
}

test_rodo_processor_dpa_signed_no_obligation {
    r := atomic.decide with input as {"rodo": {"processor_engaged": true, "dpa_signed": true}}
    r.matched == false
}

# ── Naruszenia (art. 33 — 72 h) ───────────────────────────────────────────────
test_rodo_breach_72h {
    r := atomic.decide with input as {"rodo": {"breach_detected": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_breach.r1"
    r.breach_deadline_hours == 72
    r._routing == "rodo_breach"
}

test_rodo_breach_not_detected {
    r := atomic.decide with input as {"rodo": {"breach_detected": false}}
    r.matched == false
}

# ── DPIA (art. 35) ─────────────────────────────────────────────────────────────
test_rodo_dpia_high_risk {
    r := atomic.decide with input as {"rodo": {"high_risk_processing": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_dpia.r1"
    r._routing == "rodo_dpia"
}

test_rodo_dpia_low_risk {
    r := atomic.decide with input as {"rodo": {"high_risk_processing": false}}
    r.matched == false
}

# ── Sankcje (art. 83 ust. 5 — 20 mln EUR) ─────────────────────────────────────
test_rodo_fine_severe_violation {
    r := atomic.decide with input as {"rodo": {"severe_violation": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_fine.r1"
    r.rodo_fine_max_eur == 20000000
    r._routing == "rodo_fine"
}

test_rodo_fine_no_violation {
    r := atomic.decide with input as {"rodo": {"severe_violation": false}}
    r.matched == false
}

# ── Brak sekcji rodo w inpucie → no_match (bezpieczeństwo object.get) ────────
test_rodo_missing_input_section {
    r := atomic.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.no_match"
}
