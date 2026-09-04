#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I01 KSeF SESSION ORCHESTRATOR (art. 106ka-106m VAT).

Dowód wdrożenia: reguła ksef_session_orchestrator + parametry sesji/offline
(sesje online/batch/offline, idempotencja, retry max_retries, okno offline 168h)
+ sprawdzenie kompilacji rego.
"""
from __future__ import annotations

import subprocess

from v3_p16_common import P16_RULES, THRESHOLDS, REPO, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P16-I01"


def _opa_compiles() -> bool:
    r = subprocess.run([str(REPO / "bin" / "opa"), "check", str(P16_RULES), str(THRESHOLDS)],
                       capture_output=True, text=True)
    return r.returncode == 0


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.ksef_session_orchestrator", hay)
    has_switch = "should_switch_offline" in hay and "offline_window_hours" in hay
    has_retry = "retry_exhausted" in hay and "max_retries" in hay
    has_idem = "_so_missing_ksef_number" in hay and "ksef_mandatory_from" in hay
    missing = thresholds_missing(["v3_p16_session_max_retries", "v3_p16_offline_window_hours",
                                  "ksef_mandatory_from"])
    compiles = _opa_compiles()

    checks.append({"name": "orchestrator_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła ksef_session_orchestrator: {has_rule}"})
    checks.append({"name": "offline_switch", "status": "OK" if has_switch else "FAIL",
                   "detail": "przełączenie ONLINE→OFFLINE (okno 168h)"})
    checks.append({"name": "retry_policy", "status": "OK" if has_retry else "FAIL",
                   "detail": "retry z max_retries + eskalacja"})
    checks.append({"name": "idempotency", "status": "OK" if has_idem else "FAIL",
                   "detail": "numer KSeF wymagany po dacie obowiązku"})
    checks.append({"name": "params_adr002", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})
    checks.append({"name": "opa_check", "status": "OK" if compiles else "FAIL",
                   "detail": "kompilacja rego (OPA check)"})

    if not compiles:
        findings.append({"id": "V3-P16-L01", "severity": "P1",
                         "evidence": "rego nie kompiluje się",
                         "fix": "naprawić składnię reguł I01"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "offline_switch": has_switch, "retry_policy": has_retry,
                    "compiles": compiles, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "V3_P04 (zero ciszy), P12/P13 (pola faktury), ADR-002",
                     "rule": "sesje KSeF online/batch/offline z idempotencją i retry"}}
    return emit(bundle, "v3_p16_session_orchestrator")


if __name__ == "__main__":
    raise SystemExit(main())
