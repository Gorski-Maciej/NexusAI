#!/usr/bin/env python3
"""
NexusAI JDG — LEGAL COVERAGE GAP REPORT (P02 — sekcja 3)
==========================================================
Analiza pokrycia 1935 punktów prawnych (13 aktów, klasy A/B/C) z
docs/LEGAL_COVERAGE.md względem RZECZYWISTEGO stanu rules/:

  • parsuje sekcje „## Art. X" z LEGAL_COVERAGE.md (punkty prawne, status,
    reguły Rego, pliki, progi),
  • weryfikuje, czy deklarowane rule_id faktycznie istnieją w rejestrze
    (policy_registry.json / bezpośredni skan rules/),
  • aktualizuje status: COMPLETE (reguły istnieją) / PARTIAL (część reguł
    brakuje) / GAP (brak reguł),
  • wyznacza priorytety domknięcia luk (klasa B/C, wg ryzyka KKS i
    częstotliwości transakcji — np. PCC+lokalne+akcyza 225 pkt, UoR 100 pkt,
    VAT Art. 86–88, amortyzacja 22a–22o).

Output: bundles/legal_coverage_gaps.json + docs/LEGAL_COVERAGE_GAP_RAPORT.md.

Usage:
  python legal_coverage_gap_report.py [--json] [--gate]
"""

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
LEGAL_COVERAGE = JDG_ROOT / "docs" / "LEGAL_COVERAGE.md"
RULES_DIR = JDG_ROOT / "rules"
OUT_JSON = JDG_ROOT / "bundles" / "legal_coverage_gaps.json"
OUT_MD = JDG_ROOT / "docs" / "LEGAL_COVERAGE_GAP_RAPORT.md"

ACT_HEADER_RE = re.compile(r"^#\s+([IVX]+\.\s*.+?)\s+—\s+(\d+)\s+punkt")
ART_HEADER_RE = re.compile(r"^##\s+Art\.\s+(.+)")
PUNKTY_RE = re.compile(r"\*\*Punkty prawne:\*\*\s*([^\n]+)")
POKRYCIE_RE = re.compile(r"\*\*Pokrycie JDG:\*\*\s*([^\n]+)")
REGUŁY_RE = re.compile(r"\*\*Reguły Rego:\*\*\s*`([^`]+)`")
PLIKI_RE = re.compile(r"\*\*Pliki:\*\*\s*([^\n]+)")
PROGI_RE = re.compile(r"\*\*Progi:\*\*\s*([^\n]+)")


def collect_actual_rule_ids() -> set[str]:
    ids = set()
    for path in RULES_DIR.rglob("*.rego"):
        content = path.read_text(encoding="utf-8", errors="ignore")
        ids.update(re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content))
    return ids


def parse_coverage() -> list[dict]:
    """Parsowanie LEGAL_COVERAGE.md → lista artykułów z metadanymi."""
    articles = []
    current_act = None
    current_art = None
    for raw in LEGAL_COVERAGE.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        m = ACT_HEADER_RE.match(line)
        if m:
            current_act = m.group(1).strip()
            current_art = None
            continue
        m = ART_HEADER_RE.match(line)
        if m:
            current_art = {"act": current_act or "?", "article": m.group(1).strip()}
            articles.append(current_art)
            continue
        if current_art is None:
            continue
        if "Punkty prawne" in line:
            mm = PUNKTY_RE.search(line)
            if mm:
                current_art["points"] = [p.strip() for p in mm.group(1).replace("`", "").split(",")]
        elif "Pokrycie JDG" in line:
            mm = POKRYCIE_RE.search(line)
            if mm:
                current_art["declared_status"] = "COMPLETE" if "COMPLETE" in mm.group(1) else \
                    ("PARTIAL" if "PARTIAL" in mm.group(1) else "GAP")
        elif "Reguły Rego" in line:
            mm = REGUŁY_RE.search(line)
            if mm:
                current_art["declared_rules"] = [r.strip() for r in mm.group(1).replace("`", "").split(",")]
        elif "Pliki" in line:
            mm = PLIKI_RE.search(line)
            if mm:
                current_art["files"] = mm.group(1).strip()
        elif "Progi" in line:
            mm = PROGI_RE.search(line)
            if mm:
                current_art["thresholds"] = mm.group(1).strip()
    return articles


