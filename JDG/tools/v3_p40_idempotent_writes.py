#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I03 IDEMPOTENT WRITES — operacje zmieniające stan
z Idempotency-Key; retry klienta nie duplikuje księgowań (P32).
Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p40_common import OPENAPI, ORCH_CONTRACT, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P40-I03"
RULE = "jdg.v3_p40_api_dane_ui.idempotent_writes"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    openapi = read(OPENAPI)
    has_idem = "Idempotency-Key" in openapi or "idempotency_key" in openapi
    checks.append({"name": "openapi_idempotency_key", "status": "OK" if has_idem else "FAIL",
                   "detail": f"api/openapi.yaml deklaruje Idempotency-Key: {has_idem}"})
    if not has_idem:
        findings.append("P0: openapi.yaml nie deklaruje Idempotency-Key dla operacji zapisu.")

    orch = read(ORCH_CONTRACT)
    orch_status_ok = "NEEDS_ADVICE" in orch
    checks.append({"name": "orchestrator_contract_statuses", "status": "OK" if orch_status_ok else "FAIL",
                   "detail": f"ORCHESTRATOR_DATA_CONTRACT.md: statusy pipeline (NEEDS_ADVICE): {orch_status_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "openapi_idempotency_key": has_idem,
            "orchestrator_contract_statuses": orch_status_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_idempotent_writes")


if __name__ == "__main__":
    raise SystemExit(main())
