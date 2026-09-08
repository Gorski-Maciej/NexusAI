#!/usr/bin/env python3
"""NexusAI JDG — V3-P35-I12 AUDYT INVERSE — audytor generuje przypadki, dla
których AUTO_POST byłby niebezpieczny (negatywna przestrzeń) — V3 FORTRESS.

Dowód wdrożenia: dowód defensywności obowiązkowy — wyciek AUTO_POST w
negatywnej przestrzeni = BLOCK; domena bez przypadków inverse = TRIAGE
(minimum jako dane). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p35_common import (P35_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P35-I12"
RULE = "jdg.v3_p35_audyutory_domenowe.inverse_audit"


def main() -> int:
    hay = read(P35_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    min_c = threshold_present("v3_p35_inverse_cases_min")
    checks.append({"name": "inverse_min_threshold", "status": "OK" if min_c else "FAIL",
                   "detail": "v3_p35_inverse_cases_min w thresholds: " + str(min_c)})

    neg = "negatywnej przestrzeni" in hay and "AUTO_POST" in hay
    checks.append({"name": "negative_space_semantics", "status": "OK" if neg else "FAIL",
                   "detail": "negatywna przestrzeń AUTO_POST w regule: " + str(neg)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "inverse_min_threshold": min_c,
            "negative_space_semantics": neg,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p35_inverse_audit")


if __name__ == "__main__":
    raise SystemExit(main())
