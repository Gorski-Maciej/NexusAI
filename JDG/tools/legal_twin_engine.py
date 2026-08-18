#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — LEGAL TWIN ENGINE (GLM52 P17 — ENTERPRISE AI + SYSTEM OPA, V2 F1 §2)
# Silnik Legal Twin / LKG z metrykami pewności (V2 §2.3):
#   • LCI — Legal Coverage Index: % węzłów materialnych prawa objętych regułami,
#   • TCL — Temporal Continuity of Law: % węzłów z dowiedzioną ciągłością
#           (zero luk między wersjami),
#   • RV  — Rule–Law Verification: % reguł, których _legal_basis wskazuje
#           zweryfikowane węzły LKG,
#   • pustynia pokrycia = alarm (domknięcie przez części 02-16).
# Czyta bundles/legal_graph.json (budowany przez legal_twin.py build — strukturę
# nodes[] + indexes). SLO: LCI ≥ 99%, TCL 100%, RV 100% (V2 §11.1).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
LKG_PATH = JDG_ROOT / "bundles" / "legal_graph.json"


def load_lkg() -> dict:
    if LKG_PATH.exists():
        return json.loads(LKG_PATH.read_text(encoding="utf-8"))
    return {"nodes": [], "indexes": {}, "slo": {}}


def metrics() -> dict:
    """LCI / TCL / RV z legal_graph.json — SLO V2 §11.1 (LCI ≥ 99%, RV 100%)."""
    lkg = load_lkg()
    nodes = lkg.get("nodes", [])
    indexes = lkg.get("indexes", {})
    slo = lkg.get("slo", {})

    lci = indexes.get("LCI", 0.0)
    tcl = indexes.get("TCL", 0.0)
    rv = indexes.get("RV", 0.0)
    covered = lkg.get("covered_nodes", 0)
    return {
        "lci": lci, "tcl": tcl, "rv": rv,
        "total_nodes": len(nodes), "covered_nodes": covered,
        "rules_scanned": lkg.get("rules_scanned", 0),
        "desert_alert": lci < slo.get("LCI_MIN", 99.0),
        "targets": {"lci_target": slo.get("LCI_MIN", 99.0),
                    "tcl_target": slo.get("TCL_MIN", 100.0),
                    "rv_target": slo.get("RV_MIN", 100.0)},
    }


def traceability(node_id: str) -> dict:
    """Dwukierunkowa traceability: węzeł LKG → reguły pokrywające."""
    lkg = load_lkg()
    node = next((n for n in lkg.get("nodes", []) if n.get("legal_node_id") == node_id), None)
    if not node:
        return {"node_id": node_id, "found": False}
    return {"node_id": node_id, "found": True,
            "act": node.get("act"), "article": node.get("article"),
            "rules": node.get("rules", []),
            "status": node.get("status")}


def time_travel(act_dz_u: str, article: str, on_date: str) -> dict:
    """Dowód istnienia przepisu z dnia transakcji (time-travel LKG)."""
    lkg = load_lkg()
    matches = [n for n in lkg.get("nodes", [])
               if n.get("act_dz_u") == act_dz_u and n.get("article") == article]
    if not matches:
        return {"act_dz_u": act_dz_u, "article": article, "exists": False}
    node = matches[0]
    valid_from = node.get("valid_from", "0000-01-01") or "0000-01-01"
    valid_to = node.get("valid_to") or "9999-12-31"
    exists = valid_from <= on_date <= valid_to
    return {"act_dz_u": act_dz_u, "article": article, "exists": exists,
            "valid_from": valid_from, "valid_to": valid_to, "on_date": on_date,
            "node_id": node.get("legal_node_id")}


def desert() -> list[dict]:
    """Pustynia pokrycia: węzły prawa bez reguł (alarm)."""
    lkg = load_lkg()
    return [{"node_id": n.get("legal_node_id"), "act": n.get("act"),
             "article": n.get("article")}
            for n in lkg.get("nodes", []) if not n.get("rules")][:50]


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Legal Twin Engine (P17)")
    sub = p.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("metrics"); m.set_defaults(fn=lambda a: print(json.dumps(metrics(), ensure_ascii=False, indent=1)))
    t = sub.add_parser("trace"); t.add_argument("--node-id", required=True)
    t.set_defaults(fn=lambda a: print(json.dumps(traceability(a.node_id), ensure_ascii=False, indent=1)))
    tt = sub.add_parser("time-travel"); tt.add_argument("--act-dz-u", required=True)
    tt.add_argument("--article", required=True); tt.add_argument("--date", required=True)
    tt.set_defaults(fn=lambda a: print(json.dumps(time_travel(a.act_dz_u, a.article, a.date), ensure_ascii=False, indent=1)))
    d = sub.add_parser("desert"); d.set_defaults(fn=lambda a: print(json.dumps(desert(), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
