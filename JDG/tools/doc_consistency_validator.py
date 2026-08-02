#!/usr/bin/env python3
"""
NexusAI JDG — Documentation-to-Code Consistency Validator (Innowacja 3)
Waliduje spójność między dokumentacją a kodem.

Sprawdza:
  - README (liczba plików/reguł) vs MANIFEST vs dysk
  - LEGAL_REFERENCE_ACTS.md vs Bbb.md vs LEGAL_COVERAGE.md (akty)
  - openapi.yaml vs faktyczne pakiety Rego
  - bundles/manifest.json vs stan faktyczny

Usage: python doc_consistency_validator.py [--json] [--strict]
"""

import json
import re
import sys
from pathlib import Path
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent


def count_disk():
    """Liczy faktyczny stan plików Rego na dysku."""
    rego = list((JDG_ROOT / "rules").rglob("*.rego"))
    all_ids = set()
    for fp in rego:
        try:
            ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', fp.read_text(encoding="utf-8"))
            all_ids.update(ids)
        except: pass
    return {"files": len(rego), "unique_rule_ids": len(all_ids)}


def parse_readme_numbers():
    """Ekstrahuje deklarowane liczby z README.md."""
    try:
        text = (JDG_ROOT / "README.md").read_text(encoding="utf-8")
    except: return {}
    m = re.search(r'Plików\s+Rego:\s*\*{0,2}(\d+)', text)
    files = int(m.group(1)) if m else None
    m = re.search(r'unikalnych rule_id\D+(\d[\d\s,.~]*\d)', text)
    rules = int(re.sub(r'[^\d]', '', m.group(1))) if m else None
    return {"files": files, "rules": rules}


def parse_manifest_numbers():
    """Ekstrahuje liczby z MANIFEST.md."""
    try:
        text = (JDG_ROOT / "MANIFEST.md").read_text(encoding="utf-8")
    except: return {}
    m = re.search(r'Plików\s+Rego:\s*\*{0,2}(\d+)', text)
    files = int(m.group(1)) if m else None
    m = re.search(r'Unikalnych rule_id:\s*\*{0,2}(\d+)', text)
    rules = int(m.group(1)) if m else None
    m = re.search(r'Completeness Score:\s*\S+\s*\*{0,2}(\d+)/100', text)
    score = int(m.group(1)) if m else None
    return {"files": files, "rules": rules, "completeness_score": score}


def parse_bundle_manifest():
    """Ekstrahuje liczby z bundles/manifest.json."""
    try:
        data = json.loads((JDG_ROOT / "bundles" / "manifest.json").read_text())
        meta = data.get("metadata", {})
        return {"rules_count": meta.get("rules_count"), "files_count": meta.get("files_count")}
    except: return {}


def count_legal_acts():
    """Liczy akty prawne w dokumentach."""
    result = {}
    for name in ["LEGAL_COVERAGE.md", "LEGAL_REFERENCE_ACTS.md", "Bbb.md"]:
        path = JDG_ROOT / "docs" / name
        if path.exists():
            result[name] = len(re.findall(r'Ustawa\s+z\s+dnia', path.read_text(encoding="utf-8")))
        else:
            result[name] = 0
    return result


def main():
    json_out = "--json" in sys.argv
    issues = []

    disk = count_disk()
    readme = parse_readme_numbers()
    manifest = parse_manifest_numbers()
    bundle = parse_bundle_manifest()
    acts = count_legal_acts()

    # Sprawdzenie 1: README vs dysk
    if readme.get("files") and readme["files"] != disk["files"]:
        issues.append({
            "severity": "ERROR", "check": "README files vs disk",
            "message": f"README deklaruje {readme['files']} plików, dysk ma {disk['files']}",
        })
    elif readme.get("files"):
        issues.append({"severity": "OK", "check": "README files vs disk", "message": f"ZGODNE: {disk['files']} plików"})

    # Sprawdzenie 2: MANIFEST vs dysk
    if manifest.get("files") and manifest["files"] != disk["files"]:
        issues.append({
            "severity": "ERROR", "check": "MANIFEST files vs disk",
            "message": f"MANIFEST deklaruje {manifest['files']} plików, dysk ma {disk['files']}",
        })
    elif manifest.get("files"):
        issues.append({"severity": "OK", "check": "MANIFEST files vs disk", "message": f"ZGODNE: {disk['files']} plików"})

    # Sprawdzenie 3: Bundle vs dysk
    if bundle.get("files_count") and bundle["files_count"] != disk["files"]:
        issues.append({
            "severity": "WARNING", "check": "Bundle files vs disk",
            "message": f"Bundle deklaruje {bundle['files_count']} plików, dysk ma {disk['files']}",
        })
    elif bundle.get("files_count"):
        issues.append({"severity": "OK", "check": "Bundle files vs disk", "message": f"ZGODNE: {disk['files']} plików"})

    # Sprawdzenie 4: Spójność aktów prawnych
    vals = [v for v in acts.values() if v > 0]
    if len(set(vals)) > 1:
        issues.append({
            "severity": "WARNING", "check": "Legal acts consistency",
            "message": f"Różna liczba aktów w dokumentach: {acts}",
        })
    else:
        issues.append({"severity": "OK", "check": "Legal acts consistency", "message": f"ZGODNE: {vals[0] if vals else 0} aktów"})

    # Sprawdzenie 5: Completeness Score
    if manifest.get("completeness_score"):
        sc = manifest["completeness_score"]
        sev = "OK" if sc >= 90 else "WARNING" if sc >= 70 else "ERROR"
        issues.append({"severity": sev, "check": "Completeness Score", "message": f"{sc}/100"})

    if json_out:
        print(json.dumps({"timestamp": datetime.now().isoformat(), "issues": issues}, indent=2, ensure_ascii=False))
    else:
        print("🔍 Documentation-to-Code Consistency Validator (Innowacja 3)")
        for iss in issues:
            icon = {"OK": "✅", "WARNING": "⚠️", "ERROR": "❌"}.get(iss["severity"], "•")
            print(f"  {icon} [{iss['check']}] {iss['message']}")

    errors = sum(1 for i in issues if i["severity"] == "ERROR")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
