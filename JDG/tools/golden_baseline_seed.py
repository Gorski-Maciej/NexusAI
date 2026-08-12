#!/usr/bin/env python3
"""
NexusAI JDG — P20/P00 GOLDEN BASELINE SEED (P0-10 RAPORT_00)
============================================================
Buduje pierwszy bazowy snapshot złotych werdyktów (golden_verdicts.json)
w formacie schema_version=2, zgodnym z contracts golden_replay.py.

Dane pochodzą z RZECZYWISTYCH bloków reguł (decide chains) — jeden
reprezentatywny werdykt na każdą główną domenę. Replay rows porównują
werdykty z samymi sobą → changed=false, uver_applies=false.

Usage:
  python golden_baseline_seed.py [--bundle VERSION]
"""

import argparse
import hashlib
import json
import re
import sys
from collections import OrderedDict
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
OUT_PATH = JDG_ROOT / "bundles" / "golden_verdicts.json"
SCHEMA_VERSION = 2

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')

# Reprezentatywne reguły per domena (pierwsza kanoniczna reguła z verdict dict)
SEED_RULES = [
    ("jdg.vat.a5.r1", "rules/micro/plan34_vat.rego"),
    ("jdg.vat.a41.r1", "rules/micro/plan34_vat.rego"),
    ("jdg.vat.a113.r1", "rules/p00_legal_coverage_closure.rego"),
    ("jdg.pit.a27.r1", "rules/micro/plan34_pit.rego"),
    ("jdg.pit.a30c.r1", "rules/p00_legal_coverage_closure.rego"),
    ("jdg.ord.a70.r1", "rules/micro/plan34_ord.rego"),
    ("jdg.ord.a117ba.r1", "rules/p00_legal_coverage_closure.rego"),
    ("jdg.kks.voluntary_disclosure_art16", "rules/kks.rego"),
    ("jdg.ksef_jpk.ksef_mandatory", "rules/ksef_jpk.rego"),
    ("jdg.crossborder.cfc_jdg_controlled", "rules/crossborder/exit_tax_cfc_complete.rego"),
]


def canonical_verdict_hash(v) -> str:
    canonical = json.dumps(v, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def extract_verdict_for(rule_id: str, file_path: str) -> dict | None:
    path = JDG_ROOT / file_path
    if not path.exists():
        return None
    content = path.read_text(encoding="utf-8", errors="ignore")
    for m in RULE_ID_RE.finditer(content):
        if m.group(1) == rule_id:
            ctx = content[m.start():m.start() + 4000]
            # Znajdź otwierający dict { po rule_id (lub przed)
            block_start = ctx.find(":= {")
            if block_start < 0:
                continue
            dict_start = ctx.find("{", block_start)
            # Znajdź zamykający dict } — licz nawiasy
            depth = 0
            end = dict_start
            for i in range(dict_start, len(ctx)):
                if ctx[i] == "{":
                    depth += 1
                elif ctx[i] == "}":
                    depth -= 1
                    if depth == 0:
                        end = i + 1
                        break
            try:
                verdict = json.loads(ctx[dict_start:end])
                return verdict
            except (json.JSONDecodeError, IndexError):
                continue
    return None


def main() -> None:
    p = argparse.ArgumentParser(description="Golden Baseline Seed — P0-10 RAPORT_00")
    p.add_argument("--bundle", default=f"jdg-bundle-p00-baseline-{datetime.now(timezone.utc).strftime('%Y-%m-%d')}")
    args = p.parse_args()

    verdicts = {}
    found = []
    missing = []
    for rule_id, file_path in SEED_RULES:
        verdict = extract_verdict_for(rule_id, file_path)
        if verdict is None:
            missing.append(rule_id)
            continue
        input_hash = hashlib.sha256(rule_id.encode("utf-8")).hexdigest()[:32]
        v_hash = canonical_verdict_hash(verdict)
        verdicts[input_hash] = {
            "verdict": verdict,
            "verdict_hash": v_hash,
            "hash_algorithm": "sha256-canonical-json-v1",
            "bundle_version": args.bundle,
            "recorded_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        }
        found.append(rule_id)

    if missing:
        print(f"⚠️  Missing rules (skipped): {', '.join(missing)}")

    # Replay rows: every golden verdict compared against itself (no change)
    replays = []
    for input_hash, entry in verdicts.items():
        v_hash = entry["verdict_hash"]
        replays.append({
            "input_hash": input_hash,
            "golden_verdict_hash": v_hash,
            "new_verdict": entry["verdict"],
            "new_verdict_hash": v_hash,
            "hash_algorithm": "sha256-canonical-json-v1",
            "changed": False,
            "explained": False,
            "reason": None,
            "uver_applies": False,
            "replayed_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        })

    data = {
        "schema_version": SCHEMA_VERSION,
        "verdicts": verdicts,
        "annotations": [],
        "replays": replays,
    }
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"🥇 Golden Baseline: {len(verdicts)} verdicts, {len(replays)} replays")
    print(f"   Bundle: {args.bundle}")
    print(f"   Saved: {OUT_PATH.relative_to(JDG_ROOT)}")
    if not missing:
        print("   ✅ All rules found — no missing verdicts")


if __name__ == "__main__":
    main()
