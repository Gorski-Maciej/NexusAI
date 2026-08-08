#!/usr/bin/env python3
"""
NexusAI JDG — DECLARATIVE CHANGE (P01 Fundament — Sekcja 12, WIZJA V2 F6 §7)
==============================================================================
„Człowiek opisuje zmianę w języku prostym, maszyna ją wykonuje". Interfejs
deklaratywny dla wszystkich typów zmian (dane i reguły):

  ZMIANA: Stawka VAT · Produkt: [PKWiU] · Stawka 23% → 8% · Od: 2027-01-01
  → System: mapowanie → nowa wersja parametru (hot-reload < 1 min) → golden
    replay → testy graniczne (dzień-1/0/+1) → invariants → PR 4-eyes →
    wdrożenie (data-only lub bundle).

  • plan      — tłumaczy zgłoszenie na plan wykonania (kroki + dotknięte artefakty),
  • execute   — wykonuje plan: dane → data_service (hot-reload), reguły →
    szablon + PR (dry-run), bezpośrednio NIGDY do produkcji bez bramek,
  • template  — szablon zgłoszenia zmiany,
  • history   — historia zmian deklaratywnych (audyt).

Usage:
  python declarative_change.py plan --change "Stawka VAT na usługi IT od 2027-01-01: 23% -> 8%"
  python declarative_change.py execute --change "..." --execute-data
  python declarative_change.py template
"""

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
CHANGE_PATH = JDG_ROOT / "bundles" / "declarative_changes.json"

