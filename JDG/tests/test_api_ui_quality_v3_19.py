from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "api_ui_quality_v3_19_gate.py"


def run_gate(*args: str) -> dict:
    proc = subprocess.run([sys.executable, str(GATE), "--json", *args], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    return json.loads(proc.stdout)


def test_full_contract():
    evidence = run_gate()
    assert evidence["contract"]["contract_complete"]
    assert evidence["contract"]["snapshot_present"]
    assert evidence["contract"]["p79_present"]


def test_fail_closed_contract_markers():
    evidence = run_gate()
    assert evidence["contract"]["no_auto_post_guard"]
    assert evidence["metadata"]["duplicate_free"]
    assert evidence["metadata"]["empty_legal_basis"] == 0


def test_api_spec_consistent_no_gaps():
    evidence = run_gate()
    assert evidence["gates"]["api_spec_complete"]
    assert evidence["api_spec"]["spec_gap_count"] == 0
    assert evidence["api_spec"]["spec_paths_implemented"] >= 17
    markers = evidence["api_spec"]["openapi_markers"]
    assert markers["x-rate-limit"]
    assert markers["/jdg/ready"]
    assert markers["IdempotencyKey"]


def test_control_plane_lifecycle_and_declarative_change():
    evidence = run_gate()
    assert evidence["gates"]["control_plane_complete"]
    cp = evidence["control_plane"]
    assert cp["lifecycle_stages"]
    assert cp["four_eyes_sod"]
    assert cp["declarative_wizard"]
    assert cp["declarative_never_automated"]
    assert cp["declarative_dry_run_default"]


def test_decision_center_modes_documented():
    evidence = run_gate()
    assert evidence["gates"]["decision_center_documented"]
    modes = evidence["decision_center"]["modes"]
    assert modes["AUTO_POST"] and modes["SUGGEST"] and modes["ASK_USER"]
    assert evidence["decision_center"]["certainty_guard_mentioned"]


def test_router_wired_p79():
    evidence = run_gate()
    assert evidence["gates"]["router_wired"]
    assert evidence["contract"]["post_merge_anchor_current"]


def test_evidence_gate_writes_bundle():
    proc = subprocess.run([sys.executable, str(GATE), "--write"], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    bundle = ROOT / "bundles" / "api_ui_v3_audit_19.json"
    evidence = json.loads(bundle.read_text(encoding="utf-8"))
    assert evidence["status"] == "WDROZONY_100"
    assert bundle.exists()
