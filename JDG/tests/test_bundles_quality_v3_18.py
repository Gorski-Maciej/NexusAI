from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "bundles_quality_v3_18_gate.py"


def run_gate(*args: str) -> dict:
    proc = subprocess.run([sys.executable, str(GATE), "--json", *args], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    return json.loads(proc.stdout)


def test_full_contract():
    evidence = run_gate()
    assert evidence["contract"]["contract_complete"]
    assert evidence["contract"]["snapshot_present"]
    assert evidence["contract"]["p78_present"]


def test_fail_closed_contract_markers():
    evidence = run_gate()
    assert evidence["contract"]["no_auto_post_guard"]
    assert evidence["metadata"]["duplicate_free"]
    assert evidence["metadata"]["empty_legal_basis"] == 0


def test_mirror_and_policies_present():
    evidence = run_gate()
    assert evidence["gates"]["scope_complete"]
    assert evidence["scope"]["mirror_rego_files"] > 0


def test_snapshot_versioned_with_sla_thresholds():
    evidence = run_gate()
    assert evidence["contract"]["snapshot_versioned"]
    markers = evidence["contract"]["contract_markers"]
    assert markers["temporal_valid"]


def test_control_plane_tools_registered():
    evidence = run_gate()
    assert evidence["gates"]["tools_complete"]
    assert evidence["tools"]["bundle_sign_mode"]
    assert evidence["tools"]["bundle_sbom_and_signature"]
    assert evidence["tools"]["dr_rto_rpo"]
    assert evidence["tools"]["data_service_hot_reload"]


def test_router_wired_p78():
    evidence = run_gate()
    assert evidence["gates"]["router_wired"]
    assert evidence["contract"]["post_merge_anchor_current"]


def test_evidence_gate_writes_bundle():
    proc = subprocess.run([sys.executable, str(GATE), "--write"], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    bundle = ROOT / "bundles" / "bundles_v3_audit_18.json"
    evidence = json.loads(bundle.read_text(encoding="utf-8"))
    assert evidence["status"] == "WDROZONY_100"
    assert bundle.exists()
