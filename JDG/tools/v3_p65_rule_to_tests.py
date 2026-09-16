#!/usr/bin/env python3
"""
NexusAI JDG — V3-P65 RULE-TO-TESTS GENERATOR (I03; prompt P65 Sekcja 10-I03).
Generator struktury przypadków brzegowych z treści przepisu (karty pustyni
P51, detektor kompozycji tools/v3_p51_desert_cards.py — rozszerza, nie dubluje).
Klasy brzegowe (ADR z progu v3_p65_edge_case_classes_min): dates, thresholds,
currencies, rounding. Wynik = szkielet przypadków testowych (pozytywne,
negatywne, brzegowe) gotowy do tests/auto i tests/rego.

Uruchomienie: python3 v3_p65_rule_to_tests.py [--json]
Wynik: bundles/v3_p65_i03_rule_to_tests.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p65_common import (BUNDLES, P51_CARDS, RULES_DIR, TESTS_AUTO,
                           TESTS_REGO, audit_header, now_iso, read_text,
                           read_threshold, write_json)

SCHEMA = "jdg.v3_p65.rule_to_tests.v1"
EDGE_CLASSES = ["dates", "thresholds", "currencies", "rounding"]

_RE_DATE = re.compile(r"valid_from|valid_to|2026-\d\d-\d\d|day[-_]?0|day[-_ ]?\+?1", re.I)
_RE_THRESH = re.compile(r"_th\(|thresholds\.v3_p\d+|_max|_min", re.I)
_RE_CURRENCY = re.compile(r"EUR|PLN|eur_pln|kurs|walut", re.I)
_RE_ROUNDING = re.compile(r"round|zaokr|grosz|0\.01|ceil|floor", re.I)


def extract_desert_cards() -> list[dict]:
    """Prawdziwe karty pustyni z P51 (pary przepis→test do wygenerowania)."""
    src = read_text(P51_CARDS)
    cards = []
    if src:
        # karty P51 mają wpisy aktów; ekstrakcja identyfikatorów aktów/artykułów
        for m in re.finditer(r"(?:^|\n)\s*#?\s*(art\.\s*\d+[a-zą-ę]*\s*(?:ust\.\s*\d+)?[^\n]{0,80})", src, re.I):
            cards.append({" przepis": m.group(1).strip()[:100]})
        if not cards:
            # fallback: nagłówki sekcji kart
            cards = [{" przepis": h.strip()[:100]}
                     for h in re.findall(r"^#{1,3}\s*(.+)$", src, re.M)[:20]]
    return cards


def analyze_rule_coverage() -> dict:
    """Które klasy brzegowe mają pokrycie w istniejących testach (kompozycja)?"""
    hay_auto = "\n".join(p.read_text(encoding="utf-8", errors="replace")
                         for p in sorted(TESTS_AUTO.glob("test_v3_p6*.py")))
    hay_rego = "\n".join(p.read_text(encoding="utf-8", errors="replace")
                         for p in sorted(TESTS_REGO.glob("test_v3_p6*.rego")))
    hay = hay_auto + hay_rego
    present = []
    if _RE_DATE.search(hay):
        present.append("dates")
    if _RE_THRESH.search(hay):
        present.append("thresholds")
    if _RE_CURRENCY.search(hay):
        present.append("currencies")
    if _RE_ROUNDING.search(hay):
        present.append("rounding")
    return {"present": present, "missing": [c for c in EDGE_CLASSES if c not in present]}


def generate_skeleton(rule_path: Path) -> dict:
    """Szkielet przypadków brzegowych dla reguły (statycznie z treści Rego)."""
    src = read_text(rule_path)
    cases = []
    if _RE_DATE.search(src):
        cases += [{"class": "dates", "case": "day-1 przed valid_from → NO_MATCH/stare okno", "assert": "decision in {NO_MATCH, NEEDS_ADVICE}"},
                  {"class": "dates", "case": "day-0 granica valid_from → nowe okno aktywne", "assert": "decision == oczekiwane wg nowej wersji"}]
    if _RE_THRESH.search(src):
        cases += [{"class": "thresholds", "case": "wartość == próg (granica) → nie przekracza", "assert": "decision PASS/NEEDS_ADVICE"},
                  {"class": "thresholds", "case": "wartość = próg+1 → przekroczenie → BLOCK", "assert": "decision == BLOCK"}]
    if _RE_CURRENCY.search(src):
        cases += [{"class": "currencies", "case": "EUR vs PLN (eur_pln_reference) → konwersja z provenance", "assert": "metrics.kurs z wersją i datą"}]
    if _RE_ROUNDING.search(src):
        cases += [{"class": "rounding", "case": "grosz w dół/w górę (half-up) → różnica 0,01", "assert": "kwota groszowo dokładna"}]
    return {"rule": rule_path.name, "cases": cases,
            "classes": sorted({c["class"] for c in cases})}


def main() -> int:
    ap = argparse.ArgumentParser(description="V3-P65 I03 rule-to-tests generator")
    ap.add_argument("rule", nargs="?", default=str(RULES_DIR / "v3_p65_tool_forge.rego"))
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    cov = analyze_rule_coverage()
    skel = generate_skeleton(Path(args.rule))
    cards = extract_desert_cards()
    payload = {
        "schema": SCHEMA,
        "tool": "v3_p65_rule_to_tests",
        "status": "PASS" if not cov["missing"] else "NEEDS_ADVICE",
        "edge_classes_required": EDGE_CLASSES,
        "min_classes_required": read_threshold("v3_p65_edge_case_classes_min") or 4,
        "coverage": cov,
        "skeleton": skel,
        "desert_cards_found": len(cards),
        "desert_cards_sample": cards[:5],
        "acceleration_note": "szkielet 4 klas brzegowych = start zamiast pustej strony (przyspieszenie ok. 5x wg promptu P65 Sekcja 2)",
        "evidence": "tools/v3_p51_desert_cards.py (karty pustyni P51 — kompozycja) + tests/auto + tests/rego (pokrycie klas)",
        "provenance": "art. 109e VAT (kompletność ewidencji) [NIEZWERYFIKOWANE — ISAP]; P51 karty pustyni; prompt P65 Sekcja 10-I03",
        "generated_at": now_iso(),
    }
    write_json(BUNDLES / "v3_p65_i03_rule_to_tests.json",
               {"header": audit_header({"I03_test_generator": None}), "result": payload})
    print(f"[P65:I03] rule_to_tests coverage={cov['present']} missing={cov['missing'] or 'none'} cases={len(skel['cases'])}")
    return 0 if not cov["missing"] else 1


if __name__ == "__main__":
    sys.exit(main())
