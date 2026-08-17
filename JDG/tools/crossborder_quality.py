#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CROSS-BORDER / TP / CFC / MDR — Quality Gate (GLM52 P12)
# Linter + kanonizacja _legal_basis + dedup + bramka.
# Kanony (LEGAL_REFERENCE_ACTS / SLOWNIK_REFERENCJI_PRAWNYCH):
# VAT: Dz.U. 2024 poz. 1557 ze zm. · PIT: Dz.U. 2024 poz. 1760 ze zm. ·
# OrdPU: Dz.U. 2025 poz. 234 ze zm. · KKS: Dz.U. 2025 poz. 678 ze zm. ·
# Prawo dewizowe: Dz.U. 2023 poz. 1231 ze zm.
# ═══════════════════════════════════════════════════════════════════════════════
import argparse
import re
from collections import Counter
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parents[1]

CANON_VAT = "ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)"
CANON_PIT = ("ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych "
             "(Dz.U. 2024 poz. 1760 ze zm.)")
CANON_ORD = "ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)"
CANON_KKS = "ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)"
CANON_DEW = "ustawy z dnia 27 lipca 2002 r. — Prawo dewizowe (Dz.U. 2023 poz. 1231 ze zm.)"

FILES = [
    "rules/micro/crossborder/crossborder.rego",
    "rules/micro/plan33_cb.rego",
    "rules/micro/plan33_tp.rego",
    "rules/micro/plan33_tax_trans.rego",
    "rules/micro/plan33_mdr.rego",
    "rules/crossborder.rego",
    "rules/crossborder/plan23_ue.rego",
    "rules/crossborder/post_brexit.rego",
    "rules/crossborder/exit_tax_cfc_complete.rego",
    "rules/international.rego",
    "rules/international_expanded.rego",
    "rules/tp/plan44_tp.rego",
    "rules/tp/plan45_tp.rego",
    "rules/residency/plan44_residency.rego",
    "rules/residency/plan45_residency.rego",
    "rules/fx/plan44_fx.rego",
    "rules/fx/plan45_fx.rego",
    "rules/mdr/mdr_enterprise.rego",
    "rules/mdr/mdr_hallmarks.rego",
    "rules/mdr/plan44_mdr.rego",
    "rules/mdr/plan45_mdr.rego",
    "rules/mdr_auto_generator.rego",
    "rules/mdr_dac6_enterprise.rego",
    "rules/dac8_report_generator.rego",
    "rules/cbam_full.rego",
    "rules/vida_drr_full.rego",
    "rules/cfc_auto_classifier.rego",
    "rules/exit_tax_mdr_enterprise.rego",
    "rules/p12_crossborder_innovations_v9.rego",
    "rules/r10_crossborder_innovations_v9.rego",
    "rules/cross_jurisdiction_ruling_enterprise.rego",
    "rules/micro/crossborder_atomic_p12.rego",
]

OLD_NEW = [
    # generic → kanon pełnej nazwy
    ("Dyrektywy UE, UPO, TP, CFC", "transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)"),
    ("Ustawa o PIT/CIT — cross-border", "ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)"),
    ("Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)", "ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)"),
    ("Ustawa o VAT z 11.03.2004", "ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)"),
    ("(Dz.U. 2004 nr 54 poz. 535)", "(Dz.U. 2024 poz. 1557 ze zm.)"),
    ("Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)", "ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)"),
    ("Ustawa o PIT z 26.07.1991", "ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)"),
    ("(Dz.U. 1991 nr 80 poz. 350)", "(Dz.U. 2024 poz. 1760 ze zm.)"),
    ("Art. 23o-23zf PIT (Ceny transferowe)", "Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)"),
    ("Art. 86a-86o Ordynacji Podatkowej (MDR)", "Art. 86a-86o ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)"),
    ("Art. 86a-86o Ordynacji podatkowej (MDR)", "Art. 86a-86o ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)"),
    ("Dyrektywa 2011/16/UE", "dyrektywa Rady 2011/16/UE z dnia 15 lutego 2011 r. w sprawie współpracy administracyjnej w dziedzinie opodatkowania (DAC6)"),
    ("Rozporządzenie UE 2023/956", "rozporządzenie Parlamentu Europejskiego i Rady (UE) 2023/956 z dnia 10 maja 2023 r. ustanawiające mechanizm dostosowywania cen na granicach z uwzględnieniem emisji dwutlenku węgla (CBAM)"),
    ("Dyrektywa UE 2025/2102", "dyrektywa Rady (UE) 2025/2102 z dnia 14 lipca 2025 r. (ViDA)"),
    ("Ustawa o podatkach i opłatach lokalnych (Art. 8-13)", "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych"),
    ("Prawo dewizowe", "ustawy z dnia 27 lipca 2002 r. — Prawo dewizowe (Dz.U. 2023 poz. 1231 ze zm.)"),
]

GENERIC_RE = [
    (re.compile(r'crossborder_condition_met\s*==\s*true'), "generic: crossborder_condition_met"),
    (re.compile(r'uses_crossborder\s*==\s*true'), "generic: uses_crossborder"),
]

