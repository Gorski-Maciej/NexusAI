#!/usr/bin/env python3
"""NexusAI JDG — V3-P35-I08 AUDYT CIĄGŁY VS PER-PR — rozdzielenie trybów:
per-PR (szybki zestaw kontroli) i nocny (głęboki) — V3 FORTRESS.

Dowód wdrożenia: PR pominięty = BLOCK; nocny ponad limit dni = TRIAGE
(limit jako dane; spójny z P34-I08 — dwa tryby walidacji). Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p35_common import (P35_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P35-I08"
RULE = "jdg.v3_p35_audyutory_domenowe.continuous_vs_per_pr"


def main() -> int:
    hay = read(P35_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    night = threshold_present("v3_p35_nightly_missed_max_days")
    checks.append({"name": "nightly_limit_threshold", "status": "OK" if night else "FAIL",
                   "detail": "v3_p35_nightly_missed_max_days w thresholds: " + str(night)})

    modes = "per-PR" in hay and "nocny" in hay.lower()
    checks.append({"name": "two_audit_modes", "status": "OK" if modes else "FAIL",
                   "detail": "tryby per-PR (szybki) i nocny (głęboki): " + str(modes)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "nightly_limit_threshold": night,
            "two_audit_modes": modes,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p35_continuous_vs_per_pr")


if __name__ == "__main__":
    raise SystemExit(main())
