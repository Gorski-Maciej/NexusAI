#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — DRIFT DASHBOARD (GLM52 P19 — POLICIES MIRROR, V1 §1)
# Dashboard dryfu rules/ vs policies/ (mirror): hash SHA-256 bazowy vs mirror,
# różnice per pakiet, historia synchronizacji (.sync_manifest_v2.json).
# Cel V1 §1: POJEDYNCZE ŹRÓDŁO PRAWDY — rules/ = źródło, policies/ = mirror
# generowany (CI), dryf = 0. Dashboard pokazuje: status, liczby, per-pakiet.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
POLICIES_DIR = JDG_ROOT.parent / "policies"
SYNC_MANIFEST = POLICIES_DIR / ".sync_manifest_v2.json"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def scan() -> dict:
    """Tabela dryfu: pakiet × hash(rules) × hash(mirror) × status."""
    rows = []
    synced = missing = drifted = 0
    for p in sorted(RULES_DIR.rglob("*.rego")):
        rel = p.relative_to(RULES_DIR)
        mirror = POLICIES_DIR / rel
        h_rules = sha256(p)
        if not mirror.exists():
            missing += 1
            rows.append({"file": str(rel), "status": "MISSING_IN_MIRROR"})
            continue
        h_mirror = sha256(mirror)
        if h_rules == h_mirror:
            synced += 1
            rows.append({"file": str(rel), "status": "SYNCED",
                         "hash_rules": h_rules[:12], "hash_mirror": h_mirror[:12]})
        else:
            drifted += 1
            rows.append({"file": str(rel), "status": "DRIFTED",
                         "hash_rules": h_rules[:12], "hash_mirror": h_mirror[:12]})
    total = synced + missing + drifted
    drift_pct = round(drifted / total * 100, 2) if total else 0.0
    last_sync = None
    if SYNC_MANIFEST.exists():
        meta = json.loads(SYNC_MANIFEST.read_text(encoding="utf-8"))
        last_sync = meta.get("last_sync")
    return {
        "total": total, "synced": synced, "missing": missing,
        "drifted": drifted, "drift_pct": drift_pct,
        "gate": "PASS" if drifted == 0 and missing == 0 else "FAIL",
        "last_sync": last_sync,
        "rows": rows,
    }


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Drift Dashboard (P19)")
    sub = p.add_subparsers(dest="cmd", required=True)
    d = sub.add_parser("scan"); d.set_defaults(fn=lambda a: print(json.dumps(scan(), ensure_ascii=False, indent=1)))
    g = sub.add_parser("gate"); g.set_defaults(fn=lambda a: print(json.dumps(scan(), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
