#!/usr/bin/env python3
"""Gate test for PROMPT_23: DOKUMENTACJA — verifies WDROZONY_100."""
from __future__ import annotations

import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
TOOL = BASE_DIR / "tools" / "documentation_report23_gate.py"


def _load_gate():
    import importlib.util
    spec = importlib.util.spec_from_file_location("documentation_report23_gate", TOOL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_scope_files_present():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["scope_files_present"]


def test_core_docs_complete():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["core_docs_complete"]


def test_tech_docs_adequate():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["tech_docs_adequate"]


def test_legal_docs_present():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["legal_docs_present"]


def test_metrics_consistency():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["metrics_consistency"]


def test_key_sections_present():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["key_sections_present"]


def test_doc_tools_complete():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["doc_tools_complete"]


def test_doc_directory_populated():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["doc_directory_populated"]


def test_golden_replay_ready():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["golden_replay_ready"]


def test_innovations_12_plus():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["innovations_12_plus"]


def test_syntax_ok():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["syntax_ok"]


def test_report_present():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["gates"]["report_present"]


def test_status_wdrozone_100():
    mod = _load_gate()
    ev = mod.build_evidence()
    assert ev["status"] == "WDROZONY_100", f"Status: {ev['status']} ({ev['gate_summary']})"


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-v", "--tb=short"]))