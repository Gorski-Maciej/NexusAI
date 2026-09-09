#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I01 HARD GATE CERTIFICATE — certyfikat wyłącznie gdy
wszystkie bramki twarde zamknięte; inaczej NO_CERT z listą. Produkcja zawsze
NOT_CERTIFIED bez telemetrii zewnętrznej. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p44_common import (CERT_REGISTER, FINAL_V4_GATE, emit, main_jdg_wired,
                           now, read_json, rule_present, threshold_present)

INNOVATION = "V3-P44-I01"
RULE = "jdg.v3_p44_certyfikacja_finalna.hard_gate_certificate"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    gates = reg.get("hard_gates", {}) if isinstance(reg, dict) else {}
    failed = [k for k, v in gates.items() if isinstance(v, dict) and v.get("ok") is not True]
    all_ok = bool(gates) and not failed
    checks.append({"name": "hard_gates_closed", "status": "OK" if all_ok else "FAIL",
                   "detail": f"bramki twarde: {len(gates) - len(failed)}/{len(gates)} zamknięte, otwarte={failed}"})

    # Dowód istnienia bramki enterprise_v4 (kod, nie deklaracja)
    gate_exists = FINAL_V4_GATE.exists()
    checks.append({"name": "v4_gate_tool_exists", "status": "OK" if gate_exists else "FAIL",
                   "detail": f"tools/final_certification_v4_gate.py: {gate_exists}"})

    honesty = "NOT_CERTIFIED" in str(reg.get("scope", "")) if isinstance(reg, dict) else False
    checks.append({"name": "production_honesty", "status": "OK" if honesty else "FAIL",
                   "detail": "rejestr deklaruje produkcję NOT_CERTIFIED (uczciwość, zero marketingu)"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p108"})

    if not all_ok:
        findings.append({"severity": "BLOCKER", "message": f"otwarte bramki twarde: {failed}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "hard_gates_total": len(gates),
            "hard_gates_open": len(failed),
            "production_status": "NOT_CERTIFIED",
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_hard_gate_certificate")


if __name__ == "__main__":
    raise SystemExit(main())
