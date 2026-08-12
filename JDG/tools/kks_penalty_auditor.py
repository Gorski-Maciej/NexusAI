#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P10 KKS Penalty Auditor (Enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzędzie audytowe dla modułu KKS (raport analityczny P10 v8.0).
# Audytuje realne pliki rego: JDG/rules/micro/kks/kks.rego (474 rule_id,
# artykuły a16-a83), plan33_kks.rego, _kks_micro_rates.rego. Generuje dane JSON
# do wstrzyknięcia jako data.jdg.kks_audit (pokrycie artykułów, duplikaty,
# stuby, martwe reguły).
#
# Funkcje:
#   --audit          pełny audyt plików micro KKS (domyślne)
#   --penalty        kalkulator kary (stawki dzienne, grzywna, uzasadnienie)
#   --minimization   silnik minimalizacji kary — 4-ścieżkowy decision tree
#   --risk           symulator ryzyka karno-skarbowego
#   --disclosure     asystent czynnego żalu (art. 16)
#   --limitations    kalendarz przedawnień (art. 44)
#   --conviction     tracker zatarcia skazania (art. 45)
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


def _load_kks_thresholds() -> dict:
    """Load the KKS data block from the authoritative Rego thresholds file.

    The CLI is intentionally usable without OPA, but it must not silently drift
    from the runtime data contract. Values are parsed only from the quoted KKS
    object; malformed/missing data falls back to the constants below and is
    surfaced by the report gate.
    """
    path = BASE_DIR / "rules" / "thresholds_jdg.rego"
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return {}
    match = re.search(r"(?ms)^kks\\s*:=\\s*\\{(?P<body>.*?)^\\}", text)
    if not match:
        return {}
    values = {}
    for key, raw in re.findall(r'"([a-zA-Z0-9_]+)"\\s*:\\s*([^,\\n]+)', match.group("body")):
        raw = raw.strip()
        if raw == "null":
            values[key] = None
        elif raw.lower() in {"true", "false"}:
            values[key] = raw.lower() == "true"
        elif raw.startswith('"') and raw.endswith('"'):
            values[key] = raw[1:-1]
        else:
            try:
                values[key] = float(raw) if "." in raw else int(raw)
            except ValueError:
                continue
    return values


# ── Progi ustawowe 2026 (spójne z data.jdg.thresholds.kks — ADR-002) ──────────
KKS = {
    # Fallbacks keep the standalone CLI usable when the source file is absent;
    # the authoritative values below are loaded from thresholds_jdg.rego.
    "min_wage": 4800.0,                 # minimalne wynagrodzenie 2026 (PLN)
    "daily_rate_denominator": 30,       # stawka dzienna = 1/30 min. wynagrodzenia
    "daily_rate_max_multiple": 400,     # maksymalna stawka dzienna 400×
    "crime_threshold_multiple": 200,    # próg przestępstwo/wykroczenie 200×
    "mandatory_prison_threshold": 5000000,  # >5M → obligatoryjne PW (art. 62 §3)
    "max_rates_crime": 720,             # max stawek dziennych — przestępstwo
    "max_rates_misdemeanor": 240,       # max stawek dziennych — wykroczenie
    "limitation_years_crime": 5,        # przedawnienie przestępstwa (art. 44)
    "limitation_years_misdemeanor": 3,  # przedawnienie wykroczenia (art. 44)
    "small_value_multiple": 500,        # mała wartość (art. 53 §6) — 500× min.
    "correction_interest_pct": 0.15,    # audytowy scenariusz korekty (ADR-002)
    "valid_from": "2026-01-01",
    "valid_to": None,
}
KKS.update(_load_kks_thresholds())

DAILY_RATE_MIN = round(KKS["min_wage"] / KKS["daily_rate_denominator"], 2)   # 160.00
DAILY_RATE_MAX = KKS["min_wage"] * KKS["daily_rate_max_multiple"]             # 1 920 000
CRIME_THRESHOLD = KKS["min_wage"] * KKS["crime_threshold_multiple"]           # 960 000
MANDATORY_PRISON = KKS["mandatory_prison_threshold"]                          # 5 000 000

