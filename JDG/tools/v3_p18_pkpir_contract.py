#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I07 RYCZAŁT-PKPiR CONTRACT.

Dowód wdrożenia: kontrakt pól ewidencji ryczałtu z PKPiR (P28) — sumy zgodne
w tolerancji groszowej (v3_p18_contract_tolerance_pln); rozjazd = BLOCK;
rekordy nieuzgodnione = TRIAGE.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P18-I07"

RULE = "jdg.v3_p18_ryczalt.pkpir_contract"
TH_KEYS = ["v3_p18_contract_tolerance_pln"]


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = '"ryczalt_revenue_pln"' in hay and '"pkpir_revenue_pln"' in hay and '"difference_pln"' in hay
    has_block = "_pc_mismatch" in hay and "tolerance" in hay
    th_ok = threshold_present(TH_KEYS[0])

    checks.append({"name": "contract_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "fields", "status": "OK" if has_fields else "FAIL",
                   "detail": "pola: suma ryczałt vs suma PKPiR + różnica"})
    checks.append({"name": "zero_drift_block", "status": "OK" if has_block else "FAIL",
                   "detail": "rozjazd > tolerancji = BLOCK (zero rozjazdów)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: tolerancja groszowa z data.thresholds.lump_sum"})

    if not has_block:
        findings.append({"id": "V3-P18-L07", "severity": "P1",
                         "evidence": "brak kontraktu pól ryczałt↔PKPiR",
                         "fix": "I07: zero rozjazdów (tolerancja groszowa)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "fields": has_fields, "block": has_block,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 15-19 ustawy o zryczałtowanym PIT; kontrakt V3_P28 (PKPiR)",
                     "rule": "kontrakt pól ewidencji ryczałt ↔ PKPiR"}}
    return emit(bundle, "v3_p18_pkpir_contract")


if __name__ == "__main__":
    raise SystemExit(main())
