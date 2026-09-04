#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I02 LIMITATION SENTINEL (art. 70-72 OrdPU).

Dowód wdrożenia: kalendarz przedawnienia — 5 lat, koniec roku kalendarzowego + 5
(31.12), zawieszenia (art. 71) przesuwające koniec, alerty 90/60/30 dni,
interwencja = nowy termin. Przedawnienie bez ścieżki = BLOCK (fail-closed).
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P17-I02"

RULE = "jdg.v3_p17_ordynacja_obrona.limitation_sentinel"
TH_KEYS = ["v3_p17_statute_years", "v3_p17_statute_end_rule",
           "v3_p17_limitation_alert_days", "v3_p17_suspension_max_events"]


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_5y = "assessment_year + _th(\"v3_p17_statute_years\", 5)" in hay and '"statutory_end_year"' in hay
    has_susp = '"suspension_days"' in hay and '"suspension_events"' in hay and "art. 71" in hay
    has_alerts = '"alert_tier"' in hay and "_ls_alert_90" in hay and "_ls_alert_30" in hay
    has_fail = '"limitation_expired"' in hay and "fail_closed" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "limitation_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "calendar_5y_31_12", "status": "OK" if has_5y else "FAIL",
                   "detail": "koniec roku kalendarzowego + 5 (31.12)"})
    checks.append({"name": "suspensions_art71", "status": "OK" if has_susp else "FAIL",
                   "detail": "zawieszenia przesuwają koniec (art. 71)"})
    checks.append({"name": "alerts_90_60_30", "status": "OK" if has_alerts else "FAIL",
                   "detail": "alerty N-dni przed przedawnieniem"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail else "FAIL",
                   "detail": "przedawnienie bez ścieżki = BLOCK"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: lata/reguła/alerty z data.thresholds.ord"})

    if not has_alerts:
        findings.append({"id": "V3-P17-L02", "severity": "P1",
                         "evidence": "kalendarz przedawnienia bez alertów N-dni",
                         "fix": "I02: alerty 90/60/30 + zawieszenia art. 71"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "calendar": has_5y, "suspensions": has_susp,
                    "alerts": has_alerts, "fail_closed": has_fail, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 70-72 OrdPU; kontrakt V3_P36 (kalendarz proceduralny)",
                     "rule": "kalendarz przedawnienia z alertami 90/60/30 i zawieszeniami"}}
    return emit(bundle, "v3_p17_limitation_sentinel")


if __name__ == "__main__":
    raise SystemExit(main())
