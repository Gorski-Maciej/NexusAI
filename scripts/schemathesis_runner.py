"""
schemathesis_runner.py — CLI wrapper for schemathesis API testing in CI/CD.

SUPERMOCE schemathesis v4.21.8:
  - Uruchamianie przez `python scripts/schemathesis_runner.py`
  - Obsługa CI/CD (exit codes, raporty JUnit + HTML)
  - Wsparcie dla --mode positive|negative|mixed|all|ci|security
  - Wsparcie dla --max-examples, --workers, --format human|junit|html
  - Automatyczna walidacja wersji schemathesis
  - Automatyczny fallback jeśli schemat nie jest dostępny

Usage:
    python scripts/schemathesis_runner.py                            # Szybkie testy (CI mode)
    python scripts/schemathesis_runner.py --mode security            # Security fuzzing
    python scripts/schemathesis_runner.py --mode all --max-examples 50  # Pełny fuzz
    python scripts/schemathesis_runner.py --format junit             # Raport JUnit dla CI
    python scripts/schemathesis_runner.py --format html              # Raport HTML

CI/CD Integration:
    # W GitHub Actions:
    - name: Run schemathesis API tests
      run: |
        python scripts/schemathesis_runner.py --mode ci --format junit

    - name: Run security fuzzing
      run: |
        python scripts/schemathesis_runner.py --mode security --max-examples 100

Inspiracja: posthog/posthog — schemathesis w CI dla każdego PR
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def _check_schemathesis_version() -> str | None:
    """Sprawdza wersję schemathesis i zwraca komunikat błędu lub None."""
    try:
        import schemathesis

        from nexus_ai.core.version_utils import parse_version

        version = schemathesis.__version__

        min_version = "3.30.0"
        if parse_version(version) < parse_version(min_version):
            return (
                f"⚠️  schemathesis >= {min_version} required, "
                f"got {version}. Run: pip install -U schemathesis"
            )
        return None
    except ImportError:
        return "⚠️  schemathesis not installed. Run: pip install schemathesis"


def run_schemathesis_tests(
    *,
    mode: str = "ci",
    max_examples: int = 10,
    workers: int = 0,
    format_junit: bool = False,
    format_html: bool = False,
    verbose: bool = True,
    run_stateful: bool = False,
) -> int:
    """Run schemathesis property-based API tests via pytest.

    SUPERMOC: Wiele trybów uruchamiania:
      - ci:    Domyślny — zrównoważone testy dla CI
      - all:   Wszystkie testy (włączając stateful)
      - positive: Tylko poprawne dane (szybka weryfikacja)
      - negative: Tylko nieprawidłowe dane (testowanie walidacji)
      - security: Security-focused fuzzing (wykrywanie luk)
      - mixed:  Mieszane dane (domyślny fuzz)

    Args:
        mode: Tryb testowania (ci, all, positive, negative, security, mixed)
        max_examples: Liczba przykładów per endpoint
        workers: Liczba równoległych workerów (0 = auto)
        format_junit: Czy generować raport JUnit
        format_html: Czy generować raport HTML
        verbose: Czy verbose output
        run_stateful: Czy uruchomić stateful testing

    Returns:
        Exit code: 0=success, 1=fail
    """
    # ── SUPERMOC: Walidacja wersji schemathesis ─────────────────────
    version_error = _check_schemathesis_version()
    if version_error:
        print(version_error)
        if mode == "ci":
            return 1  # CI wymaga poprawnej wersji
        # Dev: kontynuuj z ostrzeżeniem

    project_root = Path(__file__).resolve().parents[1]
    schemathesis_dir = project_root / "tests" / "schemathesis"

    if not schemathesis_dir.exists():
        print("⚠️  tests/schemathesis/ not found. Creating...")
        (schemathesis_dir / "__init__.py").touch()

    # ── SUPERMOC: Budowanie komendy pytest ──────────────────────────
    cmd = [
        "python", "-m", "pytest",
        str(schemathesis_dir),
        "--run-schemathesis",
        "-v" if verbose else "-q",
        "--timeout=120",  # dłuższy timeout dla property-based tests
    ]

    # ── SUPERMOC: Tryby testowania ──────────────────────────────────
    if mode == "positive":
        # Tylko test_positive_happy_path
        cmd.extend(["-k", "positive"])
        if max_examples == 10:  # Domyślna wartość — nadpisz dla pozytywnych
            max_examples = 3
    elif mode == "negative":
        # Tylko test_negative_scenarios
        cmd.extend(["-k", "negative"])
        if max_examples == 10:
            max_examples = 20
    elif mode == "security":
        # Security-focused: negative + auth bypass + brute-force
        cmd.extend([
            "-k", "negative or auth or security or brute_force",
            str(schemathesis_dir / "test_security_fuzzing.py"),
        ])
        if max_examples == 10:
            max_examples = 50
    elif mode == "all":
        # Wszystkie testy
        run_stateful = True
    elif mode == "ci":
        # CI mode: mixed + smoke + positive (bez stateful)
        cmd.extend(["-k", "not stateful and not slow"])
    # else: "mixed" — domyślne pytest discovery

    # ── Workers (równoległość) ──────────────────────────────────────
    if workers > 0:
        cmd.extend(["-n", str(workers)])
    elif workers == 0:
        cmd.extend(["-n", "auto"])  # auto = liczba CPU

    # ── max_examples — ustaw zmienną środowiskową ──────────────────
    # pytest-parametrize odczytuje max_examples z konfiguracji Hypothesis
    # Nie można przekazać przez CLI bezpośrednio — używamy env var
    import os
    os.environ["SCHEMATHESIS_MAX_EXAMPLES"] = str(max_examples)
    print(f"🎲 max_examples: {max_examples}")

    # ── Raporty ─────────────────────────────────────────────────────
    reports_dir = project_root / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)

    if format_junit:
        junit_path = reports_dir / "schemathesis-junit.xml"
        cmd.extend(["--junitxml", str(junit_path)])
        print(f"📊 JUnit report: {junit_path}")

    if format_html:
        # schemathesis wspiera --report dla HTML (od v3.x)
        html_path = reports_dir / "schemathesis-report.html"
        cmd.extend(["--report", str(html_path)])
        print(f"📊 HTML report: {html_path}")

    # ── Stateful testing ────────────────────────────────────────────
    if run_stateful:
        stateful_test = schemathesis_dir / "test_stateful.py"
        if stateful_test.exists():
            cmd.append("--run-slow")
            print("🔗 Stateful testing enabled")
        else:
            print("⚠️  test_stateful.py not found — skipping stateful")

    # ── EXEC ────────────────────────────────────────────────────────
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
        description="NexusAI — Schemathesis API Testing Runner (v4.21.8)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
SUPERMOCE:
  --mode ci         Zrównoważone testy dla CI (domyślny)
  --mode all        Wszystkie testy + stateful
  --mode security   Security-focused fuzzing (SQL injection, XSS)
  --mode positive   Tylko poprawne dane (szybki happy path)
  --mode negative   Tylko nieprawidłowe dane (walidacja)
  --mode mixed      Mieszane dane (domyślny fuzz)

Przykłady:
  %(prog)s                                          # CI mode
  %(prog)s --mode security --max-examples 100       # Security fuzzing
  %(prog)s --mode all --format junit                # Full CI suite
  %(prog)s --mode positive --verbose                # Quick validation
        """,
    )
    parser.add_argument(
        "--mode",
        choices=["ci", "all", "positive", "negative", "security", "mixed"],
        default="ci",
        help="Tryb testowania (domyślnie: ci)",
    )
    parser.add_argument(
        "--max-examples",
        type=int,
        default=10,
        help="Liczba przykładów per endpoint (domyślnie: 10)",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=0,
        help="Liczba równoległych workerów (0=auto, domyślnie: 0)",
    )
    parser.add_argument(
        "--format",
        choices=["human", "junit", "html"],
        default="human",
        help="Format raportu (domyślnie: human-readable)",
    )
    parser.add_argument(
        "--run-stateful",
        action="store_true",
        help="Uruchom stateful workflow testing (POST→GET→DELETE sequences)",
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Quiet mode (minimal output)",
    )

    args = parser.parse_args()

    # ── SUPERMOC: Wyświetl konfigurację przed startem ──────────────
    print("╔══════════════════════════════════════════════════════════╗")
    print("║  🔬 Schemathesis API Testing Runner v4.21.8            ║")
    print("╠══════════════════════════════════════════════════════════╣")
    print(f"║  Mode:          {args.mode:<34} ║")
    print(f"║  max_examples:  {args.max_examples:<34} ║")
    print(f"║  Workers:       {args.workers if args.workers > 0 else 'auto':<34} ║")
    print(f"║  Format:        {args.format:<34} ║")
    print(f"║  Stateful:      {'Yes' if args.run_stateful else 'No':<34} ║")
    print("╚══════════════════════════════════════════════════════════╝")

    exit_code = run_schemathesis_tests(
        mode=args.mode,
        max_examples=args.max_examples,
        workers=args.workers,
        format_junit=args.format == "junit",
        format_html=args.format == "html",
        verbose=not args.quiet,
        run_stateful=args.run_stateful,
    )
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
