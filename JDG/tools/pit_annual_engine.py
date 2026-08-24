#!/usr/bin/env python3
"""
NexusAI JDG — PIT ANNUAL ENGINE v2 (PROMPT 05 — PIT MAKRO, Sekcja 1/3)
====================================================================
Auto-zeznania roczne z werdyktów OPA (zero ręki): PIT-36 (skala),
PIT-36L (liniowy), PIT-28 (ryczałt). Zgodność: art. 45 PIT (termin 30.04),
art. 27 (skala 12%/32% + degresja kwoty zmniejszającej), art. 30c (liniowy
19%), art. 21 (zwolnienia), art. 63 § 1 OrdPU (zaokrąglanie do pełnych
złotych), art. 44 (zaliczki miesięczne/kwartalne/uproszczone).

v2 (RAPORT_GLM52_P05_PIT_MAKRO.txt, INN-02/INN-08/INN-09/INN-10):
  • kwota zmniejszająca podatek (art. 27 ust. 1): 3 600 zł (dochód ≤ 30 000),
    degresja liniowa 30 000–120 000, zero ≥ 120 000
  • zaokrąglanie art. 63 § 1 OrdPU (round_grosz): 0–49 gr w dół, 50–99 w górę
  • zaliczki: miesięczne (20.), kwartalne mały podatnik (20.04/20.07/20.10/20.01,
    art. 44 ust. 3g), uproszczone 1/12 (art. 44 ust. 6b) — lista płatności
  • PIT-28: stawki per kategoria PKWiU (2/3/5,5/8,5/12/15/17%) zamiast
    płaskiej 8,5%
  • rozliczenie roczne: nadpłata (zwrot ≤ 45 dni, art. 77 § 1 OrdPU) /
    niedopłata (dopłata + odsetki 14,5% / art. 53a OrdPU)

  • compute    — werdykty → podstawa, podatek, składki, ulgi (groszowo)
  • declaration— wybór formularza (PIT-36/36L/28) + wypełnienie pól
  • advances   — terminarz zaliczek (miesięczne/kwartalne/uproszczone)
  • settlement — nadpłata/niedopłata roczna z zaliczek
  • verify     — groszowy dowód (invariant: podatek = f(podstawa, stawki))

Zgodność: thresholds.pit (scale_low_rate, scale_high_rate, scale_threshold,
          tax_free_amount, linear_rate, annual_return_pit36/pit28_deadline,
          advance_due_day, quarterly_advance_due_months),
          thresholds.zus (health_*).

Usage:
  python pit_annual_engine.py compute --verdicts verdicts.json --form PIT_SCALE
  python pit_annual_engine.py declaration --verdicts verdicts.json
  python pit_annual_engine.py advances --income 100000 --form PIT_SCALE --quarterly
  python pit_annual_engine.py settlement --annual-tax 25000 --advances-paid 22000
  python pit_annual_engine.py verify --computed computed.json
"""

import argparse
import json
import sys
from datetime import date
from pathlib import Path

from pit_temporal_snapshot_engine import get_snapshot_for_year

SCALE_LOW = 0.12
SCALE_HIGH = 0.32
SCALE_THRESHOLD = 120000
TAX_FREE = 30000
LINEAR_RATE = 0.19
HEALTH_SCALE = 0.09
HEALTH_LINEAR = 0.049

# Kwota zmniejszająca podatek (art. 27 ust. 1 PIT, od 2022)
TAX_REDUCING_FULL = 3600.0          # 12% × 30 000 zł
DEGRESSION_START = 30000.0          # pełna kwota do 30 000 zł
DEGRESSION_END = 120000.0           # zero od 120 000 zł

