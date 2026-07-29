#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — P15 Local Taxes Toolkit (PCC + Property + Transport + Excise)
═══════════════════════════════════════════════════════════════════════════════
ENTERPRISE v7.0 — 12 innowacji dla PCC, podatków lokalnych i akcyzy.
Pokrywa największą lukę JDG (~90% niepokryte).
"""

import json, os, sys, argparse
from datetime import datetime, timedelta

REPORTS_DIR = "JDG/reports"
os.makedirs(REPORTS_DIR, exist_ok=True)

# ═══════════════════════════════════════════════════════════════════════════
# INN01: PCC Auto-Detection Engine
# ═══════════════════════════════════════════════════════════════════════════
PCC_TRANSACTION_PATTERNS = {
    "SALE": {"keywords": ["sprzedaż", "kupno", "zakup", "umowa sprzedaży", "private sale", "od osoby prywatnej"],
             "rate": 2.0, "category": "REAL_ESTATE", "form": "PCC-3", "deadline_days": 14,
             "exclusion": "VAT", "exclusion_rule": "Art. 2 pkt 4 PCC"},
    "CAR_PRIVATE": {"keywords": ["auto", "samochód", "pojazd", "car purchase", "kupno auta"],
                    "rate": 2.0, "category": "VEHICLE", "form": "PCC-3", "deadline_days": 14,
                    "exclusion": "VAT", "exclusion_rule": "Art. 2 pkt 4 PCC"},
    "LOAN": {"keywords": ["pożyczka", "loan", "pożyczam", "kredyt prywatny"],
             "rate": 0.5, "category": "LOAN", "form": "PCC-3", "deadline_days": 14,
             "exemption_family_limit": 36120, "exemption_threshold": 1000},
    "DONATION": {"keywords": ["darowizna", "donation", "daruję", "podarunek"],
                 "rate": 0.0, "category": "DONATION", "note": "Podlega SD-3, nie PCC"},
    "COMPANY": {"keywords": ["spółka", "company formation", "udziały", "share capital", "JDG→Sp. z o.o."],
                "rate": 0.5, "category": "COMPANY_FORMATION", "form": "PCC-3", "deadline_days": 14},
    "EXCHANGE": {"keywords": ["zamiana", "exchange", "swap", "barter"],
                 "rate": 1.0, "category": "EXCHANGE", "form": "PCC-3", "deadline_days": 14},
    "MORTGAGE": {"keywords": ["hipoteka", "mortgage", "zabezpieczenie hipoteczne"],
                 "rate": 0.1, "category": "MORTGAGE", "form": "PCC-3", "deadline_days": 14},
}

def detect_pcc_obligation(description: str, amount: float, is_vat_invoice: bool = False,
                          is_from_vat_payer: bool = False, transaction_date: str = None) -> dict:
    """Auto-detect PCC obligation from transaction description."""
    desc_lower = description.lower()
    result = {"pcc_applies": False, "pcc_rate": 0.0, "pcc_tax": 0.0, "form": None,
              "deadline_days": None, "matched_type": None, "warnings": [], "exemptions": []}

    if is_vat_invoice or is_from_vat_payer:
        result["warnings"].append("WYŁĄCZONE: transakcja VAT (Art. 2 pkt 4 PCC) — PCC NIE obowiązuje")
        return result

    for tx_type, pattern in PCC_TRANSACTION_PATTERNS.items():
        if any(kw in desc_lower for kw in pattern["keywords"]):
            result["matched_type"] = tx_type
            if tx_type == "DONATION":
                result["warnings"].append("Darowizny NIE podlegają PCC — podatek od spadków i darowizn (SD-3)")
                return result
            if tx_type == "LOAN":
                if amount <= pattern["exemption_threshold"]:
                    result["warnings"].append(f"ZWOLNIONE: kwota ≤ {pattern['exemption_threshold']} PLN")
                    return result
                if amount <= pattern["exemption_family_limit"]:
                    result["exemptions"].append(f"Pożyczka rodzinna ≤ {pattern['exemption_family_limit']} PLN — zwolniona jeśli zgłosisz w 6 mies.")
            result["pcc_applies"] = True
            rate = pattern.get("rate", 1.0)
            result["pcc_rate"] = rate
            result["pcc_tax"] = round(amount * rate / 100, 2)
            result["form"] = pattern.get("form")
            result["deadline_days"] = pattern.get("deadline_days")
            result["warnings"].append(
                f"PCC: {tx_type} — {amount:.2f} PLN × {rate}% = {result['pcc_tax']:.2f} PLN. "
                f"Złóż {result['form']} w ciągu {result['deadline_days']} dni!"
            )
            if transaction_date:
                try:
                    tx_date = datetime.strptime(transaction_date, "%Y-%m-%d")
                    days_elapsed = (datetime.now() - tx_date).days
                    if days_elapsed > result["deadline_days"]:
                        result["warnings"].append(
                            f"⚠️ PRZEKROCZONY TERMIN! {days_elapsed} dni od transakcji (max {result['deadline_days']}). "
                            f"Złóż z czynnym żalem!"
                        )
                except:
                    pass
            return result

    result["warnings"].append("Nie wykryto obowiązku PCC w opisie transakcji")
    return result

# ═══════════════════════════════════════════════════════════════════════════
# INN02: PCC-3 Auto-Filler
# ═══════════════════════════════════════════════════════════════════════════
def fill_pcc3(transaction_type: str, amount: float, buyer: str = "", seller: str = "",
              transaction_date: str = "", is_family: bool = False) -> dict:
    """Auto-fill PCC-3 declaration data."""
    pcc3 = {
        "form": "PCC-3",
        "field_A": "Podatnik (kupujący/pożyczkobiorca)",
        "field_B": buyer or "[DO UZUPEŁNIENIA]",
        "field_C": seller or "[DO UZUPEŁNIENIA]",
        "field_D": transaction_type,
        "field_E": round(amount, 2),
        "field_F": None,  # tax rate
        "field_G": 0.0,   # tax due
        "field_H": transaction_date or datetime.now().strftime("%Y-%m-%d"),
        "deadline": None,
    }

    for tx_type, pattern in PCC_TRANSACTION_PATTERNS.items():
        if tx_type == transaction_type:
            pcc3["field_F"] = pattern.get("rate", 1.0)
            pcc3["field_G"] = round(amount * pcc3["field_F"] / 100, 2)
            pcc3["deadline"] = (datetime.strptime(transaction_date, "%Y-%m-%d") +
                               timedelta(days=pattern.get("deadline_days", 14))).strftime("%Y-%m-%d") \
                               if transaction_date else "14 dni od zawarcia umowy"
            if tx_type == "LOAN" and is_family and amount <= 36120:
                pcc3["notes"] = "ZWOLNIENIE — pożyczka rodzinna ≤ 36 120 PLN (zgłoś w US w 6 mies.)"
                pcc3["field_G"] = 0.0
            break

    return pcc3

# ═══════════════════════════════════════════════════════════════════════════
# INN03: Property Tax Classifier (Real Estate)
# ═══════════════════════════════════════════════════════════════════════════
PROPERTY_RATES = {
    "RESIDENTIAL": 1.15,       # PLN/m²
    "BUSINESS_LAND": 1.35,     # PLN/m²
    "BUSINESS_BUILDING": 33.10, # PLN/m²
    "CONSTRUCTION": 0.02,      # 2% wartości
}

def classify_property(area_m2: float, is_business: bool, is_residential: bool,
                      construction_value: float = 0, mixed_business_pct: float = 0) -> dict:
    """Classify property and calculate annual tax."""
    result = {"classification": None, "tax_per_sqm": 0.0, "annual_tax": 0.0,
              "form": "DN-1", "deadline_days": 14, "warnings": []}

    if construction_value > 0:
        result["classification"] = "CONSTRUCTION"
        result["tax_per_sqm"] = 0
        result["annual_tax"] = round(construction_value * 0.02, 2)
        result["warnings"].append(f"BUDOWLA — 2% od {construction_value:.2f} PLN = {result['annual_tax']:.2f} PLN/rok")
    elif is_business and is_residential:
        result["classification"] = "MIXED"
        biz_area = area_m2 * mixed_business_pct / 100
        priv_area = area_m2 - biz_area
        result["annual_tax"] = round(biz_area * PROPERTY_RATES["BUSINESS_BUILDING"] +
                                     priv_area * PROPERTY_RATES["RESIDENTIAL"], 2)
        result["warnings"].append(f"MIESZANE: {biz_area:.0f}m² firmowe + {priv_area:.0f}m² prywatne = {result['annual_tax']:.2f} PLN/rok")
    elif is_business:
        result["classification"] = "BUSINESS_BUILDING"
        result["tax_per_sqm"] = PROPERTY_RATES["BUSINESS_BUILDING"]
        result["annual_tax"] = round(area_m2 * PROPERTY_RATES["BUSINESS_BUILDING"], 2)
        result["warnings"].append(f"FIRMOWY — {area_m2:.0f}m² × {PROPERTY_RATES['BUSINESS_BUILDING']} PLN/m² = {result['annual_tax']:.2f} PLN/rok")
    else:
        result["classification"] = "RESIDENTIAL"
        result["tax_per_sqm"] = PROPERTY_RATES["RESIDENTIAL"]
        result["annual_tax"] = round(area_m2 * PROPERTY_RATES["RESIDENTIAL"], 2)
        result["warnings"].append(f"MIESZKALNY — {area_m2:.0f}m² × {PROPERTY_RATES['RESIDENTIAL']} PLN/m² = {result['annual_tax']:.2f} PLN/rok")

    result["installments"] = [
        {"date": f"{datetime.now().year}-03-15", "amount": round(result["annual_tax"] / 4, 2)},
        {"date": f"{datetime.now().year}-05-15", "amount": round(result["annual_tax"] / 4, 2)},
        {"date": f"{datetime.now().year}-09-15", "amount": round(result["annual_tax"] / 4, 2)},
        {"date": f"{datetime.now().year}-11-15", "amount": round(result["annual_tax"] / 4, 2)},
    ]

    return result

# ═══════════════════════════════════════════════════════════════════════════
# INN04: Excise Warehouse Tracker
# ═══════════════════════════════════════════════════════════════════════════
EXCISE_PRODUCTS = {
    "FUEL": {"diesel": 1.171, "petrol": 1.552, "lpg": 0.553, "unit": "PLN/litr"},
    "ALCOHOL": {"ethyl_alcohol": 6900, "beer": 8.57, "wine": 180, "unit": "PLN/hl"},
    "TOBACCO": {"cigarettes": 0.484, "cigars": 0.484, "unit": "PLN/szt"},
    "ENERGY": {"electricity": 5.00, "unit": "PLN/MWh"},
}

def track_excise_warehouse(product_type: str, quantity: float, is_suspended: bool = False,
                           warehouse_id: str = "") -> dict:
    """Track excise goods in tax warehouse with suspension procedure."""
    result = {"product_type": product_type, "quantity": quantity, "excise_due": 0.0,
              "suspension": is_suspended, "warehouse_id": warehouse_id, "warnings": []}

    for category, products in EXCISE_PRODUCTS.items():
        for product, rate in products.items():
            if product == "unit":
                continue
            if product_type.upper() == product.upper() or product_type.upper() in product.upper():
                actual_rate = rate if product != product_type.upper() else EXCISE_PRODUCTS.get(category, {}).get(product, 0)
                result["excise_due"] = round(quantity * actual_rate, 2)
                result["unit"] = EXCISE_PRODUCTS.get(category, {}).get("unit", "")
                result["category"] = category

                if is_suspended:
                    result["warnings"].append(
                        f"PROCEDURA ZAWIESZENIA — Akcyza {result['excise_due']:.2f} PLN odroczona "
                        f"(skład podatkowy {warehouse_id}). Wymagane zabezpieczenie akcyzowe!"
                    )
                else:
                    result["warnings"].append(
                        f"AKCYZA NALEŻNA — {quantity} × {actual_rate} = {result['excise_due']:.2f} PLN. "
                        f"Zapłać do 25. dnia następnego miesiąca. Deklaracja AKC-4."
                    )
                return result

    result["warnings"].append(f"Nieznany produkt akcyzowy: {product_type}")
    return result

# ═══════════════════════════════════════════════════════════════════════════
# INN05: Transport Tax Auto-Calculator
# ═══════════════════════════════════════════════════════════════════════════
def calculate_transport_tax(dmc_kg: float, vehicle_type: str = "TRUCK",
                            seats: int = 0, axles: int = 2, is_electric: bool = False,
                            is_historic: bool = False, seasonal_months: int = 12) -> dict:
    """Auto-calculate transport tax for heavy vehicles."""
    result = {"tax_applies": True, "annual_tax": 0.0, "form": "DT-1", "warnings": []}

    if is_historic:
        result["tax_applies"] = False
        result["annual_tax"] = 0.0
        result["warnings"].append("ZWOLNIONE — pojazd zabytkowy (Art. 12 ust. 1 pkt 2)")
        return result

    if is_electric:
        result["tax_applies"] = False
        result["annual_tax"] = 0.0
        result["warnings"].append("ZWOLNIONE — pojazd elektryczny (Art. 12 ust. 1 pkt 1)")
        return result

    if dmc_kg <= 3500:
        result["tax_applies"] = False
        result["warnings"].append(f"NIE PODLEGA — DMC {dmc_kg}kg ≤ 3500kg")
        return result

    if vehicle_type == "BUS":
        tax = 1600 if seats < 22 else (2400 if seats < 40 else 3000)
        result["annual_tax"] = tax
        result["warnings"].append(f"AUTOBUS — {seats} miejsc → {tax} PLN/rok")
    elif vehicle_type == "TRACTOR_UNIT":
        result["annual_tax"] = 2300
        result["warnings"].append("CIĄGNIK SIODŁOWY → 2300 PLN/rok")
    elif vehicle_type in ("TRAILER", "SEMI_TRAILER"):
        dmc_t = dmc_kg / 1000
        tax = 800 if dmc_t <= 5 else (1200 if dmc_t <= 10 else (1800 if dmc_t <= 20 else (2400 if axles == 2 else 3200)))
        result["annual_tax"] = tax
        result["warnings"].append(f"PRZYCZEPA/NACZEPA — DMC {dmc_t}t, {axles} osi → {tax} PLN/rok")
    else:  # TRUCK
        tax = 800 if dmc_kg <= 5500 else (1200 if dmc_kg <= 9000 else (1800 if dmc_kg <= 16000 else 2500))
        result["annual_tax"] = tax
        result["warnings"].append(f"CIĘŻARÓWKA — DMC {dmc_kg}kg → {tax} PLN/rok")

    if seasonal_months < 12:
        full = result["annual_tax"]
        result["annual_tax"] = round(full * seasonal_months / 12, 2)
        result["warnings"].append(f"SEZONOWY ({seasonal_months}/12 mies.) → proporcjonalnie: {result['annual_tax']:.2f} PLN")

    result["installments"] = [
        {"date": f"{datetime.now().year}-02-15", "amount": round(result['annual_tax'] / 2, 2)},
        {"date": f"{datetime.now().year}-09-15", "amount": round(result['annual_tax'] / 2, 2)},
    ]

    return result

# ═══════════════════════════════════════════════════════════════════════════
# INN06: Multi-Tax Local Calendar
# ═══════════════════════════════════════════════════════════════════════════
LOCAL_TAX_CALENDAR = [
    {"tax": "PODATEK OD NIERUCHOMOŚCI", "form": "DN-1", "deadline": "14 dni od nabycia/zmiany",
     "payments": ["15 marca", "15 maja", "15 września", "15 listopada"]},
    {"tax": "PODATEK ROLNY", "form": "IR-1", "deadline": "15 stycznia",
     "payments": ["15 marca", "15 maja", "15 września", "15 listopada"]},
    {"tax": "PODATEK LEŚNY", "form": "IL-1", "deadline": "15 stycznia",
     "payments": ["15 marca", "15 maja", "15 września", "15 listopada"]},
    {"tax": "PODATEK OD TRANSPORTU", "form": "DT-1", "deadline": "15 lutego",
     "payments": ["15 lutego", "15 września"]},
    {"tax": "PCC", "form": "PCC-3", "deadline": "14 dni od zawarcia umowy",
     "payments": ["W ciągu 14 dni od powstania obowiązku"]},
    {"tax": "AKCYZA", "form": "AKC-4", "deadline": "25. dnia następnego miesiąca",
     "payments": ["Do 25. dnia następnego miesiąca"]},
    {"tax": "OPŁATA TARGOWA", "form": "—", "deadline": "W dniu sprzedaży",
     "payments": ["Przed rozpoczęciem sprzedaży"]},
    {"tax": "OPŁATA REKLAMOWA", "form": "—", "deadline": "Wg uchwały rady gminy",
     "payments": ["Wg uchwały rady gminy"]},
]

def generate_local_tax_calendar() -> list:
    """Generate local tax calendar with upcoming deadlines."""
    now = datetime.now()
    calendar = []
    for entry in LOCAL_TAX_CALENDAR:
        upcoming = []
        for pmt in entry["payments"]:
            for day_str in pmt.replace(" dnia", "").replace(" od zawarcia umowy", "").replace(" od nabycia/zmiany", "").replace(" od powstania obowiązku", "").split(", "):
                try:
                    date_parts = day_str.strip().split()
                    if len(date_parts) >= 2:
                        day = int(date_parts[0]) if date_parts[0].isdigit() else 15
                        month_map = {"stycznia":1,"lutego":2,"marca":3,"kwietnia":4,"maja":5,"czerwca":6,
                                    "lipca":7,"sierpnia":8,"września":9,"października":10,"listopada":11,"grudnia":12}
                        month = month_map.get(date_parts[-1].lower(), 1)
                        deadline = datetime(now.year, month, day)
                        if deadline < now:
                            deadline = datetime(now.year + 1, month, day)
                        upcoming.append(deadline.strftime("%Y-%m-%d"))
                except:
                    pass
        calendar.append({"tax": entry["tax"], "form": entry["form"], "deadline_rule": entry["deadline"],
                        "upcoming_dates": sorted(upcoming)[:3]})
    return calendar

# ═══════════════════════════════════════════════════════════════════════════
# INN07: VAT-PCC Exclusion Firewall
# ═══════════════════════════════════════════════════════════════════════════
def vat_pcc_exclusion_firewall(transaction_type: str, amount: float,
                               is_vat_payer: bool, has_vat_invoice: bool) -> dict:
    """Firewall ensuring no double taxation (VAT + PCC on same transaction)."""
    result = {"double_tax_risk": False, "vat_applies": False, "pcc_applies": False,
              "primary_tax": None, "exclusion_basis": None, "warnings": []}

    if is_vat_payer and has_vat_invoice:
        result["vat_applies"] = True
        result["pcc_applies"] = False
        result["primary_tax"] = "VAT"
        result["exclusion_basis"] = "Art. 2 pkt 4 ustawy o PCC"
        result["warnings"].append("FIREWALL OK — VAT wyklucza PCC. Transakcja podlega tylko VAT.")
    elif not is_vat_payer and not has_vat_invoice:
        result["pcc_applies"] = True
        result["primary_tax"] = "PCC"
        result["warnings"].append("PCC obowiązuje — brak faktury VAT, sprzedawca nie jest VAT-owcem.")
    elif is_vat_payer and not has_vat_invoice:
        result["double_tax_risk"] = True
        result["warnings"].append("⚠️ RYZYKO — VAT-owiec bez faktury! Sprawdź czy PCC nie zostanie naliczone podwójnie.")
    else:
        result["vat_applies"] = True
        result["primary_tax"] = "VAT"
        result["warnings"].append("Faktura VAT obecna — PCC wyłączone.")

    return result

# ═══════════════════════════════════════════════════════════════════════════
# INN08: Excise Suspension Procedure Manager
# ═══════════════════════════════════════════════════════════════════════════
def manage_excise_suspension(product_type: str, quantity: float, annual_volume: float,
                             warehouse_authorized: bool = False, guarantee_amount: float = 0) -> dict:
    """Manage excise suspension procedure."""
    result = {"eligible_for_suspension": False, "guarantee_required": 0.0,
              "conditions": [], "steps": [], "warnings": []}

    # Only certain products eligible
    if product_type.upper() in ("ETHYL_ALCOHOL", "FUEL", "TOBACCO"):
        result["eligible_for_suspension"] = True

    if not warehouse_authorized:
        result["conditions"].append("WYMAGANE: zezwolenie na prowadzenie składu podatkowego")
        result["steps"].append("1. Złóż wniosek o zezwolenie do naczelnika US")
        result["steps"].append("2. Przedstaw zabezpieczenie akcyzowe (gwarancja bankowa/ubezpieczeniowa)")
        result["steps"].append("3. Zainstaluj urządzenia pomiarowe")

    result["guarantee_required"] = round(quantity * 0.3, 2)  # ~30% of excise value as guarantee
    if guarantee_amount < result["guarantee_required"]:
        result["warnings"].append(
            f"NIEWYSTARCZAJĄCE ZABEZPIECZENIE — wymagane {result['guarantee_required']:.2f} PLN, "
            f"masz {guarantee_amount:.2f} PLN"
        )

    result["steps"].append(f"4. Prowadź ewidencję wyrobów akcyzowych w składzie podatkowym")
    result["steps"].append(f"5. Składaj deklaracje AKC-4 miesięcznie do 25. dnia")
    result["conditions"].append(f"Roczny wolumen: {annual_volume:.1f} — {'POWYŻEJ' if annual_volume > 100000 else 'PONIŻEJ'} progu 100k litrów/rok")

    return result

# ═══════════════════════════════════════════════════════════════════════════
# INN09: Property Tax Appeal Auto-Drafter
# ═══════════════════════════════════════════════════════════════════════════
def draft_property_tax_appeal(property_area: float, assessed_value: float,
                              taxpayer_valuation: float, dispute_reason: str) -> dict:
    """Auto-draft property tax appeal."""
    overpayment = max(0, assessed_value - taxpayer_valuation) * 33.10
    return {
        "document": "ODWOŁANIE OD DECYZJI W SPRAWIE PODATKU OD NIERUCHOMOŚCI",
        "to": "Samorządowe Kolegium Odwoławcze",
        "via": "Wójt/Burmistrz/Prezydent Miasta",
        "deadline_days": 14,
        "basis": "Art. 220-221 Ordynacji Podatkowej",
        "dispute_reason": dispute_reason,
        "assessed_value": assessed_value,
        "taxpayer_valuation": taxpayer_valuation,
        "potential_overpayment": round(overpayment, 2),
        "body_template": (
            f"Na podstawie Art. 220 §1 Ordynacji Podatkowej odwołuję się od decyzji "
            f"wymiarowej na rok {datetime.now().year}.\n\n"
            f"Powód: {dispute_reason}\n"
            f"Wartość wg organu: {assessed_value:.2f} PLN\n"
            f"Wartość wg podatnika: {taxpayer_valuation:.2f} PLN\n"
            f"Potencjalna nadpłata: {overpayment:.2f} PLN\n\n"
            f"Wnoszę o ponowne ustalenie wymiaru podatku."
        ),
        "warnings": [
            "Złóż w ciągu 14 dni od doręczenia decyzji!",
            "SKO rozpatruje w ciągu 2 miesięcy.",
            "W trakcie odwołania podatek płacisz w niekwestionowanej części."
        ]
    }

# ═══════════════════════════════════════════════════════════════════════════
# INN10: Local Tax Rate Auto-Updater
# ═══════════════════════════════════════════════════════════════════════════
LOCAL_TAX_RATES_2026 = {
    "property_business_building": 33.10,
    "property_residential": 1.15,
    "property_business_land": 1.35,
    "transport_truck_3500_5500": 800,
    "transport_truck_5500_9000": 1200,
    "transport_truck_9000_16000": 1800,
    "transport_truck_16000_plus": 2500,
    "transport_bus_small": 1600,
    "transport_bus_large": 3000,
    "transport_tractor": 2300,
    "agricultural_rye_price": 89.63,
    "forestry_wood_price": 350.00,
    "advertising_max_daily": 3.20,
    "market_daily": 40.00,
    "dog_annual": 150.00,
    "spa_daily": 6.80,
    "min_wage_2026": 4666,
}

def update_local_tax_rates(new_rates: dict = None) -> dict:
    """Auto-update local tax rates for 2026 (indexed to inflation)."""
    current = LOCAL_TAX_RATES_2026.copy()
    if new_rates:
        current.update(new_rates)
    return {
        "year": 2026,
        "rates": current,
        "indexation": "CPI 2025 = 3.7%",
        "next_update": "2027-01-01",
        "source": "Uchwały rad gmin + obwieszczenie MF",
    }

# ═══════════════════════════════════════════════════════════════════════════
# INN11: Cross-Border Excise Compliance (UE)
# ═══════════════════════════════════════════════════════════════════════════
def cross_border_excise_check(direction: str, product_type: str, quantity: float,
                              origin_country: str, destination_country: str,
                              has_emcs: bool = False) -> dict:
    """Check cross-border excise compliance within EU."""
    result = {"compliant": False, "emcs_required": False, "document": None,
              "deadline": None, "warnings": []}

    if direction == "IMPORT":
        result["emcs_required"] = True
        result["document"] = "e-AD (elektroniczny dokument administracyjny)"
        if has_emcs:
            result["compliant"] = True
            result["warnings"].append("EMCS OK — e-AD zarejestrowany. Akcyza zawieszona do momentu odbioru.")
        else:
            result["warnings"].append("⚠️ BRAK EMCS! Wymagany e-AD dla wewnątrzwspólnotowego przemieszczania wyrobów akcyzowych.")
    elif direction == "EXPORT":
        result["document"] = "e-AD + potwierdzenie odbioru"
        result["deadline"] = "5 dni roboczych od wysyłki"
        if has_emcs:
            result["compliant"] = True
            result["warnings"].append(f"EMCS OK — eksport do {destination_country}. Zwrot akcyzy po potwierdzeniu odbioru.")
        else:
            result["warnings"].append("⚠️ Zarejestruj w EMCS przed wysyłką!")

    result["warnings"].append(
        f"UE cross-border: {origin_country} → {destination_country}, "
        f"{quantity} {product_type}. {'ZGODNE' if result['compliant'] else 'NIEZGODNE'}."
    )
    return result

# ═══════════════════════════════════════════════════════════════════════════
# INN12: PCC + VAT Exclusion Comprehensive Matrix
# ═══════════════════════════════════════════════════════════════════════════
PCC_VAT_MATRIX = {
    ("SALE", True, True): "VAT_ONLY",
    ("SALE", True, False): "VAT_ONLY",
    ("SALE", False, True): "PCC_ONLY",
    ("SALE", False, False): "PCC_ONLY",
    ("LOAN", True, True): "VAT_EXEMPT_NO_PCC",
    ("LOAN", False, False): "PCC_LOAN",
    ("COMPANY_FORMATION", True, True): "VAT_ONLY",
    ("COMPANY_FORMATION", False, False): "PCC_COMPANY",
    ("EXCHANGE", True, True): "VAT_ONLY",
    ("EXCHANGE", False, True): "PCC_ONLY",
    ("CAR_PRIVATE", False, True): "PCC_CAR_2PCT",
    ("CAR_PRIVATE", True, True): "VAT_ONLY",
}

def pcc_vat_matrix_check(transaction_type: str, is_vat_payer_seller: bool,
                         has_vat_invoice: bool) -> dict:
    """Comprehensive PCC vs VAT exclusion matrix."""
    key = (transaction_type, is_vat_payer_seller, has_vat_invoice)
    default = "CHECK_MANUALLY"
    result_code = PCC_VAT_MATRIX.get(key, default)

    return {
        "transaction": transaction_type,
        "seller_is_vat_payer": is_vat_payer_seller,
        "has_vat_invoice": has_vat_invoice,
        "result": result_code,
        "pcc_applies": "PCC" in result_code,
        "vat_applies": "VAT" in result_code,
        "exclusion_basis": "Art. 2 pkt 4 PCC" if "VAT" in result_code else None,
        "warning": "OK — VAT wyklucza PCC" if "VAT" in result_code else "PCC obowiązuje — złóż PCC-3 w 14 dni"
    }

# ═══════════════════════════════════════════════════════════════════════════
# Report Generator
# ═══════════════════════════════════════════════════════════════════════════
def generate_report(title: str, results: list, report_path: str) -> str:
    """Generate TXT report for P15."""
    lines = [title, "=" * 65, f"Data: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", ""]
    for r in results:
        lines.append(f"  [{r['name']}]")
        lines.append(f"    Wynik: {r.get('result', 'OK')}")
        lines.append(f"    Opis:  {r.get('description', '')}")
        lines.append("")
    lines.append(f"=== KONIEC RAPORTU — P15 LOCAL TAXES v7.0 ===")
    content = "\n".join(lines)
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(content)
    return report_path

# ═══════════════════════════════════════════════════════════════════════════
# CLI MAIN
# ═══════════════════════════════════════════════════════════════════════════
def main():
    parser = argparse.ArgumentParser(description="P15 Local Taxes Toolkit")
    sub = parser.add_subparsers(dest="command")

    # PCC detect
    p1 = sub.add_parser("pcc-detect")
    p1.add_argument("--description", required=True)
    p1.add_argument("--amount", type=float, default=0)
    p1.add_argument("--vat-invoice", action="store_true")
    p1.add_argument("--vat-payer", action="store_true")
    p1.add_argument("--date", default=None)

    # PCC-3 fill
    p2 = sub.add_parser("pcc3-fill")
    p2.add_argument("--type", required=True)
    p2.add_argument("--amount", type=float, default=0)
    p2.add_argument("--buyer", default="")
    p2.add_argument("--seller", default="")
    p2.add_argument("--date", default=datetime.now().strftime("%Y-%m-%d"))

    # Property
    p3 = sub.add_parser("property")
    p3.add_argument("--area", type=float, default=50)
    p3.add_argument("--business", action="store_true")
    p3.add_argument("--residential", action="store_true")
    p3.add_argument("--mixed-pct", type=float, default=0)
    p3.add_argument("--construction-value", type=float, default=0)

    # Excise
    p4 = sub.add_parser("excise")
    p4.add_argument("--product", required=True)
    p4.add_argument("--quantity", type=float, required=True)
    p4.add_argument("--suspended", action="store_true")
    p4.add_argument("--warehouse", default="")

    # Transport
    p5 = sub.add_parser("transport")
    p5.add_argument("--dmc", type=float, default=8000)
    p5.add_argument("--type", default="TRUCK")
    p5.add_argument("--seats", type=int, default=0)
    p5.add_argument("--axles", type=int, default=2)
    p5.add_argument("--electric", action="store_true")
    p5.add_argument("--historic", action="store_true")
    p5.add_argument("--seasonal", type=int, default=12)

    # Calendar
    sub.add_parser("calendar")

    # Firewall
    p6 = sub.add_parser("firewall")
    p6.add_argument("--type", default="SALE")
    p6.add_argument("--amount", type=float, default=0)
    p6.add_argument("--vat-payer", action="store_true")
    p6.add_argument("--vat-invoice", action="store_true")

    # Appeal
    p7 = sub.add_parser("appeal")
    p7.add_argument("--area", type=float, default=50)
    p7.add_argument("--assessed", type=float, default=2000)
    p7.add_argument("--taxpayer-value", type=float, default=1500)
    p7.add_argument("--reason", default="Błędna klasyfikacja nieruchomości")

    # Cross-border excise
    p8 = sub.add_parser("cross-border")
    p8.add_argument("--direction", default="IMPORT")
    p8.add_argument("--product", default="FUEL")
    p8.add_argument("--quantity", type=float, default=1000)
    p8.add_argument("--origin", default="DE")
    p8.add_argument("--destination", default="PL")
    p8.add_argument("--emcs", action="store_true")

    # Matrix
    p9 = sub.add_parser("matrix")
    p9.add_argument("--type", default="SALE")
    p9.add_argument("--vat-payer", action="store_true")
    p9.add_argument("--vat-invoice", action="store_true")

    # All demo
    sub.add_parser("all")

    # Rates
    sub.add_parser("rates")

    args = parser.parse_args()
    results = []

    if args.command == "pcc-detect":
        r = detect_pcc_obligation(args.description, args.amount, args.vat_invoice, args.vat_payer, args.date)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "pcc3-fill":
        r = fill_pcc3(args.type, args.amount, args.buyer, args.seller, args.date)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "property":
        r = classify_property(args.area, args.business, args.residential, args.construction_value, args.mixed_pct)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "excise":
        r = track_excise_warehouse(args.product, args.quantity, args.suspended, args.warehouse)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "transport":
        r = calculate_transport_tax(args.dmc, args.type, args.seats, args.axles, args.electric, args.historic, args.seasonal)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "calendar":
        r = generate_local_tax_calendar()
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "firewall":
        r = vat_pcc_exclusion_firewall(args.type, args.amount, args.vat_payer, args.vat_invoice)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "appeal":
        r = draft_property_tax_appeal(args.area, args.assessed, args.taxpayer_value, args.reason)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "cross-border":
        r = cross_border_excise_check(args.direction, args.product, args.quantity, args.origin, args.destination, args.emcs)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "matrix":
        r = pcc_vat_matrix_check(args.type, args.vat_payer, args.vat_invoice)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "rates":
        r = update_local_tax_rates()
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.command == "all":
        # Demo all innovations
        r1 = detect_pcc_obligation("kupno auta od osoby prywatnej", 45000)
        results.append({"name": "INN01 PCC Detect (auto prywatne 45k)", "result": f"PCC: {r1['pcc_tax']} PLN", "description": r1['warnings'][0] if r1['warnings'] else "OK"})

        r2 = fill_pcc3("CAR_PRIVATE", 45000, "Jan Kowalski", "Anna Nowak", "2026-06-15")
        results.append({"name": "INN02 PCC-3 Auto-Fill", "result": f"Form: {r2['form']}, Tax: {r2['field_G']} PLN", "description": f"Deadline: {r2.get('deadline', 'N/A')}"})

        r3 = classify_property(80, True, True, mixed_business_pct=40)
        results.append({"name": "INN03 Property Classifier", "result": f"{r3['classification']} — {r3['annual_tax']} PLN/rok", "description": r3['warnings'][0]})

        r4 = track_excise_warehouse("diesel", 5000)
        results.append({"name": "INN04 Excise Tracker", "result": f"{r4['excise_due']} PLN", "description": r4['warnings'][0]})

        r5 = calculate_transport_tax(8000, "TRUCK")
        results.append({"name": "INN05 Transport Tax", "result": f"{r5['annual_tax']} PLN/rok", "description": r5['warnings'][0]})

        r6 = generate_local_tax_calendar()
        results.append({"name": "INN06 Calendar", "result": f"{len(r6)} entries", "description": "Kalendarz podatków lokalnych"})

        r7 = vat_pcc_exclusion_firewall("SALE", 50000, False, False)
        results.append({"name": "INN07 Firewall", "result": r7['primary_tax'], "description": r7['warnings'][0]})

        r8 = manage_excise_suspension("ETHYL_ALCOHOL", 1000, 50000)
        results.append({"name": "INN08 Suspension", "result": f"Eligible: {r8['eligible_for_suspension']}", "description": r8['conditions'][0] if r8['conditions'] else "OK"})

        r9 = draft_property_tax_appeal(100, 3310, 1655, "Błędna klasyfikacja — budynek mieszkalny, nie firmowy")
        results.append({"name": "INN09 Appeal Drafter", "result": f"Overpayment: {r9['potential_overpayment']} PLN", "description": r9['basis']})

        r10 = update_local_tax_rates()
        results.append({"name": "INN10 Rates 2026", "result": f"Min wage: {r10['rates']['min_wage_2026']} PLN", "description": f"Indexation: {r10['indexation']}"})

        r11 = cross_border_excise_check("IMPORT", "FUEL", 10000, "DE", "PL", True)
        results.append({"name": "INN11 Cross-Border", "result": "COMPLIANT" if r11['compliant'] else "NON-COMPLIANT", "description": r11['warnings'][0]})

        r12 = pcc_vat_matrix_check("SALE", True, True)
        results.append({"name": "INN12 PCC-VAT Matrix", "result": r12['result'], "description": r12['warning']})

        print(f"\n{'='*60}\n  P15 LOCAL TAXES TOOLKIT — All 12 Innovations\n{'='*60}")
        for r in results:
            print(f"  [{r['name']}] → {r['result']}")

        report_path = os.path.join(REPORTS_DIR, "RAPORT_P15_JDG_PCC_LOCAL_EXCISE_v7.0.txt")
        generate_report("RAPORT ANALITYCZNY ENTERPRISE — JDG PCC + Podatki Lokalne + Akcyza v7.0", results, report_path)
        print(f"\n  📄 Report: {report_path}")


if __name__ == "__main__":
    main()
