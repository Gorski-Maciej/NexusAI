#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P08 ZUS/SUS Micro Auditor (Enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzędzie audytowe dla warstwy mikro ZUS/SUS (raport analityczny P08 v8.0).
# Audytuje realne pliki rego: JDG/rules/micro/sus/*.rego (atomowe art. 6-47),
# JDG/rules/micro/zdrowotna/*.rego (art. 79-82) i JDG/rules/micro/zasilkowa/*.rego
# (art. 19-33) oraz plan33_zus.rego / plan33_health.rego. Generuje dane JSON
# do wstrzyknięcia jako data.jdg.zus_micro_audit (pokrycie artykułów, duplikaty,
# stuby, martwe reguły, prefiksy rule_id).
#
# Funkcje:
#   --audit           pełny audyt plików mikro (domyślne)
#   --health          kalkulator składki zdrowotnej mikro (progi 60K/300K)
#   --benefit         kalkulator zasiłków mikro (wyczekiwanie, stawki, limity)
#   --titles          atomowy silnik zbiegów tytułów (a6/a9)
#   --pipeline        migawka pipeline temporalnego (thresholdy 2022-2026)
#   --check-plan33    weryfikacja prefiksów rule_id plan33 vs katalogi mikro
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
    "scale_rate": 0.09,
    "linear_rate": 0.049,
    "linear_deduction_limit": 14100.0,
    "lump_tier_1_limit": 60000,
    "lump_tier_2_limit": 300000,
    "lump_tier_1_amount": 491.40,
    "lump_tier_2_amount": 819.00,
    "lump_tier_3_amount": 1474.20,
    "tax_card_rate": 0.09,
}

BENEFITS = {
    "sickness_rate_standard": 0.80,
    "sickness_rate_special": 1.00,
    "waiting_months": 3,
    "annual_limit": 85528.0,
    "maternity_days_20wks": 140,
    "payment_deadline_days": 30,
}

LIMITS_2026 = {
    "minimum_wage_gross": 4800.0,
    "social_base_standard": 5204.40,
    "preferential_base_rate": 0.30,
}

# Migawki temporalne 2022-2026 (minimalne, podstawa, ryczałt T2)
TEMPORAL = {
    2022: {"min_wage": 3010.0, "base": 3474.60, "lump_t2": 559.44},
    2023: {"min_wage": 3490.0, "base": 4161.00, "lump_t2": 641.94},
    2024: {"min_wage": 4242.0, "base": 4694.40, "lump_t2": 724.50},
    2025: {"min_wage": 4666.0, "base": 5054.40, "lump_t2": 797.16},
    2026: {"min_wage": 4800.0, "base": 5204.40, "lump_t2": 819.00},
}

# Priorytetowe artykuły: SUS, zdrowotna, zasilkowa (unikalne klucze z domeną)
PRIORITY_ARTICLES = [
    # SUS
    "sus_a6", "sus_a6b", "sus_a9", "sus_a11", "sus_a13", "sus_a14",
    "sus_a18", "sus_a18a", "sus_a18c", "sus_a19", "sus_a22", "sus_a24",
    "sus_a36", "sus_a40", "sus_a47",
    # Zdrowotna
    "h_a79", "h_a81", "h_a81b", "h_a81c", "h_a81d", "h_a82",
    # Zasilkowa
    "z_a19", "z_a29", "z_a32", "z_a33",
]

# Katalogi mikro i prefiksy rule_id (zweryfikowane: package w plikach rego)
MICRO_DIRS = {
    "sus": ("jdg.micro.sus", ["sus.rego", "sus_a6.rego", "sus_a6b.rego", "sus_a9.rego",
                              "sus_a11.rego", "sus_a13.rego", "sus_a14.rego", "sus_a18.rego",
                              "sus_a18a.rego", "sus_a18c.rego", "sus_a19.rego", "sus_a22.rego",
                              "sus_a24.rego", "sus_a36.rego", "sus_a40.rego", "sus_a47.rego"]),
    "zdrowotna": ("jdg.micro.zdrowotna", ["zdrowotna.rego", "zdrowotna_a79.rego", "zdrowotna_a81.rego",
                                          "zdrowotna_a81b.rego", "zdrowotna_a81c.rego", "zdrowotna_a81d.rego",
                                          "zdrowotna_a82.rego"]),
    "zasilkowa": ("jdg.micro.zasilkowa", ["zasilkowa.rego", "zasilkowa_a19.rego", "zasilkowa_a29.rego",
                                           "zasilkowa_a32.rego", "zasilkowa_a33.rego"]),
}

