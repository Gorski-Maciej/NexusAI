"""ETAP 23 — Enterprise AI / Neural Mesh governance evidence contract."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "enterprise_ai_neural_etap23_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
AUDITOR = ROOT / "tools" / "enterprise_ai_neural_etap23_audit.py"
REPORT = ROOT / "raporty_glm52_enterprise" / "23_ENTERPRISE_AI_NEURAL.txt"
BUNDLE = ROOT / "bundles" / "enterprise_ai_neural_etap23_audit_state.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure_and_unique_rule_ids():
    text = read(PACKAGE)
    assert "package jdg.enterprise_ai_neural_etap23" in text
    assert text.count('"rule_id":') == 2
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")
    assert '"AUTO_POST"' not in text


def test_prediction_separation_and_quality_controls():
    text = read(PACKAGE)
    for marker in [
        "prediction_separation", "DETERMINISTIC_REGO", "ADVISORY_ONLY",
        "calibration_complete", "drift_ok", "quality_complete",
        "bias_safety_complete", "explainability_complete", "llm_safe",
        "feedback_complete", "cashflow_complete", "banking_complete",
    ]:
        assert marker in text


def test_fail_closed_evidence_temporal_and_manual_contract():
    text = read(PACKAGE)
    for marker in [
        "input_hash", "source_refs", "legal_nodes", "evaluation_date", "facts_version", "prediction_role", "ADVISORY_ONLY",
        "threshold_version", "valid_from", "valid_to", "owner_approval",
        "manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
        'decision_mode := "SUGGEST"', '"no_auto_post": true',
    ]:
        assert marker in text


def test_legal_basis_and_domain_contract():
    text = read(PACKAGE)
    for marker in [
        "RODO art. 5", "RODO art. 22", "RODO art. 25", "PIT art. 44",
        "VAT art. 103", "OrdPU art. 4", "PSD2", "ADR-006", "ADR-022",
        "legal_verdict_authority", "prediction_domains", "auto_action",
    ]:
        assert marker in text


def test_thresholds_and_orchestrator_wiring():
    thresholds = read(THRESHOLDS)
    main = read(MAIN)
    assert "enterprise_ai_neural_etap23 := {" in thresholds
    for marker in [
        "calibration_min_samples", "max_expected_calibration_error",
        "max_population_stability_index", "prediction_role",
        "legal_verdict_authority", "required_controls",
    ]:
        assert marker in thresholds
    assert "import data.jdg.enterprise_ai_neural_etap23" in main
    assert '"jdg.enterprise_ai_neural_etap23": enterprise_ai_neural_etap23.decide' in main
    assert "final_verdict_p67 = safe_merge(final_verdict_p66" in main
    assert "object.union(final_verdict_p67" in main
    assert "final_verdict = final_verdict_enforced" in main


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
    assert evidence["gate_summary"] == {"passed": 16, "total": 16}
    assert evidence["files"]["all_present"] is True
    assert evidence["package"]["duplicate_free"] is True


def test_report_and_bundle_consistent():
    assert REPORT.exists()
    assert BUNDLE.exists()
    report = read(REPORT)
    bundle = json.loads(read(BUNDLE))
    assert "WDROZONY_100" in report
    assert "ETAP_23_COMPLETE" in report
    assert bundle["status"] == "WDROZONY_100"
    assert bundle["gate_summary"] == {"passed": 16, "total": 16}
    assert bundle["gates"]["orchestrator_wiring"] is True
