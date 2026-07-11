#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI — ScLegalGraph: Graf Zależności Reguł dla Spółki Cywilnej
# ═══════════════════════════════════════════════════════════════════════════════
#
# Narzędzie do analizy spójności reguł OPA/Rego dla spółki cywilnej.
# Buduje graf zależności między regułami z dokumentów planu i wykrywa:
#   - Cykliczne zależności (cycle detection)
#   - Osierocone reguły (orphan detection)
#   - Luki w priorytetach (priority gap detection)
#   - Pokrycie podstaw prawnych (legal basis coverage)
#   - Konflikty first-match-wins
#
# Ulepszenie #3 z 38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md
#
# Usage:
#   python3 sc_legal_graph.py [--plan-dir PLAN_OPA] [--rego-dir POLICIES]
#   python3 sc_legal_graph.py --validate
#   python3 sc_legal_graph.py --report coverage
# ═══════════════════════════════════════════════════════════════════════════════

import argparse
import json
import os
import re
import sys
from collections import defaultdict, deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


# ── Data Classes ──────────────────────────────────────────────────────────────

@dataclass
class Rule:
    """Reprezentuje pojedynczą regułę z dokumentu planu."""
    rule_id: str
    name: str
    priority: int
    package: str
    legal_basis: str = ""
    dependencies: List[str] = field(default_factory=list)
    edge_cases: List[str] = field(default_factory=list)
    description: str = ""


@dataclass
class LegalBasis:
    """Reprezentuje podstawę prawną."""
    article: str
    act: str = ""
    covered_by: List[str] = field(default_factory=list)


