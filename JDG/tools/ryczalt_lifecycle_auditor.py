#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P13 Ryczałt + Cykl Życia Auditor (Enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzędzie audytowe dla warstwy ryczałtu i cyklu życia JDG (raport P13 v8.0).
# Audytuje realne pliki rego: JDG/rules/micro/ryczalt/ryczalt.rego (156 rule_id,
# artykuły a4-a30), micro/plan33_ryc.rego (159), micro/pp/pp.rego (148),
# micro/ceidg/ceidg.rego (43), micro/sukcesja/sukcesja.rego (138).
# Generuje dane JSON do wstrzyknięcia jako data.jdg.p13_audit.
#
# Funkcje:
#   --audit          pełny audyt plików micro (domyślne)
#   --rate           auto-kalkulator stawki ryczałtu z kodu PKWiU (art. 12)
#   --limit          tracker limitu 2 mln EUR (art. 6)
#   --tax-card       audyt karty podatkowej (art. 21-28)
#   --lifecycle      asystent cyklu życia JDG (fazy, kalendarz obowiązków)
#   --succession     tracker sukcesji krok po kroku (2 lata / 5 lat)
#   --suspension     audyt zawieszeń (art. 22-25 PP)
#   --unregistered   audyt działalności nieewidencjonowanej (art. 6 PP)
#   --compare        symulator ryczałt vs skala vs liniowy
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

# ── Progi ustawowe 2026 (spójne z data.jdg.thresholds.ryczalt — ADR-002) ──────
RYC = {
    "limit_eur": 2000000,             # art. 6 ust. 4 — limit 2 mln EUR
    "eur_rate_pln": 4.50,             # kurs EUR
    "min_wage_2026": 4800,            # płaca minimalna 2026
    "nieewidencjonowana_pct": 50,      # art. 6 PP — 50% płacy minimalnej
    "zawieszenie_max_months": 24,     # art. 22 PP — max 24 mies.
    "succession_standard_months": 24, # zarząd sukcesyjny — 2 lata
    "succession_extended_months": 60, # przedłużenie do 5 lat
    "ceidg_wpis_days": 7,             # CEIDG — wpis 7 dni
    "karta_limit_zatrudnienia": 5,    # karta podatkowa — max 5 pracowników
}

# Stawki ryczałtu wg PKWiU (art. 12 ust. 1 ustawy o ryczałcie)
PKWIU_RATES = {
    "G": ("3%", "handel hurtowy i detaliczny (sekcja G)"),
    "C": ("5,5%", "działalność wytwórcza, budowlana (sekcje C, F)"),
    "F": ("5,5%", "działalność wytwórcza, budowlana (sekcje C, F)"),
    "H": ("12,5%", "usługi transportowe i magazynowe (sekcja H)"),
    "I": ("15%", "usługi gastronomiczne i zakwaterowanie (sekcja I)"),
    "J": ("12%", "usługi specjalistyczne (m.in. IT — sekcja J)"),
    "M": ("14%", "usługi architektoniczne i inżynierskie (sekcja M)"),
    "K": ("8,5%", "działalność usługowa (sekcja K)"),
    "H-U": ("8,5%", "działalność usługowa (sekcje H-U z wyłączeniami)"),
}

# Priorytetowe artykuły ryczałtu (spójne z pakietem rego)
PRIORITY_ARTICLES = ["a4", "a6", "a8", "a12", "a15", "a21", "a27", "a29", "a30"]


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Sekcja 1: auto-kalkulator stawki ryczałtu z kodu PKWiU (INN-01) ───────────
def pkwiu_section(code: str) -> str:
    """Sekcja PKWiU z kodu (prefiks)."""
    if code.startswith(("45", "46", "47")):
        return "G"
    if code.startswith(("10", "41", "42", "43")):
        return "F"  # budowlana/wytwórcza — stawka 5,5%
    if code.startswith(("49", "50", "51", "52", "53")):
        return "H"
    if code.startswith(("55", "56")):
        return "I"
    if code.startswith(("62", "63")):
        return "J"
    if code.startswith(("69", "70", "71", "72", "73", "74")):
        return "M"
    return "H-U"


def ryczalt_rate_calculator(pkwiu_code: str) -> dict:
    section = pkwiu_section(pkwiu_code)
    rate, description = PKWIU_RATES.get(section, PKWIU_RATES["H-U"])
    return {
        "pkwiu_code": pkwiu_code,
        "pkwiu_section": section,
        "rate": rate,
        "description": description,
        "note": "stawka ryczałtu wg PKWiU (art. 12 ust. 1 ustawy o ryczałcie) — auto-kalkulator z kodu",
    }


