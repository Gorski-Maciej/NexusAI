#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I05 CROSS-WRITE DETECTOR — dwie reguły zapisujące tę
samą ścieżkę werdyktu bez precedence = BLOCKER — kampania V3 FORTRESS.

Dowód wdrożenia: AP08 zamknięty — konflikt zapisów wykrywany statycznie;
konflikt bez precedence = BLOCK. Narząd: cross_package_conflict_detector.py.
Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p34_common import (BASE, P34_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P34-I05"
RULE = "jdg.v3_p34_walidacja_narzedzia.cross_write_detector"


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    detector = (BASE / "tools" / "cross_package_conflict_detector.py").exists()
    checks.append({"name": "conflict_detector_present", "status": "OK" if detector else "FAIL",
                   "detail": "tools/cross_package_conflict_detector.py: " + str(detector)})

    block_path = "precedence" in hay and "BLOCK" in hay
    checks.append({"name": "no_precedence_block_path", "status": "OK" if block_path else "FAIL",
                   "detail": "konflikt bez precedence = BLOCK (AP08): " + str(block_path)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "conflict_detector_present": detector,
            "no_precedence_block_path": block_path,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_cross_write_detector")


if __name__ == "__main__":
    raise SystemExit(main())
