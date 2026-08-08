#!/usr/bin/env python3
"""
NexusAI JDG — AUDYT PODSTAW PRAWNYCH (_legal_basis) (P02 — sekcje 2 i 5)
=========================================================================
Audyt zgodności podstaw prawnych WSZYSTKICH reguł z kanonicznym słownikiem
referencji (bundles/legal_reference_canon.json). Klasyfikacja:

  • OK             — podstawa kanoniczna („Art. X ... ustawy o VAT (Dz.U. ...)"),
  • MISSING        — reguła bez _legal_basis (bramka CI: FAIL),
  • UNKNOWN_ACT    — akt nierozpoznany w słowniku kanonicznym,
  • NON_CANONICAL  — brak wzorca „Art. X" lub nazwy aktu (np. sam komentarz).

Output: bundles/legal_basis_audit.json + docs/AUDYT_PODSTAW_PRAWNYCH.md.
Bramka: python legal_basis_audit.py --gate (FAIL przy MISSING/UNKNOWN_ACT).

Usage:
  python legal_basis_audit.py [--gate] [--json] [--act ustawy o VAT]
"""

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
CANON = JDG_ROOT / "bundles" / "legal_reference_canon.json"
OUT_JSON = JDG_ROOT / "bundles" / "legal_basis_audit.json"
OUT_MD = JDG_ROOT / "docs" / "AUDYT_PODSTAW_PRAWNYCH.md"

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
LEGAL_BASIS_RE = re.compile(r'"_?legal_basis"\s*:\s*"([^"]+)"')
ART_RE = re.compile(r"[Aa]rt\.\s*\d+")
DZ_U_RE = re.compile(r"Dz\.U\.\s*\d{4}")


def load_canon() -> dict:
    if CANON.exists():
        return json.loads(CANON.read_text(encoding="utf-8"))
    return {"acts": []}


def scan_rules() -> list[dict]:
    rules = []
    for path in sorted(RULES_DIR.rglob("*.rego")):
        content = path.read_text(encoding="utf-8", errors="ignore")
        rel = str(path.relative_to(JDG_ROOT))
        for m in RULE_ID_RE.finditer(content):
            ctx = content[m.start():m.start() + 4000]
            lb = LEGAL_BASIS_RE.search(ctx)
            rules.append({
                "rule_id": m.group(1),
                "file": rel,
                "legal_basis": lb.group(1) if lb else "",
            })
    return rules


def _inflections(short: str) -> list[str]:
    """Formy odmiany canonical_short (mianownik/dopełniacz/miejscownik) —
    „ustawa o VAT" → „ustawy o VAT", „ustawie o VAT" (odporność na odmianę)."""
    forms = [short]
    for head, tail in (("ustawa", "ustawy"), ("ustawa", "ustawie"),
                       ("rozporządzenie", "rozporządzenia"), ("rozporządzenie", "rozporządzeniu"),
                       ("prawo", "prawa"), ("kodeks", "kodeksu"), ("kodeks", "kodeksie")):
        if short.startswith(head + " "):
            forms.append(tail + short[len(head):])
    return forms


def classify(basis: str, acts: list[dict]) -> tuple[str, str | None]:
    """Zwraca (klasa, znaleziony akt kanoniczny lub None)."""
    if not basis or not basis.strip():
        return "MISSING", None
    if not ART_RE.search(basis):
        return "NON_CANONICAL", None
    lb = basis.lower()
    for act in acts:
        if any(k in lb for k in act.get("keywords", [])):
            # akt rozpoznany — sprawdź format kanoniczny (z odmianą)
            if any(f in lb for f in _inflections(act["canonical_short"].lower())):
                return "OK", act["canonical_short"]
            return "NON_CANONICAL", act["canonical_short"]
    return "UNKNOWN_ACT", None


