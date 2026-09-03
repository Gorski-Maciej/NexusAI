#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I03 RECIPE LIBRARY
=========================================
Katalog 6 wzorców zmian prawa (recipes): zmiana stawki, zmiana progu, nowy
limit czasowy, zmiana terminu, uchylenie przepisu, zmiana definicji. Każdy
recipe: parametry do zmiany, reguły do wersjonowania, testy do generacji,
ryzyka, podstawa prawna.

Usage:
  python tools/v3_p09_recipe_library.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

RECIPES = {
    "RATE_CHANGE": {
        "desc": "Zmiana stawki (VAT/ryczałt/składka)",
        "params": ["vat.standard_rate", "vat.reduced_rate_8", "vat.reduced_rate_5",
                   "vat.reduced_rate_0", "zus.health_rate"],
        "rule_ids": [], "tests": ["day-1/0/+1 boundary", "groszowe granice"],
        "risks": ["zła data wejścia", "błędna stawka"],
        "legal": "VAT art. 41; ryczałt art. 12; zdrowotna art. 79-81",
    },
    "THRESHOLD_CHANGE": {
        "desc": "Zmiana progu (PIT skala, limity)",
        "params": ["pit.scale_threshold", "pit.tax_free_amount"],
        "rule_ids": ["jdg.form_optimizer.financial_simulator"],
        "tests": ["wartość graniczna progu", "przekroczenie o 1 zł"],
        "risks": ["zaokrąglenia", "retroaktywność"],
        "legal": "PIT art. 27, 30c; ryczałt art. 6",
    },
    "NEW_LIMIT": {
        "desc": "Nowy limit czasowy (ulga okresowa)",
        "params": ["zus.limit_maly_zus", "zdrowotne.limit_roczny"],
        "rule_ids": [], "tests": ["początek/koniec okna", "przekroczenie limitu"],
        "risks": ["brak okna valid_to"],
        "legal": "SUS art. 18a/18c; u.ś.o.z. art. 81",
    },
    "DEADLINE_CHANGE": {
        "desc": "Zmiana terminu (składania/opłat)",
        "params": ["ord.term_rozliczen", "vat.term_platnosci"],
        "rule_ids": [], "tests": ["day przed/po terminie"],
        "risks": ["konflikt z innymi terminami"],
        "legal": "OrdPU art. 24a; VAT art. 103",
    },
    "REPEAL": {
        "desc": "Uchylenie przepisu",
        "params": [], "rule_ids": ["deprecate w P07"],
        "tests": ["reguła nie odpala po dacie", "zero referencji"],
        "risks": ["reguła ACTIVE z uchyloną podstawą = P1"],
        "legal": "P08-I08 (REPEALED → deprecate)",
    },
    "DEFINITION_CHANGE": {
        "desc": "Zmiana definicji (pojęcia)",
        "params": [], "rule_ids": ["wersjonowanie reguł P07"],
        "tests": ["klasyfikacja przed/po zmianie"],
        "risks": ["wpływ na wiele domen"],
        "legal": "właściwa ustawa domenowa",
    },
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    dc = (TOOLS / "declarative_change.py").read_text(encoding="utf-8")
    # ile typów zmian zna declarative_change.py?
    known = [t for t in RECIPES if t in dc]
    recipe_artifact = (BUNDLES / "v3_p09_recipe_library.json").exists()

    checks.append({"name": "six_recipes", "status": "OK" if len(RECIPES) == 6 else "FAIL",
                   "detail": f"katalog recipes: {len(RECIPES)} (RATE/THRESHOLD/NEW_LIMIT/"
                             "DEADLINE/REPEAL/DEFINITION)"})
    known_desc = ', '.join(known) if known else 'RATE_CHANGE/THRESHOLD_CHANGE/LEGAL_CHANGE'
    checks.append({"name": "recipes_in_tool", "status": "FAIL",
                   "detail": f"declarative_change.py rozpoznaje tylko: {known_desc} — "
                              "bez REPEAL/DEADLINE/DEFINITION/NEW_LIMIT"})

    findings.append({"id": "V3-P09-L03", "severity": "P1",
                     "evidence": "declarative_change.py ma 3 wzorce regex (RATE_CHANGE, "
                                 "THRESHOLD_CHANGE, LEGAL_CHANGE); brak katalogu 6 recipes z "
                                 "parametrami/testami/ryzykami — zmiany typu uchylenie, termin, "
                                 "definicja, nowy limit czasowy nie mają szablonu generacji",
                     "fix": "I03 Recipe Library (ten artefakt): 6 recipes z mapą param→test→"
                            "ryzyko→podstawa; nowy typ zmiany = nowy recipe, nie nowy regex"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I03", "generated_at": now(), "gate": gate,
        "metrics": {"recipes": len(RECIPES), "types_in_tool": known,
                    "recipe_artifact": recipe_artifact},
        "recipes": RECIPES,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P09-I04 (testy z recipes), P09-I02 (kompilacja wg recipes), "
                                "P08 (Law Radar diff → recipe), P06/P07 (wykonanie)",
                     "rule": "zmiana mapowana do recipe; recipe bez pokrycia testowego "
                             "nie może produkować AUTO_POST"}}
    (BUNDLES / "v3_p09_recipe_library.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I03] gate={gate} recipes={len(RECIPES)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
