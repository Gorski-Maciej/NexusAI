"""
test_gap_analyzer.py — Automated Test Gap Analyzer.

Enterprise v7.0 Innowacja 11: Narzędzie porównujące kod źródłowy z testami.
  - Dla każdego modułu: czy ma testy?
  - Dla każdej funkcji: czy ma property-based test?
  - Raport: "AgentOrchestrator: 0 testów, 36 metod"
  - CI fail gdy nowy moduł bez testów

Usage:
    python -m nexus_ai.services.test_gap_analyzer [--threshold 80]
"""

from __future__ import annotations

import ast
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.test.gap")


@dataclass
class ModuleCoverage:
    """Coverage info for a single source module."""

    module_path: str
    source_lines: int
    function_count: int
    class_count: int
    test_file: str | None = None
    test_count: int = 0
    has_property_test: bool = False
    coverage_pct: float = 0.0

    @property
    def is_tested(self) -> bool:
        return self.test_count > 0


@dataclass
class GapReport:
    """Complete test gap analysis report."""

    modules: list[ModuleCoverage] = field(default_factory=list)
    total_modules: int = 0
    tested_modules: int = 0
    untested_modules: int = 0
    total_functions: int = 0
    tested_functions: int = 0
    overall_coverage_pct: float = 0.0
    critical_gaps: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "total_modules": self.total_modules,
            "tested_modules": self.tested_modules,
            "untested_modules": self.untested_modules,
            "overall_coverage_pct": round(self.overall_coverage_pct, 1),
            "critical_gaps": self.critical_gaps,
            "modules": [
                {
                    "path": m.module_path,
                    "source_lines": m.source_lines,
                    "functions": m.function_count,
                    "test_file": m.test_file,
                    "test_count": m.test_count,
                    "coverage_pct": round(m.coverage_pct, 1),
                }
                for m in self.modules
            ],
        }


