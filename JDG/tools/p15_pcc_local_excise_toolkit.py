#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — P15 PCC + Local Taxes + Excise Toolkit v1.0
═══════════════════════════════════════════════════════════════════════════════

12 innowacji Enterprise P15:
  INN01: PCC Auto-Detection Engine
  INN02: PCC-3 Auto-Filler
  INN03: Real Estate Tax Classifier
  INN04: Excise Warehouse Tracker
  INN05: Transport Tax Auto-Calculator
  INN06: PCC Exemption Analyzer
  INN07: Multi-Tax Local Calendar
  INN08: Excise Suspension Procedure Manager
  INN09: Property Tax Appeal Auto-Drafter
  INN10: Local Tax Rate Auto-Updater
  INN11: Cross-Border Excise Compliance
  INN12: PCC + VAT Exclusion Firewall

Użycie:
    python JDG/tools/p15_pcc_local_excise_toolkit.py all --report
    python JDG/tools/p15_pcc_local_excise_toolkit.py pcc-detect --amount 50000 --type CAR
    python JDG/tools/p15_pcc_local_excise_toolkit.py calendar

Autor: NexusAI
Data: 2026-07-29
"""

import argparse, json, sys
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# ═══ 2026 Rates & Thresholds ═══
MIN_WAGE = 4666.00
CURRENT_DZU = "Dz.U. 2024 poz. 628 t.j."

# ── PCC Rates ──
PCC_RATES = {
    "SALE_MOVABLE": {"rate_pct": 2.0, "threshold_exempt": 1000, "declaration": "PCC-3", "deadline_days": 14},
    "SALE_REAL_ESTATE": {"rate_pct": 2.0, "threshold_exempt": 0, "declaration": "PCC-3", "deadline_days": 14},
    "SALE_VEHICLE_PRIVATE": {"rate_pct": 2.0, "threshold_exempt": 1000, "declaration": "PCC-3", "deadline_days": 14},
    "LOAN": {"rate_pct": 0.5, "threshold_exempt": 1000, "declaration": "PCC-3", "deadline_days": 14},
    "LOAN_FAMILY": {"rate_pct": 0.0, "threshold_exempt": 36120, "declaration": "PCC-3", "deadline_days": 14, "note": "Zwolnione do 36 120 PLN — zgłoś w 6 mies."},
    "SHARE_PURCHASE": {"rate_pct": 1.0, "threshold_exempt": 0, "declaration": "PCC-3", "deadline_days": 14},
    "COMPANY_FORMATION": {"rate_pct": 0.5, "threshold_exempt": 0, "declaration": "PCC-3", "deadline_days": 14},
    "EXCHANGE": {"rate_pct": 1.0, "threshold_exempt": 0, "declaration": "PCC-3", "deadline_days": 14},
    "MORTGAGE": {"rate_pct": 0.1, "threshold_exempt": 0, "declaration": "PCC-3", "deadline_days": 14},
    "DONATION": {"rate_pct": 0.0, "threshold_exempt": 0, "declaration": "SD-3", "deadline_days": 180, "note": "NIE PCC — podlega SD"},
}

# ── Real Estate Tax Rates (2026) ──
REAL_ESTATE_RATES = {
    "LAND_BUSINESS": 1.43,
    "LAND_OTHER": 0.71,
    "BUILDING_BUSINESS": 33.10,
    "BUILDING_RESIDENTIAL": 1.15,
    "CONSTRUCTION_PCT": 2.0,
}

# ── Transport Tax (2026) ──
TRANSPORT_TAX = {
    "TRUCK_3_5_TO_5_5": 800,
    "TRUCK_5_5_TO_9": 1000,
    "TRUCK_9_TO_12": 1400,
    "TRUCK_OVER_12": 2000,
    "TRACTOR_UNIT": 2300,
    "BUS_UNDER_22": 1600,
    "BUS_OVER_22": 2400,
    "TRAILER_UNDER_12": 1200,
    "TRAILER_OVER_12_3AX": 1800,
}

# ── Excise Rates (2026 per 1000L/kg/hl) ──
EXCISE_RATES = {
    "GASOLINE": 1659,
    "DIESEL": 1319,
    "LPG": 700,
    "CNG": 449,
    "HEATING_OIL_LIGHT": 64,
    "SPIRITS_PER_HL_100PCT": 8700,
    "BEER_PER_HL_PLATO": 9.29,
    "WINE_PER_HL": 216,
    "CIDER_PER_HL": 108,
    "CIGARETTES_AD_VALOREM_PCT": 32,
    "CIGARETTES_SPECIFIC_PER_1000": 105,
    "CIGARS_PER_1000": 595,
    "SMOKING_TOBACCO_PER_KG": 300,
    "ENERGY_PER_MWH": 5.00,
}

# ── Multi-Tax Calendar ──
TAX_CALENDAR = [
    {"month": 1, "day": 31, "tax": "DN-1 (podatek od nieruchomości)", "form": "DN-1"},
    {"month": 2, "day": 15, "tax": "DT-1 (podatek od transportu) I rata", "form": "DT-1"},
    {"month": 2, "day": 28, "tax": "PIT-28 (ryczałt)", "form": "PIT-28"},
    {"month": 3, "day": 15, "tax": "DN-1 — I rata", "form": "DN-1"},
    {"month": 3, "day": 15, "tax": "BDO raport roczny", "form": "BDO"},
    {"month": 3, "day": 31, "tax": "Opłata środowiskowa (Urząd Marszałkowski)", "form": "OŚ"},
    {"month": 4, "day": 30, "tax": "PIT-36/PIT-36L", "form": "PIT"},
    {"month": 5, "day": 15, "tax": "DN-1 — II rata", "form": "DN-1"},
    {"month": 9, "day": 15, "tax": "DT-1 — II rata", "form": "DT-1"},
    {"month": 9, "day": 15, "tax": "DN-1 — III rata", "form": "DN-1"},
    {"month": 11, "day": 15, "tax": "DN-1 — IV rata", "form": "DN-1"},
    {"month": None, "day": 25, "tax": "AKC-4 (akcyza — miesięcznie)", "form": "AKC-4"},
    {"month": None, "day": 25, "tax": "VAT-7 / JPK_V7 (miesięcznie)", "form": "JPK_V7"},
    {"month": None, "day": 14, "tax": "PCC-3 (14 dni od transakcji)", "form": "PCC-3"},
]


class P15Toolkit:
    """P15 PCC + Local Taxes + Excise Toolkit — 12 innovations."""

    # ── INN01: PCC Auto-Detection Engine ──
    def detect_pcc_obligation(self, amount, transaction_type, is_vat_invoice=False, from_vat_payer=False):
        pcc_applies = not is_vat_invoice and not from_vat_payer
        rate_info = PCC_RATES.get(transaction_type, PCC_RATES["SALE_MOVABLE"])
        if amount < 0:
            raise ValueError("amount must be non-negative")
        threshold = rate_info["threshold_exempt"]
        exempt_by_value = threshold > 0 and amount <= threshold
        taxable = amount if not exempt_by_value else 0
        pcc_tax = round(taxable * rate_info["rate_pct"] / 100, 2)
        exempt = exempt_by_value or not pcc_applies

        return {
            "amount": amount,
            "transaction_type": transaction_type,
            "pcc_applies": pcc_applies,
            "pcc_rate_pct": rate_info["rate_pct"],
            "taxable_amount": taxable,
            "pcc_tax_pln": pcc_tax if not exempt else 0,
            "is_exempt": exempt,
            "exemption_reason": "ZWOLNIONE — kwota w progu ustawowym" if exempt_by_value else "VAT wyłącza PCC (Art. 2 pkt 4)" if not pcc_applies else "NIE — podlega PCC",
            "declaration": rate_info["declaration"],
            "deadline_days": rate_info["deadline_days"],
            "legal_basis": "Art. 1-7 Ustawy o PCC",
            "note": rate_info.get("note", ""),
            "urgent": pcc_tax > 5000 and not exempt,
        }

    # ── INN02: PCC-3 Auto-Filler ──
    def fill_pcc3(self, buyer_name="Jan Kowalski", buyer_nip="", seller_name="", transaction_type="SALE_VEHICLE", amount=0, transaction_date=None):
        tdate = transaction_date or date.today().isoformat()
        deadline_date = date.fromisoformat(tdate) + timedelta(days=14)
        detection = self.detect_pcc_obligation(amount, transaction_type)
        pcc_tax = detection["pcc_tax_pln"]

        form = f"""PCC-3 — DEKLARACJA PCC