def run_audit() -> dict:
    canon = load_canon()
    acts = canon.get("acts", [])
    rules = scan_rules()
    rows = []
    stats = Counter()
    by_act = defaultdict(int)
    for r in rules:
        cls, act = classify(r["legal_basis"], acts)
        stats[cls] += 1
        if act:
            by_act[act] += 1
        rows.append({**r, "class": cls, "canonical_act": act})
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "rules_total": len(rules),
        "stats": dict(stats),
        "by_act": dict(by_act),
        "rows": rows,
        "rv_metric": round((stats.get("OK", 0) / len(rules)) * 100, 2) if rules else 100.0,
        "canon_acts": len(acts),
    }


def write_md(report: dict) -> None:
    s = report["stats"]
    lines = [
        "# ⚖️ AUDYT PODSTAW PRAWNYCH (_legal_basis) — P02 (sekcja 5)",
        "",
        f"> Wygenerowano: {report['generated_at']} · generator: `legal_basis_audit.py`",
        f"> Słownik kanoniczny: `bundles/legal_reference_canon.json` ({report['canon_acts']} aktów)",
        "",
        "## Statystyki",
        "",
        f"- Reguły ogółem: {report['rules_total']}",
        f"- **OK** (kanoniczne): {s.get('OK', 0)}",
        f"- **MISSING** (brak podstawy): {s.get('MISSING', 0)}",
        f"- **UNKNOWN_ACT** (akt nierozpoznany): {s.get('UNKNOWN_ACT', 0)}",
        f"- **NON_CANONICAL** (format poza kanonem): {s.get('NON_CANONICAL', 0)}",
        f"- **RV** (reguły z podstawą kanoniczną): {report['rv_metric']}% (cel V2: 100%)",
        "",
        "## Reguły BEZ podstawy prawnej (MISSING) — pełna lista",
        "",
    ]
    missing = [r for r in report["rows"] if r["class"] == "MISSING"]
    lines += [f"- `{r['rule_id']}` ({r['file']})" for r in missing[:200]] or ["- (brak)"]
    lines += [
        "",
        "## Reguły z aktem nierozpoznanym (UNKNOWN_ACT)",
        "",
    ]
    unknown = [r for r in report["rows"] if r["class"] == "UNKNOWN_ACT"]
    lines += [f"- `{r['rule_id']}`: {r['legal_basis'][:90]}" for r in unknown[:100]] or ["- (brak)"]
    lines += [
        "",
        "## Pokrycie per akt kanoniczny",
        "",
        "| Akt | Reguły |",
        "|---|---|",
    ]
    lines += [f"| {act} | {cnt} |" for act, cnt in sorted(report["by_act"].items(), key=lambda x: -x[1])]
    lines += [
        "",
        "*Słownik kanoniczny: „Art. X ust. Y pkt Z ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)\"*",
        "",
    ]
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"✅ Raport: {OUT_MD.relative_to(JDG_ROOT)}")


def main() -> None:
    p = argparse.ArgumentParser(description="Audyt podstaw prawnych — P02 sekcja 5")
    p.add_argument("--gate", action="store_true", help="bramka CI: FAIL przy MISSING/UNKNOWN_ACT")
    p.add_argument("--json", action="store_true")
    p.add_argument("--act", default=None, help="filtruj raport do aktu (canonical_short)")
    args = p.parse_args()

    report = run_audit()
    if args.act:
        rows = [r for r in report["rows"] if r.get("canonical_act") == args.act]
        report["rows"] = rows
        report["rules_total"] = len(rows)
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    s = report["stats"]
    print(f"⚖️  AUDYT PODSTAW: {report['rules_total']} reguł · OK={s.get('OK', 0)} · "
          f"MISSING={s.get('MISSING', 0)} · UNKNOWN_ACT={s.get('UNKNOWN_ACT', 0)} · "
          f"NON_CANONICAL={s.get('NON_CANONICAL', 0)} · RV={report['rv_metric']}%")
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return
    write_md(report)

    if args.gate:
        bad = s.get("MISSING", 0) + s.get("UNKNOWN_ACT", 0)
        if bad > 0:
            print(f"❌ BRAMKA: {bad} reguł z MISSING/UNKNOWN_ACT — blokada (RV < 100%)")
            sys.exit(1)
        print("✅ BRAMKA: zero reguł bez podstawy — RV=100%")


if __name__ == "__main__":
    main()
