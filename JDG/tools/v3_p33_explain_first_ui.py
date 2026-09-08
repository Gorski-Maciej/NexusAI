#!/usr/bin/env python3
"""NexusAI JDG — V3-P33-I09 EXPLAIN-FIRST UI — propozycja AI zawsze z wyjaśnieniem
(który przepis, który dowód) — kampania V3 FORTRESS.

Dowód wdrożenia: zakaz czarnoskrzynkowych sugestii — brak wyjaśnienia (przepis/
dowód/percentyl pewności) = BLOCK (AI Act przejrzystość; RODO art. 22).
Podanalizy: 5.4.
"""
from __future__ import annotations

from v3_p33_common import (P33_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P33-I09"
RULE = "jdg.v3_p33_neural_mesh_ai.explain_first_ui"


def main() -> int:
    hay = read(P33_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    req = threshold_present("v3_p33_explanation_required")
    checks.append({"name": "explanation_required", "status": "OK" if req else "FAIL",
                   "detail": "v3_p33_explanation_required w thresholds: " + str(req)})

    # wyjaśnienie zawiera przepis + dowód + percentyl pewności
    fields = all(f in hay for f in ("legal_reference", "evidence", "confidence_percentile"))
    checks.append({"name": "explanation_fields", "status": "OK" if fields else "FAIL",
                   "detail": "legal_reference + evidence + confidence_percentile: " + str(fields)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "explanation_required": req,
            "explanation_fields": fields,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p33_explain_first_ui")


if __name__ == "__main__":
    raise SystemExit(main())
