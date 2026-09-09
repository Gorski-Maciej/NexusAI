#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I12 EXPORT EVIDENCE PACK — jeden klik: eksport całego
dowodu decyzji (certyfikat, input, reguły, bundle hash, podpisy) jako pakiet;
checksum obowiązkowa (UoR art. 4 ust. 1 sprawdzalność). Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p40_common import (read_json, API_CONTRACT, CERT_SERVICE, emit,
                           main_jdg_wired, now, rule_present)

INNOVATION = "V3-P40-I12"
RULE = "jdg.v3_p40_api_dane_ui.evidence_pack"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    contract = read_json(API_CONTRACT)
    ep = contract.get("evidence_pack", {}) if contract else {}
    contents = ep.get("contents", []) if isinstance(ep, dict) else []
    required = ["decision_certificate", "input_snapshot", "rule_ids", "bundle_hash", "signatures"]
    contents_ok = all(c in contents for c in required)
    checks.append({"name": "evidence_pack_contents", "status": "OK" if contents_ok else "FAIL",
                   "detail": f"zawartość pakietu: {contents} (wymagane: {required})"})

    checksum = isinstance(ep, dict) and ep.get("checksum_required", False)
    checks.append({"name": "export_checksum_required", "status": "OK" if checksum else "FAIL",
                   "detail": f"checksum eksportu obowiązkowa: {checksum}"})
    if not checksum:
        findings.append("P0: eksport bez checksumy — dowód podważalny.")

    cert = CERT_SERVICE.exists()
    checks.append({"name": "certificate_service_exists", "status": "OK" if cert else "FAIL",
                   "detail": f"tools/certificate_service.py (P11): {cert}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "evidence_pack_contents": contents_ok,
            "export_checksum_required": checksum,
            "certificate_service_exists": cert,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_evidence_pack")


if __name__ == "__main__":
    raise SystemExit(main())
