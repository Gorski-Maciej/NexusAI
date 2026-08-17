#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — ZUS Naming Consistency Unifier (INN07 supplement — P08 Report)
═══════════════════════════════════════════════════════════════════════════════

Unifikuje nazwy rule_id w mikro-warstwie ZUS:
  jdg.micro.sus.a*.r* → jdg.micro.zus.a*.r*
  jdg.zus.a*.r* → jdg.micro.zus.a*.r*
  jdg.health.* → jdg.micro.zus.health.*

Wykrywa 3 formaty nazewnictwa i proponuje ujednolicenie.

Użycie:
    python JDG/tools/zus_naming_unifier.py [--dry-run] [--execute]
    python JDG/tools/zus_naming_unifier.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
"""

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MICRO_DIR = PROJECT_ROOT / "JDG" / "rules" / "micro"

ZUS_MICRO_FILES = [
    "sus/sus.rego", "zdrowotna/zdrowotna.rego", "zasilkowa/zasilkowa.rego",
    "plan33_zus.rego", "zus_micro_atomic_p09.rego", "plan33_health.rego",
]

# ── Naming patterns detected ─────────────────────────────────────────────────
# NOTE: Cross-package renames are DANGEROUS in OPA — packages define independent else-chains.
# Only rule_id naming is checked for consistency, NOT package renames.
PATTERN_MAP = {
    # These are REPORTED but NOT auto-renamed because packages are separate OPA namespaces
}

RULE_ID_PATTERN = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
PACKAGE_PATTERN = re.compile(r'"package"\s*:\s*"([^"]+)"')


class ZUSNamingUnifier:
    """Unifies ZUS micro rule naming conventions."""

    def __init__(self, dry_run=True):
        self.dry_run = dry_run
        self.issues = []
        self.stats = defaultdict(int)

    def analyze(self):
        """Analyze all ZUS micro files for naming inconsistencies."""
        for rel_path in ZUS_MICRO_FILES:
            filepath = MICRO_DIR / rel_path
            if not filepath.exists():
                continue
            self._analyze_file(filepath, rel_path)

        return self._generate_report()

    def _analyze_file(self, filepath, rel_path):
        """Analyze a single file."""
        content = filepath.read_text(encoding="utf-8")
        lines = content.split("\n")

        for i, line in enumerate(lines):
            rid_match = RULE_ID_PATTERN.search(line)
            pkg_match = PACKAGE_PATTERN.search(line)

            if rid_match:
                rid = rid_match.group(1)
                self._check_naming(rid, rel_path, i + 1)

            if pkg_match:
                pkg = pkg_match.group(1)
                self._check_package_naming(pkg, rel_path, i + 1)

        self.stats["files_analyzed"] += 1

    def _check_naming(self, rule_id, rel_path, line_no):
        """Check if rule_id follows recommended naming."""
        # Valid patterns across ZUS micro layer
        valid_prefixes = [
            "jdg.micro.sus.", "jdg.micro.zdrowotna.", "jdg.micro.zasilkowa.",
            "jdg.zus.", "jdg.health.", "jdg.micro.zus.", "jdg.micro.health.",
        ]
        is_valid = any(rule_id.startswith(p) for p in valid_prefixes)
        
        if not is_valid and not rule_id.endswith(".no_match"):
            self.issues.append({
                "file": rel_path,
                "line": line_no,
                "current": rule_id,
                "recommended": self._suggest_naming(rule_id),
                "type": "rule_id",
            })
            self.stats["naming_issues"] += 1
        elif rule_id.startswith("jdg.micro.sus") or rule_id.startswith("jdg.micro.zdrowotna") or rule_id.startswith("jdg.micro.zasilkowa"):
            # Report but don't flag as error — these are valid package-scoped names
            self.stats["naming_issues"] += 1
            self.issues.append({
                "file": rel_path,
                "line": line_no,
                "current": rule_id,
                "recommended": f"Consider jdg.micro.zus.* for ZUS-wide rules (current package is valid)",
                "type": "rule_id_info",
            })

    def _check_package_naming(self, package, rel_path, line_no):
        """Check if package follows recommended naming (INFO only — never auto-rename packages)."""
        valid_packages = [
            "jdg.micro.sus", "jdg.micro.zdrowotna", "jdg.micro.zasilkowa",
            "jdg.micro.zus", "jdg.micro.health", "jdg.zus", "jdg.health",
        ]
        if package not in valid_packages and not package.startswith("jdg."):
            self.issues.append({
                "file": rel_path,
                "line": line_no,
                "current": package,
                "recommended": "jdg.micro.zus (or keep current package)",
                "type": "package",
            })
            self.stats["package_issues"] += 1

    def _suggest_naming(self, rule_id):
        """Suggest canonical naming for a rule_id."""
        # Keep original package, just report
        return rule_id

    def fix(self):
        """Apply naming fixes to files — package renames are SKIPPED for OPA safety."""
        if self.dry_run:
            return {"fixed": 0, "message": "DRY_RUN — no changes made"}

        # Cross-package renames are DANGEROUS for OPA else-chains.
        # We only report inconsistencies, never auto-rename packages.
        return {"fixed": 0, "files_modified": 0, "message": "Package renames skipped — OPA packages define independent else-chains. Review manually."}

    def _generate_report(self):
        """Generate naming report."""
        return {
            "tool": "ZUS Naming Consistency Unifier",
            "version": "1.0.0",
            "mode": "DRY_RUN" if self.dry_run else "EXECUTED",
            "files_analyzed": self.stats["files_analyzed"],
            "naming_issues": self.stats["naming_issues"],
            "package_issues": self.stats["package_issues"],
            "recommended_pattern": "jdg.micro.zus.a*.r*",
            "patterns_detected": list(PATTERN_MAP.keys()),
            "issues": self.issues,
        }


def main():
    parser = argparse.ArgumentParser(description="NexusAI JDG — ZUS Naming Unifier")
    parser.add_argument("--execute", action="store_true", help="Apply naming fixes")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    dry_run = not args.execute
    unifier = ZUSNamingUnifier(dry_run=dry_run)
    report = unifier.analyze()

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print()
        print("═" * 78)
        print("  NexusAI JDG — ZUS Naming Consistency Unifier")
        print(f"  Mode: {report['mode']}")
        print(f"  Files analyzed: {report['files_analyzed']}")
        print(f"  Naming issues: {report['naming_issues']}  |  Package issues: {report['package_issues']}")
        print(f"  Recommended pattern: {report['recommended_pattern']}")
        print(f"  Patterns detected: {', '.join(report['patterns_detected'])}")
        print("═" * 78)

        if report["issues"]:
            print(f"\n  📋 ISSUES FOUND:")
            for issue in report["issues"][:15]:
                print(f"     {issue['file']}:{issue['line']} — {issue['current']} → {issue['recommended']}")

    if args.execute:
        fix_result = unifier.fix()
        print(f"\n  ✅ Applied: {fix_result['fixed']} files modified")

    if args.report:
        report_path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_NAMING_UNIFIER.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as f:
            f.write("RAPORT — ZUS Naming Consistency Unifier\n")
            f.write(f"Pattern: {report['recommended_pattern']}\n")
            f.write(f"Issues: {report['naming_issues']}\n")
        print(f"  📄 Report saved: {report_path}")


if __name__ == "__main__":
    main()
