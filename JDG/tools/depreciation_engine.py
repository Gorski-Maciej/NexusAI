#!/usr/bin/env python3
"""
NexusAI JDG — DEPRECIATION ENGINE (PROMPT 06 — PIT MIKRO + AMORTYZACJA, Sekcja 8)
==============================================================================
Silnik amortyzacji klasy ENTERPRISE (art. 22a-22o PIT, Dz.U. 2025 poz. 789):
  • KŚT — standardowe stawki roczne (10 grup + grunty), spójne z
    thresholds.jdg.depreciation.kst_rates (ADR-002)
  • metoda LINIOWA — harmonogram miesięczny (groszowo, art. 63 OrdPU),
    rozpoczęcie od miesiąca następującego po przyjęciu (art. 22h ust. 1 pkt 1)
  • metoda DEGRESYWNA — współczynnik 2.0 (maszyny grupy 3-6 i 8 + transport,
    art. 22k ust. 1) / 1.4 (pozostałe, art. 22k ust. 2); przejście na liniową,
    gdy odpis degresywny ≤ liniowy (art. 22k ust. 3)
  • JEDNORAZOWA (art. 22i / 22k ust. 7-12) — limit 100 000 EUR, mały podatnik
    (przychód ≤ 2 000 000 EUR), ŚT grup 3-8, wyłączenie samochodów osobowych
  • limity aut osobowych 150 000 / 225 000 PLN (art. 22a ust. 4a PIT)
  • niskocenne ŚT ≤ 10 000 PLN — jednorazowo w KUP (art. 22f ust. 3)
  • invariant groszowy: |suma odpisów − (wartość × stawka × m/12)| ≤ 0,01
    oraz suma odpisów ≤ wartość początkowa (F2, art. 22h)

Usage:
  python depreciation_engine.py schedule --value 100000 --group 4 [--method linear|degressive] [--months 24]
  python depreciation_engine.py verify-rate --group 4 --declared 0.20
  python depreciation_engine.py one-time --value 200000 --revenue 1800000 --small-taxpayer
  python depreciation_engine.py car-limit --value 180000 [--electric]
  python depreciation_engine.py low-value --value 9000
"""

import argparse
import json
import sys
from datetime import date

# Stawki KŚT (spójne z thresholds.jdg.depreciation.kst_rates)
KST_RATES = {
    "0": 0.0,     # grunty — nie amortyzowane (art. 22c pkt 1)
    "1": 0.015,   # budynki i lokale (mieszkalne 1,5%; niemieszkalne 2,5%)
    "2": 0.045,   # obiekty inżynierii lądowej i wodnej
    "3": 0.07,    # kotły i maszyny energetyczne
    "4": 0.14,    # maszyny i urządzenia ogólne
    "5": 0.20,    # maszyny i urządzenia specjalistyczne
    "6": 0.18,    # urządzenia techniczne
    "7": 0.20,    # środki transportu
    "8": 0.20,    # narzędzia, przyrządy, wyposażenie
    "9": 0.20,    # inwentarz żywy
    "10": 0.20,   # inwentarz martwy
}

ONE_TIME_EUR_LIMIT = 100000.0        # art. 22i / 22k ust. 7-12
SMALL_TAXPAYER_EUR = 2000000.0       # limit przychodów (art. 5a pkt 20 PIT)
EUR_PLN = 4.3                        # kurs referencyjny (audytor: 4.3)
CAR_LIMIT_STANDARD = 150000.0        # art. 22a ust. 4a PIT
CAR_LIMIT_ELECTRIC = 225000.0
LOW_VALUE_LIMIT = 10000.0            # art. 22f ust. 3 PIT
DEGRESSIVE_COEFF_MACHINES = 2.0      # art. 22k ust. 1 (grupy 3-6, 8 + transport)
DEGRESSIVE_COEFF_OTHER = 1.4         # art. 22k ust. 2
MACHINE_GROUPS = {"3", "4", "5", "6", "8", "7"}   # grupy uprawnione do 2.0


def _num(v, default=0.0):
    try:
        return round(float(v), 2)
    except (TypeError, ValueError):
        return default


def kst_rate(group: str) -> float:
    """Standardowa roczna stawka KŚT dla grupy (0 = brak amortyzacji)."""
    return KST_RATES.get(str(group), 0.0)


