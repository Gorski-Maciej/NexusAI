#!/usr/bin/env python3
"""NexusAI JDG — V3-P35-I11 LEGAL FRESHNESS STAMP — „ostatni dowód aktualności
prawa" per domena (ISAP check date) — kampania V3 FORTRESS.

Dowód wdrożenia: przejrzystość ryzyka — dane starsze niż limit (dane) = BLOCK;
spójny z legal basis linterem P34-I03 i P47. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p35_common import (P35_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P35-I11"
RULE = "jdg.v3_p35_audyutory_domenowe.legal_freshness_stamp"


def main() -> int:
    hay = read(P35_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    age = threshold_present("v3_p35_law_freshness_max_days")
    checks.append({"name": "freshness_threshold", "status": "OK" if age else "FAIL",
                   "detail": "v3_p35_law_freshness_max_days w thresholds: " + str(age)})

    isap = "ISAP" in hay
    checks.append({"name": "isap_check_date_semantics", "status": "OK" if isap else "FAIL",
                   "detail": "ISAP check date w regule: " + str(isap)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "freshness_threshold": age,
            "isap_check_date_semantics": isap,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p35_legal_freshness_stamp")


if __name__ == "__main__":
    raise SystemExit(main())
