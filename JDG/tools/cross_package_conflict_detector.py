#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Cross-Package Conflict Detector (Innowacja #7 v7.0)
═══════════════════════════════════════════════════════════════════════════════

Automatyczne wykrywanie konfliktów między pakietami Rego:
1. Buduje graf zależności między pakietami (60+ pakietów)
2. Dla każdej pary pakietów sprawdza nakładające się warunki
3. Wykrywa sprzeczne decyzje (pakiet A: STAWKA_23%, pakiet B: STAWKA_8%)
4. Generuje alert z propozycją rozstrzygnięcia

Usage: python cross_package_conflict_detector.py [--json] [--verbose]

Autor: NexusAI — v7.0 Enterprise Audit Implementation
Data: 2026-07-25
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"


def parse_rego_file(filepath: Path) -> list[dict]:
    """Parsuje plik .rego, zwraca reguły z metadanymi."""
    content = filepath.read_text(encoding="utf-8")
    rules = []
    pattern = (
        r'"matched"\s*:\s*true.*?'
        r'"rule_id"\s*:\s*"(?P<rule_id>[^"]+)".*?'
        r'(?:"priority"\s*:\s*(?P<priority>\d+))?.*?'
        r'(?:"_legal_basis"\s*:\s*"(?P<legal_basis>[^"]*)")?.*?'
        r'(?:"_routing"\s*:\s*"(?P<routing>[^"]*)")?'
    )
    for match in re.finditer(pattern, content, re.DOTALL):
        rules.append({
            "rule_id": match.group("rule_id"),
            "priority": int(match.group("priority") or 0),
            "legal_basis": match.group("legal_basis") or "",
            "routing": match.group("routing") or "",
            "file": str(filepath.relative_to(RULES_DIR)),
            "package": match.group("rule_id").split(".")[1] if "." in match.group("rule_id") else "unknown",
        })
    return rules


