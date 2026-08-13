#!/usr/bin/env python3
"""Tests for the RAPORT_20 evidence gate (TESTY PYTEST)."""

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import pytest_report20_gate as gate


def test_gate_reaches_wdrozony_100():
    ev = gate.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"expected WDROZONY_100, got {ev['status']}"
    assert ev["gate_summary"]["passed"] == ev["gate_summary"]["total"] == 7


def test_scope_all_artifacts_present():
    scope = gate.build_evidence()["scope"]
    assert scope["docs_present"] == scope["docs_total"] == 5
    assert scope["unit_tests_present"] == scope["unit_tests_total"] == 36
    assert scope["auto_block_present"] == scope["auto_block_total"] == 54
    assert scope["missing"] == []


def test_test_syntax_ok():
    syntax = gate.build_evidence()["syntax"]
    assert syntax["syntax_ok"] is True, f"syntax errors: {syntax['syntax_errors']}"
    assert syntax["files_checked"] >= 90


def test_risk_guard_imports_resolve():
    imports = gate.build_evidence()["imports"]
    assert imports["imports_ok"] is True, f"broken imports: {imports['broken_imports']}"
    assert imports["broken_imports"] == []


def test_risk_guard_tests_pass():
    pytest = gate.build_evidence()["pytest"]
    assert pytest["passed"] is True, f"pytest failed: {pytest['stdout_tail']}"
    assert pytest["exit_code"] == 0


def test_golden_replay_ready():
    replay = gate.build_evidence()["replay"]
    assert replay["valid"] is True
    assert replay["verdicts"] >= 1
    assert replay["unmatched_count"] == 0


def test_canary_rollback():
    dep = gate.build_evidence()["deployment"]
    assert dep["phase"] == "ROLLED_BACK"
    assert dep["rollback_reason"] is not None
    assert dep["rollback_sla_pass"] is True


def test_evidence_bundle_written_and_consistent():
    ev_path = BASE_DIR / "bundles" / "pytest_report20_evidence.json"
    assert ev_path.exists(), "evidence bundle not written"
    data = json.loads(ev_path.read_text(encoding="utf-8"))
    assert data["status"] == "WDROZONY_100"
    assert data["gate_summary"]["passed"] == 7
