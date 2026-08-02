#!/usr/bin/env python3
"""
NexusAI JDG — ADR Auto-Proposer (Innowacja 4)
Monitoruje zmiany w rules/ i proponuje nowe ADR gdy wykryje wzorce
rozbieżne z istniejącymi ADR-ami.

Usage: python adr_auto_proposer.py [--json]
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
ARCHITECTURE_PATH = JDG_ROOT / "docs" / "ARCHITECTURE.md"


def extract_existing_adrs():
    """Ekstrahuje istniejące ADR-y z ARCHITECTURE.md."""
    try:
        text = ARCHITECTURE_PATH.read_text(encoding="utf-8")
    except:
        return set()
    return set(re.findall(r'ADR-(\d+)', text))


def analyze_rules_structure():
    """Analizuje strukturę rules/ pod kątem potencjalnych ADR."""
    findings = []
    subdirs = set()
    file_count = 0
    rules_with_hardcoded = 0
    rules_with_routing = 0
    packages_with_conflicts = defaultdict(list)
    
    for fp in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = fp.read_text(encoding="utf-8")
        except: continue
        
        rel = str(fp.relative_to(RULES_DIR))
        subdirs.add(str(fp.parent.relative_to(RULES_DIR)))
        file_count += 1
        
        # Wykrywaj hardcoded values
        hardcoded = re.findall(r'(?<!["\w])(?:200000|15000|30000|85528|120000|0\.\d{2})(?!["\w])', content)
        if hardcoded:
            rules_with_hardcoded += 1
        
        # Wykrywaj routing
        if re.search(r'"_routing"\s*:\s*"(?:BLOCK_AND_ALERT|TRIAGE_QUEUE)"', content):
            rules_with_routing += 1
        
        # Wykrywaj konflikty per pakiet
        pkg_match = re.search(r'package\s+(\S+)', content)
        if pkg_match:
            pkg = pkg_match.group(1)
            packages_with_conflicts[pkg].append(rel)
    
    existing_adrs = extract_existing_adrs()
    
    # Propozycje ADR na podstawie analizy
    proposals = []
    
    # ADR dla hardcoded values
    if rules_with_hardcoded > 50:
        proposals.append({
            "id": max(int(x) for x in existing_adrs) + 1 if existing_adrs else 15,
            "title": f"ADR-XXX: Hardcoded Values Migration Progress",
            "trigger": f"Wykryto ~{rules_with_hardcoded} plików z zakodowanymi wartościami",
            "decision": "Przyspieszyć migrację do data.thresholds zgodnie z ADR-002",
            "impact": f"{rules_with_hardcoded} plików wymaga migracji",
            "priority": "HIGH",
        })
    
    # ADR dla struktury katalogów
    if len(subdirs) > 20:
        proposals.append({
            "id": max(int(x) for x in existing_adrs) + 2 if existing_adrs else 16,
            "title": "ADR-XXX: Rules Directory Structure Convention",
            "trigger": f"Wykryto {len(subdirs)} podkatalogów w rules/",
            "decision": "Ustalić konwencję nazewnictwa i maksymalną głębokość katalogów",
            "impact": f"Organizacja {file_count} plików w {len(subdirs)} katalogach",
            "priority": "MEDIUM",
        })
    
    # ADR dla routingu
    if rules_with_routing > 100:
        proposals.append({
            "id": max(int(x) for x in existing_adrs) + 3 if existing_adrs else 17,
            "title": "ADR-XXX: Routing Strategy Review",
            "trigger": f"{rules_with_routing} plików używa BLOCK_AND_ALERT/TRIAGE_QUEUE",
            "decision": "Przegląd strategii routingu i progów krytyczności",
            "impact": "Wpływa na proces decyzyjny i kolejki triage",
            "priority": "MEDIUM",
        })
    
    return {
        "existing_adrs": sorted(existing_adrs, key=int),
        "total_files": file_count,
        "subdirectories": len(subdirs),
        "hardcoded_files": rules_with_hardcoded,
        "routing_files": rules_with_routing,
        "proposals": proposals,
    }


def main():
    print("🤖 ADR Auto-Proposer (Innowacja 4)")
    data = analyze_rules_structure()
    
    print(f"   Istniejące ADR-y: {data['existing_adrs']}")
    print(f"   Plików: {data['total_files']}")
    print(f"   Podkatalogów: {data['subdirectories']}")
    print(f"   Hardcoded: {data['hardcoded_files']} plików")
    print(f"   Routing: {data['routing_files']} plików")
    print(f"   Propozycji nowych ADR: {len(data['proposals'])}")
    
    for p in data["proposals"]:
        print(f"\n   📝 {p['title']} [{p['priority']}]")
        print(f"      Trigger: {p['trigger']}")
        print(f"      Decision: {p['decision']}")
    
    if "--json" in sys.argv:
        print(json.dumps({
            "timestamp": datetime.now().isoformat(),
            **data,
        }, indent=2, ensure_ascii=False))
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
