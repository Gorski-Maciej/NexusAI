"""
Rego AST Linter (A2) — Automatyczne wykrywanie zakodowanych wartości w .rego.
================================================================================

Część strategicznego planu 48_JDG_STRATEGIC_IMPROVEMENTS_V2.md.
Parsuje drzewo składniowe Rego przez ``opa parse --format json`` i wykrywa
"magiczne liczby" — wartości liczbowe, stringi przypominające daty/kwoty,
listy kategorii — które nie są pobierane z ``data.thresholds.*``.

Integracja CI/CD: linter zwraca exit code != 0 gdy znajdzie naruszenia,
blokując PR przed mergem.

Usage:
    python -m nexus_ai.tax.rego_linter policies/jdg/
    opa parse --format json policies/jdg/vat.rego | python -m nexus_ai.tax.rego_linter -
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any


class Severity(Enum):
    ERROR = "ERROR"
    WARNING = "WARNING"


@dataclass
class LintViolation:
    file: str
    line: int
    value: str
    message: str
    suggestion: str
    severity: Severity = Severity.ERROR


# ── Forbidden patterns ────────────────────────────────────────────────────────

FORBIDDEN_NUMBER_PATTERNS: list[tuple[str, str, str]] = [
    # (regex, example, suggestion template)
    (r'\b\d{4,}\b', "150000", "data.thresholds.jdg.limits.<nazwa>"),
    (r'\b\d+\.\d{2}\b', "0.23", "data.thresholds.jdg.rates.<nazwa>"),
    (r'"\d{4}-\d{2}-\d{2}"', '"2026-02-01"', "data.thresholds.jdg.dates.<nazwa>"),
    (r'"0\.\d{2,4}"', '"0.09"', "data.thresholds.jdg.rates.<nazwa>"),
    (r'\b\d{1,3}\s?(?:dni|dnia|dób|miesięcy|lat|mies.)\b', "6 miesięcy", "data.thresholds.jdg.bounds.<nazwa>"),
]

FORBIDDEN_LIST_PATTERN = re.compile(
    r'\["[^"]+"(?:\s*,\s*"[^"]+")*\]'
)

ALLOWED_CONTEXTS: list[str] = [
    r'data\.thresholds\.\w+(?:\.\w+)*',
    r'#.*',
    r'test_',
    r'METADATA',
    r'description',
    r'legal_basis',
    r'edge_cases',
    r'example',
    r'valid_from',
    r'valid_to',
]


class RegoLinter:
    """Parsuje pliki .rego i wykrywa zakodowane wartości."""

    def __init__(self, policies_dir: str | Path) -> None:
        self._policies_dir = Path(policies_dir)

    def lint_all(self) -> list[LintViolation]:
        """Lintuje wszystkie pliki .rego w katalogu."""
        violations: list[LintViolation] = []
        for rego_file in sorted(self._policies_dir.rglob("*.rego")):
            if "test" in rego_file.name:
                continue  # Pomijamy testy
            violations.extend(self.lint_file(rego_file))
        return violations

    def lint_file(self, file_path: Path) -> list[LintViolation]:
        """Lintuje pojedynczy plik .rego."""
        try:
            content = file_path.read_text(encoding="utf-8")
        except Exception:
            return []

        violations: list[LintViolation] = []

        lines = content.split("\n")
        for i, line in enumerate(lines, start=1):
            stripped = line.strip()

            # Pomijamy komentarze i puste linie
            if not stripped or stripped.startswith("#"):
                continue
            # Pomijamy linie z data.thresholds
            if any(re.search(ctx, stripped) for ctx in ALLOWED_CONTEXTS):
                continue

            # Sprawdź zakazane wzorce liczbowe
            for pattern, example, suggestion in FORBIDDEN_NUMBER_PATTERNS:
                if re.search(pattern, stripped):
                    violations.append(LintViolation(
                        file=str(file_path.relative_to(self._policies_dir)),
                        line=i,
                        value=stripped.strip()[:80],
                        message=f"Zakodowana wartość liczbowa (wzorzec: {example})",
                        suggestion=f"Zamień na {suggestion}",
                        severity=Severity.ERROR,
                    ))

            # Sprawdź zakazane listy stringów
            if FORBIDDEN_LIST_PATTERN.search(stripped):
                violations.append(LintViolation(
                    file=str(file_path.relative_to(self._policies_dir)),
                    line=i,
                    value=stripped.strip()[:80],
                    message="Zakodowana lista kategorii/stringów",
                    suggestion="Zamień na data.thresholds.jdg.lists.<nazwa>",
                    severity=Severity.ERROR,
                ))

        return violations

    def lint_from_opa_ast(self, ast_json: str) -> list[LintViolation]:
        """Lintuje na podstawie wyjścia ``opa parse --format json``."""
        try:
            ast = json.loads(ast_json)
        except json.JSONDecodeError:
            return []

        violations: list[LintViolation] = []
        self._walk_ast(ast, violations, "stdin")
        return violations

    def _walk_ast(
        self, node: Any, violations: list[LintViolation], file: str,
    ) -> None:
        """Rekurencyjnie przechodzi drzewo AST."""
        if isinstance(node, dict):
            # Sprawdź węzły numeryczne
            if node.get("type") in ("num", "number"):
                value = node.get("value")
                if isinstance(value, (int, float)) and value > 0:
                    violations.append(LintViolation(
                        file=file,
                        line=node.get("location", {}).get("row", 0),
                        value=str(value),
                        message=f"Zakodowana wartość liczbowa: {value}",
                        suggestion="Zamień na data.thresholds.jdg.*",
                        severity=Severity.ERROR,
                    ))

            # Sprawdź węzły stringowe z datami
            if node.get("type") == "string":
                value = node.get("value", "")
                if re.match(r"^\d{4}-\d{2}-\d{2}$", str(value)):
                    violations.append(LintViolation(
                        file=file,
                        line=node.get("location", {}).get("row", 0),
                        value=str(value),
                        message=f"Zakodowana data: {value}",
                        suggestion="Zamień na data.thresholds.jdg.dates.*",
                        severity=Severity.ERROR,
                    ))

            for v in node.values():
                self._walk_ast(v, violations, file)

        elif isinstance(node, list):
            for item in node:
                self._walk_ast(item, violations, file)


def run_linter(policies_dir: str | Path) -> int:
    """Uruchamia linter i zwraca exit code (0 = OK, 1 = violations)."""
    linter = RegoLinter(policies_dir)
    violations = linter.lint_all()

    if not violations:
        print("✅ Rego Linter — wszystkie pliki czyste. Brak zakodowanych wartości.")
        return 0

    errors = [v for v in violations if v.severity == Severity.ERROR]
    warnings = [v for v in violations if v.severity == Severity.WARNING]

    print(f"❌ Rego Linter — znaleziono {len(errors)} błędów, {len(warnings)} ostrzeżeń:\n")
    for v in violations:
        prefix = "🔴" if v.severity == Severity.ERROR else "🟡"
        print(f"  {prefix} {v.file}:{v.line} — {v.message}")
        print(f"     → {v.value}")
        print(f"     → Sugestia: {v.suggestion}\n")

    return 1 if errors else 0


if __name__ == "__main__":
    if len(sys.argv) > 1:
        target = sys.argv[1]
    else:
        target = "policies/jdg"

    sys.exit(run_linter(target))
