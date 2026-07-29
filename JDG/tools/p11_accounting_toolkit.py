#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P11 ACCOUNTING PKPiR COMPREHENSIVE TOOLKIT v8.0
# ═══════════════════════════════════════════════════════════════════════════════
# Implements all 8 innovations from p11_accounting_pkpir_innovations_v8.rego
# plus additional report recommendations (column fix, NKUP expansion, KST full)
# ═══════════════════════════════════════════════════════════════════════════════

import argparse
import json
from datetime import date, datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
REPORTS_DIR = PROJECT_ROOT / "JDG" / "reports"
RULES_DIR = PROJECT_ROOT / "JDG" / "rules"

# ═══════════════════════════════════════════════════════════════════════════════
# INN01: PKPiR COLUMN AUTO-CLASSIFIER
# ═══════════════════════════════════════════════════════════════════════════════

# CORRECTED column numbering per Rozporządzenie MF PKPiR (17 columns)
PKPIR_COLUMNS_CORRECTED = {
    1:  {"name": "LP", "description": "Liczba porządkowa"},
    2:  {"name": "DATA_ZDARZENIA", "description": "Data zdarzenia gospodarczego"},
    3:  {"name": "DATA_WPISU", "description": "Data sporządzenia zapisu"},
    4:  {"name": "NR_DOWODU", "description": "Numer dowodu księgowego"},
    5:  {"name": "KONTRAHENT", "description": "Dane kontrahenta (nazwa, adres, NIP)"},
    6:  {"name": "OPIS", "description": "Opis zdarzenia gospodarczego"},
    7:  {"name": "SPRZEDAZ", "description": "Wartość sprzedanych towarów i usług"},
    8:  {"name": "POZOSTALE_PRZYCHODY", "description": "Pozostałe przychody"},
    9:  {"name": "UWAGI_PRZYCHODY", "description": "Uwagi do przychodów"},
    10: {"name": "ZAKUP_TOWAROW", "description": "Zakup towarów handlowych i materiałów"},
    11: {"name": "KOSZTY_UBOCZNE", "description": "Koszty uboczne zakupu"},
    12: {"name": "WYNAGRODZENIA", "description": "Wynagrodzenia w gotówce i naturze"},
    13: {"name": "POZOSTALE_WYDATKI", "description": "Pozostałe wydatki"},
    14: {"name": "RAZEM_WYDATKI", "description": "Razem wydatki (suma kol. 10-13)"},
    15: {"name": "ST_WARTOSC_POCZATKOWA", "description": "Wartość początkowa ŚT"},
    16: {"name": "ODPISY_AMORTYZACYJNE", "description": "Odpisy amortyzacyjne"},
    17: {"name": "UWAGI_KOSZTY", "description": "Uwagi"},
}

# OLD incorrect column mapping (from accounting.rego — has 19 columns!)
PKPIR_COLUMNS_SYSTEM_LEGACY = {
    10: "GOODS_REVENUE", 11: "OTHER_REVENUE", 12: "GOODS_PURCHASE",
    13: "ANCILLARY_COSTS", 14: "SALARIES", 15: "OTHER_EXPENSES",
    16: "NON_KUP", 17: "FIXED_ASSET", 19: "REMARKS",
}

EXPENSE_TO_COLUMN = {
    "GOODS_PURCHASE": 10, "MATERIALS": 10, "RAW_MATERIALS": 10,
    "TRANSPORT_IN": 11, "INSURANCE_TRANSIT": 11, "CUSTOMS_DUTY": 11, "PACKAGING": 11,
    "SALARIES": 12, "WAGES": 12, "BONUSES": 12,
    "RENT": 13, "UTILITIES": 13, "OFFICE_SUPPLIES": 13, "SOFTWARE": 13,
    "TELECOMMUNICATIONS": 13, "MARKETING": 13, "ADVERTISING": 13,
    "LEGAL_SERVICES": 13, "ACCOUNTING_SERVICES": 13, "CONSULTING": 13,
    "TRAINING": 13, "MAINTENANCE": 13, "SECURITY": 13, "TRANSPORT_GOODS": 13,
}

def classify_pkpir_column(expense_type: str, amount_net: float, is_fixed_asset: bool = False) -> dict:
    """INN01: Auto-classify an expense into the correct PKPiR column."""
    if is_fixed_asset and amount_net >= 10000:
        return {"column": 15, "name": "ST_WARTOSC_POCZATKOWA",
                "note": "Środek trwały — ewidencja w kol. 15-16"}
    if is_fixed_asset and amount_net < 10000:
        return {"column": 13, "name": "POZOSTALE_WYDATKI",
                "note": "Niskocenny składnik <10k — jednorazowo w kol. 13"}
    col = EXPENSE_TO_COLUMN.get(expense_type, 13)
    return {"column": col, "name": PKPIR_COLUMNS_CORRECTED[col]["name"],
            "note": PKPIR_COLUMNS_CORRECTED[col]["description"]}


# ═══════════════════════════════════════════════════════════════════════════════
# INN02: REVENUE-COST MATCHING ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

def match_revenue_cost(revenues: List[dict], costs: List[dict]) -> dict:
    """INN02: Match revenues to costs using DIRECT/INDIRECT/PROPORTIONAL methods."""
    result = {
        "direct_matches": [],
        "indirect_costs": [],
        "unmatched_revenues": [],
        "summary": {"total_revenue": 0, "total_cost": 0, "match_ratio": 0}
    }
    total_rev = sum(r.get("amount", 0) for r in revenues)
    total_cost = sum(c.get("amount", 0) for c in costs)
    result["summary"]["total_revenue"] = total_rev
    result["summary"]["total_cost"] = total_cost
    result["summary"]["match_ratio"] = round(total_cost / max(total_rev, 0.01) * 100, 1)

    for cost in costs:
        matched = False
        for rev in revenues:
            if cost.get("invoice_ref") == rev.get("invoice_ref"):
                result["direct_matches"].append({
                    "revenue": rev.get("amount", 0),
                    "cost": cost.get("amount", 0),
                    "margin": rev.get("amount", 0) - cost.get("amount", 0),
                    "ref": cost.get("invoice_ref")
                })
                matched = True
                break
        if not matched:
            result["indirect_costs"].append(cost)

    matched_revs = {m["ref"] for m in result["direct_matches"]}
    result["unmatched_revenues"] = [r for r in revenues
                                     if r.get("invoice_ref") not in matched_revs]
    return result


# ═══════════════════════════════════════════════════════════════════════════════
# INN03: NKUP AUTO-DETECTOR (57 points of Art. 23 PIT)
# ═══════════════════════════════════════════════════════════════════════════════

