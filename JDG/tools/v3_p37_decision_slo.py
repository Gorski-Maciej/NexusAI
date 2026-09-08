#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I01 DECISION SLO CONTRACT — SLO jako dane (YAML/JSON):
metryka, próg, okno, akcja, runbook — V3 FORTRESS.

Dowód wdrożenia: katalog bundles/v3_p37_slo_catalog.json (6 SLO z progiem,
oknem, akcją, runbookiem); SLO bez progu/akcji = BLOCK w regułach OPA;
zmiana SLO jak zmiana parametru (ADR-002/P06). Podanalizy: AN02.
"""
from __future__ import annotations

import json

from v3_p37_common import (P37_RULES, SLO_CATALOG, emit, main_jdg_wired, now,
                           read, rule_present, threshold_present)

INNOVATION = "V3-P37-I01"
RULE = "jdg.v3_p37_obserwowalnosc.decision_slo"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    catalog_raw = read(SLO_CATALOG)
    catalog = json.loads(catalog_raw) if catalog_raw else {}
    slos = catalog.get("slos", [])
    complete = [s for s in slos if all(k in s for k in
                ("metric", "target", "window_days", "action", "runbook"))]
    checks.append({"name": "slo_catalog_as_data", "status": "OK" if len(complete) >= 6 else "FAIL",
                   "detail": f"SLO kompletnych: {len(complete)}/{len(slos)} (wymagane ≥ 6)"})

    thr = threshold_present("v3_p37_law_freshness_sla_days") and \
        threshold_present("v3_p37_latency_p95_max_ms")
    checks.append({"name": "slo_thresholds_as_data", "status": "OK" if thr else "FAIL",
                   "detail": f"progi SLO w data.thresholds.v3_p37: {thr}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "slos_complete": len(complete),
            "slos_total": len(slos),
            "slo_thresholds_as_data": thr,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_decision_slo")


if __name__ == "__main__":
    raise SystemExit(main())
