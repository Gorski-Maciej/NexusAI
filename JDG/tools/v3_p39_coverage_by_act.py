#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I09 COVERAGE BY LEGAL ACT — raport CI: pokrycie per AKT
prawny (nie per plik) — trend w P37, próg w bramce (K12). Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p39_common import emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P39-I09"
RULE = "jdg.v3_p39_testy_ci.coverage_by_act"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    t = threshold_present("v3_p39_act_coverage_min_pct")
    checks.append({"name": "act_coverage_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p39_act_coverage_min_pct w data.thresholds: {t}"})

    # Rdzeń pokrycia (rozszerzamy, nie duplikujemy)
    cov = (__import__("v3_p39_common").BASE / "COVERAGE_REPORT.md").exists()
    gate_tool = (__import__("v3_p39_common").TOOLS / "test_coverage_gate.py").exists()
    checks.append({"name": "core_coverage_tools_exist", "status": "OK" if (cov and gate_tool) else "FAIL",
                   "detail": f"COVERAGE_REPORT.md: {cov}, tools/test_coverage_gate.py: {gate_tool}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "act_coverage_threshold_as_data": t,
            "core_coverage_tools_exist": bool(cov and gate_tool),
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_coverage_by_act")


if __name__ == "__main__":
    raise SystemExit(main())