# ── Sekcja 1: tracker limitu 2 mln EUR (INN-02) ───────────────────────────────
def ryczalt_limit_tracker(revenue_ytd: float) -> dict:
    limit_pln = round2(RYC["limit_eur"] * RYC["eur_rate_pln"])
    usage_pct = round2(revenue_ytd / limit_pln * 100) if limit_pln else 0.0
    return {
        "revenue_ytd": revenue_ytd,
        "limit_eur": RYC["limit_eur"],
        "limit_pln": limit_pln,
        "usage_pct": usage_pct,
        "warning_at_75pct": revenue_ytd >= round2(limit_pln * 75 / 100),
        "exceeds_limit": revenue_ytd > limit_pln,
        "note": "przekroczenie limitu 2 mln EUR → utrata ryczałtu od następnego dnia (art. 6 ust. 4)",
    }


# ── Sekcja 2: audyt karty podatkowej ──────────────────────────────────────────
def karta_podatkowa_audit() -> dict:
    return {
        "zasady": "stawki miesięczne wg tabel — zależne od rodzaju działalności, liczby zatrudnionych i miejsca wykonywania",
        "stawki_miesieczne": "kwoty stałe wg tabel (art. 23-25)",
        "limit_zatrudnienia": RYC["karta_limit_zatrudnienia"],
        "zgłoszenie": "wniosek do US do 20. dnia miesiąca poprzedzającego (art. 29)",
        "note": "karta podatkowa — forma zryczałtowana dla wybranych rodzajów działalności (art. 21-28)",
    }


# ── Sekcja 3: asystent cyklu życia JDG (INN-03) ───────────────────────────────
def lifecycle_phase(months_active: int) -> str:
    if months_active < 0:
        return "PRE_START"
    if months_active < 6:
        return "STARTUP_RELIEF"
    if months_active < 30:
        return "STARTUP_PREFERENTIAL"
    if months_active < 60:
        return "GROWTH"
    return "MATURITY"


def lifecycle_assistant(months_active: int) -> dict:
    phase = lifecycle_phase(months_active)
    phases = {
        "PRE_START": "CEIDG-1, ZUS ZUA 7 dni, rachunek firmowy, wybór formy PIT (art. 5-7 CEIDG)",
        "STARTUP_RELIEF": "ulga na start 0 zł ZUS społeczne (0-6 mies., art. 18a SUS)",
        "STARTUP_PREFERENTIAL": "preferencyjny ZUS 30% podstawy (6-30 mies., max 24 mies., art. 18c SUS)",
        "GROWTH": "limit VAT 200k → VAT-R, KSeF od 2026, pierwszy pracownik (art. 113 VAT)",
        "MATURITY": "optymalizacja skala→liniowy, JDG→sp. z o.o., CIT estoński (art. 9a PIT)",
    }
    return {
        "months_active": months_active,
        "current_phase": phase,
        "phase_description": phases[phase],
        "obligations_calendar": [
            "CEIDG aktualizacja w 7 dni",
            "ZUS DRA do 10. dnia miesiąca",
            "VAT-7 do 25. dnia",
            "PIT-28 do 31.01",
            "KSeF e-faktury od 2026",
        ],
        "note": "asystent cyklu życia JDG — kalendarz obowiązków per faza",
    }


# ── Sekcja 4: tracker sukcesji krok po kroku (INN-04) ─────────────────────────
def succession_tracker(months_elapsed: int = 0) -> dict:
    return {
        "steps": [
            "1. Powołanie zarządcy (akt notarialny) za życia",
            "2. Wpis do CEIDG w 14 dni",
            "3. Zawiadomienie US/ZUS o sukcesji",
            "4. Kontynuacja działalności na NIP zmarłego",
            "5. Rozliczenie podatków (ryczałt/PIT) w imieniu firmy",
            "6. Monitorowanie terminu 2 lat / przedłużenie do 5 lat",
        ],
        "months_elapsed": months_elapsed,
        "standard_months": RYC["succession_standard_months"],
        "extended_months": RYC["succession_extended_months"],
        "months_remaining": RYC["succession_standard_months"] - months_elapsed,
        "extended_available": months_elapsed > RYC["succession_standard_months"],
        "note": "tracker sukcesji — zarządca sukcesyjny, 2 lata + przedłużenie do 5 lat (art. 3-15 z.s.)",
    }