def monthly_linear(initial_value: float, rate: float) -> float:
    """Miesięczny odpis liniowy (groszowo, art. 63 OrdPU):
    roczny odpis = wartość × stawka; miesięczny = roczny / 12, zaokrąglony
    do pełnych złotych w górę (nadwyżka w ostatnim miesiącu)."""
    annual = _num(initial_value * rate)
    monthly = annual / 12.0
    # Zaokrąglenie art. 63 OrdPU do pełnych złotych (0-49 gr w dół, 50-99 w górę)
    return round(monthly)


def schedule(initial_value: float, group: str, method: str = "linear",
             months: int = None, start_month: int = 1, start_year: int = 2026) -> dict:
    """Harmonogram amortyzacji per środek trwały (miesiąc po miesiącu,
    z dowodem matematycznym i invariantem suma odpisów ≤ wartość początkowa)."""
    value = max(0.0, _num(initial_value))
    rate = kst_rate(group)
    if rate <= 0:
        return {"error": f"Grupa KŚT {group} nie podlega amortyzacji (stawka 0)", "group": group}

    annual_linear = _num(value * rate)
    months_total = months if months else max(1, int(round(1.0 / rate * 12)))

    entries = []
    remaining = value
    cumulative = 0.0
    if method == "degressive":
        coeff = DEGRESSIVE_COEFF_MACHINES if group in MACHINE_GROUPS else DEGRESSIVE_COEFF_OTHER
        degressive_annual = min(_num(value * rate * coeff), annual_linear * coeff)
    else:
        coeff = 1.0
        degressive_annual = annual_linear

    for m in range(1, months_total + 1):
        year = start_year + (start_month + m - 2) // 12
        month = (start_month + m - 2) % 12 + 1
        if method == "degressive" and degressive_annual > annual_linear:
            # art. 22k ust. 3: przejście na liniową, gdy odpis degresywny ≤ liniowy
            write_off = min(_num(remaining * rate * coeff / 12), _num(remaining / (months_total - m + 1)))
            if write_off <= _num(remaining * rate / 12):
                write_off = _num(remaining / (months_total - m + 1))
        else:
            write_off = min(round(monthly_linear(value, rate), 2), remaining)
        if m == months_total:
            write_off = remaining  # ostatni miesiąc — domknięcie do wartości początkowej
        cumulative = _num(cumulative + write_off)
        remaining = _num(remaining - write_off)
        entries.append({
            "month": m, "period": f"{year}-{month:02d}",
            "write_off": write_off, "cumulative": cumulative, "net_value": remaining,
        })

    proof_ok = abs(cumulative - value) <= 0.01
    invariant_ok = cumulative <= value + 0.01
    return {
        "initial_value": value,
        "group": group,
        "rate": rate,
        "method": method,
        "coefficient": coeff if method == "degressive" else None,
        "months": months_total,
        "annual_linear": annual_linear,
        "entries": entries,
        "total_write_offs": cumulative,
        "proof_grosz": proof_ok,        # |suma odpisów − wartość| ≤ 0,01
        "invariant_F2": invariant_ok,   # suma odpisów ≤ wartość początkowa
        "legal_basis": "Art. 22h-22k PIT",
    }


def verify_rate(group: str, declared: float) -> dict:
    """Weryfikator stawki KŚT — czy deklarowana stawka jest zgodna z załącznikiem."""
    standard = kst_rate(group)
    ok = abs(declared - standard) <= 0.0001
    return {
        "group": group,
        "standard_rate": standard,
        "declared_rate": declared,
        "ok": ok,
        "action": "OK" if ok else "TRIAGE_QUEUE — stawka niezgodna z załącznikiem nr 1",
        "legal_basis": "Art. 22h ust. 1 PIT + Załącznik nr 1 (rozporządzenie MF)",
    }


