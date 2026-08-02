#!/usr/bin/env python3
"""
NexusAI JDG — Coverage Report Generator v8.0 (ENTERPRISE)
Generuje COVERAGE_REPORT.md z mapowania punktów prawnych Doc 50 na reguły Rego.

Fixy v8.0 (R4 z RAPORT_P25):
  - Naprawiony NameError: zmienna `r` → `rule` w map_points_to_rules
  - Ekstrakcja WSZYSTKICH prefiksów aktów: V., P., OP., K., Z., R., PP., U., Pcc, Akc, CB, Suk, Zdr, AML, RODO
  - Usunięte hardcoded statystyki (data, liczba plików, liczba rule_id)
  - Dane pobierane z generate_manifest.py (JSON mode) lub z faktycznego stanu dysku
  - SPECIAL_MAPPINGS rozszerzone

Usage: python generate_coverage_report.py [--json] [--plan50-path PATH]
  --json         Output w formacie JSON
  --plan50-path  Ścieżka do Plan OPA/50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md
"""

import json
import os
import re
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
DEFAULT_PLAN50 = JDG_ROOT.parent / "Plan OPA" / "50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md"

# Prefiksy aktów prawnych — wszystkie obsługiwane (R4)
ACT_PREFIXES = ["V", "P", "OP", "K", "Z", "R", "PP", "U", "Pcc", "Akc", "CB", "Suk", "Zdr", "AML", "RODO"]

# Reczne mapowania specjalne (rozszerzone)
SPECIAL_MAPPINGS = {
    "V.01": ["jdg.vat.substantive.goods_delivery_taxable"],
    "V.02": ["jdg.vat.substantive.wnt_reverse_charge_buyer"],
    "V.04": ["jdg.vat.substantive.taxable_person_jdg_v04"],
    "V.07": ["jdg.vat.procedures.tax_point_delayed_invoice_60d"],
    "V.19": ["jdg.vat.deductions.bad_debt_debtor_mandatory"],
    "P.18": ["jdg.pit.forms.scale", "jdg.pit.forms.linear"],
    "OP.01": ["jdg.ord.a70.r1"],
    "OP.02": ["jdg.ord.a81.r1"],
    "OP.03": ["jdg.ord.a117ba.r1"],
    "OP.04": ["jdg.liability.statute_5_years"],
}


def extract_all_rule_ids() -> dict[str, list[str]]:
    """
    Ekstrahuje wszystkie rule_id z plików .rego i mapuje je na podstawy prawne.
    Zwraca {rule_id: [legal_basis_patterns]}.
    """
    rule_map = {}
    
    for filepath in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = filepath.read_text(encoding="utf-8")
        except Exception:
            continue
        
        # Znajdź wszystkie rule_id
        rule_ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
        
        for rid in rule_ids:
            # Znajdź powiązaną podstawę prawną (szukaj w okolicy rule_id)
            legal_match = re.search(
                rf'"{re.escape(rid)}".*?"_legal_basis"\s*:\s*"([^"]*)"',
                content, re.DOTALL
            )
            legal_basis = legal_match.group(1) if legal_match else ""
            
            if rid not in rule_map:
                rule_map[rid] = []
            if legal_basis:
                rule_map[rid].append(legal_basis)
    
    return rule_map


def extract_points_from_plan50(plan50_path: Path) -> list[dict]:
    """
    Ekstrahuje WSZYSTKIE punkty prawne z Doc 50 (nie tylko V.XX).
    Obsługuje prefiksy: V., P., OP., K., Z., R., PP., U., Pcc, Akc, CB, Suk, Zdr, AML, RODO.
    """
    points = []
    
    if not plan50_path.exists():
        print(f"⚠️  Plan 50 nie znaleziony: {plan50_path}", file=sys.stderr)
        return points
    
    content = plan50_path.read_text(encoding="utf-8")
    
    # Wzorzec dla WSZYSTKICH prefiksów (np. V.01, P.01, OP.01, K.01, itd.)
    prefix_pattern = "|".join(ACT_PREFIXES)
    pattern = rf'####\s+((?:{prefix_pattern})\.\d+(?:[a-z])?(?:\.\d+)?)'
    
    for match in re.finditer(pattern, content):
        point_id = match.group(1)
        # Znajdź kontekst (linia poniżej nagłówka)
        start = match.end()
        end = content.find("####", start)
        if end == -1:
            end = len(content)
        context = content[start:end][:500]
        
        # Ekstrakcja ID OPA
        opa_match = re.search(r'`(jdg\.[a-z_][a-z0-9._]*)`', context)
        opa_id = opa_match.group(1) if opa_match else ""
        
        # Ekstrakcja priorytetu
        prio_match = re.search(r'🔴|🟡|🟢|⬜', context)
        priority = prio_match.group(0) if prio_match else "⬜"
        
        # Ekstrakcja statusu
        status_match = re.search(r'(✅|🟡|❌)', context)
        status = status_match.group(1) if status_match else "❌"
        
        # Ekstrakcja artykułu
        art_match = re.search(r'(?:Art\.|art\.)\s*(\d+[a-z]*(?:\s*ust\.\s*\d+)?(?:\s*pkt\s*\d+)?)', context, re.IGNORECASE)
        article = f"Art. {art_match.group(1)}" if art_match else ""
        
        points.append({
            "point_id": point_id,
            "opa_id": opa_id,
            "priority": priority,
            "status": status,
            "article": article,
            "context": context.strip()[:200],
        })
    
    return points


