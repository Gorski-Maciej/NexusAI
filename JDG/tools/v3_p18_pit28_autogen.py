#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I08 PIT-28 AUTOGEN.

Dowód wdrożenia: PIT-28 generowany z ewidencji (jedyne źródło prawdy) — sumy
zgodne = SUGGEST (gotowe do e-Deklaracji, termin 20.02); rozjazd = BLOCK
(invariant RYC_INV-002); rekordy niepokryte = TRIAGE.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P18-I08"

RULE = "jdg.v3_p18_ryczalt.pit28_autogen"
TH_KEYS = ["v3_p18_pit28_due"]


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_src = '"evidence_revenue_pln"' in hay and '"declaration_revenue_pln"' in hay
    has_block = "_p28_mismatch" in hay and "RYC_INV-002" in hay
    has_due = '"pit28_due"' in hay and "02-20" in hay
    th_ok = threshold_present(TH_KEYS[0])

    checks.append({"name": "pit28_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "single_source", "status": "OK" if has_src else "FAIL",
                   "detail": "PIT-28 z ewidencji (ewidencja = jedyne źródło prawdy)"})
    checks.append({"name": "mismatch_block", "status": "OK" if has_block else "FAIL",
                   "detail": "rozjazd ewidencja ↔ deklaracja = BLOCK (invariant)"})
    checks.append({"name": "due_date", "status": "OK" if has_due else "FAIL",
                   "detail": "termin PIT-28 (20.02) jako dana"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: termin z data.thresholds.lump_sum"})

    if not has_block:
        findings.append({"id": "V3-P18-L08", "severity": "P0",
                         "evidence": "PIT-28 niepowiązany z ewidencją (ryzyko rozjazdu kwot)",
                         "fix": "I08: autogen z ewidencji + walidacja (kontrakt V3_P16)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "single_source": has_src, "block": has_block,
                    "due": has_due, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 21 ustawy o zryczałtowanym PIT (PIT-28); kontrakt V3_P16 "
                                "(deklaracje/e-Deklaracje)",
                     "rule": "PIT-28 z ewidencji z walidacją sum per stawka"}}
    return emit(bundle, "v3_p18_pit28_autogen")


if __name__ == "__main__":
    raise SystemExit(main())
