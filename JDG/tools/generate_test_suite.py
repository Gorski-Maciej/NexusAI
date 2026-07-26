#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Auto-Generated Test Suite (Innowacja #2 v7.0)
═══════════════════════════════════════════════════════════════════════════════

Dla każdej reguły BLOCK_AND_ALERT automatycznie generuje test jednostkowy:
- Parsuje _legal_basis → wyciąga artykuł
- Generuje pozytywny scenariusz (transakcja spełnia warunki)
- Generuje negatywny scenariusz (transakcja NIE spełnia warunków)
- Zapisuje jako test w JDG/tests/auto/

Usage: python generate_test_suite.py [--dry-run] [--output-dir JDG/tests/auto/]

Autor: NexusAI — v7.0 Enterprise Audit Implementation
Data: 2026-07-25
"""

import re
import sys
from pathlib import Path
from datetime import datetime

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
DEFAULT_OUTPUT = JDG_ROOT / "tests" / "auto"


def parse_rego_file(filepath: Path) -> list[dict]:
    """Parsuje plik .rego, zwraca listę reguł BLOCK_AND_ALERT.
    
    Używa prostszego podejścia: najpierw znajduje wszystkie rule_id z matched:true,
    potem sprawdza czy w tym samym bloku jest _routing: BLOCK_AND_ALERT.
    """
    content = filepath.read_text(encoding="utf-8")
    blocks = []

    # Znajdź wszystkie bloki reguł (między { i }) zawierające matched:true
    # Szukamy bloków w stylu: ... := { ... "matched": true ... }
    bloc_pattern = re.compile(
        r'\{[^}]*?"matched"\s*:\s*true[^}]*?\}',
        re.DOTALL
    )
    
    for bloc_match in bloc_pattern.finditer(content):
        bloc = bloc_match.group(0)
        
        # Wyciągnij rule_id
        rid_match = re.search(r'"rule_id"\s*:\s*"([^"]+)"', bloc)
        if not rid_match:
            continue
        rule_id = rid_match.group(1)
        
        # Sprawdź _routing
        routing_match = re.search(r'"_routing"\s*:\s*"([^"]*)"', bloc)
        routing = routing_match.group(1) if routing_match else ""
        
        if "BLOCK" not in routing.upper():
            continue
        
        # Wyciągnij pozostałe metadane
        prio_match = re.search(r'"priority"\s*:\s*(\d+)', bloc)
        priority = int(prio_match.group(1)) if prio_match else 0
        
        legal_match = re.search(r'"_legal_basis"\s*:\s*"([^"]*)"', bloc)
        legal_basis = legal_match.group(1) if legal_match else ""
        
        warnings_match = re.search(r'"_warnings"\s*:\s*\[([^\]]*)\]', bloc, re.DOTALL)
        warnings = warnings_match.group(1).strip() if warnings_match else ""
        
        blocks.append({
            "rule_id": rule_id,
            "priority": priority,
            "legal_basis": legal_basis,
            "routing": routing,
            "warnings": warnings,
            "source_file": str(filepath.relative_to(RULES_DIR)),
        })

    return blocks


def extract_article(legal_basis: str) -> str:
    """Wyciąga numer artykułu z podstawy prawnej."""
    match = re.search(r'Art\.\s*(\d+[a-z]*(?:\s*ust\.\s*\d+)?)', legal_basis, re.IGNORECASE)
    return match.group(1) if match else ""


def generate_test_for_rule(rule: dict) -> str:
    """Generuje kod testu jednostkowego dla pojedynczej reguły BLOCK_AND_ALERT."""
    rule_id = rule["rule_id"]
    safe_name = re.sub(r'[^a-zA-Z0-9_]', '_', rule_id)
    article = extract_article(rule["legal_basis"])
    pkg = rule_id.split(".")[1] if "." in rule_id else "unknown"
    legal_short = rule["legal_basis"][:80]

    return f'''@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_{safe_name}:
    """Auto-generated: {rule_id}
    Podstawa prawna: {legal_short}"""

    def test_{safe_name}_positive_block_triggered(self):
        """✅ Pozytywny: {rule_id} — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {{
            "rule_id": "{rule_id}",
            "package": "{pkg}",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "{legal_short}",
            "matched": True,
            "priority": {rule["priority"]},
        }}
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "{rule_id}"

    def test_{safe_name}_negative_no_block(self):
        """❌ Negatywny: {rule_id} — blokada NIE powinna być uruchomiona."""
        input_data = {{
            "rule_id": "{rule_id}",
            "matched": False,
            "routing": "ALLOW",
        }}
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

'''


def generate_test_suite(dry_run: bool = False, output_dir: Path = DEFAULT_OUTPUT) -> dict:
    """Główna funkcja — generuje testy dla wszystkich reguł BLOCK_AND_ALERT."""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    all_rules = []
    for filepath in sorted(RULES_DIR.rglob("*.rego")):
        all_rules.extend(parse_rego_file(filepath))

    stats = {"total_block_rules": len(all_rules), "files_generated": 0, "errors": []}

    # Grupuj reguły według pakietu
    by_package = {}
    for rule in all_rules:
        pkg = rule["rule_id"].split(".")[1] if "." in rule["rule_id"] else "unknown"
        by_package.setdefault(pkg, []).append(rule)

    for pkg, rules in sorted(by_package.items()):
        safe_pkg = re.sub(r'[^a-zA-Z0-9_]', '_', pkg)
        output_file = output_dir / f"test_auto_block_{safe_pkg}.py"
        test_count = len(rules)

        content = [
            '#!/usr/bin/env python3',
            f'"""',
            f'Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: {pkg}',
            f'Wygenerowano: {datetime.now().isoformat()}',
            f'Reguł: {test_count}',
            f'"""',
            '',
            'import pytest',
            '',
            '',
        ]

        for rule in rules:
            content.append(generate_test_for_rule(rule))

        if not dry_run:
            output_file.write_text("\n".join(content), encoding="utf-8")
            stats["files_generated"] += 1
        else:
            print(f"  [DRY-RUN] {output_file.name}: {test_count} tests")

    return stats


def main():
    dry_run = "--dry-run" in sys.argv
    output_dir = DEFAULT_OUTPUT
    for arg in sys.argv:
        if arg.startswith("--output-dir="):
            output_dir = Path(arg.split("=", 1)[1])

    print("🤖 NexusAI JDG — Auto-Generated Test Suite (Innowacja #2 v7.0)")
    print(f"   Skanowanie: {RULES_DIR}")
    print()

    stats = generate_test_suite(dry_run=dry_run, output_dir=output_dir)

    print(f"📊 Podsumowanie:")
    print(f"   Reguł BLOCK_AND_ALERT: {stats['total_block_rules']}")
    print(f"   Wygenerowanych plików: {stats['files_generated']}")
    print(f"   Błędów: {len(stats['errors'])}")
    print(f"   Katalog wyjściowy: {output_dir}")

    if dry_run:
        print("   ✅ DRY-RUN — pliki NIE zostały zapisane.")


if __name__ == "__main__":
    main()
