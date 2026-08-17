#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — AKCYZA CLASSIFIER (GLM52 P14)
# Klasyfikator wyrobu akcyzowego → stawka akcyzy (paliwa/alkohol/tytoń/energia)
# + obowiązek składu podatkowego (art. 16) + znaki akcyzy (art. 114) + e-DD
# (art. 100). Ustawa z 6.12.2008 o podatku akcyzowym (Dz.U. 2025 poz. 1220).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

LEGAL_AKCYZA = ("ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym "
                "(Dz.U. 2025 poz. 1220)")

# Stawki 2026
FUEL = {                 # PLN / 1000 l (art. 89)
    "gasoline": 1566.0,
    "diesel": 1206.0,
    "lpg": 695.0,
    "cng": 449.0,
}

ALCOHOL = {              # PLN / hl (art. 93-96)
    "ethanol": 6900.0,   # za hl 100% obj.
    "wine": 185.0,
    "beer": 8.57,        # za hl za °Plato
    "cider": 108.0,
}

TOBACCO = {              # art. 99
    "cigarettes_ad_valorem_pct": 32.0,
    "cigarettes_specific_per_1000": 105.0,
    "cigars_per_1000": 595.0,
    "smoking_tobacco_per_kg": 300.0,
}

ENERGY = {               # art. 9 ust. 1 pkt 2
    "electricity_per_mwh": 5.00,
}

WAREHOUSE_REQUIRED = {"ethanol", "gasoline", "diesel", "cigarettes"}


def classify(product: str) -> dict:
    """Klasyfikacja wyrobu → stawka akcyzy + obowiązki."""
    p = product.lower()
    if p in FUEL:
        return {
            "product": product, "category": "fuel",
            "rate": FUEL[p], "unit": "PLN/1000 l",
            "warehouse_required": p in WAREHOUSE_REQUIRED,
            "legal_basis": f"Art. 89 {LEGAL_AKCYZA}",
        }
    if p in ALCOHOL:
        return {
            "product": product, "category": "alcohol",
            "rate": ALCOHOL[p], "unit": "PLN/hl",
            "warehouse_required": p in WAREHOUSE_REQUIRED,
            "legal_basis": f"Art. 93-96 {LEGAL_AKCYZA}",
        }
    if p == "cigarettes":
        return {
            "product": product, "category": "tobacco",
            "rate": TOBACCO["cigarettes_ad_valorem_pct"], "unit": "% ad valorem",
            "specific_per_1000": TOBACCO["cigarettes_specific_per_1000"],
            "warehouse_required": True,
            "legal_basis": f"Art. 99 {LEGAL_AKCYZA}",
        }
    if p == "electricity":
        return {
            "product": product, "category": "energy",
            "rate": ENERGY["electricity_per_mwh"], "unit": "PLN/MWh",
            "warehouse_required": False,
            "legal_basis": f"Art. 9 ust. 1 pkt 2 {LEGAL_AKCYZA}",
        }
    return {
        "product": product, "category": "non_excise", "rate": 0.0, "unit": "",
        "warehouse_required": False,
        "legal_basis": f"Art. 2 {LEGAL_AKCYZA}",
        "note": "Wyrób nie jest wyrobem akcyzowym (lub poza listą)",
    }


def excise_due(product: str, volume: float) -> dict:
    """Kalkulator akcyzy z dowodem (stawka × ilość)."""
    c = classify(product)
    due = round(volume * c["rate"] / (1000 if c["unit"] == "PLN/1000 l" else 1), 2) \
        if c["rate"] else 0.0
    return {
        "product": product,
        "volume": volume,
        "rate": c["rate"],
        "unit": c["unit"],
        "excise_due": due,
        "warehouse_required": c["warehouse_required"],
        "edd_required": c["category"] in ("fuel", "alcohol", "tobacco"),
        "legal_basis": c["legal_basis"],
    }


if __name__ == "__main__":
    import json
    import sys

    product = sys.argv[1] if len(sys.argv) > 1 else "gasoline"
    vol = float(sys.argv[2]) if len(sys.argv) > 2 else 1000
    print(json.dumps(classify(product), ensure_ascii=False, indent=1))
    print(json.dumps(excise_due(product, vol), ensure_ascii=False, indent=1))
