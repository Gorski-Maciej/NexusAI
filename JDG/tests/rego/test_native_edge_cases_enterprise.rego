# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: EDGE CASES (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Domknięcie luki pokrycia pakietu jdg.edge_cases (187 reguł — R0546, prognozy
# przekroczenia limitu VAT art. 113, remanent likwidacyjny art. 14 VAT).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_edge_cases

import data.jdg.edge_cases

# ── Przekroczenie limitu VAT 200k w trakcie roku (art. 113 ust. 1 i 5) ───────
test_edge_vat_breach_mid_year {
    r := edge_cases.decide with input as {
        "jdg_entrepreneur": {"vat_status": "EXEMPT_SUBJECT", "sales_ytd_vat_exempt": 250000},
        "invoice": {"transaction_date": "2026-09-15"}
    }
    r.matched == true
    r.rule_id == "jdg.edge_cases.vat_breach_mid_year"
    r.vat_status_change == "EXEMPT→ACTIVE"
    r._routing == "BLOCK_AND_ALERT"
    "Art. 113 ust. 1 i 5 VAT" == r._legal_basis
}

test_edge_vat_no_breach_below_limit {
    r := edge_cases.decide with input as {
        "jdg_entrepreneur": {"vat_status": "EXEMPT_SUBJECT", "sales_ytd_vat_exempt": 100000}
    }
    r.matched == true
    r.rule_id != "jdg.edge_cases.vat_breach_mid_year"
}

# ── Remanent likwidacyjny (art. 14 ust. 1 i 4 VAT) ────────────────────────────
test_edge_vat_last_invoice_liquidation {
    r := edge_cases.decide with input as {
        "jdg_entrepreneur": {"vat_deregistration_in_progress": true}
    }
    r.matched == true
    r.rule_id == "jdg.edge_cases.vat_last_invoice_before_deregister"
    r.vat_final_settlement == true
    "Art. 14 ust. 1 i 4 VAT" == r._legal_basis
}

# ── Brak sekcji → no_match ────────────────────────────────────────────────────
test_edge_no_match {
    r := edge_cases.decide with input as {"other": {"flag": true}}
    r.matched == false
}
