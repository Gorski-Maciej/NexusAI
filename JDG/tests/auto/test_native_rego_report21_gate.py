#!/usr/bin/env python3
"""Tests for the RAPORT_21 evidence gate (TESTY NATYWNE REGO)."""

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import native_rego_report21_gate as gate


def test_gate_reaches_wdrozony_100():
    ev = gate.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"expected WDROZONY_100, got {ev['status']}"
    assert ev["gate_summary"]["passed"] == ev["gate_summary"]["total"] == 6


def test_scope_files_present():
    scope = gate.build_evidence()["scope"]
    assert scope["docs_present"] == scope["docs_total"] == 8
    assert scope["rego_test_files"] > 0
    assert scope["native_count"] > 0
    assert scope["missing_docs"] == []


def test_test_structure_ok():
    structural = gate.build_evidence()["structural"]
    assert structural["structural_ok"] is True, f"problems: {structural['problems']}"
    assert structural["problems"] == []


def test_coverage_tracked():
    cov = gate.build_evidence()["coverage"]
    assert cov["production_packages"] > 0
    assert cov["coverage_pct"] > 0
    assert cov["desert_count"] >= 0
    assert len(cov["deserts"]) == cov["desert_count"]


def test_duplicate_free():
    dup = gate.build_evidence()["duplicate"]
    assert dup["duplicate_free"] is True, f"collisions: {dup['collisions']}"
    assert dup["collisions"] == {}


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
    ev_path = BASE_DIR / "bundles" / "native_rego_report21_evidence.json"
    assert ev_path.exists(), "evidence bundle not written"
    data = json.loads(ev_path.read_text(encoding="utf-8"))
    assert data["status"] == "WDROZONY_100"
    assert data["gate_summary"]["passed"] == 6
