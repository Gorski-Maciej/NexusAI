#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I11 CROSS-BORDER INVARIANTS (P04 runtime).

Inwarianty: WDT zawsze z VAT-UE + VIES nabywcy, kurs D-1 dla ewidencji, import
usług (art. 28b) z samoopodatkowaniem (reverse charge). Naruszenie = BLOCK.
Dowód: reguła crossborder_invariants + parametry *_invariant_required.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I11"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.crossborder_invariants", hay)
    has_wdt = "wdt_vat_ue_ok" in hay
    has_fx_d1 = "fx_d1_ok" in hay
    has_rc = "import_services_rc_ok" in hay
    has_block = "BLOCK_AND_ALERT" in hay and "invariants.all_ok" in hay
    missing = thresholds_missing(["wdt_invariant_required", "fx_d1_invariant_required",
                                  "import_services_rc_required"])

    checks.append({"name": "invariants_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła crossborder_invariants: {has_rule}"})
    checks.append({"name": "wdt_invariant", "status": "OK" if has_wdt else "FAIL",
                   "detail": "WDT wymaga VAT-UE + VIES nabywcy"})
    checks.append({"name": "fx_d1_invariant", "status": "OK" if has_fx_d1 else "FAIL",
                   "detail": "kurs D-1 dla ewidencji"})
    checks.append({"name": "import_rc_invariant", "status": "OK" if has_rc else "FAIL",
                   "detail": "import usług — reverse charge obowiązkowy"})
    checks.append({"name": "block_on_violation", "status": "OK" if has_block else "FAIL",
                   "detail": "naruszenie invariantu → BLOCK_AND_ALERT"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów *_invariant_required: {missing or 'BRAK'}"})

    if not has_block:
        findings.append({"id": "V3-P15-L12", "severity": "P0",
                         "evidence": "naruszenie invariantu cross-border bez BLOCK = fail-open (AP07)",
                         "fix": "I11: invarianty jako runtime enforcement (P04); naruszenie = BLOCK"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "wdt": has_wdt, "fx_d1": has_fx_d1,
                    "rc": has_rc, "block": has_block, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P04 (invarianty runtime), P13 (import usług), P44",
                     "rule": "WDT bez VAT-UE / kurs nie D-1 / import usług bez reverse charge = BLOCK_AND_ALERT"}}
    return emit(bundle, "v3_p15_crossborder_invariants")


if __name__ == "__main__":
    raise SystemExit(main())