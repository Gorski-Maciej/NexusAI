#!/usr/bin/env python3
"""
NexusAI JDG — REVERSE COVERAGE DETECTOR (PROMPT 24 LEGAL TWIN, V2 F1 §2)
=======================================================================
Mapa odwrotna pokrycia: „artykuł bez reguły\". Dla każdego węzła materialnego
LKG (akt → artykuł z Bbb.md) sprawdza, czy istnieje reguła OPA z podstawą
prawną odwołującą się do tego artykułu. Węzeł materialny BEZ reguły =
ALARM POKRYCIA (luka do domknięcia w F6 declarative change).

  • scan    — przeskanuj rules/ i wylicz pokrycie węzłów (rule_id list),
  • gaps    — lista węzłów materialnych bez reguł (priorytety: P1 krytyczne),
  • report  — raport do docs/LEGAL_COVERAGE_GAP_RAPORT.md.

Zasady:
  • dopasowanie odporne na odmianę (artykuł z basis → węzeł LKG),
  • brak reguły dla węzła materialnego = luka (nie deklaracja), zapisana
    w bundles/legal_coverage_gaps.json (reverse section),
  • węzeł NIE jest „pokryty\" przez regułę z innej domeny — dopasowanie
    po (act, article).

Usage:
  python reverse_coverage_detector.py scan
  python reverse_coverage_detector.py gaps
  python reverse_coverage_detector.py report
"""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
GRAPH_PATH = JDG_ROOT / "bundles" / "legal_graph.json"
GAPS_PATH = JDG_ROOT / "bundles" / "legal_coverage_gaps.json"
REPORT_MD = JDG_ROOT / "docs" / "LEGAL_COVERAGE_GAP_RAPORT.md"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
BASIS_RE = re.compile(r'"_legal_basis"\s*:\s*"([^"]*)"')
ART_RE = re.compile(r"(?:Art\.|art\.)\s*([\da-zA-Z]+(?:-[\da-zA-Z]+)?)")

P1_ACT_KEYWORDS = ("podatku od towarów i usług", "podatku dochodowym od osób fizycznych",
                   "Ordynacja podatkowa", "Kodeks karny skarbowy", "systemie ubezpieczeń społecznych")


def _load_graph() -> dict:
    if GRAPH_PATH.exists():
        return json.loads(GRAPH_PATH.read_text(encoding="utf-8"))
    return {"nodes": [], "indexes": {}}


def _load_gaps() -> dict:
    if GAPS_PATH.exists():
        return json.loads(GAPS_PATH.read_text(encoding="utf-8"))
    return {"rows": [], "by_status": {}, "priorities": {}}


def scan_rules() -> list[dict]:
    rules: list[dict] = []
    for path in sorted(RULES_DIR.rglob("*.rego")):
        text = path.read_text(encoding="utf-8", errors="replace")
        for m in RULE_ID_RE.finditer(text):
            start = max(0, m.start() - 600)
            window = text[start:m.end() + 400]
            basis_m = BASIS_RE.search(window)
            rel = path.relative_to(JDG_ROOT) if path.is_relative_to(JDG_ROOT) else path
            rules.append({
                "rule_id": m.group(1),
                "file": str(rel),
                "legal_basis": basis_m.group(1) if basis_m else "",
            })
    return rules


def _article_from_basis(basis: str) -> str | None:
    m = ART_RE.search(basis or "")
    if not m:
        return None
    art = m.group(1)
    return art.split("-")[0]


def scan() -> dict:
    graph = _load_graph()
    rules = scan_rules()
    nodes = graph.get("nodes", [])
    # indeks: (act_normalized, article) -> node
    node_index: dict[tuple[str, str], dict] = {}
    for n in nodes:
        key = (n.get("act", "").lower(), str(n.get("article", "")))
        node_index[key] = n
    covered: dict[str, list[str]] = {}
    act_of_node: dict[str, str] = {}
    for r in rules:
        art = _article_from_basis(r["legal_basis"])
        if not art:
            continue
        lb = r["legal_basis"].lower()
        for (act_lower, node_art), node in node_index.items():
            if node_art.split("-")[0] != art:
                continue
            # dopasowanie aktu po słowie kluczowym domeny (odporne na odmianę)
            if _act_matches(act_lower, lb):
                covered.setdefault(node["legal_node_id"], []).append(r["rule_id"])
                act_of_node[node["legal_node_id"]] = act_lower
    for n in nodes:
        n["rules"] = sorted(set(covered.get(n["legal_node_id"], [])))
        n["_act_matched"] = bool(act_of_node.get(n["legal_node_id"]))
    graph["nodes"] = nodes
    graph["covered_nodes"] = sum(1 for n in nodes if n.get("rules"))
    graph["indexes"]["LCI"] = _compute_lci(nodes)
    GRAPH_PATH.write_text(json.dumps(graph, indent=2, ensure_ascii=False), encoding="utf-8")
    return {"rules_scanned": len(rules), "nodes": len(nodes),
            "covered_nodes": graph["covered_nodes"],
            "LCI": graph["indexes"]["LCI"]}