def map_points_to_rules(points: list[dict], rule_map: dict[str, list[str]]) -> list[dict]:
    """
    Mapuje punkty prawne na reguły Rego.
    FIX v8.0: zmienna `r` → `rule` (NameError fix).
    """
    results = []
    
    for point in points:
        matched_rules = []
        
        # 1. Sprawdź SPECIAL_MAPPINGS
        if point["point_id"] in SPECIAL_MAPPINGS:
            matched_rules.extend(SPECIAL_MAPPINGS[point["point_id"]])
        
        # 2. Mapowanie przez OPA ID (jeśli istnieje)
        if point["opa_id"] and not matched_rules:
            opa_id = point["opa_id"]
            # Dokładne dopasowanie: rule_id zaczyna się od opa_id + kropka LUB jest dokładnie taki sam
            for rule_id in rule_map:
                if rule_id == opa_id or rule_id.startswith(opa_id + "."):
                    matched_rules.append(rule_id)  # FIX: było `r`, teraz `rule_id`
        
        # 3. Mapowanie przez artykuł w _legal_basis
        if not matched_rules and point["article"]:
            art = point["article"]
            for rule_id, legal_bases in rule_map.items():
                for lb in legal_bases:
                    if art.lower() in lb.lower():
                        matched_rules.append(rule_id)
                        break
        
        # Deduplikacja
        matched_rules = list(dict.fromkeys(matched_rules))[:10]
        
        results.append({
            **point,
            "matched_rules": matched_rules,
            "coverage": "✅" if matched_rules else "❌",
            "partial": len(matched_rules) > 0 and all(
                "generated" in lb.lower() 
                for rid in matched_rules 
                for lb in rule_map.get(rid, [])
            ) if matched_rules else False,
        })
    
    return results


def get_factual_stats() -> dict:
    """Pobiera faktyczne statystyki z dysku (nie hardcoded)."""
    rego_files = list(RULES_DIR.rglob("*.rego"))
    
    all_rule_ids = set()
    for fp in rego_files:
        try:
            content = fp.read_text(encoding="utf-8")
            ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
            all_rule_ids.update(ids)
        except Exception:
            pass
    
    files_with_matched = 0
    for fp in rego_files:
        try:
            if '"matched"' in fp.read_text(encoding="utf-8"):
                files_with_matched += 1
        except Exception:
            pass
    
    return {
        "total_rego_files": len(rego_files),
        "unique_rule_ids": len(all_rule_ids),
        "files_with_matched": files_with_matched,
    }


