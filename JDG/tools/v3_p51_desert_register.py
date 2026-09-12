#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I01/I02 DESERT REGISTER + RISK-WEIGHTED PRIORITIZATION.

I01 Desert register with SLA: kompletny rejestr pustyni prawnych z legal_graph
    (węzły ARTICLE bez rule_ids = pustynia "no_rule"; z regułami bez testu
    natywnego = "rule_no_test"; test bez reguły kanonicznej = "test_no_rule"),
    każdy wpis: przepis (akt+art+Dz.U. [NIEZWERYFIKOWANE — ISAP]), klasa,
    ryzyko (I02), priority P0–P3, deadline SLA, właściciel, status OPEN.
I02 Risk-weighted prioritization: score = częstotliwość × kwota × niepewność
    wykładni (wagi per domena, metodologia jawna w evidence.methodology).

Rekonsyliacja 3 raportów pokrycia (kontrakt P51: kanon jako baza, dryf = luka):
  * coverage_canon.json (LCI=100% przy mianowniku 70 węzłów materialnych),
  * legal_graph.json (nodes_count/covered_nodes — stan pełny, 258 węzłów),
  * coverage_deserts.json (snapshot 2026-08-08: 72/103).
Rozjazd liczb rejestrowany uczciwie jako evidence.reconciliation — nigdy nie
wygładzany (honesty; zero fantazjowania liczbami, protokół 14).

