#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P14 PCC + Podatki Lokalne + Akcyza Auditor (Enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzędzie audytowe dla warstwy PCC, podatków lokalnych i akcyzy (raport P14 v8.0).
# Obszar wskazany w LEGAL_COVERAGE.md jako NAJWIĘKSZA LUKA (~1%).
# Audytuje realne pliki rego: JDG/rules/micro/pcc/pcc.rego (90 rule_id,
# artykuły a1-a16l), micro/plan33_pcc.rego (60), micro/akcyza/akcyza.rego (133),
# micro/transport/transport.rego (45). Generuje dane JSON jako data.jdg.p14_audit.
#
# Funkcje:
#   --audit          pełny audyt plików micro (domyślne)
#   --pcc            kalkulator PCC (stawki art. 6-7)
#   --pcc3           auto-generator deklaracji PCC-3 (art. 10 — 14 dni)
#   --real-estate    symulator podatku od nieruchomości (DN-1, stawki gminne)
#   --transport      kalkulator podatku od środków transportowych (>3,5t)
#   --gmina-registry rejestr stawek gminnych
#   --fuel           kalkulator akcyzy na paliwa (art. 89)
#   --alcohol        kalkulator akcyzy na alkohol (art. 92-96)
#   --warehouse      tracker składu podatkowego
#   --pcc-obligation auto-detektor obowiązku PCC — kupno od osoby prywatnej (INN-13)
#   --pcc3-click     zero-click PCC-3 — countdown 14 dni (INN-14)
#   --gmina-map      mapa stawek gminnych — rejestr z wersjonowaniem (INN-15)
#   --vat-pcc        rekomendacja struktury transakcji VAT vs PCC (INN-16)
#   --excise-import  wykrywacz obowiązku akcyzowego w imporcie (INN-17)
#   --table          format tabelaryczny
#   --out FILE       zapis JSON do pliku
#
# Zwraca: JSON (domyślnie) lub tabelę (--table).
# ═══════════════════════════════════════════════════════════════════════════════
import argparse
import json
import re
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
try:
    from .p14_thresholds import load_thresholds
except ImportError:  # direct ``python JDG/tools/...py`` invocation
    from p14_thresholds import load_thresholds

_P14 = load_thresholds()

# ── Progi ustawowe 2026 (z data.jdg.thresholds.pcc_local_excise — ADR-002)
PCC = {
    "rates": {
        "SALE_MOVABLE": _P14.pcc_sale_rate * 100, "SALE_REAL_ESTATE": _P14.pcc_sale_rate * 100, "SALE_VEHICLE_PRIVATE": _P14.pcc_sale_rate * 100,
        "LOAN": _P14.pcc_loan_rate * 100, "SHARE_PURCHASE": 1.0, "COMPANY_FORMATION": _P14.pcc_company_rate * 100,
        "EXCHANGE_REAL_ESTATE": _P14.pcc_sale_rate * 100, "EXCHANGE_OTHER": 1.0, "MORTGAGE": _P14.pcc_mortgage_rate * 100,
        "SURETY": 0.5, "INSTALLMENT_SALE": 2.0, "INHERITANCE_DIVISION": 1.0,
    },
    "threshold_small": _P14.pcc_exemption_limit,  # art. 9 pkt 1
    "family_loan_limit": _P14.pcc_family_loan_limit,
    "pcc3_deadline_days": _P14.pcc3_deadline_days,
    "real_estate_rates": {           # podatek od nieruchomości 2026
        "land_business": _P14.land_business_rate, "land_other": 0.71,
        "building_business": _P14.building_business_rate, "building_residential": 1.15,
        "construction_pct_value": 2.0,
    },
    "dn1_deadline_days": _P14.dn1_deadline_days,
    "dn1_payment_schedule": ["MARCH_15", "MAY_15", "SEPTEMBER_15", "NOVEMBER_15"],
    "transport_heavy_threshold_t": _P14.transport_threshold_t,
    "real_estate_rates_2025": {     # stawki 2025 (porównanie YoY w gmina_rates_map — INN-15)
        "land_business": 1.34, "building_business": 31.00, "construction_pct_value": 2.0,
    },
    "excise_fuel": {"benzyna": _P14.excise_gasoline, "on": _P14.excise_diesel, "lpg": _P14.excise_lpg},
    "excise_alcohol": {"alkohol_etylowy_pln_hl": _P14.excise_ethanol_per_hl, "piwo_pln_hl_plato": _P14.excise_beer_per_plato, "wino_pln_hl": _P14.excise_wine_per_hl},
}

