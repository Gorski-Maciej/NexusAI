# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: VAT DEDUCTIONS (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Domknięcie luki pokrycia pakietu jdg.vat.deductions (27 reguł — odliczenie
# VAT naliczonego art. 86, pro-rata art. 90, korekta).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_vat_deductions

import data.jdg.vat.deductions

# ── Odliczenie VAT naliczonego (art. 86) ──────────────────────────────────────
test_vat_deduction_input_vat {
    r := deductions.decide with input as {
        "invoice": {"input_vat": 2300.0, "taxable": true, "expense_type": "OPERATING"}
    }
    r.matched == true
}

test_vat_deduction_no_input {
    r := deductions.decide with input as {
        "invoice": {"input_vat": 0.0, "taxable": false}
    }
    r.matched == false
}

test_vat_deduction_no_match {
    r := deductions.decide with input as {"other": {"flag": true}}
    r.matched == false
}
