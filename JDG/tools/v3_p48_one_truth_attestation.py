#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I12 ONE-TRUTH ATTESTATION — certyfikat decyzji zawiera
hash reguły użytej (nie tylko rule_id) — dowód, która wersja wyliczyła
(podanalizy AN03). Audyt: decision_certificate.py (F4 V2) + main_jdg.rego
(POST-MERGE) pod kątem pola rule_hash; brak = TRIAGE z planem naprawy.
"""
from __future__ import annotations

import hashlib

from v3_p48_common import BASE, read_json, rule_present, sha256, write_bundle, write_json

INNOVATION = "V3-P48-I12"
RULE = "jdg.v3_p48_mirror_sync.one_truth_attestation"
CERT_TOOL = BASE / "tools" / "decision_certificate.py"
MAIN_JDG = BASE / "rules" / "main_jdg.rego"
P48_REGO = BASE / "rules" / "v3_p48_mirror_sync.rego"


def main() -> int:
    checks, findings = [], []

    cert_src = CERT_TOOL.read_text(encoding="utf-8", errors="replace") if CERT_TOOL.exists() else ""
    main_src = MAIN_JDG.read_text(encoding="utf-8", errors="replace") if MAIN_JDG.exists() else ""

    has_hash_in_cert = "rule_hash" in cert_src or "rule_sha256" in cert_src
    has_hash_in_main = "rule_hash" in main_src
    certificates_total = 1 if main_src else 0  # kontrakt POST-MERGE = 1 ścieżka certyfikacji
    with_hash = 1 if (has_hash_in_cert or has_hash_in_main) else 0

    # Attestation P48: P48_REGO dostarcza rule_hash w swoim _certificate (wzorzec)
    p48_src = P48_REGO.read_text(encoding="utf-8", errors="replace")
    p48_hash_anchor = "rule_hash" in p48_src

    checks.append({
        "name": "certificate_rule_hash",
        "status": "OK" if with_hash == certificates_total else "TRIAGE",
        "detail": f"decision_certificate.py: rule_hash obecny: {has_hash_in_cert}; "
                  f"main_jdg POST-MERGE: rule_hash obecny: {has_hash_in_main}",
    })
    checks.append({
        "name": "p48_attestation_anchor",
        "status": "OK" if p48_hash_anchor else "TRIAGE",
        "detail": "P48 dostarcza wzorzec rule_hash (SHA-256 pliku rego) dla certyfikatu "
                  "— one-truth: dowód, która wersja wyliczyła",
    })
    checks.append({
        "name": "attestation_record",
        "status": "OK",
        "detail": "zapis bundles/v3_p48_attestation.json — hash canonical mirror_sync.rego "
                  "jako wzorzec dowodu wersji",
    })
    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if not with_hash:
        findings.append({"severity": "MEDIUM",
                         "message": "certyfikat F4 bez rule_hash — dodaj SHA-256 wersji reguły "
                                    "(TRIAGE wg reguły I12; V2 F4: dowód wersji)"})

    routing = "BLOCK_AND_ALERT" if False else ("TRIAGE_QUEUE" if with_hash < certificates_total else "AUTO_FILE")
    metrics = {
        "certificates_total": certificates_total,
        "certificates_with_rule_hash": with_hash,
        "p48_hash_anchor": p48_hash_anchor,
        "rule_hash_sample": sha256(P48_REGO) if P48_REGO.exists() else None,
        "routing": routing,
    }
    write_json(BASE / "bundles" / "v3_p48_attestation.json", {
        "generated_at": __import__("v3_p48_common").utcnow_iso(),
        "rule_hash_sample": sha256(P48_REGO) if P48_REGO.exists() else None,
        "note": "one-truth attestation: hash reguły użytej = dowód wersji (V2 F4)",
    })
    evidence = {"checks": checks, "findings": findings}
    write_bundle("one_truth_attestation", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} with_hash={with_hash}/{certificates_total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
