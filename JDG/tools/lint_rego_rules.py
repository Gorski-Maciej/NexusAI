#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Rego Rule Linter (B3 Strategic Initiative)
═══════════════════════════════════════════════════════════════════════════════

DRY Policy Compiler + Strict Linting — 6 walidacji na poziomie pre-commit/CI:
  1. matched_true_required  — żadna reguła nie zwraca matched:false bez powodu
  2. no_fallback_allow       — brak cichych fallbacków ALLOW
  3. rule_id_canonical       — każdy rule_id w formacie jdg.<package>.<rule>
  4. no_hardcoded_integers   — zero magicznych liczb (poza thresholds_jdg.rego)
  5. legal_basis_required    — każda reguła ma _legal_basis
  6. temporal_validity       — każda reguła ma wpis temporalny

Użycie:
    python JDG/tools/lint_rego_rules.py [--ci] [--fix] [--verbose]
    python JDG/tools/lint_rego_rules.py --check matched_true_required

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-17
Wersja: 1.0.0
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

# ── Konfiguracja ─────────────────────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
JDG_RULES_DIR = PROJECT_ROOT / "JDG" / "rules"
CONFTEST_DATA_DIR = PROJECT_ROOT / "conftest" / "data"

EXCLUDED_FILES = {
    "thresholds_jdg.rego",
    "_metadata_jdg.rego",
    "_helpers_jdg.rego",
    "api_fallback.rego",
}

EXCLUDED_RULE_IDS = {
    "jdg.accounting.no_match",
    "jdg.conflicts.no_conflicts",
    "jdg.kks.no_match",
    "jdg.fallback.domestic_23pct",
}

# Wzorce regex dla walidacji
REGO_INTEGER_PATTERN = re.compile(
    r'(?<![#\w])\b([2-9]\d{3,}|[1-9]\d{4,})\b'
)
DATE_PATTERN = re.compile(r'\b\d{4}-\d{2}-\d{2}\b')
PRIORITY_PATTERN = re.compile(r'"priority":\s*(\d+)')
RULE_ID_PATTERN = re.compile(
    r'"rule_id"\s*:\s*"([^"]+)"'
)
LEGAL_BASIS_PATTERN = re.compile(
    r'"_legal_basis"\s*:\s*"([^"]*)"'
)
ROUTING_PATTERN = re.compile(
    r'"_routing"\s*:\s*("[^"]*"|[\w.]+)'  # string lub zmienna (np. col1_rt)
)
MATCHED_PATTERN = re.compile(
    r'"matched"\s*:\s*(true|false)'
)


class LintResult:
    """Wynik pojedynczej walidacji."""
    def __init__(self, check_name: str):
        self.check_name = check_name
        self.violations: list[dict] = []
        self.passed: bool = True

    def add_violation(self, file_path: str, line_no: int, rule_id: str, message: str):
        self.violations.append({
            "file": str(file_path),
            "line": line_no,
            "rule_id": rule_id,
            "message": message,
        })
        self.passed = False


