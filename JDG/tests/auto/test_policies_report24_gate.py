#!/usr/bin/env python3
"""Tests for the RAPORT_24 evidence gate (POLICIES)."""

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import policies_report24_gate as gate


def test_gate_reaches_wdrozony_100():
    ev = gate.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"expected WDROZONY_100, got {ev['status']}"
    assert ev["gate_summary"]["passed"] == ev["gate_summary"]["total"] == 6


def test_scope_files_present():
    scope = gate.build_evidence()["scope"]
    assert scope["docs_present"] == scope["docs_total"] == 5
    assert scope["tests_present"] == scope["tests_total"] == 12
    assert scope["policy_artifacts_present"] == scope["policy_artifacts_total"] == 7
    assert scope["drift_report_present"] is True
    assert scope["missing"] == []


def test_overlays_present():
    overlays = gate.build_evidence()["overlays"]
    assert overlays["all_present"] is True
    assert overlays["overlays"]["v2026"]["tax_year"] == 2026
    assert overlays["overlays"]["v2027"]["tax_year"] == 2027


def test_drift_reported():
    drift = gate.build_evidence()["drift"]
    assert drift["reported"] is True
    assert drift["drift_pct"] is not None
    assert drift["conclusion"] is not None


def test_sync_tool_present():
    sync = gate.build_evidence()["sync_tool"]
    assert sync["all"] is True
    assert sync["has_sync"] and sync["has_drift"] and sync["has_overlay"]


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
    ev_path = BASE_DIR / "bundles" / "policies_report24_evidence.json"
    assert ev_path.exists(), "evidence bundle not written"
    data = json.loads(ev_path.read_text(encoding="utf-8"))
    assert data["status"] == "WDROZONY_100"
    assert data["gate_summary"]["passed"] == 6
