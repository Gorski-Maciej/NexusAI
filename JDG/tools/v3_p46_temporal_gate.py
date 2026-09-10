#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I03 TEMPORAL PARAMETER GATE — parametr zmienny prawnie
bez valid_from/valid_to = BLOCKER (P05). Sprawdza thresholds_data.json oraz
bloki thresholds_jdg.rego (obowiązkowe valid_from w blokach v3_p46*).
Usage: python tools/v3_p46_temporal_gate.py
"""
from __future__ import annotations

import re

from v3_p46_common import (BUNDLES_DIR, RULES_DIR, THRESHOLDS_REGO, THRESHOLDS_DATA,
                           extract_threshold_block, read_json, write_bundle)

YEARLY_VARIABLE = re.compile(r"(rate|stawka|limit|próg|progu|kwota|threshold|zus|pit|vat)", re.IGNORECASE)


def check_thresholds_data() -> list[dict]:
    data = read_json(THRESHOLDS_DATA, {}) or {}
    violations = []
    for key, spec in data.get("parameters", {}).items():
        versions = spec.get("versions", [])
        if not versions:
            violations.append({"key": key, "reason": "brak wersji"})
            continue
        for v in versions:
            if not v.get("valid_from"):
                violations.append({"key": key, "reason": "wersja bez valid_from",
                                   "value": v.get("value")})
    return violations


def check_thresholds_blocks() -> list[dict]:
    violations = []
    src = THRESHOLDS_REGO.read_text(encoding="utf-8", errors="replace") if THRESHOLDS_REGO.exists() else ""
    for m in re.finditer(r"^(v3_p46[a-z_]*)\s*:=\s*\{", src, re.MULTILINE):
        block = extract_threshold_block(m.group(1)) or ""
        if '"valid_from"' not in block:
            violations.append({"key": m.group(1), "reason": "blok thresholds bez valid_from (P05)"})
    return violations


def main() -> int:
    v1 = check_thresholds_data()
    v2 = check_thresholds_blocks()
    violations = v1 + v2
    metrics = {
        "missing_valid_from": len(violations),
        "missing_valid_from_data": len(v1),
        "missing_valid_from_blocks": len(v2),
        "routing": "BLOCK_AND_ALERT" if violations else "AUTO_FILE",
    }
    write_bundle("temporal_gate", "V3-P46-I03", metrics, {
        "thresholds_data": "bundles/thresholds_data.json",
        "thresholds_rego": "rules/thresholds_jdg.rego",
        "violations": violations,
        "note": "P05: obowiązek podatkowy na datę zdarzenia — parametr bez okna = luka temporalna.",
    })
    print(f"[v3_p46_temporal_gate] violations={len(violations)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
