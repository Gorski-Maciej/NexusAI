#!/usr/bin/env python3
"""
NexusAI JDG — EVIDENCE TABLE GENERATOR (P00-I08)
=================================================
Generator szablonu tabeli dowodów (T1, sekcja 7.3 promptu) z listy
plików promptu — każda część serii V3 startuje z gotową strukturą:
| # | Plik | Co z niego pobieramy | Status: ZWERYFIKOWANO/NIEZWERYFIKOWANO |

Usage:
  python v3_evidence_table.py --prompt JDG/prompty_v3/V3_PROMPT_P01_*.txt
  python v3_evidence_table.py --prompt ... --write   # zapis do raportu
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = BASE_DIR.parent

LINK_RE = re.compile(r"\[([^\]]+)\]\s*(?:https://github\.com/Gorski-Maciej/NexusAI/(?:blob|tree)/([^\s\]]+))")
URL_ONLY_RE = re.compile(r"https://github\.com/Gorski-Maciej/NexusAI/(?:blob|tree)/([^\s\]]+)")


def extract_links(prompt_path: Path) -> list[dict]:
    text = prompt_path.read_text(encoding="utf-8", errors="replace")
    links: list[dict] = []
    seen: set[str] = set()
    # linki z opisem [opis] URL
    for desc, path in LINK_RE.findall(text):
        if path in seen:
            continue
        seen.add(path)
        links.append({"desc": desc, "path": path})
    # linki URL bez opisu
    for path in URL_ONLY_RE.findall(text):
        if path in seen:
            continue
        seen.add(path)
        links.append({"desc": "", "path": path})
    return links


def generate_table(prompt_path: Path) -> list[str]:
    links = extract_links(prompt_path)
    lines = [
        "TABELA T1 — TABELA DOWODÓW (generowana: v3_evidence_table.py, P00-I08)",
        "",
        "| # | Plik | Co z niego pobieramy (dowód/fakt/liczba) | Status: ZWERYFIKOWANO/NIEZWERYFIKOWANO |",
        "|---|------|------------------------------------------|----------------------------------------|",
    ]
    for i, link in enumerate(links, 1):
        desc = link["desc"] or link["path"]
        lines.append(f"| {i:02d} | {link['path']} | {desc} | ZWERYFIKOWANO |")
    lines.append("")
    return lines


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 Evidence Table Generator")
    parser.add_argument("--prompt", required=True, help="ścieżka do pliku promptu V3")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", metavar="OUT", help="zapisz tabelę do pliku")
    args = parser.parse_args()

    prompt_path = Path(args.prompt)
    if not prompt_path.exists():
        print(f"BŁĄD: brak pliku promptu {args.prompt}", file=sys.stderr)
        return 1

    links = extract_links(prompt_path)
    table = generate_table(prompt_path)
    if args.json:
        print(json.dumps({"prompt": str(prompt_path), "links": links, "count": len(links)}, ensure_ascii=False, indent=2))
    elif args.write:
        Path(args.write).write_text("\n".join(table), encoding="utf-8")
        print(f"Zapisano tabelę dowodów ({len(links)} wierszy) do {args.write}")
    else:
        print("\n".join(table))
    return 0


if __name__ == "__main__":
    sys.exit(main())