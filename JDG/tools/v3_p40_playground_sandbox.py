#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I10 PLAYGROUND SANDBOX — endpoint sandbox: przetestuj
regułę na fikcyjnym input (bez zapisu), bez danych osobowych — szkolenie
i debugowanie. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p40_common import (read_json, API_CONTRACT, emit, main_jdg_wired,
                           now, rule_present)

INNOVATION = "V3-P40-I10"
RULE = "jdg.v3_p40_api_dane_ui.playground_sandbox"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    contract = read_json(API_CONTRACT)
    pg = contract.get("playground", {}) if contract else {}
    no_persist = isinstance(pg, dict) and pg.get("persists_state", True) is False
    checks.append({"name": "sandbox_no_persistence", "status": "OK" if no_persist else "FAIL",
                   "detail": f"sandbox bez zapisu stanu: {no_persist}"})

    pii_strip = isinstance(pg, dict) and pg.get("pii_strip", False)
    checks.append({"name": "pii_strip", "status": "OK" if pii_strip else "FAIL",
                   "detail": f"strip PII na wejściach sandbox: {pii_strip}"})
    if not pii_strip:
        findings.append("P0: sandbox bez stripu PII — RODO minimalizacja naruszona.")

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "sandbox_no_persistence": no_persist,
            "pii_strip": pii_strip,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_playground_sandbox")


if __name__ == "__main__":
    raise SystemExit(main())
