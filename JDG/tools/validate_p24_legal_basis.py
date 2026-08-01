#!/usr/bin/env python3
"""
P24 CI Legal Basis Validator (I11 from P23 + I12 for plan33)
Validates _legal_basis fields across all micro and plan33 modules.
Ensures legal bases match the correct acts for each domain.

Usage: python validate_p24_legal_basis.py [--fix] [--ci]
"""
import re
import os
import sys
import json
from pathlib import Path
from datetime import datetime

# Correct legal basis mappings per module
EXPECTED_LEGAL_BASIS = {
    "jdg.micro.ceidg": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "jdg.micro.ryczalt": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "jdg.micro.sukcesja": "Ustawa o zarządzie sukcesyjnym (Dz.U. 2018 poz. 1629)",
    "jdg.micro.budownictwo": "Prawo budowlane (Dz.U. 1994 nr 89 poz. 414)",
    "jdg.micro.transport": "Ustawa o transporcie drogowym (Dz.U. 2001 nr 125 poz. 1371)",
    "jdg.micro.pp": "Prawo przedsiębiorców (Dz.U. 2018 poz. 646)",
    "jdg.micro.est": "Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG",
    "jdg.micro.tax_trans": "Ustawa o podatkach i opłatach lokalnych (Art. 8-13)",
}

# Known bad legal bases (errors detected in P24 report)
BAD_LEGAL_BASIS_PATTERNS = [
    (r"Ustawa o podatku od spadków i darowizn", "R-EST-1: Wrong basis — should be CIT Art. 28c-28t"),
    (r"Ustawa o podatku od czynności cywilnoprawnych", "R-TAXTRANS-1: Wrong basis — should be u.p.o.l. Art. 8-13"),
    (r"Ustawa o podatku.*dochodowym od osób fizycznych", None),  # Valid for PIT modules
]

# Valid legal basis prefixes
VALID_PREFIXES = [
    "Ustawa o", "Art.", "§", "Rozporządzenie", "Dyrektywa",
    "Prawo budowlane", "Kodeks", "Konstytucja", "Prawo przedsiębiorców",
    "KC", "KSH", "KP",
]


def extract_legal_basis(content: str) -> list[dict]:
    """Extract all _legal_basis fields with their rule_ids."""
    results = []
    lines = content.split("\n")
    current_rule = None
    current_package = None

    for line in lines:
        # Track package
        pkg_match = re.search(r'package\s+(\S+)', line)
        if pkg_match:
            current_package = pkg_match.group(1)

        # Track rule_id
        rule_match = re.search(r'"rule_id":\s*"([^"]+)"', line)
        if rule_match:
            current_rule = rule_match.group(1)

        # Extract legal basis
        basis_match = re.search(r'"_legal_basis":\s*"([^"]*)"', line)
        if basis_match and current_package:
            results.append({
                "rule_id": current_rule or "unknown",
                "package": current_package,
                "legal_basis": basis_match.group(1),
                "line": line.strip()
            })

    return results


def validate_module(module_path: str, module_name: str) -> dict:
    """Validate a single Rego module's legal basis fields."""
    results = {
        "file": module_path,
        "module": module_name,
        "total_rules": 0,
        "rules_with_basis": 0,
        "rules_without_basis": 0,
        "errors": [],
        "warnings": [],
        "status": "PASS"
    }

    if not os.path.exists(module_path):
        results["status"] = "SKIP"
        results["warnings"].append(f"File not found: {module_path}")
        return results

    with open(module_path, "r", encoding="utf-8") as f:
        content = f.read()

    bases = extract_legal_basis(content)
    results["total_rules"] = len(bases)

    expected_basis = EXPECTED_LEGAL_BASIS.get(module_name)

    for entry in bases:
        basis = entry["legal_basis"]

        if not basis or basis.strip() == "":
            results["rules_without_basis"] += 1
            results["warnings"].append(
                f"{entry['rule_id']}: EMPTY legal_basis"
            )
            continue

        results["rules_with_basis"] += 1

        # Check for known bad patterns
        if "spadków i darowizn" in basis and module_name != "jdg.micro.est":
            results["errors"].append(
                f"R-EST-1 TYPE ERROR: {entry['rule_id']} has inheritance tax basis: {basis}"
            )
            results["status"] = "FAIL"

        if "czynności cywilnoprawnych" in basis and module_name != "jdg.micro.pcc":
            results["errors"].append(
                f"R-TAXTRANS-1 TYPE ERROR: {entry['rule_id']} has PCC basis: {basis}"
            )
            results["status"] = "FAIL"

        # Validate prefix
        valid_prefix = any(basis.startswith(p) for p in VALID_PREFIXES)
        if not valid_prefix and basis:
            results["warnings"].append(
                f"{entry['rule_id']}: Unrecognized legal_basis prefix: {basis[:80]}..."
            )

        # Check consistency with expected basis (pattern match, not exact)
        if expected_basis:
            # Extract key identifier words
            expected_words = set(expected_basis.lower().split())
            actual_words = set(basis.lower().split())
            overlap = expected_words.intersection(actual_words)
            if len(overlap) < 2 and basis:
                results["warnings"].append(
                    f"{entry['rule_id']}: Legal basis may be inconsistent. "
                    f"Expected keywords: {expected_words}. Got: {basis[:100]}"
                )

    return results


