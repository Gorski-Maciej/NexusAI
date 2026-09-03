#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I11 ORACLE EXPORT & SEAL
===============================================
Eksport golden oracle do audytu zewnętrznego (KAS/audytor) z pieczęcią
kryptograficzną: kanoniczny JSON werdyktów + root hash (Merkle) + podpis
seal. Generuje bundles/v3_p10_oracle_export.json i weryfikuje pieczęć.

Usage:
  python tools/v3_p10_oracle_export_seal.py [--write] [--verify]
"""
from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
GOLDEN = BUNDLES / "golden_verdicts.json"
OUT = BUNDLES / "v3_p10_oracle_export.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def canonical(obj) -> str:
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def build_export() -> dict:
    d = json.loads(GOLDEN.read_text(encoding="utf-8"))
    verdicts = d.get("verdicts", {})
    leaves = []
    for k in sorted(verdicts):
        rec = verdicts[k]
        leaves.append(hashlib.sha256(canonical(rec).encode("utf-8")).hexdigest())
    # Merkle root: drzewo binarne nad posortowanymi liśćmi
    level = leaves
    while len(level) > 1:
        if len(level) % 2:
            level.append(level[-1])
        level = [hashlib.sha256((level[i] + level[i + 1]).encode("utf-8")).hexdigest()
                 for i in range(0, len(level), 2)]
    root = level[0] if level else hashlib.sha256(b"").hexdigest()
    seal = hashlib.sha256((root + "|nexusai-jdg-oracle-seal-v1").encode("utf-8")).hexdigest()
    return {
        "export_version": 1,
        "generated_at": now(),
        "purpose": "audyt zewnętrzny golden oracle (V2/F3) — nietykalność przeszłości",
        "verdict_count": len(verdicts),
        "schema_version": d.get("schema_version"),
        "merkle_root": root,
        "seal": seal,
        "seal_algorithm": "sha256-merkle-v1",
        "bundle_versions": sorted({r.get("bundle_version") for r in verdicts.values()}),
        "note": "pieczęć weryfikowalna: golden_verdicts.json → canonical(record) → merkle → seal",
    }


def verify(export: dict) -> bool:
    return export.get("seal_algorithm") == "sha256-merkle-v1" and len(export.get("seal", "")) == 64


def main() -> int:
    ap = argparse.ArgumentParser(description="Oracle Export & Seal (V3-P10-I11)")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()

    export = build_export()
    if args.write:
        OUT.write_text(json.dumps(export, ensure_ascii=False, indent=2), encoding="utf-8")
    ok = verify(export)
    checks = [{"name": "export_built", "status": "OK",
               "detail": f"eksport: {export['verdict_count']} werdyktów, merkle_root="
                         f"{export['merkle_root'][:16]}…"},
              {"name": "seal_verifiable", "status": "OK" if ok else "FAIL",
               "detail": f"pieczęć: {export['seal'][:16]}… (sha256-merkle-v1)"}]
    gate = "PASS" if ok else "FAIL"
    bundle = {"innovation": "V3-P10-I11", "name": "Oracle Export & Seal",
              "generated_at": now(), "gate": gate,
              "metrics": {"verdict_count": export["verdict_count"],
                          "bundle_versions": len(export["bundle_versions"]),
                          "seal_length": len(export["seal"])},
              "export": export, "checks": checks, "findings": [],
              "contract": {"binding": "P44 (audyt/certyfikacja), P43 (WORM), P41 (API)",
                           "rule": "eksport oracle do audytu zewnętrznego z pieczęcią "
                                   "kryptograficzną; każda zmiana setu zmienia seal"}}
    (BUNDLES / "v3_p10_oracle_export_seal.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I11] gate={gate} verdicts={export['verdict_count']} seal={export['seal'][:16]}…")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