# Pliki z regułami funkcyjnymi (cjr_*, nie decide) — pomijane w liczeniu reguł
FUNCTION_ONLY = {"rules/cross_jurisdiction_ruling_enterprise.rego"}

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
    dead = [(i, "fallback {true} — martwa reguła (INV-018)") for i, ln in enumerate(lines, 1)
            if DEAD_FALLBACK_RE.search(ln) and "if {" not in ln]
    old_lbs = [lb for lb in set(lbs)
               if "2004 nr 54 poz. 535" in lb or "1991 nr 80 poz. 350" in lb
               or lb.strip() in ("Ustawa o PIT/CIT — cross-border", "Dyrektywy UE, UPO, TP, CFC")]
    return {
        "file": rel,
        "rule_count": len(rids),
        "unique_rule_ids": len(set(rids)),
        "matched_true": matched_true,
        "legal_basis_count": len(lbs),
        "legal_basis_old": old_lbs,
        "generic": generic,
        "dead": dead,
    }


# Sekcje micro/crossborder → kanoniczna podstawa prawna (artykuł + pełna ustawa)
SECTION_LEGAL = {
    "a23o": "Art. 23o ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    "a23zf": "Art. 23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    "a23z": "Art. 23z ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    "a30da": "Art. 30da ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    "a30f": "Art. 30f ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    "a29": "Art. 29 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.) w zw. z art. 30a (WHT)",
    "a86r": "Art. 86a-86o ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "a20": "Konwencja MLI (Dz.U. 2018 poz. 1299) w zw. z umowami o unikaniu podwójnego opodatkowania",
}

GENERIC_CB = "transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)"


def _fix_sections(text: str) -> tuple[str, int]:
    """Sekcje micro/crossborder: zamień generyczny _legal_basis na kanon per artykuł.
    Działa liniowo — sekcje są w kolejności w pliku, każda zaczyna się od `# crossborder.aXX`."""
    n = 0
    # znajdź nagłówki sekcji (komentarze z rule_id prefix) i ich linie
    lines = text.split("\n")
    sec_order = ["a23o", "a23zf", "a30da", "a30f", "a29", "a86r", "a20"]
    # sekcje wg kolejności wystąpienia w pliku
    positions = []
    for i, ln in enumerate(lines):
        m = re.search(r'crossborder\.(a23o|a23zf|a30da|a30f|a29|a86r|a20)\b', ln)
        if m and (ln.strip().startswith("#") or "rule_id" in ln):
            positions.append((i, m.group(1)))
    if not positions:
        return text, 0
    # dla każdej sekcji: zakres [start, next_start) → zamień GENERIC_CB w wierszach _legal_basis
    for idx, (start, sec) in enumerate(positions):
        end = positions[idx + 1][0] if idx + 1 < len(positions) else len(lines)
        canon = SECTION_LEGAL.get(sec)
        if not canon:
            continue
        for j in range(start, end):
            if GENERIC_CB in lines[j] and '"_legal_basis"' in lines[j]:
                lines[j] = lines[j].replace(GENERIC_CB, canon)
                n += 1
    return "\n".join(lines), n


def fix_file(rel: str) -> int:
    path = JDG_ROOT / rel
    if not path.exists():
        return 0
    text = path.read_text(encoding="utf-8")
    orig = text
    n = 0
    for old, new in OLD_NEW:
        c = text.count(old)
        if c:
            text = text.replace(old, new)
            n += c
    text, ns = _fix_sections(text)
    n += ns
    if text != orig:
        path.write_text(text, encoding="utf-8")
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fix", action="store_true")
    ap.add_argument("--gate", action="store_true")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    if args.fix:
        for rel in FILES:
            n = fix_file(rel)
            if n:
                print(f"[FIX] {rel}: {n} zamian")

    errors, warnings = [], []
    all_ids = Counter()
    reports = []
    for rel in FILES:
        rep = analyze_file(rel)
        reports.append(rep)
        if rep.get("error"):
            errors.append(f"{rel}: {rep['error']}")
            continue
        for rid in re.findall(r'"rule_id"\s*:\s*"([^"]+)"',
                              (JDG_ROOT / rel).read_text(encoding="utf-8")):
            all_ids[rid] += 1
        for lb in rep["legal_basis_old"]:
            errors.append(f"{rel}: niekanoniczny _legal_basis: {lb[:80]}")
        for i, d in rep["generic"]:
            errors.append(f"{rel}:{i}: {d}")
        for i, d in rep["dead"]:
            errors.append(f"{rel}:{i}: {d}")

    dups = [rid for rid, c in all_ids.items() if c > 1 and not rid.endswith(".no_match")]
    for rid in dups:
        errors.append(f"zdublowany rule_id: {rid}")

    if args.gate or args.json:
        import json
        out = {
            "status": "PASS" if not errors else "FAIL",
            "errors": errors[:50],
            "warnings": warnings[:50],
            "duplicates": len(dups),
            "files": len([r for r in reports if not r.get("error")]),
            "rules_total": sum(r.get("rule_count", 0) for r in reports),
            "rules_unique": len(all_ids),
        }
        if args.json:
            print(json.dumps(out, ensure_ascii=False, indent=1))
        if args.gate:
            for r in reports:
                if r.get("error"):
                    print(f"  {r['file']}: MISSING")
                    continue
                print(f"  {r['file']}: reguł={r['rule_count']} (uniq {r['unique_rule_ids']}) "
                      f"matched={r['matched_true']} legal_basis={r['legal_basis_count']} "
                      f"old={len(r['legal_basis_old'])} generic={len(r['generic'])} dead={len(r['dead'])}")
            print(f"BRAMKA: {'PASS' if not errors else 'FAIL'}")
            print(f"  błędów: {len(errors)} · duplikatów: {len(dups)} · "
                  f"reguł: {sum(r.get('rule_count', 0) for r in reports)}")
            return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