─────────────────────────────────────────────
A. MIEJSCE SKŁADANIA: US właściwy dla kupującego
B. DANE KUPUJĄCEGO:
   Nazwisko/Imię: {buyer_name}
   NIP: {buyer_nip or '[WSTAW NIP]'}
C. DANE SPRZEDAWCY:
   Nazwisko/Imię: {seller_name or '[WSTAW DANE SPRZEDAWCY]'}
D. TRANSAKCJA:
   Typ: {transaction_type}
   Data zawarcia umowy: {tdate}
   Wartość rynkowa: {amount:,.2f} PLN
   Stawka PCC: {detection['pcc_rate_pct']}%
   Należny PCC: {pcc_tax:,.2f} PLN
E. TERMIN: Złóż do {deadline_date.isoformat()} (14 dni!)
F. PODSTAWA PRAWNA: Art. 10 Ustawy o PCC
─────────────────────────────────────────────
⚠️ Opóźnienie = odsetki + potencjalna kara KKS!
"""
        return {
            "pcc_tax_pln": pcc_tax,
            "deadline": deadline_date.isoformat(),
            "days_remaining": (deadline_date - date.today()).days,
            "form_content": form.strip(),
            "legal_basis": "Art. 10 Ustawy o PCC",
        }

    # ── INN03: Real Estate Tax Classifier ──
    def classify_property(self, area_m2, is_business, is_residential=False, is_mixed=False, business_pct=0):
        land_rate = REAL_ESTATE_RATES["LAND_OTHER"]
        bldg_rate = REAL_ESTATE_RATES["BUILDING_RESIDENTIAL"]
        biz_tax = 0
        priv_tax = 0
        biz_m2 = 0
        priv_m2 = 0

        if is_business:
            land_rate = REAL_ESTATE_RATES["LAND_BUSINESS"]
            bldg_rate = REAL_ESTATE_RATES["BUILDING_BUSINESS"]
            biz_m2 = area_m2
            biz_tax = round(area_m2 * bldg_rate + area_m2 * 0.1 * land_rate, 2)
        elif is_residential:
            priv_m2 = area_m2
            priv_tax = round(area_m2 * bldg_rate + area_m2 * 0.1 * land_rate, 2)
        elif is_mixed:
            biz_m2 = area_m2 * business_pct / 100
            priv_m2 = area_m2 - biz_m2
            biz_tax = round(biz_m2 * REAL_ESTATE_RATES["BUILDING_BUSINESS"] + biz_m2 * 0.1 * REAL_ESTATE_RATES["LAND_BUSINESS"], 2)
            priv_tax = round(priv_m2 * REAL_ESTATE_RATES["BUILDING_RESIDENTIAL"], 2)
            land_rate = REAL_ESTATE_RATES["LAND_BUSINESS"]
            bldg_rate = REAL_ESTATE_RATES["BUILDING_BUSINESS"]

        annual_tax = round(biz_tax + priv_tax, 2) if (is_mixed or is_business or is_residential) else round(area_m2 * bldg_rate + area_m2 * 0.1 * land_rate, 2)
        if is_mixed:
            annual_tax = round(biz_tax + priv_tax, 2)
        elif is_business:
            annual_tax = biz_tax
        else:
            annual_tax = priv_tax if is_residential else round(area_m2 * bldg_rate + area_m2 * 0.1 * land_rate, 2)
            annual_tax = max(annual_tax, 0)

        ptype = "MIESZANA" if is_mixed else ("FIRMOWA" if is_business else "MIESZKALNA")

        return {
            "property_type": ptype,
            "area_m2": area_m2,
            "is_mixed": is_mixed,
            "business_area_m2": round(biz_m2, 1),
            "private_area_m2": round(priv_m2, 1),
            "business_pct": business_pct if is_mixed else (100 if is_business else 0),
            "land_rate_pln_per_m2": land_rate,
            "building_rate_pln_per_m2": bldg_rate,
            "business_tax_pln": biz_tax,
            "private_tax_pln": priv_tax,
            "annual_tax_pln": annual_tax,
            "quarterly_installment": round(annual_tax / 4, 2) if annual_tax > 0 else 0,
            "declaration": "DN-1" if (is_business or is_mixed) else "BRAK (mieszkalna)",
            "dn1_deadline": "14 dni od nabycia/zmiany",
            "payment_schedule": ["15 marca", "15 maja", "15 września", "15 listopada"],
            "kup_deductible": is_business or is_mixed,
            "kup_pct": business_pct if is_mixed else (100 if is_business else 0),
            "rate_warning": f"Stawka firmowa {REAL_ESTATE_RATES['BUILDING_BUSINESS']} PLN/m² vs prywatna {REAL_ESTATE_RATES['BUILDING_RESIDENTIAL']} PLN/m² — różnica {REAL_ESTATE_RATES['BUILDING_BUSINESS']/REAL_ESTATE_RATES['BUILDING_RESIDENTIAL']:.0f}×!" if (is_business or is_mixed) else "",
            "legal_basis": "Ustawa o podatkach i opłatach lokalnych",
        }

    # ── INN04: Excise Warehouse Tracker ──
    def track_excise_warehouse(self, excise_category, requires_warehouse=True, has_warehouse=False, has_security=False):
        if not requires_warehouse and excise_category not in ("ALCOHOL", "TOBACCO"):
            return {"status": "NIE WYMAGA składu podatkowego", "ok": True}

        missing = []
        if not has_warehouse:
            missing.append("skład podatkowy")
        if not has_security:
            missing.append("zabezpieczenie akcyzowe")

        ok = len(missing) == 0

        return {
            "excise_category": excise_category,
            "requires_warehouse": requires_warehouse,
            "has_warehouse": has_warehouse,
            "has_security": has_security,
            "status": "✅ KOMPLETNY" if ok else f"❌ BRAK: {', '.join(missing)}",
            "missing": missing,
            "ok": ok,
            "routing": "OK" if ok else "BLOCK_AND_ALERT",
            "declaration": "AKC-4",
            "deadline": "25. dnia następnego miesiąca",
            "legal_basis": "Art. 38-48, 63-76 Ustawy o podatku akcyzowym",
        }

    # ── INN05: Transport Tax Auto-Calculator ──
    def calculate_transport_tax(self, dmc_kg, vehicle_type="TRUCK", seats=0, is_ev=False, is_historic=False):
        if is_ev or is_historic:
            return {"transport_tax_pln": 0, "exempt": True, "exempt_reason": "EV / zabytek — zwolniony", "declaration": "DT-1 (deklaracja zerowa)"}

        if vehicle_type == "TRACTOR_UNIT":
            tax = TRANSPORT_TAX["TRACTOR_UNIT"]
        elif vehicle_type == "BUS":
            tax = TRANSPORT_TAX["BUS_UNDER_22"] if seats < 22 else TRANSPORT_TAX["BUS_OVER_22"]
        elif vehicle_type == "TRAILER":
            tax = TRANSPORT_TAX["TRAILER_UNDER_12"] if dmc_kg / 1000 <= 12 else TRANSPORT_TAX["TRAILER_OVER_12_3AX"]
        else:
            if dmc_kg <= 3500:
                return {"transport_tax_pln": 0, "exempt": True, "exempt_reason": "DMC ≤ 3.5t — nie podlega", "declaration": "BRAK"}
            elif dmc_kg <= 5500:
                tax = TRANSPORT_TAX["TRUCK_3_5_TO_5_5"]
            elif dmc_kg <= 9000:
                tax = TRANSPORT_TAX["TRUCK_5_5_TO_9"]
            elif dmc_kg <= 12000:
                tax = TRANSPORT_TAX["TRUCK_9_TO_12"]
            else:
                tax = TRANSPORT_TAX["TRUCK_OVER_12"]

        return {
            "transport_tax_pln": tax,
            "exempt": False,
            "dmc_kg": dmc_kg,
            "vehicle_type": vehicle_type,
            "declaration": "DT-1",
            "deadline": "15 lutego",
            "installments": [f"15 lutego: {tax/2:.0f} PLN", f"15 września: {tax/2:.0f} PLN"],
            "kup_deductible": True,
            "legal_basis": "Art. 8-14 UoPiOL",
        }

    # ── INN06: PCC Exemption Analyzer ──
    def analyze_pcc_exemptions(self, amount, transaction_type, is_family=False, is_vat=False, from_vat_payer=False):
        exemptions = []
        exempt = False

        if amount <= 1000:
            exemptions.append("Kwota ≤ 1000 PLN — zwolnione (Art. 9 pkt 1)")
            exempt = True

        if is_vat or from_vat_payer:
            exemptions.append("Transakcja VAT — PCC wyłączone (Art. 2 pkt 4)")
            exempt = True

        if transaction_type == "LOAN" and is_family and amount <= 36120:
            exemptions.append("Pożyczka rodzinna ≤ 36 120 PLN — zwolniona (zgłoszenie SD-3 w 6 mies.)")
            exempt = True

        if transaction_type == "DONATION":
            exemptions.append("Darowizna NIE podlega PCC — podlega SD (SD-3)")
            exempt = True

        return {
            "amount": amount,
            "transaction_type": transaction_type,
            "exempt": exempt,
            "exemptions": exemptions if exemptions else ["BRAK — podlega PCC"],
            "pcc_possible": not exempt,
            "legal_basis": "Art. 2 pkt 4, Art. 9 Ustawy o PCC",
        }

    # ── INN07: Multi-Tax Local Calendar ──
    def generate_tax_calendar(self, year=2026):
        today = date.today()
        events = []
        for evt in TAX_CALENDAR:
            if evt["month"] is None:
                # Monthly events
                for m in range(1, 13):
                    try:
                        event_date = date(year, m, min(evt["day"], 28))
                    except ValueError:
                        event_date = date(year, m, 28)
                    days_left = (event_date - today).days
                    events.append({
                        "date": event_date.isoformat(),
                        "tax": evt["tax"],
                        "form": evt["form"],
                        "days_remaining": days_left,
                        "status": "OVERDUE" if days_left < 0 else "DUE_SOON" if days_left <= 14 else "OK",
                        "period": f"{m:02d}/{year}",
                    })
            else:
                event_date = date(year, evt["month"], evt["day"])
                days_left = (event_date - today).days
                if days_left < 0:
                    event_date = date(year + 1 if event_date.month < today.month else year, evt["month"], evt["day"])
                    days_left = (event_date - today).days
                events.append({
                    "date": event_date.isoformat(),
                    "tax": evt["tax"],
                    "form": evt["form"],
                    "days_remaining": days_left,
                    "status": "OVERDUE" if days_left < 0 else "DUE_SOON" if days_left <= 14 else "OK",
                    "period": str(year),
                })

        events.sort(key=lambda x: x["days_remaining"])
        upcoming = [e for e in events if e["status"] != "OVERDUE"][:10]
        overdue = [e for e in events if e["status"] == "OVERDUE"]

        return {
            "total_events": len(events),
            "overdue_count": len(overdue),
            "upcoming": upcoming,
            "overdue": overdue[:5] if overdue else [],
            "year": year,
        }

    # ── INN08: Excise Suspension Procedure Manager ──
    def manage_excise_suspension(self, excise_category, monthly_volume, has_warehouse=True, has_security=True, has_e_dd=True):
        is_valid = has_warehouse and has_security and has_e_dd
        steps = []
        if not has_warehouse:
            steps.append("1. Złóż wniosek o zezwolenie na prowadzenie składu podatkowego (AKC-R)")
        if not has_security:
            steps.append("2. Ustanów zabezpieczenie generalne (gwarancja bankowa lub depozyt)")
        if not has_e_dd:
            steps.append("3. Zarejestruj się w systemie e-DD / SENT")

        if is_valid:
            steps = [
                "✅ Skład podatkowy aktywny",
                "✅ Zabezpieczenie akcyzowe ustanowione",
                "✅ e-DD / SENT zarejestrowane",
                "Harmonogram: AKC-4 do 25. każdego miesiąca",
                f"Szacowana miesięczna akcyza: ~{monthly_volume:,.2f} PLN",
            ]

        return {
            "excise_category": excise_category,
            "suspension_valid": is_valid,
            "monthly_volume_est": monthly_volume,
            "steps": steps,
            "declaration": "AKC-4",
            "declaration_deadline": "25. dnia następnego miesiąca",
            "legal_basis": "Art. 40-48 Ustawy o podatku akcyzowym",
            "routing": "OK" if is_valid else "BLOCK_AND_ALERT",
        }

    # ── INN09: Property Tax Appeal Auto-Drafter ──
    def draft_property_tax_appeal(self, property_address="", municipality="", 
                                    assessed_value=0, disputed_value=0, 
                                    taxpayer="Jan Kowalski", reason="Błędna klasyfikacja — stawka firmowa zamiast mieszkalnej"):
        savings = assessed_value - disputed_value
        muni = municipality if municipality else "[GMINA]"

        draft = f"""DO: Wójt / Burmistrz / Prezydent Miasta {muni}
