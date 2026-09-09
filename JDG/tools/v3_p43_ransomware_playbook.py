#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I09 RANSOMWARE PLAYBOOK — izolacja → ocena →
odtwarzanie → raport RODO 72h → rekonsylacja; ćwiczony kwartalnie.
Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p43_common import (RODO_DOC, SECURITY_REGISTER, emit, main_jdg_wired,
                           now, read_json, rule_present, threshold_present)

INNOVATION = "V3-P43-I09"
RULE = "jdg.v3_p43_security_dr.ransomware_playbook"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(SECURITY_REGISTER)
    rp = reg.get("ransomware_playbook", {}) if isinstance(reg, dict) else {}
    stages = rp.get("stages", []) if isinstance(rp, dict) else []
    required = ["isolate", "assess", "restore", "report_72h", "reconcile"]
    stages_ok = all(s in stages for s in required)
    checks.append({"name": "playbook_stages_complete", "status": "OK" if stages_ok else "FAIL",
                   "detail": f"etapy playbooka: {stages} (wymagane: {required})"})

    rodo_72 = isinstance(rp, dict) and rp.get("report_deadline_hours") == 72
    checks.append({"name": "rodo_72h_deadline", "status": "OK" if rodo_72 else "FAIL",
                   "detail": f"deadline raportu (RODO art. 33 [NIEZWERYFIKOWANE]): {rp.get('report_deadline_hours') if isinstance(rp, dict) else 'BRAK'}h"})

    exercise = isinstance(rp, dict) and rp.get("exercise_schedule", "") == "quarterly"
    checks.append({"name": "quarterly_exercise", "status": "OK" if exercise else "FAIL",
                   "detail": f"ćwiczenie playbooka: {rp.get('exercise_schedule', 'BRAK') if isinstance(rp, dict) else 'BRAK'}"})

    doc_ok = RODO_DOC.exists()
    checks.append({"name": "rodo_aml_doc_exists", "status": "OK" if doc_ok else "FAIL",
                   "detail": f"docs/RODO_AML_BEZPIECZENSTWO_P16.md: {doc_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "playbook_stages_complete": stages_ok,
            "rodo_72h_deadline": rodo_72,
            "quarterly_exercise": exercise,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_ransomware_playbook")


if __name__ == "__main__":
    raise SystemExit(main())
