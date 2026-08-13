#!/usr/bin/env python3
"""Tests for the RAPORT_14 evidence gate (RODO / AML-CBDD / BDO / środowisko /
sekurytyzacja)."""

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

import rodo_aml_bdo_report14_gate as gate


def test_gate_reaches_wdrozony_100():
    ev = gate.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"expected WDROZONY_100, got {ev['status']}"
    assert ev["gate_summary"]["passed"] == ev["gate_summary"]["total"] == 9


def test_scope_inventory_matches_report():
    inv = gate.build_evidence()["inventory"]
    assert inv["files_present"] == inv["files_total"] == 28
    assert inv["duplicate_count"] == 0, f"duplicates: {inv['duplicate_rule_ids']}"
    assert inv["rule_ids_total"] == inv["rule_ids_unique"], "rule_id collisions remain"


def test_critical_articles_have_test_evidence():
    te = gate.build_evidence()["test_evidence"]
    assert te["critical_rule_evidence_complete"] is True
    for article in gate.CRITICAL_ARTICLES:
        assert te["critical_rule_markers"][article] is True, f"{article} marker missing"


def test_critical_articles_temporal():
    inv = gate.build_evidence()["inventory"]
    assert inv["critical_temporal_rule_count"] >= len(gate.CRITICAL_MARKERS)
    for article, ok in inv["critical_temporal_evidence"].items():
        assert ok is True, f"{article} temporal block missing"


def test_legal_twin_covers_critical_articles():
    lt = gate.build_evidence()["legal_twin"]
    for article, ok in lt["critical_articles_with_rules"].items():
        assert ok is True, f"{article} has no Legal Twin rule evidence"
    assert lt["critical_articles_required"] == len(gate.CRITICAL_ARTICLES)


def test_router_wired():
    rt = gate.build_evidence()["router"]
    assert rt["p16_package_registered"] is True
    assert rt["p15_package_registered"] is True
    assert rt["rodo_package_registered"] is True
    assert rt["security_fortress_registered"] is True
    assert rt["final_verdict"] is True


def test_safety_suggest_no_auto_post():
    s = gate.build_evidence()["safety"]
    assert s["suggest_mode_present"] is True
    assert s["no_auto_post"] is True


def test_golden_replay_and_rollback():
    ev = gate.build_evidence()
    assert ev["replay"]["replay_verified"] is True
    assert ev["replay"]["unmatched_count"] == 0
    dep = ev["deployment"]
    assert dep["phase"] == "ROLLED_BACK"
    assert dep["rollback_reason"] is not None


def test_evidence_bundle_written_and_consistent():
    ev_path = BASE_DIR / "bundles" / "rodo_aml_bdo_report14_evidence.json"
    assert ev_path.exists(), "evidence bundle not written"
    data = json.loads(ev_path.read_text(encoding="utf-8"))
    assert data["status"] == "WDROZONY_100"
    assert data["gate_summary"]["passed"] == 9
