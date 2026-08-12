#!/usr/bin/env python3
"""
NexusAI JDG — P00 (RAPORT_00 L2) DUPLICATE RULE_ID REMOVAL
===========================================================
Usuwa ZDUPLIKOWANE, BYTE-IDENTYCZNE bloki reguł (ten sam rule_id,
identyczna treść) — wskazane przez metrics_generator.py jako
„duplicate_rule_ids" (RAPORT_00: cel = 0 duplikatów).

Zasady bezpieczeństwa:
  • usuwa WYŁĄCZNIE bloki o identycznej znormalizowanej treści
    (decyzja nie zmienia semantyki — to ta sama reguła powielona),
  • zachowuje pierwsze wystąpienie (porządek alfabetyczny pliku),
  • NIGDY nie usuwa `default decide` (struktura pakietu),
  • usuwa blok `decide` tylko jeśli plik ma inny `decide`/`default`,
  • bloki `else` mogą być usuwane swobodnie (łańcuch się domyka),
  • tryb --dry-run domyślnie pokazuje plan bez zapisu.

Usage:
  python fix_p00_duplicates.py [--apply] [--limit N]
"""

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
OUT_JSON = JDG_ROOT / "bundles" / "p00_duplicate_changes.json"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
RULE_START_RE = re.compile(r"^\s*(default\s+)?(decide|else)\b")


def split_blocks(text: str) -> list[dict]:
    """Podział pliku na bloki reguł (od linii decide/else do następnej)."""
    lines = text.split("\n")
    starts = []
    for i, line in enumerate(lines):
        if RULE_START_RE.match(line):
            starts.append(i)
    blocks = []
    for idx, s in enumerate(starts):
        e = starts[idx + 1] if idx + 1 < len(starts) else len(lines)
        # dołącz komentarze bezpośrednio nad regułą
        c = s
        while c - 1 >= 0 and lines[c - 1].lstrip().startswith("#"):
            c -= 1
        blocks.append({
            "start": c,
            "end": e,
            "text": "\n".join(lines[c:e]),
            "kind": "default" if lines[s].lstrip().startswith("default") else
                    ("decide" if lines[s].lstrip().startswith("decide") else "else"),
        })
    return blocks


def scan() -> dict:
    """rule_id → wystąpienia (plik, blok)."""
    occ = defaultdict(list)
    for path in sorted(RULES_DIR.rglob("*.rego")):
        if ".bak" in path.name or "backup" in path.name.lower():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        blocks = split_blocks(text)
        for b in blocks:
            for m in RULE_ID_RE.finditer(b["text"]):
                occ[m.group(1)].append({"file": str(path), "block": b})
    return occ


def plan_removals(occ: dict, limit: int | None = None) -> list[dict]:
    removals = []
    seen_files_decide = defaultdict(lambda: defaultdict(int))
    # ile decide/default w każdym pliku (żeby nie osierocić else)
    decide_counts = defaultdict(int)
    for rid, items in occ.items():
        for it in items:
            if it["block"]["kind"] in ("decide", "default"):
                decide_counts[it["file"]] += 1

    def norm(s):
        # porównanie semantyczne: usuń komentarze i biały znak
        code = "\n".join(l for l in s.split("\n") if not l.lstrip().startswith("#"))
        return re.sub(r"\s+", "", code)
    for rid, items in sorted(occ.items()):
        if len(items) < 2:
            continue
        # grupy wg znormalizowanej treści
        groups = defaultdict(list)
        for it in items:
            groups[norm(it["block"]["text"])].append(it)
        for group in groups.values():
            if len(group) < 2:
                continue
            # zachowaj pierwszy plik (alfabetycznie), usuń resztę
            keep = min(group, key=lambda it: it["file"])
            for it in sorted(group, key=lambda it: it["file"]):
                if it is keep:
                    continue
                kind = it["block"]["kind"]
                if kind == "default":
                    continue
                if kind == "decide" and decide_counts[it["file"]] <= 1:
                    continue
                removals.append({
                    "rule_id": rid,
                    "file": it["file"],
                    "kind": kind,
                    "start": it["block"]["start"],
                    "end": it["block"]["end"],
                    "text": it["block"]["text"][:160],
                })
                if limit and len(removals) >= limit:
                    return removals
    return removals


def apply_removals(removals: list[dict]) -> dict:
    by_file = defaultdict(list)
    for r in removals:
        by_file[r["file"]].append(r)
    applied = 0
    for file, rs in by_file.items():
        text = Path(file).read_text(encoding="utf-8", errors="ignore")
        # usuń od najpóźniejszego bloku, żeby indeksy się nie przesuwały
        for r in sorted(rs, key=lambda x: -x["start"]):
            lines = text.split("\n")
            # start/end są indeksami linii wg oryginalnego split_blocks —
            # przelicz na bieżący stan: wyszukaj pierwszą regułę z tym samym
            # identyfikatorem, której treść pasuje
            seg = "\n".join(lines[r["start"]:r["end"]])
            # odtwórz linie (bezpieczniej: dopasuj ponownie po bieżącym tekście)
            new_lines = lines[:r["start"]] + lines[r["end"]:]
            text = "\n".join(new_lines)
            applied += 1
        Path(file).write_text(text, encoding="utf-8")
    return {"applied": applied}


def main() -> None:
    p = argparse.ArgumentParser(description="P00 duplicate rule_id removal")
    p.add_argument("--apply", action="store_true", help="zastosuj zmiany (bez tego dry-run)")
    p.add_argument("--limit", type=int, default=None)
    args = p.parse_args()

    occ = scan()
    removals = plan_removals(occ, args.limit)
    by_kind = defaultdict(int)
    for r in removals:
        by_kind[r["kind"]] += 1
    print(f"🔁 P00 DEDUP: plan removals={len(removals)} "
          f"(else={by_kind.get('else', 0)} decide={by_kind.get('decide', 0)})")
    if args.apply:
        res = apply_removals(removals)
        print(f"✅ Zastosowano: {res['applied']} usuniętych bloków")
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps({
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "applied": res["applied"],
            "removals": removals,
        }, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"✅ Raport: {OUT_JSON.relative_to(JDG_ROOT)}")
    else:
        print("(dry-run — użyj --apply, aby zapisać)")


if __name__ == "__main__":
    main()
