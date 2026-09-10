#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I02 VALUE PROVENANCE CHAIN — pełne DNA wartości:
parametr → akt → art. → nowela → data → zmiana (diff). Rozszerza DNA reguł
(P42) o dane. Parametr bez łańcucha o głębokości ≥ próg = BLOCK w rego I02.
Usage: python tools/v3_p46_value_provenance.py
"""
from __future__ import annotations

from v3_p46_common import (BUNDLES_DIR, THRESHOLDS_DATA, read_json, write_bundle)


def build_provenance() -> dict:
    data = read_json(THRESHOLDS_DATA, {}) or {}
    parameters = data.get("parameters", {})
    audit = data.get("changed_by_audit", [])
    entries = []
    weak = []
    for key, spec in sorted(parameters.items()):
        versions = spec.get("versions", [])
        for v in versions:
            chain = [
                v.get("source_act", "") or "",
                f"valid_from={v.get('valid_from', '')}",
                f"changed_by={v.get('changed_by', '')}",
                f"changed_at={v.get('changed_at', '')}",
            ]
            depth = sum(1 for c in chain if c)
            entry = {
                "parameter": key,
                "value": v.get("value"),
                "source_act": v.get("source_act", ""),
                "valid_from": v.get("valid_from", ""),
                "changed_by": v.get("changed_by", ""),
                "changed_at": v.get("changed_at", ""),
                "chain_depth": depth,
            }
            entries.append(entry)
            if depth < 3:
                weak.append(entry)
    return {
        "entries": entries,
        "audit_rows": len(audit),
        "weak_chain": weak,
        "min_depth_observed": min((e["chain_depth"] for e in entries), default=0),
    }


def main() -> int:
    prov = build_provenance()
    metrics = {
        "parameters_with_provenance": len(prov["entries"]),
        "weak_chain_count": len(prov["weak_chain"]),
        "audit_rows": prov["audit_rows"],
        "min_depth_observed": prov["min_depth_observed"],
        "routing": "BLOCK_AND_ALERT" if prov["weak_chain"] else "AUTO_FILE",
    }
    write_bundle("value_provenance", "V3-P46-I02", metrics, {
        "thresholds_data": "bundles/thresholds_data.json",
        "note": "chain_depth = liczba niepustych ogniw (akt, okno, autor, czas).",
    })
    out = BUNDLES_DIR / "v3_p46_value_provenance.json"
    out.write_text(
        out.read_text(encoding="utf-8").replace('"evidence": {',
            f'"evidence": {{\n    "weak_chain": {json_dumps(prov["weak_chain"])},'),
        encoding="utf-8")
    print(f"[v3_p46_value_provenance] entries={len(prov['entries'])} "
          f"weak={len(prov['weak_chain'])}")
    return 0


def json_dumps(obj) -> str:
    import json
    return json.dumps(obj, ensure_ascii=False)


if __name__ == "__main__":
    raise SystemExit(main())
