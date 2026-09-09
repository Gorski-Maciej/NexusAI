#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I09 CERTIFICATION RENEWAL POLICY — kiedy certyfikat
wygasa (nowelizacje, deploy krytyczny, czas) — mechanizm odnowienia zamiast
wiecznej ważności. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p44_common import (CERT_REGISTER, emit, now, read_json, rule_present,
                           threshold_present)

INNOVATION = "V3-P44-I09"
RULE = "jdg.v3_p44_certyfikacja_finalna.certification_renewal_policy"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    pol = reg.get("renewal_policy", {}) if isinstance(reg, dict) else {}
    triggers = pol.get("triggers", []) if isinstance(pol, dict) else []
    has_expiry = len(triggers) >= 3
    checks.append({"name": "expiry_policy_defined", "status": "OK" if has_expiry else "FAIL",
                   "detail": f"wyzwalacze wygaśnięcia (nowelizacja/deploy/czas): {len(triggers)} → {triggers}"})

    proc = str(pol.get("renewal_procedure", "")) if isinstance(pol, dict) else ""
    checks.append({"name": "renewal_procedure", "status": "OK" if proc else "FAIL",
                   "detail": f"procedura odnowienia: {proc or 'BRAK'}"})

    time_thr = threshold_present("v3_p44_cert_validity_max_days")
    checks.append({"name": "time_threshold_as_data", "status": "OK" if time_thr else "FAIL",
                   "detail": "próg v3_p44_cert_validity_max_days w thresholds_jdg.rego (ADR-002)"})

    days = pol.get("days_since_certification", 0) if isinstance(pol, dict) else 0
    checks.append({"name": "within_validity_window", "status": "OK" if days <= 90 else "FAIL",
                   "detail": f"dni od certyfikacji: {days} (okno 90)"})

    if not has_expiry:
        findings.append({"severity": "BLOCKER", "message": "certyfikat wieczysty = fikcja; brak polityki wygaśnięcia"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "triggers": len(triggers),
            "days_since_certification": days,
            "time_threshold_present": time_thr,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_renewal_policy")


if __name__ == "__main__":
    raise SystemExit(main())