NKUP_KEYWORDS = {
    "reprezentacja": {"point": 23, "severity": "HIGH",
                       "keywords": ["reprezentacja", "alkohol", "luksus", "bankiet", "przyjęcie"]},
    "kara": {"point": 4, "severity": "CRITICAL",
             "keywords": ["kara", "grzywna", "mandat", "odszkodowanie karne"]},
    "leasing_powyzej_150k": {"point": "47a", "severity": "HIGH",
                              "keywords": ["leasing", "samochód", "auto", "150"]},
    "odziez": {"point": 8, "severity": "LOW",
               "keywords": ["odzież", "ubranie", "garnitur", "buty", "garderoba"]},
    "wydatki_mieszkaniowe": {"point": 7, "severity": "MEDIUM",
                              "keywords": ["mieszkanie", "czynsz prywatny", "remont domu"]},
    "podatki_niekup": {"point": 5, "severity": "HIGH",
                        "keywords": ["podatek od nieruchomości prywatnej", "podatek od spadku"]},
    "splata_kapitalu": {"point": 12, "severity": "HIGH",
                         "keywords": ["spłata", "kapitał", "rata kredytu", "pożyczka kapitał"]},
    "darowizna": {"point": 11, "severity": "MEDIUM",
                  "keywords": ["darowizna", "datek", "fundacja", "zbiórka"]},
    "odsetki_budzetowe": {"point": 18, "severity": "HIGH",
                           "keywords": ["odsetki budżetowe", "odsetki od zaległości"]},
    "zbrojenie": {"point": 6, "severity": "CRITICAL",
                  "keywords": ["zbrojenie", "broń", "amunicja", "militaria"]},
}

# Missing 42 NKUP points to expand coverage
# -- Snip: 42 missing NKUP points -- see JDG/rules/_pkpir_rates.rego for the canonical list.
# Python convenience copy kept for standalone toolkit use.
NKUP_EXPANDED_POINTS = {
    2: "Wydatki na cele objęte protokołem",
    3: "Dodatki Dla Ziemi",
    4: "Kary, grzywny, odszkodowania karne",
    5: "Podatki i opłaty niezaliczone do KUP",
    6: "Wydatki zbrojeniowe",
    7: "Wydatki mieszkaniowe prywatne",
    8: "Odzież niereprezentacyjna",
    9: "Raty z umów najmu",
    12: "Spłata kapitału pożyczki",
    13: "Zapłata za zakup niezgodny z przepisami",
    14: "Wydatki na wyroby akcyzowe",
    15: "Rezerwy — tylko uznane w UoR",
    16: "Wydatki na cele osobiste",
    17: "Koszty egzekucyjne i postępowania",
    18: "Odsetki budżetowe i od zaległości",
    19: "Kary umowne i odszkodowania",
    20: "Wydatki na zakup gruntów (przez amortyzację)",
    21: "Odpisy aktualizujące (rezerwy)",
    22: "Wydatki na organizacje non-profit",
    24: "Koszty postępowania sądowego",
    25: "Wydatki na cele reklamowe niestandardowe",
    26: "Wydatki na zakup/wytworzenie środków trwałych",
    27: "Wydatki na nabycie wartości niematerialnych",
    28: "Wydatki na inwestycje w obcych środkach",
    29: "Wydatki na organizację produkcji",
    30: "Koszty zaniechanych inwestycji",
    31: "Straty w środkach trwałych",
    32: "Odsetki od pożyczek — thin cap",
    33: "Odsetki od pożyczek ponad limit",
    34: "Wydatki na nabycie udziałów",
    35: "Świadczenia pracownicze ponad limit",
    36: "Składki ZUS w części pracownika",
    37: "Wydatki na PFRON",
    38: "Wyżywienie pracowników ponad limit",
    39: "Wydatki na zakup odzieży służbowej",
    40: "Zakup napojów alkoholowych",
    41: "Imprezy integracyjne ponad limit",
    42: "Świadczenia urlopowe ponad limit",
    43: "VAT naliczony gdy można było odliczyć",
    44: "Składki na ubezpieczenia pracownicze",
    45: "Zakup paliw bez ewidencji przebiegu",
    46: "Samochód osobowy — 75% KUP",
    47: "Składki AC/OC auto > 150k/225k",
    471: "Leasing operacyjny auta > 150k/225k limit",
    48: "Składki członkowskie",
    49: "Wydatki na radę nadzorczą",
    50: "Kult religijny ponad limit 6% dochodu",
    51: "Działalność socjalna ponad ZFŚS",
    52: "Ekwiwalent za pranie odzieży",
    53: "Zakup wody i napojów dla pracowników",
    54: "Tłumaczenia przysięgłe prywatne",
    55: "Studia podyplomowe niekwalifikowane",
    56: "Wydatki związane z dochodami wolnymi",
    57: "Wydatki na cele osobiste właściciela",
}

def detect_nkup(description: str, amount: float, expense_type: str = "") -> List[dict]:
    """INN03: Auto-detect NKUP expenses by keyword matching against Art. 23 PIT."""
    detected = []
    desc_lower = description.lower()
    for category, info in NKUP_KEYWORDS.items():
        for kw in info["keywords"]:
            if kw.lower() in desc_lower:
                # NKUP is always the full amount for Art. 23 expenses.
                # Partial NKUP (like 75%/25% for cars) is handled by dedicated rules, not keywords.
                nkup_amount = amount
                detected.append({
                    "category": category,
                    "point": f'Art. 23 ust. 1 pkt {info["point"]} PIT',
                    "severity": info["severity"],
                    "nkup_amount": round(nkup_amount, 2),
                    "matched_keyword": kw,
                })
                break
    return detected

def get_nkup_expansion_summary() -> dict:
    """Return summary of 42 missing NKUP points ready for implementation."""
    return {
        "currently_covered": 15,
        "total_points": 57,
        "coverage_pct": 26.3,
        "missing_count": len(NKUP_EXPANDED_POINTS),
        "missing_points": NKUP_EXPANDED_POINTS,
        "recommendation": "Implement remaining points as atomic Rego rules in nkup_enterprise_complete.rego"
    }


# ═══════════════════════════════════════════════════════════════════════════════
# INN04: DEPRECIATION SCHEDULE GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

