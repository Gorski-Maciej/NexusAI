#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I02 FILAR SCOREBOARD — Legal Twin / Golden Oracle /
Decision Certificate / Law Radar / Declarative Change / Runtime Invariants:
status DOWIEDZONE/CZĘŚCIOWE/DEKLAROWANE z dowodem. DEKLAROWANE bez planu = BLOCK.
Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p44_common import CERT_REGISTER, HOLY_DOC_2, emit, now, read_json, rule_present

INNOVATION = "V3-P44-I02"
RULE = "jdg.v3_p44_certyfikacja_finalna.pillar_scoreboard"
VALID_STATUS = {"DOWIEDZONE", "CZĘŚCIOWE", "DEKLAROWANE"}


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    pillars = reg.get("pillars", {}) if isinstance(reg, dict) else {}
    all_valid = bool(pillars) and all(
        isinstance(p, dict) and p.get("status") in VALID_STATUS and p.get("evidence")
        for p in pillars.values())
    checks.append({"name": "pillars_with_status_and_evidence", "status": "OK" if all_valid else "FAIL",
                   "detail": f"filary ze statusem+dowodem: {sum(1 for p in pillars.values() if isinstance(p, dict) and p.get('evidence'))}/{len(pillars)}"})

    declared_no_plan = [k for k, p in pillars.items() if isinstance(p, dict)
                        and p.get("status") == "DEKLAROWANE" and not p.get("closure_plan")]
    checks.append({"name": "no_declared_without_plan", "status": "OK" if not declared_no_plan else "FAIL",
                   "detail": f"DEKLAROWANE bez planu (BLOCK): {declared_no_plan}"})

    doc_ok = HOLY_DOC_2.exists()
    checks.append({"name": "holy_doc_2_exists", "status": "OK" if doc_ok else "FAIL",
                   "detail": f"docs/WIZJA_OPA_ENTERPRISE_V2.md (filary): {doc_ok}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "pillars_total": len(pillars),
            "pillars_dowiedzone": sum(1 for p in pillars.values() if isinstance(p, dict) and p.get("status") == "DOWIEDZONE"),
            "pillars_czesciowe": sum(1 for p in pillars.values() if isinstance(p, dict) and p.get("status") == "CZĘŚCIOWE"),
            "declared_without_plan": len(declared_no_plan),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_pillar_scoreboard")


if __name__ == "__main__":
    raise SystemExit(main())
