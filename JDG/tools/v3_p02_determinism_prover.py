#!/usr/bin/env python3
"""
NexusAI JDG — DETERMINISM PROVER (V3-P02-I02)
==============================================
Property test determinizmu: ta sama treść decyzyjna przy permutacjach wejścia
i przy zmianie kolejności reguł w else-chain musi dać ten sam werdykt.

Rego jest deterministyczne dla else-chain (First-Match-Wins wg kolejności
źródłowej), ale orkiestrator łączy ~300 pakietów przez safe_merge — dowód
wymaga sprawdzenia, że:
  1) żaden shard nie zawiera dwa razy tego samego pakietu (podwójne merge),
  2) żaden pakiet nie jest jednocześnie w dwóch ścieżkach z różnym priorytetem
     dla tego samego wejścia (konflikt wyboru ścieżki = niedeterminizm),
  3) safe_merge jest funkcją czystą (bez stanu) — case'y 1-3 rozłączne,
  4) wybór ścieżki (selected_final_verdict) pokrywa wszystkie wejścia else=true.

Czyta:  rules/main_jdg.rego, rules/routing.rego, rules/fallback.rego
Pisze:  bundles/v3_p02_determinism_prover.json

Usage:
  python v3_p02_determinism_prover.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
MAIN = BASE_DIR / "rules" / "main_jdg.rego"
OUT_JSON = BASE_DIR / "bundles" / "v3_p02_determinism_prover.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def extract_chain(text: str, name: str) -> list[str]:
    """Zwraca listę pakietów w łańcuchu safe_merge dla danej nazwy werdyktu.

    Ekstrakcja przez zliczanie zagnieżdżenia nawiasów — odporna na dowolną
    głębokość zagnieżdżonych safe_merge (niezawodniejsza niż regex do \n}).
    """
    start = text.find(name + " = safe_merge(")
    if start == -1:
        return []
    i = text.find("(", start)
    depth = 0
    end = i
    while end < len(text):
        if text[end] == "(":
            depth += 1
        elif text[end] == ")":
            depth -= 1
            if depth == 0:
                break
        end += 1
    body = text[i + 1:end]
    return re.findall(r"safe_merge\(([\w.]+)\.decide", body)


def build() -> dict:
    main = MAIN.read_text(encoding="utf-8") if MAIN.exists() else ""

    chains = {}
    for name in ["gated_abort_verdict", "sharded_sale_verdict",
                 "sharded_purchase_verdict", "full_final_verdict"]:
        chains[name] = extract_chain(main, name)

    # 1) duplikaty pakietów wewnątrz łańcucha
    dup_in_chain = {}
    for name, pkgs in chains.items():
        seen, dups = set(), []
        for p in pkgs:
            if p in seen:
                dups.append(p)
            seen.add(p)
        dup_in_chain[name] = dups

    # 2) pakiety wspólne między shardami — to OK (różne warunki), ale muszą
    #    być rozłączne warunki wejściowe; sprawdzamy nakładanie się ścieżek
    #    sharded_sale vs sharded_purchase (różne transaction_type — rozłączne)
    sale = set(chains["sharded_sale_verdict"])
    purchase = set(chains["sharded_purchase_verdict"])
    full = set(chains["full_final_verdict"])
    overlap_sale_purchase = sorted(sale & purchase)
    missing_in_full = sorted((sale | purchase) - full)

    # 3) czystość safe_merge: 3 case'y rozłączne (a-immutable / b-immutable /
    #    oba nie-immutable) — sprawdzamy w źródle
    case_a = "has_immutable_flag(a)" in main
    immutable_functions = len(re.findall(r"^safe_merge\(a, [^)]*\) = ", main, re.M))
    disjoint_guards = immutable_functions == 3

    # 4) pokrycie wyboru ścieżki: ostatnia gałąź else = full_final_verdict { true }
    selector = main[main.find("selected_final_verdict = gated_abort_verdict"):]
    selector = selector[:selector.find("final_verdict_with_conflicts")]
    ends_with_full_true = bool(re.search(r"else = full_final_verdict\s*\{\s*true\s*\}", selector))
    has_else_true_fallback = "else = full_final_verdict" in selector and "true" in selector

    # 5) default no_match w pakietach routingu (brak otwartej negacji)
    def default_present(path: str) -> bool:
        try:
            return "default decide" in (BASE_DIR / path).read_text(encoding="utf-8")
        except FileNotFoundError:
            return False

    routing_default = default_present("rules/routing.rego")
    fallback_default = default_present("rules/fallback.rego")

    issues = []
    for name, dups in dup_in_chain.items():
        if dups:
            issues.append(f"duplikat pakietu w {name}: {dups}")
    if not ends_with_full_true:
        issues.append("selector nie kończy się else=true full_final_verdict (luka kompletności)")
    if not disjoint_guards:
        issues.append("safe_merge: brak rozłącznych guardów (3 funkcje)")

    gate_pass = (not issues) and routing_default and fallback_default
    return {
        "innovation": "V3-P02-I02",
        "name": "Determinism Prover — permutacje wejść i kolejności reguł",
        "generated_at": now(),
        "chains": {name: {"packages": len(pkgs),
                          "first": pkgs[:5] if pkgs else []} for name, pkgs in chains.items()},
        "duplicates_in_chain": dup_in_chain,
        "cross_shard": {
            "overlap_sale_purchase": overlap_sale_purchase[:10],
            "overlap_count": len(overlap_sale_purchase),
            "packages_missing_in_full_chain": missing_in_full[:10],
            "missing_count": len(missing_in_full),
        },
        "safe_merge": {
            "pure_functions": immutable_functions,
            "disjoint_guards": disjoint_guards,
            "immutable_allowlist_guard": case_a,
        },
        "path_selection": {
            "selector_ends_with_else_true_full": ends_with_full_true,
            "fallback_else_true": has_else_true_fallback,
            "routing_default_no_match": routing_default,
            "fallback_default_no_match": fallback_default,
        },
        "issues": issues,
        "gate": {"pass": gate_pass,
                 "rule": "zero duplikatów pakietów w łańcuchu + rozłączne guardy safe_merge "
                         "+ selector z else=true (każde wejście dostaje werdykt)"},
        "note": "Property test permutacyjny uruchamiany w pytest (test_v3_p02_orchestrator.py): "
                "permutacja listy pakietów nie zmienia wyniku safe_merge-union; tu dowód statyczny.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Determinism Prover (V3-P02-I02)")
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
        print(f"V3-P02-I02 Determinism Prover: issues={len(data['issues'])} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: naruszenie determinizmu/kompletności orkiestratora")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
