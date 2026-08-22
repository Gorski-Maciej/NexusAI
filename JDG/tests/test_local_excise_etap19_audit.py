"""ETAP 19 — PCC/local taxes/excise evidence contract."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "local_excise_etap19_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_package_structure_and_unique_rule_ids():
    text = read(PACKAGE)
    assert "package jdg.local_excise_etap19" in text
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    assert ids == [
        "jdg.local_excise_etap19.no_match",
        "jdg.local_excise_etap19.pcc_local_excise_verdict",
    ]
    assert text.count("{") == text.count("}")
    assert text.count("(") == text.count(")")


def test_pcc_contract():
    text = read(PACKAGE)
    for marker in [
        "pcc_subject_verified", "pcc_vat_excluded", "pcc3_required",
        "PCC-3/PCC-3A", "pcc3_deadline_days", "pcc_due",
        "pcc_exemption_limit", "family_loan_limit",
    ]:
        assert marker in text


def test_territorial_temporal_local_registry_contract():
    text = read(PACKAGE)
    for marker in [
        "local_rate_registry", "gmina", "territory_code", "resolution_id",
        "resolution_date", "valid_from", "valid_to", "source_ref",
        "local_registry_match", "local_gmina_mismatch", "scope_match",
        "PLN_PER_M2", "DN-1", "DT-1",
    ]:
        assert marker in text


def test_excise_contract():
    text = read(PACKAGE)
    for marker in [
        "classification_verified", "excise_rates", "e_dd_required", "e_dd_id",
        "warehouse_required", "warehouse_id", "stamps_required",
        "stamps_document_id", "exemption_claimed", "exemption_basis",
        "EXCISE_CLASSIFICATION_UNVERIFIED",
    ]:
        assert marker in text


def test_fail_closed_and_suggest_only():
    text = read(PACKAGE)
    for marker in [
        "context_complete", "source_complete", "document_complete",
        "manual_review_required", "BLOCK_AND_ALERT", "TRIAGE_QUEUE",
        "OWNER_APPROVAL_MISSING", "legal_traceability", "source_refs",
        'decision_mode := "SUGGEST"', '"no_auto_post": true',
    ]:
        assert marker in text
    assert '"AUTO_POST"' not in text


def test_thresholds_are_externalized():
    text = read(THRESHOLDS)
    for marker in [
        "local_excise_etap19 := {", '"registry_version"', '"pcc_rates"',
        '"pcc3_deadline_days"', '"dn1_deadline_days"',
        '"transport_threshold_t"', '"excise_rates"',
    ]:
        assert marker in text


def test_orchestrator_wiring_and_post_merge():
    text = read(MAIN)
    assert "import data.jdg.local_excise_etap19" in text
    assert '"jdg.local_excise_etap19": local_excise_etap19.decide' in text
    assert "final_verdict_p63 = safe_merge(final_verdict_p62" in text
    assert "object.union(final_verdict_p63" in text
    assert "final_verdict = final_verdict_enforced" in text


def test_auditor_native_report_and_bundle_exist():
    assert (ROOT / "tools" / "local_excise_etap19_audit.py").exists()
    assert (ROOT / "tests" / "rego" / "test_native_local_excise_etap19.rego").exists()
    report = ROOT / "raporty_glm52_enterprise" / "19_PCC_LOCAL_EXCISE.txt"
    bundle = ROOT / "bundles" / "local_excise_etap19_audit_state.json"
    assert report.exists() and bundle.exists()
    assert "ETAP_19_COMPLETE" in report.read_text(encoding="utf-8")
