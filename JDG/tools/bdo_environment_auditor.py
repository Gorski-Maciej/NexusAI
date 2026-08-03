#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P15 Środowisko + BDO + Branża Auditor (Enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzędzie audytowe dla warstwy środowiska, BDO i obowiązków branżowych
# (raport P15 v8.0). Audytuje realne pliki rego: JDG/rules/micro/bdo/*.rego
# (6 modułów: rejestracja 10, ewidencja 10, EWC 9, transport 8, zezwolenia 8,
# WEEE-baterie 7 = 52 rule_id), micro/srodowisko/srodowisko.rego (49, artykuły
# a3s/a5s/a7/a8/a10/a15), micro/budownictwo/budownictwo.rego (65, a1-a9).
# Generuje dane JSON jako data.jdg.p15_audit.
#
# Funkcje:
#   --audit           pełny audyt plików micro (domyślne)
#   --bdo-assistant   asystent BDO (rejestracja, opłaty, ewidencja — INN-01)
#   --kpo             generator kart przekazania odpadów KPO (INN-02)
#   --deadlines       tracker terminów sprawozdań BDO (INN-03)
#   --product-fee     tracker opłat produktowych opakowania/WEEE (INN-04)
#   --permit          kalkulator pozwolenia na budowę / zgłoszenia (INN-05)
#   --cbam            kalkulator CBAM (INN-06)
#   --taxfree         kalkulator tax-free VAT-REF (INN-10)
#   --seasonal        asystent sezonowości (INN-11)
#   --agricultural    kalkulator podatku rolnego (INN-12)
#   --table           format tabelaryczny
#   --out FILE        zapis JSON do pliku
#
# Zwraca: JSON (domyślnie) lub tabelę (--table).
# ═══════════════════════════════════════════════════════════════════════════════
import argparse
import json
import re
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]

# ── Progi ustawowe 2026 (spójne z data.jdg.thresholds.bdo_environment — ADR-002)
BDO = {
    "rejestracja_fees": {"mikro": 100, "mały": 300, "średni": 500},  # opłata rejestracyjna BDO (PLN)
    "kara_brak_rejestracji": 5000.0,   # art. 194 UoO — kara do 5000 zł
    "ewidencja_okres": "kwartalna",
    "kpo_elektroniczne": True,
    "packaging_fee_rate": 2.0,          # orientacyjna stawka opłaty produktowej (zł/kg)
    "budowlane_nadzor": "zgłoszenie zakończenia budowy",
    "transport_tachograf_t": 3.5,
    "cbam_price_eur_t": 80.0,           # orientacyjna cena uprawnień EU ETS (EUR/t CO2)
    "agricultural_rye_pln_q": 89.63,    # cena żyta 2026 (zł/q)
    "taxfree_vat_rate": 0.23,
}

# Priorytetowe moduły BDO + środowisko + budownictwo (spójne z pakietem rego)
PRIORITY_MODULES = [
    "bdo_rejestracja", "bdo_ewidencja", "bdo_ewc", "bdo_transport",
    "bdo_zezwolenia", "bdo_weee_baterie", "srodowisko", "budownictwo",
]
# Priorytetowe artykuły środowiska (srodowisko.rego) i budownictwa (budownictwo.rego)
SRODOWISKO_ARTICLES = ["a3s", "a5s", "a7", "a8", "a10", "a15"]
BUDOWNICTWO_ARTICLES = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a9"]


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Sekcja 1: asystent BDO (INN-01) ───────────────────────────────────────────
def bdo_assistant(registered: bool = False, company_size: str = "mikro") -> dict:
    fee = BDO["rejestracja_fees"].get(company_size, 100)
    return {
        "registered": registered,
        "company_size": company_size,
        "rejestracja_fee": fee,
        "alert": "rejestracja w BDO wymagana — opłata "
                 f"{fee} PLN" if not registered else "zarejestrowany — monitoruj ewidencję kwartalną",
        "next_deadline": "ewidencja odpadów — do 15. dnia po kwartale; sprawozdanie roczne — do 15.03",
        "note": "asystent BDO — rejestracja, opłaty (100-500 PLN), ewidencja kwartalna, terminy",
    }


# ── Sekcja 1: generator KPO (INN-02) ──────────────────────────────────────────
def kpo_generator(ewc_code: str = "") -> dict:
    valid = bool(re.match(r"^\d{2} \d{2} \d{2}$", ewc_code)) or bool(re.match(r"^\d{6}$", ewc_code))
    return {
        "waste_type": ewc_code,
        "ewc_valid": valid,
        "kpo_required": ewc_code != "",
        "form": "KPO elektroniczne — wypełniane w systemie BDO przy przekazaniu odpadów",
        "note": "generator KPO — kod EWC (6 cyfr), formularz elektroniczny BDO",
    }


