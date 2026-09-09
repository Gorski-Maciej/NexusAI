#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I04 NEGATIVE ASSERTION GENERATOR — dla każdej
skonwertowanej reguły test negatywny: brak przesłanki → NEEDS_ADVICE.
Dowód, że reguła NIE jest stubem po konwersji (asercja na konkretny
przypadek). Konwersja bez testu negatywnego = BLOCK. Podanalizy: AN02.
"""
from __future__ import annotations

import json

from v3_p45_common import (BASE, P45_CONVERSIONS, TESTS, THRESHOLDS, emit, now,
                           opa_test, read)

INNOVATION = "V3-P45-I04"
RULE = "jdg.v3_p45_stub_killer.negative_assertion"

REGO_TESTS = TESTS / "rego" / "test_v3_p45_conversions.rego"

# Testy negatywne per konwersja (muszą istnieć w test_v3_p45_conversions.rego)
NEGATIVE_TESTS = [
    "test_p45conv_neg_uor_a2_below_threshold",
    "test_p45conv_neg_uor_a3_missing_data",
    "test_p45conv_neg_mdr_hallmark_missing_benefit",
    "test_p45conv_neg_pcc_not_subject",
    "test_p45conv_neg_wht_missing_recipient",
    "test_p45conv_needs_advice_fallback",
]


def main() -> int:
    checks, findings = [], []

    hay = read(REGO_TESTS)
    present = [t for t in NEGATIVE_TESTS
               if t in hay or (t + " ") in hay or (t + "{") in hay]
    checks.append({"name": "negative_tests_present",
                   "status": "OK" if len(present) == len(NEGATIVE_TESTS) else "FAIL",
                   "detail": f"testy negatywne: {len(present)}/{len(NEGATIVE_TESTS)} "
                             f"w {REGO_TESTS.relative_to(BASE)}"})

    missing = [t for t in NEGATIVE_TESTS if t not in present]
    if missing:
        findings.append({"severity": "BLOCKER",
                         "message": f"brak testów negatywnych: {missing}"})

    # Suite konwersji musi przechodzić na obu OPA (reguły + progi + testy)
    suite = [REGO_TESTS, P45_CONVERSIONS, THRESHOLDS]
    ok68, n68, out68 = opa_test(suite, "opa")
    checks.append({"name": "opa_068_suite_pass", "status": "OK" if ok68 else "FAIL",
                   "detail": f"OPA 0.68: PASS {n68} przypadków"})
    ok19, n19, out19 = opa_test(suite, "opa19")
    checks.append({"name": "opa_19_suite_pass", "status": "OK" if ok19 else "FAIL",
                   "detail": f"OPA 1.9 (--v0-compatible): PASS {n19} przypadków"})

    if not (ok68 and ok19):
        findings.append({"severity": "BLOCKER", "message": "suite natywny konwersji nieprzechodzący"})

    # Rule wrapper negatywnego generatora w pakiecie stub_killer
    has_rule = RULE in read(BASE / "rules" / "v3_p45_stub_killer.rego")
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "negative_tests": len(present),
            "opa_068_pass": n68,
            "opa_19_pass": n19,
            "convention": "P39-I04 negative-first",
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p45_negative_assertion")


if __name__ == "__main__":
    raise SystemExit(main())
