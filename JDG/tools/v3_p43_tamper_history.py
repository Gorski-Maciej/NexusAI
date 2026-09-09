#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I08 TAMPER-EVIDENT RULE HISTORY — każda zmiana reguły
z hash chain w WORM (historia nie podlega cichej edycji). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p43_common import (WORM_STORAGE, emit, main_jdg_wired, now, read,
                           read_json, rule_present)

INNOVATION = "V3-P43-I08"
RULE = "jdg.v3_p43_security_dr.tamper_rule_history"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Mechanizm hash chain w worm_storage (skan źródła — dowód realności)
    src = read(WORM_STORAGE)
    has_chain = "prev_hash" in src or "previous_hash" in src or "hash_chain" in src
    checks.append({"name": "hash_chain_in_worm_source", "status": "OK" if has_chain else "FAIL",
                   "detail": f"hash chain (prev_hash) w tools/worm_storage.py: {has_chain}"})

    # Zakres: historia zmian reguł jest archiwizowana (kontrakt P42-K3)
    import json
    from v3_p43_common import SECURITY_REGISTER
    reg = read_json(SECURITY_REGISTER)
    worm = reg.get("worm", {}) if isinstance(reg, dict) else {}
    archived = worm.get("archived_artifacts", []) if isinstance(worm, dict) else []
    scope_ok = "rule_history" in archived
    checks.append({"name": "rule_history_in_worm_scope", "status": "OK" if scope_ok else "FAIL",
                   "detail": f"rule_history w zakresie archiwizacji: {archived}"})

    # Tamper test w CI (kontrakt P42-K3; egzekucja w tej części)
    tamper = worm.get("tamper_test_in_ci", False)
    checks.append({"name": "tamper_test_contract", "status": "OK" if tamper else "FAIL",
                   "detail": f"test tamper-proof w CI (P42-K3): {tamper}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "hash_chain_in_worm_source": has_chain,
            "rule_history_in_worm_scope": scope_ok,
            "tamper_test_contract": tamper,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_tamper_history")


if __name__ == "__main__":
    raise SystemExit(main())
