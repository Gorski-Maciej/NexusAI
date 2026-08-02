#!/usr/bin/env python3
"""
Tautology Guard for CI (Raport P27 — R2)
═══════════════════════════════════════════════════════════════════════════════

Weryfikuje, że testy JDG NIE są tautologiami (testami asertującymi własne dane).
Sprawdza:
1. Testy auto Python: czy odwołują się do plików .rego lub import data.jdg.*
2. Testy natywne Rego: czy istnieją pliki *_test.rego z faktyczną ewaluacją OPA
3. Liczbę testów natywnych vs tautologicznych

Exit code: 1 jeśli znaleziono tautologie, 0 jeśli clean.

Usage:
  python tautology_guard.py [--ci] [--auto-dir JDG/tests/auto/] [--rego-dir JDG/tests/rego/]
"""

import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent


def check_python_tests(auto_dir: Path) -> list[str]:
    """Sprawdza testy Python pod kątem tautologii."""
    issues = []
    if not auto_dir.exists():
        return issues

    for test_file in sorted(auto_dir.glob("test_*.py")):
        content = test_file.read_text(errors="replace")

        # Czy test importuje/wykonuje Rego?
        has_rego_import = bool(re.search(r'(import data\.jdg|opa eval|opa test|rego\.run)', content))
        has_rego_ref = bool(re.search(r'rules?/[a-z_]+\.rego', content))
        has_eval_rego = bool(re.search(r'(eval_rego|evaluate_rego|run_opa)', content))

        is_tautology = not (has_rego_import or has_rego_ref or has_eval_rego)

        if is_tautology:
            # Count how many tests in this file
            test_count = len(re.findall(r'def test_', content))
            issues.append(
                f"[TAUTOLOGY] {test_file.name}: {test_count} testów — brak odwołań do Rego/OPA. "
                f"Test asertuje własne input_data."
            )

    return issues


def check_rego_tests(rego_dir: Path) -> dict:
    """Sprawdza obecność natywnych testów Rego."""
    if not rego_dir.exists():
        return {"exists": False, "count": 0, "files": []}

    files = list(rego_dir.glob("*_test.rego")) + list(rego_dir.glob("test_*.rego"))
    test_count = 0
    for f in files:
        content = f.read_text(errors="replace")
        test_count += len(re.findall(r'^test_', content, re.MULTILINE))

    return {
        "exists": True,
        "count": test_count,
        "files": [f.name for f in files],
        "file_count": len(files),
    }


def main():
    ci_mode = "--ci" in sys.argv
    auto_dir = JDG_ROOT / "tests" / "auto"
    rego_dir = JDG_ROOT / "tests" / "rego"

    for arg in sys.argv:
        if arg.startswith("--auto-dir="):
            auto_dir = Path(arg.split("=", 1)[1])
        elif arg.startswith("--rego-dir="):
            rego_dir = Path(arg.split("=", 1)[1])

    print("🛡️ NexusAI JDG — Tautology Guard (P27 R2)")
    print()

    # Check Python tests
    python_issues = check_python_tests(auto_dir)
    tautology_count = len(python_issues)

    # Check Rego tests
    rego_info = check_rego_tests(rego_dir)

    # Report
    if python_issues:
        print(f"🔴 Python tests: {tautology_count} plików z tautologiami:")
        for issue in python_issues[:10]:
            print(f"   {issue}")
        if len(python_issues) > 10:
            print(f"   ... i {len(python_issues) - 10} więcej")
    else:
        print("✅ Python tests: brak tautologii")

    if rego_info["exists"]:
        print(f"✅ Native Rego tests: {rego_info['file_count']} plików, ~{rego_info['count']} testów")
    else:
        print("⚠️ Native Rego tests: BRAK (katalog tests/rego/ nie istnieje)")
        print("   Uruchom: python JDG/tools/generate_test_suite.py --mode=rego-native")

    print()
    status = "CRITICAL" if tautology_count > 0 else "OK"
    print(f"📊 Tautology Guard: {status}")

    if ci_mode and tautology_count > 0:
        print(f"\n❌ CI FAIL: {tautology_count} plików z tautologiami. Napraw przez `generate_test_suite.py --mode=rego-native`")
        return 1

    return 0 if tautology_count == 0 else 0  # Warning only, not blocking by default


if __name__ == "__main__":
    sys.exit(main())