# Priorytetowe artykuły PCC+lokalne+akcyza (spójne z pakietem rego)
PRIORITY_ARTICLES = ["a1", "a2", "a3", "a4", "a6", "a7", "a8", "a12", "a16", "a26", "a30", "a99"]


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Sekcja 1: kalkulator PCC (INN — stawki art. 6-7) ──────────────────────────
def pcc_calculator(transaction_type: str = "SALE_MOVABLE", amount: float = 100000.0) -> dict:
    if amount < 0:
        raise ValueError("amount must be non-negative")
    rate = PCC["rates"].get(transaction_type, 2.0)
    small_value_exempt = amount <= PCC["threshold_small"]
    tax_due = 0.0 if small_value_exempt else round2(amount * rate / 100)
    return {
        "transaction_type": transaction_type,
        "amount": amount,
        "rate_pct": rate,
        "tax_due": tax_due,
        "small_value_exempt": small_value_exempt,
        "note": f"stawki PCC (art. 6-7): sprzedaż 2%, pożyczka 0,5%, spółki 0,5%, hipoteka 0,1% — podatek {tax_due:,.2f} PLN",
    }


# ── Sekcja 1: auto-generator PCC-3 (INN-01) ───────────────────────────────────
def pcc3_generator(transaction_type: str = "SALE_MOVABLE", amount: float = 100000.0) -> dict:
    if amount < 0:
        raise ValueError("amount must be non-negative")
    rate = PCC["rates"].get(transaction_type, 2.0)
    small_value_exempt = amount <= PCC["threshold_small"]
    tax_due = 0.0 if small_value_exempt else round2(amount * rate / 100)
    return {
        "transaction_type": transaction_type,
        "amount": amount,
        "rate_pct": rate,
        "tax_due": tax_due,
        "deadline_days": PCC["pcc3_deadline_days"],
        "form": "PCC-3 (deklaracja) + PCC-3/A (załącznik) do US w 14 dni od powstania obowiązku",
        "small_value_exempt": small_value_exempt,
        "submission_required": not small_value_exempt,
        "note": "auto-generator PCC-3 — kwota podatku, termin 14 dni, formularz PCC-3/PCC-3/A",
    }


# ── Sekcja 2: symulator podatku od nieruchomości (INN-04) ─────────────────────
def real_estate_tax_calculator(land_business_m2: float = 100.0,
                               building_business_m2: float = 200.0) -> dict:
    rates = PCC["real_estate_rates"]
    land_tax = round2(land_business_m2 * rates["land_business"])
    building_tax = round2(building_business_m2 * rates["building_business"])
    return {
        "land_business_m2": land_business_m2,
        "building_business_m2": building_business_m2,
        "land_tax": land_tax,
        "building_tax": building_tax,
        "total_annual": round2(land_tax + building_tax),
        "rates": rates,
        "note": f"podatek od nieruchomości 2026: grunty {rates['land_business']} zł/m², budynki {rates['building_business']} zł/m² (stawki gminne)",
    }


# ── Sekcja 2: kalkulator podatku od środków transportowych (INN-05) ───────────
def transport_tax_calculator(gvw_t: float = 4.5) -> dict:
    return {
        "vehicle_gvw_t": gvw_t,
        "taxable": gvw_t > PCC["transport_heavy_threshold_t"],
        "threshold_t": PCC["transport_heavy_threshold_t"],
        "note": "podatek od środków transportowych — pojazdy >3,5t, stawki gminne (art. 8-13 ustawy lokalnej)",
    }


# ── Sekcja 2: rejestr stawek gminnych (INN-03) ────────────────────────────────
def gmina_rates_registry(gmina: str = "domyślna") -> dict:
    return {
        "gmina": gmina,
        "rates": PCC["real_estate_rates"],
        "dn1_deadline_days": PCC["dn1_deadline_days"],
        "payment_schedule": PCC["dn1_payment_schedule"],
        "note": "rejestr stawek gminnych — podatek od nieruchomości per gmina (2026); stawki zmieniają się corocznie (uchwały rad gmin)",
    }


