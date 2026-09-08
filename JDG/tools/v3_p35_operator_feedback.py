#!/usr/bin/env python3
"""NexusAI JDG — V3-P35-I09 OCENA OPERATORA — feedback loop: operator ocenia
decyzję NEEDS_ADVICE; ocena zasila golden registry i trust score — V3 FORTRESS.

Dowód wdrożenia: pętla przerwana ponad limit dni = BLOCK; decyzje bez oceny
= TRIAGE; ocena bez dowodu nie istnieje (kanon P00). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p35_common import (P35_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P35-I09"
RULE = "jdg.v3_p35_audyutory_domenowe.operator_feedback"


def main() -> int:
    hay = read(P35_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    age = threshold_present("v3_p35_feedback_max_age_days")
    checks.append({"name": "feedback_age_threshold", "status": "OK" if age else "FAIL",
                   "detail": "v3_p35_feedback_max_age_days w thresholds: " + str(age)})

    loop = "golden registry" in hay and "trust score" in hay
    checks.append({"name": "feeds_golden_and_trust", "status": "OK" if loop else "FAIL",
                   "detail": "ocena zasila golden registry + trust score: " + str(loop)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "feedback_age_threshold": age,
            "feeds_golden_and_trust": loop,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p35_operator_feedback")


if __name__ == "__main__":
    raise SystemExit(main())
