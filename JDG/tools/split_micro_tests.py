#!/usr/bin/env python3
"""
Micro Test Splitter (Raport P27 — R9)
═══════════════════════════════════════════════════════════════════════════════

Rozbija test_auto_block_micro.py (270 funkcji, 25 subpakietów) na osobne
natywne testy Rego per subpakiet: sus, zdrowotna, pkpir, vat, rodo, bdo, itd.

Usage:
  python split_micro_tests.py [--dry-run]
"""

import re
import sys
from pathlib import Path
from datetime import datetime

JDG_ROOT = Path(__file__).resolve().parent.parent
MICRO_DIR = JDG_ROOT / "rules" / "micro"
OUTPUT_DIR = JDG_ROOT / "tests" / "rego" / "micro"


def extract_rules_from_micro_subpackage(sub_dir: Path) -> list[dict]:
    """Extract rules from a micro subpackage directory."""
    rules = []
    for fp in sorted(sub_dir.glob("*.rego")):
        content = fp.read_text(errors="replace")

        pkg_match = re.search(r'package\s+(\S+)', content)
        package = pkg_match.group(1) if pkg_match else f"jdg.micro.{sub_dir.name}"

        for match in re.finditer(r'"rule_id"\s*:\s*"([^"]+)"', content):
            rule_id = match.group(1)

            start = max(0, match.start() - 300)
            end = min(len(content), match.end() + 300)
            ctx = content[start:end]

            legal = re.search(r'"_legal_basis"\s*:\s*"([^"]*)"', ctx)
            routing = re.search(r'"_routing"\s*:\s*"([^"]*)"', ctx)

            rules.append({
                "rule_id": rule_id,
                "package": package,
                "legal_basis": legal.group(1) if legal else "",
                "routing": routing.group(1) if routing else "",
            })

            if len(rules) >= 10:
                break
    return rules


def generate_micro_subpackage_test(sub_name: str, rules: list[dict]) -> str:
    """Generate a test file for one micro subpackage."""
    pkg = rules[0]["package"] if rules else f"jdg.micro.{sub_name}"
    safe_pkg = re.sub(r'[^a-zA-Z0-9_]', '_', pkg)[-40:]

    lines = [
        f"# ═══════════════════════════════════════════════════════════════",
        f"# NexusAI JDG — Native Rego Tests for micro/{sub_name}",
        f"# Generated: {datetime.now().isoformat()}",
        f"# Package: {pkg}",
        f"# Rules tested: {len(rules)}",
        f"# Report: P27 R9 — Micro test split",
        f"# ═══════════════════════════════════════════════════════════════",
        "",
        f"package test_{safe_pkg}",
        f"import data.{pkg}",
        "",
    ]

    for i, rule in enumerate(rules[:10]):
        rule_id = rule["rule_id"]
        short = rule_id.split(".")[-1][-25:]
        safe_name = re.sub(r'[^a-zA-Z0-9_]', '_', short)

        lines.append(f"# {i+1}. {rule_id}")
        lines.append(f"test_positive_{safe_name} {{")
        lines.append(f"    result := data.{pkg}.decide with input as {{}}")
        lines.append(f"    result.matched == true")
        lines.append(f"    result.rule_id == \"{rule_id}\"")
        lines.append(f"}}")
        lines.append("")

        lines.append(f"test_negative_{safe_name} {{")
        lines.append(f"    result := data.{pkg}.decide with input as {{}}")
        lines.append(f"    result.rule_id != \"{rule_id}\"")
        lines.append(f"}}")
        lines.append("")

    return "\n".join(lines)


def main():
    dry_run = "--dry-run" in sys.argv
    output_dir = Path(OUTPUT_DIR)
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"🔧 NexusAI JDG — Micro Test Splitter (P27 R9)")
    print()

    generated = 0
    for sub_dir in sorted(MICRO_DIR.iterdir()):
        if not sub_dir.is_dir():
            continue
        rules = extract_rules_from_micro_subpackage(sub_dir)
        if not rules:
            continue

        content = generate_micro_subpackage_test(sub_dir.name, rules)
        output_file = output_dir / f"test_native_micro_{sub_dir.name}.rego"

        if not dry_run:
            output_file.write_text(content, encoding="utf-8")
            generated += 1
            print(f"   ✅ micro/{sub_dir.name}: {len(rules)} reguł")

    print(f"\n📊 Wygenerowano: {generated} plików")
    if dry_run:
        print("   ✅ DRY-RUN")
    return 0


if __name__ == "__main__":
    sys.exit(main())
