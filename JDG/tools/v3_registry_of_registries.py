#!/usr/bin/env python3
"""
NexusAI JDG — REGISTRY OF REGISTRIES (P00-I02)
===============================================
Jeden indeks wszystkich rejestrów modułu JDG (rule_registry, legal_graph,
metrics_pewnosci, coverage_canon, coverage_deserts, healthy_versions,
manifest_v2, thresholds_data, v3_campaign_ledger) z wykrywaniem
sprzeczności liczbowych między nimi — bo każdy rejestr twierdzi co innego.

Usage:
  python v3_registry_of_registries.py        # raport sprzeczności (bramka)
  python v3_registry_of_registries.py --json # JSON na stdout
  python v3_registry_of_registries.py --write
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
OUT_JSON = BUNDLES_DIR / "v3_registry_of_registries.json"

# Rejestry i ich autorytatywne liczby (klucze JSON -> opis metryki)
REGISTRIES = {
    "manifest_v2.json": {"label": "MANIFEST 2.0 (P01)", "metrics": {}},
    "rule_registry.json": {"label": "Rule Registry", "metrics": {}},
    "metrics_pewnosci.json": {"label": "Metrics Pewności (Pewność Dashboard)", "metrics": {}},
    "coverage_canon.json": {"label": "Coverage Canon (AD-01)", "metrics": {}},
    "coverage_deserts.json": {"label": "Coverage Deserts", "metrics": {}},
    "healthy_versions.json": {"label": "Healthy Versions (bundle)", "metrics": {}},
    "thresholds_data.json": {"label": "Thresholds Data (ADR-002)", "metrics": {}},
    "legal_graph.json": {"label": "Legal Graph (LKG)", "metrics": {}},
    "v3_campaign_ledger.json": {"label": "V3 Campaign Ledger (P00-I06)", "metrics": {}},
}


def load(name: str):
    path = BUNDLES_DIR / name
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"__error__": "invalid JSON"}


def extract_metrics(name: str, data: dict) -> dict:
    """Wyciągnij kluczowe liczby z każdego rejestru (odpornie na brak kluczy)."""
    m: dict = {}
    if data is None:
        return {"status": "BRAK_PLIKU"}
    if "__error__" in data:
        return {"status": "USZKODZONY_JSON"}
    if name == "manifest_v2.json":
        r = data.get("rules", {})
        m = {
            "rego_files": r.get("rego_files"),
            "rule_blocks": r.get("rule_blocks"),
            "matched_blocks": r.get("matched_blocks"),
            "unique_rule_ids": r.get("unique_rule_ids"),
            "duplicate_rule_ids": r.get("duplicate_rule_ids"),
            "stub_count": r.get("stub_count"),
            "tools": data.get("tools", {}).get("python_tools"),
            "generated_at": data.get("generated_at"),
        }
    elif name == "rule_registry.json":
        m = {"entries": len(data) if isinstance(data, dict) else None, "generated_at": data.get("generated_at") if isinstance(data, dict) else None}
    elif name == "metrics_pewnosci.json":
        m = {
            "lci": data.get("lci"),
            "tcl": data.get("tcl"),
            "rv": data.get("rv"),
            "uvr": data.get("uvr"),
            "duplikaty": data.get("duplikaty"),
            "stuby": data.get("stuby"),
            "generated_at": data.get("generated_at"),
        }
    elif name == "coverage_canon.json":
        met = data.get("metrics", {})
        m = {"lci": met.get("lci"), "tcl": met.get("tcl"), "rv": met.get("rv"), "uvr": met.get("uvr"), "generated_at": data.get("generated_at")}
    elif name == "coverage_deserts.json":
        m = {"desert_nodes": data.get("desert_nodes"), "total_nodes": data.get("total_nodes"),
             "desert_pct": data.get("desert_pct"), "alarm": data.get("alarm"), "generated_at": data.get("generated_at")}
    elif name == "healthy_versions.json":
        m = {"built": len(data.get("built", [])), "healthy": len(data.get("healthy", [])), "generated_at": data.get("generated_at")}
    elif name == "thresholds_data.json":
        m = {"parameters": len(data.get("parameters", {})), "changed_by_audit": len(data.get("changed_by_audit", []))}
    elif name == "legal_graph.json":
        m = {"nodes": len(data.get("nodes", [])) if isinstance(data, dict) else None,
             "edges": len(data.get("edges", [])) if isinstance(data, dict) else None,
             "generated_at": data.get("generated_at") if isinstance(data, dict) else None}
    elif name == "v3_campaign_ledger.json":
        s = data.get("summary", {})
        m = {"total": s.get("total"), "wdrozony_100": s.get("wdrozony_100"), "generated_at": data.get("generated_at")}
    return m


def find_conflicts(extracted: dict[str, dict]) -> list[dict]:
    """Porównaj metryki wspólne między rejestrami — każda rozbieżność = konflikt Cxx."""
    conflicts: list[dict] = []
    dup_claims = []
    stub_claims = []
    rule_claims = []
    for name, m in extracted.items():
        if m.get("duplicate_rule_ids") is not None:
            dup_claims.append((name, m["duplicate_rule_ids"]))
        if m.get("stuby") is not None or m.get("stub_count") is not None:
            stub_claims.append((name, m.get("stuby") or m.get("stub_count")))
        if m.get("unique_rule_ids") is not None:
            rule_claims.append((name, m["unique_rule_ids"]))
    if len({v for _, v in dup_claims}) > 1:
        conflicts.append({"kind": "CONFLIKT_DUPLIKATY", "claims": dup_claims,
                          "message": "Rejestry podają różne liczby duplikatów rule_id — jedno źródło prawdy wymagane (P50)."})
    if len({v for _, v in stub_claims}) > 1:
        conflicts.append({"kind": "CONFLIKT_STUBY", "claims": stub_claims,
                          "message": "Rejestry podają różne liczby stubów {true} — jedno źródło prawdy wymagane (P45)."})
    if len({v for _, v in rule_claims}) > 1:
        conflicts.append({"kind": "CONFLIKT_RULE_ID", "claims": rule_claims,
                          "message": "Rejestry podają różne liczby unikalnych rule_id — rekoncyliacja wymagana."})
    # LCI: coverage_canon vs metrics_pewnosci
    lci_claims = [(n, m.get("lci")) for n, m in extracted.items() if m.get("lci") is not None]
    if len({v for _, v in lci_claims}) > 1:
        conflicts.append({"kind": "CONFLIKT_LCI", "claims": lci_claims,
                          "message": "Różne wartości LCI (pokrycie prawne) między rejestrami — metryka kanoniczna to coverage_canon (AD-01)."})
    return conflicts


def build() -> dict:
    extracted: dict[str, dict] = {}
    for name, meta in REGISTRIES.items():
        data = load(name)
        extracted[name] = {"label": meta["label"], **extract_metrics(name, data)}
    conflicts = find_conflicts(extracted)
    return {
        "schema_version": "1.0.0",
        "report": "V3_REGISTRY_OF_REGISTRIES",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "registries": extracted,
        "conflicts": conflicts,
        "conflict_count": len(conflicts),
        "status": "KONFLIKTY_WYKRYTO" if conflicts else "SPÓJNE",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 Registry of Registries")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    data = build()
    if args.write:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3 REGISTRY OF REGISTRIES: {data['status']} — {data['conflict_count']} sprzeczności")
        for c in data["conflicts"]:
            print(f"  ! {c['kind']}: {c['message']}")
            print(f"    claims: {c['claims']}")
    return 1 if data["conflicts"] else 0


if __name__ == "__main__":
    sys.exit(main())