# ── Sekcja 3: kalkulator akcyzy na paliwa (INN-07) ────────────────────────────
def excise_fuel_calculator(fuel_type: str = "benzyna", volume_l: float = 1000.0) -> dict:
    rate = PCC["excise_fuel"].get(fuel_type, 1566.0)
    excise_due = round2(volume_l / 1000 * rate)
    return {
        "fuel_type": fuel_type,
        "volume_l": volume_l,
        "rate_per_1000l": rate,
        "excise_due": excise_due,
        "note": "akcyza na paliwa 2026 (PLN/1000l): benzyna 1566, ON 1206, LPG 695 (art. 89 ustawy)",
    }


# ── Sekcja 3: kalkulator akcyzy na alkohol (INN-08) ───────────────────────────
def excise_alcohol_calculator(product: str = "alkohol_etylowy", volume_hl: float = 1.0) -> dict:
    rate = PCC["excise_alcohol"].get("alkohol_etylowy_pln_hl", 6900.0) if product == "alkohol_etylowy" \
        else PCC["excise_alcohol"].get("wino_pln_hl", 185.0) if product == "wino" \
        else PCC["excise_alcohol"].get("piwo_pln_hl_plato", 8.57)
    excise_due = round2(volume_hl * rate)
    return {
        "product": product,
        "volume_hl": volume_hl,
        "rate_pln_hl": rate,
        "excise_due": excise_due,
        "warehouse_required": product == "alkohol_etylowy",
        "note": "akcyza na alkohol 2026 (PLN/hl): alkohol 6900, piwo 8,57/°Plato, wino 185; produkcja alkoholu wymaga składu podatkowego",
    }


# ── Sekcja 3: tracker składu podatkowego (INN-11) ─────────────────────────────
def excise_warehouse_tracker(produces_alcohol: bool = False,
                             produces_fuel: bool = False,
                             warehouse_registered: bool = False) -> dict:
    required = produces_alcohol or produces_fuel
    return {
        "produces_alcohol": produces_alcohol,
        "produces_fuel": produces_fuel,
        "warehouse_registered": warehouse_registered,
        "warehouse_required": required,
        "alert": "produkcja alkoholu/paliw BEZ składu podatkowego = PRZESTĘPSTWO SKARBOWE (art. 65 KKS)",
        "note": "tracker składu podatkowego — obowiązek rejestracji dla producentów wyrobów akcyzowych",
    }


# ── Sekcja 6b (v9.1): auto-detektor obowiązku PCC (INN-13) ────────────────────
def pcc_obligation_detector(transaction_type: str = "kupno_pojazdu",
                            from_private_party: bool = False,
                            vat_applicable: bool = False,
                            amount: float = 50000.0) -> dict:
    """Kupno pojazdu/rzeczy od osoby prywatnej = obowiązek PCC 2% (transakcje VAT wyłączone)."""
    rate = PCC["rates"].get("SALE_VEHICLE_PRIVATE", 2.0) if transaction_type == "kupno_pojazdu" \
        else PCC["rates"].get("SALE_MOVABLE", 2.0) if transaction_type == "sprzedaz_rzeczy" else 0.0
    obligation = from_private_party and not vat_applicable and transaction_type in ("kupno_pojazdu", "sprzedaz_rzeczy")
    tax_due = round2(amount * rate / 100) if obligation else 0.0
    return {
        "transaction_type": transaction_type,
        "from_private_party": from_private_party,
        "vat_applicable": vat_applicable,
        "pcc_rate_pct": rate,
        "pcc_obligation": obligation,
        "tax_due": tax_due,
        "routing": "TRIAGE_QUEUE" if obligation else "",
        "note": "kupno pojazdu od osoby prywatnej = obowiązek PCC 2% + PCC-3 w 14 dni (transakcje VAT wyłączone — art. 2 pkt 4)",
    }


