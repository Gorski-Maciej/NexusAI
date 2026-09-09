#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I02 GOLDEN REPLAY AS PR GATE — golden verdicts (P10)
uruchamiane przy każdym PR; jakakolwiek regresja decyzji = BLOCKER z diffem.
Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p39_common import GOLDEN, WORKFLOW, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P39-I02"
RULE = "jdg.v3_p39_testy_ci.golden_replay_gate"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    golden = read(GOLDEN)
    golden_ok = len(golden) > 0
    checks.append({"name": "golden_verdicts_available", "status": "OK" if golden_ok else "FAIL",
                   "detail": f"bundles/golden_verdicts.json: {golden_ok}"})

    wf = read(WORKFLOW)
    golden_in_ci = "golden" in wf.lower()
    checks.append({"name": "golden_in_ci_workflow", "status": "OK" if golden_in_ci else "FAIL",
                   "detail": f"golden w .github/workflows/jdg-quality.yml: {golden_in_ci}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "golden_verdicts_available": golden_ok,
            "golden_in_ci_workflow": golden_in_ci,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_golden_replay_gate")


if __name__ == "__main__":
    raise SystemExit(main())
