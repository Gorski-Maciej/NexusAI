#!/usr/bin/env python3
"""NexusAI JDG — VAT RATE HARMONIZATION GATE (PROMPT_03, Kontrakt C2).

Wymusza KANONICZNY format pola ``vat_rate`` w werdyktach Rego w całym
rules/ — fundament dual-layer binding (mikro == makro == thresholds):

  KANON (liczbowy):   ^\\d\\.\\d{2}$        np. "0.23", "0.08", "0.05", "0.00"
  KANON (tokenowy):   ZW | NP | OO | ""    (zwolnienie, nie podlega, odwrotne
                                            obciążenie, brak stawki)

ZABRONIONE: formaty "%" ("23%"), słowne ("23"), "0%" — łamały spójność
werdyktów mikro↔makro i utrudniały agregację JPK_V7 / raporty.

Tryby:
  python tools/vat_rate_harmonization_gate.py            # skan + exit code
  python tools/vat_rate_harmonization_gate.py --fix      # automatyczna poprawka

Exit code: 0 = czysto; 1 = naruszenia (CI blokuje).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = ROOT / "rules"

RATE_FIELD_RE = re.compile(r'"(vat_rate|pit_rate)"\s*:\s*"([^"]*)"')
# VAT: ^d.dd$ (0.23); PIT dopuszcza 3 miejsca (0.085 = 8.5% skladki/stawki)
CANON_NUMERIC = re.compile(r"^\d\.\d{2,3}$")
CANON_TOKENS = {"ZW", "NP", "OO", ""}
RATE_MAP = {"23%": "0.23", "8%": "0.08", "5%": "0.05", "0%": "0.00", "23": "0.23", "8": "0.08", "5": "0.05", "0": "0.00",
            "19%": "0.19", "12%": "0.12", "15%": "0.15", "8.5%": "0.085", "32%": "0.32"}


def scan() -> tuple[list[tuple[Path, int, str, str]], int]:
    violations: list[tuple[Path, int, str, str]] = []
    total = 0
    for p in sorted(RULES_DIR.rglob("*.rego")):
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        # tylko kod (bez komentarzy)
        code = re.sub(r"#.*$", "", text, flags=re.M)
        for m in RATE_FIELD_RE.finditer(code):
            total += 1
            field, val = m.group(1), m.group(2)
            if CANON_NUMERIC.match(val) or val in CANON_TOKENS:
                continue
            line = code.count("\n", 0, m.start()) + 1
            violations.append((p.relative_to(ROOT), line, field, val))
    return violations, total


def fix() -> int:
    n = 0
    for p in sorted(RULES_DIR.rglob("*.rego")):
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue

        def repl(m: re.Match) -> str:
            nonlocal n
            field, val = m.group(1), m.group(2)
            if val in RATE_MAP:
                n += 1
                return f'"{field}": "{RATE_MAP[val]}"'
            return m.group(0)

        updated = RATE_FIELD_RE.sub(repl, text)
        if updated != text:
            p.write_text(updated, encoding="utf-8")
            print(f"[FIX] {p.relative_to(ROOT)}")
    return n


def main() -> int:
    ap = argparse.ArgumentParser(description="Rate harmonization gate (vat_rate + pit_rate)")
    ap.add_argument("--fix", action="store_true", help="auto-fix violations")
    ap.add_argument("--json", action="store_true", help="JSON output")
    args = ap.parse_args()

    if args.fix:
        n = fix()
        print(f"Poprawiono {n} pól vat_rate.")
        return 0

    violations, total = scan()
    if args.json:
        import json

        print(json.dumps({
            "gate": "rate_harmonization",
            "fields_scanned": total,
            "violations": [{"file": str(f), "line": ln, "field": fl, "value": v} for f, ln, fl, v in violations],
            "ok": len(violations) == 0,
        }, ensure_ascii=False, indent=1))
        return 0 if not violations else 1

    print(f"RATE HARMONIZATION GATE — pola vat_rate/pit_rate: {total}")
    if violations:
        print(f"NARUSZENIA ({len(violations)}):")
        for f, ln, fl, v in violations[:25]:
            print(f"  {f}:{ln}: {fl} = {v!r}  (kanon: liczbowy ^d.dd(?:d)?$ lub ZW/NP/OO/\"\")")
        return 1
    print("OK — wszystkie pola vat_rate/pit_rate w formacie kanonicznym (mikro == makro).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
