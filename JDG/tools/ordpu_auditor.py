#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P11 Ordynacja Podatkowa Auditor (Enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzędzie audytowe dla warstwy Ordynacji Podatkowej (raport analityczny P11 v8.0).
# Audytuje realne pliki rego: JDG/rules/micro/ord/ord.rego (424 rule_id,
# artykuły a16-a193a), plan33_ord.rego. Generuje dane JSON do wstrzyknięcia
# jako data.jdg.ordpu_audit (pokrycie artykułów, duplikaty, stuby).
#
# Funkcje:
#   --audit          pełny audyt plików micro OrdPU (domyślne)
#   --limitations    kalendarz przedawnień per zobowiązanie (art. 70)
#   --interest       kalkulator odsetek (art. 56 — 200% lombardu)
#   --corrections    silnik auto-korekty deklaracji (art. 81/81b)
#   --overpayment    audyt nadpłat (art. 72-80)
#   --gaar           audyt GAAR (art. 119a)
#   --white-list     monitor Białej Listy (art. 117ba — 30 dni, 20%)
#   --correspondence audyt auto-korespondencji z urzędem
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

# ── Progi ustawowe 2026 (spójne z data.jdg.thresholds.ordpu — ADR-002) ────────
ORD = {
    "limitation_years": 5,              # art. 70 §1 — 5 lat od końca roku
    "correction_years": 5,              # art. 81b — korekta do 5 lat
    "interest_rate_pct": 200,           # art. 56 §1 — 200% lombardu
    "white_list_days": 30,              # art. 117ba — zawiadomienie 30 dni
    "white_list_penalty_pct": 20,       # art. 117ba — sankcja 20%
    "overpayment_refund_months": 3,     # art. 77 — zwrot nadpłaty 3 mies.
    "interpretation_days": 30,          # art. 14d — wydanie interpretacji 30 dni
    "appeal_days": 14,                  # art. 223 — odwołanie 14 dni
    "gaar_artificiality_threshold": 60, # art. 119a — próg sztuczności (0-100)
}

# Priorytetowe artykuły OrdPU (spójne z pakietem rego)
PRIORITY_ARTICLES = [
    "a16", "a53", "a56b", "a67a", "a67b", "a67c", "a67d", "a67e", "a70",
    "a72", "a77", "a78", "a81", "a81b", "a117ba", "a119a", "a138a", "a193a",
    "a14a", "a14d",
]


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Sekcja 2: kalendarz przedawnień (INN-01) ──────────────────────────────────
def limitation_calendar(liabilities: list, current_year: int = 2026) -> dict:
    alerts = []
    urgent = []
    for l in liabilities:
        deadline_year = l["tax_year"] + ORD["limitation_years"]
        years_left = deadline_year - current_year
        entry = {
            "tax_type": l["tax_type"],
            "tax_year": l["tax_year"],
            "deadline": f"31.12.{deadline_year}",
            "years_left": years_left,
        }
        alerts.append(entry)
        if years_left <= 1:
            urgent.append(entry)
    return {
        "alerts": alerts,
        "urgent": urgent,
        "limitation_years": ORD["limitation_years"],
        "note": "zobowiązanie przedawnia się z upływem 5 lat od końca roku podatkowego (art. 70 §1 OrdPU)",
    }


# ── Sekcja 2: kalkulator odsetek (INN-02) ─────────────────────────────────────
def interest_calculator(arrears: float, days_overdue: int) -> dict:
    annual_rate = ORD["interest_rate_pct"]
    daily_rate = round2(annual_rate / 365)
    interest = round2(arrears * (annual_rate / 365) / 100 * days_overdue)
    return {
        "arrears": arrears,
        "days_overdue": days_overdue,
        "annual_rate_pct": annual_rate,
        "daily_rate": daily_rate,
        "interest_due": interest,
        "note": f"stawka podstawowa 200% lombardu (art. 56 §1) — odsetki: {interest:.2f} PLN za {days_overdue} dni",
    }


# ── Sekcja 3: silnik auto-korekty (INN-03) ────────────────────────────────────
def auto_correction_engine(original_tax: float, corrected_tax: float,
                           tax_year: int, current_year: int = 2026,
                           days_overdue: int = 0) -> dict:
    diff = round2(corrected_tax - original_tax)
    within = tax_year >= current_year - ORD["correction_years"]
    if diff > 0:
        direction = "dopłata (zaległość)"
        interest = round2(diff * (ORD["interest_rate_pct"] / 365) / 100 * days_overdue)
    elif diff < 0:
        direction = "nadpłata (zwrot)"
        interest = 0
    else:
        direction = "bez zmian"
        interest = 0
    return {
        "original_tax": original_tax,
        "corrected_tax": corrected_tax,
        "difference": diff,
        "direction": direction,
        "within_5y": within,
        "interest_on_arrears": interest,
        "note": f"korekta możliwa do {ORD['correction_years']} lat od końca roku (art. 81b OrdPU)",
    }


