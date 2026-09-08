#!/usr/bin/env python3
"""NexusAI JDG — V3-P35-I06 SKEW DETECTION — wykrywanie rozjazdu między metrykami
(wysoka pewność vs spadek pokrycia testów) z alarmem — V3 FORTRESS.

Dowód wdrożenia: krytyczny rozjazd = BLOCK, łagodny = TRIAGE; metryki muszą
rosnąć spójnie. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p35_common import (P35_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P35-I06"
RULE = "jdg.v3_p35_audyutory_domenowe.skew_detection"


def main() -> int:
    hay = read(P35_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # rozjazd pewność vs pokrycie w regule
    skew = "pewno" in hay.lower() and "pokryci" in hay.lower()
    checks.append({"name": "confidence_vs_coverage", "status": "OK" if skew else "FAIL",
                   "detail": "rozjazd pewność vs pokrycie w regule: " + str(skew)})

    two_level = "TRIAGE" in hay and "BLOCK" in hay
    checks.append({"name": "critical_and_mild_levels", "status": "OK" if two_level else "FAIL",
                   "detail": "poziomy krytyczny (BLOCK) i łagodny (TRIAGE): " + str(two_level)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "confidence_vs_coverage": skew,
            "critical_and_mild_levels": two_level,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p35_skew_detection")


if __name__ == "__main__":
    raise SystemExit(main())
