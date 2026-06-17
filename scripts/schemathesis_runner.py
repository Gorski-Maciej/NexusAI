"""
schemathesis_runner.py — CLI wrapper for schemathesis API testing in CI/CD.

SUPERMOCE schemathesis:
  - Uruchamianie przez `python -m nexus_ai.scripts.schemathesis_runner`
  - Obsługa CI/CD (exit codes, raporty JUnit)
  - Wsparcie dla --run-slow, --run-stateful, --format junit
  - Automatyczny fallback jeśli schemat nie jest dostępny

Usage:
    python scripts/schemathesis_runner.py                            # Szybkie testy
    python scripts/schemathesis_runner.py --run-stateful             # + stateful
    python scripts/schemathesis_runner.py --format junit             # Raport JUnit

CI/CD Integration:
    # W GitHub Actions:
    - name: Run schemathesis API tests
      run: |
        python scripts/schemathesis_runner.py --format junit
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def run_schemathesis_tests(
    *,
    run_stateful: bool = False,
    format_junit: bool = False,
    verbose: bool = True,
) -> int:
    """Run schemathesis property-based API tests via pytest.

    Używa pytest z odpowiednimi flagami do uruchomienia testów
    schemathesis. Domyślnie szybkie testy (max_examples=10).
    Opcjonalnie stateful testing (max_examples=5, bo trwa dłużej).

    Args:
        run_stateful: Czy uruchomić stateful testing (POST→GET→DELETE)
        format_junit: Czy generować raport JUnit dla CI
        verbose: Czy verbose output

    Returns:
        Exit code: 0=success, 1=fail
    """
    project_root = Path(__file__).resolve().parents[2]
    schemathesis_dir = project_root / "tests" / "schemathesis"

    if not schemathesis_dir.exists():
        print("⚠️  tests/schemathesis/ not found. Creating...")
        (schemathesis_dir / "__init__.py").touch()

    cmd = [
        "python", "-m", "pytest",
        str(schemathesis_dir),
        "--run-schemathesis",
        "-v" if verbose else "-q",
        "--timeout=120",  # dłuższy timeout dla property-based tests
    ]

    if format_junit:
        junit_path = project_root / "reports" / "schemathesis-junit.xml"
        junit_path.parent.mkdir(parents=True, exist_ok=True)
        cmd.extend(["--junitxml", str(junit_path)])
        print(f"📊 JUnit report: {junit_path}")

    if run_stateful:
        # Stateful testing: testy workflows (POST→GET→DELETE)
        stateful_test = schemathesis_dir / "test_stateful.py"
        if stateful_test.exists():
            cmd.append(str(stateful_test))
            print("🔗 Stateful testing enabled")

    print(f"🚀 Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=project_root)

    if result.returncode == 0:
        print("✅ Schemathesis tests PASSED")
    else:
        print("❌ Schemathesis tests FAILED")

    return result.returncode


def main() -> None:
    """Entry point for schemathesis_runner CLI."""
    parser = argparse.ArgumentParser(
        description="NexusAI — Schemathesis API Testing Runner",
    )
    parser.add_argument(
        "--run-stateful",
        action="store_true",
        help="Run stateful workflow testing (POST→GET→DELETE sequences)",
    )
    parser.add_argument(
        "--format",
        choices=["human", "junit"],
        default="human",
        help="Output format (default: human-readable)",
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Quiet mode (minimal output)",
    )

    args = parser.parse_args()
    exit_code = run_schemathesis_tests(
        run_stateful=args.run_stateful,
        format_junit=args.format == "junit",
        verbose=not args.quiet,
    )
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
