#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I02 CONTRADICTION CHECK — różne wyniki na tym samym input.

Pod-zbiór detektora I01 o NAJWYŻSZYM priorytecie (prompt P50 Sekcja 10 I02;
art. 24b OP — jedna interpretacja prawa na datę zdarzenia [NIEZWERYFIKOWANE
— ISAP]): para reguł o identycznym hashu semantycznym (warunki+skutek) z
RÓŻNYM decision_mode = sprzeczność — na tym samym input decyzja jest losowa.

To narzędzie jest warstwą klasyfikacji i decyzji nad I01 (jedno źródło prawdy
liczb; brak podwójnego parsowania):
  * contradictory_pairs z I01 → rejestr rozstrzygnięć
    (v3_p50_contradiction_resolutions.json: para → rozstrzygnięcie
    [source-of-truth per I04] + owner + date) — rozstrzygnięte wypadają
    z unresolved,
  * unresolved>0 lub bypass → BLOCK_AND_ALERT (spójnie z routing_cc02).

Baseline honesty: sprzeczności = realne pary z I01; zero para = zero.
Wyjście: bundles/v3_p50_contradictions.json.
"""
from __future__ import annotations

import json
from pathlib import Path

from v3_p50_common import BUNDLES_DIR, write_p50_bundle
from v3_p49_common import utcnow_iso

SRC = BUNDLES_DIR / "v3_p50_semantic_duplicates.json"
RESOLUTIONS = BUNDLES_DIR / "v3_p50_contradiction_resolutions.json"


def _pair_key(p: dict) -> str:
    a, b = p.get("a", {}), p.get("b", {})
    lo, hi = sorted([a.get("rule_id", ""), b.get("rule_id", "")])
    return f"{lo}||{hi}"


def main() -> int:
    if not SRC.exists():
        metrics = {"contradictory_pairs": 0, "unresolved": 0,
                   "resolved": 0, "routing": "TRIAGE_QUEUE"}
        evidence = {"note": "brak bundla I01 — uruchom detektor "
                            "(klasyfikacja bez dowodu = TRIAGE)."}
        write_p50_bundle("contradictions", "V3-P50-I02", metrics, evidence)
        print("[V3-P50-I02] missing I01 bundle → TRIAGE")
        return 0

    src = json.loads(SRC.read_text(encoding="utf-8"))
    contra = src.get("evidence", {}).get("contradictory_pairs", [])
    contra = contra if isinstance(contra, list) else []

    res = {"resolutions": []}
    if RESOLUTIONS.exists():
        try:
            res = json.loads(RESOLUTIONS.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            res = {"resolutions": []}
    resolved_keys = {r.get("pair_key") for r in res.get("resolutions", [])}

    unresolved, resolved = [], []
    for p in contra:
        k = _pair_key(p)
        (resolved if k in resolved_keys else unresolved).append(p)

    routing = ("BLOCK_AND_ALERT" if unresolved else "AUTO_FILE")
    metrics = {
        "contradictory_pairs": len(contra),
        "unresolved": len(unresolved),
        "resolved": len(resolved),
        "contradiction_max": 0,
        "routing": routing,
    }
    evidence = {
        "unresolved_sample": unresolved[:40],
        "resolved_keys": sorted(resolved_keys)[:40],
        "note": ("I02: identyczna semantyka (hash I01) + różny decision_mode "
                 "= decyzja losowa = BLOCK do rozstrzygnięcia. Rejestr "
                 "rozstrzygnięć: para → źródło prawdy (I04), owner, data; "
                 "rozstrzygnięte wypadają z unresolved (ale pozostają w "
                 "historii I01)."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("contradictions", "V3-P50-I02", metrics, evidence)
    print(f"[V3-P50-I02] pairs={len(contra)} unresolved={len(unresolved)} "
          f"resolved={len(resolved)} routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
