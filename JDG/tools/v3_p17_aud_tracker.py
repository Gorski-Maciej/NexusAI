#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I06 AUD BENEFIT TRACKER (art. 30a/30b OrdPU).

Dowód wdrożenia: śledzenie dobrowolnego ujawnienia — benefit stawki
(redukcja do v3_p17_aud_reduced_rate_pct po spełnieniu warunków: ujawnienie
przed wszczęciem + wpłata) i monitoring naruszeń (utrata benefitów = sygnał).
Stawki parametryzowane (ADR-002); weryfikacja ISAP oznaczona w raporcie.
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P17-I06"

RULE = "jdg.v3_p17_ordynacja_obrona.aud_benefit_tracker"
TH_KEYS = ["v3_p17_aud_reduced_rate_pct", "v3_p17_aud_full_rate_pct"]


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_conditions = '"before_proceeding_started"' in hay and '"disclosure_made"' in hay and "_au_eligible" in hay
    has_monitor = '"violation_detected"' in hay and "_au_violation" in hay
    has_rates = '"reduced_rate_pct"' in hay and '"full_rate_pct"' in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "aud_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "conditions", "status": "OK" if has_conditions else "FAIL",
                   "detail": "warunki benefitu (ujawnienie przed wszczęciem + wpłata)"})
    checks.append({"name": "monitoring", "status": "OK" if has_monitor else "FAIL",
                   "detail": "monitoring naruszeń warunków AUD"})
    checks.append({"name": "rates_as_data", "status": "OK" if has_rates else "FAIL",
                   "detail": "stawki w certyfikacie z thresholdów (ADR-002)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: stawki AUD z data.thresholds.ord"})

    if not has_conditions:
        findings.append({"id": "V3-P17-L06", "severity": "P1",
                         "evidence": "AUD bez ścieżek warunków benefitu",
                         "fix": "I06: ścieżki ujawnienia + monitoring naruszeń"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "conditions": has_conditions, "monitoring": has_monitor,
                    "rates": has_rates, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 30a/30b OrdPU (AUD) [NIEZWERYFIKOWANE — raport P17]; ADR-002",
                     "rule": "tracker benefitu AUD z monitoringiem warunków"}}
    return emit(bundle, "v3_p17_aud_tracker")


if __name__ == "__main__":
    raise SystemExit(main())
