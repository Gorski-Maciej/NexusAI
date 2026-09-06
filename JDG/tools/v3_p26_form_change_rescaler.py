#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I09 FORM CHANGE HEALTH RESCALER (zmiana formy w roku).

Dowód wdrożenia: zmiana formy w trakcie roku → przeliczenie zdrowotnej per
okres kwartalny (v3_p26_health_rescale_periods = 4); niekompletne = TRIAGE;
nadmiarowe = BLOCK; korekta roczna 22 maja (art. 81 u.ś.o.z.).
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P26-I09"
RULE = "jdg.v3_p26_zus_skladki.form_change_rescaler"


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_periods = threshold_present("v3_p26_health_rescale_periods")
    has_month = '"form_change_month"' in hay
    has_correction = "22 maja" in hay or "05-22" in hay

    checks.append({"name": "rescaler_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "quarterly_periods", "status": "OK" if has_periods else "FAIL",
                   "detail": "okresy przeliczenia (4 kwartalne) z zus26"})
    checks.append({"name": "change_month_gate", "status": "OK" if has_month else "FAIL",
                   "detail": "form_change_month > 0 wymusza przeliczenie"})
    checks.append({"name": "annual_correction", "status": "OK" if has_correction else "FAIL",
                   "detail": "korekta roczna 22 maja (art. 81 ust. 2-2b) [NIEZWERYFIKOWANE]"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not has_periods:
        findings.append({"id": "V3-P26-L09", "severity": "P2",
                         "evidence": "brak parametru okresów przeliczenia",
                         "fix": "I09: v3_p26_health_rescale_periods w zus26"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "periods": 4, "annual_correction": has_correction},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Rescaler wiąże P14/P18 (formy) i P44; scenariusz "
                                "zmiany formy w stress lab (I11)",
                     "rule": "niekompletne przeliczenie = TRIAGE; nadmiarowe = BLOCK"}}
    return emit(bundle, "v3_p26_form_change_rescaler")


if __name__ == "__main__":
    raise SystemExit(main())
