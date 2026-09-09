#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I03 WORM HASH CHAIN — bloki z hash chain i podpisem;
manipulacja wykrywalna; test tamper-proof. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p42_common import (SYSTEM_REGISTER, WORM_STORAGE, emit,
                           main_jdg_wired, now, read, read_json, rule_present)

INNOVATION = "V3-P42-I03"
RULE = "jdg.v3_p42_enterprise_reszta.worm_hash_chain"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    worm_ok = WORM_STORAGE.exists()
    checks.append({"name": "worm_tool_exists", "status": "OK" if worm_ok else "FAIL",
                   "detail": f"tools/worm_storage.py: {worm_ok}"})

    worm_src = read(WORM_STORAGE)
    has_chain = "prev_hash" in worm_src or "hash_chain" in worm_src or "previous_hash" in worm_src
    checks.append({"name": "hash_chain_mechanism", "status": "OK" if has_chain else "FAIL",
                   "detail": f"hash chain w worm_storage.py (prev_hash): {has_chain}"})

    reg = read_json(SYSTEM_REGISTER)
    worm_spec = reg.get("worm", {}) if isinstance(reg, dict) else {}
    tamper = worm_spec.get("tamper_test_in_ci", False)
    checks.append({"name": "tamper_test_in_register", "status": "OK" if tamper else "FAIL",
                   "detail": f"test tamper-proof w rejestrze (CI): {tamper}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "worm_tool_exists": worm_ok,
            "hash_chain_mechanism": has_chain,
            "tamper_test_in_register": tamper,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_worm_hash_chain")


if __name__ == "__main__":
    raise SystemExit(main())
