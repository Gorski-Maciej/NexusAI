#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P09 Ksiegowosc PKPiR + UoR + Amortyzacja Auditor (Enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzedzie audytowe dla warstwy ksiegowosci JDG (raport analityczny P09 v8.0).
# Audytuje realne pliki rego: JDG/rules/micro/pkpir/*.rego (kolumny 1-17,
# przychody/koszty/NKUP/remanent/korekty), JDG/rules/uor/*.rego (art. 2-74 UoR),
# _pkpir_rates.rego (KST), _uor_rates.rego (prog 2M EUR). Generuje dane JSON
# do wstrzykniecia jako data.jdg.ksiegowosc_audit.
#
# Funkcje:
#   --audit          pelny audyt plikow PKPiR/UoR (domyslne)
#   --uor            silnik decyzji "PKPiR czy UoR?" (prog 2 000 000 EUR)
#   --pkpir          audyt struktury PKPiR (kolumny 1-17, dekretacja, walidator)
#   --amortization   kalkulator amortyzacji (KST, jednorazowa 100k EUR, auta 150k/225k)
#   --leasing        symulator leasingu operacyjny vs finansowy
#   --remanent       symulator remanentu (koniec/poczatek roku)
#   --table          format tabelaryczny
#   --out FILE       zapis JSON do pliku
#
# Zwraca: JSON (domyslnie) lub tabele (--table).
# ═══════════════════════════════════════════════════════════════════════════════
import argparse
import json
import re
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]

# ── Progi ustawowe 2026 (spójne z data.jdg.thresholds.accounting — ADR-002) ──
ACCOUNTING = {
    "uor_threshold_eur": 2000000,          # art. 2 ust. 1 pkt 5 UoR (2M EUR)
    "eur_pln_reference": 4.50,             # kurs referencyjny NBP
    "early_warning_pct": 75,               # 75% progu — wczesne ostrzezenie
    "one_time_depreciation_eur": 100000,   # art. 22k ust. 7 PIT (100k EUR)
    "car_limit_standard": 150000,          # art. 23a pkt 47a (150k PLN)
    "car_limit_electric": 225000,          # auta elektryczne (225k PLN)
    "kst_group_rates": {                   # KST — rozporzadzenie RM
        "0": 0.0, "1": 0.025, "2": 0.045, "3": 0.07,
        "4": 0.14, "5": 0.20, "6": 0.20, "7": 0.20, "8": 0.20,
    },
    "remanent_pct": 1.0,
}

# Kolumny PKPiR 1-17 wg rozporzadzenia o PKPiR (Dz.U. 2025 poz. 567)
PKPIR_COLUMNS = {
    "1": "Liczba porzadkowa",
    "2": "Data zdarzenia gospodarczego",
    "3": "Data wpisu do księgi",
    "4": "Nr dowodu księgowego",
    "5": "Kontrahent (imie/nazwa, adres)",
    "6": "Opis zdarzenia",
    "7": "Przychód — sprzedaz towarów i uslug",
    "8": "Przychód — pozostale",
    "9": "Razem przychody (7+8)",
    "10": "Zakup towarów handlowych i materialów",
    "11": "Koszty uboczne zakupu",
    "12": "Wynagrodzenia brutto",
    "13": "Pozostale wydatki",
    "14": "Razem wydatki (10+11+12+13)",
    "15": "Uwagi",
    "16": "VAT naliczony — do odliczenia",
    "17": "VAT naliczony — niepodlegajacy odliczeniu",
}

# Dekretacja operacji → kolumny PKPiR (dokument → dekret)
COLUMN_MAPPING = {
    "sale_goods": "7", "sale_services": "7", "other_income": "8",
    "purchase_goods": "10", "purchase_materials": "10",
    "wages": "12", "other_expense": "13",
}

# Priorytetowe artykuly UoR (modul → artykul) i klucze pokrycia
UOR_ARTICLES = [
    "a2", "a4", "a10", "a11", "a12", "a20", "a21", "a22", "a26",
    "a27", "a28", "a32", "a45", "a46", "a47", "a49", "a52", "a74",
]


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Sekcja 2: silnik decyzji "PKPiR czy UoR?" (INN-01) ───────────────────────
def uor_obligation_engine(annual_revenue_pln: float) -> dict:
    eur = annual_revenue_pln / ACCOUNTING["eur_pln_reference"]
    threshold = ACCOUNTING["uor_threshold_eur"]
    early = threshold * ACCOUNTING["early_warning_pct"] / 100
    return {
        "annual_revenue_pln": annual_revenue_pln,
        "annual_revenue_eur": round2(eur),
        "threshold_eur": threshold,
        "threshold_pln": round2(threshold * ACCOUNTING["eur_pln_reference"]),
        "early_warning_eur": early,
        "exceeds": eur >= threshold,
        "early_warning_active": early <= eur < threshold,
        "decision": "UoR" if eur >= threshold else "PKPiR",
        "note": ("Przekroczenie progu 2M EUR — obowiazek pelnej rachunkowosci "
                 "(art. 2 ust. 1 pkt 5 UoR)") if eur >= threshold else (
                 "75% progu — planuj przejscie na UoR") if eur >= early else
                 "Przychód ponizej 75% progu — PKPiR w pelni wystarczajaca",
    }


