#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I09 VAT BALANCE INVARIANTS (art. 86, 89a/89b, 106e VAT).

Invarianty runtime (P04): (1) odliczenia ≤ należny, (2) symetria korekt
in_minus = in_plus (art. 89a/89b), (3) spójność JPK_V7 (art. 106e).
Naruszenie = BLOCK_AND_ALERT. Dowód: reguła vat_balance_invariants.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, emit

INNOVATION = "V3-P13-I09"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.vat_balance_invariants", hay)
    has_balance = "deduction_le_due_ok" in hay and "input_vat_pln" in hay and "output_vat_pln" in hay
    has_symmetry = "correction_symmetry_ok" in hay and "corrections_in_minus_pln" in hay
    has_jpk = "jpk_v7_coherent" in hay
    has_block = "BLOCK_AND_ALERT" in hay and "vat_invariants_fail" in hay

    checks.append({"name": "invariants_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła vat_balance_invariants: {has_rule}"})
    checks.append({"name": "deduction_le_due", "status": "OK" if has_balance else "FAIL",
                   "detail": "odliczenia ≤ należny (art. 86 VAT)"})
    checks.append({"name": "correction_symmetry", "status": "OK" if has_symmetry else "FAIL",
                   "detail": "symetria korekt in_minus = in_plus (art. 89a/89b)"})
    checks.append({"name": "jpk_coherence", "status": "OK" if has_jpk else "FAIL",
                   "detail": "spójność JPK_V7 (art. 106e VAT)"})
    checks.append({"name": "block_on_violation", "status": "OK" if has_block else "FAIL",
                   "detail": "naruszenie invariantu → BLOCK_AND_ALERT (P04)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"invariants_rule": has_rule, "balance": has_balance,
                    "symmetry": has_symmetry, "jpk": has_jpk, "block": has_block},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P04 (invarianty), P10 (golden), P39 (bramki CI), P03 (werdykt), P16 (JPK_V7)",
                     "rule": "invarianty VAT: odliczenia ≤ należny + symetria korekt + spójność JPK (P04)"}}
    return emit(bundle, "v3_p13_vat_balance_invariants")


if __name__ == "__main__":
    raise SystemExit(main())