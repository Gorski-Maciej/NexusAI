#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I06 SUCCESS METRIC FREEZE — definicja sukcesu zapisana
jako dane (metryki + progi + źródło) PRZED certyfikacją — ocena na dowodach,
nie na wrażeniu. Metryka bez progu = BLOCK. Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p44_common import CERT_REGISTER, emit, now, read_json, rule_present

INNOVATION = "V3-P44-I06"
RULE = "jdg.v3_p44_certyfikacja_finalna.success_metric_freeze"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    metrics = reg.get("success_metrics", []) if isinstance(reg, dict) else []
    with_threshold = [m for m in metrics if isinstance(m, dict)
                      and m.get("metric") and m.get("threshold") is not None and m.get("source")]
    no_threshold = [m.get("metric") for m in metrics if isinstance(m, dict) and m.get("threshold") is None]
    checks.append({"name": "metrics_with_threshold", "status": "OK" if metrics and len(with_threshold) == len(metrics) else "FAIL",
                   "detail": f"metryki z progiem+źródłem: {len(with_threshold)}/{len(metrics)} bez_progu={no_threshold}"})

    # Metryka z wartością zmierzoną lub jawnym "nie policzono" (zero fantazjowania)
    honest = all(isinstance(m, dict) and
                 (m.get("measured") is not None or "nie policzono" in str(m.get("measured", "")))
                 for m in metrics)
    measured_known = sum(1 for m in metrics if isinstance(m, dict)
                         and isinstance(m.get("measured"), (int, float)))
    checks.append({"name": "honest_measurements", "status": "OK" if honest else "FAIL",
                   "detail": f"metryki ze zmierzoną wartością liczbową: {measured_known}/{len(metrics)} (reszta jawna)"})

    if no_threshold:
        findings.append({"severity": "BLOCKER", "message": f"metryki bez progu: {no_threshold}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "metrics_total": len(metrics),
            "measured_numeric": measured_known,
            "metrics_without_threshold": len(no_threshold),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_metric_freeze")


if __name__ == "__main__":
    raise SystemExit(main())
