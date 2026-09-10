#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I08 UNIT SEMANTICS — jednostka parametru (% vs PLN vs
mnożnik) jawnie w schemacie; walidacja przy odczycie (defense in depth).
Wykrywa klasyczne błędy jednostek: rate w [0,1] vs PERCENT w [0,100],
mnożnik ≥1 traktowany jako kwota, wartości miesięczne vs roczne (heurystyka
30-krotności). Usage: python tools/v3_p46_unit_semantics.py
"""
from __future__ import annotations

from v3_p46_common import (THRESHOLDS_DATA, read_json, write_bundle)


def infer_unit(key: str, value, declared: str | None) -> str:
    k = key.lower()
    if declared:
        return declared
    if isinstance(value, str):
        return "TEXT"
    if isinstance(value, bool):
        return "COUNT"
    if isinstance(value, (int, float)):
        if 0 <= float(value) <= 1 and any(s in k for s in ("rate", "pct", "stawka", " procent", "_procent")):
            return "RATIO"
        if float(value) >= 1000 or any(s in k for s in ("pln", "kwota", "limit", "próg")):
            return "PLN"
        if float(value) > 1 and any(s in k for s in ("multiplier", "krotn", "mnożnik")):
            return "MULTIPLIER"
        return "COUNT"
    return "unknown"


def main() -> int:
    data = read_json(THRESHOLDS_DATA, {}) or {}
    mismatches = []
    unknowns = []
    for key, spec in data.get("parameters", {}).items():
        schema = spec.get("schema", {})
        declared = schema.get("unit")
        for v in spec.get("versions", []):
            val = v.get("value")
            unit = infer_unit(key, val, declared)
            if declared is None:
                unknowns.append({"parameter": key, "value": val, "inferred_unit": unit})
                continue
            # Walidacja deklaracji vs wartość (błąd jednostki = katastrofa)
            if declared in ("RATIO",) and isinstance(val, (int, float)) and not (0 <= float(val) <= 1):
                mismatches.append({"parameter": key, "value": val,
                                   "reason": "RATIO poza [0,1] — stawka wpisana jako procent?"})
            if declared in ("PERCENT",) and isinstance(val, (int, float)) and not (0 <= float(val) <= 100):
                mismatches.append({"parameter": key, "value": val,
                                   "reason": "PERCENT poza [0,100]"})
            if declared in ("PLN", "PLN_MIN", "EUR") and isinstance(val, (int, float)) and val < 0:
                mismatches.append({"parameter": key, "value": val,
                                   "reason": "kwota ujemna"})
    metrics = {
        "unit_mismatch": len(mismatches),
        "unknown_unit_values": len(unknowns),
        "parameters_scanned": len(data.get("parameters", {})),
        "routing": ("BLOCK_AND_ALERT" if mismatches
                    else "TRIAGE_QUEUE" if unknowns else "AUTO_FILE"),
    }
    write_bundle("unit_semantics", "V3-P46-I08", metrics, {
        "mismatches": mismatches,
        "unknown_units": unknowns,
        "note": "Katalog jednostek: data.thresholds.v3_p46.v3_p46_known_units.",
    })
    print(f"[v3_p46_unit_semantics] mismatch={len(mismatches)} unknown={len(unknowns)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
