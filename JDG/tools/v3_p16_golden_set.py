#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I12 KSeF/JPK GOLDEN SET (oracle, walidacja XSD).

Dowód wdrożenia: reguła ksef_jpk_golden_set + golden faktury/JPK z walidacją
schematową (oracle, Golden Oracle P10); rozjazd z golden = BLOCK_AND_ALERT,
zgodność = SUGGEST, poza zbiorem = TRIAGE_QUEUE (P16-AN10).
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P16-I12"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.ksef_jpk_golden_set", hay)
    has_schema = "schema_valid" in hay and "golden_fields_match" in hay
    has_violation = "oracle_violation" in hay
    has_version = "golden_version" in hay
    missing = thresholds_missing(["v3_p16_golden_set_version"])

    checks.append({"name": "golden_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła ksef_jpk_golden_set: {has_rule}"})
    checks.append({"name": "schema_validation", "status": "OK" if has_schema else "FAIL",
                   "detail": "walidacja schematowa golden faktur/JPK"})
    checks.append({"name": "oracle_gate", "status": "OK" if has_violation else "FAIL",
                   "detail": "rozjazd z golden → BLOCK_AND_ALERT (fail-closed)"})
    checks.append({"name": "version", "status": "OK" if has_version else "FAIL",
                   "detail": "wersjonowanie golden setu"})
    checks.append({"name": "params_adr002", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})

    if not has_schema:
        findings.append({"id": "V3-P16-L12", "severity": "P1",
                         "evidence": "golden set bez walidacji schematowej",
                         "fix": "I12: golden faktury/JPK z walidacją XSD (oracle)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "schema": has_schema, "violation": has_violation,
                    "version": has_version, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Golden Oracle (V2 F3, P10), P39 (bramki CI), P05 (temporalność)",
                     "rule": "golden faktury/JPK z walidacją schematową (oracle)"}}
    return emit(bundle, "v3_p16_golden_set")


if __name__ == "__main__":
    raise SystemExit(main())
