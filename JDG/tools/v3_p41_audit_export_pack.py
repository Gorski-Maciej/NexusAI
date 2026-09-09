#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I06 AUDIT EXPORT PACK — dokumenty + rejestry +
checksumy + pieczęć jednym poleceniem. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p41_common import (BASE, DOC_REGISTRY, SECTION6_DOCS, DOCS,
                           emit, main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P41-I06"
RULE = "jdg.v3_p41_dokumentacja.audit_export_pack"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(DOC_REGISTRY)
    export_spec = reg.get("audit_export_pack", {}) if isinstance(reg, dict) else {}
    contents = export_spec.get("contents", [])
    required = ["documents", "legal_registers", "checksums", "seal"]
    contents_ok = all(c in contents for c in required)
    checks.append({"name": "export_pack_spec_complete", "status": "OK" if contents_ok else "FAIL",
                   "detail": f"zawartość pakietu w rejestrze: {contents} (wymagane: {required})"})

    checksum = isinstance(export_spec, dict) and export_spec.get("checksum_required", False)
    checks.append({"name": "checksum_required", "status": "OK" if checksum else "FAIL",
                   "detail": f"checksumy obowiązkowe: {checksum}"})

    # Dane źródłowe pakietu istnieją (dokumenty + rejestry prawne)
    sources_ok = all((DOCS / d).exists() for d in SECTION6_DOCS)
    checks.append({"name": "export_sources_exist", "status": "OK" if sources_ok else "FAIL",
                   "detail": f"źródła pakietu (24 dokumenty): {sources_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "export_pack_spec_complete": contents_ok,
            "checksum_required": checksum,
            "export_sources_exist": sources_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_audit_export_pack")


if __name__ == "__main__":
    raise SystemExit(main())