# ── Sekcja 5: GAAR (art. 119a) ────────────────────────────────────────────────
def gaar_audit(artificiality_score: int) -> dict:
    threshold = ORD["gaar_artificiality_threshold"]
    return {
        "artificiality_score": artificiality_score,
        "artificiality_threshold": threshold,
        "gaar_risk": "WYSOKIE" if artificiality_score >= threshold else "NISKIE",
        "art119a": {
            "conditions": ["korzyść podatkowa", "sprzeczność z celem ustawy", "sztuczność działania"],
            "effect": "pominięcie skutków czynności sztucznej — domiar podatku",
        },
    }


# ── Sekcja 5: Biała Lista (art. 117ba) ────────────────────────────────────────
def white_list_monitor(amount: float, vendor_white_listed: bool = True,
                       paid_to_listed_account: bool = True,
                       notified_within_30d: bool = True) -> dict:
    sanction = 0.0
    if vendor_white_listed and not paid_to_listed_account and not notified_within_30d:
        sanction = round2(amount * ORD["white_list_penalty_pct"] / 100)
    return {
        "amount": amount,
        "vendor_white_listed": vendor_white_listed,
        "paid_to_listed_account": paid_to_listed_account,
        "notified_within_30d": notified_within_30d,
        "sanction": sanction,
        "sanction_pct": ORD["white_list_penalty_pct"],
        "note": "płatność na rachunek spoza Białej Listy bez zawiadomienia w 30 dni → sankcja 20% (art. 117ba OrdPU)",
    }


