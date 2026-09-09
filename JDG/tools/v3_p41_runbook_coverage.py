#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I07 RUNBOOK COVERAGE — każdy alarm P37 ma runbook;
dokumentacja ↔ obserwowalność spięte kontraktem. Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p41_common import (BUNDLES, RUNBOOKS, emit, main_jdg_wired, now,
                           read_json, rule_present, threshold_present)

INNOVATION = "V3-P41-I07"
RULE = "jdg.v3_p41_dokumentacja.runbook_coverage"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Katalog SLO/alamów z P37 — źródło alertów
    slo = read_json(BUNDLES / "v3_p37_slo_catalog.json")
    alerts = slo.get("slos", []) if isinstance(slo, dict) else []
    alerts_count = len(alerts)
    checks.append({"name": "slo_catalog_loaded", "status": "OK" if alerts_count > 0 else "FAIL",
                   "detail": f"alerty w katalogu SLO P37: {alerts_count}"})

    # Runbooki RB01-RB06 z P37
    runbooks = sorted(p.name for p in RUNBOOKS.glob("*.md")) if RUNBOOKS.exists() else []
    rb_count = len(runbooks)
    checks.append({"name": "runbooks_present", "status": "OK" if rb_count >= 6 else "FAIL",
                   "detail": f"runbooki w docs/runbooks/: {rb_count} ({runbooks})"})

    # Pokrycie: każdy alert ma przypisany runbook (pole runbook w SLO)
    uncovered = [s.get("slo_id", "?") for s in alerts
                 if isinstance(s, dict) and not s.get("runbook")]
    coverage_ok = not uncovered
    checks.append({"name": "all_alerts_have_runbook", "status": "OK" if coverage_ok else "FAIL",
                   "detail": f"alerty bez runbooka: {uncovered if uncovered else 'brak'}"})
    if not coverage_ok:
        findings.append(f"P1: alerty P37 bez runbooka: {uncovered}")

    t = threshold_present("v3_p41_runbook_coverage_min_pct")
    checks.append({"name": "coverage_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p41_runbook_coverage_min_pct w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "slo_alerts": alerts_count,
            "runbooks": rb_count,
            "all_alerts_have_runbook": coverage_ok,
            "coverage_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_runbook_coverage")


if __name__ == "__main__":
    raise SystemExit(main())
