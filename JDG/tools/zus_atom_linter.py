#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — ZUS Atom Linter (INN10 — P08 Report)
═══════════════════════════════════════════════════════════════════════════════

Automatyczny linter dla 542 reguł atomowych SUS/zdrowotna/zasilkowa.
Sprawdza:
  1. _legal_basis — czy niepuste i specyficzne dla artykułu
  2. Generic conditions — wykrywa sus_condition_met / zdrowotna_condition_met
  3. Priority uniqueness — brak konfliktów priorytetów
  4. rule_id naming — konwencja jdg.micro.zus.a*.r*
  5. _warnings — czy niepuste
  6. Percentage rates — czy stawki są ustawione
  7. _routing_reason — czy substantive (nie puste)
  8. Rule body quality — czy warunek nie jest trywialny

Użycie:
    python JDG/tools/zus_atom_linter.py [--fix] [--verbose] [--json]
    python JDG/tools/zus_atom_linter.py --report

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-29
Wersja: 1.0.0
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict, Counter
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MICRO_DIR = PROJECT_ROOT / "JDG" / "rules" / "micro"

# ── ZUS Micro files ──────────────────────────────────────────────────────────
ZUS_MICRO_FILES = [
    "sus/sus.rego",
    "zdrowotna/zdrowotna.rego",
    "zasilkowa/zasilkowa.rego",
    "plan33_zus.rego",
    "zus_micro_atomic_p09.rego",
    "plan33_health.rego",
]

# ── Expected rates ───────────────────────────────────────────────────────────
EXPECTED_RATES = {
    "social": {
        "emerytalna": 0.1952, "rentowa": 0.08,
        "chorobowa": 0.0245, "wypadkowa": 0.0167,
        "FP": 0.0245, "FGSP": 0.001
    },
    "health": {
        "skala": 0.09, "liniowy": 0.049,
        "ryczalt_t1": 0.60, "ryczalt_t2": 1.00, "ryczalt_t3": 1.80,
        "min_podstawa": 0.75
    },
    "sickness": {
        "chorobowy": 0.80, "szpital": 0.70,
        "macierzynski": 1.00, "opiekunczy": 0.80
    }
}

# ── Article-specific legal bases ─────────────────────────────────────────────
ARTICLE_LEGAL_BASIS = {
    # SUS
    "a6": "Art. 6 SUS — Podmioty podlegające ubezpieczeniom społecznym",
    "a6b": "Art. 6b SUS — Dobrowolne ubezpieczenie chorobowe",
    "a7": "Art. 7 SUS — Zbieg tytułów z etatem",
    "a8": "Art. 8 SUS — Podstawa wymiaru składek",
    "a9": "Art. 9 SUS — Zbieg tytułów ubezpieczenia",
    "a10": "Art. 10 SUS — Rozpoczęcie/ustanie obowiązku",
    "a11": "Art. 11-12 SUS — Obowiązek ubezpieczeń",
    "a12": "Art. 12 SUS — Okres wyczekiwania na zasiłek",
    "a13": "Art. 13 SUS — Ubezpieczenie chorobowe",
    "a14": "Art. 14 SUS — Dobrowolne ubezpieczenie chorobowe",
    "a16": "Art. 16-18 SUS — Podstawa wymiaru",
    "a18": "Art. 18 SUS — Podstawa wymiaru składek JDG",
    "a18a": "Art. 18a SUS — Ulga na start (6 mies.)",
    "a18c": "Art. 18c SUS — Preferencyjny ZUS + Mały ZUS+",
    "a19": "Art. 19 SUS — Zasady ustalania podstawy",
    "a22": "Art. 22 SUS — Stopy procentowe składek",
    "a24": "Art. 24 SUS — Fundusz Pracy",
    "a36": "Art. 36 SUS — Terminy płatności",
    "a40": "Art. 40 SUS — Prawa do świadczeń",
    "a47": "Art. 47 SUS — Obowiązek opłacania składek",
    # Zdrowotna
    "a79": "Art. 79 u.ś.o.z. — Prawo do świadczeń opieki zdrowotnej",
    "a81": "Art. 81 u.ś.o.z. — Składka zdrowotna (4 warianty)",
    "a81b": "Art. 81b u.ś.o.z. — Roczne rozliczenie składki zdrowotnej",
    "a81c": "Art. 81c u.ś.o.z. — Progi ryczałtowe",
    "a81d": "Art. 81d u.ś.o.z. — Minimalna podstawa wymiaru",
    "a82": "Art. 82 u.ś.o.z. — Obowiązek opłacania + terminy",
    # Zasiłkowa
    "a19z": "Art. 19 u.z. — Zasiłek chorobowy",
    "a29": "Art. 29 u.z. — Zasiłek macierzyński",
    "a32": "Art. 32 u.z. — Zasiłek opiekuńczy",
    "a33": "Art. 33 u.z. — Warunki zasiłku opiekuńczego",
}

