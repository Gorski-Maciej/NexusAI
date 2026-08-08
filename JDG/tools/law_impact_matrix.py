#!/usr/bin/env python3
"""
NexusAI JDG — LAW IMPACT MATRIX (P01 Fundament — Sekcja 7, V1 §4.2, F5/F6 V2)
==============================================================================
Analiza wpływu nowelizacji prawa na reguły OPA. Wejście: ustrukturyzowany
„diff prawny" (akt × artykuł × typ zmiany: STAWKA/PROG/DEFINICJA/TERMIN).
Wyjście: macierz (nowelizacja × reguła × priorytet WYSOKI/ŚREDNI/NISKI),
lista testów do aktualizacji i lista parametrów do zmiany.

Reguły mapowane są przez `_legal_basis` (string) oraz przez węzły LKG
(legal_graph.json z legal_twin.py — jeżeli istnieje).

Usage:
  python law_impact_matrix.py analyze --act "ustawa o VAT" --articles 113,41 \
      --change-type STAWKA --priority HIGH
  python law_impact_matrix.py analyze --diff changes.json
  python law_impact_matrix.py report
"""

import argparse
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
LEGAL_GRAPH = JDG_ROOT / "bundles" / "legal_graph.json"
OUT_PATH = JDG_ROOT / "bundles" / "impact_matrix.json"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
LEGAL_BASIS_RE = re.compile(r'"_?legal_basis"\s*:\s*"([^"]+)"')

CHANGE_TYPES = {"STAWKA", "PROG", "DEFINICJA", "TERMIN", "ZWOLNIENIE", "ODLICZENIE", "SANKCJA"}
PRIORITIES = {"HIGH", "MEDIUM", "LOW"}


def scan_rules() -> list[dict]:
    rules = []
    for path in sorted(RULES_DIR.rglob("*.rego")):
        content = path.read_text(encoding="utf-8", errors="ignore")
        rel = str(path.relative_to(JDG_ROOT))
        for m in RULE_ID_RE.finditer(content):
            ctx = content[m.start():m.start() + 4000]
            lb = LEGAL_BASIS_RE.search(ctx)
            rules.append({
                "rule_id": m.group(1),
                "file": rel,
                "legal_basis": lb.group(1) if lb else "",
            })
    return rules


ACT_KEYWORDS = [
    ("towarów i usług", ["vat"]),
    ("dochodowym od osób fizycznych", ["pit"]),
    ("systemie ubezpieczeń społecznych", ["zus"]),
    ("karny skarbowy", ["kks"]),
    ("karnym skarbowym", ["kks"]),
    ("czynności cywilnoprawnych", ["pcc"]),
    ("rachunkowości", ["uor"]),
    ("przedsiębiorców", ["przedsiębiorc"]),
    ("ordynacji podatkowej", ["ordynacj"]),
    ("zryczałtowanym", ["ryczałt", "ryczalt"]),
    ("opieki zdrowotnej", ["zdrowotn"]),
]


DOMAIN_TOKENS = {"vat": "vat", "pit": "pit", "zus": "zus", "kks": "kks",
                 "pcc": "pcc", "uor": "uor", "cit": "cit"}


def act_keywords(act: str) -> list[str]:
    """Słowa-klucze aktu używane w _legal_basis reguł (odporne na odmianę)."""
    lower = act.lower()
    for phrase, keys in ACT_KEYWORDS:
        if phrase in lower:
            return keys
    for token, key in DOMAIN_TOKENS.items():
        if f"{token}" in lower or f" {token}" in lower:
            return [key]
    return [lower]


def analyze(args) -> None:
    if args.diff:
        diff = json.loads(Path(args.diff).read_text(encoding="utf-8"))
        acts = diff.get("changes", [])
    else:
        acts = [{
            "act": args.act,
            "articles": [a.strip() for a in args.articles.split(",") if a.strip()],
            "change_type": args.change_type,
            "priority": args.priority,
        }]
    rules = scan_rules()
    rows = []
    for change in acts:
        keys = act_keywords(change["act"])
        for article in change.get("articles", []):
            needle = re.compile(rf"art\.\s*{re.escape(str(article))}(?![0-9a-z])")
            for r in rules:
                lb = r["legal_basis"].lower()
                if not any(k in lb for k in keys):
                    continue
                if not needle.search(lb):
                    continue
                rows.append({
                    "act": change["act"],
                    "article": article,
                    "change_type": change.get("change_type", "STAWKA"),
                    "priority": change.get("priority", "MEDIUM"),
                    "rule_id": r["rule_id"],
                    "file": r["file"],
                    "impact": _impact(change.get("change_type", "STAWKA")),
                })
    # Raport
    by_priority = Counter(row["priority"] for row in rows)
    by_type = Counter(row["change_type"] for row in rows)
    summary = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "changes": len(acts),
        "affected_rules": len(rows),
        "by_priority": dict(by_priority),
        "by_change_type": dict(by_type),
        "rows": rows,
        "note": "Zmiana parametru → ścieżka DANYCH (data_service.py, hot-reload < 1 min); "
                "zmiana logiki → ścieżka REGUŁ (rule_lifecycle_manager.py, ≤ 24 h / 4 h P0)",
    }
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"⚖️  IMPACT MATRIX: {len(acts)} zmian(y) → {len(rows)} dotkniętych reguł")
    print(f"   Priorytety: {dict(by_priority)}")
    print(f"   Typy zmian: {dict(by_type)}")
    if args.json:
        print(json.dumps(summary, indent=2, ensure_ascii=False))


def _impact(change_type: str) -> str:
    if change_type in ("STAWKA", "PROG"):
        return "PARAMETER_ONLY"  # ścieżka danych
    if change_type == "TERMIN":
        return "PARAMETER_AND_LOGIC"
    return "LOGIC"  # definicje, zwolnienia, odliczenia, sankcje → ścieżka reguł


def cmd_report(args) -> None:
    if not OUT_PATH.exists():
        sys.exit("❌ Brak impact_matrix.json — uruchom: analyze")
    data = json.loads(OUT_PATH.read_text(encoding="utf-8"))
    print(json.dumps(data, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="Law Impact Matrix — V1 §4.2")
    sub = p.add_subparsers(dest="cmd", required=True)

    a = sub.add_parser("analyze")
    a.add_argument("--act", default="")
    a.add_argument("--articles", default="")
    a.add_argument("--change-type", choices=sorted(CHANGE_TYPES), default="STAWKA")
    a.add_argument("--priority", choices=sorted(PRIORITIES), default="MEDIUM")
    a.add_argument("--diff", default=None, help="plik JSON ze strukturą zmian")
    a.add_argument("--json", action="store_true")
    a.set_defaults(fn=analyze)

    r = sub.add_parser("report"); r.set_defaults(fn=cmd_report)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
