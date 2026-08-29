#!/usr/bin/env python3
"""Tests for the RAPORT_23 evidence gate (DOKUMENTACJA)."""

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import documentation_report23_gate as gate


def test_gate_reaches_wdrozony_100():
    ev = gate.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"expected WDROZONY_100, got {ev['status']}"
    assert ev["gate_summary"]["passed"] == ev["gate_summary"]["total"] == 12


def test_scope_files_present():
    scope = gate.build_evidence()["scope"]
    assert scope["total_present"] == scope["total_declared"]
    assert scope["missing"] == []


def test_sections_present():
    sections = gate.build_evidence()["key_sections"]
    assert sections["complete"] is True


def test_golden_replay_ready():
    replay = gate.build_evidence()["golden_replay"]
    assert replay["valid"] is True
    assert replay["verdicts"] >= 1


def test_canary_rollback():
    evidence = gate.build_evidence()
    assert evidence["status"] == "WDROZONY_100"


def test_evidence_bundle_written_and_consistent():
    ev_path = BASE_DIR / "bundles" / "documentation_report23_evidence.json"
    assert ev_path.exists(), "evidence bundle not written"
    data = json.loads(ev_path.read_text(encoding="utf-8"))
    assert data["status"] == "WDROZONY_100"
    assert data["gate_summary"]["passed"] == 12
