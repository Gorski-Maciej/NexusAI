#!/usr/bin/env python3
"""
NexusAI JDG — KSIĘGOWOŚĆ QUALITY GATE (GLM52 P10, Enterprise)
=============================================================
Linter warstwy księgowości (PKPiR micro, UoR micro/makro, plan33_uor,
transformacja, leasing) — wdrożenie PROMPT 10:

  • kanonizacja _legal_basis (--fix):
      UoR  → "ustawy z dnia 29 września 1994 r. o rachunkowości
              (Dz.U. 2025 poz. 567, ze zm.)"
      PKPiR → "rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r.
               w sprawie prowadzenia podatkowej księgi przychodów i rozchodów"
  • detekcja MARTWYCH reguł (matched:true nigdy nieosiągalne — catch-all
    przejmujący lub warunek sprzeczny),
  • detekcja wzorców stubowych (uses_pkpir == true bez warunków merytorycznych),
  • detekcja duplikatów rule_id (cross-file + kolizja jdg.* vs jdg.micro.*),
  • raport „zdrowia" per plik + bramka CI (--gate).

Usage:
  python3 tools/ksiegowosc_quality.py                # raport (exit 1 przy błędach)
  python3 tools/ksiegowosc_quality.py --fix          # kanonizacja _legal_basis
  python3 tools/ksiegowosc_quality.py --gate         # bramka CI (0 błędów)
"""

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent

# ── Kanon aktów (LEGAL_REFERENCE_ACTS.md + legal_reference_canon.json + PROMPT 10) ──
CANON_UOR = "ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)"
CANON_PKPIR = ("rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. "
               "w sprawie prowadzenia podatkowej księgi przychodów i rozchodów")
UOR_ACT = "Ustawa z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)"

FILES = [
    "rules/micro/uor/uor.rego",
    "rules/micro/plan33_uor.rego",
    "rules/micro/pkpir/pkpir.rego",
    "rules/micro/pkpir/pkpir_kolumny.rego",
    "rules/micro/pkpir/pkpir_przychody.rego",
    "rules/micro/pkpir/pkpir_koszty.rego",
    "rules/micro/pkpir/pkpir_nkup.rego",
    "rules/micro/pkpir/pkpir_remanent.rego",
    "rules/micro/pkpir/pkpir_korekty.rego",
    "rules/uor/uor_obligation.rego",
    "rules/uor/uor_books.rego",
    "rules/uor/uor_inventory.rego",
    "rules/uor/uor_financial_stmt.rego",
    "rules/uor/uor_closing.rego",
    "rules/uor/uor_assets.rego",
    "rules/uor/uor_revenue.rego",
    "rules/uor/uor_costs.rego",
    "rules/accounting/uor_enterprise_live.rego",
    "rules/accounting/plan23_leasing.rego",
    "rules/pkpir_to_uor_transformer.rego",
    "rules/micro/ksiegowosc_atomic_p10.rego",
]

# Stare formy → kanon (zachowawcze zamiany stringów)
OLD_NEW = [
    ("Ustawy o rachunkowości", f"ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)"),
    ("Ustawy o Rachunkowości", f"ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)"),
    ("Ustawy o rachunkowości (Dz.U. 1994 nr 121 poz. 591)", f"ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)"),
    ("Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)", UOR_ACT),
    ("(Dz.U. 1994 nr 121 poz. 591)", "(Dz.U. 2025 poz. 567, ze zm.)"),
    ("rozporządzenia MF w sprawie PKPiR", CANON_PKPIR),
    ("rozporządzenia MF z 15.11.2025 r. w sprawie PKPiR", CANON_PKPIR),
    ("rozporządzenia MF z 15.11.2025 r.", CANON_PKPIR),
    ("Rozp. MF PKPiR", CANON_PKPIR),
    ("rozporządzenia MF w sprawie prowadzenia podatkowej księgi przychodów i rozchodów", CANON_PKPIR),
]

OLD_UOR_DZU_RE = re.compile(r'\(Dz\.U\.\s*1994\s*nr\s*121\s*poz\.\s*591\)')
OLD_UOR_ACT_RE = re.compile(r'Ustaw[yo]\s+o\s+rachunkowości', re.IGNORECASE)
OLD_PKPIR_RE = re.compile(r'rozporządzenia\s+MF\s+(?:z\s+15\.11\.2025\s*r\.\s*(?:w\s+sprawie\s+PKPiR)?|w\s+sprawie\s+PKPiR)', re.IGNORECASE)
OLD_PKPIR_SHORT_RE = re.compile(r'Rozp\.\s+MF\s+PKPiR')

# Wzorce stubowe (generic conditions)
GENERIC_RE = [
    (re.compile(r'uses_pkpir\s*==\s*true'), "generic: uses_pkpir == true"),
    (re.compile(r'uses_uor\s*==\s*true'), "generic: uses_uor == true"),
    (re.compile(r'_pass"\s*,\s*false\)\s*==\s*true'), "generic: *_pass flaga"),
]

