#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.zus_core_etap12_audit import (
    BUNDLE_PATH,
    PACKAGE_PATH,
    REPORT_PATH,
    build_evidence,
    package_evidence,
)

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = (ROOT / PACKAGE_PATH).read_text(encoding="utf-8")


def test_package_has_all_zus_core_sections():
    evidence = package_evidence(PACKAGE)
    assert evidence["sections"] == {
        "health": True,
        "social": True,
        "reliefs": True,
        "benefits": True,
        "ppk_pfron": True,
        "deadlines": True,
    }


def test_calculation_certificate_is_complete():
    evidence = package_evidence(PACKAGE)
    assert evidence["markers_complete"]
    for marker in ["calculation_certificate", "threshold_version", "legal_basis_version", "facts_version", "rounding_contract", "boundary_tests"]:
        assert marker in PACKAGE


def test_legal_basis_and_temporal_thresholds_are_externalized():
    evidence = package_evidence(PACKAGE)
    assert evidence["legal_basis_complete"]
    assert evidence["thresholds_externalized"]
    assert "data.jdg.thresholds" in PACKAGE


def test_relief_boundaries_are_explicit():
    assert "months_since_start < start_months" in PACKAGE
    assert "months_since_start >= start_months" in PACKAGE
    assert "start_months + preferential_months" in PACKAGE
    assert "maly_window" in PACKAGE


def test_fail_closed_and_cross_domain_gates_exist():
    for marker in ["missing_context", "uncertainty_markers", "cross_domain_collisions", "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "manual_review"]:
        assert marker in PACKAGE


def test_suggest_only_contract():
    assert 'decision_mode := "SUGGEST"' in PACKAGE
    assert '"no_auto_post": true' in PACKAGE
    assert '"AUTO_POST"' not in PACKAGE


def test_orchestrator_wiring_and_full_gate():
    evidence = build_evidence()
    assert evidence["wiring"]["complete"]
    assert REPORT_PATH.exists()
    assert BUNDLE_PATH.exists()
    assert evidence["status"] == "WDROZONY_100"
    assert evidence["gate_summary"]["passed"] == evidence["gate_summary"]["total"]