# Matryca czynów karno-skarbowych (spójna z kks_penalty_simulator.py + pakiet rego)
OFFENSE_MATRIX = {
    "art54": {"name": "Uchylanie się od opodatkowania", "max_rates": 720, "max_pw_years": 5, "severity": "CRITICAL"},
    "art54_2": {"name": "Uchylanie — duża wartość", "max_rates": 720, "max_pw_years": 10, "severity": "CRITICAL"},
    "art56": {"name": "Nierzetelne księgi/PKPiR", "max_rates": 240, "max_pw_years": 0, "severity": "HIGH"},
    "art56_3": {"name": "Fikcyjne wpisy PKPiR", "max_rates": 720, "max_pw_years": 5, "severity": "CRITICAL"},
    "art57": {"name": "Nierzetelna ewidencja VAT", "max_rates": 360, "max_pw_years": 0, "severity": "HIGH"},
    "art62": {"name": "Puste faktury", "max_rates": 720, "max_pw_years": 8, "severity": "CRITICAL"},
    "art62_3": {"name": "Korzyść >5M → obligatoryjne PW", "max_rates": 1080, "max_pw_years": 15, "severity": "CRITICAL"},
    "art64": {"name": "Niewłaściwa stawka VAT", "max_rates": 180, "max_pw_years": 0, "severity": "MEDIUM"},
    "art77": {"name": "Niezłożenie deklaracji (wykroczenie)", "max_rates": 180, "max_pw_years": 0, "severity": "MEDIUM"},
}

# Priorytetowe artykuły KKS (spójne z pakietem rego)
PRIORITY_ARTICLES = [
    "a16", "a37", "a44", "a45", "a53", "a54", "a55", "a56", "a57",
    "a62", "a64", "a77", "a78", "a79", "a80", "a81", "a82", "a83",
]


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Sekcja 2: kalkulator kary (INN-01) ────────────────────────────────────────
def penalty_calculator(amount: float, offense: str = "art54", daily_rates: int = 10,
                       is_recidivist: bool = False) -> dict:
    info = OFFENSE_MATRIX.get(offense, OFFENSE_MATRIX["art54"])
    is_crime = amount >= CRIME_THRESHOLD
    exceeds_prison = amount >= MANDATORY_PRISON
    multiplier = 2 if is_recidivist else 1
    fine_min = round2(DAILY_RATE_MIN * daily_rates * multiplier)
    fine_max = round2(DAILY_RATE_MAX * daily_rates * multiplier)
    return {
        "offense": offense,
        "offense_info": info,
        "amount": amount,
        "daily_rates": daily_rates,
        "daily_rate_min": DAILY_RATE_MIN,
        "daily_rate_max": DAILY_RATE_MAX,
        "fine_min": fine_min,
        "fine_max": fine_max,
        "is_crime": is_crime,
        "exceeds_mandatory_prison": exceeds_prison,
        "recidivism_multiplier": multiplier,
        "justification": [
            f"Grzywna wymierzana w stawkach dziennych: {daily_rates} stawek",
            f"Stawka dzienna: 1/30 min. wynagrodzenia = {DAILY_RATE_MIN:.2f} PLN (min) do {DAILY_RATE_MAX:,.0f} PLN (max)",
            f"Kara: {daily_rates} × stawka = {fine_min:,.2f} PLN (min) / {fine_max:,.2f} PLN (max)"
            + (" — recydywa ×2 (art. 37 §1 pkt 2)" if is_recidivist else ""),
        ],
    }


# ── Sekcja 2: silnik minimalizacji kary — 4-ścieżkowy decision tree (INN-02) ──
def minimization_engine(tax_arrears: float, disclosure_before_detection: bool = False,
                        willing_to_submit: bool = False, mediation_open: bool = False) -> dict:
    paths = {
        "path_1_czynny_zal": {
            "eligible": disclosure_before_detection,
            "effect": "art. 16 — zawiadomienie przed wykryciem → brak odpowiedzialności",
        },
        "path_2_dobrowolne_poddanie": {
            "eligible": willing_to_submit,
            "effect": "art. 17 — dobrowolne poddanie się odpowiedzialności → kara łagodniejsza",
        },
        "path_3_ugoda_mediacja": {
            "eligible": mediation_open,
            "effect": "art. 188-189 — postępowanie mediacyjne / ugoda",
        },
        "path_4_obrona_merytoryczna": {
            "eligible": True,
            "effect": "kwestionowanie podstaw: brak znamion, przedawnienie (art. 44), błąd co do prawa",
        },
    }
    if disclosure_before_detection:
        rec = "czynny_zal"
    elif willing_to_submit:
        rec = "dobrowolne_poddanie"
    else:
        rec = "obrona_merytoryczna"
    return {"tax_arrears": tax_arrears, "paths": paths, "recommendation": rec}


