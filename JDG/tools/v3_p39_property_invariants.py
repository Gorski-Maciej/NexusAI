#!/usr/bin/env python3
"""NexusAI JDG — V3-P39-I05 PROPERTY INVARIANTS PACK — biblioteka niezmienników
(suma składek ≥ 0, VAT ∈ stawki, waluta stabilna) używana przez property/fuzz
(K10 chaos fail-closed). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p39_common import emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P39-I05"
RULE = "jdg.v3_p39_testy_ci.property_invariants"

# Niezmienniki pakietu jako dane (kontrakt strategii testów)
INVARIANTS = [
    "invariant_totals_non_negative",
    "invariant_vat_rate_from_set",
    "invariant_currency_stable",
    "invariant_fail_closed_on_missing_field",
]


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    strategy = read(__import__("v3_p39_common").TEST_STRATEGY)
    all_inv = all(inv in strategy for inv in INVARIANTS)
    checks.append({"name": "invariants_pack_as_data", "status": "OK" if all_inv else "FAIL",
                   "detail": f"niezmienniki {len(INVARIANTS)} w kontrakcie strategii: {all_inv}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p103"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "invariants_count": len(INVARIANTS),
            "invariants_pack_as_data": all_inv,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p39_property_invariants")


if __name__ == "__main__":
    raise SystemExit(main())