OD: {taxpayer}
DATA: {date.today().strftime('%Y-%m-%d')}
NIP: [WSTAW NIP]

WNIOSEK O STWIERDZENIE NADPŁATY / KOREKTĘ
PODATKU OD NIERUCHOMOŚCI

Nieruchomość: {property_address or '[ADRES NIERUCHOMOŚCI]'}
Aktualny wymiar podatku (DN-1): {assessed_value:,.2f} PLN/rok
Prawidłowy wymiar wg wnioskodawcy: {disputed_value:,.2f} PLN/rok
Nadpłata roczna: {savings:,.2f} PLN

UZASADNIENIE:
{reason}

PODSTAWA PRAWNA:
- Art. 1a, Art. 5-6 Ustawy o podatkach i opłatach lokalnych
- Art. 74-79 Ordynacji Podatkowej (nadpłata)
- {CURRENT_DZU}

WNOSZĘ o:
1. Stwierdzenie nadpłaty w kwocie {savings:,.2f} PLN/rok
2. Korektę decyzji DN-1
3. Zwrot nadpłaty za okres do 5 lat wstecz

ZAŁĄCZNIKI:
- Dowód własności / umowa najmu
- Dokumentacja fotograficzna
- Oświadczenie o sposobie użytkowania
"""
        return {
            "draft_type": "ODWOŁANIE_DN1",
            "assessed_value": assessed_value,
            "disputed_value": disputed_value,
            "potential_savings_pln": round(savings, 2),
            "draft": draft.strip(),
            "legal_basis": "Art. 74-79 OrdPU, Art. 1a UoPiOL",
        }

    # ── INN10: Local Tax Rate Auto-Updater ──
    def get_current_rates(self):
        excise_fuel = {k: v for k, v in EXCISE_RATES.items() if k in ("GASOLINE", "DIESEL", "LPG", "CNG")}
        excise_alcohol = {k: v for k, v in EXCISE_RATES.items() if k in ("SPIRITS_PER_HL_100PCT", "BEER_PER_HL_PLATO", "WINE_PER_HL", "CIDER_PER_HL")}

        return {
            "pcc_rates": {k: v["rate_pct"] for k, v in PCC_RATES.items()},
            "real_estate_rates": REAL_ESTATE_RATES,
            "transport_tax": TRANSPORT_TAX,
            "excise_fuel": excise_fuel,
            "excise_alcohol": excise_alcohol,
            "excise_tobacco": {"CIGARETTES_AD_VALOREM": f"{EXCISE_RATES['CIGARETTES_AD_VALOREM_PCT']}%", "CIGARETTES_SPECIFIC": f"{EXCISE_RATES['CIGARETTES_SPECIFIC_PER_1000']} PLN/1000szt"},
            "excise_energy": {"ENERGY_PER_MWH": EXCISE_RATES["ENERGY_PER_MWH"]},
            "update_date": "2026-07-29",
            "next_update": "2027-01-01 (obwieszczenie MF)",
            "note": "Stawki lokalne ustalane przez Radę Gminy — sprawdź uchwałę na BIP gminy",
        }

    # ── INN11: Cross-Border Excise Compliance ──
    def check_cross_border_excise(self, movement_type="DISPATCH", origin_country="PL", dest_country="DE", excise_category="MOTOR_FUEL", volume=0):
        eu_countries = {"PL", "DE", "CZ", "SK", "LT", "LV", "EE", "FR", "IT", "ES", "NL", "BE", "AT", "HU", "RO", "BG", "HR", "SI", "SE", "DK", "FI", "IE", "PT", "GR", "CY", "MT", "LU"}

        is_intra_eu = origin_country in eu_countries and dest_country in eu_countries
        requires_emcs = is_intra_eu and excise_category in ("MOTOR_FUEL", "ALCOHOL", "TOBACCO")

        steps = []
        if is_intra_eu and movement_type == "DISPATCH":
            steps.append("1. Zgłoś w EMCS (e-AD) przed wysyłką")
            steps.append("2. Uzyskaj e-AD (Administrative Reference Code)")
            steps.append("3. Zabezpieczenie akcyzowe obowiązuje do zamknięcia procedury")
            steps.append("4. Odbiorca potwierdza odbiór w EMCS w ciągu 5 dni")
        elif is_intra_eu and movement_type == "RECEIPT":
            steps.append("1. Zweryfikuj e-AD od dostawcy")
            steps.append("2. Potwierdź odbiór w EMCS w ciągu 5 dni")
            steps.append("3. Akcyza płatna w kraju przeznaczenia")
        else:
            steps.append("1. Eksport poza UE — dokument SAD (Single Administrative Document)")
            steps.append("2. Zwolnienie z akcyzy przy eksporcie")

        return {
            "movement_type": movement_type,
            "origin": origin_country,
            "destination": dest_country,
            "is_intra_eu": is_intra_eu,
            "requires_emcs": requires_emcs,
            "excise_category": excise_category,
            "volume": volume,
            "steps": steps,
            "legal_basis": "Dyrektywa 2020/262, Art. 40-48 Ustawy o podatku akcyzowym",
            "system": "EMCS" if requires_emcs else "SAD / papierowe",
        }

    # ── INN12: PCC + VAT Exclusion Firewall ──
    def check_vat_pcc_exclusion(self, amount, is_vat_invoice=False, from_vat_payer=False, transaction_type="SALE"):
        double_tax_risk = False
        flags = []

        if is_vat_invoice or from_vat_payer:
            flags.append("✅ VAT wyłącza PCC (Art. 2 pkt 4 Ustawy o PCC) — brak podwójnego opodatkowania")
        else:
            if amount > 1000:
                flags.append("⚠️ Transakcja NIE podlega VAT → MOŻE podlegać PCC! Sprawdź obowiązek PCC-3")
                double_tax_risk = False
            else:
                flags.append("✅ Kwota ≤ 1000 PLN → zwolniona z PCC")

        if is_vat_invoice and transaction_type in ("SALE_REAL_ESTATE", "SALE_VEHICLE_PRIVATE"):
            flags.append("ℹ️ UWAGA: sprzedaż nieruchomości przez osobę prywatną = PCC nawet jeśli jest faktura (VAT marża?)")

        return {
            "amount": amount,
            "is_vat_invoice": is_vat_invoice,
            "from_vat_payer": from_vat_payer,
            "transaction_type": transaction_type,
            "double_tax_risk": double_tax_risk,
            "pcc_excluded_by_vat": is_vat_invoice or from_vat_payer,
            "flags": flags,
            "legal_basis": "Art. 2 pkt 4 Ustawy o PCC",
            "conclusion": "BEZPIECZNE — VAT wyłącza PCC" if (is_vat_invoice or from_vat_payer) else "SPRAWDŹ PCC — brak VAT, możliwy obowiązek PCC-3",
        }

    def generate_report(self):
        return {
            "tool": "P15 PCC + Local Taxes + Excise Toolkit v1.0",
            "innovations": 12,
            "coverage": "PCC / Nieruchomości / Transport / Akcyza / Opłaty lokalne / BDO / Cross-border",
            "rates_year": 2026,
        }


def main():
    parser = argparse.ArgumentParser(description="P15 PCC + Local Taxes + Excise Toolkit v1.0")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--pcc-detect", action="store_true")
    parser.add_argument("--amount", type=float, default=0)
    parser.add_argument("--type", type=str, default="SALE_MOVABLE", dest="trans_type")
    parser.add_argument("--is-vat", action="store_true")
    parser.add_argument("--from-vat-payer", action="store_true")
    parser.add_argument("--pcc3-fill", action="store_true")
    parser.add_argument("--buyer", type=str, default="Jan Kowalski")
    parser.add_argument("--seller", type=str, default="")
    parser.add_argument("--property", action="store_true")
    parser.add_argument("--area", type=float, default=50)
    parser.add_argument("--is-business-prop", action="store_true", dest="business_prop")
    parser.add_argument("--is-residential", action="store_true")
    parser.add_argument("--is-mixed", action="store_true")
    parser.add_argument("--business-pct", type=float, default=30)
    parser.add_argument("--transport", action="store_true")
    parser.add_argument("--dmc", type=float, default=5000)
    parser.add_argument("--vehicle-type", type=str, default="TRUCK")
    parser.add_argument("--seats", type=int, default=0)
    parser.add_argument("--is-ev", action="store_true")
    parser.add_argument("--warehouse", action="store_true")
    parser.add_argument("--excise-cat", type=str, default="ALCOHOL")
    parser.add_argument("--has-warehouse", action="store_true")
    parser.add_argument("--has-security", action="store_true")
    parser.add_argument("--has-e-dd", action="store_true", help="Whether e-DD/SENT system is registered")
    parser.add_argument("--exemptions", action="store_true")
    parser.add_argument("--is-family", action="store_true")
    parser.add_argument("--calendar", action="store_true")
    parser.add_argument("--suspension", action="store_true")
    parser.add_argument("--monthly-volume", type=float, default=10000)
    parser.add_argument("--draft-appeal", action="store_true")
    parser.add_argument("--assessed", type=float, default=2000)
    parser.add_argument("--disputed", type=float, default=500)
    parser.add_argument("--rates", action="store_true")
    parser.add_argument("--cross-border", action="store_true")
    parser.add_argument("--origin", type=str, default="PL")
    parser.add_argument("--dest", type=str, default="DE", dest="dest_country")
    parser.add_argument("--movement", type=str, default="DISPATCH")
    parser.add_argument("--firewall", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    tk = P15Toolkit()
    output = {}

    if args.all or args.pcc_detect:
        r = tk.detect_pcc_obligation(args.amount or 50000, args.trans_type, args.is_vat, args.from_vat_payer)
        output["INN01_pcc_detect"] = r
        if not args.json:
            print(f"\n  📋 PCC DETECTION: {'PCC!' if r['pcc_applies'] else 'Brak PCC'} — {r['pcc_tax_pln']:,.2f} PLN ({r['pcc_rate_pct']}%)")
            print(f"     {r['exemption_reason']}")

    if args.pcc3_fill:
        r = tk.fill_pcc3(args.buyer, "", args.seller, args.trans_type, args.amount or 50000, date.today().isoformat())
        output["INN02_pcc3"] = {"pcc_tax": r["pcc_tax_pln"], "deadline": r["deadline"], "days": r["days_remaining"]}
        print(f"\n  📝 PCC-3 AUTO-FILL:")
        print(r["form_content"])

    if args.property:
        r = tk.classify_property(args.area, args.business_prop, args.is_residential, args.is_mixed, args.business_pct)
        output["INN03_property"] = r
        if not args.json:
            print(f"\n  🏠 PROPERTY: {r['property_type']} — {r['annual_tax_pln']:,.2f} PLN/rok")
            print(f"     DN-1: {r.get('declaration', 'N/A')} | KUP: {'TAK' if r.get('kup_deductible') else 'NIE'}")

    if args.transport:
        r = tk.calculate_transport_tax(args.dmc, args.vehicle_type, args.seats, args.is_ev)
        output["INN05_transport"] = r
        if not args.json:
            print(f"\n  🚛 TRANSPORT: {r['transport_tax_pln']} PLN/rok — {'ZWOLNIONY' if r['exempt'] else 'DT-1 wymagane'}")

    if args.warehouse:
        r = tk.track_excise_warehouse(args.excise_cat, True, args.has_warehouse, args.has_security)
        output["INN04_warehouse"] = r
        if not args.json:
            print(f"\n  🏭 WAREHOUSE: {r['status']}")

    if args.exemptions:
        r = tk.analyze_pcc_exemptions(args.amount or 50000, args.trans_type, args.is_family, args.is_vat, args.from_vat_payer)
        output["INN06_exemptions"] = r
        if not args.json:
            print(f"\n  ✅ EXEMPTIONS: {'ZWOLNIONE' if r['exempt'] else 'PCC OBOWIĄZUJE'}")
            for e in r["exemptions"]:
                print(f"     • {e}")

    if args.all or args.calendar:
        r = tk.generate_tax_calendar()
        output["INN07_calendar"] = {"total": r["total_events"], "overdue": r["overdue_count"], "next_5": [e["tax"] for e in r["upcoming"][:5]]}
        if not args.json:
            print(f"\n  📅 TAX CALENDAR: {r['total_events']} events, {r['overdue_count']} overdue")
            for e in r["upcoming"][:5]:
                icon = "🟡" if e["status"] == "DUE_SOON" else "✅"
                print(f"     {icon} {e['date']}: {e['tax']} ({e['days_remaining']}d)")

    if args.suspension:
        r = tk.manage_excise_suspension(args.excise_cat, args.monthly_volume, args.has_warehouse, args.has_security, args.has_e_dd)
        output["INN08_suspension"] = {"valid": r["suspension_valid"], "steps_count": len(r["steps"])}
        if not args.json:
            print(f"\n  🔄 SUSPENSION: {'✅ AKTYWNA' if r['suspension_valid'] else '❌ NIEKOMPLETNA'}")
            for s in r["steps"]:
                print(f"     {s}")

    if args.draft_appeal:
        r = tk.draft_property_tax_appeal(taxpayer=args.buyer, assessed_value=args.assessed, disputed_value=args.disputed)
        output["INN09_appeal"] = {"savings": r["potential_savings_pln"]}
        print(f"\n  📝 PROPERTY TAX APPEAL — potencjalne oszczędności: {r['potential_savings_pln']:,.2f} PLN/rok")
        print(r["draft"])

    if args.all or args.rates:
        r = tk.get_current_rates()
        output["INN10_rates"] = {"pcc_count": len(r["pcc_rates"]), "excise_fuel_count": len(r["excise_fuel"])}
        if not args.json:
            print(f"\n  💱 CURRENT RATES: {len(r['pcc_rates'])} PCC, {len(r['excise_fuel'])} excise fuel, {len(r['transport_tax'])} transport")

    if args.cross_border:
        r = tk.check_cross_border_excise(args.movement, args.origin, args.dest_country, args.excise_cat)
        output["INN11_cross_border"] = {"requires_emcs": r["requires_emcs"], "system": r["system"]}
        if not args.json:
            print(f"\n  🌍 CROSS-BORDER: {r['movement_type']} {r['origin']}→{r['destination']} — {r['system']}")
            for s in r["steps"]:
                print(f"     {s}")

    if args.firewall:
        r = tk.check_vat_pcc_exclusion(args.amount or 50000, args.is_vat, args.from_vat_payer, args.trans_type)
        output["INN12_firewall"] = {"pcc_excluded": r["pcc_excluded_by_vat"], "conclusion": r["conclusion"]}
        if not args.json:
            print(f"\n  🛡️  VAT-PCC FIREWALL: {r['conclusion']}")
            for f in r["flags"]:
                print(f"     {f}")

    if args.all and not args.json:
        print(f"\n  ✅ P15 Toolkit: {len(output)} checks completed")

    if args.json and output:
        print(json.dumps(output, indent=2, ensure_ascii=False, default=str))

    if args.report:
        path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_P15_PCC_LOCAL_EXCISE_TOOLKIT_v1.0.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write("P15 PCC + Local Taxes + Excise Toolkit v1.0\n12 innovations\n")
        print(f"  📄 Report: {path}")


if __name__ == "__main__":
    main()
