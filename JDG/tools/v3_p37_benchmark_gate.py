#!/usr/bin/env python3
"""NexusAI JDG — V3-P37 BENCHMARK GATE — pomiar vs .benchmarks/eval_baseline.json
(SLO-06 / I12) — V3 FORTRESS.

Mierzy end-to-end cold-start czas eval pakietu v3_p37_obserwowalnosc tą samą
metodyką co baseline (12 przypadków × 5 przebiegów) i porównuje p95 z
baseline p95 × (1 + max_regression_pct). Regresja > próg = exit 1 (BLOCK
deployu bundle); baseline brak/uszkodzony = exit 2 (BLOCK — CI nie ma czego
bronić).

Użycie: python3 tools/v3_p37_benchmark_gate.py [--json]
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
REPO = BASE.parent
OPA = REPO / "bin" / "opa"
BASELINE = BASE / ".benchmarks" / "eval_baseline.json"
EXIT_OK, EXIT_REGRESSION, EXIT_NO_BASELINE = 0, 1, 2

CASES = {
    "decision_slo": {"analysis": "decision_slo", "decision_slo": {
        "slos_without_threshold_or_action": 0, "slo_violations_open": 0, "slos_total": 6}},
    "law_freshness_sla": {"analysis": "law_freshness_sla", "law_freshness_sla": {
        "acts_unverified": 0, "acts_stale": 1}},
    "needs_advice_radar": {"analysis": "needs_advice_radar", "needs_advice_radar": {
        "needs_advice_without_reason": 0, "spike_detected": False}},
    "latency_budget": {"analysis": "latency_budget", "latency_budget": {
        "domains_over_budget": 0, "domains_over_2x_budget": 0}},
    "certificate_telemetry": {"analysis": "certificate_telemetry", "certificate_telemetry": {
        "decisions_without_certificate": 0, "certificates_incomplete": 0, "decisions_total": 100}},
    "error_budget_freeze": {"analysis": "error_budget_freeze", "error_budget_freeze": {
        "deploys_during_freeze": 0, "budget_remaining_pct": 80}},
    "anomaly_detection": {"analysis": "anomaly_detection", "anomaly_detection": {
        "false_alarms_no_seasonality": 0, "anomalies_unaccounted": 0, "anomalies_explained": 5}},
    "golden_drift_watch": {"analysis": "golden_drift_watch", "golden_drift_watch": {
        "drifted_decisions": 0, "checked_decisions": 500}},
    "runbook_as_code": {"analysis": "runbook_as_code", "runbook_as_code": {
        "alerts_without_runbook": 0, "runbooks_stale": 0, "alerts_total": 12}},
    "status_page": {"analysis": "status_page", "status_page": {
        "missing_sections": 0, "stale_days": 0}},
    "decision_cost": {"analysis": "decision_cost", "decision_cost": {
        "ai_decisions_without_cost": 0, "decisions_over_cost_limit": 0}},
    "benchmark_regression": {"analysis": "benchmark_regression", "benchmark_regression": {
        "regression_pct": 2}},
}


def _percentile(sorted_vals: list[float], p: float) -> float:
    k = (len(sorted_vals) - 1) * p / 100.0
    f, c = int(k), min(int(k) + 1, len(sorted_vals) - 1)
    return sorted_vals[f] + (sorted_vals[c] - sorted_vals[f]) * (k - f)


def measure() -> list[float]:
    times: list[float] = []
    for ctx in CASES.values():
        payload = json.dumps({"jdg_entrepreneur": {"v3_p37_check": True},
                              "v3_p37": ctx})
        for _ in range(5):
            t0 = time.perf_counter()
            subprocess.run(
                [str(OPA), "eval", "-I",
                 "-d", str(BASE / "rules" / "v3_p37_obserwowalnosc_enterprise.rego"),
                 "-d", str(BASE / "rules" / "thresholds_jdg.rego"),
                 "data.jdg.v3_p37_obserwowalnosc.decide"],
                input=payload, capture_output=True, text=True, check=True,
                cwd=REPO)
            times.append((time.perf_counter() - t0) * 1000)
    return times


def main() -> int:
    parser = argparse.ArgumentParser(description="V3-P37 benchmark regression gate")
    parser.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args()

    if not BASELINE.exists():
        if args.as_json:
            print(json.dumps({"gate": "BLOCK", "reason": "no_baseline"}))
        else:
            print("[P37 GATE] BLOCK: brak .benchmarks/eval_baseline.json (exit 2)")
        return EXIT_NO_BASELINE
    baseline = json.loads(BASELINE.read_text(encoding="utf-8"))
    max_pct = baseline["regression_gate"]["max_regression_pct"]

    times = measure()
    vals = sorted(times)
    p50 = round(_percentile(vals, 50), 2)
    p95 = round(_percentile(vals, 95), 2)
    base_p95 = baseline["p95_ms"]
    regression_pct = round((p95 - base_p95) / base_p95 * 100, 2)
    ok = regression_pct <= max_pct

    report = {"gate": "PASS" if ok else "BLOCK",
              "measured_p95_ms": p95, "measured_p50_ms": p50,
              "baseline_p95_ms": base_p95,
              "regression_pct": regression_pct,
              "max_regression_pct": max_pct, "runs": len(times)}
    if args.as_json:
        print(json.dumps(report, indent=2))
    else:
        print(f"[P37 GATE] p95={p95} ms vs baseline {base_p95} ms → "
              f"regresja {regression_pct}% (limit {max_pct}%) → "
              f"{'PASS' if ok else 'BLOCK'}")
    return EXIT_OK if ok else EXIT_REGRESSION


if __name__ == "__main__":
    raise SystemExit(main())
