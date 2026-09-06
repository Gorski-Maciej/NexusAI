#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I04 HEALTH 2026 VERIFIER (weryfikacja stawek ISAP).

Dowód wdrożenia: wersja parametrów zdrowotnej z danych (zus26) + status
weryfikacji ISAP; rozjazd wersji host↔dane = BLOCK; brak weryfikacji = TRIAGE.
Lista poprawek 2026 → wejście do P44 (PRIORYTET P0 jeśli rozbieżności).
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, ZUS_CORE, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P26-I04"
RULE = "jdg.v3_p26_zus_skladki.health_2026_verifier"


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_version = threshold_present("v3_p26_health_params_version")
    has_isap = '"isap_verified"' in hay
    has_mismatch = "_hv_version_mismatch" in hay
    has_tag = "[NIEZWERYFIKOWANE]" in hay

    checks.append({"name": "verifier_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "versioned_params", "status": "OK" if has_version else "FAIL",
                   "detail": "wersja parametrów zdrowotnej z data.thresholds.zus26"})
    checks.append({"name": "isap_gate", "status": "OK" if has_isap else "FAIL",
                   "detail": "brak weryfikacji ISAP = TRIAGE (nigdy zaufanie domyślne)"})
    checks.append({"name": "version_mismatch_block", "status": "OK" if has_mismatch else "FAIL",
                   "detail": "rozjazd wersji host↔dane = BLOCK (akt 8.04)"})
    checks.append({"name": "legal_tag", "status": "OK" if has_tag else "FAIL",
                   "detail": "stawki/progi oznaczone [NIEZWERYFIKOWANE] (protokół 04)"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not has_isap:
        findings.append({"id": "V3-P26-L04", "severity": "P1",
                         "evidence": "brak bramki isap_verified",
                         "fix": "I04: gate weryfikacji ISAP przed zaufaniem parametrom"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "isap_gate": has_isap,
                    "health_scale_rate": ZUS_CORE["health_scale_rate"],
                    "health_linear_rate": ZUS_CORE["health_linear_rate"],
                    "linear_deduction_limit_2026": 14100},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Lista poprawek zdrowotnej → wejście do P44 (P0 przy "
                                "rozbieżnościach); wiąże P14 (dochód) i P18 (ryczałt)",
                     "rule": "wersja host ≠ dane = BLOCK; brak ISAP = TRIAGE"}}
    return emit(bundle, "v3_p26_health_2026_verifier")


if __name__ == "__main__":
    raise SystemExit(main())
