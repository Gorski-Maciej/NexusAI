#!/usr/bin/env python3
"""Gate test for PROMPT_22: POLICIES MIRROR — verifies WDROZONY_100."""
from __future__ import annotations

import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
TOOL = BASE_DIR / "tools" / "policies_mirror_report22_gate.py"


def _load_gate():
    import importlib.util
    spec = importlib.util.spec_from_file_location("policies_mirror_report22_gate", TOOL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_scope_files_present():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["scope_files_present"], f"Scope: {ev['scope']['coverage_pct']}%"


def test_rego_governance_complete():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["rego_governance_complete"], "Rego governance incomplete"


def test_readme_source_of_truth():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["readme_source_of_truth"], "README missing source of truth"


def test_sync_gate_tool_complete():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["sync_gate_tool_complete"], "Sync gate tool incomplete"


def test_overlay_engine_complete():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["overlay_engine_complete"], "Overlay engine incomplete"


def test_overlay_manifests_present():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["overlay_manifests_present"], "Overlay manifests missing"


def test_inventory_reconciliation():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["inventory_reconciliation"], "Inventory reconciliation missing"


def test_golden_replay_ready():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["golden_replay_ready"], "Golden replay not ready"


def test_drift_report_valid():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["drift_report_valid"], "Drift report invalid"


def test_innovations_12_plus():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["innovations_12_plus"], "Less than 12 innovations"


def test_syntax_ok():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["syntax_ok"], f"Syntax errors: {ev['syntax']['syntax_errors']}"


def test_test_coverage():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["test_coverage"], "Test coverage missing"


def test_report_present():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["report_present"], "Report file missing"


def test_status_wdrozone_100():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"Status: {ev['status']} ({ev['gate_summary']})"


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-v", "--tb=short"]))