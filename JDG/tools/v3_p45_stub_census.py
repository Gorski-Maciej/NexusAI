#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I10 STUB CENSUS REPORT — spis stubów per domena/
warstwa, trend, TOP-10 do naprawy. Dane z rejestru I01 (narzędzie, nie
deklaracja); wpis historyczny do trendu w bundles/stub_census_history.json.
Podanalizy: AN01.
"""
from __future__ import annotations

import json

from v3_p45_common import (BUNDLES, STUB_REGISTER, emit, now, read_json,
                           rule_present)

INNOVATION = "V3-P45-I10"
RULE = "jdg.v3_p45_stub_killer.stub_census"
HISTORY = BUNDLES / "stub_census_history.json"


def main() -> int:
    checks, findings = [], []

    reg = read_json(STUB_REGISTER)
    entries = reg.get("entries", [])
    if not entries:
        findings.append({"severity": "BLOCKER",
                         "message": "rejestr stubów pusty — uruchom v3_p45_stub_register.py"})

    by_domain: dict[str, int] = {}
    by_layer: dict[str, int] = {}
    for e in entries:
        by_domain[e["domain"]] = by_domain.get(e["domain"], 0) + 1
        by_layer[e["layer"]] = by_layer.get(e["layer"], 0) + 1

    top10 = sorted(entries, key=lambda e: (not e.get("critical_domain"), e["rule_id"]))[:10]
    census = {
        "generated_at": now(),
        "total": len(entries),
        "by_domain": dict(sorted(by_domain.items(), key=lambda kv: -kv[1])),
        "by_layer": by_layer,
        "trend": reg.get("trend", "unknown"),
        "top10_to_repair": [
            {"rule_id": t["rule_id"], "file": t["file"],
             "repair_plan": t["repair_plan"], "deadline": t["deadline"]}
            for t in top10
        ],
    }

    # Historia trendu (cotygodniowy spis — I10)
    hist = read_json(HISTORY)
    series = hist.get("series", [])
    series.append({"at": now(), "total": len(entries),
                   "critical": sum(1 for e in entries if e.get("critical_domain"))})
    hist_out = {"schema_version": "1.0.0", "series": series[-52:]}  # rok wstecz
    HISTORY.write_text(json.dumps(hist_out, ensure_ascii=False, indent=2),
                       encoding="utf-8")
    checks.append({"name": "history_recorded", "status": "OK",
                   "detail": f"trend series: {len(series)} pomiarów (stub_census_history.json)"})

    # Trend spadkowy: pierwszy pomiar = baseline
    if len(series) >= 2:
        rising = series[-1]["total"] > series[-2]["total"]
        checks.append({"name": "trend_not_rising", "status": "OK" if not rising else "FAIL",
                       "detail": f"trend: {series[-2]['total']} -> {series[-1]['total']} "
                                 f"({'rosnący — TRIAGE' if rising else 'spadkowy/stabilny'})"})
    else:
        checks.append({"name": "baseline_recorded", "status": "OK",
                       "detail": f"baseline: {len(entries)} stubów ({series[0]['at'] if series else '?'})"})

    checks.append({"name": "census_complete", "status": "OK" if entries else "FAIL",
                   "detail": f"spis: total={census['total']}, domeny={len(by_domain)}, "
                             f"warstwy={by_layer}, TOP-10={len(census['top10_to_repair'])}"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": census,
        "checks": checks, "findings": findings,
    }
    (BUNDLES / "v3_p45_stub_census.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    return emit(bundle, "v3_p45_stub_census")


if __name__ == "__main__":
    raise SystemExit(main())
