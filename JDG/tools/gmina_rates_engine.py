#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — GMINA RATES ENGINE (GLM52 P14)
# Silnik stawek gminnych: podatek od nieruchomości + środki transportowe +
# opłata targowa/uzdrowiskowa — per gmina z wersjonowaniem (temporalność,
# Law Radar F5). Ustawa z 12.01.1991 o podatkach i opłatach lokalnych
# (Dz.U. 2025 poz. 1234).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

LEGAL_LOCAL = ("ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach "
               "lokalnych (Dz.U. 2025 poz. 1234)")

# Stawki maksymalne 2026 (obwieszczenie MF) — gmina może uchwalić niższe.
MAX_RATES_2026 = {
    "land_business": 1.43,        # PLN/m² grunt związany z działalnością
    "land_other": 0.71,           # PLN/m² grunt pozostały
    "building_business": 33.10,   # PLN/m² budynek związany z działalnością
    "building_residential": 1.15, # PLN/m² budynek mieszkalny
    "construction_pct": 2.0,      # % wartości budowli
}

MAX_RATES_2025 = {
    "land_business": 1.34,
    "land_other": 0.66,
    "building_business": 31.00,
    "building_residential": 1.07,
    "construction_pct": 2.0,
}

# Uchwały rad gmin (współczynnik stawki maksymalnej — przykładowe gminy)
GMINA_FACTORS = {
    "Warszawa": 1.00,
    "Kraków": 1.00,
    "Gdańsk": 0.95,
    "Poznań": 0.98,
    "Wrocław": 0.97,
    "domyślna": 1.00,
}

TRANSPORT_HEAVY_THRESHOLD_T = 3.5  # art. 8 — pojazdy powyżej 3,5 t
DN1_DEADLINE_DAYS = 14              # art. 6 ust. 9 — DN-1 w 14 dni
DN1_SCHEDULE = ["15.03", "15.05", "15.09", "15.11"]
DT1_DEADLINE = "15.02"


def gmina_factor(gmina: str) -> float:
    return GMINA_FACTORS.get(gmina, GMINA_FACTORS.get("domyślna", 1.00))


def get_gmina_rates(gmina: str = "Warszawa", year: int = 2026) -> dict:
    """Stawki gminne dla gminy i roku (z wersjonowaniem temporalnym)."""
    base = MAX_RATES_2026 if year >= 2026 else MAX_RATES_2025
    prev = MAX_RATES_2025 if year >= 2026 else MAX_RATES_2025
    f = gmina_factor(gmina)
    rates = {k: round(v * f, 2) for k, v in base.items()}
    return {
        "gmina": gmina,
        "year": year,
        "rates": rates,
        "factor": f,
        "previous_year_rates": prev,
        "rates_changed_ytd": base != prev,
        "building_rate_delta_pct": round(
            (base["building_business"] - prev["building_business"])
            / prev["building_business"] * 100, 2),
        "versioning": "Stawki gminne wersjonowane — uchwała rady gminy + data "
                      "obowiązywania (Law Radar F5)",
        "legal_basis": f"Art. 5-7 {LEGAL_LOCAL}",
    }


def real_estate_tax(property_type: str, area_m2: float,
                    gmina: str = "Warszawa", year: int = 2026) -> dict:
    """Kalkulator podatku od nieruchomości (DN-1)."""
    info = get_gmina_rates(gmina, year)
    rates = info["rates"]
    rate = 0.0
    if property_type == "land_business":
        rate = rates["land_business"]
    elif property_type == "land_other":
        rate = rates["land_other"]
    elif property_type == "building_business":
        rate = rates["building_business"]
    elif property_type == "building_residential":
        rate = rates["building_residential"]
    return {
        "gmina": gmina,
        "property_type": property_type,
        "area_m2": area_m2,
        "rate_pln_m2": rate,
        "annual_tax": round(area_m2 * rate, 2),
        "dn1_deadline_days": DN1_DEADLINE_DAYS,
        "payment_schedule": DN1_SCHEDULE,
        "form": "DN-1",
        "legal_basis": f"Art. 5-6 {LEGAL_LOCAL}",
    }


def transport_tax(gvw_t: float) -> dict:
    """Kalkulator podatku od środków transportowych (DT-1)."""
    taxable = gvw_t > TRANSPORT_HEAVY_THRESHOLD_T
    return {
        "gvw_t": gvw_t,
        "threshold_t": TRANSPORT_HEAVY_THRESHOLD_T,
        "taxable": taxable,
        "form": "DT-1",
        "deadline": DT1_DEADLINE,
        "legal_basis": f"Art. 8-14 {LEGAL_LOCAL}",
    }


if __name__ == "__main__":
    import json
    import sys

    gmina = sys.argv[1] if len(sys.argv) > 1 else "Warszawa"
    print(json.dumps(get_gmina_rates(gmina), ensure_ascii=False, indent=1))
    print(json.dumps(real_estate_tax("building_business", 200, gmina),
                     ensure_ascii=False, indent=1))
    print(json.dumps(transport_tax(4.5), ensure_ascii=False, indent=1))
