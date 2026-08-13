#!/usr/bin/env python3
"""Tests for the RAPORT_18 evidence gate (NARZĘDZIA SYSTEMOWE)."""

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import tools_system_report18_gate as gate


def test_gate_reaches_wdrozony_100():
    ev = gate.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"expected WDROZONY_100, got {ev['status']}"
    assert ev["gate_summary"]["passed"] == ev["gate_summary"]["total"] == 9


def test_scope_all_tools_and_tests_present():
    scope = gate.build_evidence()["scope"]
    assert scope["tools_present"] == scope["tools_total"] == 52
    assert scope["tests_present"] == scope["tests_total"] == 7
    assert scope["docs_present"] == scope["docs_total"] == 5
    assert scope["missing"] == []


def test_ci_gate_tools_present():
    ci = gate.build_evidence()["ci_gates"]
    assert ci["ci_gates_present"] is True
    for rel, ok in ci["ci_gate_tools"].items():
        assert ok is True, f"missing CI gate tool: {rel}"


def test_v1_v2_pillars_present():
    pillars = gate.build_evidence()["pillars"]
    for name in ("legal_twin", "declarative_change", "decision_certificate",
                 "law_radar", "golden_replay"):
        for rel, ok in pillars[name].items():
            assert ok is True, f"missing {name} artifact: {rel}"


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
    ev_path = BASE_DIR / "bundles" / "tools_system_report18_evidence.json"
    assert ev_path.exists(), "evidence bundle not written"
    data = json.loads(ev_path.read_text(encoding="utf-8"))
    assert data["status"] == "WDROZONY_100"
    assert data["gate_summary"]["passed"] == 9
