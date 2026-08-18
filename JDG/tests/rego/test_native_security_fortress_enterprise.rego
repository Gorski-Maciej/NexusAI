# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: SECURITY FORTRESS (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Domknięcie luki pokrycia pakietu jdg.security.fortress (19 reguł — P900
# sharded router, niemutowalne werdykty, temporalność między domenami).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_security_fortress

import data.jdg.security.fortress

# ── P900: Obejście sharded routera (vendor=PL, delivery=DE) ──────────────────
test_fortress_cross_border_delivery {
    r := fortress.decide with input as {
        "vendor": {"country": "PL"},
        "delivery": {"country": "DE"}
    }
    r.matched == true
    r.rule_id == "jdg.security.fortress.cross_border_delivery_check"
    r.sec_severity == "CRITICAL"
}

# ── Niemutowalne werdykty (allowlist) ─────────────────────────────────────────
test_fortress_immutable_verdicts {
    r := fortress.decide with input as {"verdict": {"package": "jdg.zus"}}
    r.matched == true
    r.rule_id == "jdg.security.fortress.immutable_verdict_allowlist"
}

# ── Brak sekcji → no_match ────────────────────────────────────────────────────
test_fortress_no_match {
    r := fortress.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.security.fortress.no_match"
}
