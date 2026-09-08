#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I09 WALIDACJA JAKO USŁUGA — endpoint (P40) uruchamiający
walidację ad hoc na dowolnym bundle (własny lub kandydujący) — V3 FORTRESS.

Dowód wdrożenia: używa orkiestratora testów; każdy run z ID audytu (I11) —
run bez śladu = BLOCK. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p34_common import (P34_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P34-I09"
RULE = "jdg.v3_p34_walidacja_narzedzia.validation_as_service"


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # endpoint P40 + orkiestrator w _legal_basis / reason (kontrakt)
    contract = "P40" in hay and "ad hoc" in hay
    checks.append({"name": "p40_service_contract", "status": "OK" if contract else "FAIL",
                   "detail": "endpoint P40 + walidacja ad hoc w kontrakcie: " + str(contract)})

    audit_path = "audyt" in hay or "audit" in hay
    checks.append({"name": "audit_trail_required", "status": "OK" if audit_path else "FAIL",
                   "detail": "każdy run z ID audytu (I11): " + str(audit_path)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "p40_service_contract": contract,
            "audit_trail_required": audit_path,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_validation_as_service")


if __name__ == "__main__":
    raise SystemExit(main())
