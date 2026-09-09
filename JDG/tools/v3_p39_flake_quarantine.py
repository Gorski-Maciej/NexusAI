#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I07 FLAKE QUARANTINE — test flakowy trafia do
kwarantanny (osobny job) z terminem naprawy; zero trwałych flaków na ścieżce
merge. Podanalizy: AN02.
"""
from __future__ import annotations

import json

from v3_p39_common import emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P39-I07"
RULE = "jdg.v3_p39_testy_ci.flake_quarantine"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Konwencja kwarantanny jako dane w kontrakcie strategii testów
    strategy = json.loads(read(__import__("v3_p39_common").TEST_STRATEGY)) if read(__import__("v3_p39_common").TEST_STRATEGY) else {}
    fq = strategy.get("flake_quarantine", {})
    ok_fq = fq.get("separate_job") is True and bool(fq.get("repair_deadline_days"))
    checks.append({"name": "quarantine_convention_as_data", "status": "OK" if ok_fq else "FAIL",
                   "detail": f"flake_quarantine: separate_job={fq.get('separate_job')}, deadline={fq.get('repair_deadline_days')} dni"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "quarantine_convention_ok": ok_fq,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_flake_quarantine")


if __name__ == "__main__":
    raise SystemExit(main())