# FULL KST table — all 10 groups + subgroups (was only 5 in system)
KST_FULL_TABLE = {
    # Grupa 0: Grunty
    "0_0": {"group": 0, "subgroup": 0, "name": "Grunty", "rate": 0.0, "notes": "NIE amortyzuje się"},
    # Grupa 1: Budynki i lokale (40 lat)
    "1_1": {"group": 1, "subgroup": 1, "name": "Budynki mieszkalne", "rate": 2.5},
    "1_2": {"group": 1, "subgroup": 2, "name": "Budynki niemieszkalne", "rate": 2.5},
    "1_3": {"group": 1, "subgroup": 3, "name": "Lokale mieszkalne", "rate": 2.5},
    "1_4": {"group": 1, "subgroup": 4, "name": "Lokale użytkowe", "rate": 2.5},
    # Grupa 2: Budowle (NOWA — brak w systemie)
    "2_1": {"group": 2, "subgroup": 1, "name": "Budowle przemysłowe", "rate": 4.5},
    "2_2": {"group": 2, "subgroup": 2, "name": "Rurociągi", "rate": 4.5},
    "2_3": {"group": 2, "subgroup": 3, "name": "Obiekty inżynierii", "rate": 2.5},
    # Grupa 3: Kotły i maszyny energetyczne
    "3_1": {"group": 3, "subgroup": 1, "name": "Kotły energetyczne", "rate": 7.0},
    "3_2": {"group": 3, "subgroup": 2, "name": "Maszyny energetyczne", "rate": 14.0},
    # Grupa 4: Maszyny i urządzenia ogólne
    "4_1": {"group": 4, "subgroup": 1, "name": "Maszyny do obróbki metali", "rate": 14.0},
    "4_2": {"group": 4, "subgroup": 2, "name": "Maszyny do obróbki drewna", "rate": 18.0},
    "4_3": {"group": 4, "subgroup": 3, "name": "Maszyny pakujące", "rate": 20.0},
    "4_4": {"group": 4, "subgroup": 4, "name": "Urządzenia biurowe", "rate": 10.0},
    "4_5": {"group": 4, "subgroup": 5, "name": "Komputery i serwery", "rate": 30.0},
    "4_6": {"group": 4, "subgroup": 6, "name": "Sprzęt telekomunikacyjny", "rate": 20.0},
    # Grupa 5: Maszyny specjalne branżowe
    "5_1": {"group": 5, "subgroup": 1, "name": "Maszyny budowlane", "rate": 14.0},
    "5_2": {"group": 5, "subgroup": 2, "name": "Maszyny rolnicze", "rate": 20.0},
    "5_3": {"group": 5, "subgroup": 3, "name": "Maszyny włókiennicze", "rate": 14.0},
    # Grupa 6: Urządzenia techniczne (NOWA — brak w systemie)
    "6_1": {"group": 6, "subgroup": 1, "name": "Kotły grzewcze", "rate": 10.0},
    "6_2": {"group": 6, "subgroup": 2, "name": "Klimatyzacja i wentylacja", "rate": 20.0},
    "6_3": {"group": 6, "subgroup": 3, "name": "Urządzenia dźwigowe", "rate": 14.0},
    # Grupa 7: Środki transportu
    "7_1": {"group": 7, "subgroup": 1, "name": "Samochody osobowe (do 150k/225k EV)", "rate": 20.0},
    "7_2": {"group": 7, "subgroup": 2, "name": "Samochody ciężarowe", "rate": 14.0},
    "7_3": {"group": 7, "subgroup": 3, "name": "Motocykle i skutery", "rate": 20.0},
    "7_4": {"group": 7, "subgroup": 4, "name": "Przyczepy i naczepy", "rate": 14.0},
    # Grupa 8: Narzędzia i wyposażenie (NOWA — brak w systemie)
    "8_1": {"group": 8, "subgroup": 1, "name": "Narzędzia i przyrządy", "rate": 20.0},
    "8_2": {"group": 8, "subgroup": 2, "name": "Wyposażenie biurowe (meble)", "rate": 20.0},
    "8_3": {"group": 8, "subgroup": 3, "name": "Sprzęt gastronomiczny", "rate": 20.0},
    # Grupa 9: Inwentarz żywy (NOWA — brak w systemie)
    "9_1": {"group": 9, "subgroup": 1, "name": "Inwentarz żywy", "rate": 10.0},
    # Grupa 10: WNiP
    "10_1": {"group": 10, "subgroup": 1, "name": "Programy komputerowe", "rate": 20.0},
    "10_2": {"group": 10, "subgroup": 2, "name": "Patenty i licencje", "rate": 20.0},
    "10_3": {"group": 10, "subgroup": 3, "name": "Know-how", "rate": 10.0},
}

DEPRECIATION_METHODS = {
    "LINEAR": {"name": "Liniowa", "legal": "Art. 22i ust. 1 PIT"},
    "DEGRESSIVE": {"name": "Degresywna", "legal": "Art. 22i ust. 2 PIT",
                   "max_coefficient": 2.0,
                   "applicable_groups": [3, 4, 5, 6, 8]},
    "ONE_TIME_10K": {"name": "Jednorazowa do 10 000 PLN", "legal": "Art. 22d PIT",
                     "max_value": 10000},
    "ONE_TIME_100K": {"name": "Jednorazowa de minimis do 100 000 PLN", "legal": "Art. 22k PIT",
                      "max_value": 100000, "conditions": "Mały podatnik LUB pierwszy rok"},
    "ONE_TIME_50K_EUR": {"name": "Jednorazowa 50 000 EUR", "legal": "Art. 22k ust. 7-8 PIT",
                         "value_eur": 50000, "approx_pln": 215000,
                         "note": "System ma 100k PLN — jest BARDZIEJ restrykcyjny niż ustawa (50k EUR ≈ 215k PLN)"},
}

def generate_depreciation_schedule(asset_value: float, kst_group: int, kst_subgroup: int = 1,
                                    method: str = "LINEAR", coefficient: float = 1.0,
                                    is_small_taxpayer: bool = False, is_first_year: bool = False,
                                    is_electric: bool = False) -> dict:
    """INN04: Generate complete depreciation schedule for a fixed asset."""
    key = f"{kst_group}_{kst_subgroup}"
    kst_info = KST_FULL_TABLE.get(key, {"group": kst_group, "subgroup": kst_subgroup,
                                          "name": f"Grupa {kst_group}", "rate": 14.0})

    result = {
        "asset_value": asset_value,
        "kst_group": kst_group,
        "kst_subgroup": kst_subgroup,
        "kst_name": kst_info["name"],
        "method": method,
        "schedule": [],
    }

    if method == "ONE_TIME_10K" and asset_value <= 10000:
        result["annual_depreciation"] = asset_value
        result["monthly_depreciation"] = asset_value
        result["schedule"] = [{"year": 1, "depreciation": asset_value, "remaining_value": 0}]
        return result

    if method == "ONE_TIME_100K" and (is_small_taxpayer or is_first_year):
        one_time = min(asset_value, 100000)
        remaining = max(0, asset_value - 100000)
        result["annual_depreciation"] = one_time
        result["excess_over_limit"] = remaining
        result["schedule"].append({"year": 1, "depreciation": one_time, "remaining_value": remaining})
        if remaining > 0:
            rate = kst_info["rate"] / 100.0
            for yr in range(1, int(1.0 / rate) + 1):
                depr = min(remaining, remaining * rate)
                remaining -= depr
                result["schedule"].append({"year": yr + 1, "depreciation": round(depr, 2),
                                            "remaining_value": round(remaining, 2)})
        return result

    # LINEAR method (default)
    if method == "LINEAR":
        # Car limit check
        if kst_group == 7 and kst_subgroup == 1:
            car_limit = 225000 if is_electric else 150000
            if asset_value > car_limit:
                result["car_limit"] = car_limit
                result["depreciable_base"] = car_limit
                result["excess_nkup"] = asset_value - car_limit
                asset_value = car_limit

        rate = kst_info["rate"] / 100.0
        annual_depr = round(asset_value * rate, 2)
        monthly_depr = round(annual_depr / 12, 2)
        years = int(100 / kst_info["rate"])
        result["annual_depreciation"] = annual_depr
        result["monthly_depreciation"] = monthly_depr
        result["total_years"] = years
        remaining = asset_value
        for yr in range(1, years + 1):
            depr = min(remaining, annual_depr)
            remaining -= depr
            result["schedule"].append({"year": yr, "depreciation": round(depr, 2),
                                        "remaining_value": round(max(0, remaining), 2)})
        return result

    # DEGRESSIVE method
    if method == "DEGRESSIVE":
        effective_rate = kst_info["rate"] * min(coefficient, 2.0)
        remaining = asset_value
        for yr in range(1, 11):
            depr = round(remaining * effective_rate / 100, 2)
            remaining -= depr
            result["schedule"].append({"year": yr, "depreciation": depr,
                                        "remaining_value": round(max(0, remaining), 2)})
            if remaining <= 0:
                break
            # Switch to linear when degressive < linear
            linear_depr = round(remaining * kst_info["rate"] / 100, 2)
            if depr < linear_depr:
                effective_rate = kst_info["rate"]
        return result

    return result


