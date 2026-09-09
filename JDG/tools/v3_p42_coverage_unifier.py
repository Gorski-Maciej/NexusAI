#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I06 COVERAGE UNIFIER CONTRACT — unifikacja raportów
pokrycia do jednego kanonu wersjonowanego (P37 konsumuje). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p42_common import (COVERAGE_CANON, COVERAGE_UNIFIER, TESTS, emit,
                           main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P42-I06"
RULE = "jdg.v3_p42_enterprise_reszta.coverage_unifier"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    canon = read_json(COVERAGE_CANON)
    canon_ok = bool(canon)
    checks.append({"name": "coverage_canon_exists", "status": "OK" if canon_ok else "FAIL",
                   "detail": f"bundles/coverage_canon.json: {canon_ok}"})

    tool_ok = COVERAGE_UNIFIER.exists()
    checks.append({"name": "unifier_tool_exists", "status": "OK" if tool_ok else "FAIL",
                   "detail": f"tools/coverage_unifier.py: {tool_ok}"})

    # Test unifiera istnieje (kontrakt testowany) — dowód z Sekcji 6.2
    test_ok = (TESTS / "test_coverage_unifier.py").exists()
    checks.append({"name": "unifier_test_exists", "status": "OK" if test_ok else "FAIL",
                   "detail": f"tests/test_coverage_unifier.py: {test_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "coverage_canon_exists": canon_ok,
            "unifier_tool_exists": tool_ok,
            "unifier_test_exists": test_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_coverage_unifier")


if __name__ == "__main__":
    raise SystemExit(main())