# Stawki ryczałtu per kategoria (art. 12 ustawy o ryczałcie, spójne z
# jdg.pit.forms.lump_sum_rate_by_pkwiu / thresholds.rates.lump_*)
LUMP_RATES = {
    "trade": 0.02,                  # PKWiU 01-03 (handel)
    "production_food": 0.03,        # PKWiU 10-33 (produkcja/gastronomia)
    "gastronomy": 0.03,
    "construction": 0.055,          # PKWiU 41-43 (budownictwo)
    "services": 0.085,              # PKWiU 58-61, 72 (usługi, IT)
    "it": 0.085,
    "freelance": 0.085,
    "it_high": 0.12,                # PKWiU 62-63 (IT, wolne zawody > 300k)
    "freelance_high": 0.12,
    "management": 0.15,             # PKWiU 68 (zarządzanie nieruchomościami)
    "transport": 0.17,              # PKWiU 69-82 (wolne zawody, transport)
    "professional": 0.17,
}

QUARTERLY_DUE_MONTHS = [4, 7, 10, 1]   # art. 44 ust. 3g — 20.04/20.07/20.10/20.01
ADVANCE_DUE_DAY = 20
PIT36_DEADLINE = "04-30"               # art. 45 ust. 1 PIT
PIT28_DEADLINE = "02-28"               # art. 21 ust. 1 ustawy o ryczałcie


def _next_working_day(day: date) -> date:
    """Przesuwa termin na następny dzień roboczy (art. 12 § 5 OrdPU)."""
    from datetime import timedelta
    while day.weekday() >= 5:
        day += timedelta(days=1)
    return day
REFUND_DAYS = 45                       # art. 77 § 1 OrdPU
INTEREST_RATE = 0.145                  # art. 53a OrdPU (2026)


def _num(v, default=0.0):
    try:
        return round(float(v), 2)
    except (TypeError, ValueError):
        return default


def round_grosz(value: float) -> int:
    """Art. 63 § 1 OrdPU: zaokrąglenie do pełnych złotych (0–49 gr w dół,
    50–99 gr w górę). Zwraca int (pełne złote)."""
    v = _num(value)
    frac = v - int(v)
    if frac >= 0.5:
        return int(v) + 1
    return int(v)


def _pit_parameters(tax_year: int = 2026) -> dict:
    snapshot = get_snapshot_for_year(tax_year)
    if not snapshot:
        raise ValueError(f"Brak temporalnego snapshotu PIT dla roku {tax_year}")
    return {
        "scale_low_rate": snapshot["scale_low_rate"],
        "scale_high_rate": snapshot["scale_high_rate"],
        "scale_threshold": snapshot["scale_threshold"],
        "tax_free_amount": snapshot["tax_free_amount"],
        "tax_reducing_amount": snapshot["tax_reducing_amount"],
        "legal_basis": snapshot["legal_basis"],
    }


def tax_reducing_amount(income: float, tax_year: int = 2026) -> float:
    """Kwota zmniejszająca podatek (art. 27 ust. 1 PIT od 2022):
    pełna 3 600 zł do 30 000 zł dochodu, degresja liniowa 30k–120k, zero ≥ 120k."""
    income = max(0.0, _num(income))
    params = _pit_parameters(tax_year)
    reduction = params["tax_reducing_amount"]
    reduction_start = params["tax_free_amount"]
    reduction_end = params["scale_threshold"]
    if income <= reduction_start:
        return reduction
    if income >= reduction_end:
        return 0.0
    ratio = (income - reduction_start) / (reduction_end - reduction_start)
    return round(reduction * (1.0 - ratio), 2)


def scale_tax(income: float, apply_reducing: bool = True, tax_year: int = 2026) -> dict:
    """Podatek wg skali 12/32% + kwota zmniejszająca (groszowo)."""
    income = max(0.0, _num(income))
    params = _pit_parameters(tax_year)
    threshold = params["scale_threshold"]
    low_rate = params["scale_low_rate"]
    high_rate = params["scale_high_rate"]
    if income <= threshold:
        tax = round(income * low_rate, 2)
        bracket = "LOW"
    else:
        tax = round(threshold * low_rate + (income - threshold) * high_rate, 2)
        bracket = "HIGH"
    reducing = tax_reducing_amount(income, tax_year) if apply_reducing else 0.0
    return {
        "bracket": bracket,
        "gross_tax": tax,
        "tax_reducing_amount": reducing,
        "tax_after_reducing": round(max(0.0, tax - reducing), 2),
        "tax_year": tax_year,
        "legal_basis": params["legal_basis"],
    }