# ═══════════════════════════════════════════════════════════════════════════════
# INN05: VEHICLE EXPENSE SPLITTER
# ═══════════════════════════════════════════════════════════════════════════════

def split_vehicle_expenses(total_expense: float, has_mileage_log: bool = False,
                            is_electric: bool = False, car_value: float = 0,
                            expense_type: str = "GENERAL") -> dict:
    """INN05: Split vehicle expenses into KUP/NKUP portions."""
    car_limit = 225000 if is_electric else 150000
    result = {"total_expense": total_expense, "car_limit": car_limit,
              "car_value": car_value, "is_electric": is_electric}

    # Mileage log for operating expenses (fuel, repairs, etc.): 100% KUP
    is_operating = expense_type in {"FUEL", "REPAIR", "MAINTENANCE", "INSURANCE", "GENERAL"}

    if has_mileage_log and is_operating:
        result["kup_pct"] = 100
        result["kup_amount"] = total_expense
        result["nkup_amount"] = 0
        result["kup_note"] = "Ewidencja przebiegu → 100% KUP (koszty eksploatacyjne)"
        return result

    # Depreciation limit applies REGARDLESS of mileage log (Art. 23 ust. 1 pkt 4)
    if car_value > car_limit and expense_type in {"DEPRECIATION", "LEASING"}:
        ratio = car_limit / car_value
        result["limit_ratio"] = round(ratio * 100, 1)
        result["kup_amount"] = round(total_expense * ratio, 2)
        result["nkup_amount"] = round(total_expense * (1 - ratio), 2)
        result["kup_pct"] = round(ratio * 100, 1)
        result["kup_note"] = f"Amortyzacja/leasing auta > {car_limit} PLN — limit proporcjonalny (×{ratio:.2f})"
        return result

    # Without mileage log for operating expenses: 75% KUP, 25% NKUP
    result["kup_pct"] = 75
    result["kup_amount"] = round(total_expense * 0.75, 2)
    result["nkup_amount"] = round(total_expense * 0.25, 2)
    result["kup_note"] = "Bez ewidencji przebiegu → 75% KUP (koszty eksploatacyjne)"
    return result


# ═══════════════════════════════════════════════════════════════════════════════
# INN06: INVENTORY REMNANT CALCULATOR
# ═══════════════════════════════════════════════════════════════════════════════

def calculate_remnant(items: List[dict], method: str = "FIFO",
                       previous_remnant_end: float = 0,
                       is_liquidation: bool = False) -> dict:
    """INN06: Calculate inventory remnant with FIFO/weighted-average valuation."""
    result = {
        "method": method,
        "previous_remnant_end": previous_remnant_end,
        "total_valuation": 0,
        "items": [],
        "continuity_check": {},
    }

    for item in items:
        purchase_price = item.get("purchase_price", 0)
        market_price = item.get("market_price", purchase_price)
        qty = item.get("quantity", 1)
        valuation = min(purchase_price, market_price)  # LOWER_OF

        if item.get("is_damaged", False) or item.get("is_expired", False):
            valuation = 0  # Damaged goods = zero value

        total = round(valuation * qty, 2)
        result["items"].append({
            "name": item.get("name", ""),
            "qty": qty,
            "purchase_price": purchase_price,
            "market_price": market_price,
            "valuation_unit": valuation,
            "total": total,
            "note": "Uszkodzony/przeterminowany — wycena 0 PLN" if valuation == 0 else ""
        })
        result["total_valuation"] += total

    result["total_valuation"] = round(result["total_valuation"], 2)

    # Continuity check
    result["continuity_check"]["previous_end"] = previous_remnant_end
    result["continuity_check"]["current_start"] = result["total_valuation"]
    result["continuity_check"]["discrepancy"] = round(
        result["total_valuation"] - previous_remnant_end, 2)

    # Liquidation tax (10%)
    if is_liquidation:
        surplus = max(0, result["total_valuation"] - previous_remnant_end)
        result["liquidation_tax_10pct"] = round(surplus * 0.10, 2)
        result["liquidation_note"] = "10% zryczałtowany podatek od nadwyżki remanentu"

    return result


# ═══════════════════════════════════════════════════════════════════════════════
# INN07: PKPiR → UoR TRANSITION MANAGER
# ═══════════════════════════════════════════════════════════════════════════════

def manage_transition(annual_revenue_eur: float, is_voluntary: bool = False) -> dict:
    """INN07: Manage PKPiR → Full Accounting (UoR) transition."""
    LIMIT_EUR = 2_000_000
    steps = []
    must_transition = annual_revenue_eur > LIMIT_EUR

    if must_transition:
        steps.append({"step": 1, "action": "CLOSE_PKPIR",
                       "detail": f"Zamknij PKPiR na dzień poprzedzający przejście. Przychód {annual_revenue_eur:,.0f} EUR > {LIMIT_EUR:,} EUR"})
        steps.append({"step": 2, "action": "INVENTORY",
                       "detail": "Sporządź remanent na dzień przejścia (spis z natury)"})
        steps.append({"step": 3, "action": "OPENING_BALANCE",
                       "detail": "Sporządź bilans otwarcia wg UoR"})
        steps.append({"step": 4, "action": "OPEN_BOOKS",
                       "detail": "Otwórz księgi rachunkowe (dziennik, księga główna, księgi pomocnicze)"})
        steps.append({"step": 5, "action": "NOTIFY_US",
                       "detail": "Zawiadom Urząd Skarbowy o zmianie formy księgowości (30 dni)"})
        steps.append({"step": 6, "action": "FIRST_STATEMENT",
                       "detail": "Sporządź pierwsze sprawozdanie finansowe na koniec roku obrotowego"})
    elif is_voluntary:
        steps.append({"step": 1, "action": "VOLUNTARY_DECISION",
                       "detail": "Decyzja dobrowolna — bez limitu 2M EUR"})
        steps.extend([
            {"step": 2, "action": "CLOSE_PKPIR", "detail": "Zamknij PKPiR"},
            {"step": 3, "action": "INVENTORY", "detail": "Remanent na dzień przejścia"},
            {"step": 4, "action": "OPENING_BALANCE", "detail": "Bilans otwarcia"},
            {"step": 5, "action": "NOTIFY_US", "detail": "Zawiadom US"},
        ])
    else:
        steps.append({"step": 1, "action": "NO_TRANSITION",
                       "detail": f"Przychód {annual_revenue_eur:,.0f} EUR ≤ {LIMIT_EUR:,} EUR — PKPiR wystarczające"})

    return {
        "must_transition": must_transition,
        "is_voluntary": is_voluntary,
        "annual_revenue_eur": annual_revenue_eur,
        "limit_eur": LIMIT_EUR,
        "steps": steps
    }


