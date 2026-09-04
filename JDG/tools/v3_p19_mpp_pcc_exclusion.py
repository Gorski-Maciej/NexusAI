#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I03 MPP-PCC EXCLUSION GATE (PCC_INV-001).

Dowód wdrożenia: faktura MPP (mechanizm podzielonej płatności, zał. 15 VAT)
dotyczy dostawy w VAT → PCC NIE pobudzone; podwójne opodatkowanie
(MPP + deklaracja PCC) = BLOCK (invariant PCC_INV-001, kontrakt P04);
sprzedaż bez rozstrzygnięcia = TRIAGE.
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I03"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.mpp_pcc_exclusion_gate"
TH_KEYS = ["v3_p19_mpp_pcc_exclusion"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"invoice_mpp"', '"pcc_declared"',
                                        '"asset_sale"'))
    has_double = "_mp_double" in hay and "PODWÓJNE" in hay
    has_invariant = "PCC_INV-001" in hay
    has_triage = "_mp_unknown" in hay
    th_ok = threshold_present(TH_KEYS[0])
    wired = main_jdg_wired()

    checks.append({"name": "exclusion_gate", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "contract_fields", "status": "OK" if has_fields else "FAIL",
                   "detail": "kontrakt: faktura MPP / deklaracja PCC / sprzedaż majątku"})
    checks.append({"name": "double_tax_block", "status": "OK" if has_double else "FAIL",
                   "detail": "MPP + PCC jednocześnie = BLOCK"})
    checks.append({"name": "invariant", "status": "OK" if has_invariant else "FAIL",
                   "detail": "invariant PCC_INV-001 (kontrakt P04)"})
    checks.append({"name": "triage", "status": "OK" if has_triage else "FAIL",
                   "detail": "sprzedaż bez rozstrzygnięcia = TRIAGE (fail-closed)"})
    checks.append({"name": "gate_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: aktywność bramki z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_double:
        findings.append({"id": "V3-P19-L03", "severity": "P0",
                         "evidence": "brak BLOCK przy podwójnym opodatkowaniu MPP+PCC",
                         "fix": "I03: bramka wykluczenia z invariantem PCC_INV-001"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "double_block": has_double,
                    "invariant": has_invariant, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "ustawa o PCC art. 2 pkt 4; art. 108a VAT (MPP); invariant P04",
                     "rule": "bramka MPP-PCC — zero podwójnego opodatkowania VAT/PCC"}}
    return emit(bundle, "v3_p19_mpp_pcc_exclusion")


if __name__ == "__main__":
    raise SystemExit(main())
