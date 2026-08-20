#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.zus_micro_etap13_audit import (
    BUNDLE_PATH,
    PACKAGE_PATH,
    REPORT_PATH,
    build_evidence,
    package_evidence,
)

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = (ROOT / PACKAGE_PATH).read_text(encoding="utf-8")


def test_package_has_all_zus_micro_sections():
    evidence = package_evidence(PACKAGE)
    assert evidence["sections"] == {
        "atom_map": True,
        "coverage": True,
        "periods": True,
        "benefits": True,
        "invariants": True,
        "certificate": True,
    }


def test_atom_map_is_law_article_condition_calculation_certificate_test():
    for marker in ["ustawa", "artykul", "warunek", "obliczenie", "swiadectwo", "test"]:
        assert marker in PACKAGE
    assert "atom_map" in PACKAGE
    assert "atom_count" in PACKAGE


def test_coverage_reconciliation_flags_missing_and_discrepancies():
    assert "coverage_summary" in PACKAGE
    assert "coverage_discrepancies" in PACKAGE
    assert "missing_atoms" in PACKAGE
    assert '"6a"' in PACKAGE
    assert '"81b"' in PACKAGE and '"81c"' in PACKAGE and '"81d"' in PACKAGE


def test_insurance_periods_cover_concurrency_suspension_breaks():
    assert "period_analysis" in PACKAGE
    assert "concurrency" in PACKAGE
    assert "suspended" in PACKAGE
    assert "break_months" in PACKAGE
    assert "Art. 6, 9 SUS" in PACKAGE
    assert "Art. 36a SUS" in PACKAGE


def test_benefits_calculators_chorobowe_macierzynskie_opiekuncze():
    assert "benefit_calculation" in PACKAGE
    for kind in ["CHOROBOWE", "MACIERZYNSKIE", "OPIEKUNCZE"]:
        assert kind in PACKAGE
    assert "benefit_daily" in PACKAGE
    assert "benefit_amount" in PACKAGE


def test_property_invariants_and_no_silent_default():
    assert "property_invariants" in PACKAGE
    assert "invariant_failed" in PACKAGE
    assert "rates_in_unit_interval" in PACKAGE
    assert "no_silent_default" in PACKAGE
    assert "PLN_HALF_UP_2DP" in PACKAGE


def test_temporal_and_boundary_contract_is_externalized():
    assert "evaluation_date" in PACKAGE
    assert "evaluation_year" in PACKAGE
    assert "threshold_version" in PACKAGE
    assert "legal_basis_version" in PACKAGE
    assert "facts_version" in PACKAGE
    assert "sickness_max_days_standard" in PACKAGE
    assert "maternity_weeks_standard" in PACKAGE


def test_fail_closed_and_cross_domain_gates_exist():
    for marker in ["missing_context", "uncertainty_markers", "cross_domain_collisions", "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "manual_review"]:
        assert marker in PACKAGE


def test_calculation_certificate_is_complete():
    for marker in ["calculation_certificate", "rounding_contract", "threshold_version", "legal_basis_version", "facts_version"]:
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


def test_native_rego_tests_present_with_negative_temporal_property():
    from tools.zus_micro_etap13_audit import native_tests_evidence

    native = native_tests_evidence()
    assert native["present"]
    assert native["complete"]
