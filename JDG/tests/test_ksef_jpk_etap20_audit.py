"""ETAP 20 — KSeF/JPK/e-Deklaracje evidence contract."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "ksef_jpk_etap20_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
AUDITOR = ROOT / "tools" / "ksef_jpk_etap20_audit.py"
REPORT = ROOT / "raporty_glm52_enterprise" / "20_KSEF_JPK_DECLARATIONS.txt"
BUNDLE = ROOT / "bundles" / "ksef_jpk_etap20_audit_state.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure_and_unique_rule_ids():
    text = read(PACKAGE)
    assert "package jdg.ksef_jpk_etap20" in text
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    assert ids == [
        "jdg.ksef_jpk_etap20.no_match",
        "jdg.ksef_jpk_etap20.ksef_jpk_declaration_verdict",
    ]
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")


def test_document_state_machine_and_transition_catalog():
    text = read(PACKAGE)
    for marker in [
        "state_machine", "DRAFT", "VALIDATED", "QUEUED", "SUBMITTED", "ACCEPTED",
        "REJECTED", "CORRECTION_REQUIRED", "CANCELLED", "ARCHIVED",
        "transition_catalog", '"from"', '"to"', "transition_valid",
    ]:
        assert marker in text


def test_format_identifiers_and_transport_contract():
    text = read(PACKAGE)
    for marker in [
        "schema_registry", "required_invoice_fields", "missing_fields", "schema_valid",
        "identifier_complete", "identifier_unique", "token_present", "ksef_number_present",
        "upo_present", "upo_id_present", "upo_deadline_ok", "mf_available",
    ]:
        assert marker in text


def test_offline_retry_outbox_and_exactly_once():
    text = read(PACKAGE)
    for marker in [
        "offline_mode", "offline_grace_days", "retry_attempts", "max_retries",
        "outbox_entry_present", "outbox_key_matches", "duplicate_detected",
        "exactly_once", "idempotency_key",
    ]:
        assert marker in text


def test_jpk_gtu_deadline_and_correction_contract():
    text = read(PACKAGE)
    for marker in [
        "declaration_types", "JPK_V7M", "JPK_V7K", "JPK_KR", "JPK_ST", "gtu_codes",
        "invalid_gtu_codes", "deadline_ok", "correction_requested", "correction_complete",
    ]:
        assert marker in text


def test_reconciliation_and_eoffice_contract():
    text = read(PACKAGE)
    for marker in [
        "ledger_total", "jpk_total", "ksef_total", "ledger_jpk_delta", "jpk_ksef_delta",
        "reconciliation_ok", "wis_complete", "edelivery_complete", "signature_complete",
        "sandbox_complete", "sandbox_required",
    ]:
        assert marker in text


def test_fail_closed_and_no_send_claim():
    text = read(PACKAGE)
    for marker in [
        "context_complete", "source_complete", "document_evidence_complete",
        "manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
        'decision_mode := "SUGGEST"', '"no_auto_post": true', "NOT_SENT_BY_RULE",
        '"sent_by_rule": false', '"submitted_by_rule": false',
    ]:
        assert marker in text
    assert '"AUTO_POST"' not in text


def test_thresholds_and_orchestrator_wiring():
    thresholds = read(THRESHOLDS)
    main = read(MAIN)
    assert "ksef_jpk_etap20 := {" in thresholds
    for marker in ["offline_grace_days", "max_retries", "upo_deadline_days", "schema_registry", "gtu_codes"]:
        assert marker in thresholds
    assert "import data.jdg.ksef_jpk_etap20" in main
    assert '"jdg.ksef_jpk_etap20": ksef_jpk_etap20.decide' in main
    assert "final_verdict_p64 = safe_merge(final_verdict_p63" in main
    assert "object.union(final_verdict_p64" in main
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
    assert evidence["gate_summary"]["total"] == 19
    assert evidence["files"]["all_present"] is True
    assert evidence["package"]["duplicate_free"] is True


def test_report_and_bundle_are_consistent():
    assert REPORT.exists()
    assert BUNDLE.exists()
    report = read(REPORT)
    bundle = json.loads(read(BUNDLE))
    assert "WDROZONY_100" in report
    assert "ETAP_20_COMPLETE" in report
    assert bundle["status"] == "WDROZONY_100"
    assert bundle["gate_summary"]["passed"] == 19
    assert bundle["gates"]["orchestrator_wiring"] is True