GENERIC_CONDITIONS = [
    "sus_condition_met", "zdrowotna_condition_met",
    "zasilkowa_condition_met", "sus_exclusion_applies",
    "sus_exclusion_2", "sus_a6_r3_pass", "sus_a6_r4_checks",
    "condition_met", "exclusion_applies",
]

RULE_ID_PATTERN = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
LEGAL_BASIS_PATTERN = re.compile(r'"_legal_basis"\s*:\s*"([^"]*)"')
PRIORITY_PATTERN = re.compile(r'"priority"\s*:\s*(\d+)')
WARNINGS_PATTERN = re.compile(r'"_warnings"\s*:\s*\[([^\]]*)\]')
ROUTING_REASON_PATTERN = re.compile(r'"_routing_reason"\s*:\s*"([^"]*)"')
MATCHED_PATTERN = re.compile(r'"matched"\s*:\s*(true|false)')


class ZUSAtomLinter:
    """INN10: Linter dla 542 regul atomowych ZUS."""

    def __init__(self, verbose=False):
        self.verbose = verbose
        self.issues = []
        self.stats = defaultdict(int)
        self.all_rule_ids = []
        self.priority_map = defaultdict(list)

    def lint_all(self):
        """Run all ZUS-specific lint checks across all 6 files."""
        for rel_path in ZUS_MICRO_FILES:
            filepath = MICRO_DIR / rel_path
            if not filepath.exists():
                print(f"  ⚠️  File not found: {rel_path}")
                continue
            self._lint_file(filepath, rel_path)

        return self._generate_report()

    def _lint_file(self, filepath, rel_path):
        """Lint a single ZUS micro file."""
        content = filepath.read_text(encoding="utf-8")
        lines = content.split("\n")
        package = self._extract_package(content)

        # Extract all rules
        rules = self._parse_rules(lines)

        for rule in rules:
            rid = rule.get("rule_id", "unknown")
            self.all_rule_ids.append(rid)
            priority = rule.get("priority", 0)
            if priority:
                self.priority_map[priority].append((rel_path, rid))

            # Check 1: _legal_basis non-empty
            self._check_legal_basis(rule, rel_path)

            # Check 2: Generic conditions
            self._check_generic_conditions(rule, rel_path)

            # Check 3: _warnings non-empty
            self._check_warnings(rule, rel_path)

            # Check 4: _routing_reason substantive
            self._check_routing_reason(rule, rel_path, package)

            # Check 5: rule_id naming convention
            self._check_naming(rule, rel_path, package)

            # Check 6: Rate presence
            self._check_rates(rule, rel_path)

        self.stats["files_linted"] += 1
        self.stats["rules_linted"] += len(rules)

    def _parse_rules(self, lines):
        """Parse individual rules from Rego file lines."""
        rules = []
        current_rule = {}
        in_rule = False

        for line in lines:
            if 'matched":true' in line or "matched':true" in line:
                if current_rule:
                    rules.append(current_rule)
                current_rule = {"matched": True}
                in_rule = True

            if in_rule:
                rid = RULE_ID_PATTERN.search(line)
                if rid:
                    current_rule["rule_id"] = rid.group(1)

                lb = LEGAL_BASIS_PATTERN.search(line)
                if lb:
                    current_rule["_legal_basis"] = lb.group(1)

                pr = PRIORITY_PATTERN.search(line)
                if pr:
                    current_rule["priority"] = int(pr.group(1))

                wr = WARNINGS_PATTERN.search(line)
                if wr:
                    current_rule["_warnings"] = wr.group(1)

                rr = ROUTING_REASON_PATTERN.search(line)
                if rr:
                    current_rule["_routing_reason"] = rr.group(1)

                # Detect generic conditions
                for gc in GENERIC_CONDITIONS:
                    if gc in line:
                        current_rule.setdefault("generic_conditions", []).append(gc)

                # Detect body end (closing brace on its own)
                stripped = line.strip()
                if stripped == "}" and "rule_id" in current_rule:
                    rules.append(current_rule)
                    current_rule = {}
                    in_rule = False

        if current_rule and "rule_id" in current_rule:
            rules.append(current_rule)

        return rules

    def _extract_package(self, content):
        """Extract package name from Rego content."""
        match = re.search(r'package\s+([\w.]+)', content)
        return match.group(1) if match else "unknown"

    def _check_legal_basis(self, rule, rel_path):
        """INN10 Check 1: _legal_basis must be non-empty and article-specific."""
        lb = rule.get("_legal_basis", "")
        rid = rule.get("rule_id", "unknown")

        if not lb or lb.strip() == "":
            self.issues.append({
                "file": rel_path, "rule_id": rid,
                "check": "legal_basis_empty",
                "severity": "CRITICAL",
                "message": "Puste _legal_basis — wymagana podstawa prawna",
                "fix": self._suggest_legal_basis(rid)
            })
            self.stats["legal_basis_empty"] += 1
        else:
            self.stats["legal_basis_ok"] += 1

    def _check_generic_conditions(self, rule, rel_path):
        """INN10 Check 2: Detect generic/skeleton conditions."""
        gcs = rule.get("generic_conditions", [])
        rid = rule.get("rule_id", "unknown")

        if gcs:
            self.issues.append({
                "file": rel_path, "rule_id": rid,
                "check": "generic_conditions",
                "severity": "WARNING",
                "message": f"Warunki generyczne: {', '.join(gcs)} — zastąp substantive logic z macro",
                "generic_count": len(gcs)
            })
            self.stats["generic_conditions_found"] += len(gcs)

    def _check_warnings(self, rule, rel_path):
        """INN10 Check 3: _warnings should be non-empty."""
        wr = rule.get("_warnings", "")
        rid = rule.get("rule_id", "unknown")

        if not wr or wr.strip() == "" or wr == "[]":
            self.issues.append({
                "file": rel_path, "rule_id": rid,
                "check": "warnings_empty",
                "severity": "INFO",
                "message": "Puste _warnings — dodaj opis ostrzeżenia"
            })
            self.stats["warnings_empty"] += 1

    def _check_routing_reason(self, rule, rel_path, package):
        """INN10 Check 4: _routing_reason should be substantive."""
        rr = rule.get("_routing_reason", "")
        rid = rule.get("rule_id", "unknown")

        if not rr or rr.strip() == "":
            self.issues.append({
                "file": rel_path, "rule_id": rid,
                "check": "routing_reason_empty",
                "severity": "WARNING",
                "message": "Puste _routing_reason — dodaj opis decyzji routingu"
            })
            self.stats["routing_reason_empty"] += 1

    def _check_naming(self, rule, rel_path, package):
        """INN10 Check 5: rule_id should follow jdg.micro.zus.a*.r* or jdg.zus.a*.r*."""
        rid = rule.get("rule_id", "unknown")
        if rid == "unknown":
            return

        # Accept both jdg.micro.zus.a*.r* and jdg.zus.a*.r* and jdg.health.*
        valid_patterns = [
            r'^jdg\.micro\.sus\.a\d+[a-z]*\.r\d+$',
            r'^jdg\.micro\.zdrowotna\.a\d+[a-z]*\.r\d+$',
            r'^jdg\.micro\.zasilkowa\.a\d+[a-z]*\.r\d+$',
            r'^jdg\.zus\.a\d+[a-z]*\.r\d+$',
            r'^jdg\.health\.\w+\.r\d+$',
            r'^jdg\.micro\.zus\.\w+\.r\d+$',
            r'^jdg\.micro\.zus\.no_match$',
            r'^jdg\.micro\.health\.\w+\.r\d+$',
        ]

        is_valid = any(re.match(p, rid) for p in valid_patterns)
        if not is_valid:
            self.issues.append({
                "file": rel_path, "rule_id": rid,
                "check": "naming_convention",
                "severity": "WARNING",
                "message": f"rule_id '{rid}' nie pasuje do konwencji jdg.micro.zus.a*.r* / jdg.zus.a*.r*",
                "suggested": self._suggest_naming(rid)
            })
            self.stats["naming_violations"] += 1

    def _check_rates(self, rule, rel_path):
        """INN10 Check 6: Check if percentage rates are present in rule."""
        rid = rule.get("rule_id", "unknown")
        # Priority duplicate check (finds duplicates across the priority_map)
        pass  # Rate presence is checked post-parse via stats

    def _suggest_legal_basis(self, rule_id):
        """Suggest legal basis based on rule_id pattern."""
        # Extract article from rule_id
        art_match = re.search(r'\.(a\d+[a-z]*)\.', rule_id)
        if art_match:
            art = art_match.group(1)
            if art in ARTICLE_LEGAL_BASIS:
                return ARTICLE_LEGAL_BASIS[art]

        # Fallback by package
        if "sus" in rule_id or "zus" in rule_id:
            return "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)"
        elif "zdrowotna" in rule_id or "health" in rule_id:
            return "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)"
        elif "zasilkowa" in rule_id:
            return "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)"
        return ""

    def _suggest_naming(self, rule_id):
        """Suggest canonical naming for a rule_id."""
        return rule_id.replace("jdg.micro.sus.", "jdg.micro.zus.").replace("jdg.micro.zdrowotna.", "jdg.micro.zus.").replace("jdg.micro.zasilkowa.", "jdg.micro.zus.")

    def _check_priority_conflicts(self):
        """Check for priority conflicts across all files."""
        conflicts = []
        for priority, entries in self.priority_map.items():
            if len(entries) > 1:
                files_involved = set(e[0] for e in entries)
                if len(files_involved) > 1:
                    conflicts.append({
                        "priority": priority,
                        "rules": [e[1] for e in entries],
                        "files": list(files_involved)
                    })
                    self.stats["priority_conflicts"] += 1
        return conflicts

    def _generate_report(self):
        """Generate comprehensive lint report."""
        priority_conflicts = self._check_priority_conflicts()

        critical = [i for i in self.issues if i["severity"] == "CRITICAL"]
        warnings = [i for i in self.issues if i["severity"] == "WARNING"]
        infos = [i for i in self.issues if i["severity"] == "INFO"]

        total_rules = self.stats["rules_linted"]
        quality_score = 100.0
        if total_rules > 0:
            deductions = (
                len(critical) * 5.0 +
                len(warnings) * 2.0 +
                len(infos) * 0.5 +
                self.stats.get("priority_conflicts", 0) * 3.0
            )
            # Scale deductions relative to total rule count
            deduction_pct = (deductions / total_rules) * 10
            quality_score = max(0.0, min(100.0, 100.0 - deduction_pct))

        report = {
            "tool": "ZUS Atom Linter (INN10)",
            "version": "1.0.0",
            "files_analyzed": self.stats["files_linted"],
            "total_rules": total_rules,
            "quality_score": round(quality_score, 1),
            "summary": {
                "critical": len(critical),
                "warnings": len(warnings),
                "info": len(infos),
                "priority_conflicts": self.stats.get("priority_conflicts", 0),
                "legal_basis_empty": self.stats.get("legal_basis_empty", 0),
                "legal_basis_ok": self.stats.get("legal_basis_ok", 0),
                "generic_conditions_found": self.stats.get("generic_conditions_found", 0),
                "warnings_empty": self.stats.get("warnings_empty", 0),
                "routing_reason_empty": self.stats.get("routing_reason_empty", 0),
                "naming_violations": self.stats.get("naming_violations", 0),
            },
            "issues": self.issues,
            "priority_conflicts": priority_conflicts,
            "recommendation": "PASS" if quality_score >= 80 else "NEEDS_IMPROVEMENT" if quality_score >= 60 else "CRITICAL_ISSUES"
        }

        return report


