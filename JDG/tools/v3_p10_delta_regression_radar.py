#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I12 DELTA REGRESSION RADAR
=================================================
Wczesny sygnał dryfu reguł: rosnąca liczba nieuzasadnionych delt (UVR) w
czasie = radar regresji. Sprawdza metrics_pewnosci.json (uvr/tcl/rv) i
golden set, raportuje trend i próg alarmowy.

Usage:
  python tools/v3_p10_delta_regression_radar.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    metrics = BUNDLES / "metrics_pewnosci.json"
    golden = BUNDLES / "golden_verdicts.json"
    uvr = tcl = rv = None
    generated = None
    if metrics.exists():
        m = json.loads(metrics.read_text(encoding="utf-8"))
        uvr, tcl, rv = m.get("uvr"), m.get("tcl"), m.get("rv")
        generated = m.get("generated_at")

    verdicts = {}
    if golden.exists():
        verdicts = json.loads(golden.read_text(encoding="utf-8")).get("verdicts", {})

    uvr_threshold = 100  # próg alarmowy: >100 nieuzasadnionych delt = dryf
    radar_level = "GREEN"
    if uvr is not None:
        radar_level = "RED" if uvr > uvr_threshold else ("AMBER" if uvr > uvr_threshold * 0.5 else "GREEN")

    checks.append({"name": "metrics_source", "status": "OK" if uvr is not None else "FAIL",
                   "detail": f"metrics_pewnosci.json: uvr={uvr}, tcl={tcl}, rv={rv} "
                             f"(generated_at={generated})"})
    checks.append({"name": "radar_level", "status": "OK" if radar_level == "GREEN" else "FAIL",
                   "detail": f"poziom radaru regresji: {radar_level} (próg uvr>{uvr_threshold} = RED)"})

    if uvr is not None and uvr > uvr_threshold * 0.5:
        findings.append({"id": "V3-P10-L12", "severity": "P1",
                         "evidence": f"uvr={uvr} (metrics_pewnosci.json) — liczba nieuzasadnionych "
                                     f"delt powyżej 50% progu alarmowego ({uvr_threshold}); brak "
                                     f"szeregu czasowego UVR i radaru w CI — dryf reguł wykrywany "
                                     f"za późno",
                         "fix": "I12: radar regresji — szereg czasowy UVR per re-generacja, "
                                "alert przy trendzie rosnącym + blokada awansu reguł (P07)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I12",
        "name": "Delta Regression Radar — wczesny sygnał dryfu reguł",
        "generated_at": now(),
        "gate": gate,
        "metrics": {"uvr": uvr, "tcl": tcl, "rv": rv, "radar_level": radar_level,
                    "uvr_alarm_threshold": uvr_threshold,
                    "golden_verdict_count": len(verdicts)},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P37 (obserwowalność), P07 (awans reguł), P39 (CI)",
                     "rule": "rosnący trend UVR = alarm radaru + blokada awansu automatycznego "
                             "reguł (delta > próg = brak awansu)"}}
    (BUNDLES / "v3_p10_delta_regression_radar.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I12] gate={gate} uvr={uvr} radar={radar_level}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
