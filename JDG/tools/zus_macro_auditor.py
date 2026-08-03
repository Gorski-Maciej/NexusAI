#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P07 ZUS/SUS Macro Auditor (Enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzędzie audytowe dla warstwy makro ZUS/SUS (raport analityczny P07 v8.0).
# Audytuje realne pliki rego: JDG/rules/zus.rego + JDG/rules/zus/*.rego
# (macierz stawek zdrowotnej, zasiłki, podstawa wymiaru, terminy) oraz
# generuje dane JSON do wstrzyknięcia jako data.jdg.zus_audit (pokrycie
# artykułów) i data.jdg.thresholds.zus (limity temporalne).
#
# Funkcje:
#   --audit           pełny audyt plików ZUS (domyślne)
#   --health          kalkulator składki zdrowotnej per forma
#   --social          kalkulator składek społecznych (19,52/8/2,45/1,67%)
#   --benefit         kalkulator zasiłków (chorobowy/macierzyński/rehab)
#   --titles          silnik zbiegów tytułów (etat/emeryt/student/urlop)
#   --snapshot        migawka thresholdów ZUS 2022-2026 (temporalne)
#   --verify-base     weryfikator podstawy wymiaru (minimalna vs standard)
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

# ── Limity ustawowe 2026 (spójne z data.jdg.thresholds.zus — ADR-002) ────────
HEALTH = {
    "scale_rate": 0.09,           # skala — 9% od dochodu
    "linear_rate": 0.049,         # liniowy — 4,9% od dochodu
    "linear_deduction_limit": 14100.0,  # PLN/rok max odliczenia
    "lump_tier_1_limit": 60000,   # ryczałt — próg 1 przychodu
    "lump_tier_2_limit": 300000,  # ryczałt — próg 2 przychodu
    "lump_tier_1_amount": 491.40,  # 60% przeciętnego 2026
    "lump_tier_2_amount": 819.00,  # 100% przeciętnego 2026
    "lump_tier_3_amount": 1474.20,  # 180% przeciętnego 2026
    "tax_card_rate": 0.09,        # karta — 9% od minimalnego
}

SOCIAL = {
    "emerytalna": 0.1952,
    "rentowa": 0.08,
    "chorobowa": 0.0245,
    "wypadkowa": 0.0167,
    "total": 0.3164,
}

LIMITS_2026 = {
    "minimum_wage_gross": 4800.0,
    "social_base_standard": 5204.40,   # 60% × 8674
    "social_30x_limit": 318600.0,
    "maly_zus_plus_income_limit": 60000.0,
    "maly_zus_plus_revenue_limit": 120000.0,
    "sickness_annual_limit": 85528.0,
    "preferential_base_rate": 0.30,
    "maly_zus_plus_base_rate": 0.30,
    "pfron_employees_threshold": 25,
    "solidarity_rate": 0.0145,
}

# Migawki temporalne 2022-2026 (minimalne wynagrodzenie, podstawa, ryczałt T2)
TEMPORAL = {
    2022: {"min_wage": 3010.0, "base": 3474.60, "lump_t2": 559.44},
    2023: {"min_wage": 3490.0, "base": 4161.00, "lump_t2": 641.94},
    2024: {"min_wage": 4242.0, "base": 4694.40, "lump_t2": 724.50},
    2025: {"min_wage": 4666.0, "base": 5054.40, "lump_t2": 797.16},
    2026: {"min_wage": 4800.0, "base": 5204.40, "lump_t2": 819.00},
}

# Zbiegi tytułów — macierz obowiązków (art. 9 SUS)
TITLES = {
    "etat_jdg": {"social": False, "health": True,
                 "note": "Zbieg etat+JDG — z JDG tylko składka zdrowotna",
                 "legal_basis": "Art. 9 ust. 1a-2 SUS"},
    "emeryt_jdg": {"social": False, "health": True,
                   "note": "Emeryt + JDG — z JDG tylko zdrowotna",
                   "legal_basis": "Art. 9 ust. 1, art. 9a SUS"},
    "student_jdg": {"social": False, "health": True,
                    "note": "Student <26 lat + JDG — z JDG tylko zdrowotna",
                    "legal_basis": "Art. 9 ust. 1 pkt 1-2, art. 6 ust. 1 pkt 4 SUS"},
    "urlop_wychowawczy_jdg": {"social": False, "health": True,
                              "note": "Urlop wychowawczy + JDG — z JDG tylko zdrowotna",
                              "legal_basis": "Art. 9 ust. 1c SUS"},
    "none": {"social": True, "health": True,
             "note": "Brak zbiegu — pełne składki z JDG",
             "legal_basis": "Art. 6, 8, 9 SUS"},
}

