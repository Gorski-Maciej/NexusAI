#!/usr/bin/env python3
"""Tests for the RAPORT_16 evidence gate (SYSTEM OPA / P18–P35)."""

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import opa_system_report16_gate as gate


def test_gate_reaches_wdrozony_100():
    ev = gate.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"expected WDROZONY_100, got {ev['status']}"
    assert ev["gate_summary"]["passed"] == ev["gate_summary"]["total"] == 9


def test_scope_inventory_matches_report():
    inv = gate.build_evidence()["inventory"]
    assert inv["files_present"] == inv["files_total"] == 24
    assert inv["duplicate_count"] == 0, f"duplicates: {inv['duplicate_rule_ids']}"
    assert inv["rule_ids_total"] == inv["rule_ids_unique"], "rule_id collisions remain"


def test_critical_rules_have_test_evidence():
    te = gate.build_evidence()["test_evidence"]
    assert te["critical_rule_evidence_complete"] is True
    for name in gate.CRITICAL_TEST_MARKERS:
        assert te["critical_rule_markers"][name] is True, f"{name} marker missing"


def test_critical_rules_temporal():
    inv = gate.build_evidence()["inventory"]
    assert inv["critical_temporal_rule_count"] >= len(gate.CRITICAL_RULES)
    for name, ok in inv["critical_temporal_evidence"].items():
        assert ok is True, f"{name} temporal block missing"


def test_critical_rules_canonical_legal_basis():
    lc = gate.build_evidence()["legal_canonical"]
    for name, ok in lc["critical_legal_basis"].items():
        assert ok is True, f"{name} missing _legal_basis"
    for name, ok in lc["critical_canonical_reference"].items():
        assert ok is True, f"{name} missing canonical ADR/P0x reference"
    assert lc["critical_rules_required"] == len(gate.CRITICAL_RULES)


def test_router_wired():
    rt = gate.build_evidence()["router"]
    assert rt["rule_lifecycle_registered"] is True
    assert rt["reliability_registered"] is True
    assert rt["p21_registered"] is True
    assert rt["p22_registered"] is True
    assert rt["p23_registered"] is True
    assert rt["p34_registered"] is True
    assert rt["final_verdict"] is True


def test_safety_suggest_no_auto_post_mode():
    s = gate.build_evidence()["safety"]
    assert s["suggest_mode_present"] is True
    assert s["auto_post_mode_present"] is False
    assert s["no_auto_post_mode"] is True


def test_golden_replay_and_rollback():
    ev = gate.build_evidence()
    assert ev["replay"]["replay_verified"] is True
    assert ev["replay"]["unmatched_count"] == 0
    dep = ev["deployment"]
    assert dep["phase"] == "ROLLED_BACK"
    assert dep["rollback_reason"] is not None


def test_evidence_bundle_written_and_consistent():
    ev_path = BASE_DIR / "bundles" / "opa_system_report16_evidence.json"
    assert ev_path.exists(), "evidence bundle not written"
    data = json.loads(ev_path.read_text(encoding="utf-8"))
    assert data["status"] == "WDROZONY_100"
    assert data["gate_summary"]["passed"] == 9
