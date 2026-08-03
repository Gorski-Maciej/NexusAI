#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P12 Cross-Border Auditor (Enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzędzie audytowe dla warstwy Cross-Border + MDR/DAC6 + TP + CFC + FX
# (raport analityczny P12 v8.0). Audytuje realne pliki rego:
# JDG/rules/micro/crossborder/crossborder.rego (193 rule_id, artykuły a20-a86r),
# micro/plan33_cb.rego. Generuje dane JSON do wstrzyknięcia jako
# data.jdg.crossborder_audit (pokrycie artykułów, duplikaty, stuby).
#
# Funkcje:
#   --audit          pełny audyt plików micro cross-border (domyślne)
#   --place-supply   auto-kalkulator miejsca świadczenia (art. 28a-28o VAT)
#   --mdr            auto-detektor schematów MDR/DAC6 (hallmarks A-E)
#   --residency      silnik decyzji rezydencji podatkowej (art. 3 PIT)
#   --tp             kalkulator dokumentacji TP (art. 23zf PIT)
#   --cfc            kalkulator CFC (art. 30f PIT)
#   --fx             kalkulator różnic kursowych (art. 24c PIT)
#   --exit-tax       kalkulator exit tax (art. 30da PIT)
#   --wdt            tracker dokumentów WDT (art. 13 VAT — 30 dni)
#   --compliance     panel ryzyka transgranicznego
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

# ── Progi ustawowe 2026 (spójne z data.jdg.thresholds.crossborder — ADR-002) ──
CB = {
    "wdt_documentation_days": 30,          # art. 13 VAT — dowód wywozu 30 dni
    "mdr_deadline_days": 30,               # MDR — raport 30 dni
    "exit_tax_threshold_pln": 4000000,     # art. 30da PIT — próg 4M PLN
    "exit_tax_rate_pct": 19,               # art. 30da PIT — stawka 19%
    "cfc_ownership_min_pct": 50,           # art. 30f PIT — udział 50%
    "cfc_passive_income_pct": 33,          # art. 30f PIT — przychody pasywne 33%
    "cfc_tax_rate_threshold_pct": 14.25,   # art. 30f PIT — efektywny podatek <14,25%
    "tp_local_file_pln": 500000,           # art. 23zf PIT — dokumentacja lokalna 500k
    "tp_master_file_pln": 200000000,       # art. 23zf PIT — master file 200M
    "residency_days": 183,                 # art. 3 PIT — 183 dni
}

# Priorytetowe artykuły cross-border (spójne z pakietem rego)
PRIORITY_ARTICLES = [
    "a20", "a23o", "a23zf", "a29", "a30da", "a30f", "a86r",
    "a25b", "a25c", "a25d", "a86o", "a24c",
]


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Sekcja 2: auto-kalkulator miejsca świadczenia (INN-01) ────────────────────
def place_of_supply_calculator(service_type: str = "b2b",
                               customer_country: str = "DE",
                               vendor_country: str = "PL") -> dict:
    mapping = {
        "b2b": ("siedziba_nabywcy", "miejsce siedziby nabywcy B2B (art. 28b)"),
        "b2c": ("siedziba_uslugodawcy", "miejsce siedziby usługodawcy B2C (art. 28c)"),
        "real_estate": ("poloz_nieruchomosci", "miejsce położenia nieruchomości (art. 28e)"),
        "transport": ("przebieg_transportu", "przebieg transportu (art. 28f)"),
        "e_services": ("miejsce_konsumenta", "miejsce konsumenta e-usługi (art. 28i, OSS)"),
    }
    supply_place, vat_place = mapping.get(service_type, mapping["b2b"])
    return {
        "service_type": service_type,
        "customer_country": customer_country,
        "vendor_country": vendor_country,
        "supply_place": supply_place,
        "cross_border": customer_country != vendor_country,
        "vat_place": vat_place,
        "note": "art. 28a-28o Ustawy o VAT — B2B miejsce nabywcy, B2C miejsce usługodawcy, e-usługi OSS",
    }