def lump_tax(revenue: float, kup: float = 0.0, category: str = "services") -> float:
    """Ryczałt: (przychód − KUP) × stawka per kategoria (art. 12 u.z.p.d.)."""
    base = max(0.0, _num(revenue) - _num(kup))
    rate = LUMP_RATES.get(category, 0.085)
    return round(base * rate, 2)


def compute(verdicts: list, form: str = "PIT_SCALE", lump_category: str = "services",
            tax_year: int = 2026) -> dict:
    """Werdykty OPA → roczne rozliczenie (skala/liniowy/ryczałt)."""
    revenue = sum(_num(v.get("amount_net")) for v in verdicts if v.get("direction") == "SALE")
    kup = sum(_num(v.get("kup_amount")) for v in verdicts if v.get("kup_amount"))
    zus_social = sum(_num(v.get("zus_social_paid")) for v in verdicts if v.get("zus_social_paid"))
    zus_health = sum(_num(v.get("zus_health_paid")) for v in verdicts if v.get("zus_health_paid"))
    income = round(revenue - kup - zus_social, 2)

    if form == "PIT_SCALE":
        taxable = max(0.0, income - _pit_parameters(tax_year)["tax_free_amount"])
        st = scale_tax(income, tax_year=tax_year)
        tax = st["tax_after_reducing"]
        form_code = "PIT-36"
        health_deductible = 0.0  # skala: brak odliczenia zdrowotnej (2022+)
        detail = {"tax_reducing_amount": st["tax_reducing_amount"], "gross_tax": st["gross_tax"]}
    elif form == "LINEAR":
        taxable = income
        tax = round(income * LINEAR_RATE, 2)
        form_code = "PIT-36L"
        health_deductible = min(zus_health, round(income * HEALTH_LINEAR, 2))  # 4.9% odliczenia
        detail = {"tax_reducing_amount": 0.0}
    else:  # LUMP_SUM (ryczałt — stawki per kategoria, art. 12 u.z.p.d.)
        taxable = income
        tax = lump_tax(revenue, kup, lump_category)
        form_code = "PIT-28"
        health_deductible = 0.0
        detail = {"lump_rate": LUMP_RATES.get(lump_category, 0.085), "lump_category": lump_category}

    return {
        "form": form_code,
        "revenue": revenue,
        "kup": kup,
        "zus_social": zus_social,
        "zus_health": zus_health,
        "income": income,
        "taxable": taxable,
        "tax": tax,
        "health_deductible": health_deductible,
        "to_pay": round(tax - health_deductible, 2),
        "detail": detail,
        "tax_year": tax_year,
        "legal_basis": _pit_parameters(tax_year)["legal_basis"],
    }


def declaration(verdicts: list, tax_year: int = 2026) -> dict:
    """Auto-wybór formularza + wypełnienie z werdyktów."""
    form = "PIT_SCALE"
    lump_category = "services"
    for v in verdicts:
        if v.get("pit_form"):
            form = v["pit_form"]
            break
    for v in verdicts:
        if v.get("pkwiu_code"):
            lump_category = _lump_category_from_pkwiu(v["pkwiu_code"])
            break
    r = compute(verdicts, form, lump_category, tax_year)
    return {
        "declaration": r["form"],
        "fields": {
            "revenue": r["revenue"],
            "kup": r["kup"],
            "income": r["income"],
            "tax": r["tax"],
            "to_pay": r["to_pay"],
        },
        "deadline": PIT36_DEADLINE if r["form"] != "PIT-28" else PIT28_DEADLINE,
        "auto_filled": True,
        "tax_year": tax_year,
        "legal_basis": r["legal_basis"],
    }


