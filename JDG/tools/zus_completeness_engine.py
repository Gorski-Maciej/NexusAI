#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Micro-ZUS Rule Completeness Engine (INN01 — P08 Report)
═══════════════════════════════════════════════════════════════════════════════

Automatyczne porównanie reguł mikro z ustawami SUS/zdrowotna/zasilkowa.
Generuje macierz pokrycia: [ustawa][artykuł][ustęp] = rule_id | BRAK.

Użycie:
    python JDG/tools/zus_completeness_engine.py [--verbose] [--json] [--report]

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
Wersja: 1.0.0
"""

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MICRO_DIR = PROJECT_ROOT / "JDG" / "rules" / "micro"

# ── Act definitions — pełna struktura ustaw ──────────────────────────────────

SUS_ARTICLES = {
    "Art. 6": {"title": "Podmioty podlegające ubezpieczeniom", "subsections": {
        "ust. 1 pkt 1": "Umowa o pracę", "ust. 1 pkt 4": "JDG",
        "ust. 1 pkt 5": "Wspólnicy spółek", "ust. 1 pkt 6": "Zleceniobiorcy",
        "ust. 2": "Dobrowolne dla JDG"
    }},
    "Art. 6b": {"title": "Dobrowolne ubezpieczenie chorobowe", "subsections": {
        "ust. 1": "JDG może przystąpić", "ust. 2": "Termin zgłoszenia"
    }},
    "Art. 7": {"title": "Zgłoszenie do ubezpieczeń", "subsections": {
        "ust. 1": "ZUS ZUA", "ust. 2": "ZUS ZCNA"
    }},
    "Art. 8": {"title": "Podstawa wymiaru składek", "subsections": {
        "ust. 1": "Deklarowana kwota", "ust. 2": "Nie niższa niż 60%",
        "ust. 2a": "30% minimalnego (ulgowe)"
    }},
    "Art. 9": {"title": "Zbieg tytułów ubezpieczenia", "subsections": {
        "ust. 1": "Wybór jednego tytułu", "ust. 1a": "Etat + JDG",
        "ust. 2": "Kilka tytułów", "ust. 3": "Wyłączenia"
    }},
    "Art. 10": {"title": "Rozpoczęcie/ustanie obowiązku", "subsections": {
        "ust. 1": "Od dnia rozpoczęcia JDG", "ust. 2": "Do dnia zaprzestania"
    }},
    "Art. 11": {"title": "Obowiązek ubezpieczeń", "subsections": {
        "ust. 1": "Emerytalne i rentowe — obowiązkowe",
        "ust. 2": "Chorobowe — dobrowolne dla JDG"
    }},
    "Art. 12": {"title": "Okres wyczekiwania na zasiłek", "subsections": {
        "ust. 1": "90 dni dla JDG", "ust. 2": "30 dni dla pracowników"
    }},
    "Art. 13": {"title": "Ubezpieczenie wypadkowe", "subsections": {
        "ust. 1": "Obowiązkowe dla JDG", "ust. 2": "Stopy procentowe"
    }},
    "Art. 14": {"title": "Ustanie ubezpieczeń", "subsections": {
        "ust. 1": "Zamknięcie JDG", "ust. 2": "Brak chorobowej >30 dni"
    }},
    "Art. 16": {"title": "Zgłoszenie do ubezpieczeń (ZUA)", "subsections": {
        "ust. 1": "Termin 7 dni", "ust. 2": "Aktualizacja danych"
    }},
    "Art. 18": {"title": "Podstawy wymiaru składek", "subsections": {
        "ust. 1": "60% przeciętnego wynagrodzenia", "ust. 8": "Zasady ogólne"
    }},
    "Art. 18a": {"title": "Ulga na start (6 miesięcy)", "subsections": {
        "ust. 1": "6 miesięcy", "ust. 2": "Tylko społeczne",
        "ust. 3": "Zdrowotna zawsze płatna"
    }},
    "Art. 18c": {"title": "Preferencyjny ZUS + Mały ZUS+", "subsections": {
        "ust. 1": "24 miesiące na 30%", "ust. 8": "Mały ZUS+ 36 miesięcy",
        "ust. 9": "Limit 120 000 przychodu"
    }},
    "Art. 19": {"title": "Zasady ustalania podstawy", "subsections": {
        "ust. 1": "Deklarowana kwota", "ust. 2": "Minimum ustawowe"
    }},
    "Art. 22": {"title": "Stopy procentowe", "subsections": {
        "ust. 1": "Emerytalna 19.52%", "ust. 2": "Rentowa 8%",
        "ust. 3": "Chorobowa 2.45%", "ust. 4": "Wypadkowa 1.67%"
    }},
    "Art. 24": {"title": "Fundusz Pracy", "subsections": {
        "ust. 1": "2.45% dla JDG z pracownikami"
    }},
    "Art. 26": {"title": "Składki obniżone (ulgowe)", "subsections": {
        "ust. 1": "Progi dochodowe"
    }},
    "Art. 32": {"title": "Roczne rozliczenie składek", "subsections": {
        "ust. 1": "ZUS DRA roczna"
    }},
    "Art. 35": {"title": "Korekty deklaracji ZUS", "subsections": {
        "ust. 1": "Korekta ZUS DRA"
    }},
    "Art. 36": {"title": "Terminy płatności", "subsections": {
        "ust. 1": "10. dzień — społeczne", "ust. 2": "15. dzień — z pracownikami",
        "ust. 3": "20. dzień — bez pracowników"
    }},
    "Art. 40": {"title": "Prawa do świadczeń", "subsections": {
        "ust. 1": "Po opłaceniu składek"
    }},
    "Art. 46": {"title": "Egzekucja składek", "subsections": {
        "ust. 1": "ZUS może egzekwować"
    }},
    "Art. 47": {"title": "Obowiązek opłacania", "subsections": {
        "ust. 1": "Terminowe opłacanie", "ust. 2": "Kary za nieopłacanie"
    }},
}

ZDROWOTNA_ARTICLES = {
    "Art. 79": {"title": "Prawo do świadczeń opieki zdrowotnej", "subsections": {
        "ust. 1": "Osoby objęte ubezpieczeniem"
    }},
    "Art. 81": {"title": "Składka zdrowotna (4 warianty)", "subsections": {
        "ust. 2": "Skala PIT: 9% od dochodu",
        "ust. 2c": "Liniowy: 4.9% od dochodu",
        "ust. 2e": "Ryczałt: 3 progi kwotowe",
        "ust. 2a": "Karta: 9% od minimalnego"
    }},
    "Art. 81b": {"title": "Roczne rozliczenie składki zdrowotnej", "subsections": {
        "ust. 1": "Do 22 maja (ryczałt) / 30 kwietnia",
        "ust. 2": "Nadpłata/niedopłata"
    }},
    "Art. 81c": {"title": "Progi ryczałtowe", "subsections": {
        "ust. 1": "Tier I: ≤60k → 60% przeciętnego",
        "ust. 2": "Tier II: 60-300k → 100% przeciętnego",
        "ust. 3": "Tier III: >300k → 180% przeciętnego"
    }},
    "Art. 81d": {"title": "Minimalna podstawa wymiaru", "subsections": {
        "ust. 1": "75% przeciętnego wynagrodzenia"
    }},
    "Art. 82": {"title": "Obowiązek opłacania + terminy", "subsections": {
        "ust. 1": "Termin: 10/15/20 dzień", "ust. 2": "Konsekwencje nieopłacania"
    }},
}

ZASILKOWA_ARTICLES = {
    "Art. 19": {"title": "Zasiłek chorobowy", "subsections": {
        "ust. 1": "80% podstawy (70% szpital)",
        "ust. 2": "Okres wyczekiwania 90 dni",
        "ust. 3": "Max 182 dni (270 gruźlica/ciąża)"
    }},
    "Art. 29": {"title": "Zasiłek macierzyński", "subsections": {
        "ust. 1": "100% podstawy", "ust. 2": "20-37 tygodni",
        "ust. 3": "Wymaga 90 dni chorobowego"
    }},
    "Art. 32": {"title": "Zasiłek opiekuńczy", "subsections": {
        "ust. 1": "80% podstawy", "ust. 2": "60 dni (dziecko 14 lat)",
        "ust. 3": "14 dni (rodzina)"
    }},
    "Art. 33": {"title": "Warunki zasiłku opiekuńczego", "subsections": {
        "ust. 1": "Konieczność osobistej opieki"
    }},
}


class ZUSCompletenessEngine:
    """INN01: Micro-ZUS Rule Completeness Engine."""

    def __init__(self, verbose=False):
        self.verbose = verbose
        self.coverage = {}
        self.missing = []
        self.total_expected = 0
        self.total_covered = 0

    def analyze(self):
        """Run completeness analysis across all 3 acts."""
        self._analyze_act("SUS", SUS_ARTICLES, [
            MICRO_DIR / "sus" / "sus.rego",
            MICRO_DIR / "plan33_zus.rego",
            MICRO_DIR / "zus_micro_atomic_p09.rego",
        ])
        self._analyze_act("ZDROWOTNA", ZDROWOTNA_ARTICLES, [
            MICRO_DIR / "zdrowotna" / "zdrowotna.rego",
            MICRO_DIR / "plan33_health.rego",
        ])
        self._analyze_act("ZASILKOWA", ZASILKOWA_ARTICLES, [
            MICRO_DIR / "zasilkowa" / "zasilkowa.rego",
        ])
        return self._generate_report()

    def _analyze_act(self, act_name, articles, file_paths):
        """Analyze coverage for one act."""
        # Read all rules from all files
        all_rules = []
        for fp in file_paths:
            if fp.exists():
                content = fp.read_text(encoding="utf-8")
                rules = self._extract_rules(content, fp.name)
                all_rules.extend(rules)

        act_coverage = {}
        for art_name, art_def in articles.items():
            art_num = re.search(r'Art\.\s*(\d+[a-z]*)', art_name)
            art_key = art_num.group(1) if art_num else art_name

            art_rules = [r for r in all_rules if self._matches_article(r, art_key)]
            sub_coverage = {}

            if art_def.get("subsections"):
                for sub_name, sub_desc in art_def["subsections"].items():
                    sub_rules = [r for r in art_rules if sub_name.lower() in r.get("routing_reason", "").lower() or sub_desc.lower()[:20] in r.get("routing_reason", "").lower()]
                    sub_coverage[sub_name] = {
                        "description": sub_desc,
                        "rules": [r["rule_id"] for r in sub_rules],
                        "count": len(sub_rules),
                        "covered": len(sub_rules) > 0,
                    }
                    self.total_expected += 1
                    if len(sub_rules) > 0:
                        self.total_covered += 1

            coverage_pct = (len(sub_coverage) and sum(1 for s in sub_coverage.values() if s["covered"]) / len(sub_coverage) * 100) if sub_coverage else (100 if art_rules else 0)

            act_coverage[art_name] = {
                "title": art_def["title"],
                "total_rules": len(art_rules),
                "rule_ids": [r["rule_id"] for r in art_rules],
                "covered": len(art_rules) > 0,
                "coverage_pct": round(coverage_pct, 1),
                "subsections": sub_coverage,
            }

            if not art_rules:
                self.missing.append({
                    "act": act_name, "article": art_name,
                    "title": art_def["title"],
                    "message": f"Brak reguł dla {art_name} — {art_def['title']}"
                })

        self.coverage[act_name] = act_coverage

    def _extract_rules(self, content, filename):
        """Extract rules from Rego content."""
        rules = []
        rule_id_pattern = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
        routing_pattern = re.compile(r'"_routing_reason"\s*:\s*"([^"]*)"')

        # Split by decide/else blocks
        blocks = re.split(r'(?:^|\n)(?:else\s+)?(?:default\s+)?decide\s+:=', content)

        for block in blocks:
            rid_match = rule_id_pattern.search(block)
            rr_match = routing_pattern.search(block)
            if rid_match:
                rules.append({
                    "rule_id": rid_match.group(1),
                    "routing_reason": rr_match.group(1) if rr_match else "",
                    "file": filename,
                })

        return rules

    def _matches_article(self, rule, art_key):
        """Check if a rule matches an article."""
        rid = rule["rule_id"]
        # Match patterns like a6, a6b, a18, a18a, a18c
        pattern = rf'\.a{art_key}\.'
        if re.search(pattern, rid):
            return True
        # Also match plan33/34 formats
        pattern2 = rf'\.a{art_key}\b'
        if re.search(pattern2, rid):
            return True
        return False

    def _generate_report(self):
        """Generate completeness report."""
        global_cov = (self.total_covered / self.total_expected * 100) if self.total_expected > 0 else 0

        return {
            "tool": "Micro-ZUS Rule Completeness Engine (INN01)",
            "version": "1.0.0",
            "global_coverage_pct": round(global_cov, 1),
            "total_expected_subsections": self.total_expected,
            "total_covered_subsections": self.total_covered,
            "total_missing_articles": len(self.missing),
            "acts": self.coverage,
            "missing_articles": self.missing,
            "recommendation": "COMPLETE" if global_cov >= 80 else "NEEDS_EXPANSION" if global_cov >= 50 else "CRITICAL_GAPS"
        }


def print_report(report, verbose=False):
    """Print human-readable completeness report."""
    print()
    print("═" * 78)
    print("  NexusAI JDG — Micro-ZUS Rule Completeness Engine (INN01)")
    print(f"  Global Coverage: {report['global_coverage_pct']}% — {report['recommendation']}")
    print(f"  Covered: {report['total_covered_subsections']}/{report['total_expected_subsections']} subsections")
    print(f"  Missing articles: {report['total_missing_articles']}")
    print("═" * 78)

    for act_name, act_data in report["acts"].items():
        total_arts = len(act_data)
        covered_arts = sum(1 for a in act_data.values() if a["covered"])
        print(f"\n  📘 {act_name}: {covered_arts}/{total_arts} articles covered")
        for art_name, art_info in act_data.items():
            icon = "✅" if art_info["covered"] else "❌"
            rules_count = art_info["total_rules"]
            print(f"     {icon} {art_name} ({art_info['title']}): {rules_count} rules, {art_info['coverage_pct']}% subsection coverage")

    if report["missing_articles"]:
        print(f"\n  🔴 MISSING ARTICLES ({len(report['missing_articles'])}):")
        for m in report["missing_articles"]:
            print(f"     ❌ [{m['act']}] {m['article']} — {m['title']}")
    print()


def main():
    parser = argparse.ArgumentParser(description="NexusAI JDG — Micro-ZUS Completeness Engine (INN01)")
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    engine = ZUSCompletenessEngine(verbose=args.verbose)
    report = engine.analyze()

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print_report(report, verbose=args.verbose)

    if args.report:
        report_path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_INN01_ZUS_COMPLETENESS.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as f:
            f.write(f"RAPORT INN01 — Micro-ZUS Completeness Engine\n")
            f.write(f"Global Coverage: {report['global_coverage_pct']}%\n")
            f.write(f"Missing: {report['total_missing_articles']} articles\n\n")
            for act_name, act_data in report["acts"].items():
                f.write(f"\n{act_name}:\n")
                for art_name, art_info in act_data.items():
                    f.write(f"  {art_name}: {art_info['total_rules']} rules, {art_info['coverage_pct']}%\n")
        print(f"  📄 Report saved: {report_path}")


if __name__ == "__main__":
    main()