def _act_matches(act_lower: str, lb: str) -> bool:
    """Dopasowanie aktu: słowo kluczowe aktu musi wystąpić w podstawie prawnej.
    Akceptuje formy pełne („podatku od towarów i usług") i skróty kanoniczne
    („ustawy o VAT", „Ordynacji podatkowej") — odporne na odmianę."""
    keywords = {
        "vat": ("podatku od towarów i usług", "ustawy o vat", "ustawie o vat"),
        "pit": ("podatku dochodowym od osób fizycznych", "ustawy o pit", "ryczałt"),
        "zus": ("ubezpieczeń społecznych", "ustawy o sus", "zdrowotn"),
        "kks": ("kodeks karny skarbowy", "kodeksu karnego skarbowego", "kks"),
        "ordpu": ("ordynacj",),
        "uor": ("rachunkowości",),
        "pcc": ("pcc", "czynności cywilnoprawnych"),
        "local": ("lokalnych", "rolnym"),
        "excise": ("akcyz",),
        "aml": ("praniu pieniędzy",),
        "bdo": ("odpadach",),
        "business": ("przedsiębiorc", "ceidg", "sukcesyjnym"),
        "ksef": ("ksef", "fakturze ustrukturyzowanej"),
        "transport": ("transporcie drogowym",),
        "hr": ("kodeks pracy", "rehabilitacji"),
        "crossborder": ("dewiz",),
        "energy": ("energetyczne",),
        "construction": ("budowlane",),
    }
    for domain, kws in keywords.items():
        if any(kw in act_lower for kw in kws):
            return any(kw in lb for kw in kws)
    return False


def _compute_lci(nodes: list[dict]) -> float:
    material = [n for n in nodes if n.get("material")]
    covered = sum(1 for n in material if n.get("rules"))
    return round(covered / len(material) * 100, 2) if material else 100.0


def gaps() -> dict:
    graph = _load_graph()
    material = [n for n in graph.get("nodes", []) if n.get("material")]
    uncovered = [n for n in material if not n.get("rules")]
    rows = []
    for n in sorted(uncovered, key=lambda x: (0 if any(k in x.get("act", "").lower() for k in P1_ACT_KEYWORDS) else 1, x.get("act", ""))):
        rows.append({
            "legal_node_id": n["legal_node_id"],
            "act": n["act"], "article": n.get("article"),
            "domain": n.get("domain"),
            "priority": "P1" if any(k in n.get("act", "").lower() for k in P1_ACT_KEYWORDS) else "P2",
            "material": True,
        })
    by_status = {"COVERED": sum(1 for n in material if n.get("rules")),
                 "UNCOVERED": len(uncovered)}
    return {"reverse_coverage": {"material_nodes": len(material), "uncovered": len(uncovered),
                                 "coverage_pct": round((len(material) - len(uncovered)) / len(material) * 100, 2) if material else 100.0,
                                 "gaps": rows},
            "by_status": by_status}


def cmd_scan(args) -> None:
    result = scan()
    print(json.dumps(result, indent=2, ensure_ascii=False))
    print(f"🧭 REVERSE COVERAGE: {result['covered_nodes']}/{result['nodes']} węzłów pokrytych "
          f"(LCI {result['LCI']}%)")


def cmd_gaps(args) -> None:
    result = gaps()
    g = result["reverse_coverage"]
    print(json.dumps(g, indent=2, ensure_ascii=False))
    if g["uncovered"]:
        print(f"⚠️  {g['uncovered']} węzłów materialnych BEZ reguł — domknij przez F6 declarative change")
    else:
        print("✅ Brak węzłów materialnych bez reguł")


def cmd_report(args) -> None:
    result = gaps()
    data = _load_gaps()
    data.update(result)
    data["generated_at"] = now()
    GAPS_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    g = result["reverse_coverage"]
    lines = [
        "# 📊 LEGAL COVERAGE GAP REPORT — reverse coverage (PROMPT 24)",
        "",
        f"> Wygenerowano: {now()} · generator: `reverse_coverage_detector.py`",
        "",
        "## Podsumowanie reverse coverage",
        "",
        f"- Węzły materialne LKG: {g['material_nodes']}",
        f"- Pokryte regułami: {g['material_nodes'] - g['uncovered']}",
        f"- Bez reguł (luki): {g['uncovered']}",
        f"- Pokrycie (LCI): {g['coverage_pct']}%",
        "",
        "## Luki — artykuły bez reguły (priorytety P1/P2)",
        "",
        "| legal_node_id | Akt | Art. | Domena | Priorytet |",
        "|---|---|---|---|---|",
    ]
    lines += [f"| {r['legal_node_id']} | {r['act']} | {r['article']} | {r['domain']} | {r['priority']} |"
              for r in g["gaps"]]
    lines += ["", "*Luki domykane przez F6 declarative_change (człowiek zatwierdza, maszyna wykonuje).*", ""]
    REPORT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"📄 Raport: {REPORT_MD.relative_to(JDG_ROOT)} ({g['uncovered']} luk)")


def main() -> None:
    p = argparse.ArgumentParser(description="Reverse Coverage Detector — V2 F1 (artykuł bez reguły)")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("scan"); s.set_defaults(fn=cmd_scan)
    g = sub.add_parser("gaps"); g.set_defaults(fn=cmd_gaps)
    r = sub.add_parser("report"); r.set_defaults(fn=cmd_report)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
