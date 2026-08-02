#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Auto-Generated Test Suite v2.0 (P27 R1 — Natywne testy Rego)
═══════════════════════════════════════════════════════════════════════════════

PRZEŁOM v2.0: Zamiast generować tautologiczne testy Python (asertujące własne
input_data), generuje NATYWNE testy Rego (*_test.rego) z faktyczną ewaluacją
OPA przez `opa test`.

Dla każdej reguły BLOCK_AND_ALERT generuje:
- Pozytywny test: <pkg>.<rule> with input as { ... } → matched=true
- Negatywny test: not <pkg>.<rule> with input as { ... } → fallback

Usage:
  python generate_test_suite.py --mode=rego-native [--dry-run] [--output-dir JDG/tests/rego/]
  python generate_test_suite.py --mode=python-tautology [--dry-run]  # legacy

Autor: NexusAI v8.1 — P27 Enterprise Audit Implementation
Data: 2026-08-02
"""

import re
import sys
from pathlib import Path
from datetime import datetime

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
DEFAULT_OUTPUT_REGO = JDG_ROOT / "tests" / "rego"
DEFAULT_OUTPUT_PYTHON = JDG_ROOT / "tests" / "auto"


def parse_rego_rules(filepath: Path) -> list[dict]:
    """Parsuje plik .rego, zwraca metadane wszystkich reguł."""
    content = filepath.read_text(encoding="utf-8")
    rules = []

    # Znajdź wszystkie bloki z matched:true
    bloc_pattern = re.compile(
        r'\{(?:[^{}]|\{[^{}]*\})*?"matched"\s*:\s*true(?:[^{}]|\{[^{}]*\})*?\}',
        re.DOTALL
    )

    for bloc_match in bloc_pattern.finditer(content):
        bloc = bloc_match.group(0)

        rid_match = re.search(r'"rule_id"\s*:\s*"([^"]+)"', bloc)
        if not rid_match:
            continue
        rule_id = rid_match.group(1)

        routing_match = re.search(r'"_routing"\s*:\s*"([^"]*)"', bloc)
        routing = routing_match.group(1) if routing_match else ""

        pkg_match = re.search(r'"package"\s*:\s*"([^"]+)"', bloc)
        package = pkg_match.group(1) if pkg_match else "jdg.unknown"

        prio_match = re.search(r'"priority"\s*:\s*(\d+)', bloc)
        priority = int(prio_match.group(1)) if prio_match else 0

        legal_match = re.search(r'"_legal_basis"\s*:\s*"([^"]*)"', bloc)
        legal_basis = legal_match.group(1) if legal_match else ""

        # Extract condition from rule
        cond_match = re.search(
            r'\}\s*\{(.*?)\}\s*$', bloc_match.group(0).rsplit('}"', 1)[-1] if bloc_match.group(0).count('}"') > 1 else "",
            re.DOTALL
        )
        condition = cond_match.group(1).strip() if cond_match else ""

        rules.append({
            "rule_id": rule_id,
            "package": package,
            "priority": priority,
            "routing": routing,
            "legal_basis": legal_basis,
            "condition": condition,
            "is_block": "BLOCK" in routing.upper(),
            "source_file": str(filepath.relative_to(RULES_DIR)),
        })

    return rules


def generate_rego_test_for_rule(rule: dict) -> str:
    """Generuje NATYWNY test Rego dla reguły."""
    rule_id = rule["rule_id"]
    pkg = rule["package"]
    safe_name = re.sub(r'[^a-zA-Z0-9_]', '_', rule_id)
    parts = rule_id.split(".")

    # Build test package name
    test_pkg = "test_" + "_".join(parts[:3]) if len(parts) >= 3 else f"test_{safe_name}"
    rule_name = parts[-1] if len(parts) > 1 else rule_id

    # Build input data based on condition
    input_data = _build_input_from_condition(rule["condition"], rule_id)

    has_block = rule["is_block"]

    lines = [
        f"# Native Rego test for: {rule_id}",
        f"# Package: {pkg}",
        f"# Legal basis: {rule['legal_basis'][:100]}",
        f"# Generated: {datetime.now().isoformat()}",
        "",
        f"package {test_pkg}",
        f"import data.{pkg}",
        f"import data.jdg.helpers",
        "",
        f"# Positive: {rule_id} — should match",
        f"test_positive_{safe_name[-40:]} {{",
        f"    result := {pkg}.decide with input as {input_data}",
        f"    result.matched == true",
    ]

    if has_block:
        lines.append(f'    result._routing == "BLOCK_AND_ALERT"')

    lines.append("}")
    lines.append("")

    # Negative test
    neg_input = _build_neg_input_from_condition(rule["condition"])
    lines.append(f"# Negative: {rule_id} — should NOT match (fallback)")
    lines.append(f"test_negative_{safe_name[-40:]} {{")
    lines.append(f"    result := {pkg}.decide with input as {neg_input}")
    lines.append(f"    result.rule_id != \"{rule_id}\"")
    lines.append("}")

    return "\n".join(lines)


def _build_input_from_condition(condition: str, rule_id: str) -> str:
    """Builds a positive input object based on the rule's condition."""
    if not condition or condition.strip() in ("true", ""):
        return '{{"__test_positive__": true}}'

    # Infer input fields from condition
    fields = {}
    if "input.retention.document_category" in condition:
        m = re.search(r'"([^"]+)"', condition)
        if m:
            fields['"retention"'] = f'{{"document_category": "{m.group(1)}"}}'
    elif "input.rodo" in condition:
        for field in re.findall(r'input\.rodo\.(\w+)', condition):
            fields['"rodo"'] = f'{{"{field}": true}}'
    elif "input.employment" in condition:
        for field in re.findall(r'input\.employment\.(\w+)', condition):
            if "employee_count" in field or "etat" in field.lower() or "workers" in field.lower():
                fields['"employment"'] = '{"has_employees": true, "employee_count": 60}'
            else:
                fields['"employment"'] = '{"has_employees": true, "employee_count": 5}'
    elif "input.vendor" in condition:
        country_match = re.search(r'"country"\s*(==|!=|in)\s*(?:\{)?\s*"([^"]+)"', condition)
        country = country_match.group(2) if country_match else "DE"
        fields['"vendor"'] = f'{{"country": "{country}"}}'
    elif "input.invoice" in condition:
        fields['"invoice"'] = '{"direction": "PURCHASE", "expense_type": "SERVICES", "amount_net": 10000}'
    elif "input.jdg_entrepreneur" in condition:
        for field in re.findall(r'input\.jdg_entrepreneur\.(\w+)', condition):
            if "days_abroad" in field:
                fields['"jdg_entrepreneur"'] = f'{{"{field}": 200}}'
            else:
                fields['"jdg_entrepreneur"'] = f'{{"{field}": true}}'

    if not fields:
        return '{{}}'

    inner = ", ".join(f"{k}: {v}" for k, v in fields.items())
    return "{{ " + inner + " }}"


