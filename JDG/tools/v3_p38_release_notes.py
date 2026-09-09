#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I12 RELEASE NOTES AUTO-GENERATED — changelog z diffów
reguł (progi, daty, stawki) generowany automatycznie — przedsiębiorca widzi co
się zmieniło.

Dowód wdrożenia: reguła I12 (BLOCK deploy bez changelogu; TRIAGE nieświeży)
+ próg v3_p38_changelog_max_age_days. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p38_common import emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P38-I12"
RULE = "jdg.v3_p38_bundle_deploy.release_notes"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    t = threshold_present("v3_p38_changelog_max_age_days")
    checks.append({"name": "changelog_age_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p38_changelog_max_age_days w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "changelog_age_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_release_notes")


if __name__ == "__main__":
    raise SystemExit(main())
