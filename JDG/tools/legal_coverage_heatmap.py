#!/usr/bin/env python3
"""
NexusAI JDG — Legal Coverage Heatmap Generator (Innowacja 5)
Generuje interaktywną mapę cieplną 1935 punktów prawnych dla 13 aktów.
Output: HTML z heatmapą + Markdown z tabelą per akt.

Usage: python legal_coverage_heatmap.py [--output PATH] [--json]
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"


# ── Definicje aktów prawnych ─────────────────────────────────────────────────

ACTS = {
    "VAT": {"name": "Ustawa o VAT", "prefixes": ["jdg.vat", "jdg.micro.vat"], "points": 350, "color": "#2196F3"},
    "PIT": {"name": "Ustawa o PIT", "prefixes": ["jdg.pit", "jdg.micro.pit"], "points": 320, "color": "#4CAF50"},
    "OrdPU": {"name": "Ordynacja Podatkowa", "prefixes": ["jdg.ord", "jdg.micro.ord"], "points": 180, "color": "#FF9800"},
    "KKS": {"name": "KKS", "prefixes": ["jdg.kks", "jdg.micro.kks"], "points": 160, "color": "#F44336"},
    "ZUS": {"name": "ZUS/SUS", "prefixes": ["jdg.zus", "jdg.micro.sus", "jdg.micro.zdrowotna", "jdg.micro.zasilkowa"], "points": 120, "color": "#9C27B0"},
    "Ryczalt": {"name": "Ryczałt", "prefixes": ["jdg.ryc", "jdg.micro.ryczalt"], "points": 90, "color": "#00BCD4"},
    "PP": {"name": "Prawo Przedsiębiorców", "prefixes": ["jdg.business", "jdg.micro.ceidg"], "points": 80, "color": "#795548"},
    "UoR": {"name": "Ustawa o Rachunkowości", "prefixes": ["jdg.accounting", "jdg.micro.pkpir", "jdg.micro.uor"], "points": 100, "color": "#607D8B"},
    "PCC": {"name": "PCC", "prefixes": ["jdg.local_taxes.pcc", "jdg.micro.pcc"], "points": 75, "color": "#E91E63"},
    "Akcyza": {"name": "Akcyza", "prefixes": ["jdg.local_taxes", "jdg.micro.akcyza"], "points": 75, "color": "#3F51B5"},
    "CB": {"name": "Cross-Border", "prefixes": ["jdg.crossborder", "jdg.micro.crossborder"], "points": 80, "color": "#009688"},
    "Sukcesja": {"name": "Sukcesja", "prefixes": ["jdg.micro.sukcesja"], "points": 60, "color": "#FF5722"},
    "RODO/AML": {"name": "RODO + AML", "prefixes": ["jdg.rodo", "jdg.compliance", "jdg.micro.aml", "jdg.micro.rodo", "jdg.micro.bdo"], "points": 120, "color": "#8BC34A"},
}

LEGAL_BASIS_PATTERNS = {
    "VAT": r'(?:ustaw[ay]\s+(?:o\s+)?(?:podatku\s+od\s+towar[óo]w\s+i\s+us[łl]ug|VAT)|Art\.\s*\d+[a-z]*\s*(?:ust\.\s*\d+\s*(?:pkt\s*\d+)?)?\s*(?:ustawy\s+o\s+VAT)?)',
    "PIT": r'(?:ustaw[ay]\s+(?:o\s+)?(?:podatku\s+dochodowym|PIT)|Art\.\s*\d+[a-z]*\s*(?:ust\.\s*\d+)?\s*(?:ustawy\s+o\s+PIT|PIT))',
    "OrdPU": r'(?:ordynacj[ai]\s+podatkow[eąj]|OrdPU|Art\.\s*\d+[a-z]*\s*§?\s*\d*\s*OrdPU)',
    "KKS": r'(?:kodeks(?:u)?\s+karn(?:ego|ym)\s+skarbow(?:ego|ym)|KKS|Art\.\s*\d+[a-z]*\s*KKS)',
    "ZUS": r'(?:system(?:u|ie)?\s+ubezpiecze[ńn]\s+spo[łl]ecznych|SUS|ZUS|sk[łl]ad(?:ka|ek|ki)\s+(?:zdrowotn[aey]|spo[łl]eczn[aey]|ZUS))',
    "Ryczalt": r'(?:zrycza[łl]towan|rycza[łl]t|PKWiU)',
    "PP": r'(?:prawo\s+przedsi[ęe]biorc[óo]w|CEIDG|dzia[łl]alno[śs][ćc]\s+gospodarcz)',
    "UoR": r'(?:rachunkowo[śs]ci|UoR|PKPiR|amortyzac|K[ŚS]T)',
    "PCC": r'(?:PCC|czynno[śs]ci\s+cywilnoprawn)',
    "Akcyza": r'(?:akcyz|wyrob[óo]w\s+akcyzow)',
    "CB": r'(?:cross.border|WNT|WDT|transgranicz|import\s+us[łl]ug|CFC|TP|transfer\s+pric)',
    "Sukcesja": r'(?:sukcesyjn|zarz[ąa]d(y|cy|ca)\s+sukcesyjn)',
    "RODO/AML": r'(?:RODO|AML|praniu\s+pieni[ęe]dzy|danych\s+osobowych|BDO|GDPR)',
}


def extract_rule_id_data():
    """Ekstrahuje wszystkie rule_id z metadanymi."""
    rules = []
    for fp in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = fp.read_text(encoding="utf-8")
        except: continue
        rel = str(fp.relative_to(RULES_DIR))

        ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
        legal_bases = re.findall(r'"_legal_basis"\s*:\s*"([^"]*)"', content)
        matched_true = len(re.findall(r'"matched"\s*:\s*true', content)) > 0

        for i, rid in enumerate(ids):
            lb = legal_bases[i] if i < len(legal_bases) else ""
            rules.append({
                "rule_id": rid, "file": rel,
                "legal_basis": lb, "has_matched_true": matched_true,
            })
    return rules


def classify_rules_by_act(rules):
    """Klasyfikuje reguły per akt prawny."""
    act_data = {act: {"rules": [], "matched_true": 0, "with_legal_basis": 0, "unique_ids": set()}
                for act in ACTS}

    for r in rules:
        rid = r["rule_id"]
        lb = r["legal_basis"].lower() if r["legal_basis"] else ""
        classified = False

        for act, patterns in LEGAL_BASIS_PATTERNS.items():
            if re.search(patterns, lb, re.IGNORECASE):
                act_data[act]["rules"].append(r)
                act_data[act]["unique_ids"].add(rid)
                if r["has_matched_true"]:
                    act_data[act]["matched_true"] += 1
                if r["legal_basis"]:
                    act_data[act]["with_legal_basis"] += 1
                classified = True
                break

        if not classified:
            # Klasyfikuj po prefiksie rule_id
            for act, info in ACTS.items():
                if any(rid.startswith(p) for p in info["prefixes"]):
                    act_data[act]["rules"].append(r)
                    act_data[act]["unique_ids"].add(rid)
                    if r["has_matched_true"]:
                        act_data[act]["matched_true"] += 1
                    if r["legal_basis"]:
                        act_data[act]["with_legal_basis"] += 1
                    break

    return act_data


def coverage_class(covered_pct: float) -> str:
    """Określa klasę A/B/C na podstawie % pokrycia."""
    if covered_pct >= 70: return "A (GOTOWE)"
    elif covered_pct >= 30: return "B (SZKIELETY)"
    else: return "C (PLANOWANE)"


def generate_heatmap_html(act_data: dict) -> str:
    """Generuje interaktywną heatmapę HTML."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    rows_html = ""
    for act, info in ACTS.items():
        data = act_data[act]
        total_points = info["points"]
        unique_ids = len(data["unique_ids"])
        matched = data["matched_true"]
        with_lb = data["with_legal_basis"]

        pct_unique = min(100, (unique_ids * 100) // max(total_points, 1))
        pct_matched = min(100, (matched * 100) // max(total_points, 1))
        klasa = coverage_class(pct_unique)
        klasa_color = "#4CAF50" if "A" in klasa else "#FF9800" if "B" in klasa else "#F44336"

        heat = pct_unique
        r, g, b = 255, 255, 255
        if heat > 0:
            r = max(0, int(255 * (1 - heat / 100)))
            g = int(200 * (heat / 100)) + 55
            b = max(0, int(100 * (1 - heat / 100)))
        bg = f"rgb({r},{g},{b})"

        rows_html += f"""
        <tr style="background: {bg}">
            <td style="font-weight: bold; color: {info['color']}">{act}</td>
            <td>{info['name']}</td>
            <td style="text-align: right">{total_points}</td>
            <td style="text-align: right">{unique_ids}</td>
            <td style="text-align: right">{pct_unique}%</td>
            <td style="text-align: right">{matched}</td>
            <td style="text-align: right">{with_lb}</td>
            <td style="color: {klasa_color}; font-weight: bold">{klasa}</td>
        </tr>"""

    return f"""<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NexusAI JDG — Legal Coverage Heatmap v8.0</title>
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; background: #f5f5f5; }}
  h1 {{ color: #333; }}
  table {{ border-collapse: collapse; width: 100%; max-width: 1100px; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }}
  th {{ background: #333; color: white; padding: 12px; text-align: left; }}
  td {{ padding: 10px 12px; border-bottom: 1px solid #eee; }}
  .legend {{ margin: 15px 0; display: flex; gap: 15px; font-size: 13px; }}
  .legend span {{ padding: 3px 10px; border-radius: 12px; }}
  .footer {{ color: #999; font-size: 12px; margin-top: 20px; }}
  tr:hover {{ filter: brightness(0.95); }}
</style>
</head>
<body>
<h1>🗺️ NexusAI JDG — Legal Coverage Heatmap v8.0</h1>
<div class="legend">
  <span style="background: #4CAF50; color: white">Klasa A (≥70%)</span>
  <span style="background: #FF9800; color: white">Klasa B (30-69%)</span>
  <span style="background: #F44336; color: white">Klasa C (&lt;30%)</span>
  <span style="background: #ddd">Intensywność = % pokrycia unikalnymi rule_id</span>
</div>
<table>
  <tr>
    <th>Akt</th><th>Nazwa</th><th>Punktów</th><th>Rule ID</th><th>% Pokrycia</th><th>Matched:true</th><th>Legal Basis</th><th>Klasa</th>
  </tr>
  {rows_html}
</table>
<p class="footer">Wygenerowano: {now} | Innowacja 5 — Legal Coverage Heatmap | NexusAI JDG v8.0</p>
</body>
</html>"""


def generate_heatmap_markdown(act_data: dict) -> str:
    """Generuje heatmapę w Markdown."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines = [
        "# 🗺️ Legal Coverage Heatmap — NexusAI JDG v8.0",
        "",
        f"> **Wygenerowano:** {now} | **Innowacja 5**",
        "",
        "## Mapa cieplna 13 aktów prawnych",
        "",
        "| Akt | Nazwa | Punktów | Rule ID | % Pokrycia | Matched:true | Legal Basis | Klasa |",
        "|-----|-------|:-------:|:-------:|:----------:|:------------:|:-----------:|:-----:|",
    ]

    for act, info in ACTS.items():
        data = act_data[act]
        tp = info["points"]
        uid = len(data["unique_ids"])
        pct = min(100, (uid * 100) // max(tp, 1))
        mt = data["matched_true"]
        wlb = data["with_legal_basis"]
        klasa = coverage_class(pct)
        bar = "█" * (pct // 10) + "░" * (10 - pct // 10)
        lines.append(f"| **{act}** | {info['name']} | {tp} | {uid} | {pct}% {bar} | {mt} | {wlb} | {klasa} |")

    lines.extend([
        "",
        "## Podsumowanie",
        "",
        f"| Metryka | Wartość |",
        f"|---------|---------|",
        f"| Całkowita liczba punktów prawnych | {sum(a['points'] for a in ACTS.values())} |",
        f"| Unikalnych rule_id zmapowanych | {sum(len(d['unique_ids']) for d in act_data.values())} |",
        f"| Aktów w Klasie A (≥70%) | {sum(1 for a in ACTS if coverage_class(min(100, (len(act_data[a]['unique_ids']) * 100) // max(ACTS[a]['points'], 1))).startswith('A'))} |",
        f"| Aktów w Klasie B (30-69%) | {sum(1 for a in ACTS if coverage_class(min(100, (len(act_data[a]['unique_ids']) * 100) // max(ACTS[a]['points'], 1))).startswith('B'))} |",
        f"| Aktów w Klasie C (<30%) | {sum(1 for a in ACTS if coverage_class(min(100, (len(act_data[a]['unique_ids']) * 100) // max(ACTS[a]['points'], 1))).startswith('C'))} |",
        "",
        "---",
        f"*Wygenerowano automatycznie — {now}*",
        "*Innowacja 5: Legal Coverage Heatmap — `python JDG/tools/legal_coverage_heatmap.py`*",
    ])
    return "\n".join(lines)


def main():
    print("🗺️  Generowanie Legal Coverage Heatmap (Innowacja 5)...")
    rules = extract_rule_id_data()
    print(f"   Reguł: {len(rules)}")
    act_data = classify_rules_by_act(rules)

    for act, data in act_data.items():
        print(f"   {act}: {len(data['unique_ids'])} unikalnych rule_id, {data['matched_true']} matched:true, {data['with_legal_basis']} z legal_basis")

    # Generuj HTML
    html = generate_heatmap_html(act_data)
    html_path = JDG_ROOT / "reports" / "legal_coverage_heatmap.html"
    html_path.parent.mkdir(parents=True, exist_ok=True)
    html_path.write_text(html, encoding="utf-8")
    print(f"✅ Heatmapa HTML: {html_path} ({len(html)} bajtów)")

    # Generuj Markdown
    md = generate_heatmap_markdown(act_data)
    md_path = JDG_ROOT / "reports" / "legal_coverage_heatmap.md"
    md_path.write_text(md, encoding="utf-8")
    print(f"✅ Heatmapa MD: {md_path} ({len(md)} bajtów)")

    if "--json" in sys.argv:
        summary = {}
        for act in ACTS:
            data = act_data[act]
            tp = ACTS[act]["points"]
            uid = len(data["unique_ids"])
            pct = min(100, (uid * 100) // max(tp, 1))
            summary[act] = {
                "name": ACTS[act]["name"], "total_points": tp,
                "unique_rule_ids": uid, "coverage_pct": pct,
                "matched_true": data["matched_true"],
                "with_legal_basis": data["with_legal_basis"],
                "class": coverage_class(pct),
            }
        print(json.dumps(summary, indent=2, ensure_ascii=False))

    return 0


if __name__ == "__main__":
    sys.exit(main())