PATTERNS = [
    {
        "type": "RATE_CHANGE",
        "re": r"stawk[aię]?\s+([\w\s]+?)\s*(?:od\s+(\d{4}-\d{2}-\d{2})\s*)?:?\s*([\d.]+)%?\s*(?:->|na|→)\s*([\d.]+)%?",
        "target": "data.thresholds",
        "note": "ścieżka DANYCH: data_service.py set → hot-reload < 1 min (V2 §8)",
    },
    {
        "type": "THRESHOLD_CHANGE",
        "re": r"(limit|pr[oó]g|kwota)\s+(\w[\w\s-]+?)\s+od\s+(\d{4}-\d{2}-\d{2})\s*:?\s*(\d[\d\s]+?)(?:zł|PLN)?\s*(?:->|na|→)\s*(\d[\d\s]+?)(?:zł|PLN)?",
        "target": "data.thresholds",
        "note": "ścieżka DANYCH (limit/prog) — wersjonowany wpis z valid_from (V1 §7)",
    },
    {
        "type": "LEGAL_CHANGE",
        "re": r"(nowelizacj[ai]|zmiana prawa|projekt ustawy)\s*[:.]?\s*(.+)",
        "target": "law-pipeline",
        "note": "ścieżka PRAWA: law_radar.py track + law_impact_matrix.py analyze (V1 §4)",
    },
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load() -> dict:
    if CHANGE_PATH.exists():
        return json.loads(CHANGE_PATH.read_text(encoding="utf-8"))
    return {"changes": []}


def save(data: dict) -> None:
    CHANGE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CHANGE_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def parse_change(text: str) -> dict | None:
    for pat in PATTERNS:
        m = re.search(pat["re"], text, re.IGNORECASE)
        if m:
            return {"kind": pat["type"], "target": pat["target"],
                    "note": pat["note"], "groups": m.groups()}
    return None


def cmd_plan(args) -> None:
    parsed = parse_change(args.change)
    if not parsed:
        sys.exit(f"❌ Nie rozpoznano zmiany — użyj szablonu: python declarative_change.py template\n"
                 f"   Zgłoszenie: {args.change}")
    steps = [
        "1. Mapowanie na parametr/regułę (LKG + policy_registry)",
        "2. Golden replay na 12 mies. → raport zmienionych werdyktów z uzasadnieniem (F3)",
        "3. Testy graniczne dzień-1/0/+1 + invariants (F2) + impact matrix",
        "4. Generacja PR + checklista 4-eyes (owner, prawnik)",
        "5. Wdrożenie: bundle (logika) lub data-only (hot-reload < 1 min)",
        "6. Monitoring 24 h + Decision Certificate dla nowych werdyktów (F4)",
    ]
    plan = {
        "request": args.change,
        "parsed": parsed,
        "steps": steps,
        "never_automated": [
            "NIGDY bez zdrowych metryk kanara (5% → 100%)",
            "NIGDY bez podpisu 2 osób dla domen niemutowalnych (ZUS/business)",
            "NIGDY bez dowodu zero referencji przy usuwaniu reguły",
            "NIGDY bez człowieka przy interpretacji przepisu niejednoznacznego",
        ],
        "planned_at": now(),
    }
    print(f"🔧 DECLARATIVE CHANGE — plan: [{parsed['kind']}] → {parsed['target']}")
    for s in steps:
        print(f"   {s}")
    print(f"   ({parsed['note']})")
    if args.json:
        print(json.dumps(plan, indent=2, ensure_ascii=False))


def cmd_execute(args) -> None:
    parsed = parse_change(args.change)
    if not parsed:
        sys.exit("❌ Nie rozpoznano zmiany — najpierw: plan")
    if parsed["target"] != "data.thresholds":
        print(f"⚠️  Zmiana [{parsed['kind']}] wymaga ścieżki PRAWA/REGUŁ — plan wdrożenia:")
        print("   1. law_radar.py track (projekt) → 2. law_impact_matrix.py analyze → "
              "3. rule_lifecycle_manager.py register (SHADOW) → 4. PR 4-eyes")
        return
    if not args.execute_data:
        print("ℹ️  Tryb dry-run (bez zapisu). Wykonanie danych wymaga --execute-data")
        cmd_plan(args)
        return
    # Wykonanie ścieżki danych: stawka 23% → 8%
    m = re.search(r"(\d{4}-\d{2}-\d{2})", args.change)
    valid_from = m.group(1) if m else datetime.now().strftime("%Y-%m-%d")
    groups = parsed["groups"]
    rate_new = None
    if parsed["kind"] == "RATE_CHANGE":
        rate_new = float(groups[3])
    data = load()
    data["changes"].append({
        "request": args.change,
        "parsed": parsed,
        "executed_data": {
            "parameter": "vat.rate.declared",
            "new_value": rate_new,
            "valid_from": valid_from,
            "source": "declarative_change.py",
        },
        "executed_at": now(),
    })
    save(data)
    print(f"✅ WYKONANO (ścieżka danych): parametr → {rate_new} od {valid_from} — "
          "hot-reload gotowy (data_service.py export)")

    # Golden replay + invariants jako obowiązkowe kroki po zmianie danych
    print("   → Uruchom: golden_replay.py replay (F3) + invariant_checker.py ci (F2)")


def cmd_template(args) -> None:
    tpl = {
        "change": "Stawka VAT na [produkt/usługa PKWiU] od [YYYY-MM-DD]: [X]% -> [Y]%",
        "examples": [
            "Stawka VAT na usługi IT od 2027-01-01: 23% -> 8%",
            "Limit zwolnienia podmiotowego od 2027-01-01: 2000000 -> 2400000 zł",
            "Nowelizacja ustawy o VAT: art. 113 ust. 1 — limit obrotu",
        ],
        "priority": "RUTYNOWY | PILNY (P0)",
        "source_law": "[link do projektu/ustawy]",
    }
    print(json.dumps(tpl, indent=2, ensure_ascii=False))


def cmd_history(args) -> None:
    data = load()
    print(json.dumps(data, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="Declarative Change — V2 F6")
    sub = p.add_subparsers(dest="cmd", required=True)

    pl = sub.add_parser("plan")
    pl.add_argument("--change", required=True)
    pl.add_argument("--json", action="store_true")
    pl.set_defaults(fn=cmd_plan)

    e = sub.add_parser("execute")
    e.add_argument("--change", required=True)
    e.add_argument("--execute-data", action="store_true")
    e.set_defaults(fn=cmd_execute)

    t = sub.add_parser("template"); t.set_defaults(fn=cmd_template)
    h = sub.add_parser("history"); h.set_defaults(fn=cmd_history)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
