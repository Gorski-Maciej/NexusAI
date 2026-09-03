#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I10 VAT INVARIANTS PACK
=============================================
Pack niezmienników VAT dla P04: stawka ∈ {0,5,8,23,NP}, VAT ≥ 0, spójność
JPK (VAT należny − naliczony), suma podatku. Sprawdza, które inwarianty
istnieją w katalogu P04/regułach.

Usage:
  python tools/v3_p12_vat_invariants_pack.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"
TOOLS = BASE / "tools"

INVARIANTS = {
    "INV-VAT-1 rate ∈ {0,5,8,23,NP}": ["0", "5", "8", "23", "NP"],
    "INV-VAT-2 VAT amount ≥ 0": ["vat_amount", "kwota", ">=", "0"],
    "INV-VAT-3 JPK consistency (należny−naliczony)": ["naliczony", "należny", "jpk"],
    "INV-VAT-4 netto × rate = VAT (rounding)": ["netto", "round", "zaokrągl"],
    "INV-VAT-5 limit 113 nieprzekroczony bez sygnału": ["113", "limit"],
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    hay = "\n".join(f.read_text(encoding="utf-8", errors="ignore")
                    for f in RULES.glob("**/*.rego"))
    # Katalog invariantów P04 (bundle v3_p04_*)
    inv_bundles = sorted(p.name for p in BUNDLES.glob("v3_p04*.json"))
    inv_catalog = {}
    for b in inv_bundles:
        try:
            d = json.loads((BUNDLES / b).read_text(encoding="utf-8"))
            if isinstance(d, dict):
                inv_catalog[b] = list(d.keys())[:6]
        except Exception:
            pass
    catalog_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                            for p in BUNDLES.glob("v3_p04*.json"))

    statuses = {}
    for label, keys in INVARIANTS.items():
        name = label.split(" ")[0]
        # szukaj w regułach i katalogu P04
        found_in_rules = all(k in hay for k in keys[:3]) if len(keys) <= 5 else any(k in hay for k in keys)
        found_in_catalog = name.lower() in catalog_hay.lower() or label.split("]")[0].split(" ")[0] in catalog_hay
        statuses[label] = {"rules": found_in_rules, "p04_catalog": found_in_catalog}
    covered = sum(1 for s in statuses.values() if s["rules"])
    covered_cat = sum(1 for s in statuses.values() if s["p04_catalog"])

    checks.append({"name": "rate_set_invariant",
                   "status": "OK" if statuses["INV-VAT-1 rate ∈ {0,5,8,23,NP}"]["rules"] else "FAIL",
                   "detail": "INV-VAT-1: stawka ∈ {0,5,8,23,NP} w regułach: "
                             f"{statuses['INV-VAT-1 rate ∈ {0,5,8,23,NP}']['rules']}"})
    checks.append({"name": "non_negative_vat",
                   "status": "OK" if statuses["INV-VAT-2 VAT amount ≥ 0"]["rules"] else "FAIL",
                   "detail": "INV-VAT-2: VAT ≥ 0: "
                             f"{statuses['INV-VAT-2 VAT amount ≥ 0']['rules']}"})
    checks.append({"name": "jpk_consistency",
                   "status": "OK" if statuses["INV-VAT-3 JPK consistency (należny−naliczony)"]["rules"] else "FAIL",
                   "detail": "INV-VAT-3: spójność JPK: "
                             f"{statuses['INV-VAT-3 JPK consistency (należny−naliczony)']['rules']}"})
    checks.append({"name": "p04_catalog_entries",
                   "status": "OK" if covered_cat >= 3 else "FAIL",
                   "detail": f"inwarianty VAT w katalogu P04: {covered_cat}/{len(INVARIANTS)} "
                             f"(bundle P04: {len(inv_bundles)})"})

    if covered < 5 or covered_cat < 3:
        findings.append({"id": "V3-P12-L10", "severity": "P2",
                         "evidence": f"inwarianty VAT w regułach: {covered}/{len(INVARIANTS)}, "
                                     f"w katalogu P04: {covered_cat}/{len(INVARIANTS)} — pack "
                                     f"niekompletny; bez INV stawka∈set i spójności JPK ryzyko "
                                     f"cichej błędnej deklaracji (np. ujemny VAT, stawka spoza "
                                     f"setu)",
                         "fix": "I10: VAT Invariants Pack — 5 inwariantów (stawka∈set, VAT≥0, "
                                "spójność JPK, netto×rate, limit 113) jako wpisy P04 z "
                                "testami runtime"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I10", "generated_at": now(), "gate": gate,
        "metrics": {"invariants_in_rules": covered, "invariants_total": len(INVARIANTS),
                    "invariants_in_p04": covered_cat, "p04_bundles": inv_bundles,
                    "statuses": statuses},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P04 (inwarianty runtime), P16 (JPK), P03 (werdykt)",
                     "rule": "naruszony inwariant VAT = NEEDS_ADVICE/MANUAL_REVIEW, nigdy "
                             "cichy AUTO_POST"}}
    (BUNDLES / "v3_p12_vat_invariants_pack.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I10] gate={gate} rules={covered}/5 p04={covered_cat}/5")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
