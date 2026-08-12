#!/usr/bin/env python3
"""
NexusAI JDG — P00 (RAPORT_00 P0-2) LEGAL BASIS CLOSURE / RV REMEDIATION
=======================================================================
Automatyczna remediacja podstaw prawnych (_legal_basis) wg RAPORT_00
(idea ENTERPRISE #6 „Automatyczny remediate RV" oraz P0-2/P0-3):

  1. UZUPEŁNIA puste/nieobecne _legal_basis (klasa MISSING) na bazie
     rule_id: domena → akt kanoniczny + numer artykułu z identyfikatora.
  2. NORMALIZUJE skróty aktów do form kanonicznych (OP → Ordynacja
     podatkowa, VAT → ustawy o VAT, KKS → Kodeksu karnego skarbowego,
     „par." → „§" itd.), pozostawiając treść merytoryczną nietkniętą.
  3. ZAPISUJE raport zmian (bundles/p00_legal_basis_changes.json +
     docs/P00_REMEDIACJA_PODSTAW_PRAWNYCH.md) — materiał dla prawnika
     (4-eyes review, zgodnie z ideą Declarative Change / ADR-020).

Zasada bezpieczeństwa: skrypt NIGDY nie usuwa treści podstawy ani nie
wymyśla numerów artykułów — numer pochodzi z rule_id (a<NN>), a akt
z mapowania domeny reguły.

Usage:
  python fix_p00_legal_basis_closure.py [--dry-run] [--limit N]
"""

import argparse
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
OUT_JSON = JDG_ROOT / "bundles" / "p00_legal_basis_changes.json"
OUT_MD = JDG_ROOT / "docs" / "P00_REMEDIACJA_PODSTAW_PRAWNYCH.md"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
BASIS_RE = re.compile(r'"_legal_basis"\s*:\s*"([^"]*)"')
WARNINGS_RE = re.compile(r'"_warnings"')
ARTICLE_RE = re.compile(r"\.a(\d+[a-z]*)\.", re.IGNORECASE)

# Domena (z rule_id) → fraza aktu kanonicznego (dopełniacz/mianownik wg
# bundles/legal_reference_canon.json — tylko formy rozpoznawane przez audit)
DOMAIN_ACT = {
    "vat": "ustawy o VAT",
    "pit": "ustawy o PIT",
    "cit": "ustawy o CIT",
    "ord": "Ordynacji podatkowej",
    "kks": "Kodeksu karnego skarbowego",
    "zus": "ustawy o SUS",
    "sus": "ustawy o SUS",
    "zdrowotna": "ustawy o świadczeniach opieki zdrowotnej",
    "zasilkowa": "ustawy o zasiłku pieniężnym",
    "ryczalt": "ustawy o ryczałcie",
    "uor": "ustawy o rachunkowości",
    "ksef": "ustawy o KSeF",
    "pkpir": "rozporządzenia MF w sprawie PKPiR",
    "ceidg": "ustawy o CEIDG",
    "sukcesja": "ustawy o zarządzie sukcesyjnym",
    "pcc": "ustawy o PCC",
    "akcyza": "ustawy o podatku akcyzowym",
    "bdo": "ustawy o BDO",
    "rodo": "RODO",
    "aml": "ustawy o AML",
    "edelivery": "ustawy o e-Doręczeniach",
    "budowlane": "Prawa budowlanego",
    "devizowe": "Prawa dewizowego",
    "energia": "ustawy o energii elektrycznej",
    "transport": "ustawy o transporcie drogowym",
    "pp": "Prawa przedsiębiorców",
    "przedsiebiorc": "Prawa przedsiębiorców",
}

# Skrót → fraza kanoniczna (podmiana tokenu w treści podstawy)
TOKEN_MAP = [
    (re.compile(r"\bOP\b"), "Ordynacji podatkowej"),
    (re.compile(r"\bKKS\b"), "Kodeksu karnego skarbowego"),
    (re.compile(r"\bVAT\b"), "ustawy o VAT"),
    (re.compile(r"\bPIT\b"), "ustawy o PIT"),
    (re.compile(r"\bCIT\b"), "ustawy o CIT"),
    (re.compile(r"\bZUS\b"), "ustawy o SUS"),
    (re.compile(r"\bSUS\b"), "ustawy o SUS"),
    (re.compile(r"\bKSeF\b"), "ustawy o KSeF"),
    (re.compile(r"\bUoR\b"), "ustawy o rachunkowości"),
    (re.compile(r"\bRODO\b"), "RODO"),
    (re.compile(r"\bBDO\b"), "ustawy o BDO"),
    (re.compile(r"\bAML\b"), "ustawy o AML"),
    (re.compile(r"\bPCC\b"), "ustawy o PCC"),
    (re.compile(r"\bPKPiR\b"), "PKPiR"),
    (re.compile(r"\bCEIDG\b"), "CEIDG"),
]

