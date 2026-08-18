# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: AML / CBDD ATOMIC (GLM52 P15)
# Testy reguł atomowych rodo_aml_bdo_atomic_p15 (AML): CBDD art. 28a-34,
# transakcje okazjonalne > 15 000 EUR (art. 34), STR/GIIF 48 h (art. 74-80),
# beneficjent rzeczywisty (art. 28a, CRBR).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_aml

import data.jdg.micro.rodo_aml_bdo_atomic_p15 as atomic

# ── CBDD (art. 28a-34) ─────────────────────────────────────────────────────────
test_aml_cbdd_required {
    r := atomic.decide with input as {"aml": {"cbdd_required": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.aml_cbdd.r1"
    r._routing == "aml_cbdd"
    "Dz.U. 2025 poz. 213" in r._legal_basis
}

test_aml_cbdd_not_required {
    r := atomic.decide with input as {"aml": {"cbdd_required": false}}
    r.matched == false
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.no_match"
}

# ── Transakcja gotówkowa > 15 000 EUR (art. 34) ───────────────────────────────
test_aml_cash_over_15k {
    r := atomic.decide with input as {"aml": {"cash_amount_eur": 20000}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.aml_cash_15k.r1"
    r.aml_cash_threshold_eur == 15000
    r._routing == "aml_cash_15k"
}

test_aml_cash_exact_15k_no_obligation {
    r := atomic.decide with input as {"aml": {"cash_amount_eur": 15000}}
    r.matched == false
}

test_aml_cash_below_15k {
    r := atomic.decide with input as {"aml": {"cash_amount_eur": 10000}}
    r.matched == false
}

# ── STR / GIIF (art. 74-80 — 48 h) ────────────────────────────────────────────
test_aml_str_suspicious {
    r := atomic.decide with input as {"aml": {"suspicious_transaction": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.aml_str.r1"
    r.str_deadline_hours == 48
    r._routing == "aml_str"
}

test_aml_str_not_suspicious {
    r := atomic.decide with input as {"aml": {"suspicious_transaction": false}}
    r.matched == false
}

# ── Beneficjent rzeczywisty (art. 28a, CRBR) ──────────────────────────────────
test_aml_beneficiary_required {
    r := atomic.decide with input as {"aml": {"beneficiary_required": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.aml_beneficiary.r1"
    r._routing == "aml_beneficiary"
}

test_aml_beneficiary_not_required {
    r := atomic.decide with input as {"aml": {"beneficiary_required": false}}
    r.matched == false
}

# ── Brak sekcji aml w inpucie → no_match ──────────────────────────────────────
test_aml_missing_input_section {
    r := atomic.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.no_match"
}