# Mapa domena → prefiks klucza artykułu (unikalne klucze: sus_a19 vs z_a19)
DOMAIN_PREFIX = {"sus": "sus_", "zdrowotna": "h_", "zasilkowa": "z_"}


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Sekcja 2: zdrowotna mikro ─────────────────────────────────────────────────
def zus_health_scale(income: float) -> float:
    return round2(income * HEALTH["scale_rate"])


def zus_health_linear(income: float) -> float:
    return round2(income * HEALTH["linear_rate"])


def zus_health_lump(revenue: float) -> float:
    if revenue <= HEALTH["lump_tier_1_limit"]:
        return HEALTH["lump_tier_1_amount"]
    if revenue <= HEALTH["lump_tier_2_limit"]:
        return HEALTH["lump_tier_2_amount"]
    return HEALTH["lump_tier_3_amount"]


def zus_health_tax_card() -> float:
    return round2(LIMITS_2026["minimum_wage_gross"] * HEALTH["tax_card_rate"])


def health_micro_calculator(income: float, revenue: float) -> dict:
    comparison = {
        "skala": zus_health_scale(income),
        "liniowy": zus_health_linear(income),
        "ryczałt": zus_health_lump(revenue),
        "karta": zus_health_tax_card(),
    }
    cheapest = min(comparison, key=comparison.get)
    return {
        "comparison": comparison,
        "cheapest_form": cheapest,
        "cheapest_amount": comparison[cheapest],
        "minimum_monthly": round2(LIMITS_2026["minimum_wage_gross"] * HEALTH["scale_rate"]),
        "tiers": [
            {"revenue_limit": 60000, "amount": 491.40, "share": 0.60},
            {"revenue_limit": 300000, "amount": 819.00, "share": 1.00},
            {"revenue_limit": None, "amount": 1474.20, "share": 1.80},
        ],
        "lump_tier_auto_recalc": {
            "projected_revenue": revenue,
            "current": zus_health_lump(revenue),
            "tier_switch_needed": HEALTH["lump_tier_1_limit"] < revenue <= HEALTH["lump_tier_2_limit"],
            "annual_impact": round2(HEALTH["lump_tier_2_amount"] * 12 - HEALTH["lump_tier_1_amount"] * 12),
        },
        "annual_reconciliation": {
            "annual_income": round2(income * 12),
            "due_scale": round2(income * 12 * HEALTH["scale_rate"]),
        },
    }


# ── Sekcja 3: zasiłki mikro ───────────────────────────────────────────────────
def zus_sickness_benefit(base: float, rate: float, days: int) -> float:
    daily = round2(base / 30)
    return round2(daily * rate * days)


def benefit_micro_calculator(base: float, insured_months: int) -> dict:
    return {
        "waiting": {
            "months_required": BENEFITS["waiting_months"],
            "insured_months": insured_months,
            "eligible": insured_months >= BENEFITS["waiting_months"],
            "months_to_go": max(BENEFITS["waiting_months"] - insured_months, 0),
        },
        "daily": {
            "sickness_80pct": zus_sickness_benefit(base, BENEFITS["sickness_rate_standard"], 1),
            "sickness_100pct": zus_sickness_benefit(base, BENEFITS["sickness_rate_special"], 1),
            "maternity_100pct": round2(base / 30),
            "rehab_90pct": zus_sickness_benefit(base, 0.90, 1),
        },
        "limits": {
            "maternity_days_20wks": BENEFITS["maternity_days_20wks"],
            "sickness_annual_limit": BENEFITS["annual_limit"],
            "payment_deadline_days": BENEFITS["payment_deadline_days"],
        },
    }