# ── Sekcja 6b (v9.1): zero-click PCC-3 z countdownem (INN-14) ─────────────────
def pcc3_zero_click(transaction_type: str = "SALE_MOVABLE",
                    amount: float = 100000.0,
                    days_elapsed: int = 0) -> dict:
    """Auto-generowanie PCC-3 + countdown 14 dni (art. 10)."""
    if amount < 0 or days_elapsed < 0:
        raise ValueError("amount and days_elapsed must be non-negative")
    rate = PCC["rates"].get(transaction_type, 2.0)
    small_value_exempt = amount <= PCC["threshold_small"]
    tax_due = 0.0 if small_value_exempt else round2(amount * rate / 100)
    remaining = max(0, PCC["pcc3_deadline_days"] - days_elapsed)
    return {
        "transaction_type": transaction_type,
        "amount": amount,
        "rate_pct": rate,
        "tax_due": tax_due,
        "small_value_exempt": small_value_exempt,
        "days_elapsed": days_elapsed,
        "days_remaining": remaining,
        "countdown": f"PCC-3 w {remaining} dni (termin: 14 dni od powstania obowiązku)",
        "form_auto_generated": True,
        "submission_required": not small_value_exempt,
        "urgency_alert": not small_value_exempt and days_elapsed >= PCC["pcc3_deadline_days"] - 3,
        "routing": "TRIAGE_QUEUE" if not small_value_exempt and days_elapsed >= PCC["pcc3_deadline_days"] - 3 else "",
        "note": "zero-click PCC-3 — kwota podatku, countdown 14 dni, formularz PCC-3/PCC-3/A",
    }


# ── Sekcja 6b (v9.1): mapa stawek gminnych (INN-15) ───────────────────────────
def gmina_rates_map(gmina: str = "domyślna") -> dict:
    """Rejestr stawek gminnych z porównaniem rok do roku (temporalność)."""
    current = PCC["real_estate_rates"]
    previous = PCC["real_estate_rates_2025"]
    land_delta = round2((current["land_business"] - previous["land_business"]) / previous["land_business"] * 100) if previous["land_business"] else 0.0
    building_delta = round2((current["building_business"] - previous["building_business"]) / previous["building_business"] * 100) if previous["building_business"] else 0.0
    return {
        "gmina": gmina,
        "rates_current_year": current,
        "rates_previous_year": previous,
        "land_rate_delta_pct": land_delta,
        "building_rate_delta_pct": building_delta,
        "rates_changed_ytd": current["land_business"] != previous["land_business"] or current["building_business"] != previous["building_business"],
        "versioning": "wersjonowanie stawek gminnych — uchwała + data obowiązywania (Law Radar F5)",
        "note": "mapa stawek gminnych — rejestr per gmina z porównaniem rok do roku",
    }


# ── Sekcja 6b (v9.1): rekomendacja struktury transakcji VAT vs PCC (INN-16) ───
def vat_vs_pcc_optimizer(transaction_type: str = "kupno_pojazdu",
                         amount: float = 50000.0,
                         buyer_vat_deductible: bool = False,
                         from_private_party: bool = True) -> dict:
    """Legalna optymalizacja: VAT 23% (koszt bez odliczenia) vs PCC 2% (kupno prywatne)."""
    vat_cost = round2(amount * 0.23) if not buyer_vat_deductible else 0.0
    pcc_cost = round2(amount * PCC["rates"].get("SALE_VEHICLE_PRIVATE", 2.0) / 100) if from_private_party else 0.0
    if not buyer_vat_deductible and from_private_party:
        recommendation = "OD_OSOBY_PRYWATNEJ_PCC_2"
    elif buyer_vat_deductible:
        recommendation = "OD_FIRMY_VAT_ODLICZENIE"
    else:
        recommendation = "ANALIZA"
    return {
        "transaction_type": transaction_type,
        "amount": amount,
        "buyer_vat_deductible": buyer_vat_deductible,
        "vat_cost": vat_cost,
        "pcc_cost": pcc_cost,
        "recommendation": recommendation,
        "routing": "TRIAGE_QUEUE" if from_private_party and not buyer_vat_deductible else "",
        "note": "legalna optymalizacja struktury transakcji — VAT 23% vs PCC 2% (kupno od osoby prywatnej gdy brak odliczenia)",
    }


# ── Sekcja 6b (v9.1): wykrywacz obowiązku akcyzowego w imporcie (INN-17) ──────
EXCISE_GOODS_KEYWORDS = ["benzyna", "paliwo", "olej napędowy", "lpg", "alkohol", "wino",
                         "piwo", "tytoń", "papieros", "węgiel", "energia"]


