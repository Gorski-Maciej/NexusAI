#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I12 DR LEGAL CONTINUITY — tryb „deklaracje na
ostrożnych parametrach" z oznaczeniem decyzji jako DR. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p43_common import (DEPLOY_ORCHESTRATOR, SECURITY_REGISTER, emit,
                           main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P43-I12"
RULE = "jdg.v3_p43_security_dr.dr_continuity"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(SECURITY_REGISTER)
    lc = reg.get("dr_continuity", {}) if isinstance(reg, dict) else {}
    mode = isinstance(lc, dict) and lc.get("cautious_parameters_mode", False)
    checks.append({"name": "cautious_parameters_mode", "status": "OK" if mode else "FAIL",
                   "detail": f"tryb ostrożnych parametrów (najbezpieczniejsze wartości progów): {mode}"})

    marking = isinstance(lc, dict) and lc.get("decision_marking_required", False)
    checks.append({"name": "dr_decision_marking_required", "status": "OK" if marking else "FAIL",
                   "detail": f"oznaczenie decyzji jako DR obowiązkowe: {marking}"})

    # Wejście z P05: ostrożne progi = najstarsza/ostatnia zwalidowana wersja progu
    source = lc.get("threshold_source", "") if isinstance(lc, dict) else ""
    source_ok = "P05" in source or "thresholds" in source
    checks.append({"name": "threshold_source_defined", "status": "OK" if source_ok else "FAIL",
                   "detail": f"źródło ostrożnych progów: {source!r}"})

    orchestrator = DEPLOY_ORCHESTRATOR.exists()
    checks.append({"name": "deploy_orchestrator_present", "status": "OK" if orchestrator else "FAIL",
                   "detail": f"tools/deployment_orchestrator.py (przełączenie trybu): {orchestrator}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "cautious_parameters_mode": mode,
            "dr_decision_marking_required": marking,
            "threshold_source_defined": source_ok,
            "deploy_orchestrator_present": orchestrator,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_dr_continuity")


if __name__ == "__main__":
    raise SystemExit(main())
