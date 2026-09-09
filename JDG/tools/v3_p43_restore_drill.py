#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I06 RESTORE DRILLS IN CI — cotygodniowy restore
z dr_snapshots/WORM + weryfikacja checksum (backup bez testu = mit).
Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p43_common import (DR_SNAPSHOTS, SELF_HEALING, SECURITY_REGISTER, emit,
                           main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P43-I06"
RULE = "jdg.v3_p43_security_dr.restore_drill"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Realny snapshot DR istnieje (dowód z repo)
    snaps = sorted(p.name for p in DR_SNAPSHOTS.glob("*.json")) if DR_SNAPSHOTS.exists() else []
    snaps_ok = len(snaps) > 0
    checks.append({"name": "dr_snapshots_present", "status": "OK" if snaps_ok else "FAIL",
                   "detail": f"snapshoty w bundles/dr_snapshots/: {len(snaps)} ({snaps[:2]})"})

    reg = read_json(SECURITY_REGISTER)
    rd = reg.get("restore_drill", {}) if isinstance(reg, dict) else {}
    schedule_ok = isinstance(rd, dict) and rd.get("schedule", "") == "weekly_ci"
    checks.append({"name": "weekly_ci_schedule", "status": "OK" if schedule_ok else "FAIL",
                   "detail": f"harmonogram restore drill: {rd.get('schedule', 'BRAK') if isinstance(rd, dict) else 'BRAK'}"})

    checksum = isinstance(rd, dict) and rd.get("checksum_verify_required", False)
    checks.append({"name": "checksum_verify_required", "status": "OK" if checksum else "FAIL",
                   "detail": f"weryfikacja checksum po restore obowiązkowa: {checksum}"})

    healing = SELF_HEALING.exists()
    checks.append({"name": "self_healing_engine_present", "status": "OK" if healing else "FAIL",
                   "detail": f"tools/self_healing_engine.py: {healing}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "dr_snapshots": len(snaps),
            "weekly_ci_schedule": schedule_ok,
            "checksum_verify_required": checksum,
            "self_healing_engine_present": healing,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_restore_drill")


if __name__ == "__main__":
    raise SystemExit(main())
