#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I07 MIRROR-AWARE APPLY — narzędzie aktualizuje
canonical i mirror w JEDNEJ transakcji (sync guarantee P39/P48; AP11:
dryf mirror = konflikt) — V3 FORTRESS.

Dowód wdrożenia: aplikacja tylko na canonical = BLOCK; rozbieżność mirror
po aplikacji = TRIAGE; próg v3_p36_mirror_divergence_max = 0 jako dane.
Podanalizy: AN03/AN04.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P36-I07"
RULE = "jdg.v3_p36_generatory_migratory.mirror_aware_apply"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    thr = threshold_present("v3_p36_mirror_divergence_max")
    checks.append({"name": "mirror_divergence_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p36_mirror_divergence_max w thresholds: {thr}"})

    canonical_only_block = "tylko na canonical bez mirror" in hay
    checks.append({"name": "canonical_only_blocked", "status": "OK" if canonical_only_block else "FAIL",
                   "detail": "aplikacja tylko canonical = BLOCK (jedna transakcja): " + str(canonical_only_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "mirror_divergence_threshold": thr,
            "canonical_only_blocked": canonical_only_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_mirror_aware_apply")


if __name__ == "__main__":
    raise SystemExit(main())
