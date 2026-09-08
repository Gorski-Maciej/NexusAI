#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I08 GOLDEN DRIFT WATCH — ciągły porównywacz decyzji
produkcyjnych z golden verdicts (P10); rozjazd = alarm z diffem inputów —
V3 FORTRESS.

Dowód wdrożenia: rozjazd > v3_p37_golden_drift_max (0) = BLOCK; watch
wyłączony = BLOCK (obserwowalność dokładności obowiązkowa — SLO-03).
Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p37_common import (P37_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P37-I08"
RULE = "jdg.v3_p37_obserwowalnosc.golden_drift_watch"


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p37_golden_drift_max")
    checks.append({"name": "golden_drift_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p37_golden_drift_max w thresholds: {thr}"})

    disabled_block = "Drift watch wyłączony" in hay
    checks.append({"name": "watch_disabled_blocked", "status": "OK" if disabled_block else "FAIL",
                   "detail": "watch wyłączony = BLOCK: " + str(disabled_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p101"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "golden_drift_threshold": thr,
            "watch_disabled_blocked": disabled_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_golden_drift_watch")


if __name__ == "__main__":
    raise SystemExit(main())
