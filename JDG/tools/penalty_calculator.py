#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KKS PENALTY CALCULATOR (GLM52 P11)
# Kalkulator kary KKS (art. 54-83): typ czynu → stawka dzienna → liczba stawek
# → kwota, z dowodem (provenance) dla organów. Ścieżki minimalizacji:
# czynny żal (art. 16), dobrowolne poddanie (art. 17), recydywa (art. 37),
# przedawnienie (art. 44).
# Progi z data.jdg.thresholds.jdg.kks (ADR-002) — fallback wbudowany.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parents[1]


def round2(x: float) -> float:
    return round(x * 100) / 100


def _load_kks_thresholds() -> dict:
    """Progi KKS z data.jdg.thresholds.jdg.kks (ADR-002) — fallback wbudowany."""
    fallback = {
        "min_wage": 4800.0,
        "daily_rate_denominator": 30,
        "daily_rate_max_multiple": 400,
        "max_rates_crime": 720,
        "max_rates_misdemeanor": 240,
        "limitation_years_crime": 5,
        "limitation_years_misdemeanor": 3,
        "small_value_multiple": 500,
        "active_remorse_impact_pct": 0.50,
        "voluntary_submission_impact_pct": 0.50,
        "recidivism_days_window": 1825,
        "statute_limitation_kks_years": 5,
    }
    path = JDG_ROOT / "rules" / "thresholds_jdg.rego"
    if not path.exists():
        return fallback
    text = path.read_text(encoding="utf-8")
    m = re.search(r"kks := \{([^}]*)\}", text, re.S)
    if not m:
        return fallback
    body = m.group(1)
    for key in list(fallback.keys()):
        fm = re.search(rf'"{key}"\s*:\s*([\d.]+)', body)
        if fm:
            fallback[key] = float(fm.group(1))
    return fallback


# Typy czynów KKS (art. 54-83) — typ → art., rodzaj (przestępstwo/wykroczenie),
# bazowa liczba stawek, uwagi
CRIME_TYPES = {
    "art54": {"art": "54", "name": "Uchylanie się od opodatkowania", "kind": "PRZESTEPSTWO",
              "base_rates": 120, "notes": "Zaniżenie podstawy opodatkowania > 10%"},
    "art56": {"art": "56", "name": "Nierzetelne księgi", "kind": "PRZESTEPSTWO",
              "base_rates": 120, "notes": "Nierzetelne prowadzenie ksiąg"},
    "art57": {"art": "57", "name": "Nierzetelna ewidencja", "kind": "PRZESTEPSTWO",
              "base_rates": 120, "notes": "Nierzetelne prowadzenie ewidencji"},
    "art62": {"art": "62", "name": "Puste faktury", "kind": "PRZESTEPSTWO",
              "base_rates": 180, "notes": "Wystawienie faktury niezgodnie ze stanem faktycznym"},
    "art77": {"art": "77", "name": "Niezłożenie deklaracji", "kind": "WYKROCZENIE",
              "base_rates": 40, "notes": "Nieprzekazanie deklaracji w terminie"},
    "art80": {"art": "80", "name": "Naruszenie obowiązków rejestracyjnych", "kind": "WYKROCZENIE",
              "base_rates": 20, "notes": "Brak zgłoszenia rejestracyjnego"},
}


def penalty_calculator(
    amount: float,
    offense: str = "art54",
    daily_rates: int = 0,
    min_wage: float | None = None,
    remorse_before_detection: bool = False,
    voluntary_submission: bool = False,
    recidivism: bool = False,
) -> dict[str, Any]:
    """Kalkulator kary: typ → stawka dzienna → liczba stawek → kwota, z dowodem.

    Stawka dzienna (art. 23 § 2 KKS): od 1/720 do 1/30 minimalnego wynagrodzenia.
    Liczba stawek (art. 27 KKS): wykroczenie do 240, przestępstwo do 720.
    """
    ths = _load_kks_thresholds()
    info = CRIME_TYPES.get(offense, CRIME_TYPES["art54"])
    min_wage = min_wage or ths["min_wage"]

    daily_rate_min = round2(min_wage / ths["daily_rate_denominator"])
    daily_rate = daily_rate_min
    # stawka dzienna: 1/30 min. wynagrodzenia (maksymalna bazowa)
    daily_rate = round2(min_wage / ths["daily_rate_denominator"])

    if daily_rates <= 0:
        daily_rates = info["base_rates"]
    max_rates = (ths["max_rates_crime"] if info["kind"] == "PRZESTEPSTWO"
                 else ths["max_rates_misdemeanor"])
    daily_rates = min(daily_rates, max_rates)

    penalty = round2(daily_rate * daily_rates)

    # ścieżki minimalizacji
    reduction_pct = 0.0
    path = "BRAK"
    if remorse_before_detection:
        reduction_pct = ths["active_remorse_impact_pct"] * 100
        path = "CZYNNY_ZAL_art16"
    elif voluntary_submission:
        reduction_pct = ths["voluntary_submission_impact_pct"] * 100
        path = "DOBROWOLNE_PODDANIE_art17"

    penalty_after = round2(penalty * (1 - reduction_pct / 100)) if reduction_pct else penalty

    multiplier = 2.0 if recidivism else 1.0
    final_penalty = round2(penalty_after * multiplier)

    return {
        "offense": offense,
        "art": info["art"],
        "offense_name": info["name"],
        "kind": info["kind"],
        "tax_amount_pln": round2(amount),
        "min_wage_pln": min_wage,
        "daily_rate_pln": daily_rate,
        "daily_rate_min_pln": daily_rate_min,
        "rates_count": daily_rates,
        "rates_max": max_rates,
        "penalty_base_pln": penalty,
        "minimization_path": path,
        "reduction_pct": reduction_pct,
        "penalty_after_reduction_pln": penalty_after,
        "recidivism_multiplier": multiplier,
        "final_penalty_pln": final_penalty,
        "proof": {
            "formula": "stawka dzienna (1/30 min.) × liczba stawek",
            "daily_rate": daily_rate,
            "rates": daily_rates,
            "minimization": path or "brak",
            "legal": "Art. 23 § 2, 27, 54 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
        },
    }


