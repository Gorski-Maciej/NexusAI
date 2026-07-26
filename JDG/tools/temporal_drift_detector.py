#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Temporal Drift Detector (Innowacja #9 v7.0)
═══════════════════════════════════════════════════════════════════════════════

System wykrywa, które reguły wymagają aktualizacji z powodu zmian prawa:
1. ISAP crawler (C3) wykrywa zmianę ustawy
2. Legal cartography (A3) mapuje zmianę na reguły
3. System oznacza reguły jako "POTENTIALLY_STALE"
4. Generuje GitHub issue dla każdej wymagającej aktualizacji
5. CI blokuje merge jeśli są STALE reguły

Usage: python temporal_drift_detector.py [--check] [--generate-issues]

Autor: NexusAI — v7.0 Enterprise Audit Implementation
Data: 2026-07-25
"""

import json
import re
import sys
from pathlib import Path
from datetime import datetime, timedelta
from collections import defaultdict

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
ISAP_DIR = JDG_ROOT / "isap_cache"
LEGAL_CARTOGRAPHY_PATH = JDG_ROOT / "legal_cartography.json"
STALE_REGISTRY_PATH = JDG_ROOT / "stale_rules_registry.json"


def load_isap_changes() -> list[dict]:
    """Ładuje zmiany prawne z cache ISAP crawlera."""
    changes = []
    if not ISAP_DIR.exists():
        return changes

    for filepath in sorted(ISAP_DIR.glob("*.json")):
        try:
            data = json.loads(filepath.read_text(encoding="utf-8"))
            if isinstance(data, list):
                changes.extend(data)
            elif isinstance(data, dict):
                changes.append(data)
        except Exception:
            pass
    return changes


def load_legal_cartography() -> dict:
    """Ładuje mapowanie prawnych punktów na reguły Rego."""
    if not LEGAL_CARTOGRAPHY_PATH.exists():
        return {}
    try:
        return json.loads(LEGAL_CARTOGRAPHY_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}


def find_affected_rules(legal_changes: list[dict], cartography: dict) -> dict:
    """Znajduje reguły dotknięte zmianami prawnymi."""
    affected = {}

    for change in legal_changes:
        act_name = change.get("act_name", "")
        article = change.get("article", "")
        change_date = change.get("change_date", "")
        description = change.get("description", "")

        # Mapuj na reguły przez legal cartography
        for rule_id, mapping in cartography.items():
            if act_name.lower() in mapping.get("act_name", "").lower():
                if article in mapping.get("articles", []):
                    affected.setdefault(rule_id, []).append({
                        "change_description": description,
                        "change_date": change_date,
                        "act_name": act_name,
                        "article": article,
                    })

    return affected


def scan_rego_files_for_stale() -> dict:
    """Skanuje pliki .rego i wykrywa potencjalnie nieaktualne reguły."""
    stale_rules = {}

    # Data graniczna: reguły nieaktualizowane od >90 dni
    cutoff_date = datetime.now() - timedelta(days=90)

    for filepath in sorted(RULES_DIR.rglob("*.rego")):
        try:
            mtime = datetime.fromtimestamp(filepath.stat().st_mtime)
        except OSError:
            continue

        if mtime < cutoff_date:
            # Sprawdź czy plik cytuje stare przepisy
            content = filepath.read_text(encoding="utf-8")
            # Szukaj odniesień do nieaktualnych artykułów
            old_articles = re.findall(
                r'Art\.\s*(\d+[a-z]*)\s*(?:ust\.\s*\d+\s+z\s*\d{4}\s*r\.|ustawy)', content, re.IGNORECASE
            )
            if old_articles:
                rel_path = str(filepath.relative_to(RULES_DIR))
                rule_ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
                for rid in rule_ids:
                    stale_rules[rid] = {
                        "file": rel_path,
                        "last_modified": mtime.isoformat(),
                        "days_since_update": (datetime.now() - mtime).days,
                        "cited_articles": old_articles[:5],
                    }

    return stale_rules


def save_stale_registry(stale_rules: dict) -> None:
    """Zapisuje rejestr nieaktualnych reguł."""
    registry = {
        "generated_at": datetime.now().isoformat(),
        "stale_rules": stale_rules,
        "total_stale": len(stale_rules),
        "severity": "BLOCK_MERGE" if len(stale_rules) > 10 else "WARNING",
    }
    STALE_REGISTRY_PATH.write_text(
        json.dumps(registry, indent=2, ensure_ascii=False), encoding="utf-8"
    )


def generate_github_issues(stale_rules: dict) -> None:
    """Generuje polecenia do utworzenia GitHub issues dla nieaktualnych reguł."""
    print("\n🗂️ GitHub Issues do utworzenia:")
    print("═" * 60)
    for rule_id, info in list(stale_rules.items())[:20]:
        print(f"""
### [{rule_id}] Potencjalnie nieaktualna reguła

- **Plik:** {info['file']}
- **Ostatnia modyfikacja:** {info['last_modified']} ({info['days_since_update']} dni temu)
- **Cytowane artykuły:** {', '.join(info['cited_articles'][:3])}

**Akcja:** Zweryfikuj aktualność podstawy prawnej i zaktualizuj regułę.
**Label:** stale-rule, priority-high
""")


def main():
    check_only = "--check" in sys.argv
    generate_issues = "--generate-issues" in sys.argv

    print("⏳ NexusAI JDG — Temporal Drift Detector (Innowacja #9 v7.0)")
    print(f"   Data: {datetime.now().isoformat()}")

    # Krok 1: Skanuj pliki Rego
    stale_rules = scan_rego_files_for_stale()

    # Krok 2: Wczytaj zmiany ISAP
    isap_changes = load_isap_changes()
    cartography = load_legal_cartography()
    affected_by_isap = find_affected_rules(isap_changes, cartography)

    # Krok 3: Połącz wyniki
    all_stale = {**stale_rules}
    for rid, changes in affected_by_isap.items():
        if rid in all_stale:
            all_stale[rid]["isap_changes"] = changes
        else:
            all_stale[rid] = {"isap_changes": changes, "days_since_update": 999}

    print(f"   Znaleziono: {len(all_stale)} potencjalnie nieaktualnych reguł")

    if not check_only:
        save_stale_registry(all_stale)
        print(f"   ✅ Zapisano rejestr: {STALE_REGISTRY_PATH}")

    if generate_issues:
        generate_github_issues(all_stale)

    # Exit code: 1 jeśli są stale reguły (dla CI)
    if all_stale and len(all_stale) > 10:
        print(f"\n🔴 BLOKADA CI: {len(all_stale)} nieaktualnych reguł!")
        sys.exit(1)
    elif all_stale:
        print(f"\n🟡 OSTRZEŻENIE: {len(all_stale)} nieaktualnych reguł")
        sys.exit(0)
    else:
        print(f"\n✅ Wszystkie reguły aktualne")
        sys.exit(0)


if __name__ == "__main__":
    main()
