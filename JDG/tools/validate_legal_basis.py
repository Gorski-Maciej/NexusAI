#!/usr/bin/env python3
"""
P24 Legal Basis Validator — wykrywa błędne podstawy prawne w regułach OPA/Rego.
Wdrożony jako odpowiedź na R-EST-1 i R-TAXTRANS-1 z raportu P24.

Usage:
    python3 JDG/tools/validate_legal_basis.py [--fix] [directory]
"""

import re
import sys
import os
from pathlib import Path

# Mapping of incorrect legal bases → correct ones
LEGAL_BASIS_CORRECTIONS = {
    # R-EST-1: Estoński CIT
    "Ustawa o podatku od spadków i darowizn": {
        "fix": "Ustawa o CIT (Art. 28c-28t) / Ustawa o PIT (Art. 30da-30dd)",
        "severity": "CRITICAL",
        "applies_to_packages": ["jdg.micro.est", "jdg.est"],
        "report_ref": "R-EST-1"
    },
    # R-TAXTRANS-1: Podatek od środków transportowych
    "Ustawa o podatku od czynności cywilnoprawnych": {
        "fix": "Ustawa o podatkach i opłatach lokalnych (Art. 8-13)",
        "severity": "CRITICAL",
        "applies_to_packages": ["jdg.micro.tax_trans", "jdg.tax_trans"],
        "report_ref": "R-TAXTRANS-1"
    },
}

# Known correct legal bases for validation
KNOWN_CORRECT_BASES = {
    "jdg.micro.est": "Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG",
    "jdg.micro.tax_trans": "Ustawa o podatkach i opłatach lokalnych (Art. 8-13)",
    "jdg.micro.ryczalt": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "jdg.micro.ceidg": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "jdg.micro.sukcesja": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
}

# Priority range validator
PRIORITY_RANGES = {
    "micro": (10000, 260000),
    "plan33": (3000, 9999),
    "hyper": (1004, 1708),
    "enterprise": (100000, 999999),
}


def find_rego_files(directory: str) -> list:
    """Find all .rego files in directory recursively."""
    files = []
    for root, _, filenames in os.walk(directory):
        for f in filenames:
            if f.endswith(".rego"):
                files.append(os.path.join(root, f))
    return files


def extract_legal_basis(content: str) -> list:
    """Extract all _legal_basis values from a rego file."""
    pattern = r'"_legal_basis":\s*"([^"]+)"'
    return re.findall(pattern, content)


def extract_package(content: str) -> str:
    """Extract package name from a rego file."""
    match = re.search(r'package\s+([\w.]+)', content)
    return match.group(1) if match else ""


def extract_priorities(content: str) -> list:
    """Extract all priority values."""
    pattern = r'"priority":\s*(\d+)'
    return [int(m) for m in re.findall(pattern, content)]


def extract_rule_ids(content: str) -> list:
    """Extract all rule_ids."""
    pattern = r'"rule_id":\s*"([^"]+)"'
    return re.findall(pattern, content)


def validate_file(filepath: str, fix: bool = False) -> dict:
    """Validate a single .rego file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    package = extract_package(content)
    legal_bases = extract_legal_basis(content)
    priorities = extract_priorities(content)
    rule_ids = extract_rule_ids(content)

    issues = []
    fixes_applied = []

    # Check each legal basis
    for i, basis in enumerate(legal_bases):
        if basis in LEGAL_BASIS_CORRECTIONS:
            correction = LEGAL_BASIS_CORRECTIONS[basis]
            # Check if this correction applies to this package
            applies = any(pkg in package for pkg in correction["applies_to_packages"])
            if applies:
                issues.append({
                    "type": "WRONG_LEGAL_BASIS",
                    "severity": correction["severity"],
                    "current": basis,
                    "correct": correction["fix"],
                    "report_ref": correction["report_ref"],
                    "file": filepath,
                    "package": package
                })
                if fix:
                    fixes_applied.append(f"Fixed {basis} → {correction['fix']}")

    # Check if all bases are consistent (same package should use consistent basis)
    unique_bases = set(legal_bases)
    if len(unique_bases) > 1 and package in KNOWN_CORRECT_BASES:
        expected = KNOWN_CORRECT_BASES[package]
        for basis in unique_bases:
            if expected not in basis and basis != expected:
                issues.append({
                    "type": "INCONSISTENT_LEGAL_BASIS",
                    "severity": "WARNING",
                    "current": basis,
                    "expected": expected,
                    "file": filepath,
                    "package": package
                })

    # Validate priority ranges for plan33 files
    if "plan33" in filepath.lower() or "plan33" in package.lower():
        for p in priorities:
            if p < 3000 or p > 9999:
                issues.append({
                    "type": "PRIORITY_OUT_OF_RANGE",
                    "severity": "WARNING",
                    "priority": p,
                    "expected_range": "3000-9999 (plan33)",
                    "file": filepath,
                    "package": package
                })

    return {
        "file": filepath,
        "package": package,
        "rule_count": len(rule_ids),
        "issues": issues,
        "fixes_applied": fixes_applied,
        "legal_bases_found": unique_bases
    }


def main():
    directory = sys.argv[1] if len(sys.argv) > 1 else "JDG/rules"
    fix_mode = "--fix" in sys.argv

    rego_files = find_rego_files(directory)
    print(f"🔍 P24 Legal Basis Validator v7.0")
    print(f"   Scanning {len(rego_files)} .rego files in {directory}")
    print(f"   Fix mode: {'ON' if fix_mode else 'OFF'}")
    print()

    total_issues = 0
    critical_issues = 0
    results = []

    for filepath in sorted(rego_files):
        result = validate_file(filepath, fix=fix_mode)
        results.append(result)
        if result["issues"]:
            total_issues += len(result["issues"])
            critical_count = sum(1 for i in result["issues"] if i["severity"] == "CRITICAL")
            critical_issues += critical_count
            for issue in result["issues"]:
                prefix = "🔴" if issue["severity"] == "CRITICAL" else "🟡"
                print(f"  {prefix} [{issue['type']}] {os.path.basename(filepath)}")
                if "current" in issue:
                    print(f"     Current: {issue['current']}")
                    print(f"     Correct: {issue['correct']}")
                if "report_ref" in issue:
                    print(f"     Report:  {issue['report_ref']}")

    # Summary
    print()
    print(f"═══════════════════════════════════════════════════════")
    print(f"  SUMMARY")
    print(f"  Files scanned:       {len(rego_files)}")
    print(f"  Total rules:         {sum(r['rule_count'] for r in results)}")
    print(f"  Issues found:        {total_issues}")
    print(f"  Critical issues:     {critical_issues}")
    print(f"═══════════════════════════════════════════════════════")

    # KPI check
    kpi_met = critical_issues == 0
    print(f"  KPI-3 (0 błędów podstaw): {'✅ MET' if kpi_met else '❌ NOT MET'}")

    return 0 if kpi_met else 1


if __name__ == "__main__":
    sys.exit(main())
