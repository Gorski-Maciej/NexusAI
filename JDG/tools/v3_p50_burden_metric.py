#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I12 DUPLICATE BURDEN METRIC — % reguł-duplikatów.

Wskaźnik zdrowia tożsamości reguł (prompt P50 Sekcja 10 I12; AP04; trend →
P37 Obserwowalność): % reguł będących duplikatami semantycznymi; cel 0%.

Źródło prawdy liczb: bundle detektora I01 (v3_p50_semantic_duplicates.json,
OPA AST) — to narzędzie NIE przelicza od nowa (jedno źródło prawdy), tylko
agreguje: burden_pct, klasyfikacja par (identyczne / sprzeczne / temporalne),
spójność routing z polityką P50 oraz trend (historia przebiegów zapisywana
inkrementalnie do evidence.trend).

Fail-closed: brak bundla I01 albo rules_total==0 = TRIAGE (metryka bez
dowodu); burden>0 = TRIAGE (konsolidacja wg I04/I09); sprzeczne>0 =
BLOCK_AND_ALERT (spójnie z polityką routing_db12/I02).
Wyjście: bundles/v3_p50_duplicate_burden.json.
"""
from __future__ import annotations

import json
from pathlib import Path

from v3_p50_common import BUNDLES_DIR, write_p50_bundle
from v3_p49_common import utcnow_iso

SRC = BUNDLES_DIR / "v3_p50_semantic_duplicates.json"
TREND = BUNDLES_DIR / "v3_p50_burden_trend.json"


def main() -> int:
    if not SRC.exists():
        metrics = {"rules_total": 0, "duplicate_rules": 0, "burden_pct": 0.0,
                   "contradictory_pairs": 0, "target_pct": 0,
                   "routing": "TRIAGE_QUEUE"}
        evidence = {"note": "brak bundla detektora I01 — uruchom "
                            "v3_p50_duplicate_detector.py (metryka bez "
                            "dowodu = TRIAGE)."}
        write_p50_bundle("duplicate_burden", "V3-P50-I12", metrics, evidence)
        print("[V3-P50-I12] missing I01 bundle → TRIAGE")
        return 0

    src = json.loads(SRC.read_text(encoding="utf-8"))
    m = src["metrics"]
    total = int(m.get("rules_total", 0))
    dup_rules = int(m.get("duplicate_rules", 0))
    burden = float(m.get("burden_pct", 0.0))
    contra = int(m.get("contradictory_pairs", 0))

    routing = ("BLOCK_AND_ALERT" if contra > 0
               else ("TRIAGE_QUEUE" if total == 0 or burden > 0
                     else "AUTO_FILE"))

    # trend inkrementalny (historia do P37)
    trend = []
    if TREND.exists():
        try:
            trend = json.loads(TREND.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            trend = []
    trend.append({"at": utcnow_iso(), "rules_total": total,
                  "duplicate_rules": dup_rules, "burden_pct": burden,
                  "contradictory_pairs": contra, "routing": routing})
    TREND.write_text(json.dumps(trend[-50:], ensure_ascii=False, indent=2)
                     + "\n", encoding="utf-8")

    metrics = {
        "rules_total": total,
        "duplicate_rules": dup_rules,
        "duplicate_pairs": int(m.get("duplicate_pairs", 0)),
        "temporal_variant_pairs": int(m.get("temporal_variant_pairs", 0)),
        "contradictory_pairs": contra,
        "burden_pct": burden,
        "target_pct": 0,
        "parse_errors": int(m.get("parse_errors", 0)),
        "routing": routing,
    }
    evidence = {
        "method": m.get("method"),
        "trend_entries": len(trend),
        "trend_first": trend[0] if trend else None,
        "note": ("I12: burden z detektora I01 (jedno źródło prawdy; brak "
                 "podwójnego liczenia). Cel 0%; trend → P37 dashboard "
                 "Duplicate Burden. parse_errors>0 = część reguł poza "
                 "analizą AST (jawny backlog detektora — L)."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("duplicate_burden", "V3-P50-I12", metrics, evidence)
    print(f"[V3-P50-I12] rules={total} dup_rules={dup_rules} "
          f"burden={burden}% contra={contra} routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
