#!/usr/bin/env python3
"""
NexusAI JDG — V3-P65 TOOL DOCUMENTATION GENERATOR (I12; prompt P65 Sekcja 10-I12).
Dokumentacja narzędzi GENEROWANA z definicji (docstring + argparse) — zero
dryfu (binding P60: docs ↔ kod w jednym źródle). Generator czyta moduły P65,
ekstrahuje kontrakt (docstring, flagi CLI, wyjście) i pisze spójny dokument
docs/TOOLS_P65_GENERATED.md; dryf wykrywany porównaniem hash treści.

Uruchomienie: python3 v3_p65_doc_generator.py [--json] [--check]
Wynik: docs/TOOLS_P65_GENERATED.md + bundles/v3_p65_i12_docs.json
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p65_common import (BUNDLES, DOCS_DIR, DOCS_GENERATED, TOOLS_DIR,
                           audit_header, now_iso, read_threshold, write_json)

SCHEMA = "jdg.v3_p65.doc_generator.v1"
P65_TOOLS = ["v3_p65_tool_contract.py", "v3_p65_semantic_diff.py",
             "v3_p65_rule_to_tests.py", "v3_p65_worm_tamper_test.py",
             "v3_p65_adoption_metrics.py"]


def extract_tool_def(path: Path) -> dict:
    """Definicja narzędzia z AST: docstring, flagi argparse, wyjście."""
    tree = ast.parse(path.read_text(encoding="utf-8", errors="replace"))
    doc = ast.get_docstring(tree) or ""
    flags = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and getattr(node.func, "attr", "") == "add_argument":
            if node.args and isinstance(node.args[0], ast.Constant):
                flags.append(str(node.args[0].value))
    output = "bundles/v3_p65_*.json" if "BUNDLES" in path.read_text(encoding="utf-8", errors="replace") else "-"
    return {"tool": path.name, "docstring_first_line": doc.splitlines()[0] if doc else "",
            "cli_flags": sorted(set(flags)), "output": output}


def render(docs: list[dict]) -> str:
    lines = [
        "# NARZĘDZIA V3-P65 NOWE NARZĘDZIA FORTECY (WYGENEROWANE)",
        "",
        f"Generator: tools/v3_p65_doc_generator.py | Binding P60: docs ↔ kod (zero dryfu) | Wygenerowano: {now_iso()}",
        "",
        "| # | Narzędzie | Opis | Flagi CLI | Wyjście |",
        "|---|-----------|------|-----------|---------|",
    ]
    for i, d in enumerate(docs, 1):
        lines.append(f"| {i} | `{d['tool']}` | {d['docstring_first_line']} | "
                     f"{', '.join(d['cli_flags']) or '—'} | {d['output']} |")
    lines += ["",
              "## Kontrakt wspólny (I01)",
              "",
              "Każde narzędzie: `python3 <tool>.py [--dry-run] [--json]`; raport JSON "
              "min. pola: schema, tool, status, provenance; exit codes 0/1/2.",
              "",
              "> Ten plik jest generowany — NIE edytuj ręcznie (dryf = NEEDS_ADVICE I12)."]
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description="V3-P65 I12 tool documentation generator")
    ap.add_argument("--check", action="store_true", help="tylko detekcja dryfu (bez zapisu)")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    defs = [extract_tool_def(TOOLS_DIR / t) for t in P65_TOOLS]
    rendered = render(defs)
    digest = hashlib.sha256(rendered.encode()).hexdigest()[:16]
    existing = DOCS_GENERATED.read_text(encoding="utf-8", errors="replace") if DOCS_GENERATED.exists() else ""
    drift = bool(existing) and hashlib.sha256(existing.encode()).hexdigest()[:16] != digest
    binding_required = read_threshold("v3_p65_doc_binding_required")
    payload = {
        "schema": SCHEMA,
        "tool": "v3_p65_doc_generator",
        "status": "FAIL" if drift else "PASS",
        "gate": "FAIL" if drift else "PASS",
        "doc_binding_required": binding_required,
        "doc_binding_present": (not drift) and DOCS_GENERATED.exists() or (not drift and bool(existing)),
        "drift_detected": drift,
        "content_hash": digest,
        "tools_documented": len(defs),
        "definitions": defs,
        "output_doc": "docs/TOOLS_P65_GENERATED.md",
        "evidence": "AST (docstring + add_argument) z definicji narzędzi — zero ręcznych opisów",
        "provenance": "P60 dokumentacja domknięcie (binding); prompt P65 Sekcja 10-I12",
        "generated_at": now_iso(),
    }
    if not args.check:
        DOCS_GENERATED.write_text(rendered, encoding="utf-8")
        payload["doc_binding_present"] = True
        payload["status"] = payload["gate"] = "PASS"
    write_json(BUNDLES / "v3_p65_i12_docs.json",
               {"header": audit_header({"I12_docs": None}), "result": payload})
    print(f"[P65:I12] doc_generator tools={len(defs)} drift={drift} status={payload['status']}")
    return 0 if payload["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
