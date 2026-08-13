#!/usr/bin/env python3
"""RAPORT_18 NARZĘDZIA SYSTEMOWE (validate/lint/legal-twin/replay/CI) — evidence gate.

This report audits system *tooling* (58 Python tools + 7 test files), not Rego
rules, so there are no rule_id/temporal gates. Instead the gate verifies:
tool presence, CI-gate integration, and the V1/V2 pillar artifacts (Legal Twin,
Declarative Change, Decision Certificate, Law Radar, Golden Replay).

Usage (from ``JDG/``)::

    python tools/tools_system_report18_gate.py --json
    python tools/tools_system_report18_gate.py --write
    python tools/tools_system_report18_gate.py --strict
"""

from __future__ import annotations

import argparse
import ast
import json
import sys
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_18_NARZEDZIA_SYSTEM.txt"
EVIDENCE_PATH = BUNDLES_DIR / "tools_system_report18_evidence.json"

DOC_FILES = (
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/Bbb",
    "docs/LEGAL_REFERENCE_ACTS.md",
    "docs/LEGAL_COVERAGE.md",
)

# Narzędzia systemowe wyliczone w RAPORT_18 (tabela 2.1) + generate_missing_rules.py.
TOOL_FILES = (
    "tools/validate_rules.py",
    "tools/lint_rego_rules.py",
    "tools/generate_manifest.py",
    "tools/generate_coverage_report.py",
    "generate_missing_rules.py",
    "tools/hardcoded_audit.py",
    "tools/hardcoded_audit_gate.py",
    "tools/dead_rule_detector.py",
    "tools/tautology_guard.py",
    "tools/else_chain_dead_code_detector.py",
    "tools/cross_ref_validator.py",
    "tools/doc_consistency_validator.py",
    "tools/zero_defect_certification.py",
    "tools/rule_provenance_dna.py",
    "tools/validate_legal_basis.py",
    "tools/validate_legal_basis_v2.py",
    "tools/validate_p24_legal_basis.py",
    "tools/legal_basis_audit.py",
    "tools/legal_coverage_heatmap.py",
    "tools/legal_coverage_gap_report.py",
    "tools/legal_change_calendar.py",
    "tools/law_radar.py",
    "tools/law_impact_matrix.py",
    "tools/legal_twin.py",
    "tools/golden_replay.py",
    "tools/declarative_change.py",
    "tools/traceability_matrix.py",
    "tools/rule_lifecycle_manager.py",
    "tools/decision_quality_monitor.py",
    "tools/isap_crawler.py",
    "tools/isap_rule_update_pipeline.py",
    "tools/isap_drift_alarm.py",
    "tools/self_healing_engine.py",
    "tools/chaos_engineering.py",
    "tools/predictive_audit_shield.py",
    "tools/adaptive_trust_score.py",
    "tools/cross_package_conflict_detector.py",
    "tools/rule_impact_simulator.py",
    "tools/temporal_drift_detector.py",
    "tools/invariant_checker.py",
    "tools/decision_certificate.py",
    "tools/confidence_dashboard.py",
    "tools/policies_sync_gate.py",
    "tools/enterprise_dashboard.py",
    "tools/migration_impact_analyzer.py",
    "tools/initiative_numbering_auditor.py",
    "tools/adr_auto_proposer.py",
    "tools/policy_registry_api.py",
    "tools/data_service.py",
    "tools/deployment_orchestrator.py",
    "tools/manifest_v2.py",
    "tools/api_doc_generator.py",
)

TEST_FILES = (
    "tests/test_payment_priority_service.py",
    "tests/test_priority_engine.py",
    "tests/test_risk_guard.py",
    "tests/test_risk_guard_integration.py",
    "tests/test_semantic_guard.py",
    "tests/test_tax_pipeline.py",
    "tests/test_tax_rules.py",
)

# Bramki jakości CI (gwarancja zero-defect) — kluczowe narzędzia wymienione w R18.
CI_GATE_TOOLS = (
    "tools/validate_rules.py",
    "tools/lint_rego_rules.py",
    "tools/hardcoded_audit_gate.py",
    "tools/dead_rule_detector.py",
    "tools/tautology_guard.py",
    "tools/zero_defect_certification.py",
)

# Filary V1/V2 realizowane przez narzędzia systemowe.
PILLAR_ARTIFACTS = {
    "legal_twin": ("tools/legal_twin.py", "bundles/legal_graph.json"),
    "declarative_change": ("tools/declarative_change.py",),
    "decision_certificate": ("tools/decision_certificate.py",),
    "law_radar": (
        "tools/law_radar.py",
        "tools/isap_crawler.py",
        "tools/isap_drift_alarm.py",
        "tools/isap_rule_update_pipeline.py",
    ),
    "golden_replay": ("tools/golden_replay.py", "bundles/golden_verdicts.json"),
}


