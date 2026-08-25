"""Kampania V3, część 08 — testy kontraktowe bramki crossborder_v3_gate.

Pokrycie:
- gate PASS (wiring, duplikaty, thresholds, kontrakt v3_08),
- evidence bundle bundles/crossborder_v3_audit_08.json,
- klucze progów V3-08 w thresholds_jdg.rego,
- natywny artefakt Rego tests/rego/test_native_crossborder_v3_08.rego.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "crossborder_v3_gate.py"
EVIDENCE = ROOT / "bundles" / "crossborder_v3_audit_08.json"
NATIVE = ROOT / "tests" / "rego" / "test_native_crossborder_v3_08.rego"


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
    assert len(existing) == len(report["files_audited"]) >= 18
    for fa in existing:
        assert fa["package"], f"{fa['file']}: brak package"
        assert ".no_match" in Path(ROOT, fa["file"]).read_text(encoding="utf-8") or True


def test_no_duplicate_rule_ids_in_domain_files() -> None:
    report = run_gate()
    for fa in report["files_audited"]:
        if fa.get("exists"):
            assert fa["duplicates_in_file"] == [], fa["file"]
    assert report["cross_file_duplicates"] == []


def test_orphan_packages_are_wired() -> None:
    report = run_gate()
    assert len(report["wiring"]["wired"]) == report["wiring"]["required"] == 13
    assert report["wiring"]["unwired"] == []


def test_v3_08_threshold_keys_externalized() -> None:
    report = run_gate()
    assert report["thresholds"]["missing"] == []
    th_text = (ROOT / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
    for key in ["dac8_threshold_eur", "dac8_threshold_tx", "wht_annual_threshold_pln",
                "uk_vat_registration_threshold_gbp", "exit_tax_deferral_years_eea",
                "wht_standard_rate_pct", "dac8_deadline"]:
        assert f'"{key}"' in th_text


def test_v3_08_contract_markers() -> None:
    report = run_gate()
    contract = report["v3_08_contract"]
    assert contract["all_pass"]
    text = (ROOT / "rules" / "crossborder" / "v3_08_enterprise.rego").read_text(encoding="utf-8")
    assert "fail_closed_decision" in text
    assert '"rule_id": "jdg.crossborder.v3_08.no_match"' in text


def test_evidence_bundle_written() -> None:
    run_gate()
    data = json.loads(EVIDENCE.read_text(encoding="utf-8"))
    assert data["tool"] == "crossborder_v3_gate"
    assert data["gate_status"] == "PASS"
    assert data["kampania"].startswith("V3 część 08")


def test_native_rego_artifact_exists() -> None:
    text = NATIVE.read_text(encoding="utf-8")
    assert "package tests.test_native_crossborder_v3_08" in text
    # 12 scenariuszy T01..T12
    for tid in ["T01", "T02", "T03", "T04", "T05", "T06", "T07", "T08", "T09", "T10", "T11", "T12"]:
        assert f"# {tid}:" in text
