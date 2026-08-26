from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "tools_quality_v3_16_gate.py"


def run_gate(*args: str) -> dict:
    proc = subprocess.run([sys.executable, str(GATE), "--json", *args], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    return json.loads(proc.stdout)


def test_full_contract():
    evidence = run_gate()
    assert evidence["contract"]["contract_complete"]
    assert evidence["contract"]["snapshot_present"]
    assert evidence["contract"]["p76_present"]


def test_fail_closed_contract_markers():
    evidence = run_gate()
    assert evidence["contract"]["no_auto_post_guard"]
    assert evidence["metadata"]["duplicate_free"]
    assert evidence["metadata"]["empty_legal_basis"] == 0


def test_six_lint_checks_present():
    evidence = run_gate()
    assert evidence["gates"]["tools_complete"]
    assert evidence["tools"]["lint_checks_six"]


def test_snapshot_versioned_with_tool_registry():
    evidence = run_gate()
    assert evidence["contract"]["snapshot_versioned"]
    markers = evidence["contract"]["contract_markers"]
    assert markers["temporal_valid"]
    assert markers["coverage_ok"]


def test_gap_reports_and_validators_registered():
    evidence = run_gate()
    markers = evidence["contract"]["contract_markers"]
    assert markers["gap_reports_complete"]
    assert markers["validators_complete"]
    assert markers["linters_complete"]


def test_router_wired_p76():
    evidence = run_gate()
    assert evidence["gates"]["router_wired"]
    assert evidence["contract"]["post_merge_anchor_current"]


def test_evidence_gate_writes_bundle():
    proc = subprocess.run([sys.executable, str(GATE), "--write"], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stderr
    bundle = ROOT / "bundles" / "quality_gates_v3_audit_16.json"
    evidence = json.loads(bundle.read_text(encoding="utf-8"))
    assert evidence["status"] == "WDROZONY_100"
    assert bundle.exists()
