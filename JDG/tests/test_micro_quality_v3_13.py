"""Kampania V3, część 13 — whole micro quality and boundary contract."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "micro_quality_v3_13_gate.py"
EVIDENCE = ROOT / "bundles" / "micro_quality_v3_audit_13.json"
RULE = ROOT / "rules" / "micro" / "quality_v3_13.rego"
MAIN = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"


def run_gate(*args: str) -> dict:
    result = subprocess.run(
        [sys.executable, str(GATE), "--json", *args],
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0, f"gate FAIL:\n{result.stdout}\n{result.stderr}"
    return json.loads(result.stdout)


def test_whole_micro_tree_is_audited() -> None:
    report = run_gate()
    assert report["gate_status"] == "PASS"
    assert report["totals"]["files"] >= 90
    assert report["totals"]["rules"] > 1000
    assert report["totals"]["unique_rule_ids"] == report["totals"]["rules"]


def test_syntax_and_duplicate_contract() -> None:
    report = run_gate()
    assert report["syntax_errors"] == []
    assert report["duplicate_rule_ids"] == {}
    assert report["totals"]["stub_findings"] >= 0
    assert report["totals"]["empty_optional_fields_raw"] >= 0


def test_evidence_bundle_and_normalization_contract() -> None:
    report = run_gate()
    evidence = json.loads(EVIDENCE.read_text(encoding="utf-8"))
    assert evidence["schema_version"] == "1.0.0"
    assert evidence["gate_status"] == "PASS"
    assert evidence["normalized_contract"]["mode"] == "DECOUPLED"
    assert evidence["normalized_contract"]["raw_empty_field_count"] == report["totals"]["empty_optional_fields_raw"]
    assert "empty_field_boundary_normalizer" in evidence["improvements"]


def test_rego_contract_is_wired_and_fail_closed() -> None:
    text = RULE.read_text(encoding="utf-8")
    main = MAIN.read_text(encoding="utf-8")
    thresholds = THRESHOLDS.read_text(encoding="utf-8")
    assert "package jdg.micro.quality_v3_13" in text
    assert "fail_closed_decision" in text
    assert "micro_macro_binding_decision" in text
    assert "normalized_boundary_decision" in text
    assert '"no_auto_post": true' in text
    assert "data.jdg.micro.quality_v3_13" in main
    assert "micro_quality_v3_13.decide" in main
    assert "micro_quality_v3_13 :=" in thresholds


def test_python_boundary_normalizer() -> None:
    sys.path.insert(0, str(ROOT))
    from tools.micro_quality_v3_13_gate import normalize_verdict

    normalized = normalize_verdict({"rule_id": "x", "vat_rate": "", "_routing": ""})
    assert normalized["vat_rate"] is None
    assert normalized["_routing"] is None
    assert normalized["micro_boundary"] == "NORMALIZED_V3_13"
    assert normalized["micro_decision_mode"] == "DECOUPLED"
    assert normalized["no_auto_post"] is True
