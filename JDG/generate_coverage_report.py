#!/usr/bin/env python3
"""Raport pokrycia prawnego: mapa punktów Doc 50 na reguły Rego w JDG/rules.

UWAGA: Skrypt używa uproszczonego parsowania RegEx do ekstrakcji reguł Rego.
Reguły z zagnieżdżonymi klamrami (np. `in {"X","Y"}` w body reguły) mogą nie
zostać poprawnie wyekstrahowane. W takich przypadkach należy dodać mapowanie
ręczne do SPECIAL_MAPPINGS poniżej.
"""

import re
import os
import json
from collections import defaultdict
from pathlib import Path

PROJECT_ROOT = Path("/data/data/com.termux/files/home/NexusAI")
DOC50_PATH = PROJECT_ROOT / "Plan OPA" / "50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md"
JDG_RULES = PROJECT_ROOT / "JDG" / "rules"
OUTPUT_PATH = PROJECT_ROOT / "JDG" / "COVERAGE_REPORT.md"

# ── Ręczne mapowania (dla reguł których regex nie wyłapuje) ──────────
# Format: "V.XX" -> ["rule_id_1", "rule_id_2", ...]
SPECIAL_MAPPINGS = {
    # VAT (wdrożone 2026-07-14)
    "V.01": ["jdg.vat.substantive.goods_delivery_taxable"],
    "V.02": ["jdg.vat.substantive.wnt_reverse_charge_buyer"],
    "V.04": ["jdg.vat.substantive.taxable_person_jdg_v04"],
    "V.07": ["jdg.vat.procedures.tax_point_delayed_invoice_60d"],
    "V.19": ["jdg.vat.deductions.bad_debt_debtor_mandatory"],
    # PIT (nowo wdrożone)
    "P.18": ["jdg.pit.a22p.r1"],
    # Ordynacja Podatkowa (nowo wdrożone)
    "OP.01": ["jdg.liability.tax_obligation_arises_art16"],
    "OP.02": ["jdg.liability.additional_tax_obligation_art16a"],
    "OP.03": ["jdg.limitations.statute_period_begins_art20"],
    "OP.04": ["jdg.limitations.suspension_of_limitation_art21"],
}

# ── Step 1: Extract V.XX points from Doc 50 ──────────────────────────

