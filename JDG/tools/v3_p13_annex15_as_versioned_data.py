#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I05 ANNEX 15 AS VERSIONED DATA (zał. 15 VAT).

Lista towarów/usług MPP (CN ~150 pozycji) jako DANE wersjonowane
(data.jdg.thresholds.vat.annex15_cn_codes) z walidacją PKWiU/CN i historią zmian
(annex15_valid_from/annex15_data_version). Nieznany CN / brak danych =
NEEDS_ADVICE. Dowód: reguła annex15_as_versioned_data + parametry annex15_*.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P13-I05"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.annex15_as_versioned_data", hay)
    has_data = "annex15_cn_codes" in hay and "annex15_data_version" in hay
    has_validation = "annex15_matched" in hay and "startswith" in hay
    has_fail_closed = "NEEDS_ADVICE" in hay and "data_complete" in hay
    missing = thresholds_missing(["annex15_cn_codes", "annex15_data_version", "annex15_valid_from"])

    checks.append({"name": "annex15_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła annex15_as_versioned_data: {has_rule}"})
    checks.append({"name": "versioned_data", "status": "OK" if has_data else "FAIL",
                   "detail": "pełna lista CN jako dane wersjonowane z historią zmian"})
    checks.append({"name": "pkwiu_cn_validation", "status": "OK" if has_validation else "FAIL",
                   "detail": "walidacja PKWiU/CN (prefix match) w regułach"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "nieznany CN / brak danych → NEEDS_ADVICE"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów annex15_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P13-L07", "severity": "P2",
                         "evidence": f"brak danych annex15_*: {missing}",
                         "fix": "I05: pełna lista zał. 15 jako dane wersyjne (CN) + walidacja + historia"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"annex15_rule": has_rule, "versioned": has_data,
                    "validation": has_validation, "fail_closed": has_fail_closed,
                    "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry), P05 (temporalność), P10 (golden), P39 (bramki CI), P44",
                     "rule": "zał. 15 (MPP) jako dane wersjonowane CN + walidacja PKWiU/CN + historia zmian"}}
    return emit(bundle, "v3_p13_annex15_as_versioned_data")


if __name__ == "__main__":
    raise SystemExit(main())