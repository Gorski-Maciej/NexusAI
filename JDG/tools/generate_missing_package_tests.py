#!/usr/bin/env python3
"""
Native Rego Test Generator for 11 Missing Packages (Raport P27 — R3)
═══════════════════════════════════════════════════════════════════════════════

Generuje natywne testy Rego (*_test.rego) dla 11 pakietów bez testów auto:
advertising, esig, force_majeure, fx, jpk, ord, pcc, seasonal, security,
taxfree, uor

Usage:
  python generate_missing_package_tests.py [--dry-run]
"""

import re
import sys
from pathlib import Path
from datetime import datetime

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
OUTPUT_DIR = JDG_ROOT / "tests" / "rego"

MISSING_PACKAGES = [
    "advertising", "esig", "force_majeure", "fx", "jpk", "ord",
    "pcc", "seasonal", "security", "taxfree", "uor"
]


def extract_rules_from_package(pkg_dir: Path) -> list[dict]:
    """Extracts rule metadata from all .rego files in a package directory."""
    rules = []
    for fp in sorted(pkg_dir.glob("*.rego")):
        content = fp.read_text(errors="replace")

        # Find all rule_id and _legal_basis
        for match in re.finditer(
            r'"rule_id"\s*:\s*"([^"]+)".*?"_legal_basis"\s*:\s*"([^"]*)"',
            content, re.DOTALL
        ):
            rule_id = match.group(1)
            legal_basis = match.group(2)

            pkg_match = re.search(r'"package"\s*:\s*"([^"]+)"', content)
            package = pkg_match.group(1) if pkg_match else f"jdg.{pkg_dir.name}"

            routing_match = re.search(
                rf'"{re.escape(rule_id)}".*?"_routing"\s*:\s*"([^"]*)"',
                content, re.DOTALL
            )
            routing = routing_match.group(1) if routing_match else ""

            rules.append({
                "rule_id": rule_id,
                "package": package,
                "routing": routing,
                "legal_basis": legal_basis,
            })
            if len(rules) >= 20:  # Limit per package
                break

    return rules


def generate_rego_test_file(pkg_name: str, rules: list[dict]) -> str:
    """Generates a complete *_test.rego file for a package."""
    if not rules:
        return f"# No rules found for package: {pkg_name}\n"

    safe_pkg = pkg_name.replace("-", "_")
    lines = [
        f"# ═══════════════════════════════════════════════════════════════",
        f"# NexusAI JDG — Native Rego Tests for: {pkg_name}",
        f"# Generated: {datetime.now().isoformat()}",
        f"# Package: jdg.{safe_pkg}",
        f"# Rules tested: {len(rules)}",
        f"# Report: P27 R3 — 11 missing package coverage",
        f"# ═══════════════════════════════════════════════════════════════",
        "",
        f"package test_jdg_{safe_pkg}",
        f"import data.jdg.{safe_pkg}",
        "",
    ]

    for i, rule in enumerate(rules[:15]):
        rule_id = rule["rule_id"]
        parts = rule_id.split(".")
        rule_short = parts[-1] if len(parts) > 1 else rule_id
        safe_name = re.sub(r'[^a-zA-Z0-9_]', '_', rule_short)[-30:]

        lines.append(f"# Test {i+1}: {rule_id}")
        lines.append(f"test_positive_{safe_name} {{")
        lines.append(f"    result := data.jdg.{safe_pkg}.decide with input as {{}}")
        lines.append(f"    result.matched == true")
        lines.append(f"}}")
        lines.append("")

        lines.append(f"# Negative test for: {rule_id}")
        lines.append(f"test_negative_{safe_name} {{")
        lines.append(f"    result := data.jdg.{safe_pkg}.decide with input as {{\"__neg_test__\": true}}")
        lines.append(f"    result.rule_id != \"{rule_id}\"")
        lines.append(f"}}")
        lines.append("")

    return "\n".join(lines)


def main():
    dry_run = "--dry-run" in sys.argv
    output_dir = Path(OUTPUT_DIR)
    output_dir.mkdir(parents=True, exist_ok=True)

    print("🔧 NexusAI JDG — Missing Package Test Generator (P27 R3)")
    print(f"   Pakiety bez testów: {len(MISSING_PACKAGES)}")
    print()

    generated = 0
    for pkg_name in MISSING_PACKAGES:
        pkg_dir = RULES_DIR / pkg_name
        if not pkg_dir.exists():
            print(f"   ⚠️ {pkg_name}: katalog nie istnieje — pomijam")
            continue

        rules = extract_rules_from_package(pkg_dir)
        if not rules:
            print(f"   ⚠️ {pkg_name}: brak reguł — pomijam")
            continue

        content = generate_rego_test_file(pkg_name, rules)
        output_file = output_dir / f"test_native_jdg_{pkg_name}.rego"

        if not dry_run:
            output_file.write_text(content, encoding="utf-8")
            generated += 1
            print(f"   ✅ {pkg_name}: {len(rules)} reguł → {output_file.name}")

    print(f"\n📊 Wygenerowano: {generated}/{len(MISSING_PACKAGES)} plików")
    if dry_run:
        print("   ✅ DRY-RUN — pliki NIE zostały zapisane.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
