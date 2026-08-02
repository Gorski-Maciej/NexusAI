#!/usr/bin/env python3
"""
NexusAI JDG — Hardcoded Values Audit & Migration Tool (R7, P28 Grand Finale)
Audyt skryptowy: lint no_hardcoded_integers + validate_rules → migracja do thresholds_jdg.rego.
Cel: 0 hardcoded wartości w regułach.
"""
import sys, os, json, re
from datetime import datetime
from pathlib import Path

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULES_DIR = os.path.join(BASE, "rules")
THRESHOLDS_FILE = os.path.join(RULES_DIR, "thresholds_jdg.rego")

HARDCODED_PATTERNS = [
    (r'(?<!thresholds\.jdg\.)(?<!thresholds\.)(?<!")(?<![\w.])(\d{4,})(?![\w.])(?!\s*//)', "large_integer"),
    (r'(?<!thresholds\.jdg\.)(?<!thresholds\.)\b0\.\d{2,3}\b(?!\s*//)', "decimal_rate"),
    (r'(?<!")(?<![\w/])(\d{2,3})\s*(?:dni|days|miesięcy|months|lat|years)(?![\w/])', "time_period"),
]

def scan_hardcoded_values(filepath):
    """Skanuj plik w poszukiwaniu hardcoded wartości."""
    with open(filepath, "r") as f:
        content = f.read()
    
    findings = []
    for pattern, category in HARDCODED_PATTERNS:
        for match in re.finditer(pattern, content, re.IGNORECASE):
            # Wyklucz komentarze
            line_start = content.rfind("\n", 0, match.start()) + 1
            line = content[line_start:content.find("\n", match.start())]
            if line.strip().startswith("#") or line.strip().startswith("//"):
                continue
            
            findings.append({
                "file": os.path.relpath(filepath, RULES_DIR),
                "value": match.group(0),
                "category": category,
                "line": content[:match.start()].count("\n") + 1,
                "context": line.strip()[:100]
            })
    
    return findings

def suggest_threshold_mapping(value, category):
    """Zaproponuj nazwę w thresholds_jdg.rego."""
    if category == "large_integer":
        return f"threshold_{value}"
    elif category == "decimal_rate":
        return f"rate_{str(value).replace('.', '_')}"
    elif category == "time_period":
        return f"period_{value}"
    return f"custom_{value}"

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Hardcoded Values Audit (R7, P28)           ║")
    print("║  Cel: 0 hardcoded → 100% w thresholds_jdg.rego           ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    # Skanuj wszystkie pliki rego
    all_findings = []
    for root, _, files in os.walk(RULES_DIR):
        for fname in files:
            if not fname.endswith(".rego"):
                continue
            filepath = os.path.join(root, fname)
            findings = scan_hardcoded_values(filepath)
            all_findings.extend(findings)
    
    # Grupuj wg kategorii
    by_category = {}
    for f in all_findings:
        cat = f["category"]
        if cat not in by_category:
            by_category[cat] = []
        by_category[cat].append(f)
    
    print(f"\n📊 Wyniki audytu:")
    print(f"   Przeskanowano plików: {len(set(f['file'] for f in all_findings))}")
    print(f"   Znaleziono hardcoded: {len(all_findings)}")
    
    for cat, items in by_category.items():
        unique_vals = len(set(i["value"] for i in items))
        print(f"   {cat}: {len(items)} wystąpień ({unique_vals} unikalnych wartości)")
    
    # Sprawdź istniejące thresholds
    with open(THRESHOLDS_FILE, "r") as f:
        thresholds_content = f.read()
    current_thresholds = len(re.findall(r'"[^"]+":\s*\d+', thresholds_content))
    print(f"\n   Istniejące progi w thresholds_jdg.rego: ~{current_thresholds}")
    
    # Generuj rekomendacje migracji
    print(f"\n📋 Rekomendacje migracji:")
    suggested = set()
    for f in all_findings[:10]:
        mapping = suggest_threshold_mapping(f["value"], f["category"])
        suggested.add(mapping)
        print(f"   {f['file']}:{f['line']} → data.thresholds.jdg.{mapping} = {f['value']}")
    
    if len(all_findings) > 10:
        print(f"   ... oraz {len(all_findings) - 10} innych")
    
    # KPI
    pct_migrated = (1 - len(all_findings) / max(len(all_findings) + current_thresholds, 1)) * 100
    print(f"\n📋 KPI: ~{current_thresholds} w thresholds, {len(all_findings)} do migracji")
    print("   Cel P28: 0 hardcoded wartości, ~300 progów w thresholds_jdg.rego")
    
    report = {
        "generated_at": datetime.now().isoformat(),
        "total_hardcoded": len(all_findings),
        "current_thresholds": current_thresholds,
        "target_thresholds": current_thresholds + len(set(f["value"] for f in all_findings)),
        "categories": {k: len(v) for k, v in by_category.items()},
        "findings": all_findings[:50]
    }
    
    report_path = os.path.join(BASE, "reports", "hardcoded_audit_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n📄 Report: {report_path}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
