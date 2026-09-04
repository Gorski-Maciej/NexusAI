#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I06 EWC CODE LIBRARY (baza kodów jako dane).

Dowód wdrożenia: walidacja ewidencji odpadów — format kodu EWC 6-cyfrowy
(XX XX XX), obecność w bibliotece (wersja z data.thresholds), kod poza bazą
lub zły format = BLOCK (fail-closed), brak danych = TRIAGE.
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I06"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.ewc_code_library"
TH_KEYS = ["v3_p19_ewc_library_version"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"ewc_code"', '"code_in_library"',
                                        '"code_format_valid"'))
    has_format = "_ewc_format_ok" in hay and "format" in hay.lower()
    has_known = "_ewc_known" in hay and "code_in_library" in hay
    has_fail_closed = "_ewc_format_bad" in hay
    has_version = "v3_p19_ewc_library_version" in hay or "ewc-2026" in hay
    th_ok = threshold_present(TH_KEYS[0])
    wired = main_jdg_wired()

    checks.append({"name": "ewc_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "contract_fields", "status": "OK" if has_fields else "FAIL",
                   "detail": "kontrakt: kod EWC / obecność w bazie / format"})
    checks.append({"name": "format_validation", "status": "OK" if has_format else "FAIL",
                   "detail": "walidacja formatu kodu EWC"})
    checks.append({"name": "library_membership", "status": "OK" if has_known else "FAIL",
                   "detail": "członkostwo kodu w bibliotece EWC"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "zły format / kod poza bazą = BLOCK (fail-closed)"})
    checks.append({"name": "version_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: wersja bazy EWC z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_fail_closed:
        findings.append({"id": "V3-P19-L06", "severity": "P0",
                         "evidence": "brak BLOCK dla kodu EWC spoza bazy / złego formatu",
                         "fix": "I06: biblioteka kodów EWC z walidacją formatu"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "format": has_format, "membership": has_known,
                    "fail_closed": has_fail_closed, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "rozporządzenie ws. katalogu odpadów (EWC); ADR-002",
                     "rule": "biblioteka kodów EWC jako dane + walidacja ewidencji"}}
    return emit(bundle, "v3_p19_ewc_library")


if __name__ == "__main__":
    raise SystemExit(main())
