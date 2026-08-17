#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — EWC CLASSIFIER (GLM52 P15)
# Klasyfikator odpadów wg kodu EWC (rodzaj odpadu → kod) — zgodny z katalogiem
# odpadów (rozporządzenie MŚ, Dz.U. 2020 poz. 10) i ustawą o odpadach
# (Dz.U. 2025 poz. 321).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

LEGAL_BDO = ("ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)")

EWC_CODES = {
    "paper": {"code": "20 01 01", "name": "Papier i tektura", "hazardous": False},
    "plastic": {"code": "20 01 39", "name": "Tworzywa sztuczne", "hazardous": False},
    "metal": {"code": "20 01 40", "name": "Metale", "hazardous": False},
    "glass": {"code": "20 01 02", "name": "Szkło", "hazardous": False},
    "organic": {"code": "20 01 08", "name": "Odpady biodegradowalne", "hazardous": False},
    "electronic": {"code": "20 01 36", "name": "Zużyte urządzenia elektryczne", "hazardous": False},
    "batteries": {"code": "20 01 34", "name": "Baterie i akumulatory", "hazardous": False},
    "hazardous": {"code": "20 01 27*", "name": "Odpady niebezpieczne", "hazardous": True},
    "mixed": {"code": "20 03 01", "name": "Odpady zmieszane", "hazardous": False},
}


def classify_waste(waste_type: str) -> dict:
    """Klasyfikacja rodzaju odpadu → kod EWC."""
    entry = EWC_CODES.get(waste_type)
    if not entry:
        return {
            "waste_type": waste_type,
            "code": "",
            "name": "",
            "hazardous": False,
            "note": "Nieznany rodzaj odpadu — brak kodu EWC",
            "legal_basis": LEGAL_BDO,
        }
    return {
        "waste_type": waste_type,
        **entry,
        "legal_basis": LEGAL_BDO,
    }


def is_hazardous(waste_type: str) -> bool:
    return classify_waste(waste_type)["hazardous"]


if __name__ == "__main__":
    import json

    for wt in ["paper", "hazardous", "unknown"]:
        print(json.dumps(classify_waste(wt), ensure_ascii=False, indent=1))
