"""Kampania V3, część 09 — testy kontraktowe bramki ryczalt_lifecycle_v3_gate.

Pokrycie:
- gate PASS (wiring 11 pakietów, duplikaty, thresholds, kontrakt v3_09),
- evidence bundle bundles/ryczalt_lifecycle_v3_audit_09.json,
- klucze progów business_lifecycle w thresholds_jdg.rego,
- natywny artefakt Rego tests/rego/test_native_ryczalt_v3_09.rego.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "ryczalt_lifecycle_v3_gate.py"
EVIDENCE = ROOT / "bundles" / "ryczalt_lifecycle_v3_audit_09.json"
NATIVE = ROOT / "tests" / "rego" / "test_native_ryczalt_v3_09.rego"


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
    assert len(existing) == len(report["files_audited"]) == 12
    for fa in existing:
        assert fa["package"], f"{fa['file']}: brak package"


def test_no_duplicate_rule_ids() -> None:
    report = run_gate()
    for fa in report["files_audited"]:
        if fa.get("exists"):
            assert fa["duplicates_in_file"] == [], fa["file"]
    assert report["cross_file_duplicates"] == []


def test_domain_packages_wired_in_orchestrator() -> None:
    report = run_gate()
    assert len(report["wiring"]["wired"]) == report["wiring"]["required"] == 11
    assert report["wiring"]["unwired"] == []
    main_text = (ROOT / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert '"jdg.business.v3_09": business_v3_09.decide' in main_text


def test_business_lifecycle_threshold_keys_externalized() -> None:
    report = run_gate()
    assert report["thresholds"]["missing"] == []
    th_text = (ROOT / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
    for key in ["ryczalt_limit_eur", "ryczalt_warning_pct", "ryczalt_limit_alert_pct",
                "suspension_max_months", "succession_default_months",
                "ceidg_registration_days", "karta_max_employees", "min_wage_pln"]:
        assert f'"{key}"' in th_text


def test_v3_09_contract_markers() -> None:
    report = run_gate()
    assert report["v3_09_contract"]["all_pass"]
    text = (ROOT / "rules" / "business" / "v3_09_enterprise.rego").read_text(encoding="utf-8")
    assert '"rule_id": "jdg.business.v3_09.no_match"' in text
    assert "fail_closed_decision" in text
    for rid in ["ryczalt_limit_monitor", "form_advisor_checkpoint", "suspension_checklist",
                "succession_planner", "ceidg_change_deadline", "unregistered_activity_gate",
                "lifecycle_state_machine", "karta_eligibility", "lifecycle_decision_certificate"]:
        assert f"jdg.business.v3_09.{rid}" in text


def test_evidence_bundle_written() -> None:
    run_gate()
    data = json.loads(EVIDENCE.read_text(encoding="utf-8"))
    assert data["tool"] == "ryczalt_lifecycle_v3_gate"
    assert data["gate_status"] == "PASS"
    assert data["kampania"].startswith("V3 część 09")


def test_native_rego_artifact_exists() -> None:
    text = NATIVE.read_text(encoding="utf-8")
    assert "package tests.test_native_ryczalt_v3_09" in text
    for tid in ["T01", "T02", "T03", "T04", "T05", "T06", "T07", "T08", "T09", "T10", "T11", "T12"]:
        assert f"# {tid}:" in text
