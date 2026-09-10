#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I04 SCHEMA VALIDATION FOR THRESHOLDS — JSON-schema dla
thresholds_data.json walidowana w CI: typ, jednostka, zakres (min/max), okno
temporalne. Błąd jednostki niewykrywalny kodem reguł zostanie złapany w danych.
Usage: python tools/v3_p46_schema_validator.py [--schema bundles/v3_p46_thresholds_schema.json]
"""
from __future__ import annotations

import argparse
import re

from v3_p46_common import (BUNDLES_DIR, THRESHOLDS_DATA, read_json, utcnow_iso,
                           write_bundle, write_json)

SCHEMA_PATH = BUNDLES_DIR / "v3_p46_thresholds_schema.json"

KNOWN_UNITS = ["PLN", "PLN_MIN", "EUR", "PERCENT", "RATIO", "MULTIPLIER",
               "DAYS", "YEARS", "COUNT", "RATE", "M2", "TEXT"]

# Schemat normatywny (I04): struktura wpisu parametru w thresholds_data.
SCHEMA = {
    "schema_id": "v3_p46_thresholds_data_schema-2026.09",
    "valid_from": "2026-01-01",
    "type_rules": {
        "number": {"python_types": ["int", "float"], "forbid": ["str", "bool", "None"]},
        "string": {"python_types": ["str"], "forbid": ["int", "float", "bool"]},
    },
    "unit_catalog": KNOWN_UNITS,
    "required_fields": ["value", "valid_from"],
    "optional_fields": ["valid_to", "source_act", "changed_by", "changed_at", "isap_status"],
    "range_semantics": {
        "PERCENT_RATIO": "wartości rate w [0,1] mają unit RATIO; PERCENT w [0,100]",
        "PLN": "kwoty ≥ 0",
        "DAYS": "liczby całkowite ≥ 0",
    },
}


def validate_entry(key: str, spec: dict) -> list[str]:
    errors = []
    versions = spec.get("versions", [])
    schema = spec.get("schema", {})
    if not isinstance(versions, list) or not versions:
        errors.append(f"{key}: brak tablicy versions")
        return errors
    unit = schema.get("unit")
    if unit is not None and unit not in KNOWN_UNITS:
        errors.append(f"{key}: jednostka '{unit}' poza katalogiem (I08)")
    for i, v in enumerate(versions):
        if not isinstance(v, dict):
            errors.append(f"{key}[{i}]: wersja nie jest obiektem")
            continue
        if "value" not in v:
            errors.append(f"{key}[{i}]: brak value")
        if not v.get("valid_from"):
            errors.append(f"{key}[{i}]: brak valid_from (P05/I03)")
        val = v.get("value")
        declared_type = schema.get("type")
        if declared_type == "number" and not isinstance(val, (int, float)):
            errors.append(f"{key}[{i}]: typ number oczekiwany, jest {type(val).__name__} (błąd jednostki?)")
        if declared_type == "string" and not isinstance(val, str):
            errors.append(f"{key}[{i}]: typ string oczekiwany, jest {type(val).__name__}")
        mn, mx = schema.get("min"), schema.get("max")
        if isinstance(val, (int, float)):
            try:
                if mn is not None and val < float(mn):
                    errors.append(f"{key}[{i}]: wartość {val} < min {mn}")
                if mx is not None and val > float(mx):
                    errors.append(f"{key}[{i}]: wartość {val} > max {mx}")
            except (TypeError, ValueError):
                errors.append(f"{key}[{i}]: nieprawidłowa granica min/max w schemacie")
    return errors


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--schema", default=str(SCHEMA_PATH))
    args = ap.parse_args()
    if not SCHEMA_PATH.exists():
        write_json(SCHEMA_PATH, SCHEMA)
    data = read_json(THRESHOLDS_DATA, {}) or {}
    errors: list[str] = []
    checked = 0
    for key, spec in data.get("parameters", {}).items():
        checked += 1
        errors.extend(validate_entry(key, spec))
    metrics = {
        "checked": True,
        "parameters_checked": checked,
        "errors": len(errors),
        "schema_id": SCHEMA["schema_id"],
        "routing": "BLOCK_AND_ALERT" if errors else "AUTO_FILE",
    }
    write_bundle("schema_validation", "V3-P46-I04", metrics, {
        "schema": "bundles/v3_p46_thresholds_schema.json",
        "validated_document": "bundles/thresholds_data.json",
        "error_list": errors,
    })
    print(f"[v3_p46_schema_validator] checked={checked} errors={len(errors)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
