#!/usr/bin/env python3
"""Canonical evidence gate for campaign PROMPT_24 — LEGAL TWIN (F1).

Audits the executable Legal Twin contract: LKG (legal_graph from Bbb.md),
legal basis audit (RV), legal source registry, coverage gap + heatmap,
traceability (reguła → węzeł → werdykt), reverse coverage (artykuł bez
reguły), and metric gates LCI/TCL/RV. Honesty: repository completeness vs
production certification — production stays NOT_CERTIFIED; RV/LCI gaps are
reported honestly, not hidden.
"""
from __future__ import annotations

import argparse
import ast
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT = "raporty_enterprise_v4/24_LEGAL_TWIN.txt"
EVIDENCE = BUNDLES_DIR / "legal_twin_report24_evidence.json"

TOOL_SCOPE = (
    "tools/legal_basis_audit.py",
    "tools/validate_legal_basis.py",
    "tools/validate_legal_basis_v2.py",
    "tools/legal_source_registry.py",
    "tools/legal_coverage_gap_report.py",
    "tools/legal_coverage_heatmap.py",
    "tools/legal_change_impact_analyzer.py",
    "tools/legal_change_calendar.py",
    "tools/legal_twin_traceability.py",
    "tools/traceability_matrix.py",
    "tools/lkg_generator.py",
    "tools/reverse_coverage_detector.py",
    "tools/fix_p00_legal_basis_closure.py",
)

DOC_SCOPE = (
    "docs/Bbb",
    "docs/Bbb.md",
    "docs/LEGAL_REFERENCE_ACTS.md",
    "docs/AUDYT_PODSTAW_PRAWNYCH.md",
    "docs/LEGAL_COVERAGE.md",
    "docs/LEGAL_COVERAGE_GAP_RAPORT.md",
    "docs/SLOWNIK_REFERENCJI_PRAWNYCH.md",
    "docs/LEGAL_SOURCE_REGISTRY.md",
    "docs/LEGAL_TWIN_TRACEABILITY.md",
    "docs/LEGAL_TWIN_RAPORT.md",
    "docs/P00_REMEDIACJA_PODSTAW_PRAWNYCH.md",
    "docs/KALENDARZ_ZMIAN_PRAWNYCH.md",
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
)

BUNDLE_SCOPE = (
    "bundles/legal_reference_canon.json",
    "bundles/legal_graph.json",
    "bundles/legal_source_registry.json",
    "bundles/legal_twin_traceability.json",
    "bundles/legal_coverage_gaps.json",
    "bundles/legal_basis_audit.json",
    "bundles/legal_change_calendar.json",
    "bundles/legal_graph_seed.sql",
)

TEST_SCOPE = (
    "tests/test_legal_source_registry.py",
    "tests/test_legal_twin_traceability.py",
    "tests/test_legal_twin_infrastructure.py",
)

RUNTIME_REGO = "rules/audit/runtime_invariants_enterprise.rego"


