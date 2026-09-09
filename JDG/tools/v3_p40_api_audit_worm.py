#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I05 API AUDIT WORM — każde wywołanie (kto, co, kiedy,
wynik, checksum) zapisane WORM (P43) — rozliczalność wywołań (RODO art. 5.2).
Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p40_common import (read_json, API_CONTRACT, emit, main_jdg_wired,
                           now, rule_present)

INNOVATION = "V3-P40-I05"
RULE = "jdg.v3_p40_api_dane_ui.api_audit_worm"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    contract = read_json(API_CONTRACT)
    audit = contract.get("api_audit_worm", {}) if contract else {}
    required_fields = ["actor", "endpoint", "timestamp", "result", "checksum"]
    fields_ok = isinstance(audit, dict) and all(f in audit.get("entry_fields", []) for f in required_fields)
    checks.append({"name": "audit_entry_fields_complete", "status": "OK" if fields_ok else "FAIL",
                   "detail": f"pola wpisu audytowego w kontrakcie: {audit.get('entry_fields', []) if isinstance(audit, dict) else 'BRAK'}"})

    worm = isinstance(audit, dict) and audit.get("worm_storage", False)
    checks.append({"name": "worm_storage", "status": "OK" if worm else "FAIL",
                   "detail": f"zapis WORM (P43): {worm}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "audit_entry_fields_complete": fields_ok,
            "worm_storage": worm,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_api_audit_worm")


if __name__ == "__main__":
    raise SystemExit(main())
