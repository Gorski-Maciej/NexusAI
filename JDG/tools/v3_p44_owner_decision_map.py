#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I04 OWNER DECISION MAP — mapa decyzyjna właściciela:
działanie → zależności → kto decyduje → priorytet (jedna strona). P0 bez
decydenta = BLOCK. Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p44_common import CERT_REGISTER, emit, now, read_json, rule_present

INNOVATION = "V3-P44-I04"
RULE = "jdg.v3_p44_certyfikacja_finalna.owner_decision_map"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    rows = reg.get("owner_decision_map", []) if isinstance(reg, dict) else []
    complete = bool(rows) and all(
        isinstance(r, dict) and r.get("action") and r.get("dependencies")
        and r.get("decision_owner") and r.get("priority") for r in rows)
    checks.append({"name": "map_rows_complete", "status": "OK" if complete else "FAIL",
                   "detail": f"wiersze kompletne (akcja/zależności/decydent/priorytet): {len(rows)}"})

    p0_unassigned = [r.get("action") for r in rows if isinstance(r, dict)
                     and r.get("priority") == "P0" and not r.get("decision_owner")]
    checks.append({"name": "p0_all_assigned", "status": "OK" if not p0_unassigned else "FAIL",
                   "detail": f"P0 bez decydenta (BLOCK): {p0_unassigned}"})

    one_page = len(rows) <= 12
    checks.append({"name": "one_page_constraint", "status": "OK" if one_page else "FAIL",
                   "detail": f"mapa na jednej stronie (≤12 wierszy): {len(rows)}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "rows": len(rows),
            "p0_rows": sum(1 for r in rows if isinstance(r, dict) and r.get("priority") == "P0"),
            "p0_unassigned": len(p0_unassigned),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_owner_decision_map")


if __name__ == "__main__":
    raise SystemExit(main())
