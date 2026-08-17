#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — DN-1 / DT-1 GENERATOR (GLM52 P14)
# Auto-generator deklaracji DN-1 (podatek od nieruchomości, 14 dni od nabycia)
# i DT-1 (podatek od środków transportowych, do 15.02). Ustawa z 12.01.1991
# o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from gmina_rates_engine import (DN1_DEADLINE_DAYS, DN1_SCHEDULE, DT1_DEADLINE,
                                get_gmina_rates, transport_tax)

LEGAL_LOCAL = ("ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach "
               "lokalnych (Dz.U. 2025 poz. 1234)")


def generate_dn1(gmina: str, property_type: str, area_m2: float,
                 year: int = 2026) -> dict:
    """Generator deklaracji DN-1 (podatek od nieruchomości)."""
    info = get_gmina_rates(gmina, year)
    rates = info["rates"]
    rate = rates.get(property_type, 0.0)
    annual = round(area_m2 * rate, 2)
    return {
        "form": "DN-1",
        "gmina": gmina,
        "property_type": property_type,
        "area_m2": area_m2,
        "rate_pln_m2": rate,
        "annual_tax": annual,
        "quarterly_installment": round(annual / 4, 2),
        "deadline_days": DN1_DEADLINE_DAYS,
        "payment_schedule": DN1_SCHEDULE,
        "auto_filled": True,
        "legal_basis": f"Art. 6 {LEGAL_LOCAL}",
    }


def generate_dt1(gvw_t: float, axles: int = 2) -> dict:
    """Generator deklaracji DT-1 (podatek od środków transportowych)."""
    t = transport_tax(gvw_t)
    return {
        "form": "DT-1",
        "gvw_t": gvw_t,
        "axles": axles,
        "taxable": t["taxable"],
        "threshold_t": t["threshold_t"],
        "deadline": DT1_DEADLINE,
        "auto_filled": True,
        "legal_basis": f"Art. 8-14 {LEGAL_LOCAL}",
    }


if __name__ == "__main__":
    import json
    import sys

    print(json.dumps(generate_dn1("Warszawa", "building_business", 200),
                     ensure_ascii=False, indent=1))
    print(json.dumps(generate_dt1(4.5), ensure_ascii=False, indent=1))
