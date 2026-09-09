#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I01 TEST MATRIX FROM ACTS — generator (P36) tworzy
matrycę: akt × artykuł × granica (grosze/data/waluta) → przypadki; pokrycie
matrycy = metryka CI. Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p39_common import emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P39-I01"
RULE = "jdg.v3_p39_testy_ci.test_matrix"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Generator matrycy z P36 (rozszerzamy, nie duplikujemy)
    gen = __import__("v3_p39_common").TOOLS / "generate_test_suite.py"
    gen_ok = gen.exists()
    checks.append({"name": "matrix_generator_exists", "status": "OK" if gen_ok else "FAIL",
                   "detail": f"tools/generate_test_suite.py (P36): {gen_ok}"})

    t = threshold_present("v3_p39_matrix_coverage_min_pct")
    checks.append({"name": "coverage_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p39_matrix_coverage_min_pct w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "matrix_generator_exists": gen_ok,
            "coverage_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_test_matrix")


if __name__ == "__main__":
    raise SystemExit(main())
