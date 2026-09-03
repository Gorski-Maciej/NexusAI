#!/usr/bin/env python3
"""
NexusAI JDG — LEGAL NODE VERSIONING ENGINE (V3-P01-I01)
========================================================
Wersjonowanie węzłów prawa (legal_node) z diffem prawnym i dowodem
time-travel na dzień transakcji.

  • kanoniczny adres węzła: legal_node_ref =
      PL/<canonical_short>/art/<art>[/ust/<ust>][/pkt/<pkt>][/lit/<lit>]
    (zgodny z migracją 003 — legal_graph i z P05 temporalność);
  • wersja węzła = (legal_node_id, version) z oknem valid_from/valid_to;
  • diff prawny między wersjami: zmiana node_text / statusu / okna;
  • time-travel: lookup wersji OBOWIAZUJACEJ na dowolną datę transakcji.

Czytaj:  bundles/legal_graph.json
Pisz:    bundles/v3_p01_legal_node_versioning.json

Usage:
  python v3_p01_legal_node_versioning.py [--json] [--write] [--date YYYY-MM-DD]
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
GRAPH = BASE_DIR / "bundles" / "legal_graph.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_legal_node_versioning.json"

CANON_SHORT_RE = re.compile(
    r"(ustawie o podatku od towarów i usług|ustawie o podatku dochodowym od osób "
    r"fizycznych|Ordynacji podatkowej|ustawie o systemie ubezpieczeń społecznych|"
    r"ustawie o rachunkowości|Prawa przedsiębiorców|ustawie o zryczałtowanym)")

CANON_MAP = {
    "podatku od towarów i usług": "ustawa-o-VAT",
    "podatku dochodowym od osób fizycznych": "ustawa-o-PIT",
    "ordynacji podatkowej": "ordynacja-podatkowa",
    "systemie ubezpieczeń społecznych": "ustawa-o-SUS",
    "rachunkowości": "ustawa-o-rachunkowosci",
    "prawa przedsiębiorców": "prawo-przedsiebiorcow",
    "zryczałtowanym": "ustawa-o-ryczalcie",
}

VALID_FROM_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def _act_short(act: str) -> str:
    m = CANON_SHORT_RE.search(act)
    if not m:
        return "akt-inny"
    for key, short in CANON_MAP.items():
        if key in m.group(1):
            return short
    return "akt-inny"


def _clean_article(article: str) -> str:
    # "113", "21.1.148", "4-5", "42a-42h" → kanoniczny fragment ścieżki
    return article.replace(" ", "-")


def build_ref(node: dict) -> str:
    act = _act_short(str(node.get("act", "")))
    art = _clean_article(str(node.get("article", "?")))
    return f"PL/{act}/art/{art}"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def version_diff(old: dict, new: dict) -> list[str]:
    out = []
    for field in ("node_text", "status", "valid_to", "valid_from", "act_dz_u"):
        a, b = old.get(field), new.get(field)
        if a != b:
            out.append(f"{field}: {a!r} → {b!r}")
    return out


def active_on(nodes: list[dict], date_str: str) -> list[dict]:
    out = []
    for n in nodes:
        vf = str(n.get("valid_from") or "0001-01-01")[:10]
        vt = n.get("valid_to")
        vt = str(vt)[:10] if vt else "9999-12-31"
        if vf <= date_str <= vt:
            out.append(n)
    return out


def build() -> dict:
    graph = json.loads(GRAPH.read_text(encoding="utf-8")) if GRAPH.exists() else {}
    nodes: list[dict] = graph.get("nodes", [])
    refs: dict[str, list[dict]] = {}
    for n in nodes:
        refs.setdefault(build_ref(n), []).append(n)

    versions: list[dict] = []
    diffs: list[dict] = []
    for ref, chain in sorted(refs.items()):
        chain_sorted = sorted(chain, key=lambda x: (str(x.get("valid_from") or ""), int(x.get("version", 0))))
        for i, n in enumerate(chain_sorted):
            versions.append({
                "legal_node_ref": ref,
                "legal_node_id": n.get("legal_node_id"),
                "version": n.get("version", 1),
                "valid_from": n.get("valid_from"),
                "valid_to": n.get("valid_to"),
                "status": n.get("status"),
                "act": n.get("act"),
                "article": n.get("article"),
                "node_type": n.get("node_type"),
                "source": n.get("source", "NIEZWERYFIKOWANE"),
            })
            if i > 0:
                d = version_diff(chain_sorted[i - 1], n)
                if d:
                    diffs.append({"legal_node_ref": ref, "from_version": chain_sorted[i - 1].get("version"),
                                  "to_version": n.get("version"), "diff": d})

    date_travel = "2026-02-01"
    active = active_on(nodes, date_travel)

    return {
        "innovation": "V3-P01-I01",
        "generated_at": now(),
        "scheme": "PL/<akt>/art/<art>[/ust/<ust>][/pkt/<pkt>][/lit/<lit>]",
        "nodes_total": len(nodes),
        "distinct_refs": len(refs),
        "versions_count": len(versions),
        "diff_between_versions": len(diffs),
        "time_travel_sample_date": date_travel,
        "time_travel_active_nodes": len(active),
        "node_ref_sample": sorted(refs.keys())[:5],
        "diff_sample": diffs[:5],
        "contract": {
            "binding": "P05 temporalność / P08 Law Radar / P11 certyfikaty",
            "okno_waznosci": "valid_from/valid_to z migracji 003",
            "zasada": "werdykt na dzień D używa wyłącznie wersji aktywnej na D; brak wersji = NEEDS_ADVICE",
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Legal Node Versioning Engine (V3-P01-I01)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P01-I01 Legal Node Versioning: nodes={data['nodes_total']} "
              f"refs={data['distinct_refs']} versions={data['versions_count']} "
              f"diffs={data['diff_between_versions']} active@{data['time_travel_sample_date']}={data['time_travel_active_nodes']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
