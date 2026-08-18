# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: NKUP (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Domknięcie luki pokrycia pakietu jdg.nkup_enterprise (59 reguł — art. 23 PIT:
# wydatki nie stanowiące kosztów uzyskania przychodów).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_nkup

import data.jdg.nkup_enterprise

# ── NKUP-001: Środek trwały (art. 23 ust. 1 pkt 1) ───────────────────────────
test_nkup_fixed_asset {
    r := nkup_enterprise.decide with input as {
        "invoice": {"expense_type": "FIXED_ASSET", "amount_net": 25000,
                    "description": "Maszyna CNC", "kst_group": "3"}
    }
    r.matched == true
    r.rule_id == "jdg.nkup.fixed_asset_purchase_not_kup"
    r.kus_qualification == "NKUP"
    "Art. 23 ust. 1 pkt 1 lit. a-c PIT" == r._legal_basis
}

test_nkup_fixed_asset_below_threshold {
    # poniżej progu 10 000 — nie kwalifikuje się jako NKUP ŚT
    r := nkup_enterprise.decide with input as {
        "invoice": {"expense_type": "FIXED_ASSET", "amount_net": 5000}
    }
    r.matched == false
    r.rule_id == "jdg.nkup.no_match"
}

# ── Brak sekcji → no_match ────────────────────────────────────────────────────
test_nkup_no_match {
    r := nkup_enterprise.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.nkup.no_match"
}
