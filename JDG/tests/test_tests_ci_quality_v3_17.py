from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "tests_ci_quality_v3_17_gate.py"


def run_gate(*args: str) -> dict:
    proc = subprocess.run([sys.executable, str(GATE), "--json", *args], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    return json.loads(proc.stdout)


def test_full_contract():
    evidence = run_gate()
    assert evidence["contract"]["contract_complete"]
    assert evidence["contract"]["snapshot_present"]
    assert evidence["contract"]["p77_present"]


def test_fail_closed_contract_markers():
    evidence = run_gate()
    assert evidence["contract"]["no_auto_post_guard"]
    assert evidence["metadata"]["duplicate_free"]
    assert evidence["metadata"]["empty_legal_basis"] == 0


def test_workflows_present_in_repository():
    evidence = run_gate()
    assert evidence["gates"]["scope_complete"]
    assert all(evidence["scope"]["workflows"].values())


def test_snapshot_versioned_and_aligned_with_etap24():
    evidence = run_gate()
    assert evidence["contract"]["snapshot_versioned"]
    assert evidence["contract"]["snapshot_aligned_etap24"]


def test_chaos_mutation_fuzz_tools_registered():
    evidence = run_gate()
    assert evidence["gates"]["tools_complete"]
    assert evidence["tools"]["golden_replay_record_verify"]
    assert evidence["tools"]["golden_baseline_immutable"]


def test_router_wired_p77():
    evidence = run_gate()
    assert evidence["gates"]["router_wired"]
    assert evidence["contract"]["post_merge_anchor_current"]


def test_evidence_gate_writes_bundle():
    proc = subprocess.run([sys.executable, str(GATE), "--write"], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    bundle = ROOT / "bundles" / "tests_ci_v3_audit_17.json"
    evidence = json.loads(bundle.read_text(encoding="utf-8"))
    assert evidence["status"] == "WDROZONY_100"
    assert bundle.exists()