Wyjścia: bundles/v3_p51_desert_register.json + v3_p51_desert_risk.json.
"""
from __future__ import annotations

import re
from datetime import date, timedelta
from pathlib import Path

from v3_p51_common import (BASE, COVERAGE_CANON, COVERAGE_DESERTS, LEGAL_GRAPH,
                           RULES_DIR, TESTS_REGO_DIR, read_json,
                           write_p51_bundle)

SLA_DAYS = {"P0": 14, "P1": 30, "P2": 90, "P3": 180}
# Wagi ryzyka per domena (I02): (częstotliwość, kwota, niepewność) 1–5.
RISK_WEIGHTS = {
    "vat": (5, 4, 3), "ordpu": (4, 4, 4), "pit": (4, 4, 3), "ksef": (4, 3, 3),
    "zus": (4, 3, 2), "uor": (4, 3, 2), "pkpir": (4, 3, 2), "kks": (2, 4, 4),
    "ryczalt": (3, 3, 3), "health": (3, 3, 2), "business": (3, 2, 2),
    "pcc": (2, 2, 2), "lokalne": (2, 2, 2), "crossborder": (2, 4, 4),
    "other": (2, 2, 3),
}
DOMAIN_KEYWORDS = [
    ("vat", ("vat", "podatku od towarów", "faktury ustrukturyzowanej", "jpk_vat")),
    ("ksef", ("ksef", "faktury ustrukturyzowanej")),
    ("pit", ("podatku dochodowym", "pit")),
    ("ryczalt", ("zryczałtowanym", "ryczałt")),
    ("zus", ("ubezpieczeń społecznych", "zus")),
    ("health", ("zdrowotn", "opieki zdrowotnej")),
    ("ordpu", ("ordynacja", "podatkow")),
    ("kks", ("karny skarbowy", "kks")),
    ("business", ("przedsiębiorc", "ceidg", "ewidencji i informacji", "sukcesyjn")),
    ("uor", ("rachunkowoś", "pkpir", "ewidencji przychodów i kosztów")),
    ("pcc", ("czynności cywilnopraw", "pcc")),
    ("lokalne", ("podatkach i opłatach lokalnych",)),
]

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
TEST_ID_RE = re.compile(r'"(jdg\.[A-Za-z0-9_.]+)"')


def detect_domain(act: str) -> str:
    low = act.lower()
    for dom, kws in DOMAIN_KEYWORDS:
        if any(k in low for k in kws):
            return dom
    return "other"


def load_canonical_rule_ids() -> set:
    ids = set()
    for fp in RULES_DIR.rglob("*.rego"):
        try:
            ids.update(RULE_ID_RE.findall(fp.read_text(encoding="utf-8",
                                                       errors="replace")))
        except OSError:
            continue
    return ids


def load_tested_rule_ids() -> set:
    ids = set()
    if not TESTS_REGO_DIR.exists():
        return ids
    for fp in TESTS_REGO_DIR.rglob("*.rego"):
        try:
            for tid in TEST_ID_RE.findall(fp.read_text(encoding="utf-8",
                                                       errors="replace")):
                if tid.count(".") < 2:
                    continue
                if ".test." in tid or tid.split(".")[2].endswith("_test"):
                    continue  # pakiety testowe, nie reguły produkcyjne
                ids.add(tid)
        except OSError:
            continue
    return ids


def priority_of(score: int) -> str:
    if score >= 50:
        return "P0"
    if score >= 24:
        return "P1"
    if score >= 12:
        return "P2"
    return "P3"


def main() -> int:
    graph = read_json(LEGAL_GRAPH) or {}
    canon = read_json(COVERAGE_CANON) or {}
    deserts_snapshot = read_json(COVERAGE_DESERTS) or {}

    nodes = graph.get("nodes", [])
    canonical_ids = load_canonical_rule_ids()
    tested_ids = load_tested_rule_ids()
    today = date.today()

    entries, by_class, by_domain, ghost_refs = [], {}, {}, 0
    for n in nodes:
        if n.get("node_type") != "ARTICLE":
            continue
        rid_list = n.get("rule_ids") or []
        valid_rids = [r for r in rid_list if r in canonical_ids]
        ghost_refs += len(rid_list) - len(valid_rids)
        if not rid_list:
            dclass, tested = "no_rule", []
        elif not any(r in tested_ids for r in rid_list):
            dclass, tested = "rule_no_test", [r for r in rid_list
                                              if r in tested_ids]
        else:
            continue  # pełny łańcuch reguła→test — nie jest pustynią
        dom = detect_domain(n.get("act", ""))
        w_freq, w_amt, w_unc = RISK_WEIGHTS.get(dom, RISK_WEIGHTS["other"])
        score = w_freq * w_amt * w_unc
        prio = priority_of(score)
        deadline = today + timedelta(days=SLA_DAYS[prio])
        by_class[dclass] = by_class.get(dclass, 0) + 1
        by_domain[dom] = by_domain.get(dom, 0) + 1
        entries.append({
            "legal_node_id": n.get("legal_node_id"),
            "act": n.get("act"),
            "act_dz_u": n.get("act_dz_u"),
            "article": n.get("article"),
            "domain": dom,
            "desert_class": dclass,
            "risk_score": score,
            "risk_weights": {"frequency": w_freq, "amount": w_amt,
                             "uncertainty": w_unc},
            "priority": prio,
            "sla_deadline": deadline.isoformat(),
            "owner": "P51-campaign",
            "rule_ids": rid_list,
            "tested_rule_ids": tested,
            "legal_basis_verified": False,  # [NIEZWERYFIKOWANE — ISAP]
            "status": "OPEN",
        })

    entries.sort(key=lambda e: (-e["risk_score"], e["legal_node_id"]))
    prio_counts = {p: sum(1 for e in entries if e["priority"] == p)
                   for p in ("P0", "P1", "P2", "P3")}
    art_nodes = [n for n in nodes if n.get("node_type") == "ARTICLE"]
    desert_nodes = len(entries)
    covered = len(art_nodes) - desert_nodes

    recon = {
        "legal_graph": {"nodes_total": graph.get("nodes_count", len(nodes)),
                        "covered_nodes": graph.get("covered_nodes", covered),
                        "article_nodes": len(art_nodes)},
        "coverage_canon": {"LCI": (canon.get("metrics") or {}).get("LCI"),
                           "UVR": (canon.get("denominators") or {}).get(
                               "rules_untested_by_native_rego"),
                           "lkg_material_nodes": (canon.get("denominators")
                                                  or {}).get(
                               "lkg_material_nodes")},
        "deserts_snapshot": {"generated_at": deserts_snapshot.get(
                                 "generated_at"),
                             "desert_nodes": deserts_snapshot.get(
                                 "desert_nodes"),
                             "desert_pct": deserts_snapshot.get("desert_pct")},
        "drift_flags": {
            "canon_lci_100_vs_graph_7143":
                (canon.get("metrics") or {}).get("LCI") == 100.0
                and graph.get("covered_nodes", 0) < graph.get("nodes_count", 1),
            "snapshot_stale_vs_fresh":
                deserts_snapshot.get("desert_nodes") != desert_nodes,
        },
    }

    reg_metrics = {
        "analysis": "desert_register",
        "routing": "TRIAGE_QUEUE" if prio_counts["P0"] > 0 else "AUTO_FILE",
        "article_nodes": len(art_nodes),
        "nodes_total": len(art_nodes),
        "covered_nodes": covered,
        "desert_nodes": desert_nodes,
        "desert_pct": round(desert_nodes * 100.0 / len(art_nodes), 1)
                      if art_nodes else 0.0,
        "no_rule": by_class.get("no_rule", 0),
        "rule_no_test": by_class.get("rule_no_test", 0),
        "test_no_rule": 0,  # wypełniane przez v3_p51_testless_sweep.py (I09)
        "p0_count": prio_counts["P0"], "p1_count": prio_counts["P1"],
        "p2_count": prio_counts["P2"], "p3_count": prio_counts["P3"],
        "sla_registered": desert_nodes,
        "ghost_rule_refs": ghost_refs,
    }
    write_p51_bundle("desert_register", "V3-P51-I01", reg_metrics, {
        "entries_top20": entries[:20],
        "entries_total": desert_nodes,
        "by_domain": dict(sorted(by_domain.items(),
                                  key=lambda kv: -kv[1])),
        "reconciliation": recon,
        "legal_note": "Akty i Dz.U. z legal_graph.json są TWIERDZENIAMI "
                      "[NIEZWERYFIKOWANE — ISAP] do stempla 4-eyes (P47-I10).",
    })

    top_score = entries[0]["risk_score"] if entries else 0
    risk_metrics = {
        "analysis": "desert_risk",
        "routing": "TRIAGE_QUEUE" if entries else "AUTO_FILE",
        "scored": desert_nodes,
        "unscored": 0,
        "top_risk_score": top_score,
        "p0_count": prio_counts["P0"],
        "p1_count": prio_counts["P1"],
    }
    write_p51_bundle("desert_risk", "V3-P51-I02", risk_metrics, {
        "methodology": "score = frequency × amount × uncertainty (wagi 1–5 "
                       "per domena, evidence: RISK_WEIGHTS w narzędziu); "
                       "P0>=50, P1>=24, P2>=12, P3<12; SLA P0=14d, P1=30d, "
                       "P2=90d, P3=180d (I01).",
        "top10": [{"legal_node_id": e["legal_node_id"], "act": e["act"],
                   "article": e["article"], "domain": e["domain"],
                   "desert_class": e["desert_class"],
                   "risk_score": e["risk_score"],
                   "priority": e["priority"]}
                  for e in entries[:10]],
        "by_domain": by_domain,
    })

    # Rejestr pełny dla kart (I03) i kolejnych narzędzi:
    write_p51_bundle("desert_entries", "V3-P51-I01", reg_metrics, {
        "entries": entries,
    })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
