#!/usr/bin/env python3
"""
P24 R1: Micro ↔ Plan33 Deduplication Checker (CI Tool)
Detects redundant/conflicting rules between micro and plan33 layers.
Based on: P24 Report Section 10.4 R1 — Redundancja micro ↔ plan33

Usage: python dedup_micro_plan33.py [--fix] [--ci] [--json]
"""
import re
import os
import sys
import json
from pathlib import Path
from datetime import datetime

# Pairs of micro ↔ plan33 files to check for redundancy
REDUNDANCY_PAIRS = [
    ("JDG/rules/micro/ryczalt/ryczalt.rego", "JDG/rules/micro/plan33_ryc.rego"),
    ("JDG/rules/micro/sukcesja/sukcesja.rego", "JDG/rules/micro/plan33_succ.rego"),
    ("JDG/rules/micro/ceidg/ceidg.rego", "JDG/rules/micro/plan33_ceidg.rego"),
]


def extract_rules(filepath: str) -> list[dict]:
    """Extract rule_id, priority, and key fields from a Rego file."""
    rules = []
    if not os.path.exists(filepath):
        return rules

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Find all rule blocks
    blocks = re.split(r'\n(?:else\s*:=|decide\s*:=)', content)
    for block in blocks:
        rule_match = re.search(r'"rule_id":\s*"([^"]+)"', block)
        priority_match = re.search(r'"priority":\s*(\d+)', block)
        routing_match = re.search(r'"_routing_reason":\s*"([^"]*)"', block)
        legal_match = re.search(r'"_legal_basis":\s*"([^"]*)"', block)
        pit_form_match = re.search(r'"pit_form":\s*"([^"]*)"', block)
        pit_rate_match = re.search(r'"pit_rate":\s*"([^"]*)"', block)
        vat_rate_match = re.search(r'"vat_rate":\s*"([^"]*)"', block)

        if rule_match:
            rules.append({
                "rule_id": rule_match.group(1),
                "priority": int(priority_match.group(1)) if priority_match else 0,
                "routing_reason": routing_match.group(1) if routing_match else "",
                "legal_basis": legal_match.group(1) if legal_match else "",
                "pit_form": pit_form_match.group(1) if pit_form_match else "",
                "pit_rate": pit_rate_match.group(1) if pit_rate_match else "",
                "vat_rate": vat_rate_match.group(1) if vat_rate_match else "",
            })
    return rules


def normalize_rule(rule: dict) -> str:
    """Create a normalized fingerprint for comparison."""
    key_fields = [
        rule.get("pit_form", ""),
        rule.get("pit_rate", ""),
        rule.get("vat_rate", ""),
        rule.get("legal_basis", "")[:80],
    ]
    return "|".join(key_fields)


def check_redundancy(micro_file: str, plan33_file: str) -> dict:
    """Check redundancy between a micro file and its plan33 counterpart."""
    result = {
        "micro_file": micro_file,
        "plan33_file": plan33_file,
        "micro_rules": 0,
        "plan33_rules": 0,
        "exact_duplicates": [],
        "near_duplicates": [],
        "conflicting": [],
        "unique_micro": 0,
        "unique_plan33": 0,
        "redundancy_pct": 0.0,
        "status": "PASS"
    }

    micro_rules = extract_rules(micro_file)
    plan33_rules = extract_rules(plan33_file)

    result["micro_rules"] = len(micro_rules)
    result["plan33_rules"] = len(plan33_rules)

    if not micro_rules or not plan33_rules:
        result["status"] = "SKIP"
        return result

    # Normalize fingerprints
    micro_fingerprints = {normalize_rule(r): r for r in micro_rules}
    plan33_fingerprints = {normalize_rule(r): r for r in plan33_rules}

    for fp, micro_rule in micro_fingerprints.items():
        if fp in plan33_fingerprints:
            plan33_rule = plan33_fingerprints[fp]
            result["exact_duplicates"].append({
                "micro_rule_id": micro_rule["rule_id"],
                "plan33_rule_id": plan33_rule["rule_id"],
                "fingerprint": fp[:80]
            })

    # Near duplicates (same legal_basis but different rates)
    for fp_m, mr in micro_fingerprints.items():
        for fp_p, pr in plan33_fingerprints.items():
            if fp_m != fp_p:
                # Check for near-duplicate: same legal basis
                if mr["legal_basis"] == pr["legal_basis"] and mr["legal_basis"]:
                    # Different rates = potential conflict
                    if mr.get("pit_rate") != pr.get("pit_rate") and mr.get("pit_rate") and pr.get("pit_rate"):
                        result["conflicting"].append({
                            "micro_rule_id": mr["rule_id"],
                            "micro_rate": mr["pit_rate"],
                            "plan33_rule_id": pr["rule_id"],
                            "plan33_rate": pr["pit_rate"],
                            "legal_basis": mr["legal_basis"][:80]
                        })

    # Calculate redundancy
    total_unique = len(set(list(micro_fingerprints.keys()) + list(plan33_fingerprints.keys())))
    if total_unique > 0:
        dup_count = len(result["exact_duplicates"])
        result["redundancy_pct"] = round(dup_count / len(micro_fingerprints) * 100, 1)

    result["unique_micro"] = len(micro_fingerprints) - dup_count
    result["unique_plan33"] = len(plan33_fingerprints) - dup_count

    if result["redundancy_pct"] > 20:
        result["status"] = "FAIL"
    elif result["redundancy_pct"] > 10:
        result["status"] = "WARN"
    elif len(result["conflicting"]) > 0:
        result["status"] = "WARN"

    return result