# ── Sekcja 1: audyt struktury PKPiR ───────────────────────────────────────────
def pkpir_structure_audit() -> dict:
    return {
        "columns": PKPIR_COLUMNS,
        "column_count": len(PKPIR_COLUMNS),
        "required_columns": 14,
        "entry_deadline": "wpis do 20 dni od zdarzenia (przed koncem roku)",
        "posting_rule": "kol. 9 = 7+8 | kol. 14 = 10+11+12+13",
        "column_mapping": COLUMN_MAPPING,
    }


def pkpir_validator(col_7: float, col_8: float, col_9: float,
                    col_10: float, col_11: float, col_12: float,
                    col_13: float, col_14: float) -> dict:
    income_ok = round2(col_7 + col_8) == round2(col_9)
    expenses_ok = round2(col_10 + col_11 + col_12 + col_13) == round2(col_14)
    return {
        "income_ok": income_ok,
        "expenses_ok": expenses_ok,
        "consistent": income_ok and expenses_ok,
    }


# ── Sekcja 3: amortyzacja i leasing ───────────────────────────────────────────
def kst_depreciation(asset_value: float, kst_group: str, book_rate: float = None) -> dict:
    rate = ACCOUNTING["kst_group_rates"].get(kst_group, 0.14)
    tax_annual = round2(asset_value * rate)
    book = book_rate if book_rate is not None else rate
    book_annual = round2(asset_value * book)
    return {
        "asset_value": asset_value,
        "kst_group": kst_group,
        "tax_rate": rate,
        "book_rate": book,
        "tax_annual": tax_annual,
        "book_annual": book_annual,
        "difference": round2(book_annual - tax_annual),
        "groups": ACCOUNTING["kst_group_rates"],
    }


def one_time_depreciation(new_assets_value: float) -> dict:
    limit = round2(ACCOUNTING["one_time_depreciation_eur"] * ACCOUNTING["eur_pln_reference"])
    return {
        "new_assets_value": new_assets_value,
        "limit_pln": limit,
        "limit_eur": ACCOUNTING["one_time_depreciation_eur"],
        "within_limit": new_assets_value <= limit,
        "excess": round2(max(new_assets_value - limit, 0)),
    }


def car_limit_audit(car_value: float, is_electric: bool = False) -> dict:
    limit = ACCOUNTING["car_limit_electric"] if is_electric else ACCOUNTING["car_limit_standard"]
    return {
        "car_value": car_value,
        "is_electric": is_electric,
        "limit": limit,
        "excess": round2(max(car_value - limit, 0)),
        "note": ("Auto > limit — KUP limitowany proporcjonalnie (art. 23a pkt 47a PIT)"),
    }


def leasing_comparator(monthly_rent: float, interest_share: float = 0.20) -> dict:
    operating = monthly_rent
    financial = round2(monthly_rent * interest_share)
    return {
        "monthly_rent": monthly_rent,
        "operating_kup_monthly": operating,
        "financial_kup_monthly": financial,
        "annual_difference": round2(operating * 12 - financial * 12),
        "recommendation": "operacyjny" if monthly_rent > 0 else "brak",
    }