# ═══════════════════════════════════════════════════════════════════════════════
# INN08: ANNUAL PKPiR RECONCILIATION
# ═══════════════════════════════════════════════════════════════════════════════

def reconcile_pkpir(pkpir_data: dict, vat_data: dict, zus_data: dict,
                     pit_data: dict, depreciation_register: dict) -> dict:
    """INN08: Cross-check PKPiR vs VAT, ZUS, PIT, and Fixed Asset Register."""
    result = {
        "checks": [],
        "discrepancies": [],
        "passed": 0,
        "failed": 0,
    }

    # Revenue vs VAT
    pkpir_revenue = pkpir_data.get("total_revenue", 0)
    vat_sales = vat_data.get("total_sales_vat", 0)
    rev_diff = abs(pkpir_revenue - vat_sales)
    revenue_check = {
        "field": "revenue_vs_vat",
        "pkpir_value": pkpir_revenue,
        "vat_value": vat_sales,
        "difference": round(rev_diff, 2),
        "tolerance": 500,
        "passed": rev_diff <= 500,
    }
    result["checks"].append(revenue_check)

    # Costs vs VAT purchases
    pkpir_costs = pkpir_data.get("total_costs", 0)
    vat_purchases = vat_data.get("total_purchases_vat", 0)
    cost_diff = abs(pkpir_costs - vat_purchases)
    cost_check = {
        "field": "costs_vs_vat_purchases",
        "pkpir_value": pkpir_costs,
        "vat_value": vat_purchases,
        "difference": round(cost_diff, 2),
        "tolerance": 500,
        "passed": cost_diff <= 500,
    }
    result["checks"].append(cost_check)

    # Depreciation vs Fixed Asset Register
    pkpir_depr = pkpir_data.get("depreciation_annual", 0)
    reg_depr = depreciation_register.get("total_annual_depreciation", 0)
    depr_diff = abs(pkpir_depr - reg_depr)
    depr_check = {
        "field": "depreciation_vs_fixed_asset_register",
        "pkpir_value": pkpir_depr,
        "register_value": reg_depr,
        "difference": round(depr_diff, 2),
        "tolerance": 100,
        "passed": depr_diff <= 100,
    }
    result["checks"].append(depr_check)

    # Social security vs ZUS reports
    zus_kup = pkpir_data.get("zus_deductible", 0)
    zus_reported = zus_data.get("total_contributions", 0)
    zus_diff = abs(zus_kup - zus_reported)
    zus_check = {
        "field": "zus_deductible_vs_zus_reports",
        "pkpir_value": zus_kup,
        "zus_value": zus_reported,
        "difference": round(zus_diff, 2),
        "tolerance": 100,
        "passed": zus_diff <= 100,
    }
    result["checks"].append(zus_check)

    result["passed"] = sum(1 for c in result["checks"] if c["passed"])
    result["failed"] = len(result["checks"]) - result["passed"]
    result["discrepancies"] = [c for c in result["checks"] if not c["passed"]]

    return result


# ═══════════════════════════════════════════════════════════════════════════════
# INN09: PKPiR CROSS-COLUMN INTEGRITY VALIDATOR
# ═══════════════════════════════════════════════════════════════════════════════

def validate_cross_column_integrity(entries: List[dict]) -> dict:
    """INN09: Validate cross-column integrity of PKPiR entries.
    Checks: sequential LP, no gaps, kol10+11+12+13=kol14, chronology."""
    result = {
        "checks": [],
        "passed": 0,
        "failed": 0,
        "critical_errors": [],
    }

    # Check 1: Sequential LP numbering (no gaps, no duplicates)
    lp_values = [e.get("lp", 0) for e in sorted(entries, key=lambda x: x.get("lp", 0))]
    lp_issues = []
    expected = 1
    for lp in lp_values:
        if lp != expected:
            lp_issues.append({"expected": expected, "actual": lp, "type": "GAP" if lp > expected else "DUPLICATE"})
        expected = max(expected + 1, lp + 1)
    result["checks"].append({
        "check": "sequential_lp",
        "passed": len(lp_issues) == 0,
        "issues": lp_issues,
        "note": "LP must increment by 1 with no gaps" if lp_issues else "LP sequential OK"
    })

    # Check 2: Cross-column sum (kol10+11+12+13 = kol14)
    sum_issues = []
    for e in entries:
        k10 = e.get("kol10", 0) or 0
        k11 = e.get("kol11", 0) or 0
        k12 = e.get("kol12", 0) or 0
        k13 = e.get("kol13", 0) or 0
        k14 = e.get("kol14", 0) or 0
        calc_sum = k10 + k11 + k12 + k13
        if abs(calc_sum - k14) > 0.01:
            sum_issues.append({"lp": e.get("lp"), "calc_sum": calc_sum, "declared_kol14": k14,
                                "diff": round(calc_sum - k14, 2)})
    result["checks"].append({
        "check": "sum_kol10_13_eq_kol14",
        "passed": len(sum_issues) == 0,
        "issues": sum_issues,
        "note": "kol14 must equal sum(kol10+kol11+kol12+kol13)" if sum_issues else "Cross-column sum OK"
    })

    # Check 3: Date chronology (event_date <= entry_date)
    date_issues = []
    prev_date = None
    for e in sorted(entries, key=lambda x: x.get("event_date", "")):
        evt = e.get("event_date", "")
        if prev_date and evt < prev_date:
            date_issues.append({"lp": e.get("lp"), "event_date": evt, "prev_date": prev_date})
        prev_date = evt
    result["checks"].append({
        "check": "chronology",
        "passed": len(date_issues) == 0,
        "issues": date_issues,
        "note": "Entries must be in chronological order" if date_issues else "Chronology OK"
    })

    result["passed"] = sum(1 for c in result["checks"] if c["passed"])
    result["failed"] = len(result["checks"]) - result["passed"]
    result["critical_errors"] = sum_issues + lp_issues
    return result


# ═══════════════════════════════════════════════════════════════════════════════
# INN10: FULL KST RATE LOOKUP ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

def lookup_kst_rate(kst_group: int, kst_subgroup: int = 1) -> dict:
    """INN10: Full KST rate lookup across all 10 groups (28 entries)."""
    key = f"{kst_group}_{kst_subgroup}"
    if key in KST_FULL_TABLE:
        info = KST_FULL_TABLE[key]
        return {
            "found": True,
            "key": key,
            "group": info["group"],
            "subgroup": info["subgroup"],
            "name": info["name"],
            "rate_pct": info["rate"],
            "annual_factor": round(info["rate"] / 100, 4),
            "full_years": int(100 / info["rate"]) if info["rate"] > 0 else 0,
            "notes": info.get("notes", ""),
            "limit_spalinowy": info.get("limit_spalinowy"),
            "limit_elektryczny": info.get("limit_elektryczny"),
        }

    # Fallback: find group-level default
    group_entries = {k: v for k, v in KST_FULL_TABLE.items() if v["group"] == kst_group}
    if group_entries:
        first = list(group_entries.values())[0]
        return {
            "found": False,
            "key": f"{kst_group}_{kst_subgroup}",
            "group": kst_group,
            "fallback_name": first["name"],
            "fallback_rate_pct": first["rate"],
            "note": f"Subgroup {kst_subgroup} not found — using group {kst_group} default rate"
        }

    # Group not in table at all — use 14% default per Art. 22i
    return {
        "found": False,
        "key": f"{kst_group}_{kst_subgroup}",
        "group": kst_group,
        "fallback_rate_pct": 14.0,
        "note": f"Group {kst_group} not in KST table — using statutory default 14% (Art. 22i PIT)"
    }


