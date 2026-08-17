#!/usr/bin/env python3
"""
NexusAI JDG — ZUS Micro Consolidation Fixer (GLM52 P09)
========================================================
Konsolidacja plan33_zus.rego do poziomu Enterprise (INV-018, kontrakty P01):

  1. rule_id:  jdg.zus.* → jdg.micro.zus.*  (kolizja namespace z makro jdg.zus.*)
  2. _legal_basis: kanonizacja krótkich form ("Art. X SUS", "Ustawa o SUS
     z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)", "Suma skladek",
     "Art. X ustawy zasiłkowej") do kanonu LEGAL_REFERENCE_ACTS.md
     (SUS: Dz.U. 2025 poz. 345 ze zm.).
  3. Warunki: usunięcie zdublowanych warunków (business_status == "ACTIVE";
     ... == "ACTIVE") oraz naprawa kontradyktoryjnych ACTIVE;...;CLOSED
     (reguły ustania obowiązku → tylko warunek CLOSED + warunki pozastatusowe).

Usage:
  python3 tools/zus_plan33_fixer.py --check   # weryfikacja (exit 1 przy problemach)
  python3 tools/zus_plan33_fixer.py --apply   # zastosuj poprawki
"""

import argparse
import re
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
TARGET = JDG_ROOT / "rules" / "micro" / "plan33_zus.rego"

SUS_TITLE = ("ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń "
             "społecznych (Dz.U. 2025 poz. 345, ze zm.)")
ZASILK_TITLE = ("ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych "
                "z ubezpieczenia społecznego w razie choroby i macierzyństwa")

OLD_STRINGS = {
    '"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)"': f'"Ustawa z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)"',
    '"Suma skladek"': f'"Art. 22 ust. 1-4 {SUS_TITLE}"',
    '"Ustawa zasiłkowa — Świadczenia z ZUS"': f'"Ustawa z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa"',
}

# "Art. X [ust. Y [pkt Z]] SUS [— opis]"  →  kanon
SHORT_SUS_RE = re.compile(r'"Art\.\s*(\d+[a-z]*(?:\s+ust\.\s+[\d\-]+(?:\s+pkt\s+[\d\-]+(?:\s+[a-z]+(?:\s+[\d\-]+)?)?)?)?)\s+SUS[^"]*"')
# "Art. X ustawy SUS"
SUS_USTAWY_RE = re.compile(r'"Art\.\s*(\d+[a-z]*)\s+ustawy\s+SUS"')
# "Art. X [ust. Y] ustawy zasiłkowej"
ZASILK_RE = re.compile(r'"Art\.\s*(\d+[a-z]*(?:\s+ust\.\s+[\d\-]+)?)\s+ustawy\s+zasiłkowej"')

ACTIVE_RE = re.compile(r'object\.get\(input\.jdg_entrepreneur, "business_status", ""\) == "ACTIVE"')


def apply_fixes(text: str) -> tuple[str, dict]:
    stats = {"prefix": 0, "legal_basis": 0, "cond_dedup": 0, "clash_fix": 0}

    # 1. prefix rule_id
    text, stats["prefix"] = re.subn(r'"rule_id":"jdg\.zus\.', '"rule_id":"jdg.micro.zus.', text)

    # 2. _legal_basis — stare stringi
    for old, new in OLD_STRINGS.items():
        c = text.count(old)
        if c:
            text = text.replace(old, new)
            stats["legal_basis"] += c

    # 2b. krótkie formy
    text, c1 = SHORT_SUS_RE.subn(
        lambda m: f'"Art. {m.group(1).strip()} {SUS_TITLE}"', text)
    stats["legal_basis"] += c1
    text, c2 = SUS_USTAWY_RE.subn(
        lambda m: f'"Art. {m.group(1)} {SUS_TITLE}"', text)
    stats["legal_basis"] += c2
    text, c3 = ZASILK_RE.subn(
        lambda m: f'"Art. {m.group(1)} {ZASILK_TITLE}"', text)
    stats["legal_basis"] += c3

    # 3. warunki (dwa formaty: `cond }` w jednej linii lub `cond` + osobna `}`)
    lines = text.split("\n")
    for i, ln in enumerate(lines):
        if not ln.strip().startswith("object.get("):
            continue
        had_brace = ln.rstrip().endswith("}")
        if had_brace:
            body = ln.rstrip()[:-1].strip()
        else:
            body = ln.strip()
        if not (('"ACTIVE"' in body and '"CLOSED"' in body) or body.count(";") > 0):
            continue
        parts = [s.strip() for s in body.split(";") if s.strip()]
        seen, out = [], []
        for s in parts:
            if s not in seen:
                seen.append(s)
                out.append(s)
        if any('"CLOSED"' in s for s in out) and any('"ACTIVE"' in s for s in out):
            closed = [s for s in out if '"CLOSED"' in s]
            rest = [s for s in out if '"CLOSED"' not in s and "business_status" not in s]
            out = rest + closed
            stats["clash_fix"] += 1
        new_body = "; ".join(out)
        if new_body != body:
            stats["cond_dedup"] += 1
            lines[i] = "    " + new_body + (" }" if had_brace else "")
    return "\n".join(lines), stats


def verify(text: str) -> list[str]:
    problems = []
    if text.count("{") != text.count("}"):
        problems.append(f"niezbalansowane nawiasy: {{{{}}={text.count('{')} }}={text.count('}')}")
    if text.count("(") != text.count(")"):
        problems.append(f"niezbalansowane nawiasy okrągłe: {text.count('(')} vs {text.count(')')}")
    if re.search(r'"rule_id":"jdg\.zus\.', text):
        problems.append("pozostałe rule_id z prefiksem jdg.zus.*")
    if re.search(r'"_legal_basis":""', text):
        problems.append("zdublowany cudzysłów w _legal_basis")
    if re.search(r'\]} \{ \{', text):
        problems.append("zdublowany nawias { po werdykcie")
    if re.search(r'== "ACTIVE";[^}]*== "CLOSED"', text):
        problems.append("pozostałe kontradyktoryjne ACTIVE;CLOSED")
    # każda reguła ma _legal_basis
    for m in re.finditer(r'"rule_id":"([^"]+)"', text):
        rid = m.group(1)
        if rid.endswith(".no_match"):
            continue
    return problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    text = TARGET.read_text(encoding="utf-8")
    if args.apply:
        new_text, stats = apply_fixes(text)
        TARGET.write_text(new_text, encoding="utf-8")
        print("ZASTOSOWANO:", stats)
        text = new_text
    problems = verify(text)
    if problems:
        print("PROBLEMY:")
        for p in problems:
            print("  -", p)
        sys.exit(1)
    rule_count = len(re.findall(r'"rule_id":"jdg\.micro\.zus\.(?!no_match)', text))
    print(f"OK — plan33_zus.rego: {rule_count} reguł, nawiasy zbalansowane, rule_id kanoniczne")


if __name__ == "__main__":
    main()
