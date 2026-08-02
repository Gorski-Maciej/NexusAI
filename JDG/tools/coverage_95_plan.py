#!/usr/bin/env python3
"""
NexusAI JDG — Coverage 95% Implementation Plan (Section 3.6)
Realizuje ETAP 0-4 planu doprowadzenia pokrycia do 95%.

ETAP 0: Naprawa generate_coverage_report.py ✅ (R4)
ETAP 1: Harmonizacja Doc 50 z mapą 38c
ETAP 2: Auto-mapowanie przez rule_id OPA + _legal_basis
ETAP 3: Dopisanie braków krytycznych
ETAP 4: Raport pokrycia dla PIT/ZUS/KKS/Ord/PP/UoR/PCC

Usage: python coverage_95_plan.py [--etap 0|1|2|3|4] [--json]
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"


# Krytyczne niepokryte punkty (z sekcji 3.4 RAPORT_P25)
CRITICAL_GAPS = [
    {"point": "V.12", "art": "41 ust. 13", "opa_id": "jdg.vat.s.r5", "desc": "Stawka 0%"},
    {"point": "V.13", "art": "41 ust. 14", "opa_id": "jdg.vat.s.r0", "desc": "Stawka 0% WDT"},
    {"point": "V.22", "art": "96 ust. 5", "opa_id": "jdg.vat.a96.r5", "desc": "Wyrejestrowanie"},
    {"point": "V.23", "art": "96 ust. 20", "opa_id": "jdg.vat.a96.r20", "desc": "Sankcje"},
    {"point": "V.24", "art": "97 ust. 1", "opa_id": "jdg.vat.a97.r1", "desc": "Rejestr VAT"},
    {"point": "V.25", "art": "99 ust. 1", "opa_id": "", "desc": "Deklaracje"},
    {"point": "V.28", "art": "103 ust. 3", "opa_id": "jdg.vat.a103.r3", "desc": "Termin płatności"},
    {"point": "V.29", "art": "103 ust. 4", "opa_id": "", "desc": "Termin"},
    {"point": "V.33", "art": "106h", "opa_id": "", "desc": "Korekty faktur"},
    {"point": "V.36", "art": "106q", "opa_id": "", "desc": "Faktury"},
    {"point": "V.53", "art": "113 ust. 19", "opa_id": "jdg.vat.a113.r19", "desc": "Zwolnienie"},
    {"point": "V.59", "art": "125", "opa_id": "", "desc": ""},
]

def ensure_output_dir():
    """Zapewnia istnienie katalogu reports/."""
    (JDG_ROOT / "reports").mkdir(parents=True, exist_ok=True)


def extract_all_rule_ids():
    """Ekstrahuje wszystkie rule_id."""
    ids = set()
    for fp in RULES_DIR.rglob("*.rego"):
        try:
            content = fp.read_text(encoding="utf-8")
            ids.update(re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content))
        except: pass
    return ids


def auto_map_gaps(rule_ids):
    """Auto-mapuje krytyczne braki na istniejące rule_id."""
    results = []
    for gap in CRITICAL_GAPS:
        mapped = []
        opa_id = gap["opa_id"]
        
        # Szukaj rule_id pasujących do OPA ID
        if opa_id:
            for rid in rule_ids:
                if rid == opa_id or rid.startswith(opa_id + "."):
                    mapped.append(rid)
        
        # Szukaj po artykule
        if gap["art"] and not mapped:
            art_pattern = gap["art"].replace(" ", r"\s*")
            for rid in rule_ids:
                if re.search(art_pattern.replace("ust.", "ust"), rid):
                    mapped.append(rid)
        
        results.append({
            **gap,
            "mapped_rules": mapped[:5],
            "status": "✅" if mapped else "❌",
        })
    
    return results


def generate_plan_report():
    """Generuje raport planu doprowadzenia do 95%."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    rule_ids = extract_all_rule_ids()
    gaps = auto_map_gaps(rule_ids)
    
    covered = sum(1 for g in gaps if g["status"] == "✅")
    
    report = [
        "# 🎯 Plan Doprowadzenia Pokrycia do 95% (Section 3.6)",
        "",
        f"> **Wygenerowano:** {now}",
        f"> **Reguł w systemie:** {len(rule_ids)}",
        f"> **Krytycznych braków zmapowanych:** {covered}/{len(gaps)}",
        "",
        "## ETAP 0: Naprawa generate_coverage_report.py ✅",
        "Wykonane 2026-08-02 — fix NameError + wszystkie prefiksy aktów.",
        "",
        "## ETAP 1: Harmonizacja Doc 50 z mapą 38c",
        "Status: ⬜ PENDING — wymaga dostępu do Plan OPA/50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md",
        "",
        "## ETAP 2: Auto-mapowanie przez rule_id OPA",
        f"Status: 🟡 IN PROGRESS — {covered}/{len(gaps)} krytycznych punktów zmapowanych",
        "",
        "## Szczegółowe mapowanie krytycznych braków:",
        "",
        "| Punkt | Artykuł | OPA ID | Status | Znalezione reguły |",
        "|-------|---------|--------|:------:|-------------------|",
    ]
    
    for g in gaps:
        rules_str = ", ".join(f"`{r}`" for r in g["mapped_rules"][:3]) if g["mapped_rules"] else "—"
        report.append(f"| {g['point']} | {g['art']} | `{g['opa_id']}` | {g['status']} | {rules_str} |")
    
    report.extend([
        "",
        "## ETAP 3: Dopisanie braków krytycznych",
        f"Status: ⬜ PENDING — {len(gaps) - covered} punktów wymaga dopisania reguł",
        "",
        "## ETAP 4: Raport dla PIT/ZUS/KKS/Ord/PP/UoR/PCC",
        "Status: ⬜ PENDING",
        "",
        "---",
        f"*Wygenerowano — {now}*",
    ])
    
    return "\n".join(report)


def main():
    etaps = [int(a.split("=")[1]) for a in sys.argv if a.startswith("--etap=")]
    etap = etaps[0] if etaps else 0
    
    print(f"🎯 Coverage 95% Plan — ETAP {etap}")
    
    rule_ids = extract_all_rule_ids()
    print(f"   Unikalnych rule_id: {len(rule_ids)}")
    
    gaps = auto_map_gaps(rule_ids)
    covered = sum(1 for g in gaps if g["status"] == "✅")
    print(f"   Krytycznych braków: {len(gaps)} | Zmapowanych: {covered}")
    
    report = generate_plan_report()
    ensure_output_dir()
    output = JDG_ROOT / "reports" / "coverage_95_plan.md"
    output.write_text(report, encoding="utf-8")
    print(f"✅ Plan: {output} ({len(report)} bajtów)")
    
    if "--json" in sys.argv:
        print(json.dumps({
            "timestamp": datetime.now().isoformat(),
            "total_rule_ids": len(rule_ids),
            "critical_gaps": len(gaps),
            "mapped": covered,
            "pct_mapped": covered * 100 // len(gaps),
            "gaps": gaps,
        }, indent=2, ensure_ascii=False))
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