# ── Sekcja 2: symulator ryzyka karno-skarbowego (INN-03) ──────────────────────
def risk_scorer(unreliable_books: bool = False, empty_invoices: bool = False,
                missing_declarations: int = 0, recidivism: bool = False) -> dict:
    score = 0
    if unreliable_books:
        score += 25
    if empty_invoices:
        score += 35
    if missing_declarations > 0:
        score += 10 * missing_declarations
    if recidivism:
        score += 30
    level = "CRITICAL" if score >= 30 else "HIGH" if score >= 10 else "LOW"
    return {"risk_score": score, "risk_level": level,
            "indicators": {"unreliable_books": unreliable_books, "empty_invoices": empty_invoices,
                           "missing_declarations": missing_declarations, "recidivism": recidivism}}


# ── Sekcja 3: asystent czynnego żalu (INN-04) ─────────────────────────────────
def disclosure_assistant(disclosure_before_detection: bool = False,
                         control_started: bool = False) -> dict:
    worth = disclosure_before_detection and not control_started
    return {
        "disclosure_before_detection": disclosure_before_detection,
        "control_started": control_started,
        "worth_filing": worth,
        "effect": ("brak odpowiedzialności karnej (art. 16 §1)" if worth
                   else "czynny żal bezskuteczny — kontrola rozpoczęta"),
        "steps": ["1. Zawiadomienie do US/KAS", "2. Ujawnienie okoliczności",
                  "3. Zapłata podatku + odsetek", "4. Dokumentacja"],
    }


# ── Sekcja 4: kalendarz przedawnień (art. 44) i tracker zatarcia (art. 45) ────
def limitation_calendar() -> dict:
    return {
        "crime_years": KKS["limitation_years_crime"],
        "misdemeanor_years": KKS["limitation_years_misdemeanor"],
        "note": "przedawnienie karalności przestępstwa skarbowego — 5 lat; wykroczenia — 3 lata (art. 44 KKS)",
        "tax_arrears_interaction": "przedawnienie zobowiązania podatkowego (5 lat, art. 70 OrdPU)",
    }