# ── Sekcja 5: atomowy silnik zbiegów (a6/a9) ──────────────────────────────────
def atomic_titles_engine(concurrent_title: str) -> dict:
    zbiegi = {"etat_jdg", "emeryt_jdg", "student_jdg", "urlop_wychowawczy_jdg"}
    return {
        "concurrent_title": concurrent_title,
        "social": concurrent_title not in zbiegi,
        "health": True,
        "legal_atom": {"a6": "podleganie", "a9": "zbiegi tytułów"},
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def audit_rego_files() -> dict:
    rule_ids = []
    files_audited = []
    texts = []

    # Katalogi atomowe: sus/, zdrowotna/, zasilkowa/
    for sub, (prefix, expected) in MICRO_DIRS.items():
        d = BASE_DIR / "rules" / "micro" / sub
        if d.exists():
            for f in sorted(d.glob("*.rego")):
                files_audited.append(f"{sub}/{f.name}")
                t = f.read_text(encoding="utf-8")
                texts.append(t)
                rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    # Plany mikro: plan33_zus.rego (prefiks jdg.zus.* — niekonsekwencja!), plan33_health.rego
    plan33_zus = BASE_DIR / "rules" / "micro" / "plan33_zus.rego"
    plan33_health = BASE_DIR / "rules" / "micro" / "plan33_health.rego"
    plan33_zus_prefix = "jdg.zus"
    if plan33_zus.exists():
        files_audited.append("micro/plan33_zus.rego")
        t = plan33_zus.read_text(encoding="utf-8")
        texts.append(t)
        plan33_rids = re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)
        rule_ids += plan33_rids
        # Wyprowadź realny prefiks TYLKO z rule_id plan33 (pierwszy nie-no_match)
        real = [r for r in plan33_rids if not r.endswith(".no_match")]
        if real:
            plan33_zus_prefix = _derive_prefix(real[0])
    if plan33_health.exists():
        files_audited.append("micro/plan33_health.rego")
        t = plan33_health.read_text(encoding="utf-8")
        texts.append(t)
        rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    total = len(rule_ids)
    unique = sorted(set(rule_ids))
    no_match_defaults = sum(1 for rid in rule_ids if rid.endswith(".no_match"))
    real_rule_ids = [rid for rid in rule_ids if not rid.endswith(".no_match")]
    duplicates = sorted({rid for rid in set(real_rule_ids) if real_rule_ids.count(rid) > 1})

    # Stuby: "true" jako jedyne ciało (heurystyka: "{ true }" w linii po rule_id)
    combined = "\n".join(texts)
    stubs = [rid for rid in unique if _looks_like_stub(combined, rid)]
    dead_rules = _detect_dead_rules(unique)

    # Pokrycie artykułów: prefiks jdg.micro.<domain>.a{N} → unikalny klucz domena+artykuł
    covered = set()
    for rid in unique:
        m = re.match(r"jdg\.micro\.(sus|zdrowotna|zasilkowa)\.(a\d+[a-z]?)", rid)
        if m:
            covered.add(DOMAIN_PREFIX[m.group(1)] + m.group(2))

    articles = {}
    for art in PRIORITY_ARTICLES:
        domain_key, art_no = art.split("_", 1)
        domain = {"sus": "sus", "h": "zdrowotna", "z": "zasilkowa"}[domain_key]
        refs = sum(1 for rid in unique if re.match(rf"jdg\.micro\.{domain}\.{re.escape(art_no)}\.", rid))
        status = "COMPLETE" if refs > 0 else "MISSING"
        articles[art] = {"status": status, "rules": refs}

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
        "stubs": stubs,
        "stub_count": len(stubs),
        "dead_rules": dead_rules,
        "articles": articles,
        "plan33_rule_id_prefix": plan33_zus_prefix,
        "coverage": {
            "total": total_arts,
            "complete": total_arts - missing,
            "missing": missing,
            "gap_pct": round2(missing / total_arts * 100) if total_arts else 0.0,
        },
    }


