#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — DEADLINE ENGINE (GLM52 P16)
# Silnik kalendarza terminów podatkowych: przesunięcia weekendowe/świąteczne
# (art. 12 § 5 Ordynacji podatkowej), countdowny per obowiązek, alerty 3-warstwowe
# (7/3/1 dzień), odsetki za zwłokę (art. 56 OP). Ustawa z dnia 29 sierpnia 1997 r.
# — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from datetime import date, timedelta

LEGAL_OP = "Art. 12 § 5 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)"
LEGAL_INTEREST = "Art. 56 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)"

# Alerty 3-warstwowe (dni przed terminem)
ALERT_DAYS = (7, 3, 1)

# Święta państwowe i wolne od pracy (PL) — dni, które przesuwają termin
PUBLIC_HOLIDAYS = {
    (1, 1),    # Nowy Rok
    (1, 6),    # Święto Trzech Króli
    (5, 1),    # Święto Pracy
    (5, 3),    # Święto Konstytucji 3 Maja
    (8, 15),   # Wniebowzięcie NMP
    (11, 1),   # Wszystkich Świętych
    (11, 11),  # Narodowe Święto Niepodległości
    (12, 25),  # Boże Narodzenie
    (12, 26),  # Boże Narodzenie (2 dzień)
}

# Wielkanoc — wyliczana algorytmicznie (Meeus/Jones/Butcher)
def _easter(year: int) -> date:
    a = year % 19
    b, c = year // 100, year % 100
    d = (b - 8) // 25 + 1
    e = (19 * a + b - (b // 4) - d) % 30
    f = (a + 11 * e) // 319
    g = (c - (c // 4) + 2 * (26 * (e - f) + 10) // 11) % 7
    h = e - f + (2 * (b // 4) - 5 * b + 2 * (c // 4) + 8 * g) // 4
    month = 3 + (h + 40) // 44
    day = h + 28 - 31 * (month // 4)
    return date(year, month, day)


def _movable_holidays(year: int) -> set[tuple[int, int]]:
    easter = _easter(year)
    out = {(easter.month, easter.day)}
    for delta in (1, 49, 60):  # Poniedziałek Wielkanocny, Boże Ciało (60 dni po), Zielone Świątki
        d = easter + timedelta(days=delta)
        out.add((d.month, d.day))
    return out


def is_holiday(d: date) -> bool:
    key = (d.month, d.day)
    if key in PUBLIC_HOLIDAYS or key in _movable_holidays(d.year):
        return True
    return False


def is_working_day(d: date) -> bool:
    return d.weekday() < 5 and not is_holiday(d)


def next_working_day(d: date) -> date:
    """Przesunięcie terminu na najbliższy dzień roboczy (art. 12 § 5 OP)."""
    while not is_working_day(d):
        d += timedelta(days=1)
    return d


def shifted_deadline(base: date) -> dict:
    """Termin z przesunięciem — dowód przesunięcia (art. 12 § 5 OP)."""
    shifted = next_working_day(base)
    return {
        "base_date": base.isoformat(),
        "shifted_date": shifted.isoformat(),
        "shifted": shifted != base,
        "reason": "termin przypadł na dzień wolny — przesunięty na najbliższy dzień roboczy"
                  if shifted != base else "termin w dniu roboczym — bez przesunięcia",
        "legal_basis": LEGAL_OP,
    }


# ── Katalog obowiązków (dzień miesiąca / offset / roczny) ─────────────────────
OBLIGATIONS = {
    "vat_jpk_v7":      {"type": "monthly",  "day": 25,  "name": "JPK_V7 / deklaracja VAT (25.)"},
    "pit_advance":     {"type": "monthly",  "day": 20,  "name": "Zaliczka PIT (20.)"},
    "zus_social":      {"type": "monthly",  "day": 10,  "name": "Składki ZUS społeczne (10.)"},
    "zus_health":      {"type": "monthly",  "day": 20,  "name": "Składka zdrowotna (20.)"},
    "pit_annual":      {"type": "yearly",   "month": 4, "day": 30, "name": "PIT-36/37 roczne (30.04)"},
    "pcc3":            {"type": "offset",   "days": 14, "name": "PCC-3 (14 dni od czynności)"},
    "mdr":             {"type": "offset",   "days": 30, "name": "MDR-3 (30 dni od schematu)"},
    "str_gijf":        {"type": "offset",   "days": 2,  "name": "STR/GIIF (48 h od podejrzenia)"},
    "bdo_quarterly":   {"type": "quarterly", "name": "Ewidencja/sprawozdanie BDO (kwartał)"},
}


def due_date_for(obligation: str, reference: date) -> date | None:
    spec = OBLIGATIONS.get(obligation)
    if not spec:
        return None
    t = spec["type"]
    if t == "monthly":
        base = date(reference.year, reference.month, spec["day"])
    elif t == "yearly":
        base = date(reference.year, spec["month"], spec["day"])
    elif t == "offset":
        base = reference + timedelta(days=spec["days"])
    else:  # quarterly — koniec kwartału
        qm = ((reference.month - 1) // 3) * 3 + 3
        base = date(reference.year, qm, 30 if qm in (3, 6, 9) else 31)
    return next_working_day(base)


def countdown(obligation: str, today: date | None = None, reference: date | None = None) -> dict:
    """Monitor terminu: countdown + alert 7/3/1 + przesunięcie art. 12 § 5 OP."""
    today = today or date.today()
    ref = reference or today
    due = due_date_for(obligation, ref)
    if not due:
        return {"obligation": obligation, "error": "nieznany obowiązek"}
    remaining = (due - today).days
    alert = None
    if remaining <= ALERT_DAYS[2]:
        alert = "RED"
    elif remaining <= ALERT_DAYS[1]:
        alert = "AMBER"
    elif remaining <= ALERT_DAYS[0]:
        alert = "YELLOW"
    return {
        "obligation": obligation,
        "name": OBLIGATIONS[obligation]["name"],
        "due_date": due.isoformat(),
        "days_remaining": max(remaining, 0),
        "alert_level": alert,
        "overdue": remaining < 0,
        "legal_basis": LEGAL_OP,
    }


# ── Odsetki za zwłokę (art. 56 OP) ────────────────────────────────────────────
def late_interest(principal_pln: float, days_late: int,
                  base_rate_pct: float = 9.75) -> dict:
    """Odsetki za zwłokę: stawka = 200% podstawowej stopy oprocentowania kredytu lombardowego NBP."""
    annual = base_rate_pct / 100
    interest = round(principal_pln * annual * days_late / 365, 2)
    return {
        "principal_pln": principal_pln,
        "days_late": days_late,
        "rate_annual_pct": base_rate_pct,
        "interest_pln": interest,
        "legal_basis": LEGAL_INTEREST,
    }


if __name__ == "__main__":
    import json

    today = date.today()
    demo = date(2026, 4, 25)  # sobota → przesunięcie na 27.04 (poniedziałek)
    print(json.dumps(shifted_deadline(demo), ensure_ascii=False, indent=1))
    for obl in ["vat_jpk_v7", "pit_annual", "pcc3"]:
        print(json.dumps(countdown(obl, today), ensure_ascii=False, indent=1))
    print(json.dumps(late_interest(10_000, 30), ensure_ascii=False, indent=1))
