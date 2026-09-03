#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I02 INTENT COMPILER
=========================================
Parser deklaracji → precyzyjny plan zmian (parametry/reguły/testy) z wyrokiem
pewności. Weryfikuje, że cel istnieje w store parametrów (P06) lub rejestrze
reguł (P07) — kompilacja do nieistniejącego klucza = FAIL.

Usage:
  python tools/v3_p09_intent_compiler.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

SAMPLES = [
    ("Stawka VAT na usługi IT od 2027-01-01: 23% -> 8%", "vat.standard_rate", 0.08),
    ("Próg skali podatkowej od 2026-01-01: 120000 -> 130000", "pit.scale_threshold", 130000),
    ("Nowelizacja ustawy o VAT: art. 113 ust. 1 — limit obrotu", "vat.art113_limit", None),
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    store = json.loads((BUNDLES / "thresholds_data.json").read_text(encoding="utf-8"))
    params = set(store.get("parameters", {}).keys())
    dc = (TOOLS / "declarative_change.py").read_text(encoding="utf-8")
    # klucz docelowy w declarative_change.py execute
    hardcoded_key = re.search(r'"parameter":\s*"([\w.]+)"', dc)

    resolved = []
    for text, expect_key, _ in SAMPLES:
        exists = expect_key in params
        resolved.append({"sample": text, "expected_key": expect_key,
                         "in_store": exists})
    drift = [r for r in resolved if not r["in_store"]]

    checks.append({"name": "target_exists_in_store", "status": "FAIL" if drift else "OK",
                   "detail": f"klucze spoza store: {[r['expected_key'] for r in drift]}"})
    checks.append({"name": "compiler_precision", "status": "FAIL",
                   "detail": "parser regex nie mapuje na istniejące klucze — zwraca tylko "
                             "kind/groups"})

    findings.append({"id": "V3-P09-L02", "severity": "P1",
                     "evidence": f"declarative_change.py execute zapisuje parametr "
                                 f"'{hardcoded_key.group(1) if hardcoded_key else '?'}' — klucz "
                                 f"NIEISTNIEJĄCY w thresholds_data.json (store zawiera tylko "
                                 f"{sorted(params)}); kompilacja nie weryfikuje celu → zmiana "
                                 "danych nie dociera do decyzji (dead write)",
                     "fix": "I02 Intent Compiler: parser → plan z kluczem zweryfikowanym w "
                            "store/rejestrze + verdict pewności; brak klucza = odrzucenie"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I02", "generated_at": now(), "gate": gate,
        "metrics": {"samples": len(SAMPLES), "targets_missing": len(drift),
                    "store_params": sorted(params),
                    "hardcoded_target_key": hardcoded_key.group(1) if hardcoded_key else None},
        "resolution": resolved,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P09-I01 (schema), P06 (store parametrów), P07 (rejestr reguł)",
                     "rule": "cel kompilacji musi istnieć w store/rejestrze; inaczej "
                             "FAIL przed planem"}}
    (BUNDLES / "v3_p09_intent_compiler.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I02] gate={gate} missing={len(drift)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
