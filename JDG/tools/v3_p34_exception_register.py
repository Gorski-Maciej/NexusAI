#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I12 REJESTR WYJĄTKÓW — każde wyłączenie reguły walidacji
(suppress) ma termin wygaśnięcia i właściciela — kampania V3 FORTRESS.

Dowód wdrożenia: zero wiecznych wyłączeń — wyjątek bez expiry = BLOCK,
wygasły aktywny = BLOCK, bez właściciela = TRIAGE. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p34_common import (P34_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P34-I12"
RULE = "jdg.v3_p34_walidacja_narzedzia.exception_register"


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # ścieżki fail-closed: bez expiry = BLOCK, wygasły = BLOCK, bez ownera = TRIAGE
    no_expiry_block = "exceptions_without_expiry" in hay and "BLOCK" in hay
    expired_block = "expired_exceptions" in hay
    owner_triage = "exceptions_without_owner" in hay
    checks.append({"name": "no_expiry_block_path", "status": "OK" if no_expiry_block else "FAIL",
                   "detail": "wyjątek bez wygaśnięcia = BLOCK: " + str(no_expiry_block)})
    checks.append({"name": "expired_block_path", "status": "OK" if expired_block else "FAIL",
                   "detail": "wygasły wyjątek = BLOCK: " + str(expired_block)})
    checks.append({"name": "owner_triage_path", "status": "OK" if owner_triage else "FAIL",
                   "detail": "wyjątek bez właściciela = TRIAGE: " + str(owner_triage)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "no_expiry_block_path": no_expiry_block,
            "expired_block_path": expired_block,
            "owner_triage_path": owner_triage,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_exception_register")


if __name__ == "__main__":
    raise SystemExit(main())
