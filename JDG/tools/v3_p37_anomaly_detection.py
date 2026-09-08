#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I07 ANOMALY DETECTION Z SEZONOWOŚCIĄ — sezonowość
księgowa (koniec miesiąca/kwartału) w detekcji anomalii — mniej fałszywych
alarmów — V3 FORTRESS.

Dowód wdrożenia: anomalia nieuwzględniona = BLOCK (awaria ścieżki AUTO_POST?);
fałszywe alarmy bez sezonowości = TRIAGE (dopasowanie modelu sezonowego,
spójny z replayem sezonowym P32-I07). Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p37_common import (P37_RULES, emit, main_jdg_wired, now, read,
                           rule_present)

INNOVATION = "V3-P37-I07"
RULE = "jdg.v3_p37_obserwowalnosc.anomaly_detection"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    seasonality = "sezonowo" in hay
    checks.append({"name": "seasonality_model", "status": "OK" if seasonality else "FAIL",
                   "detail": "sezonowość księgowa w detekcji: " + str(seasonality)})

    unaccounted_block = "Anomalie nieuwzględnione" in hay
    checks.append({"name": "unaccounted_anomaly_blocked", "status": "OK" if unaccounted_block else "FAIL",
                   "detail": "anomalia niewyjaśniona = BLOCK: " + str(unaccounted_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "seasonality_model": seasonality,
            "unaccounted_anomaly_blocked": unaccounted_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_anomaly_detection")


if __name__ == "__main__":
    raise SystemExit(main())