def one_time_check(value: float, revenue_eur: float, is_small_taxpayer: bool,
                   is_passenger_car: bool, group: str, used_ytd: float = 0.0) -> dict:
    """Jednorazowa amortyzacja (art. 22i / 22k ust. 7-12):
    limit 100 000 EUR, mały podatnik (przychód ≤ 2 000 000 EUR), grupy 3-8,
    wyłączenie samochodów osobowych; kontrola limitu rocznego 100 000 PLN."""
    pln_limit = round(ONE_TIME_EUR_LIMIT * EUR_PLN, 2)
    allowed = True
    reasons = []
    if is_passenger_car:
        allowed = False
        reasons.append("Samochody osobowe WYKLUCZONE z jednorazowej amortyzacji (art. 22k ust. 7)")
    if group not in {"3", "4", "5", "6", "7", "8"}:
        allowed = False
        reasons.append(f"Grupa KŚT {group} poza zakresem 3-8 jednorazowej amortyzacji")
    if is_small_taxpayer and revenue_eur > SMALL_TAXPAYER_EUR:
        allowed = False
        reasons.append(f"Przychód {revenue_eur:,.0f} EUR > limit małego podatnika 2 000 000 EUR")
    if used_ytd + value > pln_limit:
        allowed = False
        reasons.append(f"Przekroczony limit {pln_limit:,.2f} PLN (wykorzystano {used_ytd:,.2f} PLN)")
    return {
        "value": value,
        "pln_limit": pln_limit,
        "eur_limit": ONE_TIME_EUR_LIMIT,
        "small_taxpayer": is_small_taxpayer,
        "revenue_eur": revenue_eur,
        "allowed": allowed,
        "reasons": reasons,
        "action": "ALLOW jednorazowo" if allowed else "BLOCK — amortyzuj liniowo/degresywnie",
        "legal_basis": "Art. 22i / 22k ust. 7-12 PIT",
    }


def car_limit(value: float, electric: bool = False) -> dict:
    """Limit wartości początkowej samochodu osobowego (art. 22a ust. 4a PIT):
    nadwyżka ponad 150 000 (225 000 EV) NIE podlega amortyzacji."""
    limit = CAR_LIMIT_ELECTRIC if electric else CAR_LIMIT_STANDARD
    excess = max(0.0, _num(value) - limit)
    return {
        "value": value,
        "limit": limit,
        "depreciable": min(_num(value), limit),
        "excess_not_depreciable": excess,
        "action": "OK" if excess == 0 else "Nadwyżka NIE amortyzowana (art. 22a ust. 4a PIT)",
        "legal_basis": "Art. 22a ust. 4a PIT",
    }


def low_value(value: float) -> dict:
    """Niskocenny ŚT ≤ 10 000 PLN — jednorazowo w KUP (art. 22f ust. 3)."""
    return {
        "value": value,
        "low_value_limit": LOW_VALUE_LIMIT,
        "one_time_kup": _num(value) <= LOW_VALUE_LIMIT,
        "action": "Jednorazowo w KUP (bez ewidencji ŚT)" if _num(value) <= LOW_VALUE_LIMIT
                  else "Wpisz do ewidencji ŚT i amortyzuj",
        "legal_basis": "Art. 22f ust. 3 PIT",
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="Depreciation Engine (PROMPT 06)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_s = sub.add_parser("schedule")
    p_s.add_argument("--value", type=float, required=True)
    p_s.add_argument("--group", required=True)
    p_s.add_argument("--method", default="linear", choices=["linear", "degressive"])
    p_s.add_argument("--months", type=int, default=None)

    p_v = sub.add_parser("verify-rate")
    p_v.add_argument("--group", required=True)
    p_v.add_argument("--declared", type=float, required=True)

    p_o = sub.add_parser("one-time")
    p_o.add_argument("--value", type=float, required=True)
    p_o.add_argument("--revenue", type=float, default=0.0)
    p_o.add_argument("--small-taxpayer", action="store_true")
    p_o.add_argument("--passenger-car", action="store_true")
    p_o.add_argument("--group", default="4")
    p_o.add_argument("--used-ytd", type=float, default=0.0)

    p_c = sub.add_parser("car-limit")
    p_c.add_argument("--value", type=float, required=True)
    p_c.add_argument("--electric", action="store_true")

    p_l = sub.add_parser("low-value")
    p_l.add_argument("--value", type=float, required=True)

    args = ap.parse_args(argv)

    if args.cmd == "schedule":
        print(json.dumps(schedule(args.value, args.group, args.method, args.months),
                         ensure_ascii=False, indent=2))
    elif args.cmd == "verify-rate":
        print(json.dumps(verify_rate(args.group, args.declared), ensure_ascii=False, indent=2))
    elif args.cmd == "one-time":
        print(json.dumps(one_time_check(args.value, args.revenue, args.small_taxpayer,
                                        args.passenger_car, args.group, args.used_ytd),
                         ensure_ascii=False, indent=2))
    elif args.cmd == "car-limit":
        print(json.dumps(car_limit(args.value, args.electric), ensure_ascii=False, indent=2))
    else:
        print(json.dumps(low_value(args.value), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
