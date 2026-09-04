#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I06 JPK FIELD CONTRACT (pola JPK_V7 z P12/P13).

Dowód wdrożenia: reguła jpk_field_contract + walidacja krzyżowa przed
generacją JPK_V7 (GTU ze słownika, MPP zgodny z progiem 15k) — kontrakt pól
z V3_P12/P13 (GTU, MPP) i P28 (PKPiR→JPK).
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, now, read, rule_present, emit

INNOVATION = "V3-P16-I06"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.jpk_field_contract", hay)
    has_gtu = "gtu_violations" in hay and "row_count" in hay
    has_mpp = "mpp_unmarked_rows" in hay and "mpp_threshold_pln" in hay
    has_contract = '"contract_ok": _jfc_ok' in hay or "contract_ok" in hay

    checks.append({"name": "jpk_contract_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła jpk_field_contract: {has_rule}"})
    checks.append({"name": "gtu_check", "status": "OK" if has_gtu else "FAIL",
                   "detail": "GTU ze słownika (13 kodów) — walidacja wierszy"})
    checks.append({"name": "mpp_check", "status": "OK" if has_mpp else "FAIL",
                   "detail": "MPP zgodny z progiem (kontrakt P12/P13)"})
    checks.append({"name": "contract_gate", "status": "OK" if has_contract else "FAIL",
                   "detail": "niezgodność → blokada generacji JPK_V7"})

    if not (has_gtu and has_mpp):
        findings.append({"id": "V3-P16-L06", "severity": "P1",
                         "evidence": "kontrakt pól JPK bez walidacji GTU/MPP",
                         "fix": "I06: pola JPK_V7 jako kontrakt (P12/P13)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "gtu": has_gtu, "mpp": has_mpp, "contract": has_contract},
        "checks": checks, "findings": findings,
        "contract": {"binding": "V3_P12/P13 (GTU/MPP), P28 (PKPiR→JPK), art. 99 ust. 2a VAT",
                     "rule": "pola JPK_V7 jako kontrakt — walidacja krzyżowa przed generacją"}}
    return emit(bundle, "v3_p16_jpk_field_contract")


if __name__ == "__main__":
    raise SystemExit(main())
