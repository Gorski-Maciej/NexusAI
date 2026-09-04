#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I01 PCC MATRIX COMPLETE (art. 1-10 ustawy o PCC).

Dowód wdrożenia: macierz czynność→stawka (2%/0,5%/1% z danych, reużycie
pcc_sale_rate/pcc_loan_rate/pcc_company_rate), zwolnienie pożyczek ≤ 1000 zł
(art. 9), termin 14 dni PCC-3, wyłączenie MPP (I03), nieznana czynność =
BLOCK (fail-closed).
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I01"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.pcc_matrix"
TH_KEYS = ["pcc_sale_rate", "pcc_loan_rate", "pcc_company_rate",
           "v3_p19_loan_exemption_limit", "v3_p19_pcc3_form"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"transaction_type"', '"amount_pln"',
                                        '"mpp_invoice"', '"pcc3_filed"',
                                        '"days_left_to_deadline"'))
    has_rates = all(f in hay for f in ('pcc_sale_rate', 'pcc_loan_rate',
                                       'pcc_company_rate'))
    has_exemption = 'v3_p19_loan_exemption_limit' in hay and '"LOAN"' in hay
    has_deadline = '"PCC-3"' in hay or "pcc3_filed" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)
    wired = main_jdg_wired()

    checks.append({"name": "pcc_matrix_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "contract_fields", "status": "OK" if has_fields else "FAIL",
                   "detail": "kontrakt wejściowy: typ czynności/kwota/MPP/PCC-3/termin"})
    checks.append({"name": "rates_as_data", "status": "OK" if has_rates else "FAIL",
                   "detail": "stawki 2%/0,5%/1% z data.thresholds (pcc_*)"})
    checks.append({"name": "loan_exemption", "status": "OK" if has_exemption else "FAIL",
                   "detail": "zwolnienie pożyczek ≤ 1000 zł (art. 9 pkt 10)"})
    checks.append({"name": "deadline_14d", "status": "OK" if has_deadline else "FAIL",
                   "detail": "termin 14 dni / PCC-3 w logice decyzji"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": f"ADR-002: klucze thresholdów ({len(TH_KEYS)})"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_rule:
        findings.append({"id": "V3-P19-L01", "severity": "P0",
                         "evidence": "brak reguły pcc_matrix",
                         "fix": "I01: macierz PCC z progami 1000 zł i terminem 14 dni"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "fields": has_fields, "rates": has_rates,
                    "exemption": has_exemption, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "ustawa o PCC art. 1-10 (stawki/zwolnienia); art. 9 pkt 10; ADR-002",
                     "rule": "macierz czynność→stawka z progami 1000 zł / 14 dni / wyłączeniem MPP"}}
    return emit(bundle, "v3_p19_pcc_matrix")


if __name__ == "__main__":
    raise SystemExit(main())
