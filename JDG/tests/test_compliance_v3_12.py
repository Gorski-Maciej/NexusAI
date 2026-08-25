"""Kampania V3, część 12 — testy kontraktowe bramki compliance_v3_gate.

Pokrycie:
- gate PASS (wiring 16 pakietów, duplikaty, thresholds, kontrakt v3_12),
- evidence bundle bundles/compliance_v3_audit_12.json,
- klucze progów rodo_aml_bdo_hr_etap21 w thresholds_jdg.rego (+ wersjonowanie),
- natywny artefakt Rego tests/rego/test_native_compliance_v3_12.rego.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "compliance_v3_gate.py"
EVIDENCE = ROOT / "bundles" / "compliance_v3_audit_12.json"
NATIVE = ROOT / "tests" / "rego" / "test_native_compliance_v3_12.rego"


def run_gate() -> dict:
    result = subprocess.run(
        [sys.executable, str(GATE), "--json"],
        capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0, f"gate FAIL:\n{result.stdout}\n{result.stderr}"
    return json.loads(result.stdout)


def test_gate_pass() -> None:
    report = run_gate()
    assert report["gate_status"] == "PASS"
    assert report["errors"] == []


def test_all_domain_files_exist_with_packages() -> None:
    report = run_gate()
    existing = [f for f in report["files_audited"] if f.get("exists")]
    assert len(existing) == len(report["files_audited"]) == 16
    for fa in existing:
        assert fa["package"], f"{fa['file']}: brak package"


def test_no_duplicate_rule_ids() -> None:
    report = run_gate()
    for fa in report["files_audited"]:
        if fa.get("exists"):
            assert fa["duplicates_in_file"] == [], fa["file"]
    assert report["cross_file_duplicates"] == []


def test_orphan_packages_are_now_wired() -> None:
    report = run_gate()
    assert len(report["wiring"]["wired"]) == report["wiring"]["required"] == 16
    assert report["wiring"]["unwired"] == []
    main_text = (ROOT / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    for pkg in ["jdg.micro.aml_cbdd", "jdg.micro.aml_ryzyko", "jdg.micro.aml_str_gif",
                "jdg.micro.aml_transakcje", "jdg.compliance.v3_12"]:
        assert f'"{pkg}"' in main_text


def test_rodo_aml_bdo_threshold_keys() -> None:
    report = run_gate()
    assert report["thresholds"]["missing"] == []
    th_text = (ROOT / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
    for key in ["rodo_breach_deadline_hours", "rodo_erasure_deadline_days",
                "aml_transaction_threshold_eur", "ubo_minimum_pct",
                "bdo_kpo_deadline_days", "threshold_version"]:
        assert f'"{key}"' in th_text
    assert '"threshold_version": "rodo-aml-bdo-2026.08"' in th_text


def test_v3_12_contract_markers() -> None:
    report = run_gate()
    assert report["v3_12_contract"]["all_pass"]
    text = (ROOT / "rules" / "compliance" / "v3_12_enterprise.rego").read_text(encoding="utf-8")
    assert '"rule_id": "jdg.compliance.v3_12.no_match"' in text
    assert "fail_closed_decision" in text
    for rid in ["rodo_breach_guard", "erasure_engine_guard", "aml_transaction_monitor",
                "aml_cbdd_guard", "bdo_kpo_guard", "dpia_guard", "domain_certificate"]:
        assert f"jdg.compliance.v3_12.{rid}" in text


def test_evidence_bundle_written() -> None:
    run_gate()
    data = json.loads(EVIDENCE.read_text(encoding="utf-8"))
    assert data["tool"] == "compliance_v3_gate"
    assert data["gate_status"] == "PASS"
    assert data["kampania"].startswith("V3 część 12")


def test_native_rego_artifact_exists() -> None:
    text = NATIVE.read_text(encoding="utf-8")
    assert "package tests.test_native_compliance_v3_12" in text
    for tid in ["T01", "T02", "T03", "T04", "T05", "T06", "T07", "T08", "T09", "T10", "T11", "T12"]:
        assert f"# {tid}:" in text
