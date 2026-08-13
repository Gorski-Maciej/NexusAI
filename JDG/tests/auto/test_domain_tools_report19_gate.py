#!/usr/bin/env python3
"""Tests for the RAPORT_19 evidence gate (NARZĘDZIA DOMENOWE)."""

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import domain_tools_report19_gate as gate


def test_gate_reaches_wdrozony_100():
    ev = gate.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"expected WDROZONY_100, got {ev['status']}"
    assert ev["gate_summary"]["passed"] == ev["gate_summary"]["total"] == 9


def test_scope_all_artifacts_present():
    scope = gate.build_evidence()["scope"]
    assert scope["docs_present"] == scope["docs_total"] == 5
    assert scope["rego_tests_present"] == scope["rego_tests_total"] == 5
    assert scope["pytest_present"] == scope["pytest_total"] == 6
    assert scope["tools_present"] == scope["tools_total"] == 82
    assert scope["missing"] == []


def test_category_coverage():
    cats = gate.build_evidence()["categories"]
    for name in ("generators", "zus_kks_toolkit", "domain_toolkits", "auditors"):
        assert cats[name]["present"] is True, f"{name} category incomplete"


def test_tools_syntax_ok():
    syntax = gate.build_evidence()["syntax"]
    assert syntax["syntax_ok"] is True, f"syntax errors: {syntax['syntax_errors']}"


def test_golden_replay_ready():
    replay = gate.build_evidence()["replay"]
    assert replay["valid"] is True
    assert replay["verdicts"] >= 1
    assert replay["unmatched_count"] == 0


def test_canary_rollback():
    dep = gate.build_evidence()["deployment"]
    assert dep["phase"] == "ROLLED_BACK"
    assert dep["rollback_reason"] is not None


def test_evidence_bundle_written_and_consistent():
    ev_path = BASE_DIR / "bundles" / "domain_tools_report19_evidence.json"
    assert ev_path.exists(), "evidence bundle not written"
    data = json.loads(ev_path.read_text(encoding="utf-8"))
    assert data["status"] == "WDROZONY_100"
    assert data["gate_summary"]["passed"] == 9
