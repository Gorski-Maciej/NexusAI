#!/usr/bin/env python3
"""Gate test for PROMPT_24: FORTECA KOŃCOWA — verifies WDROZONY_100."""
from __future__ import annotations

import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
TOOL = BASE_DIR / "tools" / "forteca_report24_gate.py"


def _load_gate():
    import importlib.util
    spec = importlib.util.spec_from_file_location("forteca_report24_gate", TOOL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_scope_files_present():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["scope_files_present"]


def test_campaign_reconciled():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["campaign_reconciled"]


def test_domain_certification():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["domain_certification"]


def test_production_blockers_cleared():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["production_blockers_cleared"]


def test_red_team_defenses():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["red_team_defenses"]


def test_chaos_matrix():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["chaos_matrix"]


def test_slo_sla_defined():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["slo_sla_defined"]


def test_fail_closed_verified():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["fail_closed_verified"]


def test_golden_replay_ready():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["golden_replay_ready"]


def test_innovations_12_plus():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["innovations_12_plus"]


def test_syntax_ok():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["syntax_ok"]


def test_report_present():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["report_present"]


def test_status_wdrozone_100():
    ev = _load_gate().build_evidence()
    assert ev["status"] == "WDROZONY_100", f"Status: {ev['status']} ({ev['gate_summary']})"


def test_campaign_25_wdrozonych():
    ev = _load_gate().build_evidence()
    c = ev["campaign"]
    assert c["reports_wdrozone"] >= 25, f"Only {c['reports_wdrozone']} wdrożone"
    assert c["reports_incomplete"] == 0, f"Still {c['reports_incomplete']} incomplete: {c['incomplete_list']}"


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-v", "--tb=short"]))