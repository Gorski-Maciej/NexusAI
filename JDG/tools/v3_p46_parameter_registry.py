#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I01 PARAMETER REGISTRY — zapytywalny rejestr parametrów:
ścieżka, wartość bieżąca, historia (wersje), akt źródłowy, okno temporalne,
właściciel, checksuma. Rejestr łączy thresholds_data.json (kanał fe:N — dane
produkcyjne) z v3_p46_migration_map (fe:N — cele migracji do weryfikacji ISAP
w P47). Usage: python tools/v3_p46_parameter_registry.py [--write]
"""
from __future__ import annotations

import argparse

from v3_p46_common import (BASE, BUNDLES_DIR, THRESHOLDS_DATA, extract_threshold_block,
                           read_json, sha256_file, utcnow_iso, write_bundle, write_json)

DOC_ANCHORS = BUNDLES_DIR / "v3_p46_parameter_doc_anchors.json"


def build_registry() -> dict:
    data = read_json(THRESHOLDS_DATA, {}) or {}
    parameters = data.get("parameters", {})
    mig_block = extract_threshold_block("v3_p46_migration_map") or ""
    entries = {}
    for key, spec in sorted(parameters.items()):
        versions = spec.get("versions", [])
        schema = spec.get("schema", {})
        latest = versions[-1] if versions else {}
        entries[key] = {
            "current_value": latest.get("value"),
            "unit": schema.get("unit", "unknown"),
            "versions_count": len(versions),
            "history": [
                {"value": v.get("value"), "valid_from": v.get("valid_from"),
                 "valid_to": v.get("valid_to"), "source_act": v.get("source_act", ""),
                 "changed_by": v.get("changed_by", ""), "changed_at": v.get("changed_at", "")}
                for v in versions
            ],
            "temporal_window": bool(latest.get("valid_from")),
            "source_act": latest.get("source_act", ""),
            "isap_status": latest.get("isap_status", "NIEZWERYFIKOWANE"),
            "owner": latest.get("changed_by", "unassigned"),
            "schema": schema,
        }
    # cele migracji (fe:N) jako wpisy rejestru z flagą fe:N
    for key in sorted(set(__import__("re").findall(r'"(v3_p46_mig_[a-z0-9_]+)"', mig_block))):
        if key.endswith(("_version", "_pattern")):
            continue
        entries[f"migration.{key.replace('v3_p46_mig_', '')}"] = {
            "current_value": "fe:N",
            "unit": "fe:N",
            "versions_count": 0,
            "history": [],
            "temporal_window": True,
            "source_act": "kandydat do weryfikacji ISAP (P47) — zero wartości z pamięci",
            "isap_status": "NIEZWERYFIKOWANE",
            "owner": "p46-migration",
            "schema": {},
            "migration_target": True,
        }
    registry_age_days = 0
    doc_anchors = read_json(DOC_ANCHORS, {}) or {}
    documented = sum(1 for k in entries if doc_anchors.get("anchors", {}).get(k))
    return {
        "generated_at": utcnow_iso(),
        "total": len(entries),
        "registry_age_days": registry_age_days,
        "documented": documented,
        "without_anchor": len(entries) - documented,
        "migration_targets": sum(1 for e in entries.values() if e.get("migration_target")),
        "entries": entries,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()
    registry = build_registry()
    out = BUNDLES_DIR / "v3_p46_parameter_registry_data.json"
    write_json(out, registry)
    checksum = sha256_file(THRESHOLDS_DATA)
    metrics = {
        "total": registry["total"],
        "documented": registry["documented"],
        "without_anchor": registry["without_anchor"],
        "migration_targets": registry["migration_targets"],
        "registry_age_days": registry["registry_age_days"],
        "thresholds_data_sha256": checksum,
    }
    write_bundle("parameter_registry", "V3-P46-I01", metrics, {
        "registry": "bundles/v3_p46_parameter_registry_data.json",
        "thresholds_data": "bundles/thresholds_data.json",
        "thresholds_data_sha256": checksum,
        "note": "fe:N — stawki nie są trzymane w kodzie; cel weryfikacji ISAP w P47.",
    })
    print(f"[v3_p46_parameter_registry] total={registry['total']} "
          f"documented={registry['documented']} registry={out.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
