#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I09 PCC GOLDEN SET (oracle granic).

Dowód wdrożenia: golden decyzje PCC — granica 1000 zł (pożyczka), termin 14
dni PCC-3, bramka MPP (I03) w oracle; rozjazd z golden = BLOCK, przypadek
graniczny = TRIAGE, zgodny = SUGGEST; wersja golden z data.thresholds.
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I09"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.pcc_golden_set"
TH_KEYS = ["v3_p19_golden_version", "v3_p19_loan_exemption_limit"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"case_id"', '"in_golden_set"',
                                        '"golden_match"', '"boundary_case"'))
    has_drift_block = "_gs_drift" in hay or ("golden_match" in hay and "BLOCK" in hay)
    has_boundary_triage = '"boundary_case"' in hay and "TRIAGE" in hay
    has_version = "v3_p19_golden_version" in hay or "golden-2026" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)
    wired = main_jdg_wired()

    checks.append({"name": "golden_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "golden_contract", "status": "OK" if has_fields else "FAIL",
                   "detail": "kontrakt oracle: case_id/in_golden_set/match/boundary"})
    checks.append({"name": "drift_block", "status": "OK" if has_drift_block else "FAIL",
                   "detail": "rozjazd decyzji z golden = BLOCK"})
    checks.append({"name": "boundary_triage", "status": "OK" if has_boundary_triage else "FAIL",
                   "detail": "przypadek graniczny (1000 zł / 15. dzień) = TRIAGE"})
    checks.append({"name": "version_as_data", "status": "OK" if has_version else "FAIL",
                   "detail": "wersja golden set z data.thresholds (ADR-002)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: granice 1000 zł / 14 dni"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_drift_block:
        findings.append({"id": "V3-P19-L09", "severity": "P0",
                         "evidence": "brak BLOCK przy rozjeździe z golden set",
                         "fix": "I09: oracle golden z granicami 1000 zł / 14 dni / MPP"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "drift_block": has_drift_block,
                    "boundary_triage": has_boundary_triage, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "ustawa o PCC art. 9 pkt 10 (1000 zł) / termin 14 dni; ADR-002",
                     "rule": "oracle golden — rozjazd = BLOCK, granica = TRIAGE"}}
    return emit(bundle, "v3_p19_golden_set")


if __name__ == "__main__":
    raise SystemExit(main())
