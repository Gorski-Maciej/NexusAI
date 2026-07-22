#!/usr/bin/env python3
"""Live Architecture Diagrams — Auto-generacja diagramów C4 z kodu (Structurizr DSL).

Supermoce v7.0:
  - Skanuje kod w poszukiwaniu komponentów (moduły, serwisy, agenci)
  - Generuje diagramy C4: Context, Container, Component
  - Output: Markdown z Mermaid + ASCII fallback
  - CI: automatyczna aktualizacja przy każdym merge do main

Usage:
  python3 tools/live_architecture_diagrams.py > docs/ARCHITECTURE_LIVE.md
  python3 tools/live_architecture_diagrams.py --format structurizr > workspace.dsl
"""

from __future__ import annotations

import argparse
import ast
import sys
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parent.parent
NEXUS_AI = PROJECT_ROOT / "nexus_ai"


def discover_modules() -> dict[str, list[str]]:
    """Discover all Python modules and their public APIs."""
    modules: dict[str, list[str]] = {}

    for py_file in sorted(NEXUS_AI.rglob("*.py")):
        if "__pycache__" in str(py_file) or ".mypy_cache" in str(py_file):
            continue

        rel_path = py_file.relative_to(NEXUS_AI)
        module_name = str(rel_path.with_suffix("")).replace("/", ".").replace("\\", ".")

        try:
            tree = ast.parse(py_file.read_text())
            classes = [
                node.name for node in ast.walk(tree)
                if isinstance(node, ast.ClassDef) and not node.name.startswith("_")
            ]
            functions = [
                node.name for node in ast.walk(tree)
                if isinstance(node, ast.FunctionDef) and not node.name.startswith("_")
            ]
            if classes or functions:
                modules[module_name] = sorted(set(classes + functions[:5]))
        except SyntaxError:
            continue

    return modules


def categorize_module(name: str) -> str:
    """Categorize a module by its path."""
    if "agents" in name:
        return "Agenci AI"
    elif "services" in name:
        return "Serwisy"
    elif "core" in name:
        return "Core"
    elif "api" in name:
        return "API"
    elif "db" in name or "database" in name:
        return "Baza danych"
    elif "tax" in name:
        return "Podatki"
    elif "frontend" in name:
        return "Frontend"
    elif "installer" in name:
        return "Instalator"
    elif "events" in name:
        return "Eventy"
    elif "sdk" in name:
        return "SDK"
    else:
        return "Inne"


def generate_context_diagram() -> str:
    """Generate C4 Context diagram (Poziom 1)."""
    return """```mermaid
C4Context
    title NexusAI — Diagram Kontekstu (Poziom 1)

    Person(przedsiebiorca, "Przedsiębiorca JDG", "Właściciel firmy")
    Person(ksiegowy, "Księgowy/Doradca", "Biuro rachunkowe")

    System(nexusai, "NexusAI", "Wirtualny Księgowy — lokalna platforma AI")

    System_Ext(ksef, "KSeF", "Krajowy System e-Faktur")
    System_Ext(mf, "MF / US", "Ministerstwo Finansów, Urząd Skarbowy")
    System_Ext(zus, "ZUS", "Zakład Ubezpieczeń Społecznych")
    System_Ext(bank, "Bank", "Open Banking API")
    System_Ext(gus, "GUS / Biała Lista", "Rejestry publiczne")

    Rel(przedsiebiorca, nexusai, "Księguje faktury, podejmuje decyzje")
    Rel(ksiegowy, nexusai, "Weryfikuje, audytuje")
    Rel(nexusai, ksef, "Wysyła/pobiera e-faktury")
    Rel(nexusai, mf, "Wysyła JPK_V7, VAT-7")
    Rel(nexusai, zus, "Wysyła ZUS DRA")
    Rel(nexusai, bank, "Importuje wyciągi")
    Rel(nexusai, gus, "Weryfikuje NIP, Biała Lista")
```

### ASCII Fallback

```
┌─────────────────┐     ┌──────────────────────────────────────┐
│ Przedsiębiorca  │────▶│            NexusAI                   │
│ JDG             │     │  ┌──────┐ ┌──────┐ ┌───────────┐   │
└─────────────────┘     │  │Agenci│ │Serwisy│ │Core (Otel,│   │
                        │  │AI (5)│ │(15+) │ │Logger...) │   │
┌─────────────────┐     │  └──────┘ └──────┘ └───────────┘   │
│ Księgowy /      │────▶│                                      │
│ Doradca         │     │  Wirtualny Księgowy — lokalna AI    │
└─────────────────┘     └──┬───────┬──────┬───────┬──────┬───┘
                           │       │      │       │      │
                    ┌──────▼┐ ┌───▼──┐ ┌─▼──┐ ┌─▼──┐ ┌▼────┐
                    │ KSeF  │ │MF/US │ │ZUS │ │Bank│ │GUS  │
                    └───────┘ └──────┘ └────┘ └────┘ └─────┘
```"""