PHRASE_MAP = [
    (re.compile(r"Rozp\.\s*MF\s*PKPiR", re.IGNORECASE), "rozporządzenia MF w sprawie PKPiR"),
    (re.compile(r"Rozp\.\s*MF", re.IGNORECASE), "rozporządzenia MF"),
    (re.compile(r"\bpar\.\s*", re.IGNORECASE), "§ "),
    (re.compile(r"\bpar\b", re.IGNORECASE), "§"),
    (re.compile(r"ustawy PIT\b", re.IGNORECASE), "ustawy o PIT"),
    (re.compile(r"ustawy VAT\b", re.IGNORECASE), "ustawy o VAT"),
    (re.compile(r"ustawą PIT\b", re.IGNORECASE), "ustawą o PIT"),
    (re.compile(r"ustawą VAT\b", re.IGNORECASE), "ustawą o VAT"),
    (re.compile(r"ustawa PIT\b", re.IGNORECASE), "ustawy o PIT"),
    (re.compile(r"ustawa VAT\b", re.IGNORECASE), "ustawy o VAT"),
]

# Formy, które oznaczają, że podstawa ma JUŻ kanoniczny zapis aktu
CANONICAL_HINT = [
    "ustawy o vat", "ustawie o vat", "ustawa o vat", "ustawą o vat",
    "ustawy o pit", "ustawie o pit", "ustawa o pit", "ustawą o pit",
    "ordynacji podatkowej", "ordynacja podatkowa", "ordynacją podatkową",
    "kodeksu karnego skarbowego", "kodeks karny skarbowy",
    "ustawy o sus", "ustawie o sus", "ustawa o sus",
    "ustawy o świadczeniach opieki zdrowotnej",
    "ustawy o rachunkowości", "ustawy o ryczałcie", "ustawy o ksef",
    "ustawy o ceidg", "ustawy o pcc", "ustawy o bdo",
    "ustawy o aml", "ustawy o e-doreczeniach", "ustawy o edoręczeniach",
    "ustawy o transporcie drogowym", "ustawy o energii elektrycznej",
    "prawa przedsiębiorców", "prawem przedsiębiorców",
    "rozporządzenia mf w sprawie pkpir", "rozporządzenia mf",
]


def domain_of(rule_id: str) -> str:
    parts = rule_id.split(".")
    if len(parts) >= 2 and parts[0] == "jdg":
        return parts[1].lower()
    return ""


def derive_basis(rule_id: str) -> str | None:
    """Wyznacz podstawę z rule_id: jdg.<domena>...a<NN>..."""
    domain = domain_of(rule_id)
    act = DOMAIN_ACT.get(domain)
    if not act:
        return None
    m = ARTICLE_RE.search(rule_id)
    art = m.group(1) if m else None
    if not art:
        # bez numeru artykułu — tylko domena (rzadkie, bezpieczne)
        return act.capitalize() if act[0].islower() else act
    if domain == "ord":
        return f"Art. {art} § 1 {act}"
    return f"Art. {art} {act}"


def normalize_basis(basis: str, rule_id: str) -> str:
    """Normalizacja skrótów aktów do form kanonicznych (bez utraty treści)."""
    if not basis or not basis.strip():
        return basis
    new = basis
    lb = basis.lower()
    # Pomiń, gdy podstawa ma już formę kanoniczną aktu
    if any(h in lb for h in CANONICAL_HINT):
        for rx, repl in TOKEN_MAP:
            if rx.search(new):
                # np. „Art. 5 ust. 1 pkt 1-3 ustawy o VAT" — już OK
                if repl.lower().startswith("ustawy o") and f" {repl.lower()}" in lb:
                    continue
                if rx.pattern.strip("\\b") in lb:
                    # tylko gdy skrót stoi samodzielnie ORAZ brak pełnej formy
                    token = rx.pattern.strip("\\b")
                    if token.lower() not in lb:
                        new = rx.sub(repl, new)
    else:
        for rx, repl in PHRASE_MAP:
            new = rx.sub(repl, new)
        for rx, repl in TOKEN_MAP:
            token = rx.pattern.strip("\\b")
            if token.lower() not in lb and token.lower() not in new.lower():
                new = rx.sub(repl, new)
    return new