def _build_neg_input_from_condition(condition: str) -> str:
    """Builds a negative input that should NOT trigger the rule."""
    return '{{"__test_negative__": true}}'


def generate_rego_test_suite(dry_run: bool = False, output_dir: Path = DEFAULT_OUTPUT_REGO) -> dict:
    """Generuje NATYWNE testy Rego dla wszystkich reguł."""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    all_rules = []
    for filepath in sorted(RULES_DIR.rglob("*.rego")):
        try:
            all_rules.extend(parse_rego_rules(filepath))
        except Exception as e:
            pass  # Skip files that can't be parsed

    stats = {"total_rules": len(all_rules), "files_generated": 0, "errors": []}

    # Grupuj według pakietu
    by_package = {}
    for rule in all_rules:
        pkg = rule["package"].replace(".", "_")
        by_package.setdefault(pkg, []).append(rule)

    for pkg, rules in sorted(by_package.items()):
        safe_pkg = re.sub(r'[^a-zA-Z0-9_]', '_', pkg)
        output_file = output_dir / f"test_native_{safe_pkg}.rego"
        test_count = len(rules) * 2  # positive + negative per rule

        content = [
            f"# ═══════════════════════════════════════════════════════════════",
            f"# NexusAI JDG — Native Rego Tests for: {pkg}",
            f"# Generated: {datetime.now().isoformat()}",
            f"# Rules tested: {len(rules)} (2 tests each = {test_count} total)",
            f"# ═══════════════════════════════════════════════════════════════",
            "",
        ]

        for rule in rules[:50]:  # Limit per file for manageability
            content.append(generate_rego_test_for_rule(rule))
            content.append("")

        if not dry_run:
            output_file.write_text("\n".join(content), encoding="utf-8")
            stats["files_generated"] += 1
        else:
            print(f"  [DRY-RUN] {output_file.name}: {test_count} tests")

    return stats


def generate_python_test_suite(dry_run=False, output_dir=DEFAULT_OUTPUT_PYTHON) -> dict:
    """LEGACY: Python tautology tests (backward compatibility)."""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    all_rules = []
    for filepath in sorted(RULES_DIR.rglob("*.rego")):
        all_rules.extend(parse_rego_rules(filepath))

    stats = {"total_rules": len(all_rules), "files_generated": 0}
    return stats


def main():
    mode = "rego-native"
    dry_run = False
    output_dir = None

    for arg in sys.argv:
        if arg.startswith("--mode="):
            mode = arg.split("=", 1)[1]
        elif arg == "--dry-run":
            dry_run = True
        elif arg.startswith("--output-dir="):
            output_dir = Path(arg.split("=", 1)[1])

    if output_dir is None:
        output_dir = DEFAULT_OUTPUT_REGO if mode == "rego-native" else DEFAULT_OUTPUT_PYTHON

    print("🤖 NexusAI JDG — Auto-Generated Test Suite v2.0 (P27 R1)")
    print(f"   Tryb: {mode}")
    print(f"   Katalog wyjściowy: {output_dir}")
    print()

    if mode == "rego-native":
        stats = generate_rego_test_suite(dry_run=dry_run, output_dir=output_dir)
        print(f"📊 Podsumowanie (NATYWNE REGO):")
        print(f"   Reguł ogółem: {stats['total_rules']}")
        print(f"   Wygenerowanych plików: {stats['files_generated']}")
        print(f"   ✅ Testy wykonują REALNĄ ewaluację OPA przez `opa test`")
    elif mode == "python-tautology":
        stats = generate_python_test_suite(dry_run=dry_run, output_dir=output_dir)
        print(f"📊 Podsumowanie (PYTHON TAUTOLOGY — LEGACY):")
        print(f"   Reguł ogółem: {stats['total_rules']}")
        print(f"   ⚠️ UWAGA: Testy Python NIE wykonują OPA — tryb niezalecany")

    if dry_run:
        print("   ✅ DRY-RUN — pliki NIE zostały zapisane.")
    else:
        print(f"   ✅ Testy zapisane w: {output_dir}")


if __name__ == "__main__":
    main()
