"""ETAP 17 — Cross-border evidence-first audit contract."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "rules" / "crossborder_etap17_v1.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"


def test_package_exists_and_is_namespaced():
    text = PACKAGE.read_text(encoding="utf-8")
    assert "package jdg.crossborder_etap17" in text
    assert '"rule_id": "jdg.crossborder_etap17.no_match"' in text
    assert '"rule_id": "jdg.crossborder_etap17.evidence_first_verdict"' in text


def test_evidence_first_contract():
    text = PACKAGE.read_text(encoding="utf-8")
    for marker in ["evidence_pack", "fact", "document", "calculation", "test", "confidence", "manual_review"]:
        assert marker in text


def test_fail_closed_temporal_and_source_contract():
    text = PACKAGE.read_text(encoding="utf-8")
    for marker in ["evaluation_date", "threshold_version", "legal_basis_version", "facts_version", "source_refs", "BLOCK_AND_ALERT"]:
        assert marker in text
    assert 'decision_mode := "SUGGEST"' in text
    assert '"no_auto_post": true' in text
    assert '"AUTO_POST"' not in text


def test_scope_and_conflict_shield():
    text = PACKAGE.read_text(encoding="utf-8")
    for marker in [
        "residency", "direction", "place_of_supply", "wdt_wnt", "tp_cfc",
        "mdr_dac", "cbam_vida_dac8", "fx", "DIRECTION_DESTINATION_CONFLICT",
        "DIRECTION_ORIGIN_CONFLICT", "VAT_PCC_CONFLICT", "FX_EVIDENCE_MISSING",
        "manual_review_required",
    ]:
        assert marker in text


def test_temporal_thresholds_are_externalized():
    text = PACKAGE.read_text(encoding="utf-8")
    assert 'object.get(object.get(data, "jdg", {}), "thresholds", {})' in text
    assert "mdr_risk_high_threshold" in text
    thresholds = (ROOT / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert '"threshold_version": "crossborder-2026.08"' in thresholds
    assert '"legal_basis_version": "isap-lkg-2026.08"' in thresholds


def test_orchestrator_wiring_and_post_merge():
    text = MAIN.read_text(encoding="utf-8")
    assert "import data.jdg.crossborder_etap17" in text
    assert '"jdg.crossborder_etap17": crossborder_etap17.decide' in text
    assert "final_verdict_p61 = safe_merge(final_verdict_p60" in text
    assert "object.union(final_verdict_p61" in text
    assert "final_verdict = final_verdict_enforced" in text


def test_native_test_and_report_artifacts_exist():
    native = ROOT / "tests" / "rego" / "test_native_crossborder_etap17.rego"
    report = ROOT / "raporty_glm52_enterprise" / "17_CROSSBORDER_MDR.txt"
    bundle = ROOT / "bundles" / "crossborder_etap17_audit_state.json"
    assert native.exists()
    assert report.exists()
    assert bundle.exists()
    assert "ETAP_17_COMPLETE" in report.read_text(encoding="utf-8")


def test_rule_ids_are_unique():
    text = PACKAGE.read_text(encoding="utf-8")
    ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    assert len(ids) == len(set(ids))