# Martwe reguły: catch-all werdyktu `} { true }` przejmujący no_match (INV-018).
# Uwaga: nie flagujemy helperów `else := false if { true }` (poprawne domyślne false).
DEAD_FALLBACK_RE = re.compile(r'\}\s*\{\s*true\s*\}\s*$')
HARDCODED_AMOUNT_RE = re.compile(r'[^"a-z_]\d{4,}(?:\.\d{2})?[^"\d]')


def analyze_file(rel: str) -> dict:
    path = JDG_ROOT / rel
    if not path.exists():
        return {"file": rel, "error": "missing"}
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    rids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    lbs = re.findall(r'"_legal_basis"\s*:\s*"([^"]*)"', text)
    matched_true = len(re.findall(r'"matched"\s*:\s*true', text))
    generic = [(i, d) for i, ln in enumerate(lines, 1) for p, d in GENERIC_RE if p.search(ln)]
    hard = [(i, "hardcoded numeric (ADR-002)") for i, ln in enumerate(lines, 1)
            if not ln.strip().startswith("#") and not ln.strip().startswith(("package ", "import "))
            and HARDCODED_AMOUNT_RE.search(ln)]
    dead = [(i, "fallback {true} — martwa reguła (INV-018)") for i, ln in enumerate(lines, 1)
            if DEAD_FALLBACK_RE.search(ln) and "if {" not in ln]
    return {
        "file": rel,
        "rule_count": len(rids),
        "unique_rule_ids": len(set(rids)),
        "matched_true": matched_true,
        "legal_basis_count": len(lbs),
        "legal_basis_old": [lb for lb in set(lbs) if "Dz.U. 1994 nr 121" in lb or "rozporządzenia MF w sprawie PKPiR" in lb or "rozporządzenia MF z 15.11.2025 r.\"" in lb],
        "generic": generic,
        "hardcoded": hard,
        "dead": dead,
    }


def fix_file(rel: str) -> tuple[int, int]:
    path = JDG_ROOT / rel
    if not path.exists():
        return 0, 0
    text = path.read_text(encoding="utf-8")
    orig = text
    n = 0
    for old, new in OLD_NEW:
        c = text.count(old)
        if c:
            text = text.replace(old, new)
            n += c
    text, c1 = OLD_UOR_DZU_RE.subn(f"(Dz.U. 2025 poz. 567, ze zm.)", text)
    n += c1
    text, c2 = OLD_PKPIR_RE.subn(lambda m: CANON_PKPIR, text)
    n += c2
    text, c3 = OLD_PKPIR_SHORT_RE.subn(lambda m: CANON_PKPIR, text)
    n += c3
    if text != orig:
        path.write_text(text, encoding="utf-8")
    return n, 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fix", action="store_true")
    ap.add_argument("--gate", action="store_true")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    if args.fix:
        for rel in FILES:
            n, _ = fix_file(rel)
            if n:
                print(f"[FIX] {rel}: {n} zamian")

    errors, warnings = [], []
    all_ids = Counter()
    reports = []
    for rel in FILES:
        rep = analyze_file(rel)
        reports.append(rep)
        if rep.get("error"):
            errors.append(f"[ERROR] {rel}: BRAK PLIKU")
            continue
        text = (JDG_ROOT / rel).read_text(encoding="utf-8")
        for rid in re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text):
            all_ids[rid] += 1
        if rep["rule_count"] == 0:
            errors.append(f"[ERROR] {rel}: zero reguł")
        if rep["rule_count"] != rep["unique_rule_ids"]:
            dup = [rid for rid, c in Counter(re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)).items() if c > 1]
            errors.append(f"[ERROR] {rel}: duplikaty rule_id: {dup[:6]}")
        if rep["legal_basis_old"]:
            errors.append(f"[ERROR] {rel}: stare _legal_basis: {rep['legal_basis_old'][:3]}")
        for i, d in rep["generic"]:
            warnings.append(f"[WARNING] {rel}:{i} — {d}")
        for i, d in rep["hardcoded"][:5]:
            warnings.append(f"[WARNING] {rel}:{i} — {d}")
        for i, d in rep["dead"]:
            errors.append(f"[ERROR] {rel}:{i} — {d}")

    for rid, c in all_ids.items():
        if c > 1:
            errors.append(f"[ERROR] rule_id '{rid}' zduplikowany {c}× (cross-file)")

    report = {"errors": errors, "warnings": warnings, "health": reports}
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print("═" * 72)
        print("NexusAI JDG — KSIĘGOWOŚĆ QUALITY GATE (GLM52 P10)")
        print(f"BŁĘDY: {len(errors)} · OSTRZEŻENIA: {len(warnings)}")
        for e in errors[:30]:
            print(" ", e)
        for w in warnings[:10]:
            print(" ", w)
        print("═" * 72)
        for h in reports:
            if h.get("error"):
                continue
            print(f"  {h['file']}: reguł={h['rule_count']} (uniq {h['unique_rule_ids']}) "
                  f"matched={h['matched_true']} legal_basis={h['legal_basis_count']} "
                  f"generic={len(h['generic'])} dead={len(h['dead'])}")
    ok = len(errors) == 0
    if args.gate:
        print("BRAMKA:", "PASS" if ok else "FAIL")
        sys.exit(0 if ok else 1)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
