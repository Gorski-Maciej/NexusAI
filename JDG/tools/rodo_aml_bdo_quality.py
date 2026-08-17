#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RODO / AML-CBDD / BDO-ŚRODOWISKO / BUDOWNICTWO / TRANSPORT —
# Quality Gate (GLM52 P15)
# Linter + kanonizacja _legal_basis + wykrywanie konfliktów pakietów + bramka.
# Kanony (LEGAL_REFERENCE_ACTS / PROMPT 15):
# RODO: rozporządzenie (UE) 2016/679 ·
# AML: ustawa z 1.03.2018 (Dz.U. 2025 poz. 213) ·
# Odpady/BDO: ustawa z 14.12.2012 (Dz.U. 2025 poz. 321) ·
# Prawo budowlane: ustawa z 7.07.1994 (Dz.U. 2025 poz. 1101).
# ═══════════════════════════════════════════════════════════════════════════════
import argparse
import re
from collections import Counter
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parents[1]

FILES = [
    "rules/rodo.rego",
    "rules/rodo_extended.rego",
    "rules/micro/rodo/rodo.rego",
    "rules/micro/rodo/rodo_ai_marketing.rego",
    "rules/micro/rodo/rodo_erasure.rego",
    "rules/micro/rodo/rodo_podprocesorzy.rego",
    "rules/micro/rodo/rodo_sankcje.rego",
    "rules/micro/rodo/rodo_zatrudnienie.rego",
    "rules/micro/plan33_rodo.rego",
    "rules/rodo/plan42_rodo.rego",
    "rules/compliance.rego",
    "rules/compliance/aml_enterprise.rego",
    "rules/micro/aml/aml.rego",
    "rules/micro/aml/aml_cbdd.rego",
    "rules/micro/aml/aml_ryzyko.rego",
    "rules/micro/aml/aml_str_gif.rego",
    "rules/micro/aml/aml_transakcje.rego",
    "rules/environmental.rego",
    "rules/environmental/bdo_enterprise.rego",
    "rules/micro/bdo/bdo_rejestracja.rego",
    "rules/micro/bdo/bdo_ewidencja.rego",
    "rules/micro/bdo/bdo_ewc.rego",
    "rules/micro/bdo/bdo_transport.rego",
    "rules/micro/bdo/bdo_zezwolenia.rego",
    "rules/micro/bdo/bdo_weee_baterie.rego",
    "rules/micro/srodowisko/srodowisko.rego",
    "rules/micro/plan33_est.rego",
    "rules/micro/budownictwo/budownictwo.rego",
    "rules/micro/transport/transport.rego",
    "rules/security/security_fortress_v8.rego",
    "rules/regulated_compliance_enterprise.rego",
    "rules/sanctions_supplements_enterprise.rego",
    "rules/p15_srodowisko_bdo_innovations_v9.rego",
    "rules/r14_rodo_aml_bdo_innovations_v9.rego",
    "rules/p16_rodo_aml_security_innovations_v9.rego",
    "rules/_compliance_rates.rego",
    "rules/micro/rodo_aml_bdo_atomic_p15.rego",
]

OLD_NEW = [
    # AML: Dz.U. 2018 poz. 723 → Dz.U. 2025 poz. 213
    ("Dz.U. 2018 poz. 723", "Dz.U. 2025 poz. 213"),
    ("ustawy o AML", "ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)"),
    ("ustawa o przeciwdziałaniu praniu pieniędzy", "ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)"),
    ("Ustawa o przeciwdziałaniu praniu pieniędzy", "ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)"),
    # Odpady/BDO: Dz.U. 2013 poz. 21 → Dz.U. 2025 poz. 321
    ("Dz.U. 2013 poz. 21", "Dz.U. 2025 poz. 321"),
    ("ustawy o odpadach z 14.12.2012", "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)"),
    ("Ustawa o odpadach", "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)"),
    ("ustawy o odpadach", "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)"),
    # Prawo budowlane: Dz.U. 1994 nr 89 poz. 414 → Dz.U. 2025 poz. 1101
    ("Dz.U. 1994 nr 89 poz. 414", "Dz.U. 2025 poz. 1101"),
    ("Prawa budowlanego", "ustawy z dnia 7 lipca 1994 r. — Prawo budowlane (Dz.U. 2025 poz. 1101)"),
    ("Prawo budowlane", "ustawy z dnia 7 lipca 1994 r. — Prawo budowlane (Dz.U. 2025 poz. 1101)"),
]

OLD_PATTERNS = [
    "Dz.U. 2018 poz. 723",
    "Dz.U. 2013 poz. 21",
    "Dz.U. 1994 nr 89 poz. 414",
]

DEAD_FALLBACK_RE = re.compile(r'\}\s*\{\s*true\s*\}\s*$')
FALLBACK_COMMENT_RE = re.compile(r'^\s*#\s*fallback\s*$', re.IGNORECASE)
ELSE_START_RE = re.compile(r'^\s*else\s*:=\s*\{')
TRUE_END_RE = re.compile(r'\}\s*\{\s*true\s*\}\s*$')


def remove_dead_fallbacks(text: str) -> tuple:
    """Usuwa martwe catch-alle `# fallback` + `else := {...} { true }` (INV-018).

    Wzorzec: komentarz `# fallback` + blok `else := {...} { true }` na końcu
    łańcucha else — przechwytuje no_match (matched: true zawsze), maskując
    default decide. Usunięcie przywraca no_match (konwencja INV-018).
    """
    lines = text.split("\n")
    out = []
    removed = 0
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        if FALLBACK_COMMENT_RE.match(line):
            j = i + 1
            while j < n and not lines[j].strip():
                j += 1
            if j < n and ELSE_START_RE.match(lines[j]):
                k = j
                while k < n and not TRUE_END_RE.search(lines[k]):
                    k += 1
                if k < n:
                    removed += 1
                    i = k + 1
                    continue
        out.append(line)
        i += 1
    return "\n".join(out), removed


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
    text, removed = remove_dead_fallbacks(text)
    n += removed
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