def generate_report(points: list[dict], mapped: list[dict], stats: dict) -> str:
    """Generuje COVERAGE_REPORT.md."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    covered = sum(1 for m in mapped if m["matched_rules"])
    uncovered = sum(1 for m in mapped if not m["matched_rules"])
    critical = sum(1 for m in mapped if m["priority"] == "🔴" and not m["matched_rules"])
    
    lines = [
        "# 📊 Raport Pokrycia Prawnego JDG — v8.0",
        "",
        f"> **Data:** {now}",
        "> **Generator:** v8.0 (wszystkie prefiksy aktów, fix NameError)",
        f"> **Źródło:** `Plan OPA/50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md`",
        f"> **Reguły Rego:** `JDG/rules/` ({stats['total_rego_files']} plików, {stats['unique_rule_ids']} unikalnych rule_id)",
        "",
        "---",
        "",
        "## 📈 Statystyki ogólne",
        "",
        "| Metryka | Wartość |",
        "|---------|--------:|",
        f"| Punktów prawnych w Doc 50 | **{len(points)}** |",
        f"| ✅ Pokrytych / zmapowanych | **{covered}** ({covered*100//max(len(points),1)}%) |",
        f"| ❌ Brak pokrycia | **{uncovered}** |",
        f"| 🔴 Krytycznych niepokrytych | **{critical}** |",
        "",
        "---",
        "",
        "## 📋 Szczegółowa mapa: Punkt → Reguły Rego",
        "",
        "| Punkt | Status | Priorytet | Artykuł | ID OPA | Reguły Rego (rule_id) |",
        "|-------|--------|-----------|---------|--------|----------------------|",
    ]
    
    for m in mapped[:250]:  # Limit do 250 punktów w raporcie
        status_icon = m["coverage"]
        rules_str = ", ".join(f"`{r}`" for r in m["matched_rules"][:5]) if m["matched_rules"] else "—"
        if len(m["matched_rules"]) > 5:
            rules_str += f" +{len(m['matched_rules']) - 5} więcej"
        
        lines.append(
            f"| {m['point_id']} | {status_icon} | {m['priority']} | {m['article']} | "
            f"`{m['opa_id']}` | {rules_str} |"
        )
    
    if len(mapped) > 250:
        lines.append(f"| ... | ... | ... | ... | ... | *({len(mapped) - 250} więcej punktów)* |")
    
    lines.extend([
        "",
        "---",
        "",
        "## 📊 Pokrycie per prefiks aktu",
        "",
        "| Prefiks | Akt | Punktów | Pokrytych | % |",
        "|---------|-----|:-------:|:---------:|:--:|",
    ])
    
    # Grupuj per prefiks
    by_prefix = defaultdict(lambda: {"total": 0, "covered": 0})
    for m in mapped:
        prefix = m["point_id"].split(".")[0]
        by_prefix[prefix]["total"] += 1
        if m["matched_rules"]:
            by_prefix[prefix]["covered"] += 1
    
    act_names = {
        "V": "VAT", "P": "PIT", "OP": "Ordynacja Podatkowa", "K": "KKS",
        "Z": "ZUS/SUS", "R": "Ryczałt", "PP": "Prawo Przedsiębiorców",
        "U": "UoR", "Pcc": "PCC", "Akc": "Akcyza", "CB": "Cross-Border",
        "Suk": "Sukcesja", "Zdr": "Zdrowotna", "AML": "AML", "RODO": "RODO",
    }
    
    for prefix in sorted(by_prefix.keys()):
        data = by_prefix[prefix]
        pct = data["covered"] * 100 // max(data["total"], 1)
        name = act_names.get(prefix, prefix)
        lines.append(f"| {prefix} | {name} | {data['total']} | {data['covered']} | {pct}% |")
    
    lines.extend([
        "",
        "---",
        f"*Wygenerowano automatycznie — {now}*",
        "*Generator v8.0 — `python JDG/tools/generate_coverage_report.py`*",
    ])
    
    return "\n".join(lines)


def main():
    json_output = "--json" in sys.argv
    
    # Ścieżka do Plan 50
    plan50_path = DEFAULT_PLAN50
    for i, arg in enumerate(sys.argv):
        if arg == "--plan50-path" and i + 1 < len(sys.argv):
            plan50_path = Path(sys.argv[i + 1])
            break
    
    print("🔍 Generowanie raportu pokrycia prawnego (v8.0)...")
    
    # Pobierz statystyki
    stats = get_factual_stats()
    print(f"   Plików Rego: {stats['total_rego_files']}")
    print(f"   Unikalnych rule_id: {stats['unique_rule_ids']}")
    
    # Ekstrakcja punktów z Plan 50
    print(f"   Źródło: {plan50_path}")
    points = extract_points_from_plan50(plan50_path)
    print(f"   Punktów prawnych: {len(points)}")
    
    if not points:
        print("⚠️  Brak punktów do analizy. Sprawdź ścieżkę do Plan 50.")
        return 1
    
    # Pobierz rule_id
    rule_map = extract_all_rule_ids()
    print(f"   Rule ID w mapie: {len(rule_map)}")
    
    # Mapowanie
    mapped = map_points_to_rules(points, rule_map)
    covered = sum(1 for m in mapped if m["matched_rules"])
    print(f"   Pokrytych: {covered}/{len(points)} ({covered*100//max(len(points),1)}%)")
    
    if json_output:
        output = {
            "generated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "total_points": len(points),
            "covered": covered,
            "uncovered": len(points) - covered,
            "coverage_pct": covered * 100 // max(len(points), 1),
            "stats": stats,
            "points": mapped[:100],
        }
        print(json.dumps(output, indent=2, ensure_ascii=False))
        return 0
    
    # Generuj raport
    report = generate_report(points, mapped, stats)
    report_path = JDG_ROOT / "COVERAGE_REPORT.md"
    report_path.write_text(report, encoding="utf-8")
    
    print(f"✅ COVERAGE_REPORT.md zaktualizowany ({len(report)} bajtów)")
    print(f"   Pokrycie: {covered}/{len(points)} ({covered*100//max(len(points),1)}%)")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