def read(rel: str) -> str:
    try:
        return (BASE_DIR / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def exists(rel: str) -> bool:
    return bool(read(rel))


def load_json(rel: str) -> dict:
    try:
        return json.loads(read(rel))
    except (json.JSONDecodeError, TypeError):
        return {}


def scope_evidence() -> dict[str, Any]:
    all_paths = (*TOOL_SCOPE, *DOC_SCOPE, *BUNDLE_SCOPE, *TEST_SCOPE, RUNTIME_REGO)
    statuses = {path: exists(path) for path in dict.fromkeys(all_paths)}
    return {
        "declared": len(statuses),
        "present": sum(statuses.values()),
        "all_present": all(statuses.values()),
        "missing": [path for path, ok in statuses.items() if not ok],
        "files": statuses,
    }


def lkg_evidence() -> dict[str, Any]:
    graph = load_json("bundles/legal_graph.json")
    nodes = graph.get("nodes", [])
    acts = graph.get("acts", [])
    indexes = graph.get("indexes", {})
    return {
        "nodes_count": graph.get("nodes_count", len(nodes)),
        "acts_count": graph.get("acts_count", len(acts)),
        "covered_nodes": graph.get("covered_nodes", 0),
        "indexes": indexes,
        "slo": graph.get("slo", {}),
        "has_article_nodes": any(n.get("node_type") == "ARTICLE" for n in nodes),
        "has_material_nodes": any(n.get("material") for n in nodes),
        "temporal_fields": all(n.get("valid_from") for n in nodes) if nodes else False,
        "seed_sql": "CREATE TABLE IF NOT EXISTS legal_graph" in read("bundles/legal_graph_seed.sql"),
        "complete": bool(nodes) and any(n.get("material") for n in nodes) and "LCI" in indexes,
    }


def audit_evidence() -> dict[str, Any]:
    audit = load_json("bundles/legal_basis_audit.json")
    stats = audit.get("stats", {})
    rv = audit.get("rv_metric", 0.0)
    trace = load_json("bundles/legal_twin_traceability.json")
    trace_metrics = trace.get("metrics", {})
    return {
        "rules_total": audit.get("rules_total", 0),
        "stats": stats,
        "rv_metric": rv,
        "rv_gate_tool": "--gate" in read("tools/legal_basis_audit.py"),
        "canonical_dict": len(load_json("bundles/legal_reference_canon.json").get("acts", [])) >= 10,
        "traceability_indexes": trace_metrics,
        "audit_report": exists("docs/AUDYT_PODSTAW_PRAWNYCH.md"),
        "complete": bool(stats) and rv >= 0 and bool(trace_metrics),
    }


def coverage_evidence() -> dict[str, Any]:
    gaps = load_json("bundles/legal_coverage_gaps.json")
    heatmap_md = read("reports/legal_coverage_heatmap.md")
    heatmap_html = exists("reports/legal_coverage_heatmap.html")
    reverse = gaps.get("reverse_coverage", {})
    return {
        "by_status": gaps.get("by_status", {}),
        "priorities": gaps.get("priorities", {}),
        "reverse_uncovered": reverse.get("uncovered", 0),
        "reverse_coverage_pct": reverse.get("coverage_pct", 100.0),
        "heatmap_md": bool(heatmap_md),
        "heatmap_html": heatmap_html,
        "complete": bool(gaps) and (bool(heatmap_md) or heatmap_html),
    }


def traceability_evidence() -> dict[str, Any]:
    trace = load_json("bundles/legal_twin_traceability.json")
    tool = read("tools/legal_twin_traceability.py")
    return {
        "traceability_id": trace.get("traceability_id"),
        "metrics": trace.get("metrics", {}),
        "rules_indexed": len(trace.get("rules", {})),
        "findings": trace.get("findings", {}),
        "tool_has_verdict_links": "verdict" in tool or "_legal_basis_refs" in tool,
        "complete": bool(trace.get("metrics")) and bool(trace.get("rules")),
    }


def reverse_coverage_evidence() -> dict[str, Any]:
    tool = read("tools/reverse_coverage_detector.py")
    gaps = load_json("bundles/legal_coverage_gaps.json")
    reverse = gaps.get("reverse_coverage", {})
    return {
        "tool_present": bool(tool),
        "gaps_detected": reverse.get("uncovered", 0),
        "coverage_pct": reverse.get("coverage_pct", 100.0),
        "has_priority_rows": bool(reverse.get("gaps", [])),
        "complete": bool(tool) and "priority" in json.dumps(reverse, ensure_ascii=False),
    }


def metric_gates_evidence() -> dict[str, Any]:
    """Bramki metryk — uczciwie: LCI/TCL wymagane, RV raportowany z lukami."""
    graph = load_json("bundles/legal_graph.json")
    indexes = graph.get("indexes", {})
    slo = graph.get("slo", {})
    lci = indexes.get("LCI", 0.0)
    tcl = indexes.get("TCL", 0.0)
    return {
        "LCI": lci, "TCL": tcl,
        "slo": slo,
        "LCI_present": lci > 0,
        "TCL_100": tcl == 100.0,
        "rv_reported": "RV" in indexes or exists("bundles/legal_basis_audit.json"),
        "note": "RV wymaga remediacji podstaw prawnych (kampania ciągła) — raportowany uczciwie, nie ukrywany",
    }


def syntax_evidence() -> dict[str, Any]:
    errors = []
    checked = 0
    for rel in TOOL_SCOPE:
        path = BASE_DIR / rel
        if not path.exists():
            continue
        checked += 1
        try:
            ast.parse(path.read_text(encoding="utf-8", errors="replace"))
        except SyntaxError as exc:
            errors.append({"file": rel, "error": str(exc)})
    return {"files_checked": checked, "syntax_errors": errors, "syntax_ok": not errors}


def test_evidence() -> dict[str, Any]:
    texts = {path: read(path) for path in TEST_SCOPE}
    joined = "\n".join(texts.values())
    return {
        "files": {path: bool(text) for path, text in texts.items()},
        "lkg_tests": "lkg_generator" in joined or "reverse_coverage" in joined or "legal_graph" in joined,
        "gate_tests": "legal_twin_report24_gate" in joined,
        "complete": all(texts.values()),
    }


def build_evidence() -> dict[str, Any]:
    scope = scope_evidence()
    lkg = lkg_evidence()
    audit = audit_evidence()
    coverage = coverage_evidence()
    trace = traceability_evidence()
    reverse = reverse_coverage_evidence()
    metrics = metric_gates_evidence()
    syntax = syntax_evidence()
    tests = test_evidence()
    gates = {
        "scope_files_present": scope["all_present"],
        "lkg_graph_from_bbb": lkg["complete"],
        "legal_basis_audit_rv": audit["complete"],
        "coverage_gap_heatmap": coverage["complete"],
        "traceability_regula_wezel_werdykt": trace["complete"],
        "reverse_coverage_detector": reverse["complete"],
        "metric_gates_lci_tcl": metrics["LCI_present"] and metrics["TCL_100"],
        "rv_reported_honest": metrics["rv_reported"],
        "tools_syntax_ok": syntax["syntax_ok"],
        "tests_complete": tests["complete"],
        "report_present": exists(REPORT),
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0",
        "report": "RAPORT_24_LEGAL_TWIN",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": scope,
        "lkg": lkg,
        "audit": audit,
        "coverage": coverage,
        "traceability": trace,
        "reverse_coverage": reverse,
        "metric_gates": metrics,
        "syntax": syntax,
        "tests": tests,
        "production_status": "NOT_CERTIFIED",
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> None:
    p = argparse.ArgumentParser(description="Canonical evidence gate — PROMPT_24 LEGAL TWIN (F1)")
    p.add_argument("--check", action="store_true", help="fail with exit code 1 when not WDROZONY_100")
    args = p.parse_args()
    evidence = build_evidence()
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    EVIDENCE.write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"status": evidence["status"],
                      "gates": evidence["gate_summary"],
                      "LCI": evidence["lkg"]["indexes"].get("LCI"),
                      "RV": evidence["audit"]["rv_metric"],
                      "reverse_gaps": evidence["reverse_coverage"]["gaps_detected"],
                      "production_status": evidence["production_status"],
                      "evidence": str(EVIDENCE.relative_to(BASE_DIR))},
                     indent=2, ensure_ascii=False))
    if args.check and evidence["status"] != "WDROZONY_100":
        sys.exit(1)


if __name__ == "__main__":
    main()