def print_report(results: list[dict]) -> int:
    """Print deduplication report."""
    print("=" * 70)
    print("P24 R1: Micro ↔ Plan33 Deduplication Checker")
    print("=" * 70)
    print(f"Timestamp: {datetime.now().isoformat()}")
    print(f"Pairs checked: {len(results)}")
    print()

    total_dup = 0
    total_conflicts = 0
    fails = 0

    for r in results:
        icon = "✅" if r["status"] == "PASS" else "⚠️" if r["status"] == "WARN" else "❌"
        print(f"  {icon} {os.path.basename(r['micro_file'])} ↔ {os.path.basename(r['plan33_file'])}")
        print(f"     Micro: {r['micro_rules']} rules, Plan33: {r['plan33_rules']} rules")
        print(f"     Duplicates: {len(r['exact_duplicates'])} ({r['redundancy_pct']}%)")
        print(f"     Conflicts: {len(r['conflicting'])}")

        if r["exact_duplicates"]:
            for d in r["exact_duplicates"][:3]:
                print(f"       DUP: {d['micro_rule_id']} = {d['plan33_rule_id']}")
            if len(r["exact_duplicates"]) > 3:
                print(f"       ... and {len(r['exact_duplicates']) - 3} more")

        if r["conflicting"]:
            for c in r["conflicting"][:3]:
                print(f"       CONFLICT: {c['micro_rule_id']} (rate={c['micro_rate']}) ≠ {c['plan33_rule_id']} (rate={c['plan33_rate']})")
            if len(r["conflicting"]) > 3:
                print(f"       ... and {len(r['conflicting']) - 3} more")

        total_dup += len(r["exact_duplicates"])
        total_conflicts += len(r["conflicting"])
        if r["status"] == "FAIL":
            fails += 1

    print()
    print(f"TOTAL: {total_dup} duplicates, {total_conflicts} conflicts, {fails} FAIL pairs")
    print(f"CI PASS: {'YES ✅' if fails == 0 else 'NO ❌'}")
    print("=" * 70)
    print()
    print("Rekomendacja (P24 Section 10.4 R1):")
    print("  Golden source = micro + plan33 po deduplikacji w CI.")
    print("  Duplikaty > 20%: usuń z plan33, zachowaj w micro.")
    print("  Konflikty: micro ma priorytet (warstwa operacyjna plan44/45).")
    print("=" * 70)

    return 0 if fails == 0 else 1


def main():
    import argparse
    parser = argparse.ArgumentParser(description="P24 Micro ↔ Plan33 Deduplication Checker")
    parser.add_argument("--ci", action="store_true", help="CI mode")
    parser.add_argument("--json", action="store_true", help="JSON output")
    parser.add_argument("--fix", action="store_true", help="Auto-fix (not yet implemented)")
    args = parser.parse_args()

    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    
    results = []
    for micro_file, plan33_file in REDUNDANCY_PAIRS:
        micro_path = os.path.join(project_root, micro_file)
        plan33_path = os.path.join(project_root, plan33_file)
        result = check_redundancy(micro_path, plan33_path)
        results.append(result)

    if args.json:
        print(json.dumps(results, indent=2, ensure_ascii=False))
    else:
        print_report(results)

    # Check for failures
    fails = sum(1 for r in results if r["status"] == "FAIL")
    if args.ci and fails > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