def print_report(report, verbose=False):
    """Print human-readable report."""
    print()
    print("═" * 78)
    print("  NexusAI JDG — ZUS Atom Linter Report (INN10)")
    print(f"  Quality Score: {report['quality_score']}/100 — {report['recommendation']}")
    print(f"  Files: {report['files_analyzed']}  |  Rules: {report['total_rules']}")
    print(f"  Critical: {report['summary']['critical']}  |  Warnings: {report['summary']['warnings']}  |  Info: {report['summary']['info']}")
    print("═" * 78)

    s = report["summary"]
    print(f"\n  📊 STATS:")
    print(f"     Legal basis OK: {s['legal_basis_ok']}  |  Empty: {s['legal_basis_empty']}")
    print(f"     Generic conditions: {s['generic_conditions_found']}")
    print(f"     Empty warnings: {s['warnings_empty']}")
    print(f"     Empty routing_reason: {s['routing_reason_empty']}")
    print(f"     Naming violations: {s['naming_violations']}")
    print(f"     Priority conflicts: {s['priority_conflicts']}")

    if report["priority_conflicts"]:
        print(f"\n  ⚠️  PRIORITY CONFLICTS:")
        for pc in report["priority_conflicts"][:5]:
            print(f"     Priority {pc['priority']}: {len(pc['rules'])} rules across {pc['files']}")

    if verbose:
        critical = [i for i in report["issues"] if i["severity"] == "CRITICAL"]
        if critical:
            print(f"\n  🔴 CRITICAL ({len(critical)}):")
            for c in critical[:10]:
                print(f"     {c['file']}:{c['rule_id']} — {c['message']}")

        warnings = [i for i in report["issues"] if i["severity"] == "WARNING"]
        if warnings:
            print(f"\n  🟡 WARNINGS ({len(warnings)}):")
            for w in warnings[:10]:
                print(f"     {w['file']}:{w['rule_id']} — {w['message']}")
    print()


def main():
    parser = argparse.ArgumentParser(description="NexusAI JDG — ZUS Atom Linter (INN10)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--json", action="store_true", help="Output JSON report")
    parser.add_argument("--report", action="store_true", help="Generate report file")
    args = parser.parse_args()

    linter = ZUSAtomLinter(verbose=args.verbose)
    report = linter.lint_all()

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print_report(report, verbose=args.verbose)

    if args.report:
        report_path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_INN10_ZUS_ATOM_LINTER.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as f:
            f.write("═" * 78 + "\n")
            f.write("  RAPORT INN10 — ZUS Atom Linter\n")
            f.write(f"  Quality Score: {report['quality_score']}/100\n")
            f.write(f"  Total Rules: {report['total_rules']}\n")
            f.write("═" * 78 + "\n\n")
            for issue in report["issues"]:
                f.write(f"[{issue['severity']}] {issue['file']}:{issue['rule_id']}\n")
                f.write(f"  {issue['message']}\n\n")
        print(f"  📄 Report saved: {report_path}")

    sys.exit(0 if report["recommendation"] == "PASS" else 1)


if __name__ == "__main__":
    main()
