"""ETAP 21 — RODO/AML/BDO/HR evidence contract."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "rodo_aml_bdo_hr_etap21_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
AUDITOR = ROOT / "tools" / "rodo_aml_bdo_hr_etap21_audit.py"
REPORT = ROOT / "raporty_glm52_enterprise" / "21_RODO_AML_BDO_HR.txt"
BUNDLE = ROOT / "bundles" / "rodo_aml_bdo_hr_etap21_audit_state.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure_and_unique_rule_ids():
    text = read(PACKAGE)
    assert "package jdg.rodo_aml_bdo_hr_etap21" in text
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    assert ids == [
        "jdg.rodo_aml_bdo_hr_etap21.no_match",
        "jdg.rodo_aml_bdo_hr_etap21.compliance_hr_verdict",
    ]
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")


def test_rodo_privacy_by_design_contract():
    text = read(PACKAGE)
    for marker in [
        "privacy_by_design", "rodo_basis_complete", "consent_complete", "retention_complete",
        "rights_workflow_complete", "breach_complete", "data_minimized", "pii_redacted_in_output",
        "breach_deadline_hours", "erasure_deadline_days",
    ]:
        assert marker in text


def test_aml_ubo_cbdd_str_contract():
    text = read(PACKAGE)
    for marker in [
        "ubo_complete", "ubo_verified", "ubo_minimum_pct", "cdd_complete", "cdd_level",
        "sanctions_screening_complete", "str_required", "str_complete", "transaction_threshold_eur",
    ]:
        assert marker in text


def test_bdo_and_hr_contract():
    text = read(PACKAGE)
    for marker in [
        "bdo_registration_complete", "kpo_complete", "ewc_complete", "waste_transport_complete",
        "waste_record_complete", "bdo_kpo_deadline_days", "employment_complete", "payroll_complete",
        "ppk_complete", "pfron_required", "pfron_complete", "pfron_employee_threshold",
    ]:
        assert marker in text


def test_fail_closed_evidence_manual_guidance_and_stub_contract():
    text = read(PACKAGE)
    for marker in [
        "evidence_chain", "context_complete", "source_complete", "legal_traceability",
        "manual_review_required", "compliance_guidance_only", "tax_decision", "stub_detector",
        "BLOCK_AND_ALERT", "TRIAGE_QUEUE", 'decision_mode := "SUGGEST"', '"no_auto_post": true',
    ]:
        assert marker in text
    assert '"AUTO_POST"' not in text


def test_legal_basis_and_temporal_contract():
    text = read(PACKAGE)
    for marker in [
        "RODO art. 5", "RODO art. 17", "u.AML art. 74-80", "UoO art. 66-70",
        "KP art. 85", "ustawa o PPK", "ustawa o PFRON", "valid_from", "valid_to",
        "facts_version", "threshold_version",
    ]:
        assert marker in text


def test_thresholds_and_orchestrator_wiring():
    thresholds = read(THRESHOLDS)
    main = read(MAIN)
    assert "rodo_aml_bdo_hr_etap21 := {" in thresholds
    for marker in ["rodo_breach_deadline_hours", "aml_transaction_threshold_eur", "ubo_minimum_pct", "bdo_kpo_deadline_days", "pfron_employee_threshold"]:
        assert marker in thresholds
    assert "import data.jdg.rodo_aml_bdo_hr_etap21" in main
    assert '"jdg.rodo_aml_bdo_hr_etap21": rodo_aml_bdo_hr_etap21.decide' in main
    assert "final_verdict_p65 = safe_merge(final_verdict_p64" in main
    assert "object.union(final_verdict_p65" in main
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
    assert evidence["gate_summary"]["passed"] == evidence["gate_summary"]["total"]
    assert evidence["gate_summary"]["total"] == 16
    assert evidence["files"]["all_present"] is True
    assert evidence["package"]["duplicate_free"] is True


def test_report_and_bundle_are_consistent():
    assert REPORT.exists()
    assert BUNDLE.exists()
    report = read(REPORT)
    bundle = json.loads(read(BUNDLE))
    assert "WDROZONY_100" in report
    assert "ETAP_21_COMPLETE" in report
    assert bundle["status"] == "WDROZONY_100"
    assert bundle["gate_summary"]["passed"] == 16
    assert bundle["gates"]["orchestrator_wiring"] is True