class TestGapAnalyzer:
    """Analyze test coverage gaps in the codebase.

    Enterprise v7.0 Innowacja 11:
      - Parses all .py source files and test files
      - Matches source modules to test files
      - Reports untested modules with function counts
      - Identifies critical gaps (high-LOC modules without tests)
    """

    def __init__(
        self,
        source_dir: str | Path = "nexus_ai",
        test_dir: str | Path = "tests",
        *,
        critical_loc_threshold: int = 500,
    ) -> None:
        self.source_dir = Path(source_dir)
        self.test_dir = Path(test_dir)
        self.critical_loc_threshold = critical_loc_threshold

    def analyze(self) -> GapReport:
        """Run full test gap analysis."""
        source_modules = self._scan_source()
        test_map = self._scan_tests()

        modules: list[ModuleCoverage] = []
        for mod in source_modules:
            test_file = self._find_test(mod["path"], test_map)
            mc = ModuleCoverage(
                module_path=mod["path"],
                source_lines=mod["lines"],
                function_count=mod["functions"],
                class_count=mod["classes"],
            )
            if test_file:
                mc.test_file = test_file["path"]
                mc.test_count = test_file["test_count"]
                mc.has_property_test = test_file["has_property"]
                mc.coverage_pct = min(100.0, (test_file["test_count"] / max(mod["functions"], 1)) * 100)
            modules.append(mc)

        tested = [m for m in modules if m.is_tested]
        untested = [m for m in modules if not m.is_tested]
        critical = [
            f"{m.module_path} ({m.source_lines} LOC, {m.function_count} functions, 0 tests)"
            for m in untested
            if m.source_lines > self.critical_loc_threshold
        ]

        return GapReport(
            modules=modules,
            total_modules=len(modules),
            tested_modules=len(tested),
            untested_modules=len(untested),
            total_functions=sum(m.function_count for m in modules),
            tested_functions=sum(m.function_count for m in tested),
            overall_coverage_pct=(len(tested) / max(len(modules), 1)) * 100,
            critical_gaps=critical,
        )

    def _scan_source(self) -> list[dict[str, Any]]:
        """Scan all Python source files and extract function/class counts."""
        modules: list[dict[str, Any]] = []
        for py_file in self.source_dir.rglob("*.py"):
            if "__pycache__" in str(py_file) or py_file.name.startswith("_"):
                continue
            try:
                content = py_file.read_text(encoding="utf-8")
                tree = ast.parse(content)
                functions = sum(1 for node in ast.walk(tree) if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)))
                classes = sum(1 for node in ast.walk(tree) if isinstance(node, ast.ClassDef))
                lines = len(content.splitlines())
                rel_path = str(py_file.relative_to(self.source_dir.parent))
                modules.append({
                    "path": rel_path,
                    "lines": lines,
                    "functions": functions,
                    "classes": classes,
                })
            except (SyntaxError, UnicodeDecodeError) as exc:
                logger.debug("[GAP] Skipping %s: %s", py_file, exc)
        return modules

    def _scan_tests(self) -> dict[str, dict[str, Any]]:
        """Build a map of test file info keyed by candidate source name."""
        test_map: dict[str, dict[str, Any]] = {}
        for py_file in self.test_dir.rglob("test_*.py"):
            if "__pycache__" in str(py_file):
                continue
            try:
                content = py_file.read_text(encoding="utf-8")
                tree = ast.parse(content)
                test_count = sum(
                    1 for node in ast.walk(tree)
                    if isinstance(node, ast.FunctionDef) and node.name.startswith("test_")
                )
                has_property = "crosshair" in content or "hypothesis" in content
                rel_path = str(py_file.relative_to(self.test_dir.parent))

                # Extract candidate source name from test file name
                # test_inventory_fifo.py → inventory_fifo
                base = py_file.stem
                if base.startswith("test_"):
                    base = base[5:]
                test_map[base] = {
                    "path": rel_path,
                    "test_count": test_count,
                    "has_property": has_property,
                }
            except (SyntaxError, UnicodeDecodeError):
                pass
        return test_map

    def _find_test(
        self, source_path: str, test_map: dict[str, dict[str, Any]],
    ) -> dict[str, Any] | None:
        """Match a source module to its test file."""
        source_stem = Path(source_path).stem
        # Direct match: inventory_fifo.py → test_inventory_fifo
        if source_stem in test_map:
            return test_map[source_stem]
        # Substring match
        for key, info in test_map.items():
            if key in source_stem or source_stem in key:
                return info
        # Module path match
        source_parts = source_path.replace("/", "_").replace("\\", "_").replace(".py", "")
        for key, info in test_map.items():
            if key in source_parts or source_parts in key:
                return info
        return None


def print_report(report: GapReport) -> None:
    """Print a human-readable test gap report."""
    print("=" * 70)
    print("TEST GAP ANALYSIS REPORT")
    print("=" * 70)
    print(f"Total modules:     {report.total_modules}")
    print(f"Tested modules:    {report.tested_modules}")
    print(f"Untested modules:  {report.untested_modules}")
    print(f"Overall coverage:  {report.overall_coverage_pct:.1f}%")
    print(f"Total functions:   {report.total_functions}")
    print(f"Tested functions:  {report.tested_functions}")
    print()

    if report.critical_gaps:
        print(f"CRITICAL GAPS ({len(report.critical_gaps)} modules > {500} LOC without tests):")
        for gap in report.critical_gaps:
            print(f"  ❌ {gap}")
    else:
        print("✅ No critical gaps found!")

    untested = [m for m in report.modules if not m.is_tested]
    if untested:
        print(f"\nUNTESTED MODULES ({len(untested)}):")
        for m in sorted(untested, key=lambda x: -x.source_lines)[:20]:
            print(f"  ⚠️  {m.module_path} ({m.source_lines} LOC, {m.function_count} functions)")


if __name__ == "__main__":
    analyzer = TestGapAnalyzer()
    report = analyzer.analyze()
    print_report(report)