def generate_container_diagram(modules: dict[str, list[str]]) -> str:
    """Generate C4 Container diagram (Poziom 2)."""
    categories: dict[str, list[str]] = {}
    for name in modules:
        cat = categorize_module(name)
        categories.setdefault(cat, []).append(name)

    lines = [
        "```mermaid",
        "C4Container",
        "    title NexusAI — Diagram Kontenerów (Poziom 2)",
        "",
        "    Person(przedsiebiorca, \"Przedsiębiorca\", \"Użytkownik\")",
        "",
        "    Container(api, \"API Litestar\", \"Python 3.13\", \"REST API + WebSocket\")",
        "    Container(nats, \"NATS JetStream\", \"Message Broker\", \"Komunikacja async\")",
        "    Container(tigerbeetle, \"TigerBeetle\", \"Ledger DB\", \"Double-entry accounting\")",
        "    Container(duckdb, \"DuckDB\", \"OLAP\", \"Analityka + Shadow Ledger\")",
        "    Container(sqlite, \"SQLite\", \"SQLCipher\", \"Dane operacyjne\")",
        "    Container(flet, \"Flet UI\", \"Material 3\", \"Desktop GUI\")",
        "    Container(agents, \"5 Agentów AI\", \"GGUF lokalnie\", \"Cognitive Architecture\")",
        "    Container(opa, \"OPA/Rego\", \"779+ reguł\", \"Policy Engine\")",
        "",
    ]

    for cat_name, cat_modules in sorted(categories.items()):
        lines.append(f"    System_Boundary({cat_name.lower().replace(' ', '_')}, \"{cat_name}\") {{")
        for mod in cat_modules[:5]:
            short = mod.split(".")[-1]
            lines.append(f"        Container({short}, \"{short}\", \"Python\", \"{cat_name}\")")
        lines.append("    }")
        lines.append("")

    lines.append("    Rel(przedsiebiorca, flet, \"Używa\")")
    lines.append("    Rel(flet, api, \"HTTP/WebSocket\")")
    lines.append("    Rel(api, nats, \"Publikuje eventy\")")
    lines.append("    Rel(agents, nats, \"Subskrybuje taski\")")
    lines.append("    Rel(api, tigerbeetle, \"Transfery\")")
    lines.append("    Rel(api, duckdb, \"Analityka\")")
    lines.append("    Rel(api, sqlite, \"CRUD\")")
    lines.append("    Rel(api, opa, \"Ewaluuje reguły\")")
    lines.append("```")

    return "\n".join(lines)


def generate_component_summary(modules: dict[str, list[str]]) -> str:
    """Generate component summary table."""
    lines = [
        "## 📊 Mapa Komponentów (auto-generowana)",
        "",
        "| Kategoria | Moduł | Kluczowe komponenty |",
        "|-----------|-------|-------------------|",
    ]

    for name, components in sorted(modules.items()):
        cat = categorize_module(name)
        comp_str = ", ".join(f"`{c}`" for c in components[:3])
        extra = f" +{len(components) - 3}" if len(components) > 3 else ""
        lines.append(f"| {cat} | `{name}` | {comp_str}{extra} |")

    return "\n".join(lines)


def generate_markdown() -> str:
    """Generate complete architecture documentation."""
    modules = discover_modules()

    sections = [
        "# 🏗️ NexusAI — Architektura Live (auto-generowana)",
        "",
        f"> Wygenerowano automatycznie z kodu źródłowego.",
        f"> Liczba modułów: {len(modules)}",
        f"> Liczba kategorii: {len(set(categorize_module(m) for m in modules))}",
        "",
        "---",
        "",
        "## 📐 C4 Context (Poziom 1)",
        "",
        generate_context_diagram(),
        "",
        "---",
        "",
        "## 📦 C4 Container (Poziom 2)",
        "",
        generate_container_diagram(modules),
        "",
        "---",
        "",
        generate_component_summary(modules),
        "",
        "---",
        "",
        "*Dokumentacja auto-generowana przez `tools/live_architecture_diagrams.py`.*",
        "*Aktualizowana automatycznie przy każdym merge do main.*",
    ]

    return "\n\n".join(sections)


def generate_structurizr_dsl() -> str:
    """Generate Structurizr DSL for architecture visualization."""
    modules = discover_modules()

    lines = [
        "workspace \"NexusAI\" \"Wirtualny Księgowy — lokalna platforma AI\" {",
        "",
        "    model {",
        "        przedsiebiorca = person \"Przedsiębiorca JDG\"",
        "        ksiegowy = person \"Księgowy\"",
        "",
        "        api = softwareSystem \"NexusAI API\" {",
        "            webapp = container \"Litestar API\"",
        "        }",
        "",
    ]

    categories: dict[str, list[str]] = {}
    for name in modules:
        cat = categorize_module(name)
        categories.setdefault(cat, []).append(name)

    for cat_name, cat_modules in sorted(categories.items()):
        slug = cat_name.lower().replace(" ", "_")
        lines.append(f"        {slug} = container \"{cat_name}\" {{")
        for mod in cat_modules[:5]:
            short = mod.split(".")[-1]
            lines.append(f"            component {short} \"{short}\"")
        for mod in cat_modules[5:]:
            short = mod.split(".")[-1]
            lines.append(f"            component {short} \"{short}\"")
        lines.append("        }")
        lines.append("")

    lines.extend([
        "    }",
        "",
        "    views {",
        "        systemContext api { include * }",
        "        container api { include * }",
        "    }",
        "}",
    ])

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Live Architecture Diagrams Generator")
    parser.add_argument(
        "--format", choices=["markdown", "structurizr"], default="markdown",
        help="Output format (default: markdown)"
    )
    args = parser.parse_args()

    if args.format == "structurizr":
        print(generate_structurizr_dsl())
    else:
        print(generate_markdown())


if __name__ == "__main__":
    main()