# ── Sekcja 5: audyt zawieszeń (art. 22-25 PP) ─────────────────────────────────
def suspension_audit() -> dict:
    return {
        "art22_25": {
            "max_months": RYC["zawieszenie_max_months"],
            "min_days": 30,
            "zus_social": "brak składek społecznych w okresie zawieszenia",
            "zus_health": "składka zdrowotna nadal płacona (art. 36a SUS)",
            "vat": "możliwość zawieszenia rozliczeń VAT",
        },
        "resumption": "wznowienie — zgłoszenie CEIDG (art. 25 PP)",
        "note": "zawieszenie działalności — art. 22-25 Prawa Przedsiębiorców",
    }


# ── Sekcja 5: działalność nieewidencjonowana (INN-05 — art. 6 PP) ─────────────
def unregistered_business_audit(monthly_revenue: float) -> dict:
    limit = round2(RYC["min_wage_2026"] * RYC["nieewidencjonowana_pct"] / 100)
    return {
        "monthly_revenue": monthly_revenue,
        "limit_monthly": limit,
        "min_wage_2026": RYC["min_wage_2026"],
        "within_limit": monthly_revenue <= limit,
        "note": "działalność nieewidencjonowana — przychody do 50% płacy minimalnej miesięcznie (art. 6 PP)",
    }


