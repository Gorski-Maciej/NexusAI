#!/usr/bin/env python3
"""
NexusAI JDG — VALIDATE LEGAL BASIS v2 (P02 — sekcja 4, V2 F1: bramka RV)
==========================================================================
Rozszerzenie validate_legal_basis.py (P24) o referencje do węzłów LKG:
podstawa prawna przestaje być stringiem, staje się REFERENCJĄ do Legal
Knowledge Graph (legal_graph.json z legal_twin.py). Bramka CI:

  • CANONICAL — format kanoniczny: „Art. X ust. Y pkt Z ustawy o VAT (Dz.U. ...)",
  • LKG_REF   — artykuł + akt z _legal_basis mapują się do węzła legal_graph
    (RV — Rule–Law Verification, cel V2: 100%),
  • MISSING   — reguła bez podstawy prawnej (FAIL).

Usage:
  python validate_legal_basis_v2.py --gate
  python validate_legal_basis_v2.py --json
  python validate_legal_basis_v2.py --rule jdg.vat.a113.r1
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
CANON = JDG_ROOT / "bundles" / "legal_reference_canon.json"
LEGAL_GRAPH = JDG_ROOT / "bundles" / "legal_graph.json"
OUT_JSON = JDG_ROOT / "bundles" / "legal_basis_v2_report.json"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
LEGAL_BASIS_RE = re.compile(r'"_?legal_basis"\s*:\s*"([^"]+)"')
ART_RE = re.compile(r"[Aa]rt\.\s*([\w.\-]+)")


def load_json(path: Path) -> dict:
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


def article_of(basis: str) -> str | None:
    m = ART_RE.search(basis)
    if not m:
        return None
    # „Art. 113.1" → „113.1"; „Art. 108a-108f" → „108a"
    art = m.group(1)
    if "-" in art:
        art = art.split("-")[0]
    return art


def match_lkg(basis: str, nodes: list[dict]) -> bool:
    art = article_of(basis)
    if not art:
        return False
    lb = basis.lower()
    for n in nodes:
        if n.get("article", "").split("-")[0] == art or n.get("article") == art:
            # dopasowanie aktu: aliasy keywordów z nazwy węzła
            hay = f"{n.get('act', '')} {n.get('article', '')}".lower()
            if any(tok in lb for tok in _act_tokens(hay)):
                return True
    return False


def _act_tokens(hay: str) -> list[str]:
    tokens = []
    for kw in ("vat", "pit", "zus", "kks", "pcc", "uor", "ryczałt", "ryczalt",
               "ordynacj", "akcyz", "rachunkowości", "przedsiębiorc", "ceidg",
               "zdrowotn", "lokalnych", "bdo", "rodo", "aml", "ksef", "dewiz"):
        if kw in hay:
            tokens.append(kw)
    return tokens


def validate() -> dict:
    canon = load_json(CANON)
    acts = canon.get("acts", [])
    lkg = load_json(LEGAL_GRAPH)
    nodes = lkg.get("nodes", [])
    rows = []
    stats = Counter()
    for path in sorted(RULES_DIR.rglob("*.rego")):
        content = path.read_text(encoding="utf-8", errors="ignore")
        rel = str(path.relative_to(JDG_ROOT))
        for m in RULE_ID_RE.finditer(content):
            ctx = content[m.start():m.start() + 4000]
            lbm = LEGAL_BASIS_RE.search(ctx)
            basis = lbm.group(1) if lbm else ""
            issues = []
            if not basis.strip():
                stats["MISSING"] += 1
                issues.append("MISSING")
            else:
                art = ART_RE.search(basis)
                if not art:
                    stats["NO_ARTICLE"] += 1
                    issues.append("NO_ARTICLE")
                act_ok = any(k in basis.lower() for act in acts for k in act.get("keywords", []))
                if not act_ok:
                    stats["UNKNOWN_ACT"] += 1
                    issues.append("UNKNOWN_ACT")
                if nodes:
                    if match_lkg(basis, nodes):
                        stats["LKG_OK"] += 1
                    else:
                        stats["NO_LKG_REF"] += 1
                        issues.append("NO_LKG_REF")
                if not issues and "Dz.U." not in basis:
                    stats["NO_DZU"] += 1
                    issues.append("NO_DZU")
            if not issues:
                stats["OK"] += 1
            rows.append({"rule_id": m.group(1), "file": rel, "legal_basis": basis,
                         "issues": issues, "status": "OK" if not issues else "FAIL"})
    total = len(rows)
    rv = round(stats.get("OK", 0) / total * 100, 2) if total else 100.0
    return {"generated_at": datetime.now(timezone.utc).isoformat(),
            "rules_total": total, "stats": dict(stats), "rv_metric": rv, "rows": rows}


def main() -> None:
    p = argparse.ArgumentParser(description="Validate Legal Basis v2 — bramka RV (P02 sekcja 4)")
    p.add_argument("--gate", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--rule", default=None)
    args = p.parse_args()

    report = validate()
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    if args.rule:
        for r in report["rows"]:
            if r["rule_id"] == args.rule:
                print(json.dumps(r, indent=2, ensure_ascii=False))
                return
        sys.exit(f"❌ Brak reguły {args.rule}")
    s = report["stats"]
    print(f"🔎 VALIDATE LEGAL BASIS v2: {report['rules_total']} reguł · RV={report['rv_metric']}% · "
          f"OK={s.get('OK', 0)} · MISSING={s.get('MISSING', 0)} · "
          f"UNKNOWN_ACT={s.get('UNKNOWN_ACT', 0)} · NO_LKG_REF={s.get('NO_LKG_REF', 0)}")
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return
    if args.gate:
        bad = s.get("MISSING", 0)
        if bad:
            print(f"❌ BRAMKA: {bad} reguł bez podstawy prawnej — FAIL")
            sys.exit(1)
        print(f"✅ BRAMKA: zero MISSING · RV={report['rv_metric']}% (cel 100%)")


if __name__ == "__main__":
    main()
