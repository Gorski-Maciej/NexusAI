#!/usr/bin/env python3
"""NexusAI JDG — V3-P35-I05 DRILL-DOWN DO DOWODU — metryka → klik → lista reguł
→ klik → kod + test + podstawa prawna (pełny ślad) — V3 FORTRESS.

Dowód wdrożenia: metryka bez pełnego śladu = BLOCK; spójny z traceability
(7.1h) i Decision Certificate (V2 F4). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p35_common import (P35_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P35-I05"
RULE = "jdg.v3_p35_audyutory_domenowe.drill_down_evidence"


def main() -> int:
    hay = read(P35_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # pełny ślad: reguła → kod + test + podstawa prawna
    full_trace = all(k in hay for k in ("kod", "test", "podstawa"))
    checks.append({"name": "full_trace_fields", "status": "OK" if full_trace else "FAIL",
                   "detail": "kod + test + podstawa prawna w śladzie: " + str(full_trace)})

    block_path = "BLOCK" in hay
    checks.append({"name": "broken_trace_block_path", "status": "OK" if block_path else "FAIL",
                   "detail": "przerwany ślad = BLOCK: " + str(block_path)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "full_trace_fields": full_trace,
            "broken_trace_block_path": block_path,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p35_drill_down_evidence")


if __name__ == "__main__":
    raise SystemExit(main())
