#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KKS + ORDYNACJA + AUDYT/OBRONA — Quality Gate (GLM52 P11)
# Linter + kanonizacja _legal_basis + dedup + bramka.
# Kanony (PROMPT 11): KKS (Dz.U. 2025 poz. 678, ze zm.), OrdPU (Dz.U. 2025
# poz. 234, ze zm.), PPSA (Dz.U. 2025 poz. 861, ze zm.), KAS (Dz.U. 2025
# poz. 108, ze zm.), Prawo przedsiębiorców (Dz.U. 2025 poz. 226, ze zm.).
# ═══════════════════════════════════════════════════════════════════════════════
import argparse
import re
from collections import Counter
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parents[1]

# ── Kanony aktów (PROMPT 11 / LEGAL_REFERENCE_ACTS) ────────────────────────────
CANON_KKS = "ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)"
CANON_ORD = "ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)"
CANON_PPSA = ("ustawy z dnia 30 sierpnia 2002 r. — Prawo o postępowaniu przed sądami "
              "administracyjnymi (Dz.U. 2025 poz. 861, ze zm.)")
CANON_KAS = ("ustawy z dnia 16 listopada 2016 r. o Krajowej Administracji Skarbowej "
             "(Dz.U. 2025 poz. 108, ze zm.)")
CANON_PP = ("ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców "
            "(Dz.U. 2025 poz. 226, ze zm.)")

FILES = [
    "rules/micro/kks/kks.rego",
    "rules/micro/ord/ord.rego",
    "rules/micro/plan33_kks.rego",
    "rules/micro/plan33_ord.rego",
    "rules/micro/plan34_ord.rego",
    "rules/audit/plan44_audit.rego",
    "rules/audit/plan45_audit.rego",
    "rules/conviction/plan44_conviction.rego",
    "rules/conviction/plan45_conviction.rego",
    "rules/kks/enterprise_penalties.rego",
    "rules/kks/kks_extensions_enterprise.rego",
    "rules/kks/plan42_detailed.rego",
    "rules/kks/plan43_decomposition.rego",
    "rules/kks/plan44_kks_conviction.rego",
    "rules/ord/ord_innovations_v8.rego",
    "rules/risk/plan26_kks.rego",
    "rules/kks.rego",
    "rules/p10_kks_innovations_v9.rego",
    "rules/p10_kks_micro_innovations_v8.rego",
    "rules/p11_ordynacja_podatkowa_innovations_v9.rego",
    "rules/p33_ordpu_kks_supplement.rego",
    "rules/r07_kks_innovations_v9.rego",
    "rules/r08_ordynacja_obrona_innovations_v9.rego",
    "rules/ord_supplements_enterprise.rego",
    "rules/audit_defense_enterprise.rego",
    "rules/defense_builder_enterprise.rego",
    "rules/gaar_shield_enterprise.rego",
    "rules/interest_calculator_enterprise.rego",
    "rules/sanctions_optimization_enterprise.rego",
    "rules/penalty_ai_enterprise.rego",
    "rules/conviction_checker_enterprise.rego",
    "rules/proceeding_tracker_enterprise.rego",
    "rules/financial_hardship_scorer_enterprise.rego",
    "rules/overpayment_auto_claimer_enterprise.rego",
    "rules/tax_authority_interaction_enterprise.rego",
    "rules/exit_tax_interest_calculator.rego",
    "rules/statute/plan26_detailed.rego",
    "rules/micro/kks_ord_atomic_p11.rego",
]

# ── Stare formy → kanon (zachowawcze zamiany stringów) ─────────────────────────
OLD_NEW = [
    ("Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
     f"Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)"),
    ("Kodeks Karny Skarbowy z dnia 10 września 1999 r. (Dz.U. 1999 nr 83 poz. 930)",
     f"Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)"),
    ("Kodeks karny skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
     f"Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)"),
    ("(Dz.U. 1999 nr 83 poz. 930)", "(Dz.U. 2025 poz. 678, ze zm.)"),
    ("Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
     f"Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)"),
    ("Ordynacja Podatkowa z dnia 29 sierpnia 1997 r. (Dz.U. 1997 nr 137 poz. 926)",
     f"Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)"),
    ("Ordynacja podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
     f"Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)"),
    ("(Dz.U. 1997 nr 137 poz. 926)", "(Dz.U. 2025 poz. 234, ze zm.)"),
    # skróty aktów w nagłówkach/komentarzach
    ("KKS z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
     "KKS (Dz.U. 2025 poz. 678, ze zm.)"),
    ("OrdPU z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
     "OrdPU (Dz.U. 2025 poz. 234, ze zm.)"),
]

