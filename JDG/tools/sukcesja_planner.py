#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — SUKCESJA PLANNER (GLM52 P13)
# Kreator planu sukcesji (art. 3-15 u.z.s. — Dz.U. 2025 poz. 1234):
# powołanie zarządcy (wpis CEIDG 14 dni), okres 2 lat (art. 12) + do 3 lat
# przedłużenia (art. 13), wygaśnięcie (art. 14-15), NIP/rachunek (art. 18-20),
# odpowiedzialność (art. 21-23), tracker z countdownem.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations
from datetime import date, timedelta

APPOINTMENT_CEIDG_DAYS = 14          # art. 3-4: wpis zarządcy do CEIDG
DEFAULT_MONTHS = 24                  # art. 12: 2 lata
EXTENDED_MONTHS = 60                 # art. 13: do 5 lat z zgodą sądu
DEATH_NOTICE_ZUS_DAYS = 30           # art. 12 ust. 1: zgłoszenie do ZUS
REMNANT_DEADLINE_DAYS = 30           # remanent sukcesyjny


def plan(death_date: date, successor_name: str,
         court_approved_extension: bool = False) -> dict:
    """Plan sukcesji: harmonogram od daty śmierci przedsiębiorcy."""
    appointment_deadline = death_date + timedelta(days=APPOINTMENT_CEIDG_DAYS)
    zus_notice_deadline = death_date + timedelta(days=DEATH_NOTICE_ZUS_DAYS)
    base_end = death_date + timedelta(days=30 * DEFAULT_MONTHS)
    ext_end = death_date + timedelta(days=30 * EXTENDED_MONTHS)
    effective_end = ext_end if court_approved_extension else base_end
    remnant_deadline = death_date + timedelta(days=REMNANT_DEADLINE_DAYS)

    today = date.today()
    remaining_days = (effective_end - today).days
    status = "ACTIVE" if remaining_days > 0 else "EXPIRED"

    return {
        "successor": successor_name,
        "death_date": death_date.isoformat(),
        "appointment_ceidg_deadline": appointment_deadline.isoformat(),
        "zus_notice_deadline": zus_notice_deadline.isoformat(),
        "base_term_end": base_end.isoformat(),
        "extended_term_end": ext_end.isoformat(),
        "effective_end": effective_end.isoformat(),
        "court_approved_extension": court_approved_extension,
        "remaining_days": max(remaining_days, 0),
        "status": status,
        "remnant_deadline": remnant_deadline.isoformat(),
        "warnings": [
            "Brak wpisu zarządcy w CEIDG w 14 dni — wygaśnięcie uprawnień (art. 3-4 u.z.s.)"
        ] if (appointment_deadline < today) else [],
        "checklist": [
            "Wniosek o wpis zarządcy sukcesyjnego do CEIDG (14 dni)",
            "Zgłoszenie do ZUS z tytułu śmierci przedsiębiorcy (30 dni)",
            "Ustanowienie pełnomocnictw do rachunku firmowego (art. 22 u.z.s.)",
            "Sporządzenie remanentu sukcesyjnego (30 dni)",
            "Decyzja o przedłużeniu zarządu (do 3 lat, art. 13 u.z.s.)",
        ],
        "legal_basis": "art. 3-15 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym "
                       "przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    }


def liability_calculator(assets_pln: float, liabilities_pln: float,
                         management_fee_pln: float = 0.0) -> dict:
    """Kalkulator odpowiedzialności zarządcy (art. 21-23 u.z.s.)."""
    net = assets_pln - liabilities_pln
    return {
        "assets_pln": assets_pln,
        "liabilities_pln": liabilities_pln,
        "net_estate_pln": net,
        "management_fee_pln": management_fee_pln,
        "successor_liability_note": (
            "Zarządca odpowiada za zobowiązania tylko do wysokości aktywów "
            "przedsiębiorstwa w zarządzie (art. 21-23 u.z.s.)"
        ),
        "legal_basis": "art. 21-23 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym "
                       "przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    }


def countdown(plan_result: dict) -> dict:
    """Countdown tracker dla planu sukcesji."""
    return {
        "status": plan_result["status"],
        "remaining_days": plan_result["remaining_days"],
        "deadline": plan_result["effective_end"],
        "alert": plan_result["remaining_days"] <= 90 and plan_result["status"] == "ACTIVE",
    }


if __name__ == "__main__":
    import json
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--liability":
        print(json.dumps(liability_calculator(500_000, 200_000), ensure_ascii=False, indent=1))
    else:
        d = date(2026, 8, 1)
        p = plan(d, "Jan Kowalski", court_approved_extension=True)
        print(json.dumps(p, ensure_ascii=False, indent=1))
        print(json.dumps(countdown(p), ensure_ascii=False, indent=1))
