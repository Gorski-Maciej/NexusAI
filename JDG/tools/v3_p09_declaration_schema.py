#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I01 DECLARATION SCHEMA v1
================================================
Pełny JSON Schema deklaracji zmiany z walidacją dat, zakresów i podstaw
prawnych (LKG/P01). Kanon pól: co, gdzie, od kiedy, podstawa, uzasadnienie.

Usage:
  python tools/v3_p09_declaration_schema.py
"""
from __future__ import annotations

import json
import re
from datetime import date, datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

SCHEMA_V1 = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "JDG Declaration of Legal Change v1",
    "type": "object",
    "required": ["declaration_id", "change_type", "domain", "target",
                 "new_value", "valid_from", "legal_basis", "justification",
                 "declared_by"],
    "properties": {
        "declaration_id": {"type": "string", "pattern": "^DEC-[0-9]{6}-[A-Z0-9]{4}$"},
        "change_type": {"enum": ["RATE_CHANGE", "THRESHOLD_CHANGE", "NEW_LIMIT",
                                 "DEADLINE_CHANGE", "REPEAL", "DEFINITION_CHANGE"]},
        "domain": {"enum": ["vat", "pit", "zus", "ryczalt", "ord", "ksef", "business"]},
        "target": {"type": "object", "required": ["kind", "key"],
                   "properties": {"kind": {"enum": ["parameter", "rule", "limit"]},
                                  "key": {"type": "string"}}},
        "new_value": {}, "old_value": {},
        "valid_from": {"type": "string", "format": "date"},
        "valid_to": {"type": ["string", "null"], "format": "date"},
        "legal_basis": {"type": "object", "required": ["act", "article"],
                        "properties": {"act": {"type": "string"},
                                       "article": {"type": "string"},
                                       "dz_u": {"type": "string"}}},
        "justification": {"type": "string", "minLength": 10},
        "declared_by": {"type": "string"},
        "reviewers": {"type": "array", "items": {"type": "string"}},
    },
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    dc = (TOOLS / "declarative_change.py").read_text(encoding="utf-8")
    # czy istniejący parser waliduje wg JSON Schema / czy tylko regex?
    validates_schema = "jsonschema" in dc or "JSONSchema" in dc or "schema" in dc.lower()
    only_regex = "PATTERNS" in dc

    checks.append({"name": "schema_validation_in_tool",
                   "status": "FAIL" if not validates_schema else "OK",
                   "detail": "declarative_change.py waliduje wyłącznie regexem — brak "
                              "walidacji wg JSON Schema v1"})
    checks.append({"name": "date_range_validation", "status": "FAIL",
                   "detail": "brak walidacji valid_from<=valid_to i spójności dat"})
    checks.append({"name": "lkg_legal_basis_check", "status": "FAIL",
                   "detail": "brak weryfikacji istnienia przepisu w LKG (P01)"})

    findings.append({"id": "V3-P09-L01", "severity": "P1",
                     "evidence": "declarative_change.py parsuje zgłoszenia wyłącznie 3 regexami "
                                 "(RATE_CHANGE/THRESHOLD_CHANGE/LEGAL_CHANGE); nie istnieje "
                                 "JSON Schema deklaracji ani walidacja dat/zakresów/istnienia "
                                 "przepisu — zmiana niepełna przechodzi do planu",
                     "fix": "I01 Declaration Schema v1 (ten artefakt): JSON Schema z polami "
                            "co/gdzie/od kiedy/podstawa/uzasadnienie + walidacja dat, zakresów "
                            "i podstawy w LKG"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I01", "generated_at": now(), "gate": gate,
        "metrics": {"schema_validation_in_tool": validates_schema, "only_regex": only_regex,
                    "required_fields": len(SCHEMA_V1["required"])},
        "schema": SCHEMA_V1,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P09-I02 (intent compiler wg schematu), P41 (UI formularza), "
                                "P06 (parametry), P01 (LKG legal basis)",
                     "rule": "każda deklaracja przed kompilacją walidowana wg SCHEMA_V1; "
                             "brak pola wymaganego = odrzucenie (fail-closed)"},
    }
    (BUNDLES / "v3_p09_declaration_schema.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I01] gate={gate} validates_schema={validates_schema}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
