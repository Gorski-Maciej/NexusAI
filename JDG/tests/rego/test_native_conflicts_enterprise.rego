# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: CONFLICTS (GLM52 P18 — TESTY / CI / JAKOŚĆ)
# Domknięcie luki pokrycia pakietu jdg.conflicts (27 reguł — detektor konfliktów
# między regułami: IP Box vs B+R na tym samym dochodzie, itd.).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_conflicts

import data.jdg.conflicts

# ── Konflikt IP Box vs B+R (art. 30ca vs art. 26e PIT) ───────────────────────
test_conflicts_ip_box_vs_rd {
    r := conflicts.decide with input as {
        "jdg_entrepreneur": {"income_ip_box": 100000, "income_rd_relief": 100000}
    }
    r.matched == true
    r.rule_id == "jdg.conflicts.ip_box_vs_rd_same_income"
}

# ── Brak konfliktu → no_conflicts ─────────────────────────────────────────────
test_conflicts_none {
    r := conflicts.decide with input as {
        "jdg_entrepreneur": {"income_ip_box": 0, "income_rd_relief": 0}
    }
    r.matched == false
    r.rule_id == "jdg.conflicts.no_conflicts"
}

test_conflicts_no_match_fallback {
    r := conflicts.decide with input as {"other": {"flag": true}}
    r.matched == false
}
