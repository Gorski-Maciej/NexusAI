#!/usr/bin/env python3
"""
NexusAI JDG — MIRROR DELTA DETECTOR (P00-I05)
==============================================
Automatyczny raport różnic między canonical (JDG/rules) a mirror
(policies/) z klasyfikacją: strukturalny (plik w jednym, nie w drugim),
treściowy (ten sam plik, inny hash), wersjonujący (rule_id w jednym, nie
w drugim). Wejście dla P48 (MIRROR_SYNC) i bramka CI.

Usage:
  python v3_mirror_delta.py                # raport dryfu (bramka)
  python v3_mirror_delta.py --json
  python v3_mirror_delta.py --write
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
JDG_ROOT = Path(__file__).resolve().parents[1]
CANONICAL = JDG_ROOT / "rules"
MIRROR = REPO_ROOT / "policies"
OUT_JSON = JDG_ROOT / "bundles" / "v3_mirror_delta.json"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rule_ids(path: Path) -> set[str]:
    try:
        return set(RULE_ID_RE.findall(path.read_text(encoding="utf-8", errors="replace")))
    except Exception:
        return set()


def files_by_name(root: Path) -> dict[str, Path]:
    out: dict[str, Path] = {}
    if not root.exists():
        return out
    for p in root.rglob("*.rego"):
        if "__pycache__" in p.parts:
            continue
        out[p.name] = p
    return out


def build() -> dict:
    canon = files_by_name(CANONICAL)
    mirror = files_by_name(MIRROR)
    canon_names = set(canon)
    mirror_names = set(mirror)

    only_canon = sorted(canon_names - mirror_names)
    only_mirror = sorted(mirror_names - canon_names)
    common = sorted(canon_names & mirror_names)

    content_diff = []
    for name in common:
        c_hash = sha256(canon[name])
        m_hash = sha256(mirror[name])
        if c_hash != m_hash:
            content_diff.append({
                "file": name,
                "canonical_sha256": c_hash,
                "mirror_sha256": m_hash,
                "canonical_rule_ids": sorted(rule_ids(canon[name])),
                "mirror_rule_ids": sorted(rule_ids(mirror[name])),
            })

    canon_ids = set()
    mirror_ids = set()
    for p in canon.values():
        canon_ids |= rule_ids(p)
    for p in mirror.values():
        mirror_ids |= rule_ids(p)

    ids_only_canon = sorted(canon_ids - mirror_ids)
    ids_only_mirror = sorted(mirror_ids - canon_ids)

    return {
        "schema_version": "1.0.0",
        "report": "V3_MIRROR_DELTA",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "counts": {
            "canonical_rego": len(canon),
            "mirror_rego": len(mirror),
            "files_only_canonical": len(only_canon),
            "files_only_mirror": len(only_mirror),
            "files_content_diff": len(content_diff),
            "rule_ids_only_canonical": len(ids_only_canon),
            "rule_ids_only_mirror": len(ids_only_mirror),
        },
        "files_only_canonical": only_canon,
        "files_only_mirror": only_mirror,
        "content_diffs": content_diff,
        "rule_ids_only_canonical_sample": ids_only_canon[:200],
        "rule_ids_only_mirror_sample": ids_only_mirror[:200],
        "drift_classification": {
            "structural": only_canon + only_mirror,
            "content": [d["file"] for d in content_diff],
            "versioning": ids_only_canon + ids_only_mirror,
        },
        "status": "DRYF_MIRROR" if (only_canon or only_mirror or content_diff) else "ZSYNCHRONIZOWANE",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 Mirror Delta Detector")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    data = build()
    if args.write:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        c = data["counts"]
        print(f"V3 MIRROR DELTA: {data['status']}")
        print(f"  canonical JDG/rules: {c['canonical_rego']} plików | mirror policies/: {c['mirror_rego']} plików")
        print(f"  tylko canonical: {c['files_only_canonical']} | tylko mirror: {c['files_only_mirror']} | różnice treści: {c['files_content_diff']}")
        print(f"  rule_id tylko canonical: {c['rule_ids_only_canonical']} | tylko mirror: {c['rule_ids_only_mirror']}")
        if data["files_only_canonical"][:10]:
            print("  przykłady tylko canonical:", ", ".join(data["files_only_canonical"][:10]))
        if data["files_only_mirror"][:10]:
            print("  przykłady tylko mirror:", ", ".join(data["files_only_mirror"][:10]))
    return 1 if data["status"] == "DRYF_MIRROR" else 0


if __name__ == "__main__":
    sys.exit(main())