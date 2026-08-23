#!/usr/bin/env python3
"""ETAP GLM 5.2 / PROMPT_01 — Temporal Interval Gate (Kontrakt C3).

Algebra interwałów czasowych dla reguł OPA/Rego modułu JDG:
  1. Wyciąga z plików Rego pary (rule_id → valid_from/valid_to).
  2. Wykrywa LUKI (gap): dla tej samej reguły koniec wersji A < początek wersji B
     (istnieje data bez żadnej wersji reguły).
  3. Wykrywa NAKŁADKI (overlap): dwie wersje tej samej reguły aktywne w tej
     samej dacie (więcej niż jeden kandydat na datę).
  4. Wykrywa reguły BEZ temporalności (brak valid_from) — wymagane przez
     Kontrakt C3 dla reguł matched=true.

Wyjście: JSON (--json) lub tekst. Exit code: 0 = zero luk/nakładek, 1 = znaleziono.
Zgodność: ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md §6, WIZJA_OPA_ENTERPRISE_V2 F1 (TCL).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import date
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = ROOT / "rules"

DATE_RE = re.compile(r"(\d{4}-\d{2}-\d{2})")
VALID_FROM_RE = re.compile(
    r'["\']valid_from["\']\s*[:=]\s*["\'](\d{4}-\d{2}-\d{2})["\']'
)
VALID_TO_RE = re.compile(
    r'["\']valid_to["\']\s*[:=]\s*(?:["\'](\d{4}-\d{2}-\d{2})["\']|null|0)'
)
RULE_ID_RE = re.compile(r'["\']rule_id["\']\s*:\s*["\']([^"\']+)["\']')


def parse_date(s: str) -> date | None:
    try:
        return date.fromisoformat(s)
    except ValueError:
        return None


def extract_intervals(path: Path) -> list[dict[str, Any]]:
    """Dla jednego pliku: lista interwałów (rule_id, valid_from, valid_to)."""
    txt = path.read_text(encoding="utf-8", errors="replace")
    blocks: list[dict[str, Any]] = []
    # Podział na bloki `decide :=`/`decide =` (else-chain) — przybliżony,
    # ale deterministyczny: interwały przypisujemy do najbliższego rule_id.
    current_rule: str | None = None
    current_from: date | None = None
    current_to: date | None = None

    def flush() -> None:
        nonlocal current_rule, current_from, current_to
        if current_rule is not None:
            blocks.append({
                "rule_id": current_rule,
                "valid_from": current_from.isoformat() if current_from else None,
                "valid_to": current_to.isoformat() if current_to else None,
            })
        current_rule, current_from, current_to = None, None, None

    for line in txt.splitlines():
        m = RULE_ID_RE.search(line)
        if m:
            flush()
            current_rule = m.group(1)
            continue
        mf = VALID_FROM_RE.search(line)
        if mf and current_rule is not None:
            current_from = parse_date(mf.group(1))
            continue
        mt = VALID_TO_RE.search(line)
        if mt and current_rule is not None:
            current_to = parse_date(mt.group(1)) if mt.group(1) else None
    flush()
    return blocks


def analyze(blocks: list[dict[str, Any]]) -> dict[str, Any]:
    by_rule: dict[str, list[dict[str, Any]]] = defaultdict(list)
    no_temporal: list[str] = []
    for b in blocks:
        by_rule[b["rule_id"]].append(b)
        if b["valid_from"] is None:
            no_temporal.append(b["rule_id"])

    gaps: list[dict[str, Any]] = []
    overlaps: list[dict[str, Any]] = []
    for rule_id, vers in by_rule.items():
        vers = sorted(vers, key=lambda v: (v["valid_from"] or "0000-01-01"))
        for a, b in zip(vers, vers[1:]):
            a_to = a["valid_to"]
            b_from = b["valid_from"]
            if a_to and b_from:
                if a_to < b_from:
                    gaps.append({"rule_id": rule_id, "od": a_to, "do": b_from})
                elif b_from < a_to:
                    overlaps.append({"rule_id": rule_id, "wersja_a": a, "wersja_b": b})
        # nakładka wewnątrz tej samej daty (duplikat valid_from w jednej regule)
        seen_from: dict[str, int] = {}
        for v in vers:
            if v["valid_from"]:
                seen_from[v["valid_from"]] = seen_from.get(v["valid_from"], 0) + 1
        for d, c in seen_from.items():
            if c > 1:
                overlaps.append({"rule_id": rule_id, "data": d, "duplikaty": c})

    return {
        "reguly_ze_temporalnoscia": len(by_rule) - len(set(no_temporal)),
        "reguly_bez_temporalnosci": len(set(no_temporal)),
        "luki": gaps,
        "nakladki": overlaps,
        "ok": not gaps and not overlaps,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Temporal Interval Gate (Kontrakt C3)")
    ap.add_argument("--json", action="store_true", help="wyjście JSON")
    ap.add_argument("--rules-dir", type=Path, default=RULES_DIR)
    args = ap.parse_args()

    all_blocks: list[dict[str, Any]] = []
    per_file: dict[str, Any] = {}
    for p in sorted(args.rules_dir.rglob("*.rego")):
        blocks = extract_intervals(p)
        if blocks:
            res = analyze(blocks)
            per_file[str(p.relative_to(ROOT))] = {
                "interwaly": len(blocks),
                **res,
            }
            all_blocks.extend(blocks)

    total = analyze(all_blocks)
    report = {
        "bramka": "temporal_interval_gate",
        "kontrakt": "C3 (zero luk, zero nakładek, TCL 100%)",
        "pliki_ze_skanem": len(per_file),
        "interwaly_znalezione": len(all_blocks),
        "wynik": total,
        "per_file": per_file,
    }
    if args.json:
        print(json.dumps(report, indent=1, ensure_ascii=False))
    else:
        print(f"Temporal Interval Gate — pliki: {len(per_file)}, interwały: {len(all_blocks)}")
        print(f"  reguły z temporalnością: {total['reguly_ze_temporalnoscia']}")
        print(f"  reguły BEZ temporalności: {total['reguly_bez_temporalnosci']}")
        print(f"  LUKI (gap): {len(total['luki'])}")
        for g in total["luki"][:20]:
            print(f"    GAP {g['rule_id']}: {g['od']} → {g['do']}")
        print(f"  NAKŁADKI (overlap): {len(total['nakladki'])}")
        for o in total["nakladki"][:20]:
            print(f"    OVERLAP {o}")
        print("  WYNIK:", "OK — zero luk i nakładek" if total["ok"] else "NARUSZENIE — patrz wyżej")
    return 0 if total["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