# ── Sekcja 4: remanent ────────────────────────────────────────────────────────
def remanent_simulator(opening: float, projected_closing: float) -> dict:
    return {
        "opening": opening,
        "projected_closing": projected_closing,
        "income_impact_next_year": round2(projected_closing - opening),
        "rule": ("wartosc remanentu na koniec roku → przychód w roku nastepnym "
                 "(art. 24 ust. 2 PIT)"),
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def audit_rego_files() -> dict:
    pkpir_rule_ids = []
    uor_rule_ids = []
    pkpir_files = []
    uor_files = []

    # Katalog PKPiR mikro
    pkpir_dir = BASE_DIR / "rules" / "micro" / "pkpir"
    if pkpir_dir.exists():
        for f in sorted(pkpir_dir.glob("*.rego")):
            pkpir_files.append(f"micro/pkpir/{f.name}")
            t = f.read_text(encoding="utf-8")
            pkpir_rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    # Katalog UoR (moduly uor_obligation, uor_books, uor_revenue...)
    uor_dir = BASE_DIR / "rules" / "uor"
    if uor_dir.exists():
        for f in sorted(uor_dir.glob("*.rego")):
            uor_files.append(f"uor/{f.name}")
            t = f.read_text(encoding="utf-8")
            uor_rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    pkpir_unique = sorted({r for r in pkpir_rule_ids if not r.endswith(".no_match")})
    uor_unique = sorted({r for r in uor_rule_ids if not r.endswith(".no_match")})

    # Pokrycie artykulów UoR: jdg.uor.<modul>.a{N}[.r{M}] → klucz artykulu
    covered = set()
    for rid in uor_unique:
        m = re.search(r"\.(a\d+[a-z]?)(?:\.r\d+)?$", rid)
        if m:
            covered.add(m.group(1))

    articles = {}
    for art in UOR_ARTICLES:
        refs = sum(1 for rid in uor_unique if re.search(rf"\.{re.escape(art)}(?:\.r\d+)?$", rid))
        articles[art] = {"status": "COMPLETE" if refs > 0 else "MISSING", "rules": refs}

    total_arts = len(UOR_ARTICLES)
    missing = sum(1 for a in articles.values() if a["status"] == "MISSING")

    # Pokrycie kolumn PKPiR (jdg.micro.pkpir_columns.p10.r{N})
    pkpir_columns_rids = [r for r in pkpir_unique if "pkpir_columns" in r]
    columns_present = set()
    for rid in pkpir_columns_rids:
        m = re.search(r"p10\.r(\d+)$", rid)
        if m:
            columns_present.add(int(m.group(1)))
    columns = {}
    for col in range(1, 18):
        columns[str(col)] = {
            "name": PKPIR_COLUMNS[str(col)],
            "status": "COMPLETE" if col in columns_present else "MISSING",
        }
    columns_missing = [c for c, v in columns.items() if v["status"] == "MISSING"]

    return {
        "pkpir_files": pkpir_files,
        "uor_files": uor_files,
        "pkpir_total_rule_ids": len(pkpir_rule_ids),
        "pkpir_unique_count": len(pkpir_unique),
        "uor_total_rule_ids": len(uor_rule_ids),
        "uor_unique_count": len(uor_unique),
        "uor_duplicates": sorted({r for r in uor_unique if uor_rule_ids.count(r) > 1}),
        "articles": articles,
        "uor_coverage": {
            "total": total_arts,
            "complete": total_arts - missing,
            "missing": missing,
            "gap_pct": round2(missing / total_arts * 100) if total_arts else 0.0,
        },
        "pkpir_columns": columns,
        "pkpir_columns_missing": columns_missing,
        "pkpir_columns_coverage": {
            "total": 17,
            "complete": 17 - len(columns_missing),
            "gap_pct": round2(len(columns_missing) / 17 * 100),
        },
        "rates_packages": {
            "pkpir_rates": (BASE_DIR / "rules" / "_pkpir_rates.rego").exists(),
            "uor_rates": (BASE_DIR / "rules" / "_uor_rates.rego").exists(),
        },
    }


# ── CLI ────────────────────────────────────────────────────────────────────────
def main() -> int:
    parser = argparse.ArgumentParser(
        description="NexusAI JDG — P09 Ksiegowosc PKPiR + UoR + Amortyzacja Auditor (Enterprise)")
    parser.add_argument("--audit", action="store_true", help="pelny audyt plikow PKPiR/UoR (domyslne)")
    parser.add_argument("--uor", action="store_true", help="silnik decyzji PKPiR czy UoR")
    parser.add_argument("--pkpir", action="store_true", help="audyt struktury PKPiR (kolumny 1-17)")
    parser.add_argument("--amortization", action="store_true", help="kalkulator amortyzacji (KST)")
    parser.add_argument("--leasing", action="store_true", help="symulator leasingu operacyjny vs finansowy")
    parser.add_argument("--remanent", action="store_true", help="symulator remanentu")
    parser.add_argument("--revenue", type=float, default=6000000.0, help="przychód roczny (PLN)")
    parser.add_argument("--asset-value", type=float, default=100000.0, help="wartosc srodka trwalego")
    parser.add_argument("--kst-group", type=str, default="4", help="grupa KST (0-8)")
    parser.add_argument("--book-rate", type=float, default=None, help="stawka bilansowa (UoR)")
    parser.add_argument("--new-assets", type=float, default=350000.0, help="wartosc nowych srodków trwalych")
    parser.add_argument("--car-value", type=float, default=180000.0, help="wartosc auta osobowego")
    parser.add_argument("--electric", action="store_true", help="auto elektryczne (limit 225k)")
    parser.add_argument("--monthly-rent", type=float, default=2000.0, help="rata leasingu miesiecznie")
    parser.add_argument("--interest-share", type=float, default=0.20, help="udzial odsetek w racie finansowej")
    parser.add_argument("--opening", type=float, default=10000.0, help="remanent otwarcia")
    parser.add_argument("--closing", type=float, default=45000.0, help="remanent zamkniecia (prognoza)")
    parser.add_argument("--table", action="store_true", help="format tabelaryczny")
    parser.add_argument("--out", type=str, default="", help="zapis JSON do pliku")
    args = parser.parse_args()

    result = {"tool": "ksiegowosc_pkpir_uor_auditor", "module": "P09 Ksiegowosc PKPiR+UoR"}

    if args.audit or not (args.uor or args.pkpir or args.amortization or
                          args.leasing or args.remanent):
        result["audit"] = audit_rego_files()
    if args.uor:
        result["uor_obligation"] = uor_obligation_engine(args.revenue)
    if args.pkpir:
        result["pkpir_structure"] = pkpir_structure_audit()
    if args.amortization:
        result["amortization"] = kst_depreciation(args.asset_value, args.kst_group, args.book_rate)
        result["one_time_depreciation"] = one_time_depreciation(args.new_assets)
        result["car_limit"] = car_limit_audit(args.car_value, args.electric)
    if args.leasing:
        result["leasing"] = leasing_comparator(args.monthly_rent, args.interest_share)
    if args.remanent:
        result["remanent"] = remanent_simulator(args.opening, args.closing)

    if args.table:
        if "uor_obligation" in result:
            u = result["uor_obligation"]
            print("SILNIK DECYZJI PKPiR czy UoR:")
            print(f"  Przychód: {u['annual_revenue_pln']:>14,.2f} PLN = {u['annual_revenue_eur']:>12,.2f} EUR")
            print(f"  Próg:     {u['threshold_eur']:>14,} EUR ({u['threshold_pln']:,.2f} PLN)")
            print(f"  Decyzja:  {u['decision']}")
            print(f"  Ostrzeżenie 75%: {'AKTYWNE' if u['early_warning_active'] else 'brak'}")
        if "pkpir_structure" in result:
            print(f"\nSTRUKTURA PKPiR: {result['pkpir_structure']['column_count']} kolumn "
                  f"({result['pkpir_structure']['required_columns']} wymaganych)")
        if "amortization" in result:
            a = result["amortization"]
            print(f"\nAMORTYZACJA (KST grupa {a['kst_group']}, stawka {a['tax_rate']}):")
            print(f"  roczna podatkowa: {a['tax_annual']:>10,.2f} | bilansowa: {a['book_annual']:>10,.2f} | różnica: {a['difference']:>10,.2f}")
            od = result["one_time_depreciation"]
            od_msg = "OK" if od["within_limit"] else "NADMIAR " + f"{od['excess']:,.2f}"
            print(f"  jednorazowa: limit {od['limit_pln']:,.2f} — {od_msg}")
            cl = result["car_limit"]
            print(f"  auto: limit {cl['limit']:,.0f} — nadwyżka {cl['excess']:,.2f}")
        if "leasing" in result:
            l = result["leasing"]
            print(f"\nLEASING: operacyjny KUP {l['operating_kup_monthly']:>10,.2f}/mies. vs "
                  f"finansowy {l['financial_kup_monthly']:>10,.2f}/mies. (rekomendacja: {l['recommendation']})")
        if "remanent" in result:
            r = result["remanent"]
            print(f"\nREMANENT: otwarcie {r['opening']:,.2f} → zamkniecie {r['projected_closing']:,.2f} "
                  f"| wpływ na dochód r. nast.: {r['income_impact_next_year']:,.2f}")
        if "audit" in result:
            a = result["audit"]
            print(f"\nAUDYT REALNYCH PLIKÓW: PKPiR {a['pkpir_unique_count']} reguł / UoR {a['uor_unique_count']} reguł")
            print(f"  Pokrycie artykułów UoR: {a['uor_coverage']['complete']}/{a['uor_coverage']['total']} "
                  f"(gap {a['uor_coverage']['gap_pct']}%)")
            print(f"  Pokrycie kolumn PKPiR:  {a['pkpir_columns_coverage']['complete']}/17 "
                  f"(braki: {a['pkpir_columns_missing'] or 'brak'})")
        return 0

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano: {args.out}")
        return 0

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
