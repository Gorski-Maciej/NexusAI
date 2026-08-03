#!/usr/bin/env python3
"""NexusAI JDG — P06 PIT Micro + Amortization Auditor (2026-08-02)

Audyt atomowej warstwy PIT (JDG/rules/micro/pit/pit.rego) oraz amortyzacji
(JDG/rules/micro/amortyzacja/*.rego, art. 22a-22n) i produkcja JSON, który
host wstrzykuje jako data.jdg.pit_micro_audit dla pakietu rego
jdg.p06_pit_micro_innovations (RAPORT ANALITYCZNY P06 v8.0 — Sekcje 1-8).

Funkcje CLI:
  --audit             pełny audyt (domyślne): rule_id, duplikaty, stuby,
                      pokrycie artykułów, spójność micro<->macro
  --amort             audyt amortyzacji (KŚT, jednorazowa 100k EUR,
                      samochody 150k/225k, stawki indywidualne 22n)
  --schedule --value N --group G --rate R   harmonogram amortyzacji liniowej
  --verify-rate --group G --declared R      weryfikator stawek KŚT
  --json / --table    format wyjścia (domyślnie JSON)
  --out FILE          zapis JSON do pliku

Zgodność: ustawa o PIT (Dz.U. 2025 poz. 789), rozporządzenie KŚT,
ADR-002 (progi), ADR-006 (_legal_basis).
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MICRO_PIT = ROOT / "rules" / "micro" / "pit" / "pit.rego"
AMORT_DIR = ROOT / "rules" / "micro" / "amortyzacja"

# Artykuły priorytetowe wg promptu P06 (Sekcja 1) — zgodne z listą w rego.
PRIORITY_ARTICLES_PIT = [
    "9", "9a", "10", "13", "14", "21", "22", "22a", "22b", "22c", "22d", "22e",
    "22f", "22g", "22h", "22i", "22j", "22k", "22l", "22m", "22n", "22o", "22p",
    "23", "24", "26", "26e", "26h", "27", "30c", "44", "45", "45a",
]

# Tabela KŚT (rozporządzenie) — grupy i standardowe stawki roczne.
KST_GROUPS = {
    "0": {"name": "Grunty", "rate": 0.0, "note": "NIE amortyzowane (art. 22c PIT)"},
    "1": {"name": "Budynki i lokale", "rate": 0.015, "note": "mieszkalne 1.5%; niemieszkalne 2.5%"},
    "2": {"name": "Obiekty inżynierii lądowej i wodnej", "rate": 0.045, "note": "budowle 4.5%"},
    "3": {"name": "Kotły i maszyny energetyczne", "rate": 0.07, "note": "7% (do 10%)"},
    "4": {"name": "Maszyny i urządzenia ogólne", "rate": 0.14, "note": "14% (do 18%)"},
    "5": {"name": "Maszyny i urządzenia specjalistyczne", "rate": 0.20, "note": "20% (do 25%)"},
    "6": {"name": "Urządzenia techniczne", "rate": 0.18, "note": "18%"},
    "7": {"name": "Środki transportu", "rate": 0.20, "note": "samochody 20% (art. 22k limity)"},
    "8": {"name": "Narzędzia, przyrządy, wyposażenie", "rate": 0.20, "note": "20%"},
}

AMORT_LIMITS = {
    "ONE_TIME_EUR_LIMIT": 100000,
    "SMALL_TAXPAYER_EUR": 2000000,
    "CAR_LIMIT_STANDARD": 150000,
    "CAR_LIMIT_ELECTRIC": 225000,
    "EUR_PLN_RATE": 4.3,
}

RULE_ID_RE = re.compile(r'"jdg\.micro\.pit\.([a-z0-9_]+)\.r(\d+)"')
INLINE_STUB_RE = re.compile(r"\{\s*true\s\}")


def _read_micro_pit() -> str:
    if not MICRO_PIT.exists():
        raise FileNotFoundError(f"Brak pliku: {MICRO_PIT}")
    return MICRO_PIT.read_text(encoding="utf-8")


def scan_rule_ids(text: str) -> dict:
    """Liczy rule_id (całość vs unikalne) i wykrywa duplikaty."""
    matches = RULE_ID_RE.findall(text)
    total = len(matches)
    counts = Counter(f"jdg.micro.pit.{a}.r{n}" for a, n in matches)
    duplicates = sorted(rid for rid, c in counts.items() if c > 1)
    return {"total_rules": total, "unique_rule_ids": len(counts), "duplicates": duplicates}


def detect_stubs(text: str) -> list:
    """Stuby: reguły z ciałem wyłącznie `true` (inline { true })."""
    stubs = []
    for m in INLINE_STUB_RE.finditer(text):
        line_no = text[: m.start()].count("\n") + 1
        stubs.append(f"line {line_no}: inline {{ true }}")
    return stubs


def article_coverage(text: str) -> dict:
    """Status pokrycia per artykuł priorytetowy wg liczby reguł atomowych.

    rule_id format 'jdg.micro.pit.a{N}[sufiks].r{M}' (np. a22a, a30c) —
    zdejmujemy wiodące 'a', aby klucze zgadzały się z PRIORITY_ARTICLES_PIT.
    """
    rule_counts = defaultdict(int)
    for a, _n in RULE_ID_RE.findall(text):
        key = a[1:] if re.match(r"a\d", a) else a
        rule_counts[key] += 1
    coverage = {}
    for art in PRIORITY_ARTICLES_PIT:
        cnt = rule_counts.get(art, 0)
        if cnt >= 5:
            coverage[art] = "COMPLETE"
        elif cnt >= 1:
            coverage[art] = "PARTIAL"
        else:
            coverage[art] = "MISSING"
    return coverage


def macro_micro_map(coverage: dict) -> dict:
    """Spójność priorytetów: micro (atomowe) < macro (500). Tylko artykuły z regułami."""
    m = {}
    for art, status in coverage.items():
        if status == "MISSING":
            continue
        m[f"art. {art}"] = {
            "micro_priority": 10,
            "macro_priority": 500,
            "micro_rule_ids": [f"jdg.micro.pit.a{art}.r*"],
        }
    return m


def amort_audit() -> dict:
    """Audyt plików amortyzacji art. 22a-22n (istnienie, liczba reguł, kluczowe markery)."""
    files = {
        "pit_a22a.rego": "art. 22a — środki trwałe (definicja, wyłączenia)",
        "pit_a22i.rego": "art. 22i — jednorazowa amortyzacja (100 000 EUR)",
        "pit_a22k.rego": "art. 22k — przyspieszona + samochody (150k/225k PLN)",
        "pit_a22n.rego": "art. 22n — stawki indywidualne (2× standard)",
    }
    result = {}
    for fname, desc in files.items():
        path = AMORT_DIR / fname
        if path.exists():
            text = path.read_text(encoding="utf-8")
            result[fname] = {
                "description": desc,
                "lines": len(text.splitlines()),
                "rule_defs": sum(
                    1 for line in text.splitlines() if re.match(r"^[a-z_][a-z0-9_]*\s*(:=|=)", line.strip())
                ),
                "present": True,
            }
        else:
            result[fname] = {"description": desc, "lines": 0, "rule_defs": 0, "present": False}
    return result


def amort_schedule(value: float, group: str, rate: float | None = None) -> dict:
    """Harmonogram liniowej amortyzacji (art. 22h): roczna, miesięczna, lata."""
    r = rate if rate is not None else KST_GROUPS.get(group, {}).get("rate", 0.14)
    annual = round(value * r, 2)
    monthly = round(annual / 12.0, 2)
    years = math.ceil(value / annual) if annual > 0 else 0
    return {
        "asset_value": round(value, 2),
        "kst_group": group,
        "rate": r,
        "annual_depreciation": annual,
        "monthly_depreciation": monthly,
        "years": years,
        "legal_basis": "Art. 22h PIT — metoda liniowa",
    }


def verify_kst_rate(group: str, declared: float) -> dict:
    """Weryfikator stawek KŚT: oczekiwana vs zadeklarowana."""
    expected = KST_GROUPS.get(group, {}).get("rate", 0.0)
    return {
        "kst_group": group,
        "expected_rate": expected,
        "declared_rate": declared,
        "correct": abs(expected - declared) <= 0.0001,
    }


def one_time_amort_pln_limit(eur_rate: float = AMORT_LIMITS["EUR_PLN_RATE"]) -> float:
    """Limit jednorazowej amortyzacji art. 22i w PLN (100 000 EUR × kurs)."""
    return round(AMORT_LIMITS["ONE_TIME_EUR_LIMIT"] * eur_rate, 2)


def run_audit() -> dict:
    """Pełny audyt P06 — wynik zgodny z data.jdg.pit_micro_audit używanym w rego."""
    text = _read_micro_pit()
    ids = scan_rule_ids(text)
    coverage = article_coverage(text)
    return {
        "total_rules": ids["total_rules"],
        "unique_rule_ids": ids["unique_rule_ids"],
        "duplicates": ids["duplicates"],
        "stubs": detect_stubs(text),
        "dead_rules": [],
        "coverage": coverage,
        "macro_micro_map": macro_micro_map(coverage),
        "amortization": amort_audit(),
        "amortization_limits": AMORT_LIMITS,
        "one_time_pln_limit": one_time_amort_pln_limit(),
    }


def render_table(audit: dict) -> str:
    lines = []
    lines.append("=== P06 PIT MICRO + AMORTYZACJA AUDIT (RAPORT v8.0) ===")
    lines.append(f"Reguły (refs): {audit['total_rules']} | Unikalne rule_id: {audit['unique_rule_ids']}")
    lines.append(f"Duplikaty: {len(audit['duplicates'])} | Stuby: {len(audit['stubs'])}")
    cov = audit["coverage"]
    complete = [a for a, s in cov.items() if s == "COMPLETE"]
    missing = [a for a, s in cov.items() if s == "MISSING"]
    lines.append(f"Pokrycie: COMPLETE {len(complete)} | MISSING {len(missing)} ({', '.join(missing)})")
    lines.append("Amortyzacja:")
    for fname, info in audit["amortization"].items():
        lines.append(f"  {fname}: {'OK' if info['present'] else 'BRAK'} ({info['rule_defs']} defs, {info['lines']} linii)")
    lines.append(f"Limit jednorazowej (art. 22i): {audit['one_time_pln_limit']} PLN")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NexusAI JDG — P06 PIT Micro + Amortization Auditor")
    p.add_argument("--audit", action="store_true", help="pełny audyt (domyślne)")
    p.add_argument("--amort", action="store_true", help="audyt plików amortyzacji")
    p.add_argument("--schedule", action="store_true", help="harmonogram amortyzacji")
    p.add_argument("--value", type=float, default=0, help="wartość środka (PLN)")
    p.add_argument("--group", default="4", help="grupa KŚT (0-8)")
    p.add_argument("--rate", type=float, default=None, help="stawka roczna (opcjonalna)")
    p.add_argument("--verify-rate", action="store_true", help="weryfikator stawki KŚT")
    p.add_argument("--declared", type=float, default=0, help="zadeklarowana stawka")
    p.add_argument("--table", action="store_true", help="format tabelaryczny")
    p.add_argument("--out", help="zapis JSON do pliku")
    args = p.parse_args(argv)

    result: dict = {}
    if args.verify_rate:
        result["kst_verification"] = verify_kst_rate(args.group, args.declared)
    elif args.schedule:
        result["amortization_schedule"] = amort_schedule(args.value, args.group, args.rate)
    else:
        audit = run_audit()
        result = audit
        if args.amort:
            result["amortization_detail"] = audit["amortization"]

    if args.table:
        if "kst_verification" in result:
            v = result["kst_verification"]
            print(f"=== WERYFIKACJA STAWKI KŚT (grupa {v['kst_group']}) ===")
            print(f"  Oczekiwana: {v['expected_rate']} | Zadeklarowana: {v['declared_rate']} | Poprawna: {v['correct']}")
        elif "amortization_schedule" in result:
            s = result["amortization_schedule"]
            print(f"=== HARMONOGRAM AMORTYZACJI (grupa KŚT {s['kst_group']}, stawka {s['rate']}) ===")
            print(f"  Wartość: {s['asset_value']} | Roczna: {s['annual_depreciation']} | Miesięczna: {s['monthly_depreciation']} | Lata: {s['years']}")
        else:
            print(render_table(result))
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2))

    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano do {args.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
