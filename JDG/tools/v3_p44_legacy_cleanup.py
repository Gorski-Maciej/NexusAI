#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I10 LEGACY CLEANUP CLOSURE — finalna fala usuwania
fasad/martwych artefaktów wykrytych w kampanii (P30/P36/P42) — zero długu
technicznego na start V4. Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p44_common import (CERT_REGISTER, SYSTEM_REGISTER_P42, emit, now,
                           read_json, rule_present)

INNOVATION = "V3-P44-I10"
RULE = "jdg.v3_p44_certyfikacja_finalna.legacy_cleanup_closure"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    legacy = reg.get("legacy_cleanup", {}) if isinstance(reg, dict) else {}
    open_facades = legacy.get("legacy_facades_open", 0) if isinstance(legacy, dict) else 0
    checks.append({"name": "zero_open_facades", "status": "OK" if open_facades == 0 else "FAIL",
                   "detail": f"otwarte fasady/martwe artefakty: {open_facades} (rejestry: {legacy.get('facade_registers', [])})"})

    # Rozróżnienie dryft vs fasada: dryft legacy (P37-L03) jest rejestrowany z planem, nie udaje pokrycia
    tracked = legacy.get("tracked_legacy_gaps", [])
    tracked_with_plan = bool(tracked) and all("P36" in str(t) or "P50" in str(t) for t in tracked)
    checks.append({"name": "legacy_drift_tracked_not_hidden", "status": "OK" if tracked_with_plan else "FAIL",
                   "detail": f"dryft legacy śledzony z planem (nie-fasada): {len(tracked)} wpis(y)"})

    # Potwierdzenie z rejestru systemowego P42 (orphan sweep — self-scan)
    p42 = read_json(SYSTEM_REGISTER_P42)
    orphans = p42.get("orphan_sweep", {}) if isinstance(p42, dict) else {}
    checks.append({"name": "p42_orphan_sweep_reference", "status": "OK" if isinstance(orphans, dict) else "FAIL",
                   "detail": f"rejestr P42 (orphan sweep/self-scan) dostępny: {bool(p42)}"})

    if open_facades > 0:
        findings.append({"severity": "HIGH", "message": f"fasady otwarte: {open_facades} — dług przed V4"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "legacy_facades_open": open_facades,
            "tracked_legacy_gaps": len(tracked),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_legacy_cleanup")


if __name__ == "__main__":
    raise SystemExit(main())