def _lump_category_from_pkwiu(pkwiu: str) -> str:
    """Mapowanie PKWiU (2 cyfry) → kategoria ryczałtu (spójne z Rego)."""
    code = str(pkwiu).split(".")[0][:2]
    if code in {"01", "02", "03"}:
        return "trade"
    if code in {"10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
                "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
                "30", "31", "32", "33", "56"}:
        return "production_food"
    if code in {"41", "42", "43", "64", "65", "66"}:
        return "construction"
    if code in {"62", "63"}:
        return "it_high"
    if code in {"58", "59", "60", "61", "72"}:
        return "it"
    if code == "68":
        return "management"
    if code in {"69", "70", "71", "73", "74", "75", "77", "78", "79", "80", "81", "82"}:
        return "transport"
    return "services"


def advances(form: str = "PIT_SCALE", income: float = 0.0, prev_year_income: float = 0.0,
             quarterly: bool = False, simplified: bool = False, year: int = 2026) -> dict:
    """Terminarz zaliczek (art. 44 PIT):
    — miesięczne: 20. każdego miesiąca,
    — kwartalne (mały podatnik, art. 44 ust. 3g): 20.04 / 20.07 / 20.10 / 20.01,
    — uproszczone (art. 44 ust. 6b): 1/12 podatku z roku poprzedniego."""
    income = max(0.0, _num(income))
    if form == "LINEAR":
        annual_tax = round(income * LINEAR_RATE, 2)
    elif form == "LUMP_SUM":
        annual_tax = lump_tax(income)
    else:
        annual_tax = scale_tax(income, tax_year=year)["tax_after_reducing"]

    if simplified and prev_year_income > 0:
        prev_tax = scale_tax(prev_year_income)["tax_after_reducing"] if form != "LINEAR" \
            else round(prev_year_income * LINEAR_RATE, 2)
        installment = round(prev_tax / 12, 2)
        frequency = "SIMPLIFIED_1_12"
        payments = [{"due_date": f"{year}-{m:02d}-{ADVANCE_DUE_DAY:02d}", "amount": installment}
                    for m in range(1, 13)]
        note = "Zaliczki uproszczone: 1/12 podatku z roku poprzedniego (art. 44 ust. 6b PIT)"
    elif quarterly:
        quarterly_tax = round(annual_tax / 4, 2)
        frequency = "QUARTERLY"
        payments = [{"quarter": f"Q{q}", "due_date": f"{year}-{m:02d}-{ADVANCE_DUE_DAY:02d}",
                     "amount": quarterly_tax}
                    for q, m in enumerate(QUARTERLY_DUE_MONTHS, start=1)]
        note = "Zaliczki kwartalne małego podatnika: 20.04 / 20.07 / 20.10 / 20.01 (art. 44 ust. 3g PIT)"
    else:
        monthly_tax = round(annual_tax / 12, 2)
        frequency = "MONTHLY"
        payments = [{"due_date": f"{year}-{m:02d}-{ADVANCE_DUE_DAY:02d}", "amount": monthly_tax}
                    for m in range(1, 13)]
        note = "Zaliczki miesięczne: 20. dzień miesiąca (art. 44 ust. 1 i 3 PIT)"

    total = round(sum(p["amount"] for p in payments), 2)
    return {
        "form": form,
        "frequency": frequency,
        "annual_tax_est": annual_tax,
        "payments": payments,
        "total_advances": total,
        "due_day": ADVANCE_DUE_DAY,
        "note": note,
        "rounded_grosz": [round_grosz(p["amount"]) for p in payments],  # art. 63 OrdPU
    }


def settlement(annual_tax: float, advances_paid: float) -> dict:
    """Rozliczenie roczne (art. 45 ust. 6 PIT + art. 77 § 1 OrdPU):
    nadpłata → zwrot ≤ 45 dni; niedopłata → dopłata + odsetki 14,5%."""
    diff = round(_num(annual_tax) - _num(advances_paid), 2)
    if diff < 0:
        return {
            "type": "NADPŁATA",
            "amount": abs(diff),
            "refund_days": REFUND_DAYS,
            "action": f"Zwrot na konto w ciągu {REFUND_DAYS} dni od złożenia zeznania",
        }
    if diff > 0:
        return {
            "type": "NIEDOPŁATA",
            "amount": diff,
            "interest_rate": INTEREST_RATE,
            "action": f"Dopłać {round(diff, 2)} zł + odsetki {INTEREST_RATE * 100:.1f}% rocznie",
        }
    return {"type": "ZEROWE", "amount": 0.0, "action": "Brak dopłaty/zwrotu"}


