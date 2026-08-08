#!/usr/bin/env python3
"""
NexusAI JDG — ZGODNOŚĆ Z DOKUMENTAMI KSIĘGOWYMI (P02 — sekcja 6)
================================================================
Tabele zgodności reguł OPA z obowiązkowymi dokumentami księgowymi JDG:

  • UoR (Art. 2, 4, 20–22, 26, 28, 32, 74),
  • PKPiR (rozporządzenie — struktura kolumn 1–17),
  • JPK_V7M / JPK_V7K,
  • formularze PIT-36 / PIT-36L / PIT-28,
  • deklaracje VAT-7 / VAT-7K / VAT-UE,
  • PCC-3,
  • deklaracje ZUS (ZUS DRA, ZUS ZUA).

Dla każdego elementu sprawdzane jest istnienie reguł implementujących
(wyszukiwanie w rejestrze policy_registry.json po słowach kluczowych domeny
i numerze artykułu / typie dokumentu). Output: docs/ZGODNOSC_DOKUMENTY_KSIEGOWE.md.

Usage:
  python accounting_docs_compliance.py [--json] [--gate]
"""

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
REGISTRY = JDG_ROOT / "bundles" / "policy_registry.json"
OUT_JSON = JDG_ROOT / "bundles" / "accounting_compliance.json"
OUT_MD = JDG_ROOT / "docs" / "ZGODNOSC_DOKUMENTY_KSIEGOWE.md"

# Wymagane elementy dokumentów księgowych → słowa kluczowe w rule_id/legal_basis
DOCS = [
    {"doc": "UoR", "elements": [
        {"element": "Art. 2 — definicje", "keywords": ["uor", "definicj"]},
        {"element": "Art. 4 — zasady rachunkowości", "keywords": ["uor", "zasad"]},
        {"element": "Art. 20–22 — księgi rachunkowe", "keywords": ["uor", "księg"]},
        {"element": "Art. 26 — wycena aktywów", "keywords": ["uor", "wycen"]},
        {"element": "Art. 28 — wycena bilansowa", "keywords": ["uor", "bilans"]},
        {"element": "Art. 32 — amortyzacja", "keywords": ["uor", "amortyz"]},
        {"element": "Art. 74 — dokumentacja", "keywords": ["uor", "dokumentacj"]},
    ]},
    {"doc": "PKPiR", "elements": [
        {"element": f"Kolumna {i}", "keywords": ["pkpir", f"kol_{i}", f"column_{i}"]}
        for i in range(1, 18)
    ]},
    {"doc": "JPK_V7M", "elements": [
        {"element": "Sekcja ewidencja sprzedaży", "keywords": ["jpk", "v7", "sprzedaż"]},
        {"element": "Sekcja ewidencja zakupów", "keywords": ["jpk", "v7", "zakup"]},
        {"element": "GTU (grupy towarów)", "keywords": ["jpk", "gtu"]},
    ]},
    {"doc": "JPK_V7K", "elements": [
        {"element": "Ewidencja sprzedaży", "keywords": ["jpk", "v7k"]},
        {"element": "Ewidencja zakupów", "keywords": ["jpk", "v7k", "zakup"]},
    ]},
    {"doc": "PIT-36", "elements": [
        {"element": "Skala podatkowa", "keywords": ["pit36", "pit-36", "skala"]},
        {"element": "Dochód z działalności", "keywords": ["pit36", "działalności"]},
    ]},
    {"doc": "PIT-36L", "elements": [
        {"element": "Podatek liniowy 19%", "keywords": ["pit36l", "pit-36l", "liniow"]},
    ]},
    {"doc": "PIT-28", "elements": [
        {"element": "Ryczałt od przychodów", "keywords": ["pit28", "pit-28", "ryczałt", "ryczalt"]},
    ]},
    {"doc": "VAT-7", "elements": [
        {"element": "Deklaracja VAT-7", "keywords": ["vat7", "vat-7", "deklaracj"]},
    ]},
    {"doc": "VAT-7K", "elements": [
        {"element": "Deklaracja VAT-7K (kwartalna)", "keywords": ["vat7k", "vat-7k", "kwartal"]},
    ]},
    {"doc": "VAT-UE", "elements": [
        {"element": "Informacja podsumowująca VAT-UE", "keywords": ["vat-ue", "vat_ue", "wdt"]},
    ]},
    {"doc": "PCC-3", "elements": [
        {"element": "Deklaracja PCC-3", "keywords": ["pcc3", "pcc-3"]},
    ]},
    {"doc": "ZUS DRA", "elements": [
        {"element": "Deklaracja rozliczeniowa ZUS DRA", "keywords": ["zus", "dra"]},
    ]},
    {"doc": "ZUS ZUA", "elements": [
        {"element": "Zgłoszenie ubezpieczonego ZUS ZUA", "keywords": ["zus", "zua"]},
    ]},
]


def load_rules() -> list[dict]:
    if REGISTRY.exists():
        data = json.loads(REGISTRY.read_text(encoding="utf-8"))
        return data.get("rules", [])
    return []


def analyze() -> dict:
    rules = load_rules()
    haystack = [(r["rule_id"], f"{r['rule_id']} {r.get('legal_basis', '')}".lower()) for r in rules]
    rows = []
    for doc in DOCS:
        for el in doc["elements"]:
            matched = []
            for rule_id, hay in haystack:
                if all(k.lower() in hay for k in el["keywords"]):
                    matched.append(rule_id)
            rows.append({
                "doc": doc["doc"],
                "element": el["element"],
                "status": "COMPLETE" if matched else "GAP",
                "rules": matched[:5],
                "count": len(matched),
            })
    by_status = {}
    for r in rows:
        by_status.setdefault(r["status"], 0)
        by_status[r["status"]] += 1
    return {"generated_at": datetime.now(timezone.utc).isoformat(),
            "elements_total": len(rows), "by_status": by_status, "rows": rows}


def write_md(report: dict) -> None:
    lines = [
        "# 🧾 ZGODNOŚĆ Z DOKUMENTAMI KSIĘGOWYMI — P02 (sekcja 6)",
        "",
        f"> Wygenerowano: {report['generated_at']} · generator: `accounting_docs_compliance.py`",
        "",
        "| Dokument | Element | Status | Reguły |",
        "|---|---|---|---|",
    ]
    for r in report["rows"]:
        lines.append(f"| {r['doc']} | {r['element']} | **{r['status']}** | "
                     f"{', '.join(r['rules']) or '—'} |")
    lines += ["", "*Status: COMPLETE = reguły implementujące istnieją w rejestrze; "
              "GAP = brak reguł (do domknięcia w P09/P04/P17).*", ""]
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"✅ Raport: {OUT_MD.relative_to(JDG_ROOT)}")


def main() -> None:
    p = argparse.ArgumentParser(description="Zgodność z dokumentami księgowymi — P02 sekcja 6")
    p.add_argument("--json", action="store_true")
    p.add_argument("--gate", action="store_true")
    args = p.parse_args()

    report = analyze()
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"🧾 ZGODNOŚĆ: {report['elements_total']} elementów · "
          f"COMPLETE={report['by_status'].get('COMPLETE', 0)} · "
          f"GAP={report['by_status'].get('GAP', 0)}")
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return
    write_md(report)
    if args.gate:
        gaps = report["by_status"].get("GAP", 0)
        if gaps:
            print(f"❌ BRAMKA: {gaps} luk w dokumentach księgowych — domknij (P09/P04/P17)")
            sys.exit(1)
        print("✅ BRAMKA: wszystkie dokumenty księgowe pokryte")


if __name__ == "__main__":
    main()
