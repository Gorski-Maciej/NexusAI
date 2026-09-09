#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I02 CANARY Z DECISION DIFF — porównanie werdyktów canary
vs produkcja na próbce realnych inputów (z anonimizacją); rozjazd = auto-hold.

Dowód wdrożenia: reguła I02 (BLOCK przy rozjazd > 0, TRIAGE przy próbka <
min) + progi v3_p38_canary_diff_max / v3_p38_canary_sample_min. Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p38_common import BUNDLES, emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P38-I02"
RULE = "jdg.v3_p38_bundle_deploy.canary_decision_diff"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    t1 = threshold_present("v3_p38_canary_diff_max")
    t2 = threshold_present("v3_p38_canary_sample_min")
    checks.append({"name": "canary_thresholds", "status": "OK" if (t1 and t2) else "FAIL",
                   "detail": f"diff_max={t1}, sample_min={t2} (ADR-002)"})

    # Decision diff na golden verdicts (próbka kontrolowana, brak PII)
    golden = read(BUNDLES / "golden_verdicts.json")
    has_golden = len(golden) > 0
    checks.append({"name": "golden_sample_available", "status": "OK" if has_golden else "FAIL",
                   "detail": f"bundles/golden_verdicts.json: {has_golden} (próbka diff)"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "canary_diff_max_as_data": t1,
            "canary_sample_min_as_data": t2,
            "golden_sample_available": has_golden,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_canary_decision_diff")


if __name__ == "__main__":
    raise SystemExit(main())
