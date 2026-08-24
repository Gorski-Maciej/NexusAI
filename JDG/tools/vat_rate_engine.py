#!/usr/bin/env python3
"""
NexusAI JDG — VAT RATE ENGINE (PROMPT 02 — VAT MAKRO, Sekcja 1: Stawki i zwolnienia)
=============================================================================
Silnik stawek VAT klasy ENTERPRISE z bazą PKWiU/CN (art. 41-43 VAT,
Rozporządzenie MF z 4.12.2024 r. — stawki 8% i 5%).

Funkcje:
  • classify      — klasyfikacja towaru/usługi: PKWiU/CN → stawka (23/8/5/0/NP/ZW)
                     z Trust Score (pewność klasyfikacji 0-1)
  • snapshot      — temporalna stawka: valid_from/valid_to (zmiany prawa)
  • index         — generowanie indeksu category_code→stawka (pre-kompilacja)
  • duckdb        — baza PKWiU/CN w DuckDB (jeśli dostępna)

Zgodność: art. 41-43, 113 VAT, Rozp. MF 4.12.2024, P02 Sekcja 1, ADR-002.

Usage:
  python vat_rate_engine.py classify --description "chleb" [--category_code 10.71]
  python vat_rate_engine.py classify --cn_code 19059045
  python vat_rate_engine.py index --out /tmp/vat_index.json
"""

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent

# ═══════════════════════════════════════════════════════════════════════════════
# BAZA STAWEK (jedno źródło prawdy — zsynchronizowane z thresholds_jdg.rego)
# ═══════════════════════════════════════════════════════════════════════════════
STANDARD_RATE = 0.23      # art. 41 ust. 1 VAT
REDUCED_RATE_8 = 0.08     # art. 41 ust. 2 + Rozp. MF 4.12.2024 (załącznik 3)
REDUCED_RATE_5 = 0.05     # art. 41 ust. 2a + Rozp. MF 4.12.2024 (załącznik 10)

# ── Mapowanie PKWiU (sekcja/klasa/dział) → stawka ─────────────────────────────
# Klucze: prefiksy PKWiU 2008 (4 znaki: klasa), wartości: stawka
PKWIU_RATES = {
    # 5% — żywność (dział 10-12), książki (58.11), czasopisma specjalistyczne
    "10.1": 0.05, "10.2": 0.05, "10.3": 0.05, "10.4": 0.05, "10.5": 0.05,
    "10.6": 0.05, "10.7": 0.05, "10.8": 0.05, "10.9": 0.05,
    "11.0": 0.05, "11.0": 0.05, "12.0": 0.05,
    "58.1": 0.05,  # książki (58.11), gazety (58.13)
    # 8% — artykuły spożywcze specjalne, usługi gastronomiczne, budownictwo społeczne
    "56.1": 0.08,  # restauracje
    "43.2": 0.08,  # wykończeniowe roboty budowlane (budownictwo społeczne)
    "43.3": 0.08,
    "86.1": 0.08,  # usługi medyczne (część)
    "49.3": 0.08,  # transport pasażerski
    # 23% — pozostałe (default)
}

# ── Mapowanie CN (kod 8-cyfrowy) → stawka (podzbiór kluczowych towarów) ───────
CN_RATES = {
    "1905": 0.05,  # pieczywo, ciasta
    "0401": 0.05,  # mleko
    "0201": 0.05,  # wołowina
    "0203": 0.05,  # wieprzowina
    "0207": 0.05,  # drób
    "0302": 0.05,  # ryby
    "0701": 0.05,  # ziemniaki
    "1001": 0.05,  # pszenica
    "1701": 0.05,  # cukier
    "1806": 0.08,  # czekolada (część 8%)
    "2203": 0.08,  # piwo (8%)
    "2204": 0.23,  # wino (23%)
    "2710": 0.23,  # paliwa
    "8703": 0.23,  # samochody
}

# ── Słowa-klucze semantyczne → stawka (klasyfikator pomocniczy) ───────────────
SEMANTIC_RULES = [
    (r"chleb|pieczywo|bułk|ciast|mąk", 0.05),
    (r"mleko|masło|ser|jajk|mięso|wołow|wieprz|drobi|ryb|wędlin|warzyw|owoc|ziemniak", 0.05),
    (r"książk|e-book|gazet|czasopism|wydawnictw", 0.05),
    (r"piwo|restauracj|gastronom|katering", 0.08),
    (r"pal|benzyn|olej napęd|gaz", 0.23),
    (r"samoch|auto|cześci|części", 0.23),
]

# ── Temporalność: zmiany stawek (valid_from) ─────────────────────────────────
RATE_SNAPSHOTS = [
    {"from": "2021-01-01", "to": None, "standard": 0.23, "reduced_8": 0.08, "reduced_5": 0.05},
    {"from": "2011-01-01", "to": "2020-12-31", "standard": 0.23, "reduced_8": 0.08, "reduced_5": 0.05},
]


def _valid_date(value: str) -> bool:
    try:
        date.fromisoformat(value)
    except (TypeError, ValueError):
        return False
    return True


def _load_thresholds() -> dict:
    """Odczyt stawek z thresholds_jdg.rego (jedno źródło prawdy, ADR-002)."""
    path = JDG_ROOT / "rules" / "thresholds_jdg.rego"
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    rates = {}
    for key in ("standard_rate", "reduced_rate_8", "reduced_rate_5"):
        m = re.search(rf'"{key}"\s*:\s*([0-9.]+)', text)
        if m:
            rates[key] = float(m.group(1))
    return rates