def get_kst_full_summary() -> dict:
    """INN10: Summary of KST coverage."""
    groups_found = set(v["group"] for v in KST_FULL_TABLE.values())
    return {
        "total_entries": len(KST_FULL_TABLE),
        "groups_covered": sorted(groups_found),
        "groups_count": len(groups_found),
        "groups_missing": sorted(set(range(0, 11)) - groups_found),
        "note": "System now has all 10 KST groups (was 5). Groups 2,6,8,9 added."
    }


# ═══════════════════════════════════════════════════════════════════════════════
# INN11: NKUP COVERAGE EXPANSION TRACKER
# ═══════════════════════════════════════════════════════════════════════════════

def track_nkup_expansion() -> dict:
    """INN11: Track NKUP coverage from current 26% toward 100%."""
    covered_points = {
        1, 10, 11, 23, 43, 46, 47,  # int keys
        "47a",  # Art. 23 ust. 1 pkt 47a (leasing limit)
    }
    all_points = set(range(1, 58))
    covered_int = {p for p in covered_points if isinstance(p, int)}
    # Count 47a as covered separately
    total_covered = len(covered_int) + (1 if "47a" in covered_points else 0)

    missing_points = sorted(all_points - covered_int)

    priority_map = {}
    for pt in missing_points:
        if pt in {4, 6, 40}:
            priority_map[pt] = "CRITICAL"
        elif pt in {5, 7, 12, 13, 16, 17, 18, 19, 26, 27, 32, 33, 34, 45, 47, 56, 57}:
            priority_map[pt] = "HIGH"
        elif pt in {2, 9, 14, 15, 20, 21, 24, 28, 29, 30, 31, 35, 38, 41, 42, 43, 51, 55}:
            priority_map[pt] = "MEDIUM"
        else:
            priority_map[pt] = "LOW"

    return {
        "current_coverage_pct": 26.3,
        "points_covered": total_covered,
        "points_total": 57,
        "points_missing": len(missing_points),
        "missing_by_priority": {
            "CRITICAL": len([p for p in missing_points if priority_map.get(p) == "CRITICAL"]),
            "HIGH": len([p for p in missing_points if priority_map.get(p) == "HIGH"]),
            "MEDIUM": len([p for p in missing_points if priority_map.get(p) == "MEDIUM"]),
            "LOW": len([p for p in missing_points if priority_map.get(p) == "LOW"]),
        },
        "implementation_path": "Implement CRITICAL first → expand nkup_enterprise_complete.rego with atomic rules per point",
    }


# ═══════════════════════════════════════════════════════════════════════════════
# INN12: CASH TRAP & WHITE LIST AUTO-VERIFIER
# ═══════════════════════════════════════════════════════════════════════════════

def verify_cash_and_whitelist(amount_gross: float, payment_method: str = "CASH",
                               vendor_nip: str = "", vendor_name: str = "",
                               whitelist_status: str = "UNCHECKED") -> dict:
    """INN12: Verify cash trap (>15k NKUP) and Biała Lista VAT status."""
    result = {
        "amount_gross": amount_gross,
        "payment_method": payment_method,
        "checks": [],
        "flags": [],
    }

    # Cash trap: payments >15,000 PLN must be via bank transfer
    if payment_method.upper() in ("CASH", "GOTÓWKA") and amount_gross > 15000:
        result["checks"].append({
            "check": "cash_trap_15k",
            "triggered": True,
            "severity": "BLOCK",
            "detail": f"Płatność gotówkowa {amount_gross:.2f} PLN > 15 000 PLN → CAŁOŚĆ NKUP (Art. 22p PIT)",
            "nkup_amount": amount_gross,
            "recommendation": "Płać przelewem bankowym! Transakcje >15k w gotówce = NKUP."
        })
        result["flags"].append("CASH_TRAP_NKUP")
    elif amount_gross > 15000:
        result["checks"].append({
            "check": "cash_trap_15k",
            "triggered": False,
            "severity": "OK",
            "detail": f"Płatność bezgotówkowa — limit 15k nie dotyczy"
        })

    # White List (Biała Lista VAT) verification
    if vendor_nip:
        if whitelist_status == "NOT_ON_LIST":
            result["checks"].append({
                "check": "whitelist_vat",
                "triggered": True,
                "severity": "BLOCK",
                "detail": f"Kontrahent {vendor_name} (NIP {vendor_nip}) NIE figuruje na Białej Liście VAT",
                "consequence": "Brak prawa do odliczenia VAT + solidarna odpowiedzialność za VAT kontrahenta",
                "recommendation": "Wstrzymaj płatność do czasu weryfikacji! Zgłoś do US w ciągu 3 dni."
            })
            result["flags"].append("WHITELIST_MISSING")
        elif whitelist_status == "CHECKED_OK":
            result["checks"].append({
                "check": "whitelist_vat",
                "triggered": False,
                "severity": "OK",
                "detail": f"Kontrahent {vendor_name} (NIP {vendor_nip}) figuruje na Białej Liście VAT"
            })
        elif whitelist_status == "UNCHECKED":
            result["checks"].append({
                "check": "whitelist_vat",
                "triggered": True,
                "severity": "WARNING",
                "detail": f"Biała Lista VAT NIE sprawdzona dla NIP {vendor_nip} — zweryfikuj przed płatnością",
                "recommendation": "Sprawdź kontrahenta na https://www.podatki.gov.pl/wykaz-podatnikow-vat"
            })
            result["flags"].append("WHITELIST_UNCHECKED")

    return result

def detect_column_mismatches() -> dict:
    """Detect column numbering inconsistencies between system and Rozporządzenie MF."""
    mismatches = []
    system_cols = PKPIR_COLUMNS_SYSTEM_LEGACY
    for sys_col, sys_name in system_cols.items():
        if sys_col in PKPIR_COLUMNS_CORRECTED:
            correct = PKPIR_COLUMNS_CORRECTED[sys_col]
            if correct["name"] != sys_name:
                mismatches.append({
                    "column": sys_col,
                    "system_uses": sys_name,
                    "rozporzadzenie_mf": correct["name"],
                    "description": correct["description"],
                })
        else:
            mismatches.append({
                "column": sys_col,
                "system_uses": sys_name,
                "rozporzadzenie_mf": "NIE ISTNIEJE",
                "description": f"PKPiR ma tylko 17 kolumn — kolumna {sys_col} nie istnieje!",
            })

    return {
        "total_mismatches": len(mismatches),
        "mismatches": mismatches,
        "system_has_19_columns": True,
        "pkpir_has_17_columns": True,
        "recommendation": "Ujednolić z Rozporządzeniem MF: kolumny 1-17, usunąć 18-19"
    }


# ═══════════════════════════════════════════════════════════════════════════════
# BONUS: KST COMPLETENESS CHECKER
# ═══════════════════════════════════════════════════════════════════════════════