# ── Sekcja 1: tracker terminów sprawozdań BDO (INN-03) ────────────────────────
def bdo_deadline_tracker() -> dict:
    return {
        "deadlines": [
            "ewidencja kwartalna — do 15. dnia po kwartale",
            "sprawozdanie roczne o odpadach — do 15.03",
            "sprawozdanie o opakowaniach — do 15.03",
            "sprawozdanie WEEE/baterie — do 15.03",
        ],
        "note": "tracker terminów sprawozdań BDO — ewidencja kwartalna i sprawozdania roczne",
    }


# ── Sekcja 1: tracker opłat produktowych (INN-04) ─────────────────────────────
def product_fee_tracker(packaging_kg: float = 0.0, weee_reporting: bool = False) -> dict:
    fee = round2(packaging_kg * BDO["packaging_fee_rate"])
    return {
        "packaging_placed_kg": packaging_kg,
        "packaging_fee_rate": BDO["packaging_fee_rate"],
        "packaging_fee_due": fee,
        "weee_reporting": weee_reporting,
        "note": "tracker opłat produktowych — opakowania (art. 17-18 UoO), WEEE, baterie",
    }


# ── Sekcja 2: kalkulator pozwolenia na budowę / zgłoszenia (INN-05) ───────────
def budowlane_pozwolenie_calculator(project_type: str = "nowy_budynek") -> dict:
    return {
        "project_type": project_type,
        "requires_permit": project_type in ("nowy_budynek", "rozbudowa"),
        "requires_notice": project_type in ("remont", "wiata"),
        "nadzor": BDO["budowlane_nadzor"],
        "note": "kalkulator pozwolenia/zgłoszenia — typ inwestycji (prawo budowlane art. 28-30)",
    }


# ── Sekcja 5: kalkulator CBAM (INN-06) ────────────────────────────────────────
def cbam_calculator(co2_t: float = 0.0, value: float = 0.0) -> dict:
    return {
        "import_value": value,
        "embedded_emissions_t": co2_t,
        "cbam_price_eur_t": BDO["cbam_price_eur_t"],
        "cbam_due_eur": round2(co2_t * BDO["cbam_price_eur_t"]),
        "note": "kalkulator CBAM — wbudowane emisje CO2 × cena EU ETS (raportowanie kwartalne od 2023)",
    }


# ── Sekcja 4: kalkulator tax-free VAT-REF (INN-10) ────────────────────────────
def taxfree_calculator(sale_amount: float = 0.0) -> dict:
    refundable = round2(sale_amount * BDO["taxfree_vat_rate"] / 1.23)
    return {
        "sale_to_tourist": sale_amount,
        "vat_rate": BDO["taxfree_vat_rate"],
        "vat_refundable": refundable,
        "note": "kalkulator tax-free — zwrot VAT dla podróżnych (VAT-REF, art. 127-130 VAT)",
    }


# ── Sekcja 4: asystent sezonowości (INN-11) ───────────────────────────────────
def seasonal_assistant(seasonal: bool = False, season_months: int = 0) -> dict:
    return {
        "seasonal": seasonal,
        "season_months": season_months,
        "note": "asystent sezonowości — rozliczenia roczne vs okresowe, zwolnienie VAT a sezon",
    }


