#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I12 CURRENCY CONSISTENCY GATE (kontrakt P28/P16).

CI: te same kursy dla VAT i PKPiR na tym samym inputcie (JPK_V7 pola
WDT/WNT/UE). Niespójność = BLOCK przed księgowaniem. Dowód: reguła
currency_consistency_gate + parametr currency_consistency_required.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I12"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.currency_consistency_gate", hay)
    has_consistency = "consistent" in hay and "vat_rate" in hay and "pkpir_rate" in hay
    has_block = "BLOCK_AND_ALERT" in hay and "currency_consistency" in hay
    has_param = not thresholds_missing(["currency_consistency_required"])

    checks.append({"name": "currency_gate_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła currency_consistency_gate: {has_rule}"})
    checks.append({"name": "vat_pkpir_compare", "status": "OK" if has_consistency else "FAIL",
                   "detail": "porównanie kursów VAT vs PKPiR na tym samym inputcie"})
    checks.append({"name": "block_on_mismatch", "status": "OK" if has_block else "FAIL",
                   "detail": "niespójność kursów → BLOCK_AND_ALERT (JPK zgodność)"})
    checks.append({"name": "param", "status": "OK" if has_param else "FAIL",
                   "detail": "parametr currency_consistency_required (ADR-002)"})

    if not has_consistency:
        findings.append({"id": "V3-P15-L13", "severity": "P1",
                         "evidence": "brak bramki spójności kursów VAT↔PKPiR = ryzyko niezgodności JPK",
                         "fix": "I12: bramka CI — te same kursy dla VAT i PKPiR; kontrakt z P28/P16"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "compare": has_consistency, "block": has_block,
                    "param": has_param},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P28 (księgowość), P16 (JPK_V7), P39 (CI), P44",
                     "rule": "te same kursy dla VAT i PKPiR na tym samym inputcie; inaczej BLOCK przed księgowaniem"}}
    return emit(bundle, "v3_p15_currency_consistency_gate")


if __name__ == "__main__":
    raise SystemExit(main())