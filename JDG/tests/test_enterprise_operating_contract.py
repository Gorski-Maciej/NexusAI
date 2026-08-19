"""Tests for the machine-readable GLM52 Enterprise ETAP_00 contract."""
from __future__ import annotations

import json
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(JDG_ROOT / "tools"))

import validate_enterprise_contract as validator  # noqa: E402


CONTRACT = JDG_ROOT / "bundles" / "enterprise_operating_contract.json"


def test_contract_passes_fail_closed_validation() -> None:
    assert validator.validate() == []


def test_contract_has_all_stages_in_order() -> None:
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    stages = list(data["dependency_map"])
    assert stages == [f"ETAP_{i:02d}" for i in range(29)]
    assert data["dependency_map"]["ETAP_00"] == []
    assert data["dependency_map"]["ETAP_28"] == ["ETAP_27"]


def test_contract_is_fail_closed_and_does_not_claim_production() -> None:
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    assert data["production_activation"] == "NOT_CERTIFIED"
    assert all(gate["on_fail"] == "BLOCK" for gate in data["pass_fail_gates"])
    assert data["slo_sla"]["duplicate_rule_ids_target"] == 0
    assert data["slo_sla"]["production_stub_target"] == 0


def test_stage_zero_report_is_marked_and_has_handoff_marker() -> None:
    report = JDG_ROOT / "raporty_glm52_enterprise" / "00_MASTER_OPERATING_CONTRACT.txt"
    text = report.read_text(encoding="utf-8")
    assert "Status raportu: WDROŻONY_100" in text
    assert "ETAP_00_COMPLETE — CONTEXT_RESET_REQUIRED" in text
