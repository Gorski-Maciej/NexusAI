"""ETAP 22 — Hyper Enterprise Contexts evidence contract."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "hyper_enterprise_contexts_etap22_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
AUDITOR = ROOT / "tools" / "hyper_enterprise_contexts_etap22_audit.py"
REPORT = ROOT / "raporty_glm52_enterprise" / "22_HYPER_ENTERPRISE_CONTEXTS.txt"
BUNDLE = ROOT / "bundles" / "hyper_enterprise_contexts_etap22_audit_state.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure_and_unique_rule_ids():
    text = read(PACKAGE)
    assert "package jdg.hyper_enterprise_contexts_etap22" in text
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    assert ids == [
        "jdg.hyper_enterprise_contexts_etap22.no_match",
        "jdg.hyper_enterprise_contexts_etap22.hyper_meta_verdict",
    ]
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")


def test_context_input_evidence_result_test_recipient_contract():
    text = read(PACKAGE)
    for marker in [
        "context_catalog", "context_registry_complete", "output_contract_complete",
        "input_hash", "evidence_ref", "result", "test_ref", "recipient",
        "source_refs", "legal_nodes", "owner_approval",
    ]:
        assert marker in text


def test_deadline_limits_and_special_contexts():
    text = read(PACKAGE)
    for marker in [
        "deadline_engine", "deadline_id", "due_date", "limit_items", "limits_registry",
        "mdr_complete", "sanctions_complete", "fx_complete", "wis_complete",
        "edelivery_complete", "territory_required", "territorial_validation",
    ]:
        assert marker in text


def test_dependency_graph_conflicts_and_priorities():
    text = read(PACKAGE)
    for marker in [
        "dependency_graph", "graph_version", "graph_nodes", "graph_edges", "conflict_pairs",
        "conflict_detector", "conflict_gate_ok", "priority_validation", "invalid_priorities",
    ]:
        assert marker in text


def test_fail_closed_safe_routing():
    text = read(PACKAGE)
    for marker in [
        "meta_validation", "stub_detected", "manual_review_required", "BLOCK_AND_ALERT",
        "TRIAGE_QUEUE", 'decision_mode := "SUGGEST"', '"no_auto_post": true',
        "compliance_guidance_only", "auto_action",
    ]:
        assert marker in text
    assert '"AUTO_POST"' not in text


def test_legal_temporal_and_threshold_contract():
    text = read(PACKAGE)
    thresholds = read(THRESHOLDS)
    for marker in ["PIT art. 30ca", "30h", "45", "OrdPU art. 12", "126", "MDR", "eIDAS", "valid_from", "valid_to", "facts_version", "threshold_version"]:
        assert marker in text
    assert "hyper_enterprise_contexts_etap22 := {" in thresholds
    for marker in ["context_catalog", "required_contract_fields", "dependency_graph_required", "manual_review_required"]:
        assert marker in thresholds


def test_orchestrator_wiring():
    text = read(MAIN)
    assert "import data.jdg.hyper_enterprise_contexts_etap22" in text
    assert '"jdg.hyper_enterprise_contexts_etap22": hyper_enterprise_contexts_etap22.decide' in text
    assert "final_verdict_p66 = safe_merge(final_verdict_p65" in text
    assert "object.union(final_verdict_p66" in text
    assert "final_verdict = final_verdict_enforced" in text


def test_auditor_builds_complete_evidence():
    proc = subprocess.run(
        [sys.executable, str(AUDITOR), "build", "--json"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
        timeout=30,
    )
    assert proc.returncode == 0, proc.stderr
    evidence = json.loads(proc.stdout)
    assert evidence["status"] == "WDROZONY_100"
    assert evidence["gate_summary"]["passed"] == evidence["gate_summary"]["total"]
    assert evidence["gate_summary"]["total"] == 17
    assert evidence["files"]["all_present"] is True
    assert evidence["package"]["duplicate_free"] is True


def test_report_and_bundle_consistent():
    assert REPORT.exists()
    assert BUNDLE.exists()
    report = read(REPORT)
    bundle = json.loads(read(BUNDLE))
    assert "WDROZONY_100" in report
    assert "ETAP_22_COMPLETE" in report
    assert bundle["status"] == "WDROZONY_100"
    assert bundle["gate_summary"]["passed"] == 17
    assert bundle["gates"]["orchestrator_wiring"] is True