def four_path_simulator(
    tax_arrears: float,
    audit_started: bool = False,
    detection_imminent: bool = False,
) -> dict[str, Any]:
    """Symulator 4-ścieżkowej minimalizacji kary (art. 16/17/81 OP/obrona)."""
    base = penalty_calculator(tax_arrears)
    base_penalty = base["final_penalty_pln"]

    paths = {
        "CZYNNY_ZAL": round2(base_penalty * 0.0),  # umorzenie (znikoma szkodliwość)
        "DOBROWOLNE_PODDANIE": round2(base_penalty * 0.5),
        "KOREKTA_PRZED_KONTROLA": round2(base_penalty * 0.3),
        "OBRONA_AUDYTOWA": round2(base_penalty * 0.0 if detection_imminent else base_penalty * 0.7),
    }

    # rekomendacja: najlepsza dostępna ścieżka
    if audit_started:
        paths["CZYNNY_ZAL"] = None  # po rozpoczęciu kontroli czynny żal NIE działa
    available = {k: v for k, v in paths.items() if v is not None}
    best = min(available.values(), default=base_penalty)
    best_path = next((k for k, v in available.items() if v == best), "BRAK")

    return {
        "tax_arrears_pln": round2(tax_arrears),
        "base_penalty_pln": base_penalty,
        "paths": paths,
        "recommended_path": best_path,
        "recommended_penalty_pln": best,
        "audit_started": audit_started,
        "note": "Czynny żal (art. 16) tylko przed wykryciem; korekta (art. 81b) w 14 dni",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    r = penalty_calculator(100000, offense="art54")
    if r["kind"] != "PRZESTEPSTWO":
        failures.append("art54 powinno być przestępstwem")
    if r["penalty_base_pln"] != round2(r["daily_rate_pln"] * r["rates_count"]):
        failures.append("kara ≠ stawka × stawek")
    r2 = penalty_calculator(100000, offense="art54", remorse_before_detection=True)
    if r2["final_penalty_pln"] != round2(r2["penalty_after_reduction_pln"]):
        failures.append("czynny żal: final ≠ after_reduction")
    if r2["final_penalty_pln"] >= r["final_penalty_pln"]:
        failures.append("czynny żal powinien obniżyć karę")
    r3 = penalty_calculator(100000, offense="art77")
    if r3["kind"] != "WYKROCZENIE":
        failures.append("art77 powinno być wykroczeniem")
    s = four_path_simulator(50000)
    if s["recommended_penalty_pln"] != 0:
        failures.append("bez kontroli: czynny żal → 0 zł")
    s2 = four_path_simulator(50000, audit_started=True)
    if s2["paths"]["CZYNNY_ZAL"] is not None:
        failures.append("po kontroli czynny żal niedostępny")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="KKS Penalty Calculator (GLM52 P11)")
    ap.add_argument("--amount", type=float, default=100000.0, help="kwota uszczuplenia")
    ap.add_argument("--offense", default="art54", choices=sorted(CRIME_TYPES))
    ap.add_argument("--rates", type=int, default=0, help="liczba stawek dziennych (0 = bazowa)")
    ap.add_argument("--remorse", action="store_true", help="czynny żal przed wykryciem (art. 16)")
    ap.add_argument("--voluntary", action="store_true", help="dobrowolne poddanie (art. 17)")
    ap.add_argument("--recidivism", action="store_true", help="recydywa (art. 37)")
    ap.add_argument("--simulate", action="store_true", help="symulator 4 ścieżek")
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

    if args.simulate:
        print(json.dumps(four_path_simulator(args.amount), ensure_ascii=False, indent=2))
        return 0

    print(json.dumps(penalty_calculator(
        args.amount, offense=args.offense, daily_rates=args.rates,
        remorse_before_detection=args.remorse,
        voluntary_submission=args.voluntary, recidivism=args.recidivism,
    ), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