def analyze() -> dict:
    articles = parse_coverage()
    actual = collect_actual_rule_ids()
    rows = []
    for a in articles:
        declared = a.get("declared_rules", [])
        if not declared:
            actual_status = "GAP"  # brak deklaracji reguł
        else:
            existing = [r for r in declared if r in actual]
            if len(existing) == len(declared):
                actual_status = "COMPLETE"
            elif existing:
                actual_status = "PARTIAL"
            else:
                actual_status = "GAP"
        rows.append({
            "act": a["act"],
            "article": a["article"],
            "points": a.get("points", []),
            "declared_status": a.get("declared_status", "GAP"),
            "actual_status": actual_status,
            "declared_rules": declared,
            "existing_rules": [r for r in declared if r in actual],
            "missing_rules": [r for r in declared if r not in actual],
        })
    by_status = Counter(r["actual_status"] for r in rows)
    # Priorytety domknięcia luk (sekcja 3 P02 — wg ryzyka i objętości)
    priorities = {
        "P1_KKS": [r for r in rows if "KKS" in r["act"] and r["actual_status"] != "COMPLETE"],
        "P1_VAT_odliczenia": [r for r in rows if "VAT" in r["act"] and "86" in r["article"] and r["actual_status"] != "COMPLETE"],
        "P1_amortyzacja": [r for r in rows if any(a in r["article"] for a in ("22a", "22b", "22c", "22d", "22e", "22f", "22g", "22h", "22i", "22j", "22k", "22l", "22m", "22n", "22o")) and r["actual_status"] != "COMPLETE"],
        "P2_UoR": [r for r in rows if "RACHUNKOWO" in r["act"].upper() and r["actual_status"] != "COMPLETE"],
        "P2_PCC_lokalne_akcyza": [r for r in rows if any(k in r["act"].upper() for k in ("PCC", "LOKALN", "AKCYZ")) and r["actual_status"] != "COMPLETE"],
    }
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "articles_total": len(articles),
        "declared_points": sum(len(a.get("points", [])) for a in articles),
        "by_status": dict(by_status),
        "priorities": {k: len(v) for k, v in priorities.items()},
        "priority_details": {k: [r["act"] + " Art. " + r["article"] for r in v[:15]] for k, v in priorities.items()},
        "rows": rows,
        "actual_rule_ids": len(actual),
    }


def write_md(report: dict) -> None:
    s = report["by_status"]
    lines = [
        "# 📊 LEGAL COVERAGE GAP REPORT — P02 (sekcja 3)",
        "",
        f"> Wygenerowano: {report['generated_at']} · generator: `legal_coverage_gap_report.py`",
        "",
        "## Podsumowanie",
        "",
        f"- Artykuły w LEGAL_COVERAGE.md: {report['articles_total']}",
        f"- Punkty prawne deklarowane: {report['declared_points']}",
        f"- COMPLETE: {s.get('COMPLETE', 0)} · PARTIAL: {s.get('PARTIAL', 0)} · GAP: {s.get('GAP', 0)}",
        f"- Rzeczywiste rule_id w rules/: {report['actual_rule_ids']}",
        "",
        "## Priorytety domknięcia luk",
        "",
        "| Priorytet | Luk |",
        "|---|---|",
    ]
    for k, v in report["priorities"].items():
        lines.append(f"| {k} | {v} |")
    lines += ["", "### Szczegóły priorytetów", ""]
    for k, items in report["priority_details"].items():
        lines.append(f"**{k}**")
        lines += [f"- {i}" for i in items] or ["- (brak)"]
        lines.append("")
    lines += [
        "## Tabela pokrycia (akt × artykuł × status)",
        "",
        "| Akt | Art. | Status deklarowany | Status faktyczny | Brakujące reguły |",
        "|---|---|---|---|---|",
    ]
    for r in report["rows"]:
        lines.append(f"| {r['act']} | {r['article']} | {r['declared_status']} | "
                     f"**{r['actual_status']}** | {', '.join(r['missing_rules'][:3]) or '—'} |")
    lines += ["", "*Status faktyczny = weryfikacja istnienia deklarowanych rule_id w rules/.*", ""]
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"✅ Raport: {OUT_MD.relative_to(JDG_ROOT)}")


def main() -> None:
    p = argparse.ArgumentParser(description="Legal Coverage Gap Report — P02 sekcja 3")
    p.add_argument("--json", action="store_true")
    p.add_argument("--gate", action="store_true", help="bramka: FAIL przy lukach GAP")
    args = p.parse_args()

    report = analyze()
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    s = report["by_status"]
    print(f"📊 POKRYCIE: {report['articles_total']} artykułów · COMPLETE={s.get('COMPLETE', 0)} · "
          f"PARTIAL={s.get('PARTIAL', 0)} · GAP={s.get('GAP', 0)} · "
          f"punkty={report['declared_points']}")
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return
    write_md(report)
    if args.gate and s.get("GAP", 0) > 0:
        print(f"❌ BRAMKA: {s.get('GAP', 0)} luk GAP — domknij przed merge")
        sys.exit(1)


if __name__ == "__main__":
    main()
