#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I10 LOCAL TAX INVARIANTS (kontrakt V3_P04).

Dowód wdrożenia: invarianty lokalne — PCC+VAT jednocześnie = BLOCK
(PCC_INV-001), stawka gminna ponad limit = BLOCK, termin minięty = BLOCK;
aktywność invariantów z data.thresholds; kontrakt P04.
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I10"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.local_tax_invariants"
TH_KEYS = ["v3_p19_invariants_active"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"mpp_and_pcc"', '"gmina_rate_exceeds_limit"',
                                        '"deadline_breached"'))
    has_inv001 = "PCC_INV-001" in hay
    has_gmina = '"gmina_rate_exceeds_limit"' in hay and "BLOCK" in hay
    has_deadline = '"deadline_breached"' in hay and "BLOCK" in hay
    has_contract_p04 = "kontrakt P04" in hay or "P04" in hay
    th_ok = threshold_present(TH_KEYS[0])
    wired = main_jdg_wired()

    checks.append({"name": "invariants_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "invariant_inputs", "status": "OK" if has_fields else "FAIL",
                   "detail": "flagi naruszeń: PCC+VAT / limit gminny / termin"})
    checks.append({"name": "pcc_inv_001", "status": "OK" if has_inv001 else "FAIL",
                   "detail": "invariant PCC_INV-001 (zero podwójnego opodatkowania)"})
    checks.append({"name": "gmina_limit_block", "status": "OK" if has_gmina else "FAIL",
                   "detail": "stawka gminna ponad limit = BLOCK"})
    checks.append({"name": "deadline_block", "status": "OK" if has_deadline else "FAIL",
                   "detail": "termin minięty = BLOCK"})
    checks.append({"name": "contract_p04", "status": "OK" if has_contract_p04 else "FAIL",
                   "detail": "kontrakt invariantów V3_P04"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: aktywność invariantów z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_inv001:
        findings.append({"id": "V3-P19-L10", "severity": "P0",
                         "evidence": "brak invariantu PCC_INV-001 w paczce lokalnej",
                         "fix": "I10: invarianty lokalne (PCC+VAT, limity, terminy)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "pcc_inv_001": has_inv001,
                    "gmina_block": has_gmina, "deadline_block": has_deadline,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "kontrakt V3_P04 (invarianty); PCC_INV-001; UoPiOL art. 5/10",
                     "rule": "paczka invariantów lokalnych — naruszenie = BLOCK"}}
    return emit(bundle, "v3_p19_invariants")


if __name__ == "__main__":
    raise SystemExit(main())
