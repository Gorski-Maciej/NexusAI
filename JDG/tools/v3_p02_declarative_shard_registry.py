#!/usr/bin/env python3
"""
NexusAI JDG — DECLARATIVE SHARD REGISTRY (V3-P02-I09)
======================================================
Shardy rejestrowane deklaratywnie (JSON) — dodanie domeny bez dotykania
orkiestratora (zgodnie z V2/F6 Declarative Change). Eksportuje aktualne
łańcuchy safe_merge z main_jdg.rego do rejestru JSON: shard → pakiety →
warunki routingu. Nowa domena = nowy wpis w rejestrze (dane), nie edycja
main_jdg.rego.

Czyta:  rules/main_jdg.rego (łańcuchy + warunki)
Pisze:  bundles/v3_p02_declarative_shard_registry.json

Usage:
  python v3_p02_declarative_shard_registry.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
MAIN = BASE_DIR / "rules" / "main_jdg.rego"
OUT_JSON = BASE_DIR / "bundles" / "v3_p02_declarative_shard_registry.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def extract_chain(text: str, name: str) -> list[str]:
    """Ekstrakcja przez zliczanie nawiasów — odporna na głębokie zagnieżdżenie."""
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
    for name, cond in [
        ("gated_abort_verdict", "risk/routing BLOCK_AND_ALERT → early abort"),
        ("sharded_sale_verdict", "DOMESTIC_SALE + ACTIVE + krajowa"),
        ("sharded_purchase_verdict", "DOMESTIC_PURCHASE + ACTIVE + krajowa"),
        ("full_final_verdict", "cross-border / non-ACTIVE / else (pełny łańcuch)"),
    ]:
        pkgs = extract_chain(main, name)
        chains[name] = {"packages": pkgs, "condition": cond, "package_count": len(pkgs)}

    # schema rejestru deklaratywnego (F6)
    registry_schema = {
        "schema_version": "1.0.0",
        "kind": "jdg.shard_registry",
        "entries": [{
            "shard": "gated_abort_verdict",
            "condition": "risk._routing == BLOCK_AND_ALERT or routing._routing == BLOCK_AND_ALERT",
            "packages": chains["gated_abort_verdict"]["packages"],
            "owner": "domain",
            "lifecycle": "ACTIVE",
        }],
        "contract": "nowa domena: dodaj pakiet do rejestru (dane) — orkiestrator "
                    "czyta rejestr, nie listę w kodzie (V2/F6, ADR-009).",
    }

    # Reconciliation w przestrzeni ALIASÓW zmiennych: _package_decisions mapuje
    # pełną nazwę pakietu ("jdg.zus") na alias używany w łańcuchach (zus.decide).
    # Porównujemy aliasy łańcucha z aliasami w mapie decyzyjnej (nie pełne nazwy).
    m = re.search(r"_package_decisions\s*:?=\s*\{(.*?)\n\}", main, re.S)
    dec_aliases = set()
    dec_entries = 0
    if m:
        body = m.group(1)
        dec_entries = len(re.findall(r'^\s*"[^"]+"\s*:', body, re.M))
        dec_aliases = set(re.findall(r'"[^"]+"\s*:\s*([\w.]+)\.decide', body))

    full = set(chains["full_final_verdict"]["packages"])
    # aliasy w łańcuchu, których nie ma w mapie decyzyjnej = orphan (bez provenance)
    in_full_not_in_dec = sorted(full - dec_aliases)
    # aliasy zmapowane, których nie ma w full chain = pakiet decyzyjny poza łańcuchem
    # (może być w shardzie sale/purchase — to nie błąd, tylko sygnał do audytu)
    in_dec_not_in_full = sorted(dec_aliases - full)

    issues = []
    if in_full_not_in_dec:
        issues.append(f"aliasy w full_final_verdict poza _package_decisions (orphan, brak provenance): "
                      f"{in_full_not_in_dec[:10]}")

    gate_pass = len(issues) == 0
    return {
        "innovation": "V3-P02-I09",
        "name": "Declarative Shard Registry — domena bez edycji orkiestratora",
        "generated_at": now(),
        "shards": chains,
        "registry_schema": registry_schema,
        "reconciliation": {
            "decisions_map_entries": dec_entries,
            "decisions_map_aliases": len(dec_aliases),
            "aliases_in_full_chain": len(full),
            "aliases_in_full_chain_not_in_decisions_map": in_full_not_in_dec[:15],
            "aliases_in_decisions_map_not_in_full_chain": in_dec_not_in_full[:15],
        },
        "issues": issues,
        "gate": {"pass": gate_pass,
                 "rule": "spójność aliasów: każdy pakiet w łańcuchu full ma wpis w mapie "
                         "decyzyjnej (provenance); zero orphan-pakietów (V3-08..12 domknięte)"},
        "note": "rejestr eksportowany z kodu (aktualny stan); docelowo źródłem jest "
                "JSON data.jdg.shard_registry — orkiestrator czyta rejestr (F6).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Declarative Shard Registry (V3-P02-I09)")
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
        print(f"V3-P02-I09 Declarative Shard Registry: shards={len(data['shards'])} "
              f"issues={len(data['issues'])} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: niespójność rejestru shardów")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
