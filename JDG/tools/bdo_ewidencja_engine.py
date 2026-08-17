#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — BDO EWIDENCJA ENGINE (GLM52 P15)
# Generator rejestracji BDO (art. 17-18) + ewidencja odpadów (art. 49-55, karty
# KPO — zero ręki) + monitor kwartalny + kara art. 194 (5000 zł). Ustawa
# o odpadach (Dz.U. 2025 poz. 321).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from ewc_classifier import classify_waste

LEGAL_BDO = ("ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)")
REGISTRATION_FEE_PLN = 100    # art. 17-18 — opłata 100-500 zł
FINE_ART194_PLN = 5000        # art. 194 — kara 5000 zł


def registration(producer: str, waste_types: list[str]) -> dict:
    """Generator rejestracji w BDO (art. 17-18)."""
    return {
        "form": "BDO — wniosek rejestracyjny",
        "producer": producer,
        "waste_types": waste_types,
        "ewc_codes": {wt: classify_waste(wt)["code"] for wt in waste_types},
        "registration_fee_pln": REGISTRATION_FEE_PLN,
        "legal_basis": f"Art. 17-18 {LEGAL_BDO}",
    }


def waste_record(waste_type: str, mass_kg: float, quarter: str) -> dict:
    """Karta ewidencji odpadu / KPO (art. 49-55)."""
    ewc = classify_waste(waste_type)
    return {
        "form": "KPO (karta przekazania odpadu)",
        "waste_type": waste_type,
        "ewc_code": ewc["code"],
        "mass_kg": mass_kg,
        "quarter": quarter,
        "hazardous": ewc["hazardous"],
        "auto_filled": True,
        "legal_basis": f"Art. 49-55 {LEGAL_BDO}",
    }


def quarterly_monitor(records: list[dict]) -> dict:
    """Monitor kwartalny ewidencji BDO."""
    return {
        "records_count": len(records),
        "total_mass_kg": round(sum(r["mass_kg"] for r in records), 2),
        "filing_required": len(records) > 0,
        "fine_risk_pln": FINE_ART194_PLN if len(records) == 0 else 0,
        "legal_basis": f"Art. 49-55, 194 {LEGAL_BDO}",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(registration("Firma X", ["paper", "plastic"]),
                     ensure_ascii=False, indent=1))
    print(json.dumps(waste_record("paper", 100.5, "Q3-2026"),
                     ensure_ascii=False, indent=1))
    print(json.dumps(quarterly_monitor([waste_record("paper", 100.5, "Q3-2026")]),
                     ensure_ascii=False, indent=1))