def _derive_prefix(rule_id: str) -> str:
    """Wyprowadź prefiks pakietu z rule_id (np. jdg.zus.a11.r2 → jdg.zus)."""
    m = re.match(r"(.+)\.a\d+[a-z]?(?:\.r\d+)?$", rule_id)
    return m.group(1) if m else rule_id


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
        description="NexusAI JDG — P08 ZUS/SUS Micro Auditor (Enterprise)")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików mikro (domyślne)")
    parser.add_argument("--health", action="store_true", help="kalkulator zdrowotnej mikro")
    parser.add_argument("--benefit", action="store_true", help="kalkulator zasiłków mikro")
    parser.add_argument("--titles", action="store_true", help="atomowy silnik zbiegów (a6/a9)")
    parser.add_argument("--pipeline", action="store_true", help="migawka pipeline temporalnego")
    parser.add_argument("--check-plan33", action="store_true", help="weryfikacja prefiksów plan33")
    parser.add_argument("--income", type=float, default=10000.0, help="dochód miesięczny (PLN)")
    parser.add_argument("--revenue", type=float, default=120000.0, help="przychód roczny (PLN)")
    parser.add_argument("--base", type=float, default=5204.40, help="podstawa wymiaru (PLN)")
    parser.add_argument("--insured-months", type=int, default=6, help="miesiące ubezpieczenia")
    parser.add_argument("--title", type=str, default="etat_jdg", help="zbieg tytułów")
    parser.add_argument("--table", action="store_true", help="format tabelaryczny")
    parser.add_argument("--out", type=str, default="", help="zapis JSON do pliku")
    args = parser.parse_args()

    result = {"tool": "zus_micro_auditor", "module": "P08 ZUS/SUS Micro"}

    if args.audit or not (args.health or args.benefit or args.titles or
                          args.pipeline or args.check_plan33):
        result["audit"] = audit_rego_files()
    if args.health:
        result["health_micro"] = health_micro_calculator(args.income, args.revenue)
    if args.benefit:
        result["benefits_micro"] = benefit_micro_calculator(args.base, args.insured_months)
    if args.titles:
        result["titles"] = atomic_titles_engine(args.title)
    if args.pipeline:
        result["pipeline"] = {
            "steps": ["ingest", "generate", "verify", "emit"],
            "snapshots": {str(y): d for y, d in sorted(TEMPORAL.items())},
        }
    if args.check_plan33:
        audit = audit_rego_files()
        result["plan33_check"] = {
            "plan33_prefix": audit["plan33_rule_id_prefix"],
            "sus_dir_prefix": "jdg.micro.sus",
            "consistent": audit["plan33_rule_id_prefix"] == "jdg.micro.zus",
            "note": "plan33_zus.rego używa jdg.zus.a{N} (bez .micro.) — niekonsekwencja",
        }

    if args.table:
        if "health_micro" in result:
            print("ZDROWOTNA MIKRO (miesięcznie, PLN):")
            for form, amount in result["health_micro"]["comparison"].items():
                print(f"  {form:<10} {amount:>10.2f}")
            print(f"  {'NAJNIŻSZA':<10} {result['health_micro']['cheapest_amount']:>10.2f}  ({result['health_micro']['cheapest_form']})")
        if "benefits_micro" in result:
            print("ZASIŁKI MIKRO (dziennie, PLN):")
            for k, v in result["benefits_micro"]["daily"].items():
                print(f"  {k:<18} {v:>10.2f}")
            w = result["benefits_micro"]["waiting"]
            if w["eligible"]:
                print("  wyczekiwanie: OK")
            else:
                print(f"  wyczekiwanie: brak {w['months_to_go']} mies.")
        if "plan33_check" in result:
            c = result["plan33_check"]
            print(f"PREFIKSY rule_id: plan33={c['plan33_prefix']} vs sus={c['sus_dir_prefix']} — "
                  f"{'ZGODNE' if c['consistent'] else 'NIEKONSEKWENCJA'}")
        return 0

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano: {args.out}")
        return 0

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
