from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "enterprise_quality_v3_15_gate.py"


def run_gate(*args: str) -> dict:
    proc = subprocess.run([sys.executable, str(GATE), "--json", *args], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    return json.loads(proc.stdout)


def test_full_contract():
    evidence = run_gate()
    assert evidence["contract"]["contract_complete"]
    assert evidence["contract"]["snapshot_present"]
    assert evidence["contract"]["p75_present"]


def test_fail_closed_contract_markers():
    evidence = run_gate()
    assert evidence["contract"]["no_auto_post_guard"]
    assert evidence["metadata"]["duplicate_free"]
    assert evidence["metadata"]["empty_legal_basis"] == 0


def test_s1_s24_initiative_registry_complete():
    evidence = run_gate()
    assert evidence["gates"]["s1_s24_complete"]
    assert len(evidence["metadata"]["s1_s24_ids_in_contract"]) == 24


def test_temporal_and_calibration_snapshot_versioned():
    evidence = run_gate()
    assert evidence["contract"]["snapshot_versioned"]
    markers = evidence["contract"]["contract_markers"]
    assert markers["temporal_valid"]
    assert markers["scoring_calibrated"]
    assert markers["mesh_complete"]


def test_red_team_and_composer_contract():
    evidence = run_gate()
    markers = evidence["contract"]["contract_markers"]
    assert markers["red_team_complete"]
    assert markers["composer_complete"]


def test_enterprise_tools_present():
    evidence = run_gate()
    assert evidence["gates"]["tools_complete"]
    assert evidence["tools"]["autonomous_tax_strategy"]
    assert evidence["tools"]["decision_quality_monitor"]


def test_evidence_gate_writes_bundle():
    proc = subprocess.run([sys.executable, str(GATE), "--write"], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    bundle = ROOT / "bundles" / "enterprise_v3_audit_15.json"
    evidence = json.loads(bundle.read_text(encoding="utf-8"))
    assert evidence["status"] == "WDROZONY_100"
    assert bundle.exists()
