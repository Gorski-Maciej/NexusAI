#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I12 CERTIFICATE GOLDEN LINK
==================================================
Decyzje golden setu mają certyfikaty — dowód spójności oracle (P10).
Sprawdza, czy każdy werdykt golden_verdicts.json (P10) ma odpowiadający
certyfikat w decision_certificates.json (P11) i czy hash treści jest
spójny (link dowodowy oracle→certyfikat).

Usage:
  python tools/v3_p11_golden_link.py
"""
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def canonical(obj) -> str:
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def main() -> int:
    checks, findings = [], []
    golden_file = BUNDLES / "golden_verdicts.json"
    cert_file = BUNDLES / "decision_certificates.json"

    golden = {}
    if golden_file.exists():
        golden = json.loads(golden_file.read_text(encoding="utf-8")).get("verdicts", {})
    certs = {}
    if cert_file.exists():
        certs = json.loads(cert_file.read_text(encoding="utf-8")).get("certificates", {})

    # Czy certyfikaty odwołują się do golden verdicts?
    golden_keys = set(golden.keys())
    cert_payload_hashes = {c.get("seal", {}).get("payload_hash", "")
                           for c in certs.values()}
    golden_hashes = set()
    for gk, gv in golden.items():
        vh = gv.get("verdict_hash")
        if vh:
            golden_hashes.add(vh)
        else:
            golden_hashes.add(hashlib.sha256(
                canonical(gv.get("verdict", gv)).encode("utf-8")).hexdigest())

    overlap = cert_payload_hashes & golden_hashes
    # Czy certyfikaty mają pole golden_verdict_id / pochodzą z oracle?
    has_oracle_ref = any("golden" in c or "oracle" in json.dumps(c, ensure_ascii=False)
                         for c in certs.values())

    coverage = len(overlap) / len(golden) if golden else 0.0
    checks.append({"name": "golden_link",
                   "status": "OK" if coverage >= 1.0 else "FAIL",
                   "detail": f"werdykty golden z certyfikatem (hash spójny): {len(overlap)}/"
                             f"{len(golden)} ({coverage:.0%})"})
    checks.append({"name": "oracle_reference",
                   "status": "OK" if has_oracle_ref else "FAIL",
                   "detail": f"certyfikat odwołuje się do golden/oracle: {has_oracle_ref}"})

    if coverage < 1.0:
        findings.append({"id": "V3-P11-L12", "severity": "P1",
                         "evidence": f"tylko {len(certs)} certyfikat(ów) w "
                                     f"decision_certificates.json wobec {len(golden)} werdyktów "
                                     f"golden (P10); brak łańcucha dowodowego "
                                     f"golden_verdict → certyfikat (hash/verdict_id) — decyzje "
                                     f"golden setu nie mają swoich certyfikatów",
                         "fix": "I12: Certificate Golden Link — każdy werdykt golden ma "
                                "certyfikat z golden_verdict_id + verdict_hash w decision; "
                                "bramka spójności oracle↔certyfikat w CI"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I12", "generated_at": now(), "gate": gate,
        "metrics": {"golden_verdicts": len(golden), "certificates": len(certs),
                    "golden_linked": len(overlap), "coverage": coverage,
                    "oracle_reference": has_oracle_ref},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P10 (golden oracle), P44, P03 (werdykt)",
                     "rule": "decyzja na golden secie MA certyfikat; spójność hash werdyktu "
                             "weryfikowana w CI (zero cichych rozjazdów)"}}
    (BUNDLES / "v3_p11_golden_link.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I12] gate={gate} golden={len(golden)} certs={len(certs)} linked={len(overlap)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