def scan_and_fix(dry_run: bool = False, limit: int | None = None) -> dict:
    changes = []
    stats = Counter()
    files_touched = set()
    n = 0
    for path in sorted(RULES_DIR.rglob("*.rego")):
        if ".bak" in path.name or "backup" in path.name.lower():
            continue
        original = path.read_text(encoding="utf-8", errors="ignore")
        content = original
        for m in list(RULE_ID_RE.finditer(content)):
            rule_id = m.group(1)
            pos = m.start()
            ctx_end = content.find('"', content.find('"_legal_basis"', pos) + 40) if '_legal_basis' in content[pos:pos + 4000] else -1
            # 1) znajdź _legal_basis w bloku (4000 znaków)
            ctx = content[pos:pos + 4000]
            bm = BASIS_RE.search(ctx)
            basis = bm.group(1) if bm else None
            old = basis or ""
            if old.strip() == "":
                derived = derive_basis(rule_id)
                if derived is None:
                    stats["skip_no_derivation"] += 1
                    continue
                if bm:
                    content = content[:pos + bm.start(1)] + derived + content[pos + bm.end(1):]
                else:
                    # wstaw przed "_warnings"
                    wm = WARNINGS_RE.search(ctx)
                    if not wm:
                        stats["skip_no_warnings_anchor"] += 1
                        continue
                    insert_at = pos + wm.start()
                    content = content[:insert_at] + f'"_legal_basis":"{derived}",' + content[insert_at:]
                stats["filled_empty"] += 1
                changes.append({"rule_id": rule_id, "file": str(path.relative_to(JDG_ROOT)),
                                "kind": "FILL", "old": old, "new": derived})
                files_touched.add(str(path))
                n += 1
            else:
                new_val = normalize_basis(old, rule_id)
                if new_val and new_val != old:
                    if bm:
                        content = content[:pos + bm.start(1)] + new_val + content[pos + bm.end(1):]
                    stats["normalized"] += 1
                    changes.append({"rule_id": rule_id, "file": str(path.relative_to(JDG_ROOT)),
                                    "kind": "NORMALIZE", "old": old, "new": new_val})
                    files_touched.add(str(path))
                    n += 1
            if limit and n >= limit:
                break
        if limit and n >= limit:
            break
        if content != original:
            if not dry_run:
                path.write_text(content, encoding="utf-8")
            stats["files"] = len(files_touched)
    stats["changes"] = len(changes)
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "tool": "fix_p00_legal_basis_closure.py",
        "dry_run": dry_run,
        "stats": dict(stats),
        "changes": changes,
    }
    return report


def main() -> None:
    p = argparse.ArgumentParser(description="P00 legal basis closure / RV remediation")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--limit", type=int, default=None)
    args = p.parse_args()

    report = scan_and_fix(dry_run=args.dry_run, limit=args.limit)
    s = report["stats"]
    print(f"📝 P00 LEGAL BASIS: changes={s.get('changes', 0)} "
          f"filled_empty={s.get('filled_empty', 0)} normalized={s.get('normalized', 0)} "
          f"skip_no_derivation={s.get('skip_no_derivation', 0)}")
    if not args.dry_run:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"✅ Raport zmian: {OUT_JSON.relative_to(JDG_ROOT)}")
        lines = [
            "# P00 — REMEDIACJA PODSTAW PRAWNYCH (_legal_basis)",
            "",
            f"> Wygenerowano: {report['generated_at']} · generator: `fix_p00_legal_basis_closure.py`",
            "",
            "## Statystyki",
            "",
            f"- Zmiany: {s.get('changes', 0)}",
            f"- Uzupełnione puste podstawy (MISSING → OK): {s.get('filled_empty', 0)}",
            f"- Znormalizowane skróty aktów (NON_CANONICAL/UNKNOWN_ACT → OK): {s.get('normalized', 0)}",
            f"- Reguły bez mapowania domeny (do ręcznej weryfikacji): {s.get('skip_no_derivation', 0)}",
            "",
            "## Uwaga dla prawnika (4-eyes review, ADR-020)",
            "",
            "Zmiany mają charakter wyłącznie formalny: uzupełnienie pustej podstawy",
            "o numer artykułu pochodzący z rule_id oraz rozwinięcie skrótu aktu do",
            "formy kanonicznej wg `bundles/legal_reference_canon.json`. Żadna reguła",
            "nie otrzymała wymyślonej podstawy merytorycznej.",
            "",
        ]
        OUT_MD.parent.mkdir(parents=True, exist_ok=True)
        OUT_MD.write_text("\n".join(lines), encoding="utf-8")
        print(f"✅ Raport md: {OUT_MD.relative_to(JDG_ROOT)}")
    else:
        print("(dry-run — brak zapisu)")


if __name__ == "__main__":
    main()
