#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RYCZAŁT / CEIDG / PRAWO PRZEDSIĘBIORCÓW / SUKCESJA — Quality Gate
# (GLM52 P13)
# Linter + kanonizacja _legal_basis + wykrywanie konfliktów pakietów + bramka.
# Kanony (LEGAL_REFERENCE_ACTS / PROMPT 13):
# Ryczałt: ustawa z 20.11.1998 (Dz.U. 2025 poz. 234 ze zm.) ·
# CEIDG: ustawa z 6.03.2018 (Dz.U. 2025 poz. 456) ·
# Prawo przedsiębiorców: ustawa z 6.03.2018 (Dz.U. 2025 poz. 123) ·
# Zarząd sukcesyjny: ustawa z 5.07.2018 (Dz.U. 2025 poz. 1234).
# ═══════════════════════════════════════════════════════════════════════════════
import argparse
import re
from collections import Counter
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parents[1]

CANON_RYCZALT = "ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)"
CANON_CEIDG = "ustawy z dnia 6 marca 2018 r. o Centralnej Ewidencji i Informacji o Działalności Gospodarczej i Punkcie Informacji dla Przedsiębiorcy (Dz.U. 2025 poz. 456)"
CANON_PP = "ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)"
CANON_SUCC = "ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)"
CANON_VAT = "ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)"
CANON_PIT = ("ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych "
             "(Dz.U. 2024 poz. 1760 ze zm.)")
CANON_SUS = "ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345 ze zm.)"

FILES = [
    "rules/micro/ryczalt/ryczalt.rego",
    "rules/micro/plan33_ryc.rego",
    "rules/micro/ceidg/ceidg.rego",
    "rules/micro/plan33_ceidg.rego",
    "rules/micro/pp/pp.rego",
    "rules/micro/sukcesja/sukcesja.rego",
    "rules/micro/plan33_succ.rego",
    "rules/business.rego",
    "rules/business/gig_economy.rego",
    "rules/business/plan26_suspension_succession.rego",
    "rules/business/strategic_intelligence.rego",
    "rules/_business_lifecycle_rates.rego",
    "rules/lifecycle_manager_enterprise.rego",
    "rules/p13_ryczalt_cykl_zycia_innovations_v9.rego",
    "rules/r12_ryczalt_cykl_zycia_innovations_v9.rego",
    "rules/p16_business_lifecycle_innovations_v8.rego",
    "rules/p16_autoform_generator_enterprise.rego",
    "rules/p16_entrepreneur_test_enterprise.rego",
    "rules/p16_enhanced_sca_enterprise.rego",
    "rules/p16_estonian_cit_enterprise.rego",
    "rules/poa_manager_enterprise.rego",
    "rules/restructuring.rego",
    "rules/micro/ryczalt_cykl_atomic_p13.rego",
]

OLD_NEW = [
    # ryczałt: Dz.U. 1998 nr 144 poz. 930 → Dz.U. 2025 poz. 234
    ("Dz.U. 1998 nr 144 poz. 930", "Dz.U. 2025 poz. 234"),
    ("ustawy o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)", "ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)"),
    ("ustawy o ryczałcie z 20.11.1998", "ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)"),
    # CEIDG: Dz.U. 2018 poz. 647 → Dz.U. 2025 poz. 456
    ("Dz.U. 2018 poz. 647", "Dz.U. 2025 poz. 456"),
    ("Ustawy o CEIDG z 06.03.2018", "ustawy z dnia 6 marca 2018 r. o Centralnej Ewidencji i Informacji o Działalności Gospodarczej i Punkcie Informacji dla Przedsiębiorcy"),
    ("ustawy o CEIDG z 06.03.2018", "ustawy z dnia 6 marca 2018 r. o Centralnej Ewidencji i Informacji o Działalności Gospodarczej i Punkcie Informacji dla Przedsiębiorcy"),
    # Prawo przedsiębiorców: Dz.U. 2018 poz. 646 → Dz.U. 2025 poz. 123
    ("Dz.U. 2018 poz. 646", "Dz.U. 2025 poz. 123"),
    ("Prawa Przedsiębiorców z 06.03.2018", "ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców"),
    ("Prawa przedsiębiorców z 06.03.2018", "ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców"),
    ("Prawo Przedsiębiorców z 06.03.2018", "ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców"),
    # Zarząd sukcesyjny: Dz.U. 2018 poz. 1629 → Dz.U. 2025 poz. 1234
    ("Dz.U. 2018 poz. 1629", "Dz.U. 2025 poz. 1234"),
    ("ustawy o zarządzie sukcesyjnym z 05.07.2018", "ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej"),
    ("ustawy o zarządzie sukcesyjnym z 5.07.2018", "ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej"),
    ("Ustawy o zarządzie sukcesyjnym z 05.07.2018", "ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej"),
    ("Ustawa o zarządzie sukcesyjnym z 05.07.2018", "ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej"),
    ("Ustawa o zarządzie sukcesyjnym z 5.07.2018", "ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej"),
    # skróty → pełne nazwy
    ("u.z.s.", "ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)"),
    ("ustawy o CEIDG", "ustawy z dnia 6 marca 2018 r. o Centralnej Ewidencji i Informacji o Działalności Gospodarczej i Punkcie Informacji dla Przedsiębiorcy (Dz.U. 2025 poz. 456)"),
    ("Ustawy o CEIDG", "ustawy z dnia 6 marca 2018 r. o Centralnej Ewidencji i Informacji o Działalności Gospodarczej i Punkcie Informacji dla Przedsiębiorcy (Dz.U. 2025 poz. 456)"),
    ("Prawa przedsiębiorców", "ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)"),
    ("Prawa Przedsiębiorców", "ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)"),
    ("ustawy o ryczałcie", "ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)"),
    ("ustawy o zryczałtowanym podatku dochodowym", "ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)"),
]

OLD_PATTERNS = [
    "Dz.U. 1998 nr 144 poz. 930",
    "Dz.U. 2018 poz. 647",
    "Dz.U. 2018 poz. 646",
    "Dz.U. 2018 poz. 1629",
]

DEAD_FALLBACK_RE = re.compile(r'\}\s*\{\s*true\s*\}\s*$')


def analyze_file(rel: str) -> dict:
    path = JDG_ROOT / rel
    if not path.exists():
        return {"file": rel, "error": "missing"}
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    rids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    lbs = re.findall(r'"_legal_basis"\s*:\s*"([^"]*)"', text)
    matched_true = len(re.findall(r'"matched"\s*:\s*true', text))
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
        for rid in re.findall(r'"rule_id"\s*:\s*"([^"]+)"',
                              (JDG_ROOT / rel).read_text(encoding="utf-8")):
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