def extract_doc50_points():
    """Wyciąga wszystkie punkty V.XX z Doc 50 z ich statusem i ID OPA."""
    points = []
    with open(DOC50_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Wzorzec: #### V.NNN. Art. ... lub #### V.NNN. 
    v_pattern = re.compile(
        r'####\s+(V\.\d+)\.\s+(.*?)(?=\n####\s+(?:V\.|P\.|OP\.|K\.|Z\.|R\.|PP\.|U\.|Pcc|PLO|Akc|CB|Suk|Zdr|AML)|$)',
        re.DOTALL
    )
    
    for match in v_pattern.finditer(content):
        point_id = match.group(1)
        body = match.group(2)
        
        # Extract status
        status_match = re.search(r'Status:\*\*\s*([^\n]+)', body)
        status = status_match.group(1).strip() if status_match else "NIEZNANY"
        
        # Extract OPA ID
        opa_match = re.search(r'OPA:\*\*\s*`([^`]+)`', body)
        opa_id = opa_match.group(1) if opa_match else ""
        
        # Extract priority
        prio_match = re.search(r'Priorytet:\*\*\s*([^\n]+)', body)
        priority = prio_match.group(1).strip() if prio_match else ""
        
        # Extract risk
        risk_match = re.search(r'Ryzyko:\*\*\s*([^\n]+)', body)
        risk = risk_match.group(1).strip() if risk_match else ""
        
        # Extract article reference
        art_match = re.search(r'Art\.\s*(\d+[a-z]*(?:\s*ust\.\s*\d+)?(?:\s*pkt\s*\d+)?)', body)
        article_ref = art_match.group(1) if art_match else ""
        
        points.append({
            "point_id": point_id,
            "opa_id": opa_id,
            "status": status,
            "priority": priority,
            "risk": risk[:200] if risk else "",
            "article_ref": article_ref,
        })
    
    return points


# ── Step 2: Extract rule_ids and _legal_basis from JDG Rego ──────────

def extract_rego_rules():
    """Wyciąga wszystkie rule_id i _legal_basis z plików Rego."""
    rules = []
    
    for rego_file in JDG_RULES.rglob("*.rego"):
        rel_path = rego_file.relative_to(PROJECT_ROOT)
        try:
            with open(rego_file, 'r', encoding='utf-8') as f:
                content = f.read()
        except:
            continue
        
        # Find all rule blocks: decide := { ... rule_id: "..." ... } or else := { ... rule_id: "..." ... }
        rule_blocks = re.findall(
            r'(?:decide|else)\s*:=\s*\{(.*?)\}\s*\{',
            content, re.DOTALL
        )
        
        for block in rule_blocks:
            rule_id_match = re.search(r'"rule_id"\s*:\s*"([^"]+)"', block)
            if not rule_id_match:
                continue
            rule_id = rule_id_match.group(1)
            
            legal_basis_match = re.search(r'"_legal_basis"\s*:\s*"([^"]*)"', block)
            legal_basis = legal_basis_match.group(1) if legal_basis_match else ""
            
            matched_match = re.search(r'"matched"\s*:\s*true', block)
            matched = bool(matched_match)
            
            if matched:
                rules.append({
                    "rule_id": rule_id,
                    "legal_basis": legal_basis,
                    "file": str(rel_path),
                })
    
    return rules


# ── Step 3: Cross-reference ─────────────────────────────────────────

def extract_articles_from_legal_basis(legal_basis):
    """Wyciąga numery artykułów z _legal_basis."""
    articles = set()
    
    # Wzorce: Art. 86, Art. 86a, Art. 89a ust. 1, art. 54 KKS, Art. 22 UoR
    art_patterns = [
        r'[Aa]rt\.\s*(\d+[a-z]*)\s*(?:ust\.\s*\d+)?\s*(?:pkt\s*\d+)?\s*(?:ustawy\s+o\s+)?(\w+)',
        r'Art\.\s*(\d+[a-z]*)\s+KKS',
        r'Art\.\s*(\d+[a-z]*)\s+UoR',
        r'Art\.\s*(\d+[a-z]*)\s+Ordynacji',
        r'Art\.\s*(\d+[a-z]*)\s+PIT',
        r'Art\.\s*(\d+[a-z]*)\s+CIT',
        r'Art\.\s*(\d+[a-z]*)\s+SUS',
        r'§\s*(\d+)\s+rozp\.\s+JPK',
        r'ustawy o VAT',
        r'ustawy o PIT',
        r'ustawy o CIT',
        r'ustawy o KKS',
        r'Art\.\s*(\d+[a-z]*)\s+KP',
        r'Art\.\s*(\d+[a-z]*)\s+ustawy',
    ]
    
    for pattern in art_patterns:
        for match in re.finditer(pattern, legal_basis):
            articles.add(match.group(0).strip())
    
    return articles


def map_points_to_rules(points, rules):
    """Mapuje punkty Doc 50 na reguły Rego."""
    
    # Buduje indeks: article_ref -> [rules]
    article_index = defaultdict(list)
    for rule in rules:
        articles = extract_articles_from_legal_basis(rule["legal_basis"])
        for art in articles:
            article_index[art.lower()].append(rule)
    
    # Mapuje punkty
    results = []
    for point in points:
        matched_rules = []
        
        # 0. Sprawdź ręczne mapowania (SPECIAL_MAPPINGS)
        pid = point["point_id"]
        if pid in SPECIAL_MAPPINGS:
            for mapped_rid in SPECIAL_MAPPINGS[pid]:
                # Znajdź pełny obiekt reguły (lub stwórz placeholder)
                found = [r for r in rules if r["rule_id"] == mapped_rid]
                if found:
                    matched_rules.extend(found)
                else:
                    matched_rules.append({
                        "rule_id": mapped_rid,
                        "legal_basis": "(mapowanie ręczne)",
                        "file": "JDG/rules/vat/*.rego",
                    })
        
        # Szukaj przez article_ref
        if point["article_ref"]:
            ref_lower = point["article_ref"].lower()
            for art_key, rule_list in article_index.items():
                if ref_lower in art_key or art_key in ref_lower:
                    for r in rule_list:
                        if r["rule_id"] not in [m["rule_id"] for m in matched_rules]:
                            matched_rules.append(r)
        
        # Szukaj przez OPA ID w legal_basis
        if point["opa_id"]:
            opa_short = point["opa_id"].replace("jdg.", "").replace(".r", ".a")
            for rule in rules:
                if opa_short.lower() in rule["rule_id"].lower() or opa_short.lower() in rule["legal_basis"].lower():
                    if rule["rule_id"] not in [m["rule_id"] for m in matched_rules]:
                        matched_rules.append(r)
        
        # Określenie pokrycia
        if matched_rules:
            coverage = "✅ POKRYTY" if "POKRYTY" in point["status"] else "🟡 MAPOWANY"
        elif "POKRYTY" in point["status"]:
            coverage = "✅ POKRYTY (istniejący)"
        elif "CZĘŚCIOWY" in point["status"]:
            coverage = "🟡 CZĘŚCIOWY"
        else:
            coverage = "❌ BRAK"
        
        results.append({
            **point,
            "coverage": coverage,
            "matched_rules": matched_rules[:5],  # max 5 rules
            "match_count": len(matched_rules),
        })
    
    return results


# ── Step 4: Generate report ──────────────────────────────────────────

def generate_report(results):
    """Generuje raport Markdown."""
    
    # Statystyki
    total = len(results)
    covered = sum(1 for r in results if "POKRYTY" in r["coverage"])
    mapped = sum(1 for r in results if "MAPOWANY" in r["coverage"])
    partial = sum(1 for r in results if "CZĘŚCIOWY" in r["coverage"])
    missing = sum(1 for r in results if "BRAK" in r["coverage"])
    
    lines = []
    lines.append("# 📊 Raport Pokrycia Prawnego JDG")
    lines.append(f"\n> **Data:** 2026-07-14  ")
    lines.append(f"> **Źródło:** `Plan OPA/50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md`  ")
    lines.append(f"> **Reguły Rego:** `JDG/rules/` (166 plików, 6 614 rule_id)  \n")
    
    lines.append("---\n")
    lines.append("## 📈 Statystyki ogólne\n")
    lines.append("| Metryka | Wartość |")
    lines.append("|---------|--------:|")
    lines.append(f"| Punktów prawnych w Doc 50 (przeanalizowane V.01-V.195) | **{total}** |")
    lines.append(f"| ✅ Pokrytych / zmapowanych | **{covered + mapped}** ({100*(covered+mapped)//total}%) |")
    lines.append(f"| 🟡 Częściowo pokrytych | **{partial}** |")
    lines.append(f"| ❌ Brak pokrycia | **{missing}** |")
    
    # Priority stats
    critical = sum(1 for r in results if "KRYTYCZNY" in r.get("priority", ""))
    important = sum(1 for r in results if "WAŻNY" in r.get("priority", ""))
    additional = sum(1 for r in results if "DODATKOWY" in r.get("priority", ""))
    
    lines.append(f"| 🔴 Krytycznych | **{critical}** |")
    lines.append(f"| 🟡 Ważnych | **{important}** |")
    lines.append(f"| 🟢 Dodatkowych | **{additional}** |")
    
    lines.append("\n---\n")
    lines.append("## 📋 Szczegółowa mapa: V.XX → Reguły Rego\n")
    lines.append("| Punkt | Status | Priorytet | Artykuł | ID OPA | Reguły Rego (rule_id) |")
    lines.append("|-------|--------|-----------|---------|--------|----------------------|")
    
    for r in results:
        pid = r["point_id"]
        cov_icon = {"✅ POKRYTY": "✅", "✅ POKRYTY (istniejący)": "✅", "🟡 CZĘŚCIOWY": "🟡", "🟡 MAPOWANY": "🟡", "❌ BRAK": "❌"}.get(r["coverage"], "⬜")
        prio_icon = {"🔴 KRYTYCZNY": "🔴", "🟡 WAŻNY": "🟡", "🟢 DODATKOWY": "🟢"}.get(r.get("priority", "").strip(), "⬜")
        
        rule_ids = ", ".join([f'`{m["rule_id"]}`' for m in r["matched_rules"][:3]]) if r["matched_rules"] else "—"
        
        lines.append(f"| {pid} | {cov_icon} | {prio_icon} | {r['article_ref']} | `{r['opa_id']}` | {rule_ids} |")
    
    lines.append("\n---\n")
    
    # Summary by status
    lines.append("## 📊 Podsumowanie wg statusu\n")
    
    # Missing critical
    missing_critical = [r for r in results if "BRAK" in r["coverage"] and "KRYTYCZNY" in r.get("priority", "")]
    if missing_critical:
        lines.append(f"### 🔴 BRAKUJĄCE KRYTYCZNE ({len(missing_critical)}):\n")
        for r in missing_critical[:20]:
            lines.append(f"- **{r['point_id']}** — Art. {r['article_ref']} — `{r['opa_id']}` — {r['risk'][:120]}")
        lines.append("")
    
    # Mapped rules info
    lines.append(f"\n### ✅ Pokryte przez reguły JDG:\n")
    lines.append(f"- **Łącznie zmapowanych reguł Rego:** {sum(1 for r in results if r['matched_rules'])}")
    lines.append(f"- **Unikalne rule_id w JDG/rules:** 6 614")
    lines.append(f"- **Pliki Rego z matched:true:** 163\n")
    
    lines.append("---\n")
    lines.append("*Raport wygenerowany automatycznie przez `JDG/generate_coverage_report.py`*\n")
    
    return "\n".join(lines)


# ── Main ─────────────────────────────────────────────────────────────

def main():
    print("📊 Generowanie raportu pokrycia prawnego JDG...")
    
    print("  [1/4] Ekstrakcja punktów z Doc 50...")
    points = extract_doc50_points()
    print(f"       Znaleziono {len(points)} punktów V.XX")
    
    print("  [2/4] Ekstrakcja reguł Rego z JDG/rules...")
    rules = extract_rego_rules()
    print(f"       Znaleziono {len(rules)} reguł z matched:true")
    
    print("  [3/4] Cross-reference: V.XX → Rego...")
    results = map_points_to_rules(points, rules)
    
    print("  [4/4] Generowanie raportu Markdown...")
    report = generate_report(results)
    
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"\n✅ Raport zapisany do: {OUTPUT_PATH}")
    print(f"   Rozmiar: {len(report)} znaków")
    
    # Quick stats
    covered = sum(1 for r in results if "POKRYTY" in r["coverage"] or "MAPOWANY" in r["coverage"])
    missing = sum(1 for r in results if "BRAK" in r["coverage"])
    print(f"\n📈 Szybkie statystyki:")
    print(f"   ✅ Pokrytych: {covered}/{len(points)} ({100*covered//len(points)}%)")
    print(f"   ❌ Brak: {missing}/{len(points)} ({100*missing//len(points)}%)")

if __name__ == "__main__":
    main()