# ── Sekcja 3: auto-detektor schematów MDR/DAC6 (INN-02) ───────────────────────
def mdr_auto_detector(tax_saving_primary: bool = False,
                      confidentiality_clause: bool = False,
                      cross_border_related: bool = False,
                      tax_haven: bool = False,
                      no_substance: bool = False) -> dict:
    hallmark_map = {
        "A": tax_saving_primary,
        "B": no_substance,
        "C": cross_border_related,
        "D": confidentiality_clause,
        "E": tax_haven,
    }
    matched = [h for h, v in hallmark_map.items() if v]
    return {
        "indicators": hallmark_map,
        "matched_hallmarks": matched,
        "mdr_report_required": len(matched) > 0,
        "report_deadline_days": CB["mdr_deadline_days"],
        "note": f"raport MDR w {CB['mdr_deadline_days']} dni (formularz MDR-1) — hallmarks A-E (OrdPU art. 86a-86o)",
    }


# ── Sekcja 4: silnik decyzji rezydencji podatkowej (INN-03) ───────────────────
def residency_decision_engine(days_in_poland: int = 200,
                              center_of_life_pl: bool = True,
                              center_of_business_pl: bool = True) -> dict:
    resident = days_in_poland >= CB["residency_days"] or center_of_life_pl or center_of_business_pl
    return {
        "days_in_poland": days_in_poland,
        "residency_days_threshold": CB["residency_days"],
        "center_of_life_pl": center_of_life_pl,
        "center_of_business_pl": center_of_business_pl,
        "resident_pl": resident,
        "note": "rezydencja PL — 183 dni pobytu lub centrum interesów życiowych/gospodarczych (art. 3 ust. 1a PIT)",
    }


# ── Sekcja 4: kalkulator dokumentacji TP (INN-05) ─────────────────────────────
def tp_documentation_calculator(related_party_revenue: float = 600000.0) -> dict:
    return {
        "related_party_revenue": related_party_revenue,
        "local_file_threshold": CB["tp_local_file_pln"],
        "master_file_threshold": CB["tp_master_file_pln"],
        "local_file_required": related_party_revenue >= CB["tp_local_file_pln"],
        "master_file_required": related_party_revenue >= CB["tp_master_file_pln"],
        "note": "dokumentacja lokalna od 500k PLN transakcji z podmiotami powiązanymi (art. 23zf PIT)",
    }


# ── Sekcja 4: kalkulator CFC (INN-08) ─────────────────────────────────────────
def cfc_calculator(ownership_pct: float = 60.0,
                   passive_income_pct: float = 40.0,
                   effective_tax_rate: float = 10.0) -> dict:
    cfc = (ownership_pct >= CB["cfc_ownership_min_pct"]
           and passive_income_pct >= CB["cfc_passive_income_pct"]
           and effective_tax_rate < CB["cfc_tax_rate_threshold_pct"])
    return {
        "ownership_pct": ownership_pct,
        "passive_income_pct": passive_income_pct,
        "effective_tax_rate": effective_tax_rate,
        "cfc_applies": cfc,
        "thresholds": {
            "ownership_min": CB["cfc_ownership_min_pct"],
            "passive_income_min": CB["cfc_passive_income_pct"],
            "tax_rate_max": CB["cfc_tax_rate_threshold_pct"],
        },
        "note": "CFC: udział ≥50%, przychody pasywne ≥33%, efektywny podatek <14,25% (art. 30f PIT)",
    }


# ── Sekcja 4: kalkulator różnic kursowych (INN-07) ────────────────────────────
def fx_difference_calculator(receivable_fx: float = 10000.0,
                             exchange_rate_receipt: float = 4.20,
                             exchange_rate_due: float = 4.30) -> dict:
    diff = round2(receivable_fx * (exchange_rate_due - exchange_rate_receipt))
    return {
        "receivable_fx": receivable_fx,
        "exchange_rate_receipt": exchange_rate_receipt,
        "exchange_rate_due": exchange_rate_due,
        "fx_difference": diff,
        "method": "metoda podatkowa (art. 24c PIT) — różnica między kursem otrzymania a kursem wymagalności",
    }


# ── Sekcja 5: kalkulator exit tax (INN-10) ────────────────────────────────────
def exit_tax_calculator(assets_value: float = 5000000.0) -> dict:
    applies = assets_value >= CB["exit_tax_threshold_pln"]
    tax_due = round2(assets_value * CB["exit_tax_rate_pct"] / 100) if applies else 0.0
    return {
        "assets_value": assets_value,
        "threshold_pln": CB["exit_tax_threshold_pln"],
        "exit_tax_applies": applies,
        "tax_due": tax_due,
        "installments": "rozłożenie na raty do 5 lat (art. 30db PIT)",
        "note": "exit tax — zmiana rezydencji/transfer aktywów ≥4M PLN, stawka 19% (art. 30da PIT)",
    }


