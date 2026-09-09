#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I11 AUDITOR MODE — widok audytora: pełne ścieżki
dowodowe (jak sprawdzić każdą deklarację). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p41_common import (DOC_REGISTRY, emit, main_jdg_wired, now,
                           read_json, rule_present)

INNOVATION = "V3-P41-I11"
RULE = "jdg.v3_p41_dokumentacja.auditor_mode"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(DOC_REGISTRY)
    am = reg.get("auditor_mode", {}) if isinstance(reg, dict) else {}
    view = am.get("auditor_view_doc", "")
    view_ok = bool(view)
    checks.append({"name": "auditor_view_defined", "status": "OK" if view_ok else "FAIL",
                   "detail": f"dokument widoku audytora w rejestrze: {view!r}"})

    paths = am.get("evidence_paths", {}) if isinstance(am, dict) else {}
    paths_ok = len(paths) >= 3
    checks.append({"name": "evidence_paths_complete", "status": "OK" if paths_ok else "FAIL",
                   "detail": f"ścieżki dowodowe per domena: {len(paths)} (min 3)"})

    # Łańcuch dowodowy: reguła→test→bundle→werdykt→certyfikat opisany w rejestrze
    chain = am.get("evidence_chain", []) if isinstance(am, dict) else []
    required_chain = ["rule", "test", "bundle", "verdict", "certificate"]
    chain_ok = all(c in chain for c in required_chain)
    checks.append({"name": "evidence_chain_documented", "status": "OK" if chain_ok else "FAIL",
                   "detail": f"łańcuch dowodowy w rejestrze: {chain} (wymagane: {required_chain})"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "auditor_view_defined": view_ok,
            "evidence_paths": len(paths),
            "evidence_chain_documented": chain_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_auditor_mode")


if __name__ == "__main__":
    raise SystemExit(main())