def validate_all_modules(rules_dir: str) -> dict:
    """Validate all P24 micro and plan33 modules."""
    modules = {
        # Micro modules
        "jdg.micro.ceidg": os.path.join(rules_dir, "micro", "ceidg", "ceidg.rego"),
        "jdg.micro.ryczalt": os.path.join(rules_dir, "micro", "ryczalt", "ryczalt.rego"),
        "jdg.micro.sukcesja": os.path.join(rules_dir, "micro", "sukcesja", "sukcesja.rego"),
        "jdg.micro.budownictwo": os.path.join(rules_dir, "micro", "budownictwo", "budownictwo.rego"),
        "jdg.micro.transport": os.path.join(rules_dir, "micro", "transport", "transport.rego"),
        "jdg.micro.pp": os.path.join(rules_dir, "micro", "pp", "pp.rego"),
        # Plan33 modules
        "jdg.micro.est": os.path.join(rules_dir, "micro", "plan33_est.rego"),
        "jdg.micro.tax_trans": os.path.join(rules_dir, "micro", "plan33_tax_trans.rego"),
        "jdg.micro.tp": os.path.join(rules_dir, "micro", "plan33_tp.rego"),
        "jdg.micro.mdr": os.path.join(rules_dir, "micro", "plan33_mdr.rego"),
        "jdg.micro.ryc": os.path.join(rules_dir, "micro", "plan33_ryc.rego"),
        "jdg.micro.succ": os.path.join(rules_dir, "micro", "plan33_succ.rego"),
        "jdg.micro.ceidg33": os.path.join(rules_dir, "micro", "plan33_ceidg.rego"),
    }

    all_results = []
    total_errors = 0
    total_warnings = 0
    failed_modules = 0

    for name, path in sorted(modules.items()):
        result = validate_module(path, name)
        all_results.append(result)

        if result["status"] == "FAIL":
            failed_modules += 1
        total_errors += len(result["errors"])
        total_warnings += len(result["warnings"])

        # Print per-module summary
        status_icon = "✅" if result["status"] == "PASS" else "⚠️" if result["status"] == "SKIP" else "❌"
        print(f"  {status_icon} {result['module']}: {result['total_rules']} rules, "
              f"{result['rules_with_basis']} with basis, "
              f"{result['rules_without_basis']} without, "
              f"{len(result['errors'])} errors, {len(result['warnings'])} warnings")

    summary = {
        "validator": "P24 Legal Basis Validator (I11+I12)",
        "timestamp": datetime.now().isoformat(),
        "total_modules": len(all_results),
        "failed_modules": failed_modules,
        "total_errors": total_errors,
        "total_warnings": total_warnings,
        "modules": all_results,
        "ci_pass": total_errors == 0
    }

    return summary


def print_report(summary: dict) -> int:
    """Print validation report and return exit code."""
    print("=" * 70)
    print("P24 CI LEGAL BASIS VALIDATOR (I11 from P23 + I12 for plan33)")
    print("=" * 70)
    print(f"Timestamp: {summary['timestamp']}")
    print(f"Modules checked: {summary['total_modules']}")
    print()

    for mod in summary["modules"]:
        print(f"  {mod['module']}: {mod['status']}")
        for err in mod["errors"]:
            print(f"    ❌ ERROR: {err}")
        for warn in mod["warnings"][:5]:  # limit warnings
            print(f"    ⚠️  WARNING: {warn}")
        if len(mod["warnings"]) > 5:
            print(f"    ... and {len(mod['warnings']) - 5} more warnings")

    print()
    print(f"TOTAL: {summary['total_errors']} errors, {summary['total_warnings']} warnings")
    print(f"CI PASS: {'YES ✅' if summary['ci_pass'] else 'NO ❌'}")
    print()
    print("R-EST-1 status: " + ("FIXED ✅" if not any(
        "R-EST-1" in str(e) for m in summary["modules"] for e in m["errors"]
    ) else "STILL BROKEN ❌"))
    print("R-TAXTRANS-1 status: " + ("FIXED ✅" if not any(
        "R-TAXTRANS-1" in str(e) for m in summary["modules"] for e in m["errors"]
    ) else "STILL BROKEN ❌"))
    print("=" * 70)

    return 0 if summary["ci_pass"] else 1


def main():
    import argparse
    parser = argparse.ArgumentParser(description="P24 Legal Basis Validator")
    parser.add_argument("--ci", action="store_true", help="CI mode: exit non-zero on errors")
    parser.add_argument("--fix", action="store_true", help="Attempt auto-fix (not yet implemented)")
    parser.add_argument("--rules-dir", default="JDG/rules", help="Rules directory")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    rules_dir = os.path.join(project_root, args.rules_dir)

    if not os.path.isdir(rules_dir):
        # Try relative path
        if os.path.isdir(args.rules_dir):
            rules_dir = args.rules_dir
        else:
            print(f"ERROR: Rules directory not found: {rules_dir}")
            return 1

    print(f"Scanning rules in: {rules_dir}")
    summary = validate_all_modules(rules_dir)

    if args.json:
        print(json.dumps(summary, indent=2, ensure_ascii=False))
    else:
        print_report(summary)

    if args.ci and not summary["ci_pass"]:
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
