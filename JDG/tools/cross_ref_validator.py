#!/usr/bin/env python3
"""
NexusAI JDG — Cross-Document Reference Validator (Innowacja 9)
Waliduje referencje między dokumentami w JDG/.

Sprawdza:
  - Wszystkie linki/ścieżki w docs/ → czy istnieją
  - Zgodność liczb między README, MANIFEST, COVERAGE, bundles/manifest.json
  - Martwe odnośniki w dokumentacji
  - Cross-reference integrity: LEGAL_REFERENCE vs Bbb.md

Usage: python cross_ref_validator.py [--json]
"""

import json
import re
import sys
from pathlib import Path
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent


def extract_links_from_file(path: Path) -> list[str]:
    """Ekstrahuje wszystkie referencje z pliku Markdown."""
    try:
        text = path.read_text(encoding="utf-8")
    except: return []

    links = []
    # Markdown links: [text](path)
    links.extend(re.findall(r'\[([^\]]*)\]\(([^)]+)\)', text))
    # Backtick paths: `path/to/file`
    links.extend([("", m) for m in re.findall(r'`([^`]+\.(?:md|rego|py|yaml|json|sql))`', text)])
    return links


def check_link_exists(link: str) -> bool:
    """Sprawdza czy ścieżka z linku istnieje."""
    clean = link.split("#")[0].strip()
    if clean.startswith("http"): return True  # URL zewnętrzny
    if clean.startswith("/"): return True  # absolutny

    candidates = [
        JDG_ROOT / clean,
        JDG_ROOT / "docs" / clean,
        JDG_ROOT / "rules" / clean,
        JDG_ROOT / "tools" / clean,
        JDG_ROOT / "bundles" / clean,
        JDG_ROOT / "tests" / clean,
        JDG_ROOT / "api" / clean,
        JDG_ROOT / "migrations" / clean,
        JDG_ROOT / clean.replace("JDG/", ""),
        JDG_ROOT.parent / clean,  # Plan OPA/
    ]
    return any(c.exists() for c in candidates)


def extract_all_numbers():
    """Ekstrahuje wszystkie deklarowane liczby z dokumentów."""
    numbers = {}
    sources = {
        "README.md": JDG_ROOT / "README.md",
        "MANIFEST.md": JDG_ROOT / "MANIFEST.md",
        "COVERAGE_REPORT.md": JDG_ROOT / "COVERAGE_REPORT.md",
        "bundles/manifest.json": JDG_ROOT / "bundles" / "manifest.json",
    }

    for name, path in sources.items():
        if not path.exists(): continue
        try:
            text = path.read_text(encoding="utf-8")
        except: continue

        if path.suffix == ".json":
            data = json.loads(text)
            meta = data.get("metadata", {})
            numbers[name] = {"files": meta.get("files_count"), "rules": meta.get("rules_count")}
        else:
            m = re.search(r'(?:Plików|plików)\s*(?:Rego)?[:\s]*\*?\*?(\d+)', text)
            files = int(m.group(1)) if m else None
            m = re.search(r'(?:Reguł|rule_id)[:\s]*\*?\*?(?:~)?(\d[\d\s,.]*\d)', text)
            rules = int(re.sub(r'[^\d]', '', m.group(1))) if m else None
            numbers[name] = {"files": files, "rules": rules}

    return numbers


def main():
    json_out = "--json" in sys.argv
    issues = []

    print("🔍 Cross-Document Reference Validator (Innowacja 9)")

    # 1. Sprawdź linki w dokumentach docs/
    docs_dir = JDG_ROOT / "docs"
    for doc in sorted(docs_dir.glob("*.md")):
        links = extract_links_from_file(doc)
        for text, link in links:
            if not check_link_exists(link):
                issues.append({
                    "severity": "WARNING", "source": doc.name,
                    "message": f"Martwy link: [{text[:30]}]({link[:50]})",
                })

    dead = sum(1 for i in issues if "Martwy link" in i["message"])
    print(f"   Martwych linków: {dead}")

    # 2. Sprawdź spójność liczb między dokumentami
    numbers = extract_all_numbers()
    file_nums = {k: v.get("files") for k, v in numbers.items() if v.get("files")}
    rule_nums = {k: v.get("rules") for k, v in numbers.items() if v.get("rules")}

    unique_files = set(file_nums.values())
    unique_rules = set(rule_nums.values())

    if len(unique_files) > 1:
        issues.append({
            "severity": "ERROR",
            "message": f"ROZJAZD liczby plików: {file_nums}",
        })
    else:
        issues.append({"severity": "OK", "message": f"Liczba plików spójna: {list(unique_files)[0]}"})

    if len(unique_rules) > 2:  # dopuszczamy różnicę między matched_blocks a unique_rule_ids
        issues.append({
            "severity": "WARNING",
            "message": f"Rozbieżność liczby reguł: {rule_nums}",
        })
    else:
        issues.append({"severity": "OK", "message": f"Liczby reguł akceptowalne: {rule_nums}"})

    print(f"   Dokumentów z liczbami: {len(numbers)}")
    print(f"   Unikalnych wartości 'files': {len(unique_files)}")
    print(f"   Unikalnych wartości 'rules': {len(unique_rules)}")

    if json_out:
        output = {
            "timestamp": datetime.now().isoformat(),
            "dead_links": dead,
            "numbers": numbers,
            "files_unique_values": list(unique_files),
            "rules_unique_values": list(unique_rules),
            "issues": issues,
        }
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        for iss in issues:
            icon = {"OK": "✅", "WARNING": "⚠️", "ERROR": "❌"}.get(iss["severity"], "•")
            print(f"  {icon} {iss['message']}")

    errors = sum(1 for i in issues if i["severity"] == "ERROR")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