# ── Sekcja 7: symulator ryczałt vs skala vs liniowy (INN-09) ──────────────────
def pit_form_comparator(annual_revenue: float, ryczalt_rate_pct: float = 8.5) -> dict:
    ryczalt_tax = round2(annual_revenue * ryczalt_rate_pct / 100)
    skala_tax = round2(annual_revenue * 0.12)
    liniowy_tax = round2(annual_revenue * 0.19)
    best = min((ryczalt_tax, "ryczałt"), (skala_tax, "skala"), (liniowy_tax, "liniowy"))[1]
    return {
        "annual_revenue": annual_revenue,
        "ryczalt_rate_pct": ryczalt_rate_pct,
        "ryczalt_tax": ryczalt_tax,
        "skala_tax": skala_tax,
        "liniowy_tax": liniowy_tax,
        "best_form": best,
        "note": "symulator ryczałt vs skala (12%) vs liniowy (19%) — wybór najkorzystniejszej formy (PIT art. 9a, 30c)",
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def audit_rego_files() -> dict:
    rule_ids = []
    files_audited = []
    texts = []

    dirs = [
        ("micro/ryczalt", BASE_DIR / "rules" / "micro" / "ryczalt"),
        ("micro/pp", BASE_DIR / "rules" / "micro" / "pp"),
        ("micro/ceidg", BASE_DIR / "rules" / "micro" / "ceidg"),
        ("micro/sukcesja", BASE_DIR / "rules" / "micro" / "sukcesja"),
    ]
    for label, d in dirs:
        if d.exists():
            for f in sorted(d.glob("*.rego")):
                files_audited.append(f"{label}/{f.name}")
                t = f.read_text(encoding="utf-8")
                texts.append(t)
                rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    plan33 = BASE_DIR / "rules" / "micro" / "plan33_ryc.rego"
    if plan33.exists():
        files_audited.append("micro/plan33_ryc.rego")
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
        refs = sum(1 for rid in unique if re.match(rf"jdg\.micro\.ryczalt\.{re.escape(art)}(?:\.|$)", rid))
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
        description="NexusAI JDG — P13 Ryczałt + Cykl Życia Auditor (Enterprise)")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików micro (domyślne)")
    parser.add_argument("--rate", action="store_true", help="auto-kalkulator stawki ryczałtu z PKWiU")
    parser.add_argument("--limit", action="store_true", help="tracker limitu 2 mln EUR")
    parser.add_argument("--tax-card", action="store_true", help="audyt karty podatkowej")
    parser.add_argument("--lifecycle", action="store_true", help="asystent cyklu życia JDG")
    parser.add_argument("--succession", action="store_true", help="tracker sukcesji")
    parser.add_argument("--suspension", action="store_true", help="audyt zawieszeń")
    parser.add_argument("--unregistered", action="store_true", help="audyt działalności nieewidencjonowanej")
    parser.add_argument("--compare", action="store_true", help="symulator ryczałt vs skala vs liniowy")
    parser.add_argument("--pkwiu-code", type=str, default="6201", help="kod PKWiU")
    parser.add_argument("--revenue-ytd", type=float, default=5000000.0, help="przychód od początku roku (PLN)")
    parser.add_argument("--months-active", type=int, default=3, help="miesiące aktywności JDG")
    parser.add_argument("--succession-months", type=int, default=10, help="miesiące zarządu sukcesyjnego")
    parser.add_argument("--monthly-revenue", type=float, default=2000.0, help="miesięczny przychód (nieewidencjonowana)")
    parser.add_argument("--annual-revenue", type=float, default=300000.0, help="roczny przychód (porównanie form)")
    parser.add_argument("--ryczalt-rate", type=float, default=8.5, help="stawka ryczałtu % (porównanie form)")
    parser.add_argument("--table", action="store_true", help="format tabelaryczny")
    parser.add_argument("--out", type=str, default="", help="zapis JSON do pliku")
    args = parser.parse_args()

    result = {"tool": "ryczalt_lifecycle_auditor", "module": "P13 Ryczałt + Cykl Życia JDG"}

    if args.audit or not (args.rate or args.limit or args.tax_card or args.lifecycle or
                          args.succession or args.suspension or args.unregistered or args.compare):
        result["audit"] = audit_rego_files()
    if args.rate:
        result["rate"] = ryczalt_rate_calculator(args.pkwiu_code)
    if args.limit:
        result["limit"] = ryczalt_limit_tracker(args.revenue_ytd)
    if args.tax_card:
        result["tax_card"] = karta_podatkowa_audit()
    if args.lifecycle:
        result["lifecycle"] = lifecycle_assistant(args.months_active)
    if args.succession:
        result["succession"] = succession_tracker(args.succession_months)
    if args.suspension:
        result["suspension"] = suspension_audit()
    if args.unregistered:
        result["unregistered"] = unregistered_business_audit(args.monthly_revenue)
    if args.compare:
        result["compare"] = pit_form_comparator(args.annual_revenue, args.ryczalt_rate)

    if args.table:
        if "audit" in result:
            a = result["audit"]
            print(f"AUDYT MICRO RYCZAŁT+CYKL: {a['total_rule_ids']} rule_id | {a['unique_count']} unikalnych | "
                  f"duplikaty: {a['duplicate_count']} | stuby: {a['stub_count']}")
            print(f"  Pokrycie artykułów ryczałtu: {a['coverage']['complete']}/{a['coverage']['total']} "
                  f"(gap {a['coverage']['gap_pct']}%)")
            missing = [k for k, v in a["articles"].items() if v["status"] == "MISSING"]
            if missing:
                print(f"  Braki: {', '.join(missing)}")
        if "rate" in result:
            r = result["rate"]
            print(f"\nSTAWKA RYCZAŁTU (PKWiU {r['pkwiu_code']}, sekcja {r['pkwiu_section']}): {r['rate']} — {r['description']}")
        if "limit" in result:
            l = result["limit"]
            print(f"\nLIMIT 2M EUR: {l['revenue_ytd']:,.0f} / {l['limit_pln']:,.0f} PLN "
                  f"({l['usage_pct']}%) | przekroczenie: {l['exceeds_limit']}")
        if "lifecycle" in result:
            lc = result["lifecycle"]
            print(f"\nCYKL ŻYCIA: {lc['months_active']} mies. → faza {lc['current_phase']}")
        if "succession" in result:
            s = result["succession"]
            print(f"\nSUKCESJA: {s['months_elapsed']} mies. → pozostało {s['months_remaining']} (2 lata), "
                  f"przedłużenie do {s['extended_months']} mies.")
        if "unregistered" in result:
            u = result["unregistered"]
            print(f"\nNIEEWIDENCJONOWANA: {u['monthly_revenue']:,.0f} / {u['limit_monthly']:,.0f} PLN "
                  f"(50% płacy min.) → w limicie: {u['within_limit']}")
        if "compare" in result:
            c = result["compare"]
            print(f"\nPORÓWNANIE FORM: ryczałt {c['ryczalt_tax']:,.0f} | skala {c['skala_tax']:,.0f} | "
                  f"liniowy {c['liniowy_tax']:,.0f} → NAJKORZYSTNIEJSZY: {c['best_form']}")
        return 0

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano: {args.out}")
        return 0

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
