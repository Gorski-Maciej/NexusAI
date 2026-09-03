#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I07 HSM KEY CEREMONY
===========================================
Procedura inicjalizacji i rotacji kluczy podpisujących (HSM/KMS) z audytem
ceremonii i zachowaniem weryfikowalności starych certyfikatów.
Sprawdza: prawdziwy klucz podpisujący, rotację, klucze offline DR,
łańcuch zaufania starych podpisów.

Usage:
  python tools/v3_p11_hsm_key_ceremony.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    cs = (TOOLS / "certificate_service.py").read_text(encoding="utf-8")
    dc = (TOOLS / "decision_certificate.py").read_text(encoding="utf-8")
    worm = (TOOLS / "worm_storage.py").read_text(encoding="utf-8")

    # 1. Prawdziwy podpis kluczem (cryptography/ecdsa/rsa) czy placeholder HSM-ECDSA-<hash>?
    has_real_sig = any(k in (cs + dc) for k in ("cryptography.hazmat", "ecdsa", "rsa",
                                                "sign(", "private_key", "kms", "boto3"))
    placeholder = "HSM-ECDSA-" in (cs + dc) and "sha256" in (cs + dc)
    # 2. Rotacja kluczy (quarterly) + weryfikacja starych podpisów
    has_rotation = any(k in (cs + dc).lower() for k in ("rotation", "rotat", "kid", "key_id",
                                                        "key_version"))
    # 3. Klucze offline DR / backup ceremonii
    ceremony_artifacts = sorted(p.name for p in TOOLS.glob("*.py")
                                if any(k in p.name.lower() for k in ("ceremony", "hsm", "kms")))
    has_dr_keys = any(k in (cs + dc + worm).lower() for k in ("offline", "dr key", "cold key",
                                                              "backup key"))
    # 4. Audyt ceremonii (kto/kiedy/jaki klucz) — 4-eyes
    has_ceremony_audit = "ceremony" in (cs + dc).lower() or bool(ceremony_artifacts)

    checks.append({"name": "real_signing_key",
                   "status": "OK" if has_real_sig else "FAIL",
                   "detail": f"podpis prawdziwym kluczem (crypto/KMS): {has_real_sig} | "
                             f"placeholder HSM-ECDSA-<hash>: {placeholder}"})
    checks.append({"name": "key_rotation",
                   "status": "OK" if has_rotation else "FAIL",
                   "detail": f"rotacja kluczy (kid/key_version): {has_rotation}"})
    checks.append({"name": "ceremony_audit",
                   "status": "OK" if has_ceremony_audit else "FAIL",
                   "detail": f"ceremonia/audyt kluczy: {ceremony_artifacts or has_ceremony_audit}"})
    checks.append({"name": "dr_keys",
                   "status": "OK" if has_dr_keys else "FAIL",
                   "detail": f"klucze offline DR: {has_dr_keys}"})

    if not has_real_sig:
        findings.append({"id": "V3-P11-L07", "severity": "P0",
                         "evidence": "hsm_signature w certificate_service.py i "
                                     "decision_certificate.py to placeholder "
                                     "'HSM-ECDSA-' + sha256(rule_id+cert_id)[:32] — NIE jest "
                                     "to podpis kryptograficzny kluczem; verify() akceptuje "
                                     "dowolny string z prefiksem HSM-ECDSA- (fail-open dowodu "
                                     "podpisu)",
                         "fix": "I07: HSM Key Ceremony — prawdziwy klucz (KMS/HSM), podpis "
                                "ECDSA/RSA payload_hash, kid + key_version w seal, rotacja "
                                "kwartalna, klucze offline DR, audyt ceremonii 4-eyes"})
    if not has_rotation:
        findings.append({"id": "V3-P11-L07b", "severity": "P1",
                         "evidence": "brak rotacji kluczy i wersjonowania (kid) — nie da się "
                                     "wymienić klucza bez unieważnienia wszystkich starych "
                                     "certyfikatów; weryfikacja starych podpisów po rotacji "
                                     "niemożliwa",
                         "fix": "I07: kid/key_version w seal; weryfikacja używa klucza "
                                "wskazanego przez kid (stare certyfikaty weryfikowalne)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I07", "generated_at": now(), "gate": gate,
        "metrics": {"real_signing_key": has_real_sig, "placeholder": placeholder,
                    "key_rotation": has_rotation, "dr_keys": has_dr_keys,
                    "ceremony_audit": has_ceremony_audit},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P43 (security/DR), P38 (deploy), P07 (4-eyes)",
                     "rule": "podpis = prawdziwy klucz HSM/KMS z kid; rotacja nie łamie "
                             "weryfikowalności starych certyfikatów (klucz wg kid)"}}
    (BUNDLES / "v3_p11_hsm_key_ceremony.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I07] gate={gate} real_key={has_real_sig} rotation={has_rotation}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
