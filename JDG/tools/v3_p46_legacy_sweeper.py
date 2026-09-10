#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I10 LEGACY VALUE SWEEPER — po migracji: skan kodu w
poszukiwaniu „osieroconych" wartości prawnych (liczby wyglądające jak stawki/
progi poza thresholds) — rejestr do weryfikacji. Wyklucza thresholds_jdg.rego
(kanon ADR-002), pliki testów (testy mają prawo mieć wartości graniczne jako
dane testowe P36) oraz wartości strukturalne (roki, ms→dni, 86400 s).
Usage: python tools/v3_p46_legacy_sweeper.py
"""
from __future__ import annotations

from v3_p46_common import (RULES_DIR, THRESHOLDS_REGO, scan_hardcoded,
                           sha256_file, write_bundle, write_json)

import json

STRUCTURAL_HINTS = ("86400", "3600", "1000", "24", "60", "365")


def is_structural(value: str) -> bool:
    digits = value.split(".")[0]
    return any(h in digits for h in STRUCTURAL_HINTS)


def main() -> int:
    result = scan_hardcoded(RULES_DIR, exclude={THRESHOLDS_REGO.name})
    findings = result["findings"]
    orphans = []
    extreme = []
    for f in findings:
        val = f["value"]
        if f["category"] == "large_integer" and len(val) == 4 and val.startswith("20"):
            continue  # rok
        if is_structural(val):
            continue
        orphans.append(f)
        try:
            x = float(val)
            if x >= 1_000_000 or (0 < x < 1):
                extreme.append(f)
        except ValueError:
            pass
    by_category = {}
    for f in findings:
        by_category[f["category"]] = by_category.get(f["category"], 0) + 1
    # trend: porównanie z poprzednim pomiarem (historia jak stub_census P45)
    history_path = __import__("pathlib").Path(__import__("v3_p46_common").BUNDLES_DIR) / "v3_p46_orphan_history.json"
    history = []
    prev = None
    if history_path.exists():
        try:
            history = json.loads(history_path.read_text(encoding="utf-8"))
            prev = history[-1].get("orphan_total") if history else None
        except json.JSONDecodeError:
            prev = None
    trend = "declining" if (prev is not None and len(orphans) < prev) else (
        "rising" if (prev is not None and len(orphans) > prev) else "baseline")
    history.append({"measured_at": __import__("v3_p46_common").utcnow_iso(),
                    "orphan_total": len(orphans), "findings_total": len(findings),
                    "sha256_thresholds": sha256_file(THRESHOLDS_REGO) if THRESHOLDS_REGO.exists() else ""})
    write_json(history_path, history)
    metrics = {
        "scanned_files": result["scanned_files"],
        "findings_total": len(findings),
        "orphan_values": len(orphans),
        "extreme_literals": len(extreme),
        "by_category": by_category,
        "trend": trend,
        "previous_total": prev,
        "routing": ("BLOCK_AND_ALERT" if len(orphans) > 0 and trend == "rising"
                    else "TRIAGE_QUEUE" if len(orphans) > 0 else "AUTO_FILE"),
    }
    top = orphans[:25]
    write_bundle("legacy_sweep", "V3-P46-I10", metrics, {
        "orphan_register_sample": top,
        "history": "bundles/v3_p46_orphan_history.json",
        "note": ("Backlog rejestrowany uczciwie (honesty protokół 14): licznik z "
                 "narzędzia, migracja value-po-value wg mapy I01; gate merge P45 "
                 "blokuje wzrost w plikach zmienianych."),
    })
    print(f"[v3_p46_legacy_sweeper] files={result['scanned_files']} "
          f"orphans={len(orphans)} trend={trend}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
