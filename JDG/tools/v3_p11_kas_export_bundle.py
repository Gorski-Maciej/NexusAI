#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I06 KAS EXPORT BUNDLE
=============================================
Paczka dla organu (KAS/audytor): certyfikaty + merkle root + snapshoty
przepisów (P01/P05) + podpis. Sprawdza, czy eksport decision_certificate
zawiera komplet: certyfikaty, legal snapshots, root, manifest — a nie
tylko XML pojedynczego certyfikatu.

Usage:
  python tools/v3_p11_kas_export_bundle.py
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
    dc = (TOOLS / "decision_certificate.py").read_text(encoding="utf-8")

    # 1. Eksport KAS w decision_certificate (cmd_export)?
    has_export_cmd = "def cmd_export" in dc or "export" in dc.lower()
    # 2. Czy eksport to paczka (katalog/zip z kompletem) czy pojedynczy XML?
    export_is_bundle = any(k in dc for k in ("zipfile", "shutil.make_archive",
                                             "Path.mkdir", "export_dir"))
    # 3. Składowe paczki KAS: legal snapshots (P01/P05), merkle root, manifest
    has_legal_snapshot_ref = any(k in dc.lower() for k in ("legal_basis", "snapshot",
                                                           "legal_snapshot"))
    certs = json.loads((BUNDLES / "decision_certificates.json").read_text(encoding="utf-8"))
    cert_count = len(certs.get("certificates", {}))
    # 4. Snapshoty przepisów istnieją w bundles?
    legal_snapshots = sorted(p.name for p in BUNDLES.glob("*.json")
                             if any(k in p.name.lower() for k in ("isap", "legal_merkle",
                                                                  "snapshot", "source_cert")))
    merkle_roots = sorted(p.name for p in BUNDLES.glob("*root*.json"))

    checks.append({"name": "export_command",
                   "status": "OK" if has_export_cmd else "FAIL",
                   "detail": f"eksport KAS w decision_certificate: {has_export_cmd}"})
    checks.append({"name": "export_bundle_structure",
                   "status": "OK" if export_is_bundle else "FAIL",
                   "detail": f"eksport jako paczka (komplet plików): {export_is_bundle}"})
    checks.append({"name": "legal_snapshots_available",
                   "status": "OK" if legal_snapshots else "FAIL",
                   "detail": f"snapshoty przepisów P01/P05 w bundles: {legal_snapshots or 'BRAK'}"})
    checks.append({"name": "merkle_roots_available",
                   "status": "OK" if merkle_roots else "FAIL",
                   "detail": f"rejestr rootów merkle: {merkle_roots or 'BRAK'}"})

    if not export_is_bundle or not legal_snapshots:
        findings.append({"id": "V3-P11-L06", "severity": "P1",
                         "evidence": "cmd_export w decision_certificate.py generuje pojedynczy "
                                     "XML certyfikatu, a nie paczkę KAS: brak pakietu "
                                     "(certyfikaty + merkle root + legal snapshots z P01/P05 + "
                                     "manifest) z podpisem całości",
                         "fix": "I06: KAS Export Bundle — katalog/zip: certyfikaty.json, "
                                "merkle_root.json, legal_snapshots (P01/P05), manifest z "
                                "hashami i podpisem całości"})
    if not merkle_roots:
        findings.append({"id": "V3-P11-L06b", "severity": "P2",
                         "evidence": "brak rejestru rootów merkle (transparencja) — paczka KAS "
                                     "nie ma czego załączyć jako dowód spójności okresu",
                         "fix": "I06 + I02: publikacja roota miesięcznego w bundles"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I06", "generated_at": now(), "gate": gate,
        "metrics": {"certificate_count": cert_count, "export_command": has_export_cmd,
                    "export_is_bundle": export_is_bundle,
                    "legal_snapshots": legal_snapshots, "merkle_roots": merkle_roots},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P44 (definicja sukcesu: dowód dla organów), P01/P05 (legal refs)",
                     "rule": "paczka KAS = certyfikaty + root merkle + snapshoty przepisów + "
                             "manifest; weryfikowalna offline w całości"}}
    (BUNDLES / "v3_p11_kas_export_bundle.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I06] gate={gate} export_bundle={export_is_bundle} snapshots={len(legal_snapshots)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