# ── Sekcja 4: audyt auto-korespondencji ───────────────────────────────────────
def correspondence_audit() -> dict:
    return {
        "integrated_packages": [
            "tax_authority_interaction (auto-generacja pism do US/KAS/ZUS)",
            "tax_correspondence_engine (silnik korespondencji)",
            "tax_ruling_autodrafter (auto-draft interpretacji)",
            "overpayment_auto_claimer (auto-wnioski o zwrot nadpłaty)",
            "proceeding_tracker (tracker postępowań)",
            "poa_manager (pełnomocnictwa art. 138a-138o)",
        ],
        "proceeding_flow": [
            "1. Pismo do US (wniosek/zawiadomienie)",
            "2. Postępowanie podatkowe (art. 120-129)",
            "3. Decyzja / interpretacja (art. 14d — 30 dni)",
            "4. Odwołanie (14 dni, art. 223)",
            "5. Rozstrzygnięcie II instancji / sąd",
        ],
        "appeal_days": ORD["appeal_days"],
        "interpretation_days": ORD["interpretation_days"],
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def audit_rego_files() -> dict:
    rule_ids = []
    files_audited = []
    texts = []

    micro_dir = BASE_DIR / "rules" / "micro" / "ord"
    if micro_dir.exists():
        for f in sorted(micro_dir.glob("*.rego")):
            files_audited.append(f"micro/ord/{f.name}")
            t = f.read_text(encoding="utf-8")
            texts.append(t)
            rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    plan33 = BASE_DIR / "rules" / "micro" / "plan33_ord.rego"
    if plan33.exists():
        files_audited.append("micro/plan33_ord.rego")
        t = plan33.read_text(encoding="utf-8")
        texts.append(t)
        rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    # GLM52 P11 — reguły atomiczno-porządkowe (a70, a81b, a117ba, a119a,
    # a193a, a282b, a14a, a14d) żyją w kks_ord_atomic_p11.rego; bez tego pliku
    # audyt pokazywałby fałszywe MISSING (kontynuacja części 06 kampanii V3).
    atomic = BASE_DIR / "rules" / "micro" / "kks_ord_atomic_p11.rego"
    if atomic.exists():
        files_audited.append("micro/kks_ord_atomic_p11.rego")
        t = atomic.read_text(encoding="utf-8")
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

    covered = set()
    for rid in unique:
        m = re.match(r"jdg\.micro\.ord\.(a\d+[a-z]?)", rid)
        if m:
            covered.add(m.group(1))

    articles = {}
    for art in PRIORITY_ARTICLES:
        refs = sum(1 for rid in unique if re.match(rf"jdg\.micro\.ord\.{re.escape(art)}(?:\.|$)", rid))
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
        description="NexusAI JDG — P11 Ordynacja Podatkowa Auditor (Enterprise)")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików micro OrdPU (domyślne)")
    parser.add_argument("--limitations", action="store_true", help="kalendarz przedawnień (art. 70)")
    parser.add_argument("--interest", action="store_true", help="kalkulator odsetek (art. 56)")
    parser.add_argument("--corrections", action="store_true", help="silnik auto-korekty (art. 81/81b)")
    parser.add_argument("--overpayment", action="store_true", help="audyt nadpłat (art. 72-80)")
    parser.add_argument("--gaar", action="store_true", help="audyt GAAR (art. 119a)")
    parser.add_argument("--white-list", action="store_true", help="monitor Białej Listy (art. 117ba)")
    parser.add_argument("--correspondence", action="store_true", help="audyt auto-korespondencji")
    parser.add_argument("--current-year", type=int, default=2026, help="bieżący rok")
    parser.add_argument("--arrears", type=float, default=10000.0, help="kwota zaległości (PLN)")
    parser.add_argument("--days-overdue", type=int, default=60, help="dni zwłoki")
    parser.add_argument("--original-tax", type=float, default=10000.0, help="podatek pierwotny")
    parser.add_argument("--corrected-tax", type=float, default=12000.0, help="podatek skorygowany")
    parser.add_argument("--tax-year", type=int, default=2023, help="rok podatkowy korekty")
    parser.add_argument("--artificiality", type=int, default=70, help="scoring sztuczności GAAR (0-100)")
    parser.add_argument("--payment-amount", type=float, default=50000.0, help="kwota płatności (Biała Lista)")
    parser.add_argument("--not-listed-account", action="store_true", help="płatność na konto spoza Białej Listy")
    parser.add_argument("--no-notification", action="store_true", help="brak zawiadomienia w 30 dni")
    parser.add_argument("--table", action="store_true", help="format tabelaryczny")
    parser.add_argument("--out", type=str, default="", help="zapis JSON do pliku")
    args = parser.parse_args()

    result = {"tool": "ordpu_auditor", "module": "P11 Ordynacja Podatkowa"}

    if args.audit or not (args.limitations or args.interest or args.corrections or
                          args.overpayment or args.gaar or args.white_list or
                          args.correspondence):
        result["audit"] = audit_rego_files()
    if args.limitations:
        result["limitation_calendar"] = limitation_calendar([
            {"tax_type": "VAT", "tax_year": 2021},
            {"tax_type": "PIT", "tax_year": 2024},
        ], args.current_year)
    if args.interest:
        result["interest"] = interest_calculator(args.arrears, args.days_overdue)
    if args.corrections:
        result["corrections"] = auto_correction_engine(args.original_tax, args.corrected_tax,
                                                       args.tax_year, args.current_year, args.days_overdue)
    if args.overpayment:
        result["overpayment"] = {
            "art72": "nadpłata — nadpłacony podatek (deklaracja, decyzja, zaliczka)",
            "art77": f"zwrot nadpłaty — do {ORD['overpayment_refund_months']} miesięcy od złożenia wniosku",
            "art78": "oprocentowanie nadpłaty — od dnia powstania do dnia zwrotu",
        }
    if args.gaar:
        result["gaar"] = gaar_audit(args.artificiality)
    if args.white_list:
        result["white_list"] = white_list_monitor(args.payment_amount,
                                                  paid_to_listed_account=not args.not_listed_account,
                                                  notified_within_30d=not args.no_notification)
    if args.correspondence:
        result["correspondence"] = correspondence_audit()

    if args.table:
        if "audit" in result:
            a = result["audit"]
            print(f"AUDYT MICRO ORDPU: {a['total_rule_ids']} rule_id | {a['unique_count']} unikalnych | "
                  f"duplikaty: {a['duplicate_count']} | stuby: {a['stub_count']}")
            print(f"  Pokrycie artykułów: {a['coverage']['complete']}/{a['coverage']['total']} "
                  f"(gap {a['coverage']['gap_pct']}%)")
            missing = [k for k, v in a["articles"].items() if v["status"] == "MISSING"]
            if missing:
                print(f"  Braki: {', '.join(missing)}")
        if "limitation_calendar" in result:
            l = result["limitation_calendar"]
            print("\nKALENDARZ PRZEDAWNIEŃ (art. 70):")
            for a in l["alerts"]:
                flag = " ⚠ URGENT" if a in l["urgent"] else ""
                print(f"  {a['tax_type']} {a['tax_year']} → przedawnienie {a['deadline']} ({a['years_left']} lat){flag}")
        if "interest" in result:
            i = result["interest"]
            print(f"\nODSETKI: {i['arrears']:,.2f} PLN × {i['days_overdue']} dni @ {i['annual_rate_pct']}% = {i['interest_due']:,.2f} PLN")
        if "corrections" in result:
            c = result["corrections"]
            print(f"\nAUTO-KOREKTA: {c['direction']} | różnica {c['difference']:,.2f} | odsetki {c['interest_on_arrears']:,.2f}")
        if "gaar" in result:
            g = result["gaar"]
            print(f"\nGAAR (art. 119a): sztuczność {g['artificiality_score']}/{g['artificiality_threshold']} → {g['gaar_risk']}")
        if "white_list" in result:
            w = result["white_list"]
            print(f"\nBIAŁA LISTA (art. 117ba): sankcja = {w['sanction']:,.2f} PLN ({w['sanction_pct']}%)")
        return 0

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano: {args.out}")
        return 0

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
