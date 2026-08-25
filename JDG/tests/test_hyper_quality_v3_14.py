from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "hyper_quality_v3_14_gate.py"


def run_gate(*args: str) -> dict:
    proc = subprocess.run([sys.executable, str(GATE), "--json", *args], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    return json.loads(proc.stdout)


def test_full_contract():
    evidence = run_gate()
    assert evidence["contract"]["contract_complete"]
    assert evidence["contract"]["snapshot_present"]
    assert evidence["contract"]["p74_present"]


def test_fail_closed_contract_markers():
    evidence = run_gate()
    assert evidence["contract"]["no_auto_post_guard"]
    assert evidence["metadata"]["duplicate_free"]
    assert evidence["metadata"]["empty_legal_basis"] == 0


def test_temporal_registry_and_deadlines_are_required():
    evidence = run_gate()
    assert evidence["contract"]["snapshot_versioned"]
    assert evidence["contract"]["contract_markers"]["temporal_valid"]
    assert evidence["contract"]["contract_markers"]["deadline_complete"]


def test_limits_sanctions_and_force_majeure_contract():
    evidence = run_gate()
    markers = evidence["contract"]["contract_markers"]
    assert markers["limits_complete"]
    assert markers["sanction_complete"]
    assert markers["force_majeure_complete"]


def test_evidence_gate_writes_bundle():
    proc = subprocess.run([sys.executable, str(GATE), "--write"], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    evidence = json.loads((ROOT / "bundles" / "hyper_quality_v3_audit_14.json").read_text(encoding="utf-8"))
    assert evidence["status"] == "WDROZONY_100"
    assert (ROOT / "bundles" / "hyper_quality_v3_audit_14.json").exists()