# Priorytetowe artykuły ZUS (klucze pokrycia)
PRIORITY_ARTICLES = [
    "a81", "a66", "a9", "a18", "a22", "a47", "a4", "a7",
    "a48", "a36", "a24", "a5", "a8", "a14", "a19", "a30",
]


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Sekcja 1: składka zdrowotna ────────────────────────────────────────────────
def health_scale_contribution(income: float) -> float:
    return round2(income * HEALTH["scale_rate"])


def health_linear_contribution(income: float) -> float:
    return round2(income * HEALTH["linear_rate"])


def health_lump_contribution(revenue: float) -> float:
    if revenue <= HEALTH["lump_tier_1_limit"]:
        return HEALTH["lump_tier_1_amount"]
    if revenue <= HEALTH["lump_tier_2_limit"]:
        return HEALTH["lump_tier_2_amount"]
    return HEALTH["lump_tier_3_amount"]


def health_tax_card_contribution() -> float:
    return round2(LIMITS_2026["minimum_wage_gross"] * HEALTH["tax_card_rate"])


def health_calculator(income: float, revenue: float) -> dict:
    candidates = {
        "skala_9pct": health_scale_contribution(income),
        "liniowy_4p9pct": health_linear_contribution(income),
        "ryczałt": health_lump_contribution(revenue),
        "karta_9pct_min": health_tax_card_contribution(),
    }
    cheapest = min(candidates, key=candidates.get)
    return {
        "comparison": candidates,
        "cheapest_form": cheapest,
        "cheapest_amount": candidates[cheapest],
        "minimum_monthly": round2(LIMITS_2026["minimum_wage_gross"] * HEALTH["scale_rate"]),
        "annual_scale": round2(health_scale_contribution(income) * 12),
        "annual_linear": round2(health_linear_contribution(income) * 12),
        "annual_lump": round2(health_lump_contribution(revenue) * 12),
        "annual_tax_card": round2(health_tax_card_contribution() * 12),
        "linear_deduction_limit": HEALTH["linear_deduction_limit"],
    }


# ── Sekcja 2: składki społeczne ────────────────────────────────────────────────
def social_contribution_calculator(base: float) -> dict:
    return {
        "emerytalna": round2(base * SOCIAL["emerytalna"]),
        "rentowa": round2(base * SOCIAL["rentowa"]),
        "chorobowa": round2(base * SOCIAL["chorobowa"]),
        "wypadkowa": round2(base * SOCIAL["wypadkowa"]),
        "total": round2(base * SOCIAL["total"]),
        "base": round2(base),
    }


def social_calculator() -> dict:
    standard_base = LIMITS_2026["social_base_standard"]
    pref_base = round2(LIMITS_2026["minimum_wage_gross"] * LIMITS_2026["preferential_base_rate"])
    mzp_base = round2(LIMITS_2026["minimum_wage_gross"] * LIMITS_2026["maly_zus_plus_base_rate"])
    return {
        "standard_base": standard_base,
        "standard_monthly": social_contribution_calculator(standard_base),
        "preferential_base": pref_base,
        "preferential_monthly": social_contribution_calculator(pref_base),
        "maly_zus_base": mzp_base,
        "maly_zus_monthly": social_contribution_calculator(mzp_base),
        "rates": SOCIAL,
        "deadlines": {"osoba_fizyczna": "10 dzień miesiąca",
                      "spolka_osobowa": "15 dzień miesiąca",
                      "platnik_zatrudniajacy": "20 dzień miesiąca"},
        "thirty_x_limit": LIMITS_2026["social_30x_limit"],
    }


# ── Sekcja 3: zasiłki ──────────────────────────────────────────────────────────
def benefit_calculator(base: float) -> dict:
    daily = round2(base / 30)
    return {
        "sickness_80pct_daily": round2(daily * 0.80),
        "sickness_100pct_daily": round2(daily),
        "maternity_100pct_daily": round2(daily),
        "rehab_90pct_daily": round2(daily * 0.90),
        "care_80pct_daily": round2(daily * 0.80),
        "annual_limit": LIMITS_2026["sickness_annual_limit"],
        "waiting_months": 3,
        "maternity_days_20wks": 140,
    }


