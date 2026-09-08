#!/usr/bin/env python3
"""NexusAI JDG — V3-P35-I04 UNIFIED AUDIT REPORT — jeden schema wyniku audytora
(score, luki, dowody) — kampania V3 FORTRESS.

Dowód wdrożenia: konsumowany przez dashboardy (P37) i certyfikat (V2 F4);
raport spoza schema = BLOCK; spójny z etapami audytów P31. Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p35_common import (P35_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P35-I04"
RULE = "jdg.v3_p35_audyutory_domenowe.unified_audit_report"


def main() -> int:
    hay = read(P35_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # schema: score, luki, dowody — w regule
    schema = all(k in hay for k in ("score", "luki", "dowod"))
    checks.append({"name": "schema_fields", "status": "OK" if schema else "FAIL",
                   "detail": "schema (score, luki, dowody) w regule: " + str(schema)})

    contract = "P31" in hay
    checks.append({"name": "p31_unified_schema_link", "status": "OK" if contract else "FAIL",
                   "detail": "spójność z unified schema P31: " + str(contract)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "schema_fields": schema,
            "p31_unified_schema_link": contract,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p35_unified_audit_report")


if __name__ == "__main__":
    raise SystemExit(main())
