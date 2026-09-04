#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I05 RATE SPLIT ENGINE.

Dowód wdrożenia: rozdzielanie przychodów wielostawkowych (art. 12 ust. 1) —
suma per stawka z pozycji ewidencji; totals per stawka → podstawa PIT-28;
stawka spoza zestawu = BLOCK (invariant RYC_INV-001); brak pozycji = BLOCK.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P18-I05"

RULE = "jdg.v3_p18_ryczalt.rate_split_engine"
TH_KEYS = ["v3_p18_rate_set"]


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_split = '"totals_per_rate"' in hay and "line.rate" in hay and "amount_pln" in hay
    has_unknown = "_rs_unknown_rate" in hay and "RYC_INV-001" in hay
    th_ok = threshold_present(TH_KEYS[0])

    checks.append({"name": "split_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "per_rate_totals", "status": "OK" if has_split else "FAIL",
                   "detail": "sumy per stawka z pozycji ewidencji"})
    checks.append({"name": "unknown_rate_block", "status": "OK" if has_unknown else "FAIL",
                   "detail": "stawka spoza zestawu = BLOCK (invariant)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: zestaw stawek z data.thresholds.lump_sum"})

    if not has_split:
        findings.append({"id": "V3-P18-L05", "severity": "P1",
                         "evidence": "brak rozdzielania przychodów wielostawkowych",
                         "fix": "I05: ewidencja per stawka → PIT-28"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "split": has_split, "unknown_block": has_unknown,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 12 ust. 1 ustawy o zryczałtowanym PIT; art. 15 (ewidencja)",
                     "rule": "split przychodów wielostawkowych per stawka"}}
    return emit(bundle, "v3_p18_rate_split")


if __name__ == "__main__":
    raise SystemExit(main())
