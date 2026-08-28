#!/usr/bin/env python3
import sys
import re
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.pkpir_etap14_audit import (
    BUNDLE_PATH,
    PACKAGE_PATH,
    REPORT_PATH,
    build_evidence,
    package_evidence,
)

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = (ROOT / PACKAGE_PATH).read_text(encoding="utf-8")


def test_package_has_all_pkpir_sections():
    evidence = package_evidence(PACKAGE)
    assert evidence["sections"] == {
        "evidence_pack": True,
        "columns": True,
        "moment": True,
        "deductions": True,
        "adjustments": True,
        "reconciliation": True,
        "idempotency": True,
        "invariants": True,
    }


def test_evidence_pack_has_document_and_source_rule():
    for marker in ["evidence_pack", "required_document", "source_rule", "decision"]:
        assert marker in PACKAGE
    assert "evidence_count" in PACKAGE


def test_columns_numbering_and_chronology_verified():
    assert "column_audit" in PACKAGE
    assert "lp_sequential" in PACKAGE
    assert "chronology_ok" in PACKAGE
    assert "document_present" in PACKAGE
    assert "columns_complete" in PACKAGE


def test_revenue_cost_moment_is_cash_basis():
    assert "moment_audit" in PACKAGE
    assert "CASH_RECEIPT" in PACKAGE
    assert "CASH_PAID" in PACKAGE
    assert "cash_basis_days" in PACKAGE
    assert "art. 14 ust. 1 PIT" in PACKAGE


def test_nkup_vehicles_leasing_wages_covered():
    assert "deduction_audit" in PACKAGE
    assert "nkup" in PACKAGE
    assert "vehicle_limit" in PACKAGE
    assert "leasing_type" in PACKAGE
    assert "wages_amount" in PACKAGE
    assert "car_limit_standard" in PACKAGE
    assert "car_limit_electric" in PACKAGE


def test_remanent_storno_and_corrections_covered():
    assert "adjustment_audit" in PACKAGE
    assert "remanent_type" in PACKAGE
    assert "storno" in PACKAGE
    assert "correction_reason" in PACKAGE


def test_three_way_reconciliation_pkpir_vat_bank():
    assert "reconciliation" in PACKAGE
    assert "vat_sales_total" in PACKAGE
    assert "vat_purchase_total" in PACKAGE
    assert "bank_inflows" in PACKAGE
    assert "bank_outflows" in PACKAGE
    assert "balanced" in PACKAGE


def test_idempotent_bookkeeping_and_duplicate_detection():
    assert "idempotency_audit" in PACKAGE
    assert "idempotency_key" in PACKAGE
    assert "duplicate_detected" in PACKAGE
    assert "already_posted" in PACKAGE


def test_auto_post_lock_and_fail_closed_gates():
    assert "auto_post_allowed" in PACKAGE
    for marker in ["missing_context", "uncertainty_markers", "cross_domain_collisions", "BLOCK_AND_ALERT", "TRIAGE_QUEUE", "manual_review"]:
        assert marker in PACKAGE


def test_property_invariants_present():
    assert "property_invariants" in PACKAGE
    assert "invariant_failed" in PACKAGE
    assert "storno_negative" in PACKAGE
    assert "amount_non_negative" in PACKAGE


def test_temporal_and_boundary_contract_is_externalized():
    assert "evaluation_date" in PACKAGE
    assert "evaluation_year" in PACKAGE
    assert "threshold_version" in PACKAGE
    assert "legal_basis_version" in PACKAGE
    assert "facts_version" in PACKAGE
    assert "pkpir_columns" in PACKAGE
    assert "PLN_HALF_UP_2DP" in PACKAGE


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


def test_gate_marker_coverage_for_accounting_contract():
    markers = [
        "evidence_pack", "column", "chronology", "moment", "nkup", "vehicle",
        "leasing", "wages", "remanent", "storno", "correction", "reconciliation",
        "idempotent", "auto_post", "SUGGEST", "temporal", "boundary",
    ]
    source = (ROOT / "tools" / "pkpir_etap14_audit.py").read_text(encoding="utf-8")
    assert all(marker in source for marker in markers)


def test_native_rego_tests_present_with_negative_temporal_property():
    from tools.pkpir_etap14_audit import native_tests_evidence

    native = native_tests_evidence()
    assert native["present"]
    assert native["complete"]
