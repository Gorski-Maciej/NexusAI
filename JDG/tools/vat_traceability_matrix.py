# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT Article-to-Rego Traceability Matrix (P29 Innovation #1)
# ═══════════════════════════════════════════════════════════════════════════════
# Auto-generuje macierz Art.→RuleID z plików Rego.
# Publikowana jako artefakt CI (JSON/CSV).
# Uruchom: python JDG/tools/vat_traceability_matrix.py
# ═══════════════════════════════════════════════════════════════════════════════

import re
import json
import sys
import os
from pathlib import Path
from collections import defaultdict

VAT_ARTICLES = {
    "Art. 5": "Zakres opodatkowania — dostawa towarów",
    "Art. 7": "Dostawa towarów",
    "Art. 8": "Świadczenie usług",
    "Art. 9": "WNT — wewnątrzwspólnotowe nabycie towarów",
    "Art. 10": "Miejsce WNT",
    "Art. 11": "Import towarów",
    "Art. 12": "Dostawa poza terytorium kraju",
    "Art. 13": "WDT — wewnątrzwspólnotowa dostawa towarów",
    "Art. 14": "Opodatkowanie WDT",
    "Art. 15": "Podatnik",
    "Art. 17": "Odwrotne obciążenie",
    "Art. 19a": "Obowiązek podatkowy",
    "Art. 28a": "Miejsce świadczenia — definicja",
    "Art. 28b": "Miejsce — B2B",
    "Art. 28c": "Miejsce — B2C",
    "Art. 28d": "Miejsce — pośrednictwo",
    "Art. 28e": "Miejsce — nieruchomości",
    "Art. 28f": "Miejsce — transport towarów",
    "Art. 28g": "Miejsce — transport osób",
    "Art. 28i": "Miejsce — kultura/sport/edukacja",
    "Art. 28j": "Miejsce — restauracje/catering",
    "Art. 28k": "Miejsce — wynajem pojazdów",
    "Art. 28l": "Miejsce — e-usługi B2C",
    "Art. 28o": "Zapobieganie podwójnemu opodatkowaniu",
    "Art. 29a": "Podstawa opodatkowania",
    "Art. 41": "Stawki VAT",
    "Art. 42": "WDT 0% — warunki",
    "Art. 43": "Zwolnienia przedmiotowe",
    "Art. 86": "Odliczenia VAT",
    "Art. 86a": "Odliczenia — limit aut",
    "Art. 87": "Zwrot VAT",
    "Art. 89a": "Złe długi — wierzyciel",
    "Art. 89b": "Złe długi — dłużnik",
    "Art. 90": "Proporcja VAT",
    "Art. 91": "Korekta roczna proporcji",
    "Art. 96": "Rejestracja VAT",
    "Art. 106e": "Elementy faktury",
    "Art. 108a": "MPP — obowiązkowy",
    "Art. 113": "Zwolnienie podmiotowe",
    "Art. 115": "VAT RR — rolnik ryczałtowy",
    "Art. 116": "VAT RR — zwrot",
    "Art. 120": "Procedura marży",
}

def find_vat_rules(root_dir: str) -> dict[str, list[str]]:
    """Find all VAT rule_ids and map to articles"""
    matrix = defaultdict(list)

    for rego_file in Path(root_dir).rglob("*.rego"):
        if 'vat' not in str(rego_file).lower():
            continue

        try:
            content = rego_file.read_text(encoding='utf-8')
        except Exception:
            continue

        # Extract rule_id and legal_basis
        for match in re.finditer(
            r'"rule_id":\s*"([^"]+)".*?"_legal_basis":\s*"([^"]*)"',
            content, re.DOTALL
        ):
            rule_id = match.group(1)
            legal_basis = match.group(2)

            if not legal_basis:
                continue

            # Match against known VAT articles
            for art_key in VAT_ARTICLES:
                art_num = art_key.replace("Art. ", "")
                if art_num in legal_basis:
                    matrix[art_key].append({
                        "rule_id": rule_id,
                        "file": str(rego_file.relative_to(root_dir)),
                        "legal_basis": legal_basis
                    })

    return dict(matrix)

def generate_report(matrix: dict, output_format: str = "json"):
    """Generate traceability report"""
    if output_format == "json":
        report = {
            "title": "VAT Article-to-Rego Traceability Matrix",
            "generated": "2026-08-02",
            "audit_source": "P29_LEGAL_AUDIT_VAT_ARTICLE_BY_ARTICLE",
            "articles": {}
        }
        for art_key, desc in VAT_ARTICLES.items():
            rules = matrix.get(art_key, [])
            report["articles"][art_key] = {
                "description": desc,
                "coverage": "COMPLETE" if len(rules) > 0 else "MISSING",
                "rules_count": len(rules),
                "rules": rules
            }
        return json.dumps(report, indent=2, ensure_ascii=False)

    return ""

if __name__ == '__main__':
    root = sys.argv[1] if len(sys.argv) > 1 else "JDG/rules"
    matrix = find_vat_rules(root)

    total_articles = len(VAT_ARTICLES)
    covered = sum(1 for art in VAT_ARTICLES if len(matrix.get(art, [])) > 0)
    total_rules = sum(len(v) for v in matrix.values())

    print(f"VAT Traceability Matrix: {covered}/{total_articles} articles covered, {total_rules} rules")
    print(generate_report(matrix)[:500] + "...")