# ── Sekcja 3: kalkulator podatku rolnego (INN-12) ─────────────────────────────
def agricultural_tax_calculator(ha_conversion: float = 0.0) -> dict:
    per_ha = round2(2.5 * BDO["agricultural_rye_pln_q"])
    return {
        "hectares_conversion": ha_conversion,
        "rye_price_per_quintal": BDO["agricultural_rye_pln_q"],
        "tax_per_ha": per_ha,
        "annual_tax": round2(ha_conversion * 2.5 * BDO["agricultural_rye_pln_q"]),
        "note": "kalkulator podatku rolnego — 2,5 q żyta/ha przeliczeniowego × cena (89,63 zł/q 2026)",
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def audit_rego_files() -> dict:
    rule_ids = []
    files_audited = []
    texts = []

    bdo_dir = BASE_DIR / "rules" / "micro" / "bdo"
    module_files = {
        "bdo_rejestracja": "bdo_rejestracja.rego",
        "bdo_ewidencja": "bdo_ewidencja.rego",
        "bdo_ewc": "bdo_ewc.rego",
        "bdo_transport": "bdo_transport.rego",
        "bdo_zezwolenia": "bdo_zezwolenia.rego",
        "bdo_weee_baterie": "bdo_weee_baterie.rego",
    }
    for mod, fname in module_files.items():
        f = bdo_dir / fname
        if f.exists():
            files_audited.append(f"micro/bdo/{fname}")
            t = f.read_text(encoding="utf-8")
            texts.append(t)
            rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    srodowisko_f = BASE_DIR / "rules" / "micro" / "srodowisko" / "srodowisko.rego"
    if srodowisko_f.exists():
        files_audited.append("micro/srodowisko/srodowisko.rego")
        t = srodowisko_f.read_text(encoding="utf-8")
        texts.append(t)
        rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    budownictwo_f = BASE_DIR / "rules" / "micro" / "budownictwo" / "budownictwo.rego"
    if budownictwo_f.exists():
        files_audited.append("micro/budownictwo/budownictwo.rego")
        t = budownictwo_f.read_text(encoding="utf-8")
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

    # Moduły BDO (per plik) + środowisko + budownictwo
    modules = {}
    bdo_counts = {}
    for mod, fname in module_files.items():
        f = bdo_dir / fname
        if f.exists():
            bdo_counts[mod] = len(re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', f.read_text(encoding="utf-8")))
        else:
            bdo_counts[mod] = 0
    modules["bdo_rejestracja"] = {"status": "COMPLETE" if bdo_counts["bdo_rejestracja"] > 0 else "MISSING", "rules": bdo_counts["bdo_rejestracja"]}
    modules["bdo_ewidencja"] = {"status": "COMPLETE" if bdo_counts["bdo_ewidencja"] > 0 else "MISSING", "rules": bdo_counts["bdo_ewidencja"]}
    modules["bdo_ewc"] = {"status": "COMPLETE" if bdo_counts["bdo_ewc"] > 0 else "MISSING", "rules": bdo_counts["bdo_ewc"]}
    modules["bdo_transport"] = {"status": "COMPLETE" if bdo_counts["bdo_transport"] > 0 else "MISSING", "rules": bdo_counts["bdo_transport"]}
    modules["bdo_zezwolenia"] = {"status": "COMPLETE" if bdo_counts["bdo_zezwolenia"] > 0 else "MISSING", "rules": bdo_counts["bdo_zezwolenia"]}
    modules["bdo_weee_baterie"] = {"status": "COMPLETE" if bdo_counts["bdo_weee_baterie"] > 0 else "MISSING", "rules": bdo_counts["bdo_weee_baterie"]}
    modules["srodowisko"] = {"status": "COMPLETE" if len(_find_articles(unique, SRODOWISKO_ARTICLES, "srodowisko")) > 0 else "MISSING", "rules": sum(1 for rid in unique if ".srodowisko." in rid)}
    modules["budownictwo"] = {"status": "COMPLETE" if len(_find_articles(unique, BUDOWNICTWO_ARTICLES, "budownictwo")) > 0 else "MISSING", "rules": sum(1 for rid in unique if ".budownictwo." in rid)}

    missing = sum(1 for m in modules.values() if m["status"] != "COMPLETE")
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
        "modules": modules,
        "srodowisko_articles": {a: {"rules": len(_find_articles(unique, [a], "srodowisko"))} for a in SRODOWISKO_ARTICLES},
        "budownictwo_articles": {a: {"rules": len(_find_articles(unique, [a], "budownictwo"))} for a in BUDOWNICTWO_ARTICLES},
        "coverage": {
            "total": len(PRIORITY_MODULES),
            "complete": len(PRIORITY_MODULES) - missing,
            "missing": missing,
            "gap_pct": round2(missing / len(PRIORITY_MODULES) * 100) if PRIORITY_MODULES else 0.0,
        },
    }


def _find_articles(unique, articles, pkg=""):
    """Zwraca rule_id z unikalnych pasujące do artykułów w obrębie pakietu
    (np. ".srodowisko.a7." — bez fałszywych trafień z innych pakietów)."""
    found = []
    for rid in unique:
        for art in articles:
            pattern = rf"\.{re.escape(pkg)}\.{re.escape(art)}\." if pkg else rf"\.{re.escape(art)}\."
            if re.search(pattern, rid):
                found.append(rid)
    return sorted(set(found))


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
        description="NexusAI JDG — P15 Środowisko + BDO + Branża Auditor (Enterprise)")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików micro (domyślne)")
    parser.add_argument("--bdo-assistant", action="store_true", help="asystent BDO (rejestracja, opłaty)")
    parser.add_argument("--kpo", action="store_true", help="generator kart przekazania odpadów KPO")
    parser.add_argument("--deadlines", action="store_true", help="tracker terminów sprawozdań BDO")
    parser.add_argument("--product-fee", action="store_true", help="tracker opłat produktowych")
    parser.add_argument("--permit", action="store_true", help="kalkulator pozwolenia na budowę / zgłoszenia")
    parser.add_argument("--cbam", action="store_true", help="kalkulator CBAM")
    parser.add_argument("--taxfree", action="store_true", help="kalkulator tax-free VAT-REF")
    parser.add_argument("--seasonal", action="store_true", help="asystent sezonowości")
    parser.add_argument("--agricultural", action="store_true", help="kalkulator podatku rolnego")
    parser.add_argument("--registered", action="store_true", help="czy zarejestrowany w BDO")
    parser.add_argument("--company-size", type=str, default="mikro", help="wielkość firmy (mikro/mały/średni)")
    parser.add_argument("--ewc-code", type=str, default="", help="kod EWC odpadu (6 cyfr)")
    parser.add_argument("--packaging-kg", type=float, default=0.0, help="masa opakowań (kg)")
    parser.add_argument("--project-type", type=str, default="nowy_budynek", help="typ inwestycji")
    parser.add_argument("--co2-t", type=float, default=0.0, help="wbudowane emisje CO2 (t)")
    parser.add_argument("--import-value", type=float, default=0.0, help="wartość importu (PLN)")
    parser.add_argument("--sale-amount", type=float, default=0.0, help="sprzedaż (PLN)")
    parser.add_argument("--ha-conversion", type=float, default=0.0, help="ha przeliczeniowe")
    parser.add_argument("--table", action="store_true", help="format tabelaryczny")
    parser.add_argument("--out", type=str, default="", help="zapis JSON do pliku")
    args = parser.parse_args()

    result = {"tool": "bdo_environment_auditor", "module": "P15 Środowisko + BDO + Branża"}

    funcs = [args.bdo_assistant, args.kpo, args.deadlines, args.product_fee,
             args.permit, args.cbam, args.taxfree, args.seasonal, args.agricultural]
    if args.audit or not any(funcs):
        result["audit"] = audit_rego_files()
    if args.bdo_assistant:
        result["bdo_assistant"] = bdo_assistant(args.registered, args.company_size)
    if args.kpo:
        result["kpo"] = kpo_generator(args.ewc_code)
    if args.deadlines:
        result["deadlines"] = bdo_deadline_tracker()
    if args.product_fee:
        result["product_fee"] = product_fee_tracker(args.packaging_kg)
    if args.permit:
        result["permit"] = budowlane_pozwolenie_calculator(args.project_type)
    if args.cbam:
        result["cbam"] = cbam_calculator(args.co2_t, args.import_value)
    if args.taxfree:
        result["taxfree"] = taxfree_calculator(args.sale_amount)
    if args.seasonal:
        result["seasonal"] = seasonal_assistant()
    if args.agricultural:
        result["agricultural"] = agricultural_tax_calculator(args.ha_conversion)

    if args.table:
        if "audit" in result:
            a = result["audit"]
            print(f"AUDYT MICRO BDO+ŚRODOWISKO+BUDOWNICTWO: {a['total_rule_ids']} rule_id | "
                  f"{a['unique_count']} unikalnych | duplikaty: {a['duplicate_count']} | stuby: {a['stub_count']}")
            print(f"  Pokrycie modułów: {a['coverage']['complete']}/{a['coverage']['total']} "
                  f"(gap {a['coverage']['gap_pct']}%)")
            missing = [k for k, v in a["modules"].items() if v["status"] != "COMPLETE"]
            if missing:
                print(f"  Braki: {', '.join(missing)}")
        if "bdo_assistant" in result:
            ba = result["bdo_assistant"]
            print(f"\nBDO ASSISTANT ({ba['company_size']}): opłata {ba['rejestracja_fee']} PLN | {ba['alert']}")
        if "kpo" in result:
            k = result["kpo"]
            print(f"\nKPO: kod {k['waste_type']!r} | poprawny: {k['ewc_valid']} | wymagany: {k['kpo_required']}")
        if "product_fee" in result:
            pf = result["product_fee"]
            print(f"\nOPŁATA PRODUKTOWA: {pf['packaging_placed_kg']} kg × {pf['packaging_fee_rate']} = "
                  f"{pf['packaging_fee_due']} PLN")
        if "permit" in result:
            p = result["permit"]
            print(f"\nPOZWOLENIE ({p['project_type']}): pozwolenie: {p['requires_permit']} | "
                  f"zgłoszenie: {p['requires_notice']}")
        if "cbam" in result:
            c = result["cbam"]
            print(f"\nCBAM: {c['embedded_emissions_t']} t CO2 × {c['cbam_price_eur_t']} = "
                  f"{c['cbam_due_eur']} EUR")
        if "taxfree" in result:
            t = result["taxfree"]
            print(f"\nTAX-FREE: sprzedaż {t['sale_to_tourist']} → zwrot VAT {t['vat_refundable']} PLN")
        if "agricultural" in result:
            ag = result["agricultural"]
            print(f"\nPODATEK ROLNY: {ag['hectares_conversion']} ha × {ag['tax_per_ha']} = "
                  f"{ag['annual_tax']} PLN/rok")
        return 0

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano: {args.out}")
        return 0

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
