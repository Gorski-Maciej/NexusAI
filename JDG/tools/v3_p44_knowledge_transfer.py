#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I08 KNOWLEDGE TRANSFER PACK — pakiet przekazania
(dokumenty, runbooki, rejestry, kontakty decyzyjne) — forteca operowalna przez
innych niż twórcy. Brakujący artefakt = TRIAGE. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p44_common import BASE, CERT_REGISTER, RUNBOOKS, emit, now, read_json, rule_present

INNOVATION = "V3-P44-I08"
RULE = "jdg.v3_p44_certyfikacja_finalna.knowledge_transfer_pack"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    pack = reg.get("knowledge_transfer_pack", {}) if isinstance(reg, dict) else {}
    artifacts = pack.get("required_artifacts", {}) if isinstance(pack, dict) else {}
    missing = [a for a, ok in artifacts.items() if ok is not True]
    declared = [a for a, ok in artifacts.items() if ok is True and (BASE / a).exists()]
    checks.append({"name": "artifacts_present", "status": "OK" if artifacts and not missing and len(declared) == len(artifacts) else "FAIL",
                   "detail": f"artefakty obecne fizycznie: {len(declared)}/{len(artifacts)}; deklarowane-brakujące: {missing or 'brak'}"})

    runbooks_ok = RUNBOOKS.exists() and any(RUNBOOKS.iterdir()) if RUNBOOKS.exists() else False
    checks.append({"name": "runbooks_operable", "status": "OK" if runbooks_ok else "FAIL",
                   "detail": f"docs/runbooks: {runbooks_ok} (P37 RB01–RB06)"})

    contacts = pack.get("decision_contacts", [])
    checks.append({"name": "decision_contacts", "status": "OK" if contacts else "FAIL",
                   "detail": f"kontakty decyzyjne: {len(contacts)}"})

    if missing:
        findings.append({"severity": "HIGH", "message": f"brakujące artefakty przekazania: {missing}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "artifacts_total": len(artifacts),
            "artifacts_missing": len(missing),
            "contacts": len(contacts),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_knowledge_transfer")


if __name__ == "__main__":
    raise SystemExit(main())
