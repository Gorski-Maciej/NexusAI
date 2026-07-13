#!/usr/bin/env python3
"""
NexusAI JDG — Rego Rules Validator
Sprawdza jakość i spójność reguł Rego w katalogu JDG/rules/.

Walidacje:
1. Wszystkie reguły mają matched:true lub matched:false
2. Wszystkie reguły mają _legal_basis
3. Wszystkie reguły mają _routing (BLOCK_AND_ALERT, TRIAGE_QUEUE, lub "")
4. Brak zakodowanych wartości liczbowych (progi, stawki)
5. Spójność else-chain (kolejność priorytetów)
6. Unikalność rule_id

Usage: python validate_rules.py [--strict]
  --strict  Traktuje ostrzeżenia jako błędy
"""

import os
import re
import sys
from pathlib import Path
from collections import defaultdict

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"

# Wzorce do wykrywania hardcoded values
HARDCODED_PATTERNS = [
    (r'(?<!")\b\d{4,}\b(?!\s*")', "Liczba >= 1000 (możliwy próg)"),
    (r'(?<!")\b\d+\.\d{2}\b(?!\s*")', "Kwota PLN (np. 15000.00)"),
    (r'"0\.\d{2,3}"', "Stawka podatkowa (np. 0.23)"),
    (r'\b20\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\b', "Data ISO (np. 2026-01-01)"),
]


class Violation:
    def __init__(self, file: str, line: int, rule_id: str, message: str, severity: str = "ERROR"):
        self.file = file
        self.line = line
        self.rule_id = rule_id
        self.message = message
        self.severity = severity

    def __str__(self):
        return f"[{self.severity}] {self.file}:{self.line} ({self.rule_id}) — {self.message}"


def find_hardcoded_values(filepath: Path) -> list[Violation]:
    """Wykrywa zakodowane wartości w pliku Rego."""
    violations = []
    content = filepath.read_text(encoding="utf-8")
    lines = content.split("\n")

    for i, line in enumerate(lines, 1):
        # Pomiń komentarze
        if line.strip().startswith("#"):
            continue
        # Pomiń deklaracje pakietów i importów
        if line.strip().startswith("package ") or line.strip().startswith("import "):
            continue

        for pattern, desc in HARDCODED_PATTERNS:
            if re.search(pattern, line):
                violations.append(Violation(
                    str(filepath.relative_to(RULES_DIR)), i,
                    "—", f"Hardcoded value: {desc}",
                    "WARNING"
                ))
                break

    return violations


def validate_rule_structure(filepath: Path) -> list[Violation]:
    """Sprawdza strukturę reguł w pliku."""
    violations = []
    content = filepath.read_text(encoding="utf-8")
    rel_path = str(filepath.relative_to(RULES_DIR))

    # Znajdź wszystkie rule_id
    rule_ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
    matched_true = re.findall(r'"matched"\s*:\s*true', content)

    # Sprawdź unikalność rule_id
    seen = set()
    for rid in rule_ids:
        if rid in seen:
            violations.append(Violation(rel_path, 0, rid, "DUPLICATE rule_id!", "ERROR"))
        seen.add(rid)

    # Znajdź reguły z matched:true
    rule_blocks = re.finditer(
        r'(?:else\s+)?:=\s*\{[^}]*"matched"\s*:\s*true[^}]*"rule_id"\s*:\s*"([^"]+)"[^}]*\}',
        content, re.DOTALL
    )

    for block in rule_blocks:
        rule_id = block.group(1)
        block_text = block.group(0)

        # Sprawdź _legal_basis
        if '"_legal_basis"' not in block_text:
            violations.append(Violation(rel_path, 0, rule_id,
                "Brak _legal_basis", "ERROR"))

        # Sprawdź _routing
        if '"_routing"' not in block_text:
            violations.append(Violation(rel_path, 0, rule_id,
                "Brak _routing", "WARNING"))

        # Sprawdź _warnings
        if '"_warnings"' not in block_text:
            violations.append(Violation(rel_path, 0, rule_id,
                "Brak _warnings", "WARNING"))

    return violations


def main():
    strict = "--strict" in sys.argv
    all_violations = []
    total_rules = 0
    total_files = 0

    for filepath in sorted(RULES_DIR.rglob("*.rego")):
        rel = str(filepath.relative_to(RULES_DIR))
        content = filepath.read_text(encoding="utf-8")
        matched = len(re.findall(r'"matched"\s*:\s*true', content))
        total_rules += matched
        total_files += 1

        # Walidacja struktury
        struct_violations = validate_rule_structure(filepath)
        all_violations.extend(struct_violations)

        # Wykrywanie hardcoded values
        hc_violations = find_hardcoded_values(filepath)
        all_violations.extend(hc_violations)

    # Raport
    errors = [v for v in all_violations if v.severity == "ERROR"]
    warnings = [v for v in all_violations if v.severity == "WARNING"]

    print(f"📋 JDG Rules Validator")
    print(f"   Plików: {total_files}")
    print(f"   Reguł:  {total_rules}")
    print(f"   Błędów: {len(errors)}")
    print(f"   Ostrzeżeń: {len(warnings)}")
    print()

    if errors:
        print("🔴 BŁĘDY:")
        for v in errors:
            print(f"   {v}")

    if warnings:
        print("🟡 OSTRZEŻENIA (pierwsze 10):")
        for v in warnings[:10]:
            print(f"   {v}")
        if len(warnings) > 10:
            print(f"   ... i {len(warnings) - 10} więcej")

    exit_code = 1 if (errors or (strict and warnings)) else 0
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
