#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PCC / PODATKI LOKALNE / AKCYZA / PODATEK ROLNY — Quality Gate
# (GLM52 P14)
# Linter + kanonizacja _legal_basis + wykrywanie konfliktów pakietów + bramka.
# Kanony (LEGAL_REFERENCE_ACTS / PROMPT 14):
# PCC: ustawa z 9.09.2000 (Dz.U. 2025 poz. 789) ·
# Podatki lokalne: ustawa z 12.01.1991 (Dz.U. 2025 poz. 1234) ·
# Akcyza: ustawa z 6.12.2008 (Dz.U. 2025 poz. 1220).
# ═══════════════════════════════════════════════════════════════════════════════
import argparse
import re
from collections import Counter
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parents[1]

CANON_PCC = "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)"
CANON_LOCAL = "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)"
CANON_AKCYZA = "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)"

FILES = [
    "rules/local_taxes.rego",
    "rules/local_taxes/pcc.rego",
    "rules/local_taxes/pcc_enterprise_complete.rego",
    "rules/local_taxes/pcc_excise_enterprise.rego",
    "rules/local_taxes/akcyza_alcohol.rego",
    "rules/local_taxes/akcyza_fuel.rego",
    "rules/local_taxes/excise_enterprise_complete.rego",
    "rules/local_taxes/local_procedures_enterprise.rego",
    "rules/local_taxes/real_estate.rego",
    "rules/local_taxes/transport.rego",
    "rules/local_taxes/plan26_local.rego",
    "rules/pcc/pcc_rates.rego",
    "rules/pcc/pcc_sales.rego",
    "rules/pcc/pcc_loans.rego",
    "rules/pcc/pcc_companies.rego",
    "rules/pcc/plan42_pcc.rego",
    "rules/micro/pcc/pcc.rego",
    "rules/micro/akcyza/akcyza.rego",
    "rules/micro/plan33_pcc.rego",
    "rules/micro/plan33_prop.rego",
    "rules/micro/plan33_prop_transport.rego",
    "rules/micro/plan33_agricultural_tax.rego",
    "rules/_pcc_local_excise_rates.rego",
    "rules/p14_pcc_lokalne_akcyza_innovations_v9.rego",
    "rules/r11_pcc_lokalne_akcyza_innovations_v9.rego",
    "rules/p15_pcc_local_excise_innovations_v8.rego",
    "rules/p33_pcc_complete.rego",
    "rules/p33_excise_supplement.rego",
    "rules/micro/pcc_lokalne_atomic_p14.rego",
]

OLD_NEW = [
    # PCC: Dz.U. 2000 nr 86 poz. 959 → Dz.U. 2025 poz. 789
    ("Dz.U. 2000 nr 86 poz. 959", "Dz.U. 2025 poz. 789"),
    ("Ustawa o PCC z 09.09.2000", "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych"),
    ("ustawy o PCC z 09.09.2000", "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych"),
    ("Ustawa o PCC (Dz.U. 2025 poz. 789)", "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)"),
    ("Ustawa o PCC", "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)"),
    ("ustawa o PCC", "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)"),
    ("u.p.c.c.", "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)"),
    # Lokalne: ustawa o podatkach i opłatach lokalnych
    ("Ustawa o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)", "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)"),
    ("ustawy lokalnej", "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)"),
    ("Ustawa o podatkach i opłatach lokalnych", "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)"),
    ("ustawy o podatkach i opłatach lokalnych", "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)"),
    ("u.p.o.l.", "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)"),
    # Akcyza: ustawa o podatku akcyzowym
    ("Ustawa o podatku akcyzowym (06.12.2008)", "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)"),
    ("Ustawa o podatku akcyzowym", "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)"),
    ("ustawy o podatku akcyzowym", "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)"),
    ("ustawy akcyzowej", "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)"),
    ("u. akcyzowej", "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)"),
]

OLD_PATTERNS = [
    "Dz.U. 2000 nr 86 poz. 959",
]

DEAD_FALLBACK_RE = re.compile(r'\}\s*\{\s*true\s*\}\s*$')


def analyze_file(rel: str) -> dict:
    path = JDG_ROOT / rel
    if not path.exists():
        return {"file": rel, "error": "missing"}
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    rids = re.findall(r'\"rule_id\"\s*:\s*\"([^\"]+)\"', text)
    lbs = re.findall(r'\"_legal_basis\"\s*:\s*\"([^\"]*)\"', text)
    matched_true = len(re.findall(r'\"matched\"\s*:\s*true', text))
    dead = [(i, "fallback {true} — martwa reguła (INV-018)") for i, ln in enumerate(lines, 1)
            if DEAD_FALLBACK_RE.search(ln) and "if {" not in ln]
    old_lbs = [lb for lb in set(lbs) if any(p in lb for p in OLD_PATTERNS)]
    return {
        "file": rel,
        "rule_count": len(rids),
        "unique_rule_ids": len(set(rids)),
        "matched_true": matched_true,
        "legal_basis_count": len(lbs),
        "legal_basis_old": old_lbs,
        "dead": dead,
    }


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
        path = JDG_ROOT / rel
        for rid in re.findall(r'\"rule_id\"\s*:\s*\"([^\"]+)\"', path.read_text(encoding="utf-8")):
            all_ids[rid] += 1
        for lb in rep["legal_basis_old"]:
            errors.append(f"{rel}: niekanoniczny _legal_basis: {lb[:90]}")
        for i, d in rep["dead"]:
            errors.append(f"{rel}:{i}: {d}")

    # konflikt pakietów: dwa pliki z tym samym pakietem i default decide
    pkg_defaults: dict[str, list[str]] = {}
    for rel in FILES:
        path = JDG_ROOT / rel
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        m = re.search(r'^package\s+([\w.]+)', text, re.M)
        if m and re.search(r'^default\s+decide', text, re.M):
            pkg_defaults.setdefault(m.group(1), []).append(rel)
    for pkg, files in sorted(pkg_defaults.items()):
        if len(files) > 1:
            errors.append(f"KONFLIKT PAKIETU {pkg}: 2× default decide w {', '.join(files)}")

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
                      f"old={len(r['legal_basis_old'])} dead={len(r['dead'])}")
            print(f"BRAMKA: {'PASS' if not errors else 'FAIL'}")
            print(f"  błędów: {len(errors)} · duplikatów: {len(dups)} · "
                  f"reguł: {sum(r.get('rule_count', 0) for r in reports)}")
            return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