class ScLegalGraph:
    """Graf zależności między regułami spółki cywilnej."""

    def __init__(self):
        self.rules: Dict[str, Rule] = {}
        self.graph: Dict[str, Set[str]] = defaultdict(set)
        self.reverse_graph: Dict[str, Set[str]] = defaultdict(set)
        self.legal_bases: Dict[str, LegalBasis] = {}
        self.priority_map: Dict[int, List[str]] = defaultdict(list)

    def parse_markdown_documents(self, plan_dir: str) -> int:
        """Parsuje dokumenty Markdown z Plan OPA i ekstrahuje reguły."""
        plan_path = Path(plan_dir)
        sc_docs = [
            "SC_DEFINITIVE_REGO_PLAN.md",
            "SC_EXPANSION_14_AREAS.md",
            "35_SPOLKA_CYWILNA_ADVANCED_GAPS.md",
            "36_SPOLKA_CYWILNA_ULTIMATE_GAPS.md",
            "37_SPOLKA_CYWILNA_ULTIMATE_GRANULARITY.md",
        ]

        count = 0
        for doc_name in sc_docs:
            doc_path = plan_path / doc_name
            if not doc_path.exists():
                print(f"⚠️  Dokument nie znaleziony: {doc_name}", file=sys.stderr)
                continue
            count += self._parse_document(doc_path)

        return count

    def _parse_document(self, path: Path) -> int:
        """Parsuje pojedynczy dokument Markdown."""
        content = path.read_text()
        count = 0

        # Wzorce ekstrakcji reguł — obsługa formatu P i GR
        patterns = [
            # Format: #### GR-XXX: `nazwa_reguly` (gwiazdki)
            re.compile(
                r'^####\s+GR-(\d+):\s+`([^`]+)`\s*(★*)',
                re.MULTILINE
            ),
            # Format: ### PXXX: `nazwa_reguly` (gwiazdki)
            re.compile(
                r'^####\s+P(\d+):\s+`([^`]+)`\s*(★*)',
                re.MULTILINE
            ),
        ]

        for pattern in patterns:
            for match in pattern.finditer(content):
                priority = int(match.group(1))
                name = match.group(2)
                importance = match.group(3)

                # Ekstrakcja podstawy prawnej z następnych 5 linii
                text_after = content[match.end():match.end() + 500]
                legal_basis = self._extract_legal_basis(text_after)
                dependencies = self._extract_dependencies(text_after)
                edge_cases = self._extract_edge_cases(text_after)

                rule_id = f"GR-{priority}" if "GR" in match.group(0) else f"P{priority}"
                package = self._extract_package(content, match.start())

                rule = Rule(
                    rule_id=rule_id,
                    name=name,
                    priority=priority,
                    package=package,
                    legal_basis=legal_basis,
                    dependencies=dependencies,
                    edge_cases=edge_cases,
                    description=text_after[:200].strip()
                )

                self._add_rule(rule)
                count += 1

        return count

    def _extract_legal_basis(self, text: str) -> str:
        """Ekstrahuje podstawę prawną z tekstu po regule."""
        patterns = [
            r'Art\.\s*[\d]+\s*(?:ust\.\s*\d+)?\s*\w+',
            r'Art\.\s*[\d]+[a-z]?(?:\s*§?\s*[\d]+)?\s*(?:ust\.\s*[\d]+)?\s*\w+',
        ]
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                return match.group(0)
        return ""

    def _extract_dependencies(self, text: str) -> List[str]:
        """Ekstrahuje zależności od innych reguł."""
        deps = []
        dep_patterns = [
            r'Po\s+GR-(\d+)',
            r'Po\s+P(\d+)',
            r'Przed\s+GR-(\d+)',
            r'Przed\s+P(\d+)',
        ]
        for pattern in dep_patterns:
            for match in re.finditer(pattern, text):
                deps.append(f"GR-{match.group(1)}")
        return deps

    def _extract_edge_cases(self, text: str) -> List[str]:
        """Ekstrahuje przypadki brzegowe."""
        edge_pattern = re.compile(r'Brzegowe?:.*?(?=##|\Z)', re.DOTALL)
        match = edge_pattern.search(text)
        if match:
            return [e.strip() for e in match.group(0).split('•') if e.strip()]
        return []

    def _extract_package(self, content: str, position: int) -> str:
        """Znajduje pakiet dla reguły na podstawie nagłówka sekcji."""
        preceding = content[:position]
        package_pattern = re.compile(
            r'###\s+\d+\.\d+\s+(sc\.\S+)',
            re.MULTILINE
        )
        matches = package_pattern.findall(preceding)
        return matches[-1] if matches else "unknown"

    def _add_rule(self, rule: Rule) -> None:
        """Dodaje regułę do grafu."""
        if rule.rule_id not in self.rules:
            self.rules[rule.rule_id] = rule
        else:
            # Jeśli reguła już istnieje, łączymy dane
            existing = self.rules[rule.rule_id]
            if rule.legal_basis:
                existing.legal_basis = rule.legal_basis
            if rule.package != "unknown":
                existing.package = rule.package

        self.priority_map[rule.priority].append(rule.rule_id)

        for dep in rule.dependencies:
            self.graph[rule.rule_id].add(dep)
            self.reverse_graph[dep].add(rule.rule_id)

    # ── Analizy ────────────────────────────────────────────────────────────

    def detect_cycles(self) -> List[List[str]]:
        """Wykrywa cykle w grafie zależności."""
        cycles = []
        visited = set()
        stack = []

        def dfs(node: str) -> None:
            if node in stack:
                cycle_start = stack.index(node)
                cycles.append(stack[cycle_start:] + [node])
                return
            if node in visited:
                return
            visited.add(node)
            stack.append(node)
            for neighbor in self.graph.get(node, set()):
                dfs(neighbor)
            stack.pop()

        for node in self.graph:
            if node not in visited:
                dfs(node)
        return cycles

    def detect_orphans(self) -> List[str]:
        """Wykrywa osierocone reguły — nieprzywoływane przez żadną inną."""
        all_deps = set()
        for deps in self.graph.values():
            all_deps.update(deps)
        return [rid for rid in self.rules if rid not in all_deps and rid not in self.graph]

    def detect_priority_gaps(self, max_gap: int = 5) -> List[Tuple[int, int]]:
        """Wykrywa luki w priorytetach."""
        priorities = sorted(self.priority_map.keys())
        gaps = []
        for i in range(len(priorities) - 1):
            gap = priorities[i + 1] - priorities[i]
            if gap > max_gap:
                gaps.append((priorities[i], priorities[i + 1]))
        return gaps

    def detect_priority_conflicts(self) -> List[Tuple[int, List[str]]]:
        """Wykrywa wiele reguł z tym samym priorytetem."""
        return [(p, rids) for p, rids in self.priority_map.items() if len(rids) > 1]

    def coverage_report(self, expected_articles: List[str]) -> Dict[str, float]:
        """Generuje raport pokrycia podstaw prawnych."""
        covered = set()
        for rule in self.rules.values():
            if rule.legal_basis:
                covered.add(rule.legal_basis)

        expected_set = set(expected_articles)
        covered_count = len(covered & expected_set)
        missing = expected_set - covered

        return {
            "total_expected": len(expected_set),
            "covered": covered_count,
            "missing": list(missing)[:20],
            "coverage_pct": covered_count / len(expected_set) * 100 if expected_set else 0,
        }

    def generate_impact_report(self, rule_id: str) -> Dict:
        """Generuje raport wpływu zmiany danej reguły."""
        impact_upstream = self._bfs_upstream(rule_id)
        impact_downstream = self._bfs_downstream(rule_id)
        return {
            "rule_id": rule_id,
            "rule_name": self.rules.get(rule_id, Rule("", "", 0, "")).name,
            "affects_upstream": list(impact_upstream),
            "affects_downstream": list(impact_downstream),
            "total_affected": len(impact_upstream) + len(impact_downstream),
        }

    def _bfs_upstream(self, node: str) -> Set[str]:
        """BFS w górę grafu — które reguły zależą od tej reguły?"""
        visited = set()
        queue = deque([node])
        while queue:
            current = queue.popleft()
            if current in visited:
                continue
            visited.add(current)
            for neighbor in self.reverse_graph.get(current, set()):
                if neighbor not in visited:
                    queue.append(neighbor)
        visited.discard(node)
        return visited

    def _bfs_downstream(self, node: str) -> Set[str]:
        """BFS w dół grafu — od jakich reguł ta reguła zależy?"""
        visited = set()
        queue = deque([node])
        while queue:
            current = queue.popleft()
            if current in visited:
                continue
            visited.add(current)
            for neighbor in self.graph.get(current, set()):
                if neighbor not in visited:
                    queue.append(neighbor)
        visited.discard(node)
        return visited

    # ── Export ──────────────────────────────────────────────────────────────

    def export_dot(self) -> str:
        """Eksportuje graf do formatu DOT (Graphviz)."""
        lines = ["digraph ScLegalGraph {", "  rankdir=TB;", '  node [shape=box, style=filled, fillcolor=lightyellow];']
        for rule_id, rule in self.rules.items():
            label = f"{rule.name}\\n[{rule_id}] {rule.package}"
            lines.append(f'  "{rule_id}" [label="{label}"];')
        for src, deps in self.graph.items():
            for dst in deps:
                lines.append(f'  "{src}" -> "{dst}";')
        lines.append("}")
        return "\n".join(lines)

    def export_json(self) -> Dict:
        """Eksportuje graf do JSON."""
        return {
            "rules": {
                rid: {
                    "name": r.name,
                    "priority": r.priority,
                    "package": r.package,
                    "legal_basis": r.legal_basis,
                }
                for rid, r in self.rules.items()
            },
            "dependencies": {k: list(v) for k, v in self.graph.items()},
        }


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="ScLegalGraph — analiza spójności reguł SC")
    parser.add_argument("--plan-dir", default="Plan OPA", help="Katalog z dokumentami planu")
    parser.add_argument("--validate", action="store_true", help="Uruchom pełną walidację")
    parser.add_argument("--report", choices=["cycles", "orphans", "gaps", "conflicts", "coverage", "impact"], help="Typ raportu")
    parser.add_argument("--rule-id", help="ID reguły dla impact report")
    parser.add_argument("--export", choices=["dot", "json"], help="Format eksportu")
    args = parser.parse_args()

    graph = ScLegalGraph()
    count = graph.parse_markdown_documents(args.plan_dir)
    print(f"✅ Sparsowano {count} reguł z dokumentów w {args.plan_dir}/")

    if args.validate or args.report == "cycles":
        cycles = graph.detect_cycles()
        if cycles:
            print(f"\n🔴 CYKLE: Znaleziono {len(cycles)} cykli zależności!")
            for cycle in cycles:
                print(f"   {' → '.join(cycle)}")
        else:
            print("\n✅ Brak cykli w grafie zależności")

    if args.validate or args.report == "orphans":
        orphans = graph.detect_orphans()
        if orphans:
            print(f"\n🟡 OSIEROCONE: {len(orphans)} reguł bez zależności")
            for orphan in orphans[:10]:
                rule = graph.rules.get(orphan)
                if rule:
                    print(f"   {orphan}: {rule.name}")
        else:
            print("\n✅ Brak osieroconych reguł")

    if args.validate or args.report == "gaps":
        gaps = graph.detect_priority_gaps()
        if gaps:
            print(f"\n🟡 LUKI: {len(gaps)} luk w priorytetach >5")
            for g in gaps[:10]:
                print(f"   Między {g[0]} a {g[1]} — luka {g[1] - g[0]}")
        else:
            print("\n✅ Priorytety bez znaczących luk")

    if args.validate or args.report == "conflicts":
        conflicts = graph.detect_priority_conflicts()
        if conflicts:
            print(f"\n🔴 KONFLIKTY: {len(conflicts)} priorytetów z wieloma regułami!")
            for priority, rids in conflicts:
                print(f"   Priorytet {priority}: {', '.join(rids)}")
        else:
            print("\n✅ Brak konfliktów priorytetów")

    if args.report == "coverage":
        expected = [
            "Art. 8 PIT", "Art. 26e PIT", "Art. 41 VAT", "Art. 86 VAT",
            "Art. 113 VAT", "Art. 864 KC", "Art. 866 KC", "Art. 867 KC",
            "Art. 869 KC", "Art. 871 KC", "Art. 872 KC", "Art. 874 KC",
        ]
        coverage = graph.coverage_report(expected)
        print(f"\n📊 POKRYCIE: {coverage['coverage_pct']:.1f}% ({coverage['covered']}/{coverage['total_expected']})")
        if coverage["missing"]:
            print(f"   Brakuje: {', '.join(coverage['missing'][:10])}")

    if args.report == "impact" and args.rule_id:
        impact = graph.generate_impact_report(args.rule_id)
        print(f"\n🎯 WPŁYW zmiany {args.rule_id} ({impact['rule_name']}):")
        print(f"   W górę (zależy od): {len(impact.get('affects_upstream', []))} reguł")
        print(f"   W dół (zależy od niego): {len(impact.get('affects_downstream', []))} reguł")
        print(f"   Łącznie dotkniętych: {impact.get('total_affected', 0)} reguł")

    if args.export == "dot":
        dot = graph.export_dot()
        output_path = "sc_legal_graph.dot"
        Path(output_path).write_text(dot)
        print(f"\n📁 Graf wyeksportowany do {output_path} (render: dot -Tpng {output_path} -o graph.png)")

    if args.export == "json":
        data = graph.export_json()
        output_path = "sc_legal_graph.json"
        Path(output_path).write_text(json.dumps(data, indent=2, ensure_ascii=False))
        print(f"\n📁 Graf wyeksportowany do {output_path}")


if __name__ == "__main__":
    main()
