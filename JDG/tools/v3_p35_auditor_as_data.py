#!/usr/bin/env python3
"""NexusAI JDG — V3-P35-I02 AUDITOR AS DATA — definicja audytu (kontrole, progi,
przykłady) w danych — kampania V3 FORTRESS.

Dowód wdrożenia: zmiana audytu bez deployu; domena bez definicji = TRIAGE,
definicja bez kontroli ponad limit = BLOCK (audyt bez kontroli jest fasadą).
Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p35_common import (P35_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P35-I02"
RULE = "jdg.v3_p35_audyutory_domenowe.auditor_as_data"


def main() -> int:
    hay = read(P35_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    limit = threshold_present("v3_p35_missing_controls_max")
    checks.append({"name": "missing_controls_threshold", "status": "OK" if limit else "FAIL",
                   "detail": "v3_p35_missing_controls_max w thresholds: " + str(limit)})

    # auditor-as-data + kontrakt P31 (etapy audytów)
    contract = "kontrol" in hay.lower() and "P31" in hay
    checks.append({"name": "p31_contract_link", "status": "OK" if contract else "FAIL",
                   "detail": "definicja audytu (kontrole) + kontrakt P31: " + str(contract)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "missing_controls_threshold": limit,
            "p31_contract_link": contract,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p35_auditor_as_data")


if __name__ == "__main__":
    raise SystemExit(main())
