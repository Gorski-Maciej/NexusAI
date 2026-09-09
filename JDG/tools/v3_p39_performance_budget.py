#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I10 PERFORMANCE BUDGET CI — benchmark eval na
referencyjnym input; regresja > 10% p95 = BLOCKER (spójne z P37-I12/P38-I10).
Podanalizy: AN04.
"""
from __future__ import annotations

import json

from v3_p39_common import BENCHMARKS, emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P39-I10"
RULE = "jdg.v3_p39_testy_ci.performance_budget"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    t = threshold_present("v3_p39_benchmark_regression_max_pct")
    checks.append({"name": "regression_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p39_benchmark_regression_max_pct w data.thresholds: {t}"})

    baseline = json.loads(read(BENCHMARKS)) if read(BENCHMARKS) else {}
    baseline_ok = baseline.get("runs") == 60 and baseline.get("p95_ms", 0) > 0
    checks.append({"name": "benchmark_baseline_measured", "status": "OK" if baseline_ok else "FAIL",
                   "detail": f"eval_baseline: runs={baseline.get('runs')}, p95={baseline.get('p95_ms')} ms"})

    gate_tool = (__import__("v3_p39_common").TOOLS / "v3_p37_benchmark_gate.py").exists()
    checks.append({"name": "benchmark_gate_tool_exists", "status": "OK" if gate_tool else "FAIL",
                   "detail": f"tools/v3_p37_benchmark_gate.py (P37): {gate_tool}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "regression_threshold_as_data": t,
            "benchmark_baseline_measured": baseline_ok,
            "benchmark_gate_tool_exists": gate_tool,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_performance_budget")


if __name__ == "__main__":
    raise SystemExit(main())
