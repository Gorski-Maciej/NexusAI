#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I04 NEGATIVE-FIRST TESTING — każdy test pozytywny musi
mieć parę negatywną (brak pola → NEEDS_ADVICE); lint wymusza (AP06).
Podanalizy: AN01/AN02.
"""
from __future__ import annotations

import re

from v3_p39_common import TESTS, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P39-I04"
RULE = "jdg.v3_p39_testy_ci.negative_first"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Własny pakiet P39: macierz zawiera asercje negatywne (BLOCK/TRIAGE)
    test_src = read(TESTS / "rego" / "test_v3_p39_testy_ci_enterprise.rego")
    negatives = len(re.findall(r"BLOCK_AND_ALERT|TRIAGE_QUEUE", test_src))
    checks.append({"name": "negative_assertions_in_p39_suite", "status": "OK" if negatives >= 20 else "FAIL",
                   "detail": f"asercje negatywne (BLOCK/TRIAGE) w suite P39: {negatives}"})

    # Konwencja w regułach V3 (NEEDS_ADVICE jawnie)
    rules39 = read(__import__("v3_p39_common").P39_RULES)
    needs_advice = "NEEDS_ADVICE" in rules39 or "TRIAGE" in rules39
    checks.append({"name": "needs_advice_path_in_rules", "status": "OK" if needs_advice else "FAIL",
                   "detail": f"ścieżka NEEDS_ADVICE/TRIAGE w pakiecie P39: {needs_advice}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "negative_assertions_count": negatives,
            "needs_advice_path_in_rules": needs_advice,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_negative_first")


if __name__ == "__main__":
    raise SystemExit(main())
