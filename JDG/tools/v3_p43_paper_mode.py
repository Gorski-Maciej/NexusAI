#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I07 PAPER-MODE RUNBOOK — procedura księgowości
ręcznej (formularze, terminy, rekonsylacja po DR). Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p43_common import (RUNBOOKS, SECURITY_REGISTER, emit, main_jdg_wired,
                           now, read_json, rule_present)

INNOVATION = "V3-P43-I07"
RULE = "jdg.v3_p43_security_dr.paper_mode"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Runbooki operacyjne P37 istnieją (podstawa; paper-mode je uzupełnia)
    rb = sorted(p.name for p in RUNBOOKS.glob("*.md")) if RUNBOOKS.exists() else []
    rb_ok = len(rb) >= 6
    checks.append({"name": "operational_runbooks_present", "status": "OK" if rb_ok else "FAIL",
                   "detail": f"runbooki P37: {len(rb)} (RB01-RB06)"})

    reg = read_json(SECURITY_REGISTER)
    pm = reg.get("paper_mode", {}) if isinstance(reg, dict) else {}
    sections = pm.get("sections", []) if isinstance(pm, dict) else []
    required = ["forms", "deadlines", "reconciliation_after_dr"]
    sections_ok = all(s in sections for s in required)
    checks.append({"name": "paper_mode_sections_complete", "status": "OK" if sections_ok else "FAIL",
                   "detail": f"sekcje paper-mode: {sections} (wymagane: {required})"})

    # Kalendarz terminów dostępny offline (P25 — dane, nie API)
    cal = reg.get("paper_mode", {}).get("calendar_source", "") if isinstance(pm, dict) else ""
    cal_ok = "P25" in cal
    checks.append({"name": "offline_calendar_source", "status": "OK" if cal_ok else "FAIL",
                   "detail": f"źródło terminów offline: {cal!r} (P25 zus_calendar jako dane)"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "operational_runbooks": len(rb),
            "paper_mode_sections_complete": sections_ok,
            "offline_calendar_source": cal_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_paper_mode")


if __name__ == "__main__":
    raise SystemExit(main())
