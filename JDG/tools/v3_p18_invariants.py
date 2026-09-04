#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I11 RYCZAŁT INVARIANTS PACK (kontrakt V3_P04).

Dowód wdrożenia: invarianty runtime — RYC_INV-001 stawka ∈ zestaw art. 12,
RYC_INV-002 ewidencja = deklaracja, RYC_INV-003 waluty z kursem D-1 (V3_P15);
naruszenie = BLOCK_AND_ALERT z listą naruszeń.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P18-I11"

RULE = "jdg.v3_p18_ryczalt.invariants_pack"
TH_KEYS = ["v3_p18_invariants_active", "v3_p18_rate_set"]


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_i1 = "RYC_INV-001" in hay and '"applied_rate"' in hay
    has_i2 = "RYC_INV-002" in hay and "evidence_declaration_mismatch" in hay
    has_i3 = "RYC_INV-003" in hay and "currency_rate_missing" in hay and "D-1" in hay
    has_list = '"violations"' in hay and "object.keys(_iv_flags)" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "invariants_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "RYC_INV_001", "status": "OK" if has_i1 else "FAIL",
                   "detail": "stawka ∈ zestaw art. 12"})
    checks.append({"name": "RYC_INV_002", "status": "OK" if has_i2 else "FAIL",
                   "detail": "ewidencja = deklaracja (PIT-28)"})
    checks.append({"name": "RYC_INV_003", "status": "OK" if has_i3 else "FAIL",
                   "detail": "waluty z kursem D-1 (V3_P15)"})
    checks.append({"name": "violation_list", "status": "OK" if has_list else "FAIL",
                   "detail": "lista naruszeń w certyfikacie"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: aktywacja/zestaw z data.thresholds.lump_sum"})

    if not (has_i1 and has_i2 and has_i3):
        findings.append({"id": "V3-P18-L11", "severity": "P0",
                         "evidence": "brak invariantów runtime ryczałtu",
                         "fix": "I11: RYC_INV-001..003 + BLOCK (kontrakt P04)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "i1": has_i1, "i2": has_i2, "i3": has_i3,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "kontrakt invariantów V3_P04; art. 12/15-19 ustawy o "
                                "zryczałtowanym PIT; kursy V3_P15",
                     "rule": "pakiet invariantów ryczałtu (stawka/ewidencja/kursy)"}}
    return emit(bundle, "v3_p18_invariants")


if __name__ == "__main__":
    raise SystemExit(main())
