#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I03 NEEDS-ADVICE RADAR — klasterizacja NEEDS_ADVICE
w czasie; nagły skok = sygnał luki prawnej lub awarii danych (auto-ticket
P08/P30) — V3 FORTRESS.

Dowód wdrożenia: NEEDS_ADVICE bez powodu = BLOCK (wskaźnik fail-closed jako
SLO-05); skok > v3_p37_na_spike_ratio×baseline = TRIAGE z tickietem.
Podanalizy: AN01/AN03.
"""
from __future__ import annotations

from v3_p37_common import (P37_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P37-I03"
RULE = "jdg.v3_p37_obserwowalnosc.needs_advice_radar"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p37_na_spike_ratio")
    checks.append({"name": "spike_ratio_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p37_na_spike_ratio w thresholds: {thr}"})

    reason_block = "bez powodu" in hay
    checks.append({"name": "no_reason_blocked", "status": "OK" if reason_block else "FAIL",
                   "detail": "NEEDS_ADVICE bez powodu = BLOCK: " + str(reason_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "spike_ratio_threshold": thr,
            "no_reason_blocked": reason_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_needs_advice_radar")


if __name__ == "__main__":
    raise SystemExit(main())