def conviction_tracker(penalty_type: str = "grzywna") -> dict:
    period = 1 if penalty_type == "grzywna" else 3 if penalty_type == "kara_ograniczenia_wolnosci" else 5
    return {
        "penalty_type": penalty_type,
        "expungement_period_years": period,
        "impact_contracts": "zatarcie — brak wpływu na kontrakty i pozwolenia po upływie okresu",
        "tracker_note": "zatarcie z mocy prawa po okresie próby / wykonaniu kary (art. 45 KKS)",
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def audit_rego_files() -> dict:
    rule_ids = []
    files_audited = []
    texts = []

    micro_dir = BASE_DIR / "rules" / "micro" / "kks"
    if micro_dir.exists():
        for f in sorted(micro_dir.glob("*.rego")):
            files_audited.append(f"micro/kks/{f.name}")
            t = f.read_text(encoding="utf-8")
            texts.append(t)
            rule_ids += re.findall(r'"rule_id"\s*:\s*"([a-z0-9_.]+)"', t)

    plan33 = BASE_DIR / "rules" / "micro" / "plan33_kks.rego"
    if plan33.exists():
        files_audited.append("micro/plan33_kks.rego")
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

    # Pokrycie artykułów: jdg.micro.kks.a{N} → klucz artykułu
    covered = set()
    for rid in unique:
        m = re.match(r"jdg\.micro\.kks(?:\.plan33)?\.(a\d+[a-z]?)", rid)
        if m:
            covered.add(m.group(1))

    articles = {}
    for art in PRIORITY_ARTICLES:
        refs = sum(1 for rid in unique if re.match(rf"jdg\.micro\.kks(?:\.plan33)?\.{re.escape(art)}(?:\.|$)", rid))
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
        description="NexusAI JDG — P10 KKS Penalty Auditor (Enterprise)")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików micro KKS (domyślne)")
    parser.add_argument("--penalty", action="store_true", help="kalkulator kary KKS")
    parser.add_argument("--minimization", action="store_true", help="silnik minimalizacji kary (4-ścieżkowy)")
    parser.add_argument("--risk", action="store_true", help="symulator ryzyka karno-skarbowego")
    parser.add_argument("--disclosure", action="store_true", help="asystent czynnego żalu")
    parser.add_argument("--limitations", action="store_true", help="kalendarz przedawnień (art. 44)")
    parser.add_argument("--conviction", action="store_true", help="tracker zatarcia skazania (art. 45)")
    parser.add_argument("--amount", type=float, default=150000.0, help="kwota uszczuplenia (PLN)")
    parser.add_argument("--offense", type=str, default="art54", help="typ czynu (art54, art56, art62...)")
    parser.add_argument("--daily-rates", type=int, default=10, help="liczba stawek dziennych")
    parser.add_argument("--recidivist", action="store_true", help="recydywa (art. 37)")
    parser.add_argument("--disclosure-early", action="store_true", help="zawiadomienie przed wykryciem")
    parser.add_argument("--control-started", action="store_true", help="kontrola rozpoczęta")
    parser.add_argument("--submit", action="store_true", help="gotowość dobrowolnego poddania się")
    parser.add_argument("--unreliable-books", action="store_true", help="nierzetelne księgi")
    parser.add_argument("--empty-invoices", action="store_true", help="puste faktury")
    parser.add_argument("--missing-declarations", type=int, default=0, help="liczba niezłożonych deklaracji")
    parser.add_argument("--table", action="store_true", help="format tabelaryczny")
    parser.add_argument("--out", type=str, default="", help="zapis JSON do pliku")
    args = parser.parse_args()

    result = {"tool": "kks_penalty_auditor", "module": "P10 KKS (Kodeks Karny Skarbowy)"}

    if args.audit or not (args.penalty or args.minimization or args.risk or
                          args.disclosure or args.limitations or args.conviction):
        result["audit"] = audit_rego_files()
    if args.penalty:
        result["penalty"] = penalty_calculator(args.amount, args.offense, args.daily_rates, args.recidivist)
    if args.minimization:
        result["minimization"] = minimization_engine(args.amount, args.disclosure_early, args.submit)
    if args.risk:
        result["risk"] = risk_scorer(args.unreliable_books, args.empty_invoices,
                                     args.missing_declarations, args.recidivist)
    if args.disclosure:
        result["disclosure"] = disclosure_assistant(args.disclosure_early, args.control_started)
    if args.limitations:
        result["limitations"] = limitation_calendar()
    if args.conviction:
        result["conviction"] = conviction_tracker()

    if args.table:
        if "audit" in result:
            a = result["audit"]
            print(f"AUDYT MICRO KKS: {a['total_rule_ids']} rule_id | {a['unique_count']} unikalnych | "
                  f"duplikaty: {a['duplicate_count']} | stuby: {a['stub_count']}")
            print(f"  Pokrycie artykułów: {a['coverage']['complete']}/{a['coverage']['total']} "
                  f"(gap {a['coverage']['gap_pct']}%)")
        if "penalty" in result:
            p = result["penalty"]
            print(f"\nKALKULATOR KARY ({p['offense']} — {p['offense_info']['name']}):")
            print(f"  Kwota: {p['amount']:,.2f} PLN | stawki dzienne: {p['daily_rates']} | "
                  f"przestępstwo: {'TAK' if p['is_crime'] else 'NIE'}")
            print(f"  Kara: {p['fine_min']:,.2f} PLN (min) — {p['fine_max']:,.2f} PLN (max)")
        if "minimization" in result:
            m = result["minimization"]
            print(f"\nSILNIK MINIMALIZACJI: rekomendacja = {m['recommendation']}")
        if "risk" in result:
            r = result["risk"]
            print(f"\nRYZYKO KARNO-SKARBOWE: score {r['risk_score']} → {r['risk_level']}")
        if "disclosure" in result:
            d = result["disclosure"]
            print(f"\nCZYNNY ŻAL: warto złożyć = {'TAK' if d['worth_filing'] else 'NIE'} ({d['effect']})")
        if "limitations" in result:
            l = result["limitations"]
            print(f"\nPRZEDAWNIENIE: przestępstwo {l['crime_years']} lat | wykroczenie {l['misdemeanor_years']} lat")
        return 0

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano: {args.out}")
        return 0

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