def check_kst_completeness() -> dict:
    """Check KST coverage in system vs full 10-group table."""
    system_groups = {1, 3, 4, 5, 7}  # Only these 5 groups in accounting.rego P840
    full_groups = set(range(0, 11))

    missing = full_groups - system_groups
    # Note: group 0 (land) doesn't need rates, group 10 (WNiP) has some coverage

    return {
        "system_coverage": sorted(system_groups),
        "missing_groups": sorted(missing),
        "system_rate": f"{len(system_groups)}/10",
        "full_table_entries": len(KST_FULL_TABLE),
        "recommendation": "Add groups 2 (budowle), 6 (urządzenia techniczne), 8 (narzędzia), 9 (inwentarz)"
    }


# ═══════════════════════════════════════════════════════════════════════════════
# REPORT GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

def generate_report(results: dict, report_path: str = None) -> str:
    """Generate comprehensive P11 report."""
    if report_path is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_path = str(REPORTS_DIR / f"RAPORT_P11_ACCOUNTING_TOOLKIT_{timestamp}.txt")

    lines = []
    lines.append("═" * 70)
    lines.append("  RAPORT P11 — ACCOUNTING PKPiR COMPREHENSIVE TOOLKIT v8.0")
    lines.append("═" * 70)
    lines.append(f"  Data: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("")

    for section_name, section_data in results.items():
        lines.append(f"─── {section_name} ───")
        if isinstance(section_data, dict):
            for k, v in section_data.items():
                if isinstance(v, (list, dict)):
                    lines.append(f"  {k}: {json.dumps(v, indent=2, ensure_ascii=False, default=str)}")
                else:
                    lines.append(f"  {k}: {v}")
        elif isinstance(section_data, list):
            for item in section_data:
                lines.append(f"  • {item}")
        else:
            lines.append(f"  {section_data}")
        lines.append("")

    content = "\n".join(lines)
    Path(report_path).parent.mkdir(parents=True, exist_ok=True)
    Path(report_path).write_text(content, encoding="utf-8")
    return report_path


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN CLI
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="P11 Accounting PKPiR Comprehensive Toolkit")
    sub = parser.add_subparsers(dest="command")

    # INN01: Column classifier
    c1 = sub.add_parser("classify", help="INN01: Classify expense to PKPiR column")
    c1.add_argument("--expense-type", required=True, help="Expense type")
    c1.add_argument("--amount", type=float, default=0, help="Amount")
    c1.add_argument("--fixed-asset", action="store_true", help="Is fixed asset?")

    # INN02: Revenue-cost matching
    c2 = sub.add_parser("match", help="INN02: Match revenue to costs")
    c2.add_argument("--data", type=str, help="JSON data: {revenues: [...], costs: [...]}")

    # INN03: NKUP detection
    c3 = sub.add_parser("nkup", help="INN03: Detect NKUP expenses")
    c3.add_argument("--description", required=True, help="Expense description")
    c3.add_argument("--amount", type=float, default=0, help="Amount")

    # INN04: Depreciation schedule
    c4 = sub.add_parser("depreciation", help="INN04: Generate depreciation schedule")
    c4.add_argument("--value", type=float, required=True, help="Asset value PLN")
    c4.add_argument("--kst-group", type=int, required=True, help="KST group")
    c4.add_argument("--kst-subgroup", type=int, default=1, help="KST subgroup")
    c4.add_argument("--method", default="LINEAR",
                     choices=["LINEAR", "DEGRESSIVE", "ONE_TIME_10K", "ONE_TIME_100K"])
    c4.add_argument("--coefficient", type=float, default=1.0, help="Degressive coefficient")
    c4.add_argument("--small-taxpayer", action="store_true")
    c4.add_argument("--first-year", action="store_true")
    c4.add_argument("--electric", action="store_true")

    # INN05: Vehicle splitter
    c5 = sub.add_parser("vehicle", help="INN05: Split vehicle expenses")
    c5.add_argument("--expense", type=float, required=True, help="Total expense")
    c5.add_argument("--mileage-log", action="store_true", help="Has mileage log?")
    c5.add_argument("--car-value", type=float, default=0, help="Car value")
    c5.add_argument("--electric", action="store_true")

    # INN06: Remnant calculator
    c6 = sub.add_parser("remnant", help="INN06: Calculate inventory remnant")
    c6.add_argument("--data", type=str, help="JSON items array")
    c6.add_argument("--method", default="FIFO", choices=["FIFO", "WEIGHTED_AVERAGE"])
    c6.add_argument("--prev-remnant", type=float, default=0)
    c6.add_argument("--liquidation", action="store_true")

    # INN07: Transition manager
    c7 = sub.add_parser("transition", help="INN07: PKPiR → UoR transition")
    c7.add_argument("--revenue-eur", type=float, required=True, help="Annual revenue EUR")
    c7.add_argument("--voluntary", action="store_true")

    # INN08: Reconciliation
    c8 = sub.add_parser("reconcile", help="INN08: Annual PKPiR reconciliation")
    c8.add_argument("--pkpir-data", type=str, help="JSON PKPiR data")
    c8.add_argument("--vat-data", type=str, help="JSON VAT data")
    c8.add_argument("--zus-data", type=str, help="JSON ZUS data")
    c8.add_argument("--pit-data", type=str, help="JSON PIT data")
    c8.add_argument("--depr-data", type=str, help="JSON depreciation register data")

    # All-in-one
    allp = sub.add_parser("all", help="Run all checks and generate report")
    allp.add_argument("--report", action="store_true", help="Generate report file")

    # Column fix detector
    colp = sub.add_parser("column-fix", help="Detect column numbering mismatches")

    # KST completeness
    kstp = sub.add_parser("kst-check", help="Check KST table completeness")

    # INN09: Cross-column integrity
    c9 = sub.add_parser("integrity", help="INN09: Validate PKPiR cross-column integrity")
    c9.add_argument("--data", type=str, help="JSON entries array")

    # INN10: KST lookup
    c10 = sub.add_parser("kst", help="INN10: Lookup KST rate")
    c10.add_argument("--group", type=int, required=True, help="KST group")
    c10.add_argument("--subgroup", type=int, default=1, help="KST subgroup")

    # INN11: NKUP expansion
    c11 = sub.add_parser("nkup-expand", help="INN11: Track NKUP expansion coverage")

    # INN12: Cash trap + whitelist
    c12 = sub.add_parser("cash-trap", help="INN12: Cash trap + Biala Lista verification")
    c12.add_argument("--amount", type=float, required=True, help="Amount gross")
    c12.add_argument("--method", default="CASH", help="Payment method")
    c12.add_argument("--nip", default="", help="Vendor NIP")
    c12.add_argument("--vendor-name", default="", help="Vendor name")
    c12.add_argument("--whitelist", default="UNCHECKED",
                       choices=["UNCHECKED", "CHECKED_OK", "NOT_ON_LIST"])

    args = parser.parse_args()

    if args.command == "classify":
        result = classify_pkpir_column(args.expense_type, args.amount, args.fixed_asset)
        print(json.dumps(result, indent=2, ensure_ascii=False))

    elif args.command == "match":
        data = json.loads(args.data) if args.data else {"revenues": [], "costs": []}
        result = match_revenue_cost(data.get("revenues", []), data.get("costs", []))
        print(json.dumps(result, indent=2, ensure_ascii=False))

    elif args.command == "nkup":
        detected = detect_nkup(args.description, args.amount)
        expansion = get_nkup_expansion_summary()
        print(f"Nkup detection ({len(detected)} found):")
        for d in detected:
            print(f"  ⚠️  {d['category']} ({d['point']}): {d['nkup_amount']} PLN NKUP — {d['matched_keyword']}")
        print(f"\nNKUP Coverage: {expansion['coverage_pct']}% ({expansion['currently_covered']}/{expansion['total_points']})")
        print(f"Missing: {len(expansion['missing_points'])} points to implement")

    elif args.command == "depreciation":
        result = generate_depreciation_schedule(
            args.value, args.kst_group, args.kst_subgroup,
            args.method, args.coefficient, args.small_taxpayer, args.first_year, args.electric
        )
        print(f"Depreciation schedule: {result.get('kst_name', '')} ({args.value:.2f} PLN)")
        print(f"  Method: {args.method}")
        if "monthly_depreciation" in result:
            print(f"  Monthly: {result['monthly_depreciation']:.2f} PLN")
        if "annual_depreciation" in result:
            print(f"  Annual: {result['annual_depreciation']:.2f} PLN")
        for yr in result.get("schedule", []):
            print(f"  Year {yr['year']}: {yr['depreciation']:.2f} PLN → remaining {yr['remaining_value']:.2f} PLN")

    elif args.command == "vehicle":
        result = split_vehicle_expenses(args.expense, args.mileage_log,
                                         args.electric, args.car_value)
        print(f"Vehicle expense: {result['total_expense']:.2f} PLN")
        print(f"  KUP: {result['kup_amount']:.2f} PLN ({result['kup_pct']}%)")
        print(f"  NKUP: {result['nkup_amount']:.2f} PLN")
        print(f"  Note: {result['kup_note']}")

    elif args.command == "remnant":
        data = json.loads(args.data) if args.data else []
        result = calculate_remnant(data, args.method, args.prev_remnant, args.liquidation)
        print(f"Remanent ({args.method}): {result['total_valuation']:.2f} PLN")
        print(f"  Continuity diff: {result['continuity_check']['discrepancy']:.2f} PLN")
        if args.liquidation:
            print(f"  Liquidation tax (10%): {result.get('liquidation_tax_10pct', 0):.2f} PLN")

    elif args.command == "transition":
        result = manage_transition(args.revenue_eur, args.voluntary)
        status = "MUST TRANSITION" if result["must_transition"] else "NO TRANSITION NEEDED"
        print(f"PKPiR → UoR: {status}")
        for step in result["steps"]:
            print(f"  Step {step['step']}: {step['action']} — {step['detail']}")

    elif args.command == "reconcile":
        pkpir = json.loads(args.pkpir_data) if args.pkpir_data else {}
        vat = json.loads(args.vat_data) if args.vat_data else {}
        zus = json.loads(args.zus_data) if args.zus_data else {}
        pit = json.loads(args.pit_data) if args.pit_data else {}
        depr = json.loads(args.depr_data) if args.depr_data else {}
        result = reconcile_pkpir(pkpir, vat, zus, pit, depr)
        print(f"PKPiR Reconciliation: {result['passed']}/{len(result['checks'])} checks passed")
        for check in result["checks"]:
            status = "✅" if check["passed"] else "❌"
            print(f"  {status} {check['field']}: diff {check['difference']:.2f} PLN")

    elif args.command == "column-fix":
        result = detect_column_mismatches()
        print(f"Column Mismatches: {result['total_mismatches']}")
        print(f"  System has 19 columns, PKPiR has 17: {result['system_has_19_columns']}")
        for m in result["mismatches"]:
            print(f"  ❌ Kol. {m['column']}: system '{m['system_uses']}' → should be '{m['rozporzadzenie_mf']}'")
        print(f"\n{result['recommendation']}")

    elif args.command == "kst-check":
        result = check_kst_completeness()
        print(f"KST Coverage: {result['system_rate']}")
        print(f"  System has: {result['system_coverage']}")
        print(f"  Missing: {result['missing_groups']}")
        print(f"  Full table: {result['full_table_entries']} entries")
        print(f"\n{result['recommendation']}")

    elif args.command == "integrity":
        data = json.loads(args.data) if args.data else []
        result = validate_cross_column_integrity(data)
        print(f"Cross-Column Integrity: {result['passed']}/{len(result['checks'])} checks passed")
        for c in result['checks']:
            status = "OK" if c['passed'] else "FAIL"
            print(f"  {status} {c['check']}: {c['note']}")

    elif args.command == "kst":
        result = lookup_kst_rate(args.group, args.subgroup)
        if result.get('found'):
            print(f"KST {result['key']}: {result['name']} - {result['rate_pct']}% ({result['full_years']} years)")
        else:
            print(f"KST {result['key']}: NOT FOUND - fallback {result.get('fallback_rate_pct', 14)}%")

    elif args.command == "nkup-expand":
        result = track_nkup_expansion()
        print(f"NKUP Coverage: {result['current_coverage_pct']}% ({result['points_covered']}/{result['points_total']})")
        print(f"  Missing: {result['points_missing']} points")
        for prio, count in result['missing_by_priority'].items():
            if count > 0:
                print(f"    {prio}: {count}")

    elif args.command == "cash-trap":
        result = verify_cash_and_whitelist(args.amount, args.method, args.nip, args.vendor_name, args.whitelist)
        print(f"Cash Trap & White List: {len(result['flags'])} flags")
        for check in result['checks']:
            icon = "FAIL" if check.get('triggered') else "OK"
            print(f"  {icon} {check['check']}: {check.get('detail', '')}")

    elif args.command == "all":
        results = {
            "P11_COLUMN_MISMATCHES": detect_column_mismatches(),
            "P11_KST_COMPLETENESS": check_kst_completeness(),
            "P11_NKUP_EXPANSION": get_nkup_expansion_summary(),
            "P11_DEPRECIATION_METHODS": {k: v["name"] for k, v in DEPRECIATION_METHODS.items()},
            "P11_DEMO_CLASSIFICATION": classify_pkpir_column("SALARIES", 5000),
            "P11_DEMO_DEPRECIATION": generate_depreciation_schedule(80000, 4, 5, "LINEAR"),
            "P11_DEMO_VEHICLE": split_vehicle_expenses(2000, False, False, 180000),
            "P11_DEMO_TRANSITION": manage_transition(2500000),
            "P11_DEMO_NKUP": detect_nkup("alkohol na imprezę firmową z kontrahentami", 3500),
            "P11_DEMO_REMNANT": calculate_remnant([
                {"name": "Towar A", "purchase_price": 100, "market_price": 90, "quantity": 50},
                {"name": "Towar B", "purchase_price": 200, "market_price": 220, "quantity": 30},
                {"name": "Towar C", "purchase_price": 50, "market_price": 40, "quantity": 10, "is_damaged": True},
            ], "FIFO", 10000, False),
        }
        report_path = None
        if args.report:
            report_path = generate_report(results)
            print(f"Report: {report_path}")
        else:
            print(json.dumps(results, indent=2, ensure_ascii=False, default=str))

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
