#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I03 RESIDENCY ADVISOR (art. 3 PIT).

Rezydencja jako DETERMINATOR NEEDS_ADVICE: 183 dni / centrum interesów życiowych.
Nigdy automatyczna decyzja; kwestionariusz + checklist dokumentów (certyfikat).
Dowód: reguła residency_advisor + parametr residency_days w thresholds.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I03"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.residency_advisor", hay)
    has_needs_advice = "NIEPEWNA" in hay and "certyfikat rezydencji" in hay
    has_threshold = not thresholds_missing(["residency_days"])

    checks.append({"name": "residency_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła residency_advisor: {has_rule}"})
    checks.append({"name": "determinator_needs_advice", "status": "OK" if has_needs_advice else "FAIL",
                   "detail": "niepewna rezydencja → NEEDS_ADVICE + checklist dokumentów"})
    checks.append({"name": "residency_days_param", "status": "OK" if has_threshold else "FAIL",
                   "detail": "parametr residency_days (183) w thresholds (ADR-002)"})

    if not has_needs_advice:
        findings.append({"id": "V3-P15-L04", "severity": "P0",
                         "evidence": "rezydencja bez determinatora NEEDS_ADVICE = ryzyko automatycznej decyzji",
                         "fix": "I03: kwestionariusz → NEEDS_ADVICE; zero automatycznej decyzji rezydencji"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"residency_rule": has_rule, "needs_advice": has_needs_advice,
                    "threshold": has_threshold},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P03 (klasy pewności), P44",
                     "rule": "niepewna rezydencja = NEEDS_ADVICE + checklist (certyfikat, kalendarz, centrum interesów)"}}
    return emit(bundle, "v3_p15_residency_advisor")


if __name__ == "__main__":
    raise SystemExit(main())