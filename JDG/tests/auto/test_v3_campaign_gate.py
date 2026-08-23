#!/usr/bin/env python3
"""Gate test for campaign V3 — verifies prompts, registry and reports."""
from __future__ import annotations

import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
TOOL = BASE_DIR / "tools" / "v3_campaign_gate.py"


def _load_gate():
    import importlib.util
    spec = importlib.util.spec_from_file_location("v3_campaign_gate", TOOL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_prompts_present():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["prompts_present"], "Brakuje plików Prompt 00-20"


def test_registry_valid():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["registry_valid"], "Rejestr enterprise_v3_registry.json niepoprawny"


def test_reports_for_completed_present():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["reports_for_completed_present"], f"Brak raportów: {ev['missing_reports']}"


def test_summary_consistent():
    ev = _load_gate().build_evidence()
    assert ev["gates"]["summary_consistent"]


def test_status_is_w_trakcie_or_wdrozony():
    ev = _load_gate().build_evidence()
    assert ev["status"] in ("W_TRAKCIE_KAMPANII", "WDROZONY_100"), ev["status"]


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-v", "--tb=short"]))