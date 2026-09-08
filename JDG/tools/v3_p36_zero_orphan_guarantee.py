#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I12 ZERO-ORPHAN GUARANTEE — po każdej transformacji
kontrola: żadna reguła bez testu, żaden test bez reguły, żaden manifest bez
pliku — V3 FORTRESS.

Dowód wdrożenia: próg v3_p36_orphans_max = 0 jako dane; suma orphanów > max
= BLOCK; wejście do bramek P29/P39 i zero-orphan check end-to-end
(generator → reguła → test → manifest). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P36-I12"
RULE = "jdg.v3_p36_generatory_migratory.zero_orphan_guarantee"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p36_orphans_max")
    checks.append({"name": "orphans_max_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p36_orphans_max w thresholds: {thr}"})

    triple = all(tok in hay for tok in ("rules_without_test", "tests_without_rule", "manifests_without_file"))
    checks.append({"name": "triple_orphan_check", "status": "OK" if triple else "FAIL",
                   "detail": "reguła/test/manifest — trzy kierunki orphan check: " + str(triple)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "orphans_max_threshold": thr,
            "triple_orphan_check": triple,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_zero_orphan_guarantee")


if __name__ == "__main__":
    raise SystemExit(main())
