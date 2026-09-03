#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I05 REVOCATION MANIFEST
===============================================
Podpisany manifest unieważnień rozpowszechniany z certyfikatami
(odpowiednik CRL dla certyfikatów decyzyjnych). Sprawdza, czy istnieje
rejestr unieważnień + zasada kto może unieważnić (4-eyes) + powiązanie
z certyfikatami korekt (I04).

Usage:
  python tools/v3_p11_revocation_manifest.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
DOCS = BASE / "docs"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    keywords = ("revok", "unieważn", "crl", "manifest")
    # Skanujemy TYLKO istniejące narzędzia certyfikatów (nie własne pliki v3_p11_*)
    base_cert = [p for p in TOOLS.glob("*.py")
                 if any(k in p.name for k in ("decision_certificate", "certificate_service",
                                              "worm_storage", "blockchain_audit_trail"))]
    hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore") for p in base_cert)
    has_revocation = any(k in hay.lower() for k in keywords)
    revocation_artifacts = sorted(p.name for p in BUNDLES.glob("*.json")
                                  if ("revok" in p.name.lower()
                                      or ("manifest" in p.name.lower()
                                          and any(k in p.name.lower() for k in ("cert", "decision", "revok", "audit")))))
    # Tylko realne manifesty (nie inventory_manifest / overlay manifests)
    revocation_artifacts = [a for a in revocation_artifacts
                            if any(k in a for k in ("revok", "cert", "decision"))]
    # Kto może unieważnić — 4-eyes / uprawnienia (P07/P09)
    has_authorization = any(k in hay.lower() for k in ("4-eyes", "four_eyes", "authorized",
                                                       "uprawnieni", "roles"))
    # Manifest podpisany (seal) — czy w ogóle istnieje mechanizm
    doc_mentions = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                             for p in DOCS.glob("V3_P11*.md"))

    checks.append({"name": "revocation_mechanism",
                   "status": "OK" if has_revocation else "FAIL",
                   "detail": f"mechanizm unieważnień w narzędziach certyfikatów: {has_revocation}"})
    checks.append({"name": "revocation_manifest_artifact",
                   "status": "OK" if revocation_artifacts else "FAIL",
                   "detail": f"artefakt manifestu unieważnień: {revocation_artifacts or 'BRAK'}"})
    checks.append({"name": "authorization_4eyes",
                   "status": "OK" if has_authorization else "FAIL",
                   "detail": f"kontrola uprawnień/4-eyes przy unieważnieniu: {has_authorization}"})

    if not has_revocation or not revocation_artifacts:
        findings.append({"id": "V3-P11-L05", "severity": "P1",
                         "evidence": "brak manifestu unieważnień (CRL decyzyjny): żadne "
                                     "narzędzie certyfikatów nie implementuje revoke/CRL; "
                                     "brak artefaktu manifestu i zasady kto może unieważnić "
                                     "(4-eyes, uprawnienia)",
                         "fix": "I05: Revocation Manifest — podpisany rejestr unieważnionych "
                                "certyfikatów (id, powód, data, podpis), rozpowszechniany "
                                "z certyfikatami; unieważnienie wymaga 4-eyes"})
    if not has_authorization:
        findings.append({"id": "V3-P11-L05b", "severity": "P2",
                         "evidence": "brak jawnej kontroli uprawnień przy unieważnianiu "
                                     "certyfikatów — ryzyko nieautoryzowanego unieważnienia",
                         "fix": "I05: role i 4-eyes dla operacji revoke (P07/P09)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I05", "generated_at": now(), "gate": gate,
        "metrics": {"revocation_mechanism": has_revocation,
                    "revocation_artifacts": revocation_artifacts,
                    "authorization_4eyes": has_authorization},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P36 (procesy), P44, P07 (4-eyes)",
                     "rule": "unieważnienie = wpis w podpisanym manifeście; weryfikacja "
                             "offline sprawdza certyfikat przeciw manifestowi"}}
    (BUNDLES / "v3_p11_revocation_manifest.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I05] gate={gate} revocation={has_revocation} manifest={revocation_artifacts or 'BRAK'}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
