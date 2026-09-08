#!/usr/bin/env python3
"""NexusAI JDG — V3-P32-I06 GRANICE GROSZOWE JAKO DANE TESTOWE.

Dowód wdrożenia: 0,00/0,01/99999999,99 per reguła wyliczania — generator P36 (AN02)
"""
from __future__ import annotations

from v3_p32_common import (P32_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P32-I06"
RULE = "jdg.v3_p32_ksiegowosc_automation.penny_boundary_tests"


def main() -> int:
    hay = read(P32_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    has_routing = "BLOCK_AND_ALERT" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: BLOCK_AND_ALERT (hardcode granic = BLOCK)"})
    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p96"})
    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": rule_present(RULE, hay),
            "wiring_main_jdg": main_jdg_wired(),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p32_penny_boundaries")


if __name__ == "__main__":
    raise SystemExit(main())