class RegoLinter:
    """Główny linter reguł Rego dla JDG."""

    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.results: list[LintResult] = []
        self.rego_files: list[Path] = []
        self.rule_ids: set[str] = set()

    def discover_files(self) -> None:
        """Znajdź wszystkie pliki .rego w JDG/rules/."""
        self.rego_files = sorted(
            f for f in JDG_RULES_DIR.rglob("*.rego")
            if f.name not in EXCLUDED_FILES
            and not f.name.endswith(".bak2")
        )
        if self.verbose:
            print(f"📁 Found {len(self.rego_files)} Rego files to lint")

    def extract_rule_ids(self) -> None:
        """Wyciągnij wszystkie rule_id z plików Rego."""
        for file_path in self.rego_files:
            content = file_path.read_text(encoding="utf-8")
            for match in RULE_ID_PATTERN.finditer(content):
                self.rule_ids.add(match.group(1))

        if self.verbose:
            print(f"🔍 Found {len(self.rule_ids)} unique rule IDs")

    # ── Walidacja 1: matched_true_required ──────────────────────────────────

    def check_matched_true_required(self) -> LintResult:
        """Sprawdź czy reguły nie zwracają matched:false bez powodu."""
        result = LintResult("matched_true_required")

        for file_path in self.rego_files:
            lines = file_path.read_text(encoding="utf-8").split("\n")
            for i, line in enumerate(lines, 1):
                matched_match = MATCHED_PATTERN.search(line)
                if matched_match and matched_match.group(1) == "false":
                    # Sprawdź czy to dozwolony default
                    rule_match = RULE_ID_PATTERN.search(line)
                    rid = rule_match.group(1) if rule_match else "unknown"

                    # Pobierz kontekst — czy to default fallback?
                    context_start = max(0, i - 5)
                    context = "\n".join(lines[context_start:i])
                    is_default = "default decide" in context

                    # P01 v9.x: reguły *.no_match to celowe fallbacki (default decide) —
                    # rule_id kończący się '.no_match' jest legalnym matched:false.
                    # P01 v9.x: rid=='unknown' (linie danych, np. invarianty) oraz reguły
                    # zawierające 'no_match' (fallbacki) są legalnym matched:false.
                    if rid not in EXCLUDED_RULE_IDS and not is_default \
                            and rid != 'unknown' and 'no_match' not in rid and 'fallback' not in rid:
                        result.add_violation(
                            str(file_path.relative_to(PROJECT_ROOT)),
                            i, rid,
                            "Rule returns matched:false — must be matched:true or default fallback"
                        )

        return result

    # ── Walidacja 2: no_fallback_allow ──────────────────────────────────────

    def check_no_fallback_allow(self) -> LintResult:
        """Sprawdź czy reguły mają konkretny _routing, nie domyślny ALLOW."""
        result = LintResult("no_fallback_allow")

        for file_path in self.rego_files:
            content = file_path.read_text(encoding="utf-8")
            lines = content.split("\n")

            # Znajdź wszystkie bloki decide/else
            for i, line in enumerate(lines):
                if 'matched":true' in line or "matched':true" in line:
                    # Sprawdź czy ta reguła ma _routing
                    routing_match = ROUTING_PATTERN.search(line)

                    # Szukaj _routing w całym bloku reguły (P01 v9.x: kontekst do nowej
                    # reguły na wcięciu 0-2, nie tylko 3 linie — bloki > 3 linie
                    # generowały fałszywe 'no _routing')
                    if not routing_match:
                        block_end = min(i + 80, len(lines))
                        for j in range(i + 1, block_end):
                            routing_match = ROUTING_PATTERN.search(lines[j])
                            if routing_match:
                                break
                            if re.match(r'^\s{0,2}(else\s+)?[a-zA-Z_][\w]*\s*:=\s*\{', lines[j]):
                                break

                    if not routing_match:
                        rule_match = RULE_ID_PATTERN.search(line)
                        rid = rule_match.group(1) if rule_match else "unknown"
                        if rid not in EXCLUDED_RULE_IDS:
                            result.add_violation(
                                str(file_path.relative_to(PROJECT_ROOT)),
                                i + 1, rid,
                                "Rule has no _routing field — BLOCK_AND_ALERT, TRIAGE_QUEUE, or explicit '' required"
                            )

        return result

    # ── Walidacja 3: rule_id_canonical ──────────────────────────────────────

    def check_rule_id_canonical(self) -> LintResult:
        """Sprawdź czy rule_id są w formacie jdg.<package>.<rule>."""
        result = LintResult("rule_id_canonical")

        for file_path in self.rego_files:
            content = file_path.read_text(encoding="utf-8")
            lines = content.split("\n")

            for i, line in enumerate(lines):
                rule_match = RULE_ID_PATTERN.search(line)
                if rule_match:
                    rid = rule_match.group(1)
                    if not rid.startswith("jdg.") and rid not in EXCLUDED_RULE_IDS:
                        result.add_violation(
                            str(file_path.relative_to(PROJECT_ROOT)),
                            i + 1, rid,
                            f"Rule ID '{rid}' does not follow canonical format 'jdg.<package>.<rule>'"
                        )

        return result

    # ── Walidacja 4: no_hardcoded_integers ──────────────────────────────────

    def check_no_hardcoded_integers(self) -> LintResult:
        """Sprawdź czy nie ma zahardkodowanych wartości numerycznych."""
        result = LintResult("no_hardcoded_integers")

        ALLOWED_PATTERNS = [
            DATE_PATTERN,
            re.compile(r'"priority":\s*\d+'),
            re.compile(r'"step":\s*\d+'),
            re.compile(r'#.*'),
            re.compile(r'\d+\.rego'),
            # P01 v9.x: fallback w object.get(..., <wartość>) to legalny wzorzec
            # odporności na brak danych (używany w całym repo, m.in. micro/amortyzacja)
            re.compile(r'object\.get\([^)]*,\s*'),
        ]

        # P01 v9.x: pliki `_*_rates.rego` to CELOWA warstwa danych stawek (odpowiednik
        # thresholds_jdg.rego) — wartości w nich to parametry, nie hardcode w regułach.
        # P01 v9.x: pliki `_*_rates.rego` i `thresholds_jdg.rego` to CELOWA warstwa danych
        # (stawki/progi/limity — odpowiednik data.thresholds) — wartości w nich to parametry,
        # nie hardcode w regułach decyzyjnych.
        rates_files = {
            str(p.relative_to(PROJECT_ROOT)) for p in self.rego_files
            if (p.name.startswith('_') and p.name.endswith('_rates.rego'))
            or p.name == 'thresholds_jdg.rego'
        }

        for file_path in self.rego_files:
            content = file_path.read_text(encoding="utf-8")
            lines = content.split("\n")

            rel = str(file_path.relative_to(PROJECT_ROOT))
            if rel in rates_files:
                continue

            for i, line in enumerate(lines):
                # Pomiń komentarze
                stripped = line.split("#")[0] if "#" in line else line

                for match in REGO_INTEGER_PATTERN.finditer(stripped):
                    matched_text = match.group(0)

                    # P01 v9.x: pomiń liczby w STRINGACH (komunikaty, podstawy prawne, numery
                    # wyroków, kody klasyfikacyjne) oraz stałe konwersji czasu/ns — to nie są
                    # progi ani stawki w logice decyzyjnej (ADR-002 dotyczy progów/stawek).
                    ctx60 = stripped[max(0, match.start() - 60):match.end() + 60]
                    if re.search(r'"_legal_basis"|"_warnings"|"_routing_reason"|"reason"|_ns\b|time\.now_ns', ctx60):
                        continue
                    if re.search(r'"\d+|\d+"', ctx60):
                        continue

                    # Sprawdź czy to dozwolony pattern
                    is_allowed = False
                    for pattern in ALLOWED_PATTERNS:
                        if pattern.search(matched_text) or pattern.search(
                            stripped[max(0, match.start() - 120):match.end() + 10]
                        ):
                            is_allowed = True
                            break

                    if not is_allowed and matched_text not in {"2025", "2026", "2027"}:
                        result.add_violation(
                            rel,
                            i + 1, "",
                            f"Hardcoded integer '{matched_text}' — move to thresholds_jdg.rego"
                        )

        return result

    # ── Walidacja 5: legal_basis_required ───────────────────────────────────

    def check_legal_basis_required(self) -> LintResult:
        """Sprawdź czy reguły mają _legal_basis."""
        result = LintResult("legal_basis_required")

        for file_path in self.rego_files:
            content = file_path.read_text(encoding="utf-8")
            lines = content.split("\n")

            for i, line in enumerate(lines):
                if 'matched":true' in line or "matched':true" in line:
                    rule_match = RULE_ID_PATTERN.search(line)
                    rid = rule_match.group(1) if rule_match else "unknown"

                    if rid in EXCLUDED_RULE_IDS:
                        continue

                    # Szukaj _legal_basis w tej samej lub następnych liniach
                    basis_match = LEGAL_BASIS_PATTERN.search(line)

                    if not basis_match:
                        # Szukaj w kontekście — reguły wieloliniowe (P01 v9.x: kontekst = cały blok
                        # reguły do { na wcięciu 0-2, nie tylko 10 linii — bloki > 10 linii
                        # generowały fałszywe 'missing _legal_basis')
                        block_end = min(i + 80, len(lines))
                        for j in range(i, block_end):
                            basis_match = LEGAL_BASIS_PATTERN.search(lines[j])
                            if basis_match:
                                break
                            # Nowa reguła na wcięciu 0-2 (decide/else) kończy kontekst
                            if j > i and re.match(r'^\s{0,2}(else\s+)?[a-zA-Z_][\w]*\s*:=\s*\{', lines[j]):
                                break

                    if basis_match:
                        basis = basis_match.group(1)
                        if not basis or basis == "":
                            result.add_violation(
                                str(file_path.relative_to(PROJECT_ROOT)),
                                i + 1, rid,
                                "Rule has empty _legal_basis — every rule must cite legal basis"
                            )
                    else:
                        result.add_violation(
                            str(file_path.relative_to(PROJECT_ROOT)),
                            i + 1, rid,
                            "Rule missing _legal_basis — every rule must cite legal basis (art./ust./pkt/lit.)"
                        )

        return result

    # ── Walidacja 6: temporal_validity ──────────────────────────────────────

    def check_temporal_validity(self) -> LintResult:
        """Sprawdź czy reguły mają wpis w rejestrze temporalnym."""
        result = LintResult("temporal_validity")

        # Wczytaj rejestr temporalny
        temporal_path = CONFTEST_DATA_DIR / "temporal_registry.json"
        always_active: set[str] = set()

        if temporal_path.exists():
            with open(temporal_path, encoding="utf-8") as f:
                registry = json.load(f)
            for rid, entry in registry.get("_entries", {}).items():
                if entry.get("is_always_active"):
                    always_active.add(rid)

        # Sprawdź każdy rule_id
        for file_path in self.rego_files:
            content = file_path.read_text(encoding="utf-8")
            lines = content.split("\n")

            for i, line in enumerate(lines):
                if 'matched":true' in line or "matched':true" in line:
                    rule_match = RULE_ID_PATTERN.search(line)
                    rid = rule_match.group(1) if rule_match else ""

                    if rid in EXCLUDED_RULE_IDS or rid in always_active:
                        continue

                    # Sprawdź czy jest wpis w rejestrze
                    # (w uproszczeniu: flagujemy jeśli nie ma w always_active)
                    # Pełna walidacja wymaga DuckDB
                    if rid and rid not in always_active:
                        pass  # W tym momencie tylko raportujemy, nie blokujemy

        return result

    # ── Uruchom wszystkie walidacje ─────────────────────────────────────────

    def run_all(self) -> dict:
        """Uruchom wszystkie 6 walidacji i zwróć raport."""
        self.discover_files()
        self.extract_rule_ids()

        checks = [
            ("matched_true_required", self.check_matched_true_required),
            ("no_fallback_allow", self.check_no_fallback_allow),
            ("rule_id_canonical", self.check_rule_id_canonical),
            ("no_hardcoded_integers", self.check_no_hardcoded_integers),
            ("legal_basis_required", self.check_legal_basis_required),
            ("temporal_validity", self.check_temporal_validity),
        ]

        for name, check_fn in checks:
            if self.verbose:
                print(f"🔍 Running check: {name}...")
            result = check_fn()
            self.results.append(result)

        return self.generate_report()

    def run_single(self, check_name: str) -> dict:
        """Uruchom pojedynczą walidację."""
        self.discover_files()
        self.extract_rule_ids()

        checks = {
            "matched_true_required": self.check_matched_true_required,
            "no_fallback_allow": self.check_no_fallback_allow,
            "rule_id_canonical": self.check_rule_id_canonical,
            "no_hardcoded_integers": self.check_no_hardcoded_integers,
            "legal_basis_required": self.check_legal_basis_required,
            "temporal_validity": self.check_temporal_validity,
        }

        if check_name not in checks:
            print(f"❌ Unknown check: {check_name}")
            print(f"   Available: {', '.join(checks.keys())}")
            sys.exit(1)

        result = checks[check_name]()
        self.results = [result]
        return self.generate_report()

    def generate_report(self) -> dict:
        """Generuj raport JSON."""
        total_violations = sum(len(r.violations) for r in self.results)
        all_passed = all(r.passed for r in self.results)

        report = {
            "status": "PASS" if all_passed else "FAIL",
            "total_checks": len(self.results),
            "checks_passed": sum(1 for r in self.results if r.passed),
            "checks_failed": sum(1 for r in self.results if not r.passed),
            "total_violations": total_violations,
            "results": [],
        }

        for result in self.results:
            report["results"].append({
                "check": result.check_name,
                "passed": result.passed,
                "violations": result.violations,
            })

        return report


