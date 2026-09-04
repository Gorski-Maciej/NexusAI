#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I10 DISTANCE SELLING TRACKER (art. 24/25 VAT).

Monitoring progów sprzedaży wysyłkowej per kraj (10k EUR / 35k / 100k) z
alarmami. Dowód: reguła distance_selling_tracker + parametr
distance_selling_limit_eur w thresholds.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I10"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.distance_selling_tracker", hay)
    has_triage = "TRIAGE_QUEUE" in hay and "distance_selling_status" in hay
    has_limit = not thresholds_missing(["distance_selling_limit_eur"])

    checks.append({"name": "distance_selling_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła distance_selling_tracker: {has_rule}"})
    checks.append({"name": "alarm_on_exceed", "status": "OK" if has_triage else "FAIL",
                   "detail": "przekroczenie progu per kraj → TRIAGE_QUEUE + alarm"})
    checks.append({"name": "limit_param", "status": "OK" if has_limit else "FAIL",
                   "detail": "parametr distance_selling_limit_eur (ADR-002)"})

    if not has_triage:
        findings.append({"id": "V3-P15-L11", "severity": "P2",
                         "evidence": "distance selling bez alarmów przy przekroczeniu progów",
                         "fix": "I10: monitoring progów per kraj z alarmami i eskalacją"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "triage": has_triage, "limit_param": has_limit},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P36 (kalendarz), P12 (stawki), P44",
                     "rule": "sprzedaż wysyłkowa powyżej progu per kraj = alarm + obowiązki rejestracyjne"}}
    return emit(bundle, "v3_p15_distance_selling_tracker")


if __name__ == "__main__":
    raise SystemExit(main())