# Krótkie formy "Art. X OP" / "Art. X KKS" → pełne akty (reguły audit/hyper)
SHORT_ACT_RE = [
    # "Art. 272-280 OP" → pełna nazwa (zachowuje art.)
    (re.compile(r'("_legal_basis"\s*:\s*")(Art\.\s*[\d\s\-–,\w§]+?)\s+OP(")'),
     lambda m: f'{m.group(1)}{m.group(2)} {CANON_ORD}{m.group(3)}'),
    (re.compile(r'("_legal_basis"\s*:\s*")(Art\.\s*[\d\s\-–,\w§]+?)\s+KKS(")'),
     lambda m: f'{m.group(1)}{m.group(2)} {CANON_KKS}{m.group(3)}'),
    (re.compile(r'("_legal_basis"\s*:\s*")(Art\.\s*[\d\s\-–,\w§]+?)\s+PPSA(")'),
     lambda m: f'{m.group(1)}{m.group(2)} {CANON_PPSA}{m.group(3)}'),
    (re.compile(r'("_legal_basis"\s*:\s*")(Art\.\s*[\d\s\-–,\w§]+?)\s+KAS(")'),
     lambda m: f'{m.group(1)}{m.group(2)} {CANON_KAS}{m.group(3)}'),
    (re.compile(r'("_legal_basis"\s*:\s*")(Art\.\s*[\d\s\-–,\w§]+?)\s+PP(")'),
     lambda m: f'{m.group(1)}{m.group(2)} {CANON_PP}{m.group(3)}'),
]

# Wzorce stubowe (generic conditions)
GENERIC_RE = [
    (re.compile(r'kks_condition_met\s*==\s*true'), "generic: kks_condition_met"),
    (re.compile(r'ord_condition_met\s*==\s*true'), "generic: ord_condition_met"),
    (re.compile(r'uses_penalty\s*==\s*true'), "generic: uses_penalty"),
]

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
    old_lbs = [lb for lb in set(lbs)
               if "1999 nr 83 poz. 930" in lb or "1997 nr 137 poz. 926" in lb]
    short_lbs = [lb for lb in set(lbs)
                 if re.search(r'\b(OP|KKS|PPSA|KAS)\s*"$', lb) or " OP\"" in lb]
    return {
        "file": rel,
        "rule_count": len(rids),
        "unique_rule_ids": len(set(rids)),
        "matched_true": matched_true,
        "legal_basis_count": len(lbs),
        "legal_basis_old": old_lbs,
        "legal_basis_short": short_lbs,
        "generic": generic,
        "hardcoded": hard,
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
    for rx, fn in SHORT_ACT_RE:
        text, c = rx.subn(fn, text)
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
    for rid in re.findall(r'"rule_id"\s*:\s*"([^"]+)"', (JDG_ROOT / rel).read_text(encoding="utf-8") if (JDG_ROOT / rel).exists() else ""):
        all_ids[rid] += 1
        for lb in rep["legal_basis_old"]:
            errors.append(f"{rel}: niekanoniczny _legal_basis: {lb[:80]}")
        for lb in rep["legal_basis_short"]:
            warnings.append(f"{rel}: short-form _legal_basis: {lb[:80]}")
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
                      f"old={len(r['legal_basis_old'])} short={len(r['legal_basis_short'])} "
                      f"generic={len(r['generic'])} dead={len(r['dead'])}")
            print(f"BRAMKA: {'PASS' if not errors else 'FAIL'}")
            print(f"  błędów: {len(errors)} · ostrzeżeń: {len(warnings)} · "
                  f"duplikatów: {len(dups)} · reguł: {sum(r.get('rule_count', 0) for r in reports)}")
            return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
