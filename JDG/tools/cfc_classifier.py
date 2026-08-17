#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CFC AUTO-CLASSIFIER (GLM52 P12)
# CFC (art. 30f PIT): kontrola ≥50% (udziały), dochody pasywne ≥33%,
# podatek zagraniczny <14.25% (połowa polskiego CIT) → przypisanie dochodu
# proporcjonalnie do udziału; wyłączenia (rzeczywista działalność, EBITDA).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parents[1]


def _load_thresholds() -> dict:
    fallback = {
        "cfc_ownership_min_pct": 0.50,
        "cfc_passive_income_pct": 0.33,
        "cfc_tax_rate_threshold_pct": 0.1425,
    }
    path = JDG_ROOT / "rules" / "thresholds_jdg.rego"
    if not path.exists():
        return fallback
    text = path.read_text(encoding="utf-8")
    m = re.search(r"crossborder := \{([^}]*)\}", text, re.S)
    if not m:
        return fallback
    body = m.group(1)
    for key in list(fallback.keys()):
        fm = re.search(rf'"{key}"\s*:\s*([\d.]+)', body)
        if fm:
            fallback[key] = float(fm.group(1))
    return fallback


def round2(x: float) -> float:
    return round(x * 100) / 100


def classify(
    ownership_pct: float,
    passive_income_pct: float,
    foreign_tax_rate_pct: float,
    cfc_income_pln: float = 0.0,
    real_economic_activity: bool = False,
    ebitda_ratio: float = 0.0,
    ebitda_threshold: float = 0.0,
) -> dict[str, Any]:
    """Auto-klasyfikator CFC: 3 testy + wyłączenia → przypisany dochód."""
    ths = _load_thresholds()
    tests = {
        "kontrola_50pct": ownership_pct >= ths["cfc_ownership_min_pct"],
        "dochody_pasywne_33pct": passive_income_pct >= ths["cfc_passive_income_pct"],
        "podatek_ponizej_14_25": foreign_tax_rate_pct < ths["cfc_tax_rate_threshold_pct"],
    }
    cfc = all(tests.values())
    # wyłączenia (art. 30f ust. 2-3 PIT)
    excluded = False
    exclusion = ""
    if real_economic_activity:
        excluded = True
        exclusion = "rzeczywista działalność gospodarcza (art. 30f ust. 2)"
    elif ebitda_threshold > 0 and ebitda_ratio >= ebitda_threshold:
        excluded = True
        exclusion = "wskaźnik EBITDA przekroczony (art. 30f ust. 3)"

    final_cfc = cfc and not excluded
    attributed = round2(cfc_income_pln * ownership_pct) if final_cfc else 0.0

    return {
        "cfc_classified": final_cfc,
        "tests": tests,
        "excluded": excluded,
        "exclusion_reason": exclusion,
        "ownership_pct": ownership_pct,
        "passive_income_pct": passive_income_pct,
        "foreign_tax_rate_pct": foreign_tax_rate_pct,
        "attributed_income_pln": attributed,
        "legal": "Art. 30f ust. 1-3 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    c = classify(0.60, 0.50, 0.10, cfc_income_pln=100000)
    if not c["cfc_classified"]:
        failures.append("60%/50%/10% → CFC")
    if c["attributed_income_pln"] != 60000:
        failures.append("przypisanie 60% z 100k = 60k")
    c2 = classify(0.40, 0.50, 0.10)
    if c2["cfc_classified"]:
        failures.append("40% udziału → NIE CFC")
    c3 = classify(0.60, 0.50, 0.10, real_economic_activity=True)
    if c3["cfc_classified"]:
        failures.append("rzeczywista działalność → wyłączenie")
    c4 = classify(0.60, 0.20, 0.10)
    if c4["cfc_classified"]:
        failures.append("20% pasywnych → NIE CFC")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="CFC Auto-Classifier (GLM52 P12)")
    ap.add_argument("--ownership", type=float, default=0.0)
    ap.add_argument("--passive", type=float, default=0.0)
    ap.add_argument("--foreign-tax", type=float, default=0.0)
    ap.add_argument("--income", type=float, default=0.0)
    ap.add_argument("--real-activity", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)

    if args.self_test:
        failures = self_test()
        if failures:
            print("SELF-TEST: FAIL")
            for f in failures:
                print(f"  ❌ {f}")
            return 1
        print("SELF-TEST: PASS")
        return 0

    print(json.dumps(classify(args.ownership, args.passive, args.foreign_tax, args.income,
                              real_economic_activity=args.real_activity),
                     ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
