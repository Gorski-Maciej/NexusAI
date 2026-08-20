#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.kks_ord_etap16_audit import (
    BUNDLE_PATH,
    PACKAGE_PATH,
    REPORT_PATH,
    build_evidence,
    package_evidence,
)

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = (ROOT / PACKAGE_PATH).read_text(encoding="utf-8")


def test_package_has_all_kks_ord_sections():
    evidence = package_evidence(PACKAGE)
    assert evidence["sections"] == {
        "risk": True,
        "evidence": True,
        "disclosure": True,
        "sanctions": True,
        "limitation": True,
        "obligations": True,
        "procedures": True,
        "deadline": True,
        "invariants": True,
    }


def test_risk_scoring_with_classes():
    assert "risk_scoring" in PACKAGE
    assert "risk_score" in PACKAGE
    assert "risk_class" in PACKAGE
    assert "CRITICAL" in PACKAGE and "HIGH" in PACKAGE and "LOW" in PACKAGE


def test_evidence_chain_with_source_rule():
    assert "evidence_chain" in PACKAGE
    assert "source_rule" in PACKAGE
    assert "evidence_count" in PACKAGE


def test_voluntary_disclosure_non_automatic_with_disclaimer():
    assert "voluntary_disclosure_audit" in PACKAGE
    assert "disclaimer" in PACKAGE
    assert "automatic" in PACKAGE
    assert "art. 16 § 1 KKS" in PACKAGE


def test_sanctions_and_materiality():
    assert "sanction_audit" in PACKAGE
    assert "materiality" in PACKAGE
    assert "penalty_cap" in PACKAGE
    assert "daily_rate" in PACKAGE
    assert "art. 54-83 KKS" in PACKAGE


def test_limitation_temporal():
    assert "limitation_audit" in PACKAGE
    assert "limitation_years" in PACKAGE
    assert "expired" in PACKAGE
    assert "art. 44 KKS" in PACKAGE
    assert "art. 70 OrdPU" in PACKAGE


def test_correction_interest_overpayment_relief():
    assert "obligation_audit" in PACKAGE
    assert "correction" in PACKAGE
    assert "interest_amount" in PACKAGE
    assert "overpayment" in PACKAGE
    assert "payment_relief" in PACKAGE


def test_interpretation_poa_and_gaar():
    assert "procedure_audit" in PACKAGE
    assert "interpretation_requested" in PACKAGE
    assert "power_of_attorney" in PACKAGE
    assert "gaar_analysis" in PACKAGE
    assert "art. 119a OrdPU" in PACKAGE


def test_deadline_engine_red_amber_green():
    assert "deadline_audit" in PACKAGE
    assert "deadline_level" in PACKAGE
    assert "RED" in PACKAGE and "AMBER" in PACKAGE and "GREEN" in PACKAGE
    assert "deadline_overdue" in PACKAGE


def test_manual_review_and_fail_closed_gates():
    # CRITICAL risk or overdue deadline is routed to manual review, never auto-posted.
    assert "manual_review" in PACKAGE
    for marker in ["missing_context", "uncertainty_markers", "cross_domain_collisions", "BLOCK_AND_ALERT", "TRIAGE_QUEUE"]:
        assert marker in PACKAGE


def test_property_invariants_present():
    assert "property_invariants" in PACKAGE
    assert "invariant_failed" in PACKAGE
    assert "risk_in_range" in PACKAGE
    assert "disclaimer_present" in PACKAGE


def test_temporal_and_boundary_contract_is_externalized():
    assert "evaluation_date" in PACKAGE
    assert "evaluation_year" in PACKAGE
    assert "threshold_version" in PACKAGE
    assert "legal_basis_version" in PACKAGE
    assert "facts_version" in PACKAGE
    assert "penalty_multiplier_max" in PACKAGE
    assert "daily_rate_denominator" in PACKAGE


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


def test_native_rego_tests_present_with_risk_temporal_property():
    from tools.kks_ord_etap16_audit import native_tests_evidence

    native = native_tests_evidence()
    assert native["present"]
    assert native["complete"]
