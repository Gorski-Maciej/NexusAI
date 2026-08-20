#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.uor_etap15_audit import (
    BUNDLE_PATH,
    PACKAGE_PATH,
    REPORT_PATH,
    build_evidence,
    package_evidence,
)

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = (ROOT / PACKAGE_PATH).read_text(encoding="utf-8")


def test_package_has_all_uor_sections():
    evidence = package_evidence(PACKAGE)
    assert evidence["sections"] == {
        "obligation": True,
        "double_entry": True,
        "documents": True,
        "assets": True,
        "amortization": True,
        "inventory": True,
        "closing": True,
        "financial_stmt": True,
        "transition": True,
        "invariants": True,
    }


def test_uor_obligation_threshold_and_early_warning():
    assert "obligation_audit" in PACKAGE
    assert "uor_required" in PACKAGE
    assert "early_warning" in PACKAGE
    assert "art. 2 ust. 1 pkt 5 UoR" in PACKAGE


def test_double_entry_balance_invariant():
    assert "double_entry_audit" in PACKAGE
    assert "debits_total" in PACKAGE
    assert "credits_total" in PACKAGE
    assert "double_entry_balanced" in PACKAGE
    assert "art. 15 ust. 1 UoR" in PACKAGE


def test_documents_valuation_and_assets_balance():
    assert "document_audit" in PACKAGE
    assert "document_present" in PACKAGE
    assert "assets_audit" in PACKAGE
    assert "balance_ok" in PACKAGE
    assert "art. 21 UoR" in PACKAGE


def test_amortization_bilansowa_vs_podatkowa():
    assert "amortization_audit" in PACKAGE
    assert "amortization_balance" in PACKAGE
    assert "amortization_tax" in PACKAGE
    assert "art. 32 UoR" in PACKAGE
    assert "art. 22a-22n PIT" in PACKAGE


def test_inventory_and_closing_covered():
    assert "inventory_audit" in PACKAGE
    assert "inventory_missing" in PACKAGE
    assert "closing_audit" in PACKAGE
    assert "closing_complete" in PACKAGE
    assert "art. 26 UoR" in PACKAGE


def test_financial_stmt_manual_approval():
    assert "financial_stmt_audit" in PACKAGE
    assert "requires_manual_approval" in PACKAGE
    assert "manual_approval_mandatory" in PACKAGE
    assert "art. 45-49 UoR" in PACKAGE


def test_pkpir_uor_transition_reconciliation_and_idempotency():
    # idempotent transition: the same migration must never be posted twice.
    assert "transition_audit" in PACKAGE
    assert "opening_balance_pln" in PACKAGE
    assert "pkpir_closing_balance" in PACKAGE
    assert "idempotency_key" in PACKAGE
    assert "transition_balanced" in PACKAGE
    assert "transition_already_posted" in PACKAGE


def test_hardcode_and_fake_complete_detection():
    assert "hardcode_scan" in PACKAGE
    assert "coverage_audit" in PACKAGE
    assert "fake_complete" in PACKAGE
    assert "thresholds_externalized" in PACKAGE


def test_property_invariants_present():
    assert "property_invariants" in PACKAGE
    assert "invariant_failed" in PACKAGE
    assert "double_entry_balanced" in PACKAGE
    assert "no_auto_fs_approval" in PACKAGE


def test_temporal_and_boundary_contract_is_externalized():
    assert "evaluation_date" in PACKAGE
    assert "evaluation_year" in PACKAGE
    assert "threshold_version" in PACKAGE
    assert "legal_basis_version" in PACKAGE
    assert "facts_version" in PACKAGE
    assert "uor_threshold_eur" in PACKAGE
    assert "eur_pln_reference" in PACKAGE


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


def test_native_rego_tests_present_with_balance_property():
    from tools.uor_etap15_audit import native_tests_evidence

    native = native_tests_evidence()
    assert native["present"]
    assert native["complete"]
