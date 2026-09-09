#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I12 TEST IMPACT MAP — mapa zmiana_pliku → dotknięte
testy (z routing P02); PR uruchamia tylko istotne testy bez utraty
bezpieczeństwa (golden zawsze). Podanalizy: AN04.
"""
from __future__ import annotations

import json

from v3_p39_common import emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P39-I12"
RULE = "jdg.v3_p39_testy_ci.impact_map"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    t = threshold_present("v3_p39_impact_map_max_stale_days")
    checks.append({"name": "staleness_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p39_impact_map_max_stale_days w data.thresholds: {t}"})

    strategy = json.loads(read(__import__("v3_p39_common").TEST_STRATEGY)) if read(__import__("v3_p39_common").TEST_STRATEGY) else {}
    im = strategy.get("impact_map", {})
    ok_im = im.get("source") == "P02_routing_registry" and im.get("golden_always_runs") is True
    checks.append({"name": "impact_map_convention_as_data", "status": "OK" if ok_im else "FAIL",
                   "detail": f"impact_map: source={im.get('source')}, golden_always={im.get('golden_always_runs')}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "staleness_threshold_as_data": t,
            "impact_map_convention_ok": ok_im,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_impact_map")


if __name__ == "__main__":
    raise SystemExit(main())
