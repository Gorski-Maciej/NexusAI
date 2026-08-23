#!/usr/bin/env python3
"""Gate test for PROMPT_21: TESTS I CI — verifies WDROZONY_100."""
from __future__ import annotations

import json
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
TOOL = BASE_DIR / "tools" / "tests_ci_report21_gate.py"

# Import via exec (tool is not a package)
def _load_gate():
    import importlib.util
    spec = importlib.util.spec_from_file_location("tests_ci_report21_gate", TOOL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_scope_files_present():
    mod = _load_gate()
    evidence = mod.build_evidence()
    assert evidence["gates"]["scope_files_present"], f"Scope failed: {evidence['scope']['missing_tools'][:3]}..."


def test_ci_pipeline_complete():
    mod = _load_gate()
    evidence = mod.build_evidence()
    assert evidence["gates"]["ci_pipeline_complete"], "CI pipeline incomplete"


def test_test_infrastructure_complete():
    mod = _load_gate()
    evidence = mod.build_evidence()
    infra = evidence["test_infrastructure"]
    assert infra["passed"] >= infra["total"] * 0.85, f"Infra: {infra['passed']}/{infra['total']}"


def test_rego_rules_complete():
    mod = _load_gate()
    evidence = mod.build_evidence()
    assert evidence["gates"]["rego_rules_complete"], "Rego rules incomplete"


def test_L0_L9_strategy():
    mod = _load_gate()
    evidence = mod.build_evidence()
    strat = evidence["strategy_L0_L9"]
    assert strat["implemented"] >= 8, f"Strategy: {strat['implemented']}/{strat['total']}"


def test_coverage_tracked():
    mod = _load_gate()
    evidence = mod.build_evidence()
    assert evidence["gates"]["coverage_tracked"], "Coverage not tracked"


def test_golden_replay_ready():
    mod = _load_gate()
    evidence = mod.build_evidence()
    assert evidence["gates"]["golden_replay_ready"], "Golden replay not ready"


def test_innovations_12_plus():
    mod = _load_gate()
    evidence = mod.build_evidence()
    assert evidence["gates"]["innovations_12_plus"], "Less than 12 innovations"


def test_syntax_ok():
    mod = _load_gate()
    evidence = mod.build_evidence()
    assert evidence["gates"]["syntax_ok"], f"Syntax errors: {evidence['syntax']['syntax_errors']}"


def test_report_present():
    mod = _load_gate()
    evidence = mod.build_evidence()
    assert evidence["gates"]["report_present"], "Report file not present"


def test_status_wdrozone_100():
    mod = _load_gate()
    evidence = mod.build_evidence()
    assert evidence["status"] == "WDROZONY_100", f"Status: {evidence['status']} ({evidence['gate_summary']})"


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-v", "--tb=short"]))