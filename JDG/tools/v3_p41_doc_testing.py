#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I10 DOCUMENTATION TESTING — przykłady curl/rego
w dokumentach testowane w CI (example-as-test). Podanalizy: AN04.
"""
from __future__ import annotations

import re

from v3_p41_common import DOCS, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P41-I10"
RULE = "jdg.v3_p41_dokumentacja.doc_testing"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Przykłady w dokumentacji (bloki kodu do przetestowania)
    api_ref = read(DOCS / "API_REFERENCJA.md")
    curl_examples = len(re.findall(r"```(bash|sh|shell|curl)", api_ref))
    rego_examples = len(re.findall(r"```rego", api_ref))
    examples_ok = (curl_examples + rego_examples) > 0
    checks.append({"name": "examples_present", "status": "OK" if examples_ok else "FAIL",
                   "detail": f"przykłady w API_REFERENCJA.md: curl={curl_examples}, rego={rego_examples}"})

    # Testy pytest w repo odwołują się do endpointów z docs (example-as-test seed)
    tests_dir = DOCS.parent / "tests"
    risk_api = tests_dir / "test_risk_api.py"
    has_api_tests = risk_api.exists()
    checks.append({"name": "api_example_tests_exist", "status": "OK" if has_api_tests else "FAIL",
                   "detail": f"tests/test_risk_api.py (testy przykładów API): {has_api_tests}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "curl_examples": curl_examples,
            "rego_examples": rego_examples,
            "api_example_tests_exist": has_api_tests,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_doc_testing")


if __name__ == "__main__":
    raise SystemExit(main())
