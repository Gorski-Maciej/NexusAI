#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I03 TEMPORAL PAIR TESTS — para testów (dzień przed/po
przełączeniu) generowana automatycznie z valid_from/valid_to (P05).
Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p39_common import emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P39-I03"
RULE = "jdg.v3_p39_testy_ci.temporal_pairs"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Testy temporalne rdzenia (rozszerzamy, nie duplikujemy)
    temporal = __import__("v3_p39_common").TESTS / "test_core_guards_temporal_thresholds.py"
    temporal_ok = temporal.exists()
    checks.append({"name": "core_temporal_tests_exist", "status": "OK" if temporal_ok else "FAIL",
                   "detail": f"tests/test_core_guards_temporal_thresholds.py: {temporal_ok}"})

    # Okna temporalne w proagach (P05): valid_from w thresholds
    thr = read(__import__("v3_p39_common").THRESHOLDS)
    windows = thr.count('"valid_from"')
    checks.append({"name": "temporal_windows_in_thresholds", "status": "OK" if windows > 0 else "FAIL",
                   "detail": f"bloki valid_from w thresholds_jdg.rego: {windows}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "core_temporal_tests_exist": temporal_ok,
            "temporal_windows_count": windows,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_temporal_pairs")


if __name__ == "__main__":
    raise SystemExit(main())
