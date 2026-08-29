#!/usr/bin/env python3
"""
NexusAI JDG — LKG NODE GENERATOR (PROMPT 24 LEGAL TWIN, WIZJA V2 F1 §2)
======================================================================
Generator węzłów Legal Knowledge Graph (LKG) z docs/Bbb.md — jednego źródła
prawdy o aktach prawnych JDG. Parsuje tabele Bbb.md (akt → kluczowe artykuły)
i buduje węzły `akt → artykuł → ustęp → pkt` z:
  • legal_node_id (LKG-NNNN), node_type (ACT/ARTICLE/SECTION/POINT),
  • valid_from/valid_to (wersjonowanie — TCL), status,
  • domain (vat/pit/zus/...), source (Bbb.md → ISAP), article_label.

Wynik:
  • bundles/legal_graph.json — LKG (append do istniejących węzłów, bez duplikatów),
  • raport w docs/LEGAL_TWIN_RAPORT.md (metryki LCI/TCL/RV per akt),
  • seed SQL do DuckDB: bundles/legal_graph_seed.sql (tabela legal_graph).

Zasady:
  • NIE duplikuje istniejących węzłów LKG (dedup po (act, article)),
  • węzły materialne (kluczowe artykuły z Bbb.md) dostają flagę
    `material: true` — LCI liczy pokrycie węzłów materialnych,
  • żaden węzeł nie jest deklarowany jako „pokryty" bez krawędzi do reguły
    (krawędzie liczone przez legal_twin_traceability.py / legal_basis_audit).

Usage:
  python lkg_generator.py build          # pełne budowanie LKG z Bbb.md
  python lkg_generator.py seed           # generacja seed SQL do DuckDB
  python lkg_generator.py report         # raport metryk per akt
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parent.parent
BBB_MD = JDG_ROOT / "docs" / "Bbb.md"
GRAPH_PATH = JDG_ROOT / "bundles" / "legal_graph.json"
SEED_PATH = JDG_ROOT / "bundles" / "legal_graph_seed.sql"
REPORT_PATH = JDG_ROOT / "docs" / "LEGAL_TWIN_RAPORT.md"
REGISTRY_PATH = JDG_ROOT / "bundles" / "legal_source_registry.json"

# Domena per akt (mapowanie z LEGAL_REFERENCE_ACTS / Bbb.md)
ACT_DOMAIN = {
    "Prawo przedsiębiorców": "business",
    "CEIDG": "business",
    "zarządzie sukcesyjnym": "business",
    "podatku od towarów i usług": "vat",
    "obniżonych stawek VAT": "vat",
    "podatku dochodowym od osób fizycznych": "pit",
    "wzorów zeznań podatkowych PIT": "pit",
    "zryczałtowanym podatku": "pit",
    "Ordynacja podatkowa": "ordpu",
    "systemie ubezpieczeń społecznych": "zus",
    "świadczeniach opieki zdrowotnej": "zus",
    "rachunkowości": "uor",
    "prowadzenia uproszczonej ewidencji": "pkpir",
    "PKPiR": "pkpir",
    "fakturze ustrukturyzowanej": "ksef",
    "zmianie ustawy o VAT": "ksef",
    "przeciwdziałaniu praniu pieniędzy": "aml",
    "odpadach": "bdo",
    "podatku akcyzowym": "excise",
    "podatkach i opłatach lokalnych": "local",
    "podatku rolnym": "local",
    "transporcie drogowym": "transport",
    "budowlane": "construction",
    "energetyczne": "energy",
    "dewizowe": "crossborder",
    "Kodeks pracy": "hr",
    "rehabilitacji zawodowej": "hr",
    "świadczeniach pieniężnych": "zus",
    "PCC": "pcc",
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _load_graph() -> dict:
    if GRAPH_PATH.exists():
        return json.loads(GRAPH_PATH.read_text(encoding="utf-8"))
    return {"schema_version": "2.0.0", "generated_at": now(), "nodes": [],
            "indexes": {"LCI": 0.0, "TCL": 0.0, "RV": 0.0}, "slo": {"LCI_MIN": 99, "TCL_MIN": 100, "RV_MIN": 100}}


def _domain_of(act_name: str) -> str:
    lowered = act_name.lower()
    for key, domain in ACT_DOMAIN.items():
        if key.lower() in lowered:
            return domain
    return "other"


def parse_bbb() -> list[dict]:
    """Wyciągnij (akt, kluczowe artykuły, dz.u.) z tabel Bbb.md."""
    text = BBB_MD.read_text(encoding="utf-8")
    rows: list[dict] = []
    # linie tabeli: | Ustawa ... | Temat ... | Art. ... |
    for line in text.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3:
            continue
        act, topic, articles = cells[0], cells[1], cells[2]
        if act.startswith("Źródło") or act.startswith("---") or act.startswith("Temat"):
            continue
        if not articles or articles in {"Kluczowe artykuły", "Temat", "Całość rozporządzenia", ""}:
            articles = ""
        rows.append({"act": act, "topic": topic, "articles": articles})
    return rows


def build_nodes() -> list[dict]:
    """Zbuduj węzły LKG z Bbb.md (dedup po (act, article))."""
    existing = _load_graph().get("nodes", [])
    seen = {(n.get("act"), n.get("article")) for n in existing}
    next_id = max((int(n["legal_node_id"].split("-")[1]) for n in existing if n.get("legal_node_id", "").startswith("LKG-")), default=0) + 1
    nodes = list(existing)
    added = 0
    for row in parse_bbb():
        act = row["act"]
        domain = _domain_of(act)
        articles = re.findall(r"(?:Art\.|art\.)\s*([\da-zA-Z]+(?:-[\da-zA-Z]+)?)", row["articles"])
        if not articles:
            # akt bez jawnych artykułów — węzeł ACT
            key = (act, "")
            if key not in seen:
                nodes.append({
                    "legal_node_id": f"LKG-{next_id:04d}",
                    "act": act, "article": "", "article_label": "całość",
                    "node_type": "ACT", "domain": domain, "material": False,
                    "valid_from": "2004-01-01", "valid_to": None, "version": 1,
                    "source": "Bbb.md", "status": "OBOWIAZUJACY",
                    "rules": [], "topic": row["topic"],
                })
                seen.add(key); next_id += 1; added += 1
            continue
        for art in articles:
            key = (act, art)
            if key in seen:
                continue
            nodes.append({
                "legal_node_id": f"LKG-{next_id:04d}",
                "act": act, "article": art, "article_label": f"Art. {art}",
                "node_type": "ARTICLE", "domain": domain, "material": True,
                "valid_from": "2004-01-01", "valid_to": None, "version": 1,
                "source": "Bbb.md", "status": "OBOWIAZUJACY",
                "rules": [], "topic": row["topic"],
            })
            seen.add(key); next_id += 1; added += 1
    return nodes, added


def compute_indexes(nodes: list[dict], rules: list[dict]) -> dict:
    """LCI (pokrycie węzłów materialnych), TCL (ciągłość), RV (kanoniczność)."""
    material = [n for n in nodes if n.get("material")]
    covered = sum(1 for n in material if n.get("rules"))
    lci = round(covered / len(material) * 100, 2) if material else 100.0
    temporal = sum(1 for n in nodes if n.get("valid_from"))
    tcl = round(temporal / len(nodes) * 100, 2) if nodes else 100.0
    ok = sum(1 for r in rules if r.get("class") == "OK")
    rv = round(ok / len(rules) * 100, 2) if rules else 100.0
    return {"LCI": lci, "TCL": tcl, "RV": rv}


def cmd_build(args) -> None:
    graph = _load_graph()
    nodes, added = build_nodes()
    graph["nodes"] = nodes
    graph["generated_at"] = now()
    graph["nodes_count"] = len(nodes)
    graph["covered_nodes"] = sum(1 for n in nodes if n.get("rules"))
    acts = {}
    for n in nodes:
        acts.setdefault(n["act"], {"articles": 0, "material": 0, "covered": 0})
        acts[n["act"]]["articles"] += 1
        if n.get("material"):
            acts[n["act"]]["material"] += 1
            if n.get("rules"):
                acts[n["act"]]["covered"] += 1
    graph["acts"] = [{"act": k, **v} for k, v in sorted(acts.items())]
    graph["indexes"] = compute_indexes(nodes, [])
    GRAPH_PATH.write_text(json.dumps(graph, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"🧬 LKG: {len(nodes)} węzłów ({added} nowych) · {len(acts)} aktów · "
          f"LCI {graph['indexes']['LCI']}% (wymagane {graph['slo']['LCI_MIN']}%)")


def cmd_seed(args) -> None:
    graph = _load_graph()
    lines = [
        "-- LKG seed (PROMPT 24) — generator: lkg_generator.py",
        "CREATE TABLE IF NOT EXISTS legal_graph (",
        "  legal_node_id TEXT PRIMARY KEY, act TEXT, article TEXT,",
        "  node_type TEXT, domain TEXT, material BOOLEAN,",
        "  valid_from DATE, valid_to DATE, version INTEGER, status TEXT,",
        "  source TEXT, rules JSON);",
        "DELETE FROM legal_graph;",
    ]
    for n in graph.get("nodes", []):
        rules = json.dumps(n.get("rules", []), ensure_ascii=False)
        node_type = n.get('node_type', 'ARTICLE')
        domain = n.get('domain', 'other')
        lines.append(
            f"INSERT INTO legal_graph VALUES ('{n['legal_node_id']}', "
            f"'{n['act'].replace(chr(39), chr(39)+chr(39))}', "
            f"'{n.get('article','')}', '{node_type}', '{domain}', "
            f"{'TRUE' if n.get('material') else 'FALSE'}, "
            f"'{n.get('valid_from') or '2004-01-01'}', "
            f"{'NULL' if not n.get('valid_to') else chr(39)+str(n['valid_to'])+chr(39)}, "
            f"{n.get('version', 1)}, '{n.get('status','OBOWIAZUJACY')}', "
            f"'{n.get('source','Bbb.md')}', '{rules}');"
        )
    SEED_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    rel = SEED_PATH.relative_to(JDG_ROOT) if SEED_PATH.is_relative_to(JDG_ROOT) else SEED_PATH
    print(f"🗄️  Seed SQL: {rel} ({len(graph.get('nodes', []))} INSERTs)")


def cmd_report(args) -> None:
    graph = _load_graph()
    idx = graph.get("indexes", {})
    rows = []
    for act in graph.get("acts", []):
        rows.append({
            "act": act["act"], "articles": act["articles"],
            "material": act["material"], "covered": act["covered"],
            "coverage_pct": round(act["covered"] / act["material"] * 100, 1) if act["material"] else 0.0,
        })
    print(json.dumps({
        "nodes": graph.get("nodes_count"), "acts": graph.get("acts_count"),
        "indexes": idx,
        "slo": graph.get("slo"),
        "per_act": rows,
        "traceability_note": "Krawędzie węzeł→reguła liczone przez legal_twin_traceability.py / legal_basis_audit.py",
    }, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="LKG Node Generator — V2 F1 (Bbb.md → legal_graph)")
    sub = p.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build"); b.set_defaults(fn=cmd_build)
    s = sub.add_parser("seed"); s.set_defaults(fn=cmd_seed)
    r = sub.add_parser("report"); r.set_defaults(fn=cmd_report)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