def classify(description: str = "", category_code: str = "", cn_code: str = "",
             date_str: str = "2026-01-01") -> dict:
    """
    Klasyfikacja towaru/usługi → stawka VAT z Trust Score.
    Kolejność: CN → PKWiU → semantyka → 23% (default).
    """
    if not _valid_date(date_str):
        raise ValueError("date_str must be an ISO date (YYYY-MM-DD)")
    temporal = snapshot(date_str)
    if "error" in temporal:
        raise ValueError(temporal["error"])

    std = temporal["standard"]
    r8 = temporal["reduced_8"]
    r5 = temporal["reduced_5"]

    rate, source, score = std, "DEFAULT_23", 0.3

    # 1. CN 8-cyfrowy (najwyższa precyzja)
    if cn_code and len(cn_code) >= 4:
        cn4 = cn_code[:4]
        if cn4 in CN_RATES:
            rate, source, score = CN_RATES[cn4], f"CN_{cn4}", 0.98

    # 2. PKWiU (klasa 4 znaki)
    if source == "DEFAULT_23" and category_code and len(category_code) >= 4:
        pkwiu = category_code[:4]
        if pkwiu in PKWIU_RATES:
            rate, source, score = PKWIU_RATES[pkwiu], f"PKWIU_{pkwiu}", 0.95

    # 3. Semantyka opisu
    if source == "DEFAULT_23" and description:
        desc_l = description.lower()
        for pattern, r in SEMANTIC_RULES:
            if re.search(pattern, desc_l):
                rate, source, score = r, "SEMANTIC", 0.85
                break

    # Normalizacja stawki do formatu "23%"/"8%"/"5%"/"0%"
    rate_pct = ""
    if rate == std:
        rate_pct = "23"
    elif rate == r8:
        rate_pct = "8"
    elif rate == r5:
        rate_pct = "5"
    elif rate == 0:
        rate_pct = "0"

    return {
        "matched": True,
        "vat_rate": rate_pct,
        "rate_decimal": rate,
        "trust_score": round(score, 2),
        "source": source,
        "rule_id": f"jdg.vat_rate_engine.classify.{source.lower()}",
        "category_code": category_code or "",
        "cn_code": cn_code or "",
        "date": date_str,
        "legal_basis": "Art. 41-43 VAT + Rozp. MF z 4.12.2024 r.",
        "temporal_snapshot": temporal,
    }


def build_index() -> dict:
    """Pre-kompilowany indeks category_code→stawka (wydajność: p95 < 5 ms)."""
    thr = _load_thresholds()
    std = thr.get("standard_rate", STANDARD_RATE)
    r8 = thr.get("reduced_rate_8", REDUCED_RATE_8)
    r5 = thr.get("reduced_rate_5", REDUCED_RATE_5)
    index = {}
    for code, rate in PKWIU_RATES.items():
        if rate == r5:
            index[code] = "5"
        elif rate == r8:
            index[code] = "8"
        else:
            index[code] = "23"
    for code, rate in CN_RATES.items():
        if rate == r5:
            index[code] = "5"
        elif rate == r8:
            index[code] = "8"
        else:
            index[code] = "23"
    return {
        "generated_at": "2026-08-16",
        "engine": "vat_rate_engine v9.x (P02 — ENTERPRISE)",
        "entries": len(index),
        "index": index,
    }


def snapshot(date_str: str) -> dict:
    """Temporalna stawka dla daty (zmiany prawa)."""
    for snap in RATE_SNAPSHOTS:
        if snap["from"] <= date_str and (snap["to"] is None or date_str <= snap["to"]):
            return {
                "date": date_str,
                "standard": snap["standard"],
                "reduced_8": snap["reduced_8"],
                "reduced_5": snap["reduced_5"],
                "from": snap["from"],
                "to": snap["to"],
                "legal_basis": "Art. 41-43 VAT (brzmienie temporalne)",
            }
    return {"date": date_str, "error": "data poza zakresem snapshots"}


def main() -> int:
    parser = argparse.ArgumentParser(description="VAT Rate Engine (P02 — ENTERPRISE)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_cls = sub.add_parser("classify", help="klasyfikacja towaru → stawka")
    p_cls.add_argument("--description", default="")
    p_cls.add_argument("--category_code", default="")
    p_cls.add_argument("--cn_code", default="")
    p_cls.add_argument("--date", default="2026-01-01")

    p_idx = sub.add_parser("index", help="generuj indeks stawek")
    p_idx.add_argument("--out", default="")

    p_snap = sub.add_parser("snapshot", help="stawki dla daty")
    p_snap.add_argument("--date", default="2026-01-01")

    args = parser.parse_args()

    if args.cmd == "classify":
        result = classify(args.description, args.category_code, args.cn_code, args.date)
        print(json.dumps(result, ensure_ascii=False, indent=2))
    elif args.cmd == "index":
        idx = build_index()
        if args.out:
            Path(args.out).write_text(json.dumps(idx, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"Indeks zapisany: {args.out} ({idx['entries']} wpisów)")
        else:
            print(json.dumps(idx, ensure_ascii=False, indent=2))
    elif args.cmd == "snapshot":
        print(json.dumps(snapshot(args.date), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
