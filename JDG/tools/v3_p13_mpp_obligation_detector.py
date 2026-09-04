#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I04 MPP OBLIGATION DETECTOR (art. 108a-108d VAT).

Auto-detekcja MPP end-to-end: faktura (CN z zał. 15 + kwota brutto ≥ 15 000 zł)
→ obowiązek rachunku VAT → brak MPP = sankcja 30% + NKUP + solidarna
odpowiedzialność. Walidacja BRUTTO (próg 15k liczy się od kwoty brutto).
Dowód: reguła mpp_obligation_detector + mpp_mandatory_threshold (misc) +
mpp_sanction_rate (misc) w thresholds.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, THRESHOLDS, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P13-I04"


def main() -> int:
    hay = read(P13_RULES)
    th = read(THRESHOLDS)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.mpp_obligation_detector", hay)
    has_brutto = "invoice_brutto_pln" in hay and "gross_basis" in hay
    has_sanction = "sanction_30pct" in hay and "nkup" in hay and "solidary_liability" in hay
    has_block = "BLOCK_AND_ALERT" in hay and "violation" in hay
    missing = thresholds_missing(["mpp_mandatory_threshold", "mpp_sanction_rate"], th)

    checks.append({"name": "mpp_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła mpp_obligation_detector: {has_rule}"})
    checks.append({"name": "gross_basis", "status": "OK" if has_brutto else "FAIL",
                   "detail": "próg 15k liczony od kwoty BRUTTO"})
    checks.append({"name": "sanctions_108d", "status": "OK" if has_sanction else "FAIL",
                   "detail": "sankcja 30% + NKUP + solidarna odpowiedzialność"})
    checks.append({"name": "block_on_violation", "status": "OK" if has_block else "FAIL",
                   "detail": "brak MPP przy obowiązku → BLOCK_AND_ALERT"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów MPP (misc): {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P13-L06", "severity": "P2",
                         "evidence": f"brak parametrów MPP: {missing}",
                         "fix": "I04: walidacja brutto 15k + blokada reguł (30% + NKUP + solidarna)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"mpp_rule": has_rule, "brutto": has_brutto, "sanction": has_sanction,
                    "block": has_block, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry), P05 (temporalność), P10 (golden), P16 (JPK MPP), P41 (UI płatności)",
                     "rule": "auto-detekcja MPP end-to-end + blokada (30% + NKUP + solidarna) + walidacja brutto 15k"}}
    return emit(bundle, "v3_p13_mpp_obligation_detector")


if __name__ == "__main__":
    raise SystemExit(main())