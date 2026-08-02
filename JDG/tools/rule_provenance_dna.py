#!/usr/bin/env python3
"""
NexusAI JDG — Rule Provenance DNA (Innovation #13, P28 Grand Finale)
Kazda reguła z metadanymi: kto (autor), kiedy (data), dlaczego (uzasadnienie),
na podstawie czego (legal_basis + źródło).
Rozszerza standardowy werdykt 25-polowy (ADR-004).
"""
import sys, os, json, re
from datetime import datetime
from pathlib import Path

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULES_DIR = os.path.join(BASE, "rules")

PROVENANCE_TEMPLATE = """    "_provenance": {
        "author": "{author}",
        "created": "{created}",
        "last_modified": "{last_modified}",
        "change_reason": "{change_reason}",
        "legal_source": "{legal_source}",
        "legal_source_url": "{legal_source_url}",
        "review_status": "{review_status}",
        "reviewed_by": "{reviewed_by}",
        "review_date": "{review_date}",
        "dna_hash": "{dna_hash}",
        "dependencies": [{dependencies}],
        "test_coverage": {test_coverage}
    },"""

def compute_dna_hash(rule_block):
    """Oblicz hash DNA reguły na podstawie legal_basis, rule_id, author."""
    import hashlib
    content = f"{rule_block}"
    return hashlib.sha256(content.encode()).hexdigest()[:16]

def extract_current_metadata(filepath):
    """Ekstrahuj obecne metadane z pliku rego."""
    with open(filepath, "r") as f:
        content = f.read()
    
    rules = []
    rule_blocks = re.split(r'\n(?:else\s+)?:=', content)
    
    for block in rule_blocks:
        rule_id_match = re.search(r'"rule_id"\s*:\s*"([^"]*)"', block)
        legal_basis_match = re.search(r'"_legal_basis"\s*:\s*"([^"]*)"', block)
        warnings_match = re.search(r'"_warnings"\s*:\s*\[(.*?)\]', block, re.DOTALL)
        routing_match = re.search(r'"_routing"\s*:\s*"([^"]*)"', block)
        
        rule_id = rule_id_match.group(1) if rule_id_match else "unknown"
        
        rules.append({
            "rule_id": rule_id,
            "has_legal_basis": legal_basis_match is not None,
            "legal_basis": legal_basis_match.group(1) if legal_basis_match else "",
            "has_warnings": warnings_match is not None,
            "routing": routing_match.group(1) if routing_match else "",
            "has_provenance": "_provenance" in block,
            "dna_hash": compute_dna_hash(block)
        })
    
    return rules

def generate_provenance_report():
    """Wygeneruj raport DNA dla wszystkich reguł."""
    all_dna = []
    
    for root, _, files in os.walk(RULES_DIR):
        for f in files:
            if not f.endswith(".rego"):
                continue
            filepath = os.path.join(root, f)
            try:
                rules = extract_current_metadata(filepath)
                for r in rules:
                    r["file"] = os.path.relpath(filepath, RULES_DIR)
                all_dna.extend(rules)
            except Exception as e:
                print(f"⚠️  {filepath}: {e}")
    
    return all_dna

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Rule Provenance DNA v1.0                    ║")
    print("║  Innovation #13: Traceable Rule Origin (P28 Grand Finale) ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    dna = generate_provenance_report()
    
    total = len(dna)
    with_provenance = sum(1 for r in dna if r["has_provenance"])
    with_legal = sum(1 for r in dna if r["has_legal_basis"])
    with_warnings = sum(1 for r in dna if r["has_warnings"])
    
    print(f"\n📊 DNA Report:")
    print(f"   Total rules: {total}")
    print(f"   With provenance: {with_provenance} ({with_provenance/max(total,1)*100:.1f}%)")
    print(f"   With legal_basis: {with_legal} ({with_legal/max(total,1)*100:.1f}%)")
    print(f"   With warnings: {with_warnings} ({with_warnings/max(total,1)*100:.1f}%)")
    print(f"   Missing provenance: {total - with_provenance}")
    
    # KPI
    provenance_pct = with_provenance / max(total, 1) * 100
    print(f"\n📋 KPI: {provenance_pct:.1f}% reguł z DNA")
    print("   Cel P28: 100% reguł z provenance DNA (autor, data, legal_basis)")
    
    # Save report
    report = {
        "generated_at": datetime.now().isoformat(),
        "total_rules": total,
        "with_provenance": with_provenance,
        "with_legal_basis": with_legal,
        "with_warnings": with_warnings,
        "provenance_pct": provenance_pct,
        "rules": dna
    }
    
    report_path = os.path.join(BASE, "reports", "provenance_dna_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n📄 Report: {report_path}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