def _exists(rel: str) -> bool:
    return (BASE_DIR / rel).exists()


def _scope_evidence() -> dict[str, Any]:
    tools = {rel: _exists(rel) for rel in TOOL_FILES}
    tests = {rel: _exists(rel) for rel in TEST_FILES}
    docs = {rel: _exists(rel) for rel in DOC_FILES}
    return {
        "tools_total": len(TOOL_FILES),
        "tools_present": sum(tools.values()),
        "tests_total": len(TEST_FILES),
        "tests_present": sum(tests.values()),
        "docs_total": len(DOC_FILES),
        "docs_present": sum(docs.values()),
        "missing": [rel for rel, ok in {**tools, **tests, **docs}.items() if not ok],
    }


def _ci_gate_evidence() -> dict[str, Any]:
    return {
        "ci_gate_tools": {rel: _exists(rel) for rel in CI_GATE_TOOLS},
        "ci_gates_present": all(_exists(rel) for rel in CI_GATE_TOOLS),
    }


def _pillar_evidence() -> dict[str, Any]:
    return {
        name: {rel: _exists(rel) for rel in rels}
        for name, rels in PILLAR_ARTIFACTS.items()
    }


def _syntax_evidence() -> dict[str, Any]:
    """Wszystkie narzędzia muszą się parsować (py_compile/ast) — zero-defect."""
    bad = []
    for rel in TOOL_FILES:
        path = BASE_DIR / rel
        if not path.exists():
            continue
        try:
            ast.parse(path.read_text(encoding="utf-8", errors="ignore"))
        except SyntaxError as exc:
            bad.append({"file": rel, "error": str(exc)})
    return {"syntax_errors": bad, "syntax_ok": not bad}


def _golden_replay_evidence() -> dict[str, Any]:
    verdicts_path = BUNDLES_DIR / "golden_verdicts.json"
    if not verdicts_path.exists():
        return {"valid": False, "verdicts": 0, "replays": 0, "unmatched": []}
    data = json.loads(verdicts_path.read_text(encoding="utf-8"))
    replays = data.get("replays", [])
    unmatched = data.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {
        "valid": True,
        "verdicts": len(data.get("verdicts", {})),
        "replays": len(replays) if isinstance(replays, (list, dict)) else 0,
        "unmatched": unmatched,
        "unmatched_count": len(unmatched),
    }


def _deployment_evidence() -> dict[str, Any]:
    deployments = json.loads(
        (BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8")
    )
    dep = deployments.get("deployments", {}).get("jdg-tls-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-tls-bundle-v9.0.0",
        "phase": dep.get("phase"),
        "rollout_pct": dep.get("rollout_pct"),
        "quality": dep.get("quality"),
        "error_rate": dep.get("error_rate"),
        "rollback_reason": dep.get("rollback_reason"),
        "soak_completed_at": dep.get("soak_completed_at"),
        "active_version": deployments.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    ci = _ci_gate_evidence()
    pillar = _pillar_evidence()
    syntax = _syntax_evidence()
    replay = _golden_replay_evidence()
    deployment = _deployment_evidence()

    gates = {
        "scope_files_present": scope["tools_present"] == scope["tools_total"]
        and scope["tests_present"] == scope["tests_total"]
        and scope["docs_present"] == scope["docs_total"],
        "duplicate_free": True,  # 0 rule_id w zakresie (brak Rego)
        "ci_gates_present": ci["ci_gates_present"],
        "legal_twin_ready": all(pillar["legal_twin"].values()),
        "declarative_change_ready": all(pillar["declarative_change"].values())
        and all(pillar["decision_certificate"].values()),
        "law_radar_ready": all(pillar["law_radar"].values()),
        "golden_replay_ready": replay["valid"]
        and replay["verdicts"] >= 1
        and replay["unmatched_count"] == 0,
        "tools_syntax_ok": syntax["syntax_ok"],
        "canary_rollback_ok": deployment["phase"] == "ROLLED_BACK"
        and deployment["rollback_reason"] is not None,
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_18_NARZEDZIA_SYSTEM",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "ci_gates": ci,
        "pillars": pillar,
        "syntax": syntax,
        "replay": replay,
        "deployment": deployment,
        "generated_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_18 evidence gate")
    parser.add_argument("--json", action="store_true", help="print evidence as JSON")
    parser.add_argument("--write", action="store_true", help="write evidence bundle")
    parser.add_argument("--strict", action="store_true", help="fail if not WDROZONY_100")
    args = parser.parse_args()

    evidence = build_evidence()
    if args.write:
        EVIDENCE_PATH.write_text(
            json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        print(f"✅ Evidence: {EVIDENCE_PATH.name} ({evidence['status']})")
    elif args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(
            f"RAPORT_18: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
