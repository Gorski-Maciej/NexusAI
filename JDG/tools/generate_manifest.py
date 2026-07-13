#!/usr/bin/env python3
"""
NexusAI JDG — Manifest Generator
Auto-generuje JDG/MANIFEST.md z rzeczywistej zawartości plików Rego.
Parsuje reguły, liczy matched:true, weryfikuje zgodność z mapą kanoniczną.

Usage: python generate_manifest.py [--check]
  --check  Tylko sprawdza spójność, nie nadpisuje MANIFEST.md
"""

import os
import re
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"


def parse_rego_file(filepath: Path) -> list[dict]:
    """Parsuje plik .rego i zwraca listę reguł z metadanymi."""
    rules = []
    content = filepath.read_text(encoding="utf-8")

    # Znajdź wszystkie reguły z matched:true
    pattern = r'"matched"\s*:\s*true[^}]*"rule_id"\s*:\s*"([^"]+)"[^}]*"priority"\s*:\s*(\d+)'
    for match in re.finditer(pattern, content):
        rule_id = match.group(1)
        priority = int(match.group(2))

        # Wyciągnij _legal_basis
        legal_match = re.search(
            rf'"{re.escape(rule_id)}".*?"_legal_basis"\s*:\s*"([^"]*)"',
            content, re.DOTALL
        )
        legal_basis = legal_match.group(1) if legal_match else ""

        # Wyciągnij _routing
        routing_match = re.search(
            rf'"{re.escape(rule_id)}".*?"_routing"\s*:\s*"([^"]*)"',
            content, re.DOTALL
        )
        routing = routing_match.group(1) if routing_match else ""

        rules.append({
            "rule_id": rule_id,
            "priority": priority,
            "legal_basis": legal_basis,
            "routing": routing,
            "file": filepath.name,
        })

    return rules


def count_matched_true(filepath: Path) -> int:
    """Liczy reguły z matched:true w pliku."""
    content = filepath.read_text(encoding="utf-8")
    return len(re.findall(r'"matched"\s*:\s*true', content))


def collect_all_rules() -> dict:
    """Zbiera wszystkie reguły ze wszystkich plików .rego."""
    all_rules = defaultdict(list)
    total_files = 0
    total_rules = 0

    for filepath in sorted(RULES_DIR.rglob("*.rego")):
        rules = parse_rego_file(filepath)
        if rules:
            rel_path = str(filepath.relative_to(RULES_DIR))
            all_rules[rel_path] = rules
            total_files += 1
            total_rules += len(rules)

    return {
        "files": total_files,
        "rules": total_rules,
        "by_file": dict(all_rules),
    }


def generate_manifest(data: dict) -> str:
    """Generuje zawartość MANIFEST.md."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    lines = [
        "# 📋 JDG MANIFEST — Tracker Pokrycia Reguł vs Mapa Kanoniczna 38c",
        "",
        f"> **Auto-generowane:** {now}",
        f"> **Plików Rego:** {data['files']}",
        f"> **Reguł:** {data['rules']}",
        "> **Mapa kanoniczna:** `Plan OPA/38c_JDG_CANONICAL_MAP.md` (~779 reguł)",
        "",
        "---",
        "",
        "## 📊 REGUŁY PER PLIK",
        "",
        "| Plik | Reguł | BLOCK | TRIAGE |",
        "|------|:-----:|:-----:|:------:|",
    ]

    for filepath in sorted(data["by_file"].keys()):
        rules = data["by_file"][filepath]
        block_count = sum(1 for r in rules if r["routing"] == "BLOCK_AND_ALERT")
        triage_count = sum(1 for r in rules if r["routing"] == "TRIAGE_QUEUE")
        lines.append(f"| `rules/{filepath}` | {len(rules)} | {block_count} | {triage_count} |")

    lines.extend([
        f"| **RAZEM** | **{data['rules']}** | — | — |",
        "",
        "---",
        "",
        "## 📋 SZCZEGÓŁOWE REGUŁY",
        "",
    ])

    for filepath in sorted(data["by_file"].keys()):
        rules = data["by_file"][filepath]
        lines.append(f"### `rules/{filepath}` ({len(rules)} reguł)")
        lines.append("")
        lines.append("| Priorytet | Rule ID | Routing | Podstawa prawna |")
        lines.append("|:---------:|---------|:-------:|----------------|")

        for r in sorted(rules, key=lambda x: x["priority"]):
            routing_flag = "🔴 BLOCK" if r["routing"] == "BLOCK_AND_ALERT" else (
                "🟡 TRIAGE" if r["routing"] == "TRIAGE_QUEUE" else ""
            )
            legal_short = r["legal_basis"][:60] + "..." if len(r["legal_basis"]) > 60 else r["legal_basis"]
            lines.append(f"| {r['priority']} | `{r['rule_id']}` | {routing_flag} | {legal_short} |")

        lines.append("")

    lines.extend([
        "---",
        f"*Wygenerowano automatycznie — {now}*",
        "*Aktualizuj przez: `python JDG/tools/generate_manifest.py`*",
    ])

    return "\n".join(lines)


def main():
    check_only = "--check" in sys.argv

    print("🔍 Skanowanie plików Rego...")
    data = collect_all_rules()
    print(f"   Znaleziono: {data['files']} plików, {data['rules']} reguł")

    manifest_content = generate_manifest(data)
    manifest_path = JDG_ROOT / "MANIFEST.md"

    if check_only:
        print(f"✅ Sprawdzenie zakończone. MANIFEST.md NIE został nadpisany.")
        return 0

    manifest_path.write_text(manifest_content, encoding="utf-8")
    print(f"✅ MANIFEST.md zaktualizowany ({len(manifest_content)} bajtów)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