# ── Sekcja 7: tracker dokumentów WDT (INN-04) ─────────────────────────────────
def wdt_documentation_tracker(deliveries: list) -> dict:
    missing = [d for d in deliveries if not d.get("documentation_ok", False)]
    return {
        "deliveries_count": len(deliveries),
        "deadline_days": CB["wdt_documentation_days"],
        "documents_missing": missing,
        "alert": "brak dowodu wywozu w 30 dni → utrata stawki 0% WDT (art. 13 VAT)",
    }


# ── Sekcja 7: panel ryzyka transgranicznego (INN-12) ──────────────────────────
def crossborder_compliance_panel(cross_penalties: int = 0) -> dict:
    return {
        "checks": {
            "wnt_wdt": "dokumentacja 30 dni — stawka 0%",
            "miejsce_swiadczenia": "art. 28a-28o — poprawna kwalifikacja",
            "mdr": "raport 30 dni — hallmarks A-E",
            "tp": "dokumentacja lokalna/master od progów",
            "cfc": "test 50%/33%/14,25%",
            "rezydencja": "test 183 dni / centrum interesów",
            "exit_tax": "próg 4M — zmiana rezydencji",
        },
        "cross_penalties": cross_penalties,
        "compliance_score": max(0, 100 - cross_penalties * 10),
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def audit_rego_files() -> dict:
    rule_ids = []
    files_audited = []
    texts = []

    micro_dir = BASE_DIR / "rules" / "micro" / "crossborder"
    if micro_dir.exists():
        for f in sorted(micro_dir.glob("*.rego")):
            files_audited.append(f"micro/crossborder/{f.name}")
            t = f.read_text(encoding="utf-8")
            texts.append(t)
            rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    plan33 = BASE_DIR / "rules" / "micro" / "plan33_cb.rego"
    if plan33.exists():
        files_audited.append("micro/plan33_cb.rego")
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
        refs = sum(1 for rid in unique if re.match(rf"jdg\.micro\.crossborder\.{re.escape(art)}(?:\.|$)", rid))
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
        description="NexusAI JDG — P12 Cross-Border Auditor (Enterprise)")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików micro cross-border (domyślne)")
    parser.add_argument("--place-supply", action="store_true", help="auto-kalkulator miejsca świadczenia (art. 28a-28o)")
    parser.add_argument("--mdr", action="store_true", help="auto-detektor schematów MDR/DAC6")
    parser.add_argument("--residency", action="store_true", help="silnik decyzji rezydencji (art. 3 PIT)")
    parser.add_argument("--tp", action="store_true", help="kalkulator dokumentacji TP (art. 23zf)")
    parser.add_argument("--cfc", action="store_true", help="kalkulator CFC (art. 30f)")
    parser.add_argument("--fx", action="store_true", help="kalkulator różnic kursowych (art. 24c)")
    parser.add_argument("--exit-tax", action="store_true", help="kalkulator exit tax (art. 30da)")
    parser.add_argument("--wdt", action="store_true", help="tracker dokumentów WDT (art. 13)")
    parser.add_argument("--compliance", action="store_true", help="panel ryzyka transgranicznego")
    parser.add_argument("--service-type", type=str, default="b2b", help="typ usługi: b2b/b2c/real_estate/transport/e_services")
    parser.add_argument("--customer-country", type=str, default="DE", help="kraj nabywcy")
    parser.add_argument("--vendor-country", type=str, default="PL", help="kraj usługodawcy")
    parser.add_argument("--days-in-poland", type=int, default=200, help="dni pobytu w PL")
    parser.add_argument("--related-party-revenue", type=float, default=600000.0, help="przychody z podmiotami powiązanymi (PLN)")
    parser.add_argument("--ownership-pct", type=float, default=60.0, help="udział w CFC (%)")
    parser.add_argument("--passive-income-pct", type=float, default=40.0, help="przychody pasywne CFC (%)")
    parser.add_argument("--effective-tax-rate", type=float, default=10.0, help="efektywny podatek CFC (%)")
    parser.add_argument("--receivable-fx", type=float, default=10000.0, help="należność w walucie")
    parser.add_argument("--rate-receipt", type=float, default=4.20, help="kurs otrzymania")
    parser.add_argument("--rate-due", type=float, default=4.30, help="kurs wymagalności")
    parser.add_argument("--assets-value", type=float, default=5000000.0, help="wartość aktywów (exit tax)")
    parser.add_argument("--cross-penalties", type=int, default=0, help="liczba kar transgranicznych")
    parser.add_argument("--table", action="store_true", help="format tabelaryczny")
    parser.add_argument("--out", type=str, default="", help="zapis JSON do pliku")
    args = parser.parse_args()

    result = {"tool": "crossborder_auditor", "module": "P12 Cross-Border/MDR/TP/CFC/FX"}

    if args.audit or not (args.place_supply or args.mdr or args.residency or args.tp or
                          args.cfc or args.fx or args.exit_tax or args.wdt or args.compliance):
        result["audit"] = audit_rego_files()
    if args.place_supply:
        result["place_of_supply"] = place_of_supply_calculator(
            args.service_type, args.customer_country, args.vendor_country)
    if args.mdr:
        result["mdr"] = mdr_auto_detector(
            tax_saving_primary=True, cross_border_related=True)
    if args.residency:
        result["residency"] = residency_decision_engine(args.days_in_poland)
    if args.tp:
        result["tp"] = tp_documentation_calculator(args.related_party_revenue)
    if args.cfc:
        result["cfc"] = cfc_calculator(args.ownership_pct, args.passive_income_pct,
                                       args.effective_tax_rate)
    if args.fx:
        result["fx"] = fx_difference_calculator(args.receivable_fx,
                                                args.rate_receipt, args.rate_due)
    if args.exit_tax:
        result["exit_tax"] = exit_tax_calculator(args.assets_value)
    if args.wdt:
        result["wdt"] = wdt_documentation_tracker([
            {"delivery_id": "D-1", "documentation_ok": True},
            {"delivery_id": "D-2", "documentation_ok": False},
        ])
    if args.compliance:
        result["compliance"] = crossborder_compliance_panel(args.cross_penalties)

    if args.table:
        if "audit" in result:
            a = result["audit"]
            print(f"AUDYT MICRO CROSS-BORDER: {a['total_rule_ids']} rule_id | {a['unique_count']} unikalnych | "
                  f"duplikaty: {a['duplicate_count']} | stuby: {a['stub_count']}")
            print(f"  Pokrycie artykułów: {a['coverage']['complete']}/{a['coverage']['total']} "
                  f"(gap {a['coverage']['gap_pct']}%)")
            missing = [k for k, v in a["articles"].items() if v["status"] == "MISSING"]
            if missing:
                print(f"  Braki: {', '.join(missing)}")
        if "place_of_supply" in result:
            p = result["place_of_supply"]
            print(f"\nMIEJSCE ŚWIADCZENIA ({p['service_type']}): {p['vat_place']} | "
                  f"transgraniczna: {p['cross_border']}")
        if "mdr" in result:
            m = result["mdr"]
            print(f"\nMDR: hallmarks {m['matched_hallmarks']} | raport wymagany: {m['mdr_report_required']} "
                  f"({m['report_deadline_days']} dni)")
        if "residency" in result:
            r = result["residency"]
            print(f"\nREZYDENCJA: {r['days_in_poland']} dni → rezydent PL: {r['resident_pl']}")
        if "tp" in result:
            t = result["tp"]
            print(f"\nTP: lokalna {t['local_file_required']} | master {t['master_file_required']} "
                  f"(przychody {t['related_party_revenue']:,.0f})")
        if "cfc" in result:
            c = result["cfc"]
            print(f"\nCFC: zastosowanie {c['cfc_applies']} (udział {c['ownership_pct']}%, "
                  f"pasywne {c['passive_income_pct']}%, podatek {c['effective_tax_rate']}%)")
        if "fx" in result:
            f = result["fx"]
            print(f"\nRÓŻNICE KURSOWE: {f['fx_difference']:,.2f} PLN ({f['method']})")
        if "exit_tax" in result:
            e = result["exit_tax"]
            print(f"\nEXIT TAX: zastosowanie {e['exit_tax_applies']} | podatek {e['tax_due']:,.2f} PLN")
        return 0

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano: {args.out}")
        return 0

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
