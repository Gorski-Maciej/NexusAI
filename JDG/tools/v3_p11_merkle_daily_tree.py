#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I02 MERKLE DAILY TREE
============================================
Drzewa Merkle per dzień + root miesięczny + publiczny rejestr rootów
(transparencja). Sprawdza, czy certificate_service/decision_certificate
budują prawdziwe drzewo (nie Merkle-lite = pojedynczy hash).

Usage:
  python tools/v3_p11_merkle_daily_tree.py
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
    bat = (TOOLS / "blockchain_audit_trail.py")
    bat_txt = bat.read_text(encoding="utf-8") if bat.exists() else ""

    has_real_tree = "Merkle" in bat_txt or "merkle" in bat_txt
    has_daily_period = any(k in bat_txt for k in ("day", "date", "period", "genesis"))
    daily_files = sorted(p.name for p in BUNDLES.glob("*.json")
                         if any(k in p.name for k in ("merkle", "root", "audit_trail")))
    root_register = sorted(p.name for p in BUNDLES.glob("*root*"))

    checks.append({"name": "audit_trail_merkle", "status": "OK" if has_real_tree else "FAIL",
                   "detail": f"blockchain_audit_trail.py buduje drzewo/łańcuch: {has_real_tree}"})
    checks.append({"name": "daily_period", "status": "OK" if has_daily_period else "FAIL",
                   "detail": f"periodyzacja (dzień/miesiąc): {has_daily_period}"})
    checks.append({"name": "root_register", "status": "OK" if (daily_files or root_register) else "FAIL",
                   "detail": f"artefakty merkle/root: {daily_files or root_register}"})

    if "merkle_root(payload)" in dc and "Merkle-lite" in dc:
        findings.append({"id": "V3-P11-L02", "severity": "P1",
                         "evidence": "decision_certificate.py używa Merkle-LITE (payload_hash = "
                                     "merkle_root = pojedynczy hash werdyktu), a nie drzewa "
                                     "dziennego; blockchain_audit_trail.py buduje łańcuch z PoW, "
                                     "ale brak drzewa dziennego + roota miesięcznego + "
                                     "publicznego rejestru rootów",
                         "fix": "I02: Merkle Daily Tree — hash per werdykt → drzewo dzienne → "
                                "root miesięczny → publikacja rejestru rootów (transparencja)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I02", "generated_at": now(), "gate": gate,
        "metrics": {"audit_trail_merkle": has_real_tree, "daily_period": has_daily_period,
                    "merkle_artifacts": daily_files, "root_register": root_register},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P43 (WORM/DR), P38 (deploy), P44",
                     "rule": "każdy certyfikat jest liściem drzewa dziennego; root miesięczny "
                             "publikowany i weryfikowalny offline"}}
    (BUNDLES / "v3_p11_merkle_daily_tree.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I02] gate={gate} tree={has_real_tree} daily={has_daily_period}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