# ── Sekcja 4: PPK/PFRON/FS ─────────────────────────────────────────────────────
def ppk_pfron_solidarity(employees: int) -> dict:
    return {
        "ppk": {"employee": 0.02, "employer_min": 0.015, "employer_max": 0.04},
        "pfron": {"threshold": 25, "quota": 0.06, "obliged": employees >= 25},
        "solidarity": {"rate": 0.0145},
        "employees": employees,
    }


# ── Sekcja 5: zbiegi tytułów ───────────────────────────────────────────────────
def titles_engine(concurrent_title: str) -> dict:
    return TITLES.get(concurrent_title, TITLES["none"])


# ── Sekcja 6: migawki temporalne ───────────────────────────────────────────────
def temporal_snapshot() -> dict:
    out = {}
    for year, data in sorted(TEMPORAL.items()):
        out[str(year)] = data
    changes = {}
    prev = None
    for year in sorted(TEMPORAL):
        if prev is not None:
            changes[str(year)] = {
                "min_wage_pct": round2((TEMPORAL[year]["min_wage"] - prev["min_wage"]) / prev["min_wage"] * 100),
                "base_pct": round2((TEMPORAL[year]["base"] - prev["base"]) / prev["base"] * 100),
            }
        prev = TEMPORAL[year]
    return {"snapshots": out, "changes": changes}


# ── Audyt realnych plików rego ─────────────────────────────────────────────────
def audit_rego_files() -> dict:
    zus_core = BASE_DIR / "rules" / "zus.rego"
    zus_dir = BASE_DIR / "rules" / "zus"
    rule_ids = []
    files_audited = []
    texts = []
    if zus_core.exists():
        files_audited.append("zus.rego")
        t = zus_core.read_text(encoding="utf-8")
        texts.append(t)
        rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)
    if zus_dir.exists():
        for f in sorted(zus_dir.glob("*.rego")):
            files_audited.append(f"zus/{f.name}")
            t = f.read_text(encoding="utf-8")
            texts.append(t)
            rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    total = len(rule_ids)
    unique = sorted(set(rule_ids))
    # no_match = architektoniczny fallback per plik współdzielonego pakietu jdg.zus
    # (każdy plik deklaruje własny default decide) — to NIE jest konflikt reguł.
    no_match_defaults = sum(1 for rid in rule_ids if rid.endswith(".no_match"))
    real_rule_ids = [rid for rid in rule_ids if not rid.endswith(".no_match")]
    duplicates = sorted({rid for rid in set(real_rule_ids) if real_rule_ids.count(rid) > 1})

    # Pokrycie artykułów — rule_id ZUS są name-based (np. jdg.zus.sickness_benefit_eligibility),
    # więc mapujemy przez _legal_basis / tekst komentarzy ("Art. N") zamiast prefiksu rule_id.
    article_terms = {
        "a81": r"Art\.\s*81\b", "a66": r"Art\.\s*66\b", "a9": r"Art\.\s*9\b",
        "a18": r"Art\.\s*18\b", "a22": r"Art\.\s*22\b", "a47": r"Art\.\s*47\b",
        "a4": r"Art\.\s*4\b", "a7": r"Art\.\s*7\b", "a48": r"Art\.\s*48\b",
        "a36": r"Art\.\s*36\b", "a24": r"Art\.\s*24\b", "a5": r"Art\.\s*5\b",
        "a8": r"Art\.\s*8\b", "a14": r"Art\.\s*14\b", "a19": r"Art\.\s*19\b",
        "a30": r"Art\.\s*30\b",
    }
    combined = "\n".join(texts)
    articles = {}
    for art in PRIORITY_ARTICLES:
        term = article_terms.get(art, r"")
        refs = len(re.findall(term, combined)) if term else 0
        articles[art] = {"status": "COMPLETE" if refs > 0 else "MISSING",
                         "legal_basis_refs": refs}

    total_arts = len(PRIORITY_ARTICLES)
    missing = sum(1 for a in articles.values() if a["status"] == "MISSING")
    return {
        "files_audited": files_audited,
        "total_rule_ids": total,
        "unique_rule_ids": unique,
        "unique_count": len(unique),
        "no_match_defaults": no_match_defaults,
        "duplicates": duplicates,
        "duplicate_count": len(duplicates),
        "articles": articles,
        "coverage": {
            "total": total_arts,
            "complete": total_arts - missing,
            "missing": missing,
            "gap_pct": round2(missing / total_arts * 100) if total_arts else 0.0,
        },
    }


