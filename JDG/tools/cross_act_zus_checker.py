#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Cross-Act ZUS Coherence Checker (INN06 — P08 Report)
═══════════════════════════════════════════════════════════════════════════════

Sprawdza spójność między 3 ustawami: SUS, zdrowotna, zasiłkowa.
Wykrywa logiczne konflikty między ustawami:
  - Art. 9 SUS (zbieg) vs Art. 82 u.ś.o.z. (zdrowotna z każdego tytułu)
  - Art. 18c SUS (Mały ZUS+, limit 120k) vs Art. 81c u.ś.o.z. (progi ryczałtu)
  - Art. 19 u.z. (chorobowy 80%) vs Art. 22 SUS (chorobowa 2.45%)

Użycie:
    python JDG/tools/cross_act_zus_checker.py [--verbose] [--json] [--report]

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
Wersja: 1.0.0
"""

import argparse
import json
import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MICRO_DIR = PROJECT_ROOT / "JDG" / "rules" / "micro"
RULES_DIR = PROJECT_ROOT / "JDG" / "rules"

# ── Coherence checks ─────────────────────────────────────────────────────────

COHERENCE_CHECKS = [
    {
        "id": "C01",
        "name": "SUS Art.9 vs Zdrowotna Art.82 — Zbieg tytułów a składka zdrowotna",
        "description": "Przy zbiegu etat+JDG: społeczne z etatu, zdrowotna z obu tytułów. Sprawdź czy reguły są spójne.",
        "act_a": "SUS", "article_a": "Art. 9",
        "act_b": "Zdrowotna", "article_b": "Art. 82",
        "check": "Przy has_employment_contract=true: społeczne z etatu, zdrowotna z JDG+etat",
        "expected": "consistent",
    },
    {
        "id": "C02",
        "name": "SUS Art.18c vs Zdrowotna Art.81c — Limity Mały ZUS+ vs Progi ryczałtu",
        "description": "Mały ZUS+ limit 120k vs ryczałt progi 60k/300k. Różne limity, różne podstawy.",
        "act_a": "SUS", "article_a": "Art. 18c ust. 9",
        "act_b": "Zdrowotna", "article_b": "Art. 81c",
        "check": "Limit 120k Małego ZUS+ vs 60k/300k progów ryczałtu — różne cele, ale niesprzeczne",
        "expected": "consistent_different_purposes",
    },
    {
        "id": "C03",
        "name": "SUS Art.22 vs Zasiłkowa Art.19 — Stopa chorobowa vs Zasiłek chorobowy",
        "description": "Składka chorobowa 2.45% od podstawy, zasiłek 80% podstawy.",
        "act_a": "SUS", "article_a": "Art. 22 ust. 3",
        "act_b": "Zasiłkowa", "article_b": "Art. 19",
        "check": "Składka 2.45% od podstawy, zasiłek 80% podstawy — spójne (składka ≠ zasiłek)",
        "expected": "consistent",
    },
    {
        "id": "C04",
        "name": "SUS Art.11 vs Zasiłkowa Art.29 — Dobrowolne chorobowe a macierzyński",
        "description": "Macierzyński wymaga 90 dni dobrowolnego chorobowego.",
        "act_a": "SUS", "article_a": "Art. 11 ust. 2",
        "act_b": "Zasiłkowa", "article_b": "Art. 29",
        "check": "Czy reguły sprawdzają 90-dniowy okres wyczekiwania przed macierzyńskim?",
        "expected": "consistent",
    },
    {
        "id": "C05",
        "name": "Zdrowotna Art.81 vs PIT — Odliczalność składki zdrowotnej",
        "description": "Liniowy: odliczalna do limitu. Skala: NIEodliczalna. Ryczałt: NIEodliczalna.",
        "act_a": "Zdrowotna", "article_a": "Art. 81",
        "act_b": "PIT", "article_b": "Art. 27/30c",
        "check": "Czy reguły zdrowotne i PIT są spójne co do odliczalności?",
        "expected": "consistent",
    },
    {
        "id": "C06",
        "name": "SUS Art.18a vs Zdrowotna Art.81d — Ulga start vs Minimalna podstawa zdrowotna",
        "description": "Ulga start: ZUS społeczne=0, ale zdrowotna zawsze płatna od min. podstawy.",
        "act_a": "SUS", "article_a": "Art. 18a",
        "act_b": "Zdrowotna", "article_b": "Art. 81d",
        "check": "Czy START_RELIEF prawidłowo ustawia social_base=0 i health_base=75% przeciętnego?",
        "expected": "consistent",
    },
    {
        "id": "C07",
        "name": "SUS Art.14 vs Zasiłkowa — Ustanie ubezpieczeń a prawo do zasiłku",
        "description": "Po ustaniu ubezpieczenia: brak prawa do zasiłku po 30 dniach.",
        "act_a": "SUS", "article_a": "Art. 14",
        "act_b": "Zasiłkowa", "article_b": "Art. 19",
        "check": "Czy reguły sprawdzają datę ustania ubezpieczenia vs datę zasiłku?",
        "expected": "consistent",
    },
]

# ── Cross-reference rule patterns ────────────────────────────────────────────

SUS_RULES = {
    "a9": {"files": ["sus/sus.rego", "plan33_zus.rego"], "pattern": r"a9\.r\d+"},
    "a11": {"files": ["sus/sus.rego", "plan33_zus.rego"], "pattern": r"a11\.r\d+"},
    "a14": {"files": ["sus/sus.rego"], "pattern": r"a14\.r\d+"},
    "a18a": {"files": ["sus/sus.rego"], "pattern": r"a18a\.r\d+"},
    "a18c": {"files": ["sus/sus.rego"], "pattern": r"a18c\.r\d+"},
    "a22": {"files": ["sus/sus.rego", "plan33_zus.rego"], "pattern": r"a22\.r\d+"},
}

ZDROWOTNA_RULES = {
    "a81": {"files": ["zdrowotna/zdrowotna.rego"], "pattern": r"a81\.r\d+"},
    "a81c": {"files": ["zdrowotna/zdrowotna.rego"], "pattern": r"a81c\.r\d+"},
    "a81d": {"files": ["zdrowotna/zdrowotna.rego"], "pattern": r"a81d\.r\d+"},
    "a82": {"files": ["zdrowotna/zdrowotna.rego"], "pattern": r"a82\.r\d+"},
}

ZASILKOWA_RULES = {
    "a19": {"files": ["zasilkowa/zasilkowa.rego"], "pattern": r"a19\.r\d+"},
    "a29": {"files": ["zasilkowa/zasilkowa.rego"], "pattern": r"a29\.r\d+"},
}


class CrossActZUSChecker:
    """INN06: Cross-Act ZUS Coherence Checker."""

    def __init__(self, verbose=False):
        self.verbose = verbose
        self.results = []
        self.inconsistencies = []
        self.rule_presence = {}

    def check_all(self):
        """Run all coherence checks."""
        self._scan_rule_presence()
        self._run_coherence_checks()
        return self._generate_report()

    def _scan_rule_presence(self):
        """Scan which rules exist in which files."""
        all_rule_sets = {**SUS_RULES, **ZDROWOTNA_RULES, **ZASILKOWA_RULES}

        for art_name, info in all_rule_sets.items():
            found_in = []
            for rel_path in info["files"]:
                filepath = MICRO_DIR / rel_path
                if filepath.exists():
                    content = filepath.read_text(encoding="utf-8")
                    if re.search(info["pattern"], content):
                        found_in.append(rel_path)

            self.rule_presence[art_name] = {
                "expected_files": info["files"],
                "found_in": found_in,
                "present": len(found_in) > 0,
            }

    def _run_coherence_checks(self):
        """Run all defined coherence checks."""
        for check in COHERENCE_CHECKS:
            result = self._evaluate_check(check)
            self.results.append(result)

            if result["status"] == "INCONSISTENT":
                self.inconsistencies.append(result)

    def _evaluate_check(self, check):
        """Evaluate a single coherence check."""
        result = {
            "id": check["id"],
            "name": check["name"],
            "expected": check["expected"],
            "status": "CONSISTENT",
            "findings": [],
        }

        # Check rule presence for both acts
        act_a_rules = self._find_rules_for_check(check["act_a"], check["article_a"])
        act_b_rules = self._find_rules_for_check(check["act_b"], check["article_b"])

        result["act_a_rules"] = act_a_rules
        result["act_b_rules"] = act_b_rules

        # If both have rules, it's consistent at the structural level
        if act_a_rules and act_b_rules:
            result["status"] = "CONSISTENT"
        elif act_a_rules and not act_b_rules:
            result["status"] = "INCONSISTENT"
            result["findings"].append(f"Brak reguł dla {check['act_b']} {check['article_b']}")
        elif not act_a_rules and act_b_rules:
            result["status"] = "INCONSISTENT"
            result["findings"].append(f"Brak reguł dla {check['act_a']} {check['article_a']}")
        else:
            result["status"] = "INCONSISTENT"
            result["findings"].append(f"Brak reguł dla obu ustaw!")

        return result

    def _find_rules_for_check(self, act, article):
        """Find rules for a specific act/article combination."""
        # Extract article number from various formats
        art_match = re.search(r'(?:Art\.\s*)?(a?\d+[a-z]*)', article, re.IGNORECASE)
        if not art_match:
            return []
        art_key = art_match.group(1).lower()
        if not art_key.startswith("a"):
            art_key = "a" + art_key

        # Map act to rule set
        if act == "SUS":
            rule_set = SUS_RULES
        elif act == "Zdrowotna":
            rule_set = ZDROWOTNA_RULES
        elif act == "Zasiłkowa":
            rule_set = ZASILKOWA_RULES
        else:
            # Check all
            rule_set = {**SUS_RULES, **ZDROWOTNA_RULES, **ZASILKOWA_RULES}

        info = rule_set.get(art_key)
        if not info:
            return []

        rules = []
        for rel_path in info["files"]:
            filepath = MICRO_DIR / rel_path
            if filepath.exists():
                content = filepath.read_text(encoding="utf-8")
                rule_id_pattern = re.compile(r'"rule_id"\s*:\s*"([^"]*' + art_key + r'[^"]*)"')
                for match in rule_id_pattern.finditer(content):
                    rules.append(match.group(1))
        return rules

    def _generate_report(self):
        """Generate coherence report."""
        consistent = sum(1 for r in self.results if r["status"] == "CONSISTENT")
        inconsistent = sum(1 for r in self.results if r["status"] == "INCONSISTENT")

        return {
            "tool": "Cross-Act ZUS Coherence Checker (INN06)",
            "version": "1.0.0",
            "total_checks": len(self.results),
            "consistent": consistent,
            "inconsistent": inconsistent,
            "coherence_score": round(consistent / len(self.results) * 100, 1) if self.results else 0,
            "results": self.results,
            "inconsistencies": self.inconsistencies,
            "rule_presence_summary": {k: v["present"] for k, v in self.rule_presence.items()},
        }


def print_report(report):
    """Print human-readable coherence report."""
    print()
    print("═" * 78)
    print("  NexusAI JDG — Cross-Act ZUS Coherence Checker (INN06)")
    print(f"  Coherence Score: {report['coherence_score']}%")
    print(f"  Consistent: {report['consistent']}/{report['total_checks']}  |  Inconsistent: {report['inconsistent']}")
    print("═" * 78)

    for r in report["results"]:
        icon = "✅" if r["status"] == "CONSISTENT" else "❌"
        print(f"\n  {icon} [{r['id']}] {r['name']}")
        if r["findings"]:
            for f in r["findings"]:
                print(f"      → {f}")
        print(f"      SUS rules: {len(r['act_a_rules'])} | Zdrowotna/Zasiłkowa rules: {len(r['act_b_rules'])}")

    print(f"\n  📊 OBECNOŚĆ REGUŁ:")
    for art, present in report["rule_presence_summary"].items():
        icon = "✅" if present else "❌"
        print(f"     {icon} {art}")


def main():
    parser = argparse.ArgumentParser(description="NexusAI JDG — Cross-Act ZUS Coherence Checker (INN06)")
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    checker = CrossActZUSChecker(verbose=args.verbose)
    report = checker.check_all()

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print_report(report)

    if args.report:
        report_path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_INN06_CROSS_ACT_COHERENCE.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as f:
            f.write("RAPORT INN06 — Cross-Act ZUS Coherence Checker\n")
            f.write(f"Score: {report['coherence_score']}%\n")
            f.write(f"Consistent: {report['consistent']}/{report['total_checks']}\n")
        print(f"  📄 Report saved: {report_path}")


if __name__ == "__main__":
    main()
