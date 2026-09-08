#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I12 BENCHMARK REGRESSION GATE — benchmarki eval w CI
z progiem regresji (p95 > +10% = BLOCK) przed deployem bundle — V3 FORTRESS.

Dowód wdrożenia: baseline .benchmarks/eval_baseline.json ZMIERZONY (60
przebiegów); gate funkcjonalny tools/v3_p37_benchmark_gate.py uruchomiony
(PASS); regresja > próg = BLOCK; brak baseline = BLOCK. Podanalizy: AN04.
"""
from __future__ import annotations

import json
import subprocess
import sys

from v3_p37_common import (BASE, BENCHMARKS, P37_RULES, emit, main_jdg_wired,
                           now, read, rule_present, threshold_present)

INNOVATION = "V3-P37-I12"
RULE = "jdg.v3_p37_obserwowalnosc.benchmark_regression"
GATE_TOOL = BASE / "tools" / "v3_p37_benchmark_gate.py"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p37_benchmark_regression_max_pct")
    checks.append({"name": "regression_max_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p37_benchmark_regression_max_pct w thresholds: {thr}"})

    baseline_raw = read(BENCHMARKS)
    baseline = json.loads(baseline_raw) if baseline_raw else {}
    has_baseline = bool(baseline) and "p95_ms" in baseline and "runs" in baseline
    checks.append({"name": "measured_baseline_exists", "status": "OK" if has_baseline else "FAIL",
                   "detail": f"baseline zmierzony (p95={baseline.get('p95_ms')} ms, "
                             f"runs={baseline.get('runs')}): {has_baseline}"})

    gate_exit = subprocess.run([sys.executable, str(GATE_TOOL)], capture_output=True,
                               text=True, timeout=600)
    gate_ok = gate_exit.returncode == 0 and "PASS" in gate_exit.stdout
    checks.append({"name": "gate_tool_run_pass", "status": "OK" if gate_ok else "FAIL",
                   "detail": f"uruchomienie gate: {gate_exit.stdout.strip()} (exit {gate_exit.returncode})"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "regression_max_threshold": thr,
            "measured_baseline_exists": has_baseline,
            "baseline_p95_ms": baseline.get("p95_ms"),
            "gate_run_pass": gate_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_benchmark_regression")


if __name__ == "__main__":
    raise SystemExit(main())
