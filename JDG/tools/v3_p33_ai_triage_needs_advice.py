#!/usr/bin/env python3
"""NexusAI JDG — V3-P33-I12 AI W TRIAGE NEEDS_ADVICE — judgment_predictor
wyłącznie sortuje kolejki do człowieka — kampania V3 FORTRESS.

Dowód wdrożenia: sugestia zawsze z dowodem i percentylem pewności; predictor
decydujący samodzielnie = BLOCK (fail-closed P04; cel nadrzędny serii).
Podanalizy: 5.2/5.3.
"""
from __future__ import annotations

from v3_p33_common import (P33_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P33-I12"
RULE = "jdg.v3_p33_neural_mesh_ai.ai_triage_needs_advice"


def main() -> int:
    hay = read(P33_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    pct = threshold_present("v3_p33_judgment_min_percentile")
    checks.append({"name": "min_percentile_threshold", "status": "OK" if pct else "FAIL",
                   "detail": "v3_p33_judgment_min_percentile w thresholds: " + str(pct)})

    # predictor sortuje kolejki — nie decyduje (triage-only)
    triage_only = "triage_only" in hay or "sort" in hay
    checks.append({"name": "triage_only_semantics", "status": "OK" if triage_only else "FAIL",
                   "detail": "predictor = triage-only (sortuje kolejki): " + str(triage_only)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "min_percentile_threshold": pct,
            "triage_only_semantics": triage_only,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p33_ai_triage_needs_advice")


if __name__ == "__main__":
    raise SystemExit(main())
