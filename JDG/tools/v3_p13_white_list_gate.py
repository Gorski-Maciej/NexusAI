#!/usr/bin/env python3
"""NexusAI JDG — V3-P13-I06 WHITE LIST GATE (art. 96b VAT).

Weryfikacja przed przelewem > 15 000 zł: status na Białej Liście + cache TTL +
fallback offline (NEEDS_ADVICE) + audit weryfikacji. Nie na liście = BLOCK
(sankcja 20% + NKUP + solidarna odpowiedzialność). Dowód: reguła white_list_gate
+ parametry whitelist_* w thresholds.
"""
from __future__ import annotations

from v3_p13_common import P13_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P13-I06"


def main() -> int:
    hay = read(P13_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p13_vat_deductions.white_list_gate", hay)
    has_threshold = "whitelist_check_threshold_pln" in hay and "verification_required" in hay
    has_fallback = "fallback_mode" in hay and "NEEDS_ADVICE" in hay
    has_audit = "audit_entry" in hay and "cache_ttl_hours" in hay
    missing = thresholds_missing(["whitelist_check_threshold_pln", "whitelist_cache_ttl_hours",
                                  "whitelist_fallback_mode"])

    checks.append({"name": "whitelist_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła white_list_gate: {has_rule}"})
    checks.append({"name": "before_transfer_15k", "status": "OK" if has_threshold else "FAIL",
                   "detail": "weryfikacja przed przelewem > 15 000 zł (art. 96b)"})
    checks.append({"name": "offline_fallback", "status": "OK" if has_fallback else "FAIL",
                   "detail": "fallback offline → NEEDS_ADVICE (nigdy cichy AUTO_POST)"})
    checks.append({"name": "cache_and_audit", "status": "OK" if has_audit else "FAIL",
                   "detail": "cache TTL + audit weryfikacji"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów whitelist_*: {missing or 'BRAK'}"})

    if missing:
        findings.append({"id": "V3-P13-L10", "severity": "P3",
                         "evidence": f"brak parametrów Białej Listy: {missing}",
                         "fix": "I06: weryfikacja przed przelewem + cache TTL + fallback NEEDS_ADVICE + audit"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"whitelist_rule": has_rule, "threshold": has_threshold,
                    "fallback": has_fallback, "audit": has_audit, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P05 (temporalność), P10 (golden), P39 (bramki CI), P41 (UI review), P13 (cross-border)",
                     "rule": "Biała Lista (art. 96b): weryfikacja > 15k przed przelewem, cache, fallback NEEDS_ADVICE, audit"}}
    return emit(bundle, "v3_p13_white_list_gate")


if __name__ == "__main__":
    raise SystemExit(main())