# ── CLI ────────────────────────────────────────────────────────────────────────
def main() -> int:
    parser = argparse.ArgumentParser(
        description="NexusAI JDG — P07 ZUS/SUS Macro Auditor (Enterprise)")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików rego (domyślne)")
    parser.add_argument("--health", action="store_true", help="kalkulator składki zdrowotnej")
    parser.add_argument("--social", action="store_true", help="kalkulator składek społecznych")
    parser.add_argument("--benefit", action="store_true", help="kalkulator zasiłków")
    parser.add_argument("--titles", action="store_true", help="silnik zbiegów tytułów")
    parser.add_argument("--snapshot", action="store_true", help="migawka thresholdów 2022-2026")
    parser.add_argument("--verify-base", action="store_true", help="weryfikator podstawy wymiaru")
    parser.add_argument("--ppk", action="store_true", help="audyt PPK/PFRON/fundusz solidarnościowy")
    parser.add_argument("--income", type=float, default=10000.0, help="dochód miesięczny (PLN)")
    parser.add_argument("--revenue", type=float, default=120000.0, help="przychód roczny (PLN)")
    parser.add_argument("--base", type=float, default=5204.40, help="podstawa wymiaru (PLN)")
    parser.add_argument("--title", type=str, default="etat_jdg", help="zbieg tytułów")
    parser.add_argument("--employees", type=int, default=10, help="liczba pracowników")
    parser.add_argument("--table", action="store_true", help="format tabelaryczny")
    parser.add_argument("--out", type=str, default="", help="zapis JSON do pliku")
    args = parser.parse_args()

    result = {"tool": "zus_macro_auditor", "module": "P07 ZUS/SUS Macro"}

    if args.audit or not (args.health or args.social or args.benefit or
                          args.titles or args.snapshot or args.verify_base):
        result["audit"] = audit_rego_files()
    if args.health:
        result["health"] = health_calculator(args.income, args.revenue)
    if args.social:
        result["social"] = social_calculator()
    if args.benefit:
        result["benefit"] = benefit_calculator(args.base)
    if args.titles:
        result["titles"] = {"concurrent_title": args.title,
                            "obligation": titles_engine(args.title)}
    if args.snapshot:
        result["temporal"] = temporal_snapshot()
    if args.verify_base:
        min_base = round2(LIMITS_2026["minimum_wage_gross"] * LIMITS_2026["preferential_base_rate"])
        result["base_verification"] = {
            "declared_base": args.base,
            "minimum_base": min_base,
            "standard_base": LIMITS_2026["social_base_standard"],
            "below_minimum": args.base < min_base,
            "recommended": max(args.base, min_base),
        }
    if args.ppk:
        result["ppk_pfron_solidarity"] = ppk_pfron_solidarity(args.employees)

    if args.table:
        if "health" in result:
            print("SKŁADKA ZDROWOTNA (miesięcznie, PLN):")
            for form, amount in result["health"]["comparison"].items():
                print(f"  {form:<18} {amount:>10.2f}")
            print(f"  {'NAJNIŻSZA':<18} {result['health']['cheapest_amount']:>10.2f}  ({result['health']['cheapest_form']})")
        if "social" in result:
            print("SKŁADKI SPOŁECZNE (standard, PLN):")
            for fund, amount in result["social"]["standard_monthly"].items():
                print(f"  {fund:<12} {amount:>10.2f}")
        if "base_verification" in result:
            b = result["base_verification"]
            print(f"WERYFIKACJA PODSTAWY: zadeklarowana {b['declared_base']:.2f} | min {b['minimum_base']:.2f} | "
                  f"{'PONIŻEJ MINIMUM' if b['below_minimum'] else 'OK'}")
        if "ppk_pfron_solidarity" in result:
            p = result["ppk_pfron_solidarity"]
            print(f"PPK/PFRON/FS: pracownik {p['ppk']['employee']*100:.1f}% | pracodawca {p['ppk']['employer_min']*100:.1f}-{p['ppk']['employer_max']*100:.1f}% | "
                  f"PFRON ({p['employees']} prac.): {'OBOWIĄZEK' if p['pfron']['obliged'] else 'brak obowiązku'} | FS {p['solidarity']['rate']*100:.2f}%")
        return 0

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano: {args.out}")
        return 0

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