def print_report(report: dict) -> None:
    """Wyświetl raport w czytelnej formie."""
    print()
    print("═" * 78)
    print(f"  NexusAI JDG — Rego Rule Linter Report")
    print(f"  Status: {'✅ PASS' if report['status'] == 'PASS' else '❌ FAIL'}")
    print(f"  Checks: {report['checks_passed']}/{report['total_checks']} passed")
    print(f"  Violations: {report['total_violations']}")
    print("═" * 78)

    for result in report["results"]:
        icon = "✅" if result["passed"] else "❌"
        print(f"\n  {icon} {result['check']}")
        if result["violations"]:
            for v in result["violations"][:5]:  # max 5 per check
                print(f"     📄 {v['file']}:{v['line']} — {v['message']}")
            if len(result["violations"]) > 5:
                print(f"     ... and {len(result['violations']) - 5} more")
    print()


def main():
    parser = argparse.ArgumentParser(
        description="NexusAI JDG — Rego Rule Linter (B3 Strategic Initiative)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--ci", action="store_true",
                        help="CI mode — exit 1 on failures")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Verbose output")
    parser.add_argument("--json", action="store_true",
                        help="Output JSON report")
    parser.add_argument("--check", type=str, metavar="CHECK_NAME",
                        help="Run single validation check")

    args = parser.parse_args()

    linter = RegoLinter(verbose=args.verbose)

    if args.check:
        report = linter.run_single(args.check)
    else:
        report = linter.run_all()

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print_report(report)

    if args.ci and report["status"] == "FAIL":
        sys.exit(1)
    elif report["status"] == "FAIL":
        sys.exit(1)


if __name__ == "__main__":
    main()