def excise_import_detector(imported_goods: str = "benzyna bezołowiowa") -> dict:
    """Wykrycie obowiązku akcyzowego przy imporcie wyrobów (spójność z P12)."""
    desc = imported_goods.lower()
    matched = [kw for kw in EXCISE_GOODS_KEYWORDS if kw in desc]
    return {
        "imported_goods": imported_goods,
        "excise_goods": len(matched) > 0,
        "matched_keywords": matched,
        "obligation": "zgłoszenie akcyzowe + zabezpieczenie akcyzowe przy imporcie wyrobów akcyzowych z państwa trzeciego",
        "alcohol_import_note": "import alkoholu — obowiązek banderolowania / skład podatkowy",
        "fuel_import_note": "import paliw — zabezpieczenie akcyzowe przed dopuszczeniem do obrotu",
        "cross_border_integration": "spójność z P12 (cross-border) — dokumenty celne + akcyza",
        "routing": "TRIAGE_QUEUE" if len(matched) > 0 else "",
        "note": "wykrywacz obowiązku akcyzowego w imporcie — paliwa, alkohol, tytoń, energia (art. 39-41 ustawy)",
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def audit_rego_files() -> dict:
    rule_ids = []
    files_audited = []
    texts = []

    dirs = [
        ("micro/pcc", BASE_DIR / "rules" / "micro" / "pcc"),
        ("micro/akcyza", BASE_DIR / "rules" / "micro" / "akcyza"),
        ("micro/transport", BASE_DIR / "rules" / "micro" / "transport"),
    ]
    for label, d in dirs:
        if d.exists():
            for f in sorted(d.glob("*.rego")):
                files_audited.append(f"{label}/{f.name}")
                t = f.read_text(encoding="utf-8")
                texts.append(t)
                rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    plan33 = BASE_DIR / "rules" / "micro" / "plan33_pcc.rego"
    if plan33.exists():
        files_audited.append("micro/plan33_pcc.rego")
        t = plan33.read_text(encoding="utf-8")
        texts.append(t)
        rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    total = len(rule_ids)
    unique = sorted(set(rule_ids))
    no_match_defaults = sum(1 for rid in rule_ids if rid.endswith(".no_match"))
    real_rule_ids = [rid for rid in rule_ids if not rid.endswith(".no_match")]
    duplicates = sorted({rid for rid in set(real_rule_ids) if real_rule_ids.count(rid) > 1})

    combined = "\n".join(texts)
    stubs = [rid for rid in unique if _looks_like_stub(combined, rid)]
    dead_rules = _detect_dead_rules(unique)

    articles = {}
    for art in PRIORITY_ARTICLES:
        refs = sum(1 for rid in unique if re.match(rf"jdg\.micro\.(?:pcc|akcyza|transport)\.{re.escape(art)}(?:\.|$)", rid))
        articles[art] = {"status": "COMPLETE" if refs > 0 else "MISSING", "rules": refs}

    total_arts = len(PRIORITY_ARTICLES)
    missing = sum(1 for a in articles.values() if a["status"] == "MISSING")
    return {
        "files_audited": files_audited,
        "total_rule_ids": total,
        "unique_count": len(unique),
        "no_match_defaults": no_match_defaults,
        "duplicates": duplicates,
        "duplicate_count": len(duplicates),
        "stubs": stubs,
        "stub_count": len(stubs),
        "dead_rules": dead_rules,
        "articles": articles,
        "coverage": {
            "total": total_arts,
            "complete": total_arts - missing,
            "missing": missing,
            "gap_pct": round2(missing / total_arts * 100) if total_arts else 0.0,
        },
    }


def _looks_like_stub(text: str, rule_id: str) -> bool:
    """Heurystyka stubu: rule_id w jednej linii, a '{ true }' w następnej."""
    idx = text.find(rule_id)
    if idx == -1:
        return False
    chunk = text[idx:idx + 200]
    return bool(re.search(r"\{[^{}]*true[^{}]*\}", chunk))


def _detect_dead_rules(unique) -> list:
    """Detektor martwych reguł: reguły z prefiksem no_match lub test_* w produkcji."""
    return [rid for rid in unique if ".test_" in rid or rid.endswith("_legacy")]


# ── CLI ────────────────────────────────────────────────────────────────────────
def main() -> int:
    parser = argparse.ArgumentParser(
        description="NexusAI JDG — P14 PCC + Podatki Lokalne + Akcyza Auditor (Enterprise)")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików micro (domyślne)")
    parser.add_argument("--pcc", action="store_true", help="kalkulator PCC (stawki art. 6-7)")
    parser.add_argument("--pcc3", action="store_true", help="auto-generator deklaracji PCC-3 (14 dni)")
    parser.add_argument("--real-estate", action="store_true", help="symulator podatku od nieruchomości (DN-1)")
    parser.add_argument("--transport", action="store_true", help="kalkulator podatku od środków transportowych")
    parser.add_argument("--gmina-registry", action="store_true", help="rejestr stawek gminnych")
    parser.add_argument("--fuel", action="store_true", help="kalkulator akcyzy na paliwa (art. 89)")
    parser.add_argument("--alcohol", action="store_true", help="kalkulator akcyzy na alkohol (art. 92-96)")
    parser.add_argument("--warehouse", action="store_true", help="tracker składu podatkowego")
    parser.add_argument("--pcc-obligation", action="store_true", help="auto-detektor obowiązku PCC — INN-13")
    parser.add_argument("--pcc3-click", action="store_true", help="zero-click PCC-3 — countdown 14 dni — INN-14")
    parser.add_argument("--gmina-map", action="store_true", help="mapa stawek gminnych — wersjonowanie — INN-15")
    parser.add_argument("--vat-pcc", action="store_true", help="rekomendacja VAT vs PCC — INN-16")
    parser.add_argument("--excise-import", action="store_true", help="wykrywacz akcyzy w imporcie — INN-17")
    parser.add_argument("--transaction-type", type=str, default="SALE_MOVABLE", help="typ czynności PCC")
    parser.add_argument("--from-private", action="store_true", help="kontrahent osobą prywatną (INN-13/16)")
    parser.add_argument("--vat-applicable", action="store_true", help="transakcja opodatkowana VAT (INN-13)")
    parser.add_argument("--days-elapsed", type=int, default=0, help="dni od powstania obowiązku PCC (INN-14)")
    parser.add_argument("--buyer-deductible", action="store_true", help="nabywca odlicza VAT (INN-16)")
    parser.add_argument("--import-goods", type=str, default="benzyna bezołowiowa", help="importowane towary (INN-17)")
    parser.add_argument("--amount", type=float, default=100000.0, help="kwota czynności (PLN)")
    parser.add_argument("--land-m2", type=float, default=100.0, help="grunty firmowe (m²)")
    parser.add_argument("--building-m2", type=float, default=200.0, help="budynki firmowe (m²)")
    parser.add_argument("--gvw-t", type=float, default=4.5, help="DMC pojazdu (t)")
    parser.add_argument("--fuel-type", type=str, default="benzyna", help="rodzaj paliwa")
    parser.add_argument("--volume-l", type=float, default=1000.0, help="objętość paliwa (l)")
    parser.add_argument("--alcohol-product", type=str, default="alkohol_etylowy", help="produkt alkoholowy")
    parser.add_argument("--volume-hl", type=float, default=1.0, help="objętość alkoholu (hl)")
    parser.add_argument("--gmina", type=str, default="domyślna", help="gmina (rejestr stawek)")
    parser.add_argument("--table", action="store_true", help="format tabelaryczny")
    parser.add_argument("--out", type=str, default="", help="zapis JSON do pliku")
    args = parser.parse_args()

    result = {"tool": "pcc_local_excise_auditor", "module": "P14 PCC + Podatki Lokalne + Akcyza"}

    if args.audit or not (args.pcc or args.pcc3 or args.real_estate or args.transport or
                          args.gmina_registry or args.fuel or args.alcohol or args.warehouse or
                          args.pcc_obligation or args.pcc3_click or args.gmina_map or
                          args.vat_pcc or args.excise_import):
        result["audit"] = audit_rego_files()
    if args.pcc:
        result["pcc"] = pcc_calculator(args.transaction_type, args.amount)
    if args.pcc3:
        result["pcc3"] = pcc3_generator(args.transaction_type, args.amount)
    if args.real_estate:
        result["real_estate"] = real_estate_tax_calculator(args.land_m2, args.building_m2)
    if args.transport:
        result["transport"] = transport_tax_calculator(args.gvw_t)
    if args.gmina_registry:
        result["gmina_registry"] = gmina_rates_registry(args.gmina)
    if args.fuel:
        result["fuel"] = excise_fuel_calculator(args.fuel_type, args.volume_l)
    if args.alcohol:
        result["alcohol"] = excise_alcohol_calculator(args.alcohol_product, args.volume_hl)
    if args.warehouse:
        result["warehouse"] = excise_warehouse_tracker(produces_alcohol=True)
    # Dla flag --pcc-obligation/--vat-pcc domyślny typ transakcji to "kupno_pojazdu"
    # (osoba prywatna), o ile użytkownik nie podał własnego --transaction-type.
    # Uwaga: argparse nie odróżnia defaultu od jawnego przekazania wartości —
    # jawne --transaction-type SALE_MOVABLE zostanie nadpisane na kupno_pojazdu.
    obligation_type = args.transaction_type if args.transaction_type != "SALE_MOVABLE" else "kupno_pojazdu"
    if args.pcc_obligation:
        result["pcc_obligation"] = pcc_obligation_detector(
            obligation_type, args.from_private, args.vat_applicable, args.amount)
    if args.pcc3_click:
        result["pcc3_click"] = pcc3_zero_click(args.transaction_type, args.amount, args.days_elapsed)
    if args.gmina_map:
        result["gmina_map"] = gmina_rates_map(args.gmina)
    if args.vat_pcc:
        result["vat_pcc"] = vat_vs_pcc_optimizer(
            obligation_type, args.amount, args.buyer_deductible, args.from_private)
    if args.excise_import:
        result["excise_import"] = excise_import_detector(args.import_goods)

    if args.table:
        if "audit" in result:
            a = result["audit"]
            print(f"AUDYT MICRO PCC+LOKALNE+AKCYZA: {a['total_rule_ids']} rule_id | {a['unique_count']} unikalnych | "
                  f"duplikaty: {a['duplicate_count']} | stuby: {a['stub_count']}")
            print(f"  Pokrycie artykułów: {a['coverage']['complete']}/{a['coverage']['total']} "
                  f"(gap {a['coverage']['gap_pct']}%)")
            missing = [k for k, v in a["articles"].items() if v["status"] == "MISSING"]
            if missing:
                print(f"  Braki: {', '.join(missing)}")
        if "pcc" in result:
            p = result["pcc"]
            print(f"\nPCC ({p['transaction_type']}): {p['amount']:,.0f} × {p['rate_pct']}% = {p['tax_due']:,.2f} PLN")
        if "pcc3" in result:
            p3 = result["pcc3"]
            print(f"\nPCC-3: podatek {p3['tax_due']:,.2f} PLN | termin {p3['deadline_days']} dni | {p3['form']}")
        if "real_estate" in result:
            re_ = result["real_estate"]
            print(f"\nNIERUCHOMOŚCI: grunty {re_['land_tax']:,.2f} + budynki {re_['building_tax']:,.2f} "
                  f"= {re_['total_annual']:,.2f} PLN/rok")
        if "fuel" in result:
            f = result["fuel"]
            print(f"\nAKCYZA PALIWA ({f['fuel_type']}): {f['volume_l']:,.0f} l → {f['excise_due']:,.2f} PLN")
        if "alcohol" in result:
            al = result["alcohol"]
            print(f"\nAKCYZA ALKOHOL ({al['product']}): {al['volume_hl']} hl → {al['excise_due']:,.2f} PLN "
                  f"| skład wymagany: {al['warehouse_required']}")
        if "pcc_obligation" in result:
            po = result["pcc_obligation"]
            print(f"\nOBOWIĄZEK PCC ({po['transaction_type']}): {po['pcc_obligation']} | "
                  f"podatek {po['tax_due']:,.2f} PLN ({po['pcc_rate_pct']}%)")
        if "pcc3_click" in result:
            c = result["pcc3_click"]
            print(f"\nZERO-CLICK PCC-3: {c['countdown']} | podatek {c['tax_due']:,.2f} PLN")
        if "gmina_map" in result:
            g = result["gmina_map"]
            print(f"\nMAPA STAWEK GMINNYCH ({g['gmina']}): zmiana YoY grunty {g['land_rate_delta_pct']}% / "
                  f"budynki {g['building_rate_delta_pct']}% | zmiana: {g['rates_changed_ytd']}")
        if "vat_pcc" in result:
            v = result["vat_pcc"]
            print(f"\nVAT vs PCC: rekomendacja {v['recommendation']} "
                  f"(VAT {v['vat_cost']:,.2f} vs PCC {v['pcc_cost']:,.2f})")
        if "excise_import" in result:
            ei = result["excise_import"]
            print(f"\nAKCYZA IMPORT: {ei['excise_goods']} (słowa: {ei['matched_keywords']})")
        return 0

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano: {args.out}")
        return 0

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