class CrossPackageConflictDetector:
    """Detektor konfliktów między pakietami Rego."""

    ROUTING_CONFLICT_RULES = {
        ("BLOCK_AND_ALERT", "ALLOW"): "CRITICAL",
        ("BLOCK_AND_ALERT", "TRIAGE_QUEUE"): "HIGH",
        ("TRIAGE_QUEUE", "ALLOW"): "MEDIUM",
    }

    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.all_rules: list[dict] = []
        self.conflicts: list[dict] = []
        self.dependency_graph: dict[str, set[str]] = defaultdict(set)

    def scan(self) -> None:
        """Skanuje wszystkie pliki .rego i buduje bazę reguł."""
        for filepath in sorted(RULES_DIR.rglob("*.rego")):
            rules = parse_rego_file(filepath)
            self.all_rules.extend(rules)
        if self.verbose:
            print(f"📁 Zeskanowano {len(set(r['file'] for r in self.all_rules))} plików, "
                  f"{len(self.all_rules)} reguł")

    def build_dependency_graph(self) -> None:
        """Buduje graf zależności między pakietami."""
        packages = defaultdict(list)
        for rule in self.all_rules:
            pkg = rule["package"]
            packages[pkg].append(rule)

        # Wykryj zależności przez legal_basis cross-references
        for pkg, rules in packages.items():
            for rule in rules:
                for other_pkg, other_rules in packages.items():
                    if other_pkg == pkg:
                        continue
                    # Sprawdź czy cytują te same artykuły
                    pkg_basis = self._extract_articles(rule["legal_basis"])
                    for other_rule in other_rules:
                        other_basis = self._extract_articles(other_rule["legal_basis"])
                        if pkg_basis & other_basis:
                            self.dependency_graph[pkg].add(other_pkg)
                            self.dependency_graph[other_pkg].add(pkg)

        if self.verbose:
            print(f"🔗 Graf zależności: {len(self.dependency_graph)} pakietów, "
                  f"{sum(len(d) for d in self.dependency_graph.values())} krawędzi")

    def detect_conflicts(self) -> list[dict]:
        """Wykrywa konflikty między pakietami."""
        packages = defaultdict(list)
        for rule in self.all_rules:
            packages[rule["package"]].append(rule)

        # Porównaj pary pakietów, które mają wspólne zależności
        for pkg_a, pkg_b_list in self.dependency_graph.items():
            for pkg_b in pkg_b_list:
                if pkg_a >= pkg_b:
                    continue  # Unikaj duplikatów

                rules_a = packages.get(pkg_a, [])
                rules_b = packages.get(pkg_b, [])

                conflict = self._analyze_package_pair(pkg_a, rules_a, pkg_b, rules_b)
                if conflict:
                    self.conflicts.append(conflict)

        return sorted(self.conflicts, key=lambda c: c.get("severity_score", 0), reverse=True)

    def _analyze_package_pair(
        self, pkg_a: str, rules_a: list[dict], pkg_b: str, rules_b: list[dict]
    ) -> dict | None:
        """Analizuje parę pakietów pod kątem konfliktów."""
        routings_a = Counter(r["routing"] for r in rules_a if r["routing"])
        routings_b = Counter(r["routing"] for r in rules_b if r["routing"])

        dominant_a = max(routings_a, key=routings_a.get) if routings_a else ""
        dominant_b = max(routings_b, key=routings_b.get) if routings_b else ""

        conflict_key = tuple(sorted([dominant_a, dominant_b]))
        severity = self.ROUTING_CONFLICT_RULES.get(conflict_key)

        if severity:
            shared_articles = set()
            for r_a in rules_a:
                for r_b in rules_b:
                    articles_a = self._extract_articles(r_a["legal_basis"])
                    articles_b = self._extract_articles(r_b["legal_basis"])
                    shared = articles_a & articles_b
                    if shared:
                        shared_articles.update(shared)

            return {
                "packages": [pkg_a, pkg_b],
                "conflict_type": f"{dominant_a} vs {dominant_b}",
                "severity": severity,
                "severity_score": {"CRITICAL": 100, "HIGH": 70, "MEDIUM": 40, "LOW": 10}.get(severity, 0),
                "rules_a_count": len(rules_a),
                "rules_b_count": len(rules_b),
                "shared_articles": list(shared_articles)[:5],
                "dominant_routing_a": dominant_a,
                "dominant_routing_b": dominant_b,
                "recommendation": self._recommend_resolution(pkg_a, pkg_b, dominant_a, dominant_b),
            }
        return None

    def _extract_articles(self, legal_basis: str) -> set[str]:
        """Ekstrahuje numery artykułów z podstawy prawnej."""
        articles = set()
        for match in re.finditer(r'Art\.\s*(\d+[a-z]*)', legal_basis, re.IGNORECASE):
            articles.add(match.group(1))
        return articles

    def _recommend_resolution(self, pkg_a: str, pkg_b: str, routing_a: str, routing_b: str) -> str:
        """Generuje rekomendację rozwiązania konfliktu."""
        if "BLOCK" in routing_a and "ALLOW" in routing_b:
            return (
                f"OSTROŻNOŚĆ: {pkg_a} blokuje, a {pkg_b} zezwala. "
                "Zweryfikuj priorytety i dodaj jawny else-chain. "
                "Zalecana konfiguracja: BLOCK > TRIAGE > ALLOW."
            )
        elif "BLOCK" in routing_a and "TRIAGE" in routing_b:
            return (
                f"UWAGA: {pkg_a} blokuje, a {pkg_b} wymaga triage. "
                "Rozważ podniesienie priorytetu BLOCK lub dodanie cross-package dependency."
            )
        return "Zweryfikuj spójność decyzji między pakietami."

    def generate_report(self) -> dict:
        """Generuje pełny raport JSON."""
        return {
            "generated_at": str(Path(__file__).stat().st_mtime),
            "total_packages": len(self.dependency_graph),
            "total_rules": len(self.all_rules),
            "conflicts_found": len(self.conflicts),
            "conflicts": self.conflicts[:50],
            "dependency_graph": {
                pkg: list(deps) for pkg, deps in self.dependency_graph.items()
            },
        }


def main():
    verbose = "--verbose" in sys.argv
    json_output = "--json" in sys.argv

    print("🔍 NexusAI JDG — Cross-Package Conflict Detector (Innowacja #7 v7.0)")

    detector = CrossPackageConflictDetector(verbose=verbose)
    detector.scan()
    detector.build_dependency_graph()
    conflicts = detector.detect_conflicts()

    if json_output:
        print(json.dumps(detector.generate_report(), indent=2, ensure_ascii=False))
    else:
        print(f"   Pakiety: {len(detector.dependency_graph)}")
        print(f"   Reguły: {len(detector.all_rules)}")
        print(f"   Konflikty: {len(conflicts)}")
        print()

        if conflicts:
            for i, c in enumerate(conflicts[:10], 1):
                icon = {"CRITICAL": "🔴", "HIGH": "🟠", "MEDIUM": "🟡", "LOW": "🟢"}.get(c["severity"], "⚪")
                print(f"   {icon} #{i}: {c['packages'][0]} vs {c['packages'][1]}")
                print(f"      Typ: {c['conflict_type']} | Severity: {c['severity']}")
                print(f"      Rekomendacja: {c['recommendation']}")
                print()
        else:
            print("   ✅ Brak wykrytych konfliktów między pakietami.")

    sys.exit(1 if conflicts else 0)


if __name__ == "__main__":
    main()
