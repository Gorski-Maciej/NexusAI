"""ETAP 18 — business lifecycle state-machine audit contract."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "business_lifecycle_etap18_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"


def test_package_structure_and_rule_ids():
    text = PACKAGE.read_text(encoding="utf-8")
    assert "package jdg.business_lifecycle_etap18" in text
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    assert ids == ["jdg.business_lifecycle_etap18.no_match", "jdg.business_lifecycle_etap18.state_machine_verdict"]


def test_state_machine_scope_and_transitions():
    text = PACKAGE.read_text(encoding="utf-8")
    for marker in ["state_machine", "transition_catalog", "PRE_START", "ACTIVE_STARTUP", "ACTIVE_GROWTH", "SUSPENDED", "SUCCESSION", "TRANSITION", "CLOSING", "CLOSED"]:
        assert marker in text
    assert text.count('"from":') >= 10
    assert "transition_exists" in text and "next_state" in text


def test_forms_deadlines_and_rollback():
    text = PACKAGE.read_text(encoding="utf-8")
    for marker in ["required_forms", "deadline_calendar", "deadline_days", "rollback_event", "MANUAL_REOPEN_ONLY"]:
        assert marker in text


def test_temporal_legal_and_rate_contract():
    text = PACKAGE.read_text(encoding="utf-8")
    for marker in ["effective_from", "effective_to", "facts_version", "threshold_version", "legal_traceability", "rate_registry", "pkwiu_verified"]:
        assert marker in text
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in text


def test_fail_closed_manual_gate():
    text = PACKAGE.read_text(encoding="utf-8")
    for marker in ["owner_approval", "manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "UNKNOWN_STATE", "INVALID_TRANSITION"]:
        assert marker in text
    assert 'decision_mode := "SUGGEST"' in text
    assert '"no_auto_post": true' in text
    assert '"AUTO_POST"' not in text


def test_orchestrator_wiring():
    text = MAIN.read_text(encoding="utf-8")
    assert "import data.jdg.business_lifecycle_etap18" in text
    assert '"jdg.business_lifecycle_etap18": business_lifecycle_etap18.decide' in text
    assert "final_verdict_p62 = safe_merge(final_verdict_p61" in text
    assert "object.union(final_verdict_p62" in text
    assert "final_verdict = final_verdict_enforced" in text


def test_auditor_report_and_native_artifacts():
    assert (ROOT / "tools" / "business_lifecycle_etap18_audit.py").exists()
    assert (ROOT / "tests" / "rego" / "test_native_business_lifecycle_etap18.rego").exists()
    report = ROOT / "raporty_glm52_enterprise" / "18_RYCZALT_BUSINESS_LIFECYCLE.txt"
    bundle = ROOT / "bundles" / "business_lifecycle_etap18_audit_state.json"
    assert report.exists() and bundle.exists()
    assert "ETAP_18_COMPLETE" in report.read_text(encoding="utf-8")
