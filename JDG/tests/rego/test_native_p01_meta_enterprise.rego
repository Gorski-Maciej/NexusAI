# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: P01 FUNDAMENT + HYPER META (GLM52 P18 — TESTY / CI)
# Ostatnie pakiety z regułami bez testów: jdg.p01_fundament_innovations (digital
# twin), jdg.hyper_plan45_meta (consistency check).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_p01_meta

import data.jdg.p01_fundament_innovations
import data.jdg.hyper_plan45_meta

# ── P01: Digital twin (bliźniak cyfrowy) ──────────────────────────────────────
test_p01_digital_twin {
    r := p01_fundament_innovations.decide with input as {"digital_twin": {"simulate": true}}
    r.matched == true
    r.rule_id == "jdg.p01_fundament_innovations.digital_twin"
}

test_p01_no_match {
    r := p01_fundament_innovations.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.p01_fundament_innovations.no_match"
}

# ── Hyper meta: consistency check ─────────────────────────────────────────────
test_hyper_meta_consistency {
    r := hyper_plan45_meta.decide with input as {"hyper": {"consistency": true}}
    r.matched == true
    r.rule_id == "jdg.meta.consistency_check"
}

test_hyper_meta_no_match {
    r := hyper_plan45_meta.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.meta.no_match"
}