def verify(computed: dict) -> dict:
    """Groszowy dowód: invariant podatek = f(podstawa, stawki) ± 0.01."""
    tax = computed["tax"]
    income = computed["income"]
    form = computed.get("form", "PIT-36")
    if form == "PIT-36L":
        expected = round(income * LINEAR_RATE, 2)
    elif form == "PIT-28":
        expected = lump_tax(computed.get("revenue", income), computed.get("kup", 0.0),
                            computed.get("detail", {}).get("lump_category", "services"))
    else:
        expected = scale_tax(income, tax_year=computed.get("tax_year", 2026))["tax_after_reducing"]
    return {"consistent": abs(tax - expected) <= 0.01, "tax": tax, "expected": expected}


def schedule(year: int = 2026) -> dict:
    """Terminy roczne: PIT-36/36L 30.04, PIT-28 28.02 (korekta weekendu)."""
    pit36 = _next_working_day(date(year, 4, 30))
    pit28 = _next_working_day(date(year, 2, 28))
    return {
        "pit_36_36l": pit36.isoformat(),
        "pit_28": pit28.isoformat(),
        "pit36_deadline": PIT36_DEADLINE,
        "pit28_deadline": PIT28_DEADLINE,
        "correction": "do 30 dni po wykryciu błędu (art. 81 OrdPU)",
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="PIT Annual Engine v2")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_c = sub.add_parser("compute")
    p_c.add_argument("--verdicts", required=True)
    p_c.add_argument("--form", default="PIT_SCALE", choices=["PIT_SCALE", "LINEAR", "LUMP_SUM"])
    p_c.add_argument("--lump-category", default="services")

    p_d = sub.add_parser("declaration")
    p_d.add_argument("--verdicts", required=True)

    p_a = sub.add_parser("advances")
    p_a.add_argument("--income", type=float, required=True)
    p_a.add_argument("--form", default="PIT_SCALE", choices=["PIT_SCALE", "LINEAR", "LUMP_SUM"])
    p_a.add_argument("--prev-year-income", type=float, default=0.0)
    p_a.add_argument("--quarterly", action="store_true")
    p_a.add_argument("--simplified", action="store_true")
    p_a.add_argument("--year", type=int, default=2026)

    p_s = sub.add_parser("settlement")
    p_s.add_argument("--annual-tax", type=float, required=True)
    p_s.add_argument("--advances-paid", type=float, required=True)

    p_v = sub.add_parser("verify")
    p_v.add_argument("--computed", required=True)

    p_sc = sub.add_parser("schedule")
    p_sc.add_argument("--year", type=int, default=2026)

    args = ap.parse_args(argv)

    if args.cmd == "compute":
        print(json.dumps(compute(_load(args.verdicts), args.form, args.lump_category),
                         ensure_ascii=False, indent=2))
    elif args.cmd == "declaration":
        print(json.dumps(declaration(_load(args.verdicts)), ensure_ascii=False, indent=2))
    elif args.cmd == "advances":
        print(json.dumps(advances(args.form, args.income, args.prev_year_income,
                                  args.quarterly, args.simplified, args.year),
                         ensure_ascii=False, indent=2))
    elif args.cmd == "settlement":
        print(json.dumps(settlement(args.annual_tax, args.advances_paid),
                         ensure_ascii=False, indent=2))
    elif args.cmd == "verify":
        print(json.dumps(verify(_load(args.computed)), ensure_ascii=False, indent=2))
    else:
        print(json.dumps(schedule(args.year), ensure_ascii=False, indent=2))
    return 0


def _load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


if __name__ == "__main__":
    sys.exit(main())
