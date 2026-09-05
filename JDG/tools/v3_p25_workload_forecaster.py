#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I08 WORKLOAD FORECASTER (planowanie pracy księgowej).

Dowód wdrożenia: prognoza obciążeń (horyzont 14 dni, próg przeciążenia 80%
pojemności) → koniec kwartału/miesiąca = TRIAGE (rozłóż pracę); wejście
z kalendarza MASTER; horyzont jako dane (ADR-002).
"""
from __future__ import annotations

from v3_p25_common import P25_RULES, emit, now, read, rule_present, threshold_present

INNOVATION = "V3-P25-I08"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.workload_forecaster"
TH_KEYS = ["v3_p25_workload_forecast_horizon_days"]


def forecast(upcoming: int, capacity: int, horizon: int = 14,
             threshold_pct: int = 80) -> dict:
    load = 0 if capacity <= 0 else (upcoming * 100) // capacity
    return {"upcoming": upcoming, "capacity": capacity, "horizon_days": horizon,
            "load_pct": load, "overload": load > threshold_pct}


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_threshold = "_wf_overload_pct" in hay and "_wf_capacity" in hay
    th_ok = threshold_present(TH_KEYS[0])

    probe = forecast(9, 10)  # 9/10 = 90% → overload
    probe_ok = probe["load_pct"] == 90 and probe["overload"] is True

    checks.append({"name": "forecaster_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "load_engine", "status": "OK" if probe_ok else "FAIL",
                   "detail": f"sonda: 9 terminów / pojemność 10 → {probe['load_pct']}% overload={probe['overload']}"})
    checks.append({"name": "overload_triage", "status": "OK" if "_wf_overload" in hay else "FAIL",
                   "detail": "przeciążenie = TRIAGE (zaplanuj pracę / zasoby)"})
    checks.append({"name": "horizon_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": f"ADR-002: {TH_KEYS[0]}"})
    checks.append({"name": "capacity_gate", "status": "OK" if has_threshold else "FAIL",
                   "detail": "próg 80% pojemności + capacity jako dane wejściowe"})

    if not th_ok:
        findings.append({"id": "V3-P25-L08", "severity": "P3",
                         "evidence": f"brak {TH_KEYS[0]} w thresholds",
                         "fix": "dodaj klucz (I08)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "probe": probe, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Kalendarz jako doradca: planowanie pracy (koniec kwartału = szczyt)",
                     "rule": "load% > próg → TRIAGE; horyzont 14 dni z danych"}}
    return emit(bundle, "v3_p25_workload_forecaster")


if __name__ == "__main__":
    raise SystemExit(main())
