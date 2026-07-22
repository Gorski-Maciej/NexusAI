#!/usr/bin/env python3
"""Documentation Coverage Map — Auto-generowana mapa pokrycia dokumentacją.

Supermoce v7.0:
  - Skanuje kod w poszukiwaniu docstringów
  - Mapuje moduły do plików dokumentacji
  - Generuje siatkę pokrycia: które moduły mają docs, które nie
  - Output: Markdown tabela + JSON

Usage:
  python3 tools/doc_coverage_map.py > docs/COVERAGE_MAP.md
  python3 tools/doc_coverage_map.py --format json > coverage.json
"""

from __future__ import annotations

import argparse
import ast
import json
import sys
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parent.parent
NEXUS_AI = PROJECT_ROOT / "nexus_ai"
DOCS_DIR = PROJECT_ROOT / "docs"


def analyze_module(py_file: Path) -> dict[str, Any]:
    """Analyze a Python module for documentation coverage."""
    try:
        tree = ast.parse(py_file.read_text())
    except SyntaxError:
        return {"error": "syntax_error"}

    rel_path = py_file.relative_to(NEXUS_AI)
    module_name = str(rel_path.with_suffix("")).replace("/", ".").replace("\\", ".")

    total_classes = 0
    documented_classes = 0
    total_functions = 0
    documented_functions = 0
    total_methods = 0
    documented_methods = 0
    has_module_doc = False

    for node in ast.walk(tree):
        if isinstance(node, ast.Module):
            has_module_doc = bool(ast.get_docstring(node))
        elif isinstance(node, ast.ClassDef):
            if node.name.startswith("_"):
                continue
            total_classes += 1
            if ast.get_docstring(node):
                documented_classes += 1
            for child in node.body:
                if isinstance(child, ast.FunctionDef) and not child.name.startswith("_"):
                    total_methods += 1
                    if ast.get_docstring(child):
                        documented_methods += 1
        elif isinstance(node, ast.FunctionDef):
            if node.name.startswith("_"):
                continue
            # Skip methods (handled above)
            if any(isinstance(p, ast.ClassDef) for p in ast.walk(tree) if
                   hasattr(p, 'body') and node in getattr(p, 'body', [])):
                continue
            total_functions += 1
            if ast.get_docstring(node):
                documented_functions += 1

    total = total_classes + total_functions + total_methods
    documented = documented_classes + documented_functions + documented_methods
    coverage = (documented / total * 100) if total > 0 else 100.0

    return {
        "module": module_name,
        "total_classes": total_classes,
        "documented_classes": documented_classes,
        "total_functions": total_functions,
        "documented_functions": documented_functions,
        "total_methods": total_methods,
        "documented_methods": documented_methods,
        "coverage_pct": round(coverage, 1),
        "has_module_doc": has_module_doc,
    }


def find_docs_for_module(module_name: str, docs_files: list[Path]) -> list[str]:
    """Find documentation files related to a module."""
    related: list[str] = []

    # Map module parts to doc filenames
    parts = module_name.split(".")
    keywords = set(parts)
    keywords.add(module_name.replace(".", "_"))

    for doc_file in docs_files:
        doc_name = doc_file.stem.lower()
        doc_content = ""
        try:
            doc_content = doc_file.read_text().lower()
        except Exception:
            pass

        for kw in keywords:
            if kw.lower() in doc_name or kw.lower() in doc_content[:500]:
                related.append(str(doc_file.relative_to(DOCS_DIR)))
                break

    return sorted(set(related))


def generate_coverage_map() -> str:
    """Generate documentation coverage map as Markdown."""
    docs_files = sorted(DOCS_DIR.glob("*.md")) if DOCS_DIR.exists() else []
    py_files = sorted(NEXUS_AI.rglob("*.py"))

    results: list[dict[str, Any]] = []
    total_coverage = 0.0
    fully_documented = 0
    undocumented = 0

    for py_file in py_files:
        if "__pycache__" in str(py_file) or ".mypy_cache" in str(py_file):
            continue
        result = analyze_module(py_file)
        if "error" in result:
            continue
        related_docs = find_docs_for_module(result["module"], docs_files)
        result["related_docs"] = related_docs
        result["has_doc_file"] = len(related_docs) > 0
        results.append(result)
        total_coverage += result["coverage_pct"]
        if result["coverage_pct"] >= 90:
            fully_documented += 1
        if result["coverage_pct"] == 0:
            undocumented += 1

    avg_coverage = total_coverage / max(len(results), 1)

    lines = [
        "# 📊 Documentation Coverage Map (auto-generowana)",
        "",
        f"> **Średnie pokrycie docstringami:** {avg_coverage:.1f}%",
        f"> **Moduły w pełni udokumentowane (≥90%):** {fully_documented}/{len(results)}",
        f"> **Moduły bez dokumentacji (0%):** {undocumented}/{len(results)}",
        f"> **Pliki dokumentacji:** {len(docs_files)}",
        "",
        "---",
        "",
        "## 🗺️ Mapa pokrycia",
        "",
        "| Moduł | Klasy | Funkcje | Metody | Pokrycie | Docs |",
        "|-------|-------|---------|--------|----------|------|",
    ]

    for r in sorted(results, key=lambda x: x["coverage_pct"]):
        icon = "✅" if r["coverage_pct"] >= 90 else "⚠️" if r["coverage_pct"] >= 50 else "❌"
        docs_icon = "📄" if r["has_doc_file"] else "—"
        lines.append(
            f"| `{r['module']}` | {r['documented_classes']}/{r['total_classes']} | "
            f"{r['documented_functions']}/{r['total_functions']} | "
            f"{r['documented_methods']}/{r['total_methods']} | "
            f"{icon} {r['coverage_pct']:.0f}% | {docs_icon} |"
        )

    lines.extend([
        "",
        "---",
        "",
        "## 📋 Moduły bez dokumentacji",
        "",
    ])

    for r in results:
        if r["coverage_pct"] == 0:
            lines.append(f"- ❌ `{r['module']}` — zero docstringów")

    lines.extend([
        "",
        "## 🏆 Top 10 najlepiej udokumentowanych modułów",
        "",
    ])

    for r in sorted(results, key=lambda x: x["coverage_pct"], reverse=True)[:10]:
        if r["coverage_pct"] > 0:
            lines.append(f"- ✅ `{r['module']}` — {r['coverage_pct']:.0f}% pokrycia")

    lines.extend([
        "",
        "---",
        "",
        "*Mapa generowana automatycznie przez `tools/doc_coverage_map.py`.*",
        "*Aktualizowana przy każdym merge do main.*",
    ])

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Documentation Coverage Map Generator")
    parser.add_argument(
        "--format", choices=["markdown", "json"], default="markdown",
        help="Output format"
    )
    args = parser.parse_args()

    if args.format == "json":
        docs_files = sorted(DOCS_DIR.glob("*.md")) if DOCS_DIR.exists() else []
        py_files = sorted(NEXUS_AI.rglob("*.py"))
        results = []
        for py_file in py_files:
            if "__pycache__" in str(py_file) or ".mypy_cache" in str(py_file):
                continue
            result = analyze_module(py_file)
            if "error" in result:
                continue
            results.append(result)
        print(json.dumps({"modules": results}, indent=2, ensure_ascii=False))
    else:
        print(generate_coverage_map())


if __name__ == "__main__":
    main()
