#!/usr/bin/env python3
"""
NexusAI JDG — Dead Rule & Duplicate Rule Detector (Innowacja 13)
Wykrywa martwe i zduplikowane reguły w całym drzewie rules/.

Wykrywa:
  1. Globalne duplikaty rule_id (ten sam ID w różnych plikach)
  2. Reguły checkpoint (szkielety z generate_missing_rules)
  3. Potencjalnie martwe reguły (ten sam priorytet, nieosiągalne)
  4. Statystyki per pakiet/domena

Usage: python dead_rule_detector.py [--json] [--fix-skeletons]
  --fix-skeletons  Oznacza reguły checkpoint jako [SKELETON]
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"


def extract_all_rules():
    """Ekstrahuje wszystkie rule_id z metadanymi."""
    rules = []
    for fp in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = fp.read_text(encoding="utf-8")
        except: continue
        rel = str(fp.relative_to(RULES_DIR))

        # Znajdź wszystkie rule_id
        ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
        priorities = re.findall(r'"priority"\s*:\s*(\d+)', content)
        matched_true = re.findall(r'"matched"\s*:\s*true', content)

        for i, rid in enumerate(ids):
            # Licz tylko reguły z matched:true (pomiń fallbacki no_match)
            is_matched = i < len(matched_true)
            rules.append({
                "rule_id": rid,
                "file": rel,
                "priority": int(priorities[i]) if i < len(priorities) else 0,
                "matched_true": is_matched,
                "is_skeleton": "_check" in rid or "checkpoint" in rid.lower(),
            })

    return rules


def detect_duplicates(rules):
    """Wykrywa globalne duplikaty rule_id."""
    by_id = defaultdict(list)
    for r in rules:
        by_id[r["rule_id"]].append(r["file"])

    return {rid: files for rid, files in by_id.items() if len(files) > 1}


def detect_skeletons(rules):
    """Wykrywa reguły-szkielety (checkpoint rules)."""
    return [r for r in rules if r["is_skeleton"]]


def detect_dead_by_priority(rules):
    """Wykrywa potencjalnie martwe reguły (ten sam priorytet w pakiecie)."""
    by_pkg_prio = defaultdict(list)
    for r in rules:
        pkg = r["rule_id"].rsplit(".", 1)[0] if "." in r["rule_id"] else r["rule_id"]
        by_pkg_prio[(pkg, r["priority"])].append(r)

    return {k: v for k, v in by_pkg_prio.items() if len(v) > 1}


def main():
    json_out = "--json" in sys.argv

    print("🔍 Dead Rule & Duplicate Rule Detector (Innowacja 13)")
    rules = extract_all_rules()
    print(f"   Wszystkich wystąpień rule_id: {len(rules)}")

    # Duplikaty
    dupes = detect_duplicates(rules)
    print(f"   Zduplikowanych rule_id: {len(dupes)}")
    if dupes and not json_out:
        for rid, files in sorted(dupes.items(), key=lambda x: -len(x[1]))[:10]:
            print(f"     - {rid}: {len(files)}× ({', '.join(files[:3])})")
        if len(dupes) > 10:
            print(f"     ... i {len(dupes)-10} więcej")

    # Szkielety
    skeletons = detect_skeletons(rules)
    print(f"   Reguł szkieletowych (checkpoint): {len(skeletons)}")

    # Martwe (priority collisions)
    dead = detect_dead_by_priority(rules)
    print(f"   Potencjalnie martwych (priority collision): {len(dead)}")

    if json_out:
        output = {
            "timestamp": datetime.now().isoformat(),
            "total_rule_occurrences": len(rules),
            "duplicate_rule_ids": len(dupes),
            "duplicate_details": {rid: len(files) for rid, files in dupes.items()},
            "skeleton_rules": len(skeletons),
            "skeleton_details": [{"rule_id": s["rule_id"], "file": s["file"]} for s in skeletons[:50]],
            "dead_by_priority_collision": len(dead),
        }
        print(json.dumps(output, indent=2, ensure_ascii=False))

    return 0 if not dupes else 1


if __name__ == "__main__":
    sys.exit(main())
