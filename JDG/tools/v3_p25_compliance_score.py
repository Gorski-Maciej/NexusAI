#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I11 COMPLIANCE SCORE HISTORY (metryka wartości).

Dowód wdrożenia: % dotrzymanych terminów + trend (RISING/FLAT/DECLINING,
okno 12M); trend spadkowy lub < 90% = TRIAGE; brak danych = TRIAGE
(nigdy cisza); obserwowalność P37.
"""
from __future__ import annotations

from v3_p25_common import P25_RULES, emit, now, read, rule_present, threshold_present

INNOVATION = "V3-P25-I11"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.compliance_score"
TH_KEYS = ["v3_p25_compliance_score_history_months"]
TARGET_PCT = 90


def score(on_time: int, total: int, trend: str = "FLAT") -> dict:
    pct = 0 if total <= 0 else (on_time * 100) // total
    triage = total <= 0 or trend == "DECLINING" or pct < TARGET_PCT
    return {"on_time": on_time, "total": total, "pct": pct, "trend": trend,
            "target": TARGET_PCT, "triage": triage}


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_trend = "_hs_trend" in hay
    th_ok = threshold_present(TH_KEYS[0])

    probe_declining = score(80, 100, "DECLINING")
    probe_low = score(85, 100, "FLAT")
    probe_ok = score(95, 100, "RISING")
    probe_nodata = score(0, 0)
    probes_ok = (probe_declining["triage"] and probe_low["triage"]
                 and not probe_ok["triage"] and probe_nodata["triage"])

    checks.append({"name": "score_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "score_engine", "status": "OK" if probes_ok else "FAIL",
                   "detail": f"sondy: declining={probe_declining['pct']}%→TRIAGE, "
                             f"low={probe_low['pct']}%→TRIAGE, ok={probe_ok['pct']}%→SUGGEST, "
                             f"nodata→TRIAGE"})
    checks.append({"name": "trend_gate", "status": "OK" if has_trend else "FAIL",
                   "detail": "trend RISING/FLAT/DECLINING; spadek = TRIAGE"})
    checks.append({"name": "target_90", "status": "OK" if "90" in hay else "FAIL",
                   "detail": "cel ≥ 90% dotrzymanych"})
    checks.append({"name": "window_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": f"ADR-002: {TH_KEYS[0]}"})

    if not probes_ok:
        findings.append({"id": "V3-P25-L11", "severity": "P3",
                         "evidence": "sondy score niezgodne z oczekiwaniami",
                         "fix": "napraw engine score (I11)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "probe_ok": probe_ok,
                    "probe_declining": probe_declining, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Metryki wartości → obserwowalność P37 (dashboard % dotrzymanych, "
                                "kary uniknięte) i P44 (certyfikacja)",
                     "rule": "score = on_time/total; <90% lub spadek = TRIAGE"}}
    return emit(bundle, "v3_p25_compliance_score")


if __name__ == "__main__":
    raise SystemExit(main())
