#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I03 ZERO-SILENCE CONSTITUTION (nigdy cisza).

Dowód wdrożenia: termin minął + brak wykonania = BLOCK + eskalacja 48h
(kontrakt V3_P04); alerty 7/3/1 z override per obowiązek; naruszenie
konstytucji (breach bez BLOCK) = BLOCK; ścieżki awaryjne (odsetki/korekta).
"""
from __future__ import annotations

from v3_p25_common import P25_RULES, emit, now, read, rule_present, threshold_present

INNOVATION = "V3-P25-I03"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.zero_silence"
TH_KEYS = ["v3_p25_zero_silence_constitution", "v3_p25_alert_levels_days",
           "v3_p25_escalation_hours"]


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_breach = "_zs_breached" in hay and "ZERO CISZY" in hay
    has_constitution = "_zs_constitution_ok" in hay
    has_alerts = "_zs_alert_7" in hay and "_zs_alert_3" in hay and "_zs_alert_1" in hay
    has_escalation = "_zs_escalation_hours" in hay
    has_emergency = "art. 56 OrdPU" in hay and "korekta czynna" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "zero_silence_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "breach_block", "status": "OK" if has_breach else "FAIL",
                   "detail": "termin minął + brak wykonania = BLOCK (zero ciszy)"})
    checks.append({"name": "constitution_gate", "status": "OK" if has_constitution else "FAIL",
                   "detail": "naruszenie konstytucji (breach bez BLOCK) = BLOCK (P04)"})
    checks.append({"name": "alerts_7_3_1", "status": "OK" if has_alerts else "FAIL",
                   "detail": "alerty 7/3/1 z override per obowiązek z tabeli MASTER"})
    checks.append({"name": "escalation_48h", "status": "OK" if has_escalation else "FAIL",
                   "detail": "eskalacja 48h (księgowa → manager)"})
    checks.append({"name": "emergency_paths", "status": "OK" if has_emergency else "FAIL",
                   "detail": "ścieżki awaryjne: odsetki (art. 56 OP) + korekta czynna (art. 81 OP)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": f"ADR-002: klucze {TH_KEYS}"})

    if not has_constitution:
        findings.append({"id": "V3-P25-L03", "severity": "P1",
                         "evidence": "brak bramki naruszenia konstytucji zero-ciszy",
                         "fix": "I03: constitution_ok gate — breach bez BLOCK = BLOCK"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "breach_block": has_breach,
                    "constitution": has_constitution, "alerts": has_alerts,
                    "escalation": has_escalation, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Konstytucja zero-ciszy (kontrakt V3_P04): brak wykonania = "
                                "alarm + eskalacja, NIGDY cisza; AUTO_POST niemożliwy przy breach",
                     "rule": "breach=BLOCK; alerty 7/3/1 per obowiązek; eskalacja 48h"}}
    return emit(bundle, "v3_p25_zero_silence")


if __name__ == "__main__":
    raise SystemExit(main())
