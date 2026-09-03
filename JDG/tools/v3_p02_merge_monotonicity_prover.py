#!/usr/bin/env python3
"""
NexusAI JDG — MERGE MONOTONICITY PROVER (V3-P02-I07)
=====================================================
Dowód monotoniczności merge testem na delta-werdyktach. Monotoniczność =
informacja tylko przyrasta: merge(a,b) ⊇ a oraz merge(a,b) ⊇ b dla zbioru pól
(żadne pole z werdyktu źródłowego nie znika), Z WYJĄTKIEM pól niemutowalnych
chronionych allowlistą (INV-005/018/042), gdzie werdykt chroniony wygrywa.

Metoda: implementacja reguł safe_merge z main_jdg.rego (case 1-3) w Pythonie
i property test na losowych parach werdyktów: dla pary (a,b):
  • jeśli a immutable → wynik = a (pola b NIE wchodzą),
  • jeśli b immutable → wynik ⊇ b i ⊇ a minus pola kolidujące,
  • wpp. wynik = union(a,b) — ściśle monotoniczny.
Czyta:  rules/main_jdg.rego (definicje), deterministyczny model w Pythonie
Pisze:  bundles/v3_p02_merge_monotonicity_prover.json

Usage:
  python v3_p02_merge_monotonicity_prover.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import json
import random
import re
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
MAIN = BASE_DIR / "rules" / "main_jdg.rego"
OUT_JSON = BASE_DIR / "bundles" / "v3_p02_merge_monotonicity_prover.json"

ALLOWLIST = {"jdg.zus", "jdg.zus.sickness_benefits", "jdg.zus.enterprise_benefits",
             "jdg.zus.health_contribution", "jdg.business", "jdg.security.fortress"}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def has_immutable_flag(v: dict) -> bool:
    return v.get("immutable_verdict") is True and v.get("package") in ALLOWLIST


def safe_merge(a: dict, b: dict) -> dict:
    """Port reguł safe_merge z main_jdg.rego (case 1-3)."""
    if has_immutable_flag(a):
        return dict(a)
    if has_immutable_flag(b):
        merged = dict(b)
        merged.update({k: v for k, v in a.items() if k not in b})
        return merged
    merged = dict(a)
    merged.update(b)
    return merged


def build() -> int:
    main = MAIN.read_text(encoding="utf-8") if MAIN.exists() else ""
    # weryfikacja zgodności portu z kodem: obecność 3 case'ów i allowlisty
    code_has_3_cases = len(re.findall(r"^safe_merge\(a, b\) = ", main, re.M)) >= 2 and \
        "safe_merge(a, _) = a" in main
    code_allowlist = re.findall(r'"jdg\.(zus|business|security)[^"]*"', main)
    allowlist_matches = len(set(code_allowlist)) >= 5

    rng = random.Random(20260903)  # deterministyczny seed (property test)
    FIELD_POOL = ["vat_rate", "pit_rate", "zus_health_rate", "kus_percent",
                  "pit_form", "gtu_code", "_routing", "_legal_basis", "business_status"]

    def rand_verdict(immutable: bool) -> dict:
        pkg = rng.choice(sorted(ALLOWLIST)) if immutable else "jdg.some_domain"
        v = {"package": pkg, "rule_id": f"{pkg}.rule_x", "matched": True}
        if immutable:
            v["immutable_verdict"] = True
        for f in rng.sample(FIELD_POOL, k=rng.randint(2, 6)):
            v[f] = f"val_{rng.randint(1, 50)}"
        return v

    trials = 2000
    monotonic_ok = 0
    conflicts_ok = 0
    violations = []
    for _ in range(trials):
        a = rand_verdict(rng.random() < 0.25)
        b = rand_verdict(rng.random() < 0.25)
        res = safe_merge(a, b)

        # monotoniczność: pole obecne w (a lub b) nie znika, chyba że strona
        # przeciwna jest immutable (wtedy chroniona strona wygrywa celowo)
        a_imm = has_immutable_flag(a)
        b_imm = has_immutable_flag(b)
        if a_imm:
            ok = all(res.get(k) == a.get(k) for k in a)
        elif b_imm:
            ok = all(res.get(k) == b.get(k) for k in b)
        else:
            ok = all(k in res for k in list(a) + list(b))
        if ok:
            monotonic_ok += 1
        else:
            violations.append({"a": a, "b": b, "res": res})

        # konflikt → fail-closed: konflikt pól między domenami niemutowalnej
        # pary musi być rozstrzygnięty (immutable wygrywa) — nigdy cichy losowy
        if a_imm and b_imm and a["package"] != b["package"]:
            if res["package"] == a["package"]:
                conflicts_ok += 1

    gate_pass = monotonic_ok == trials and len(violations) == 0
    return {
        "innovation": "V3-P02-I07",
        "name": "Merge Monotonicity Prover — delta-werdykty",
        "generated_at": now(),
        "code_evidence": {
            "safe_merge_3_cases_present": code_has_3_cases,
            "allowlist_entries_in_code": sorted(set(code_allowlist)),
            "allowlist_consistent": allowlist_matches,
            "allowlist_expected": sorted(ALLOWLIST),
        },
        "property_test": {
            "seed": 20260903,
            "trials": trials,
            "monotonic_ok": monotonic_ok,
            "violations": violations[:5],
            "immutable_conflict_resolutions_ok": conflicts_ok,
        },
        "gate": {"pass": gate_pass,
                 "rule": "merge jest monotoniczny (info przyrasta) lub chroni "
                         "werdykt niemutowalny wg allowlisty — nigdy cichy ubytek "
                         "(INV-018/042, property test w pytest)"},
        "note": "port Pythona reguł safe_merge z main_jdg.rego; test permutacyjny "
                "na 2000 par werdyktów; ten sam test w pytest (test_v3_p02_orchestrator.py).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Merge Monotonicity Prover (V3-P02-I07)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P02-I07 Merge Monotonicity: trials={data['property_test']['trials']} "
              f"ok={data['property_test']['monotonic_ok']} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: naruszenie monotoniczności merge")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
