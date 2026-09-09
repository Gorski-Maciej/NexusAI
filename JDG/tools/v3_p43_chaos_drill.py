#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I05 CHAOS LEGAL DRILL — gra wojenna: próba wniesienia
błędnej reguły przez cały proces (PR→bramki→deploy). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p43_common import (CHAOS_ENGINEERING, CHAOS_RUNNER, SECURITY_REGISTER,
                           emit, main_jdg_wired, now, read_json, rule_present,
                           threshold_present)

INNOVATION = "V3-P43-I05"
RULE = "jdg.v3_p43_security_dr.chaos_drill"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    tools_ok = CHAOS_RUNNER.exists() and CHAOS_ENGINEERING.exists()
    checks.append({"name": "chaos_tools_exist", "status": "OK" if tools_ok else "FAIL",
                   "detail": f"chaos_runner.py + chaos_engineering.py: {tools_ok}"})

    reg = read_json(SECURITY_REGISTER)
    cd = reg.get("chaos_drill", {}) if isinstance(reg, dict) else {}
    scenario_ok = isinstance(cd, dict) and cd.get("scenario", "") == "bad_rule_through_pipeline"
    checks.append({"name": "drill_scenario_defined", "status": "OK" if scenario_ok else "FAIL",
                   "detail": f"scenariusz drillu: {cd.get('scenario', 'BRAK') if isinstance(cd, dict) else 'BRAK'}"})

    path_ok = isinstance(cd, dict) and {"pr", "gates", "deploy"} <= set(cd.get("stages", []))
    checks.append({"name": "full_pipeline_path", "status": "OK" if path_ok else "FAIL",
                   "detail": f"ścieżka drillu (pr→gates→deploy): {cd.get('stages', []) if isinstance(cd, dict) else 'BRAK'}"})

    t = threshold_present("v3_p43_chaos_drill_max_age_days")
    checks.append({"name": "drill_age_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p43_chaos_drill_max_age_days w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "chaos_tools_exist": tools_ok,
            "drill_scenario_defined": scenario_ok,
            "full_pipeline_path": path_ok,
            "drill_age_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_chaos_drill")


if __name__ == "__main__":
    raise SystemExit(main())
