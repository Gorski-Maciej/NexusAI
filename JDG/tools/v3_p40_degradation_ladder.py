#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I07 DEGRADATION LADDER — plan degradacji:
pełny → tylko cache → tryb offline (kolejki P32) → read-only; tryb deklarowany
w nagłówku odpowiedzi X-API-Mode. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p40_common import (read_json, API_CONTRACT, emit, main_jdg_wired,
                           now, rule_present)

INNOVATION = "V3-P40-I07"
RULE = "jdg.v3_p40_api_dane_ui.degradation_ladder"
EXPECTED_LADDER = ["FULL", "CACHE_ONLY", "OFFLINE_QUEUES", "READ_ONLY"]


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    contract = read_json(API_CONTRACT)
    dl = contract.get("degradation_ladder", {}) if contract else {}
    modes = dl.get("modes", []) if isinstance(dl, dict) else []
    ladder_ok = modes == EXPECTED_LADDER
    checks.append({"name": "degradation_ladder_as_data", "status": "OK" if ladder_ok else "FAIL",
                   "detail": f"drabinka degradacji w kontrakcie: {modes} (oczekiwane: {EXPECTED_LADDER})"})

    header = dl.get("response_header", "") if isinstance(dl, dict) else ""
    header_ok = header == "X-API-Mode"
    checks.append({"name": "api_mode_header", "status": "OK" if header_ok else "FAIL",
                   "detail": f"nagłówek trybu w kontrakcie: {header!r} (oczekiwane X-API-Mode)"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "degradation_ladder_as_data": ladder_ok,
            "api_mode_header": header_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_degradation_ladder")


if __name__ == "__main__":
    raise SystemExit(main())
