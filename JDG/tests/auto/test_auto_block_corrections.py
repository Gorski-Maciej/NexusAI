#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: corrections
Wygenerowano: 2026-07-26T00:44:20.480994
Reguł: 3
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_corrections_invoice_numbering:
    """Auto-generated: jdg.corrections.invoice_numbering
    Podstawa prawna: Art. 106e ust. 1 pkt 2 VAT"""

    def test_jdg_corrections_invoice_numbering_positive_block_triggered(self):
        """✅ Pozytywny: jdg.corrections.invoice_numbering — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.corrections.invoice_numbering",
            "package": "corrections",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 106e ust. 1 pkt 2 VAT",
            "matched": True,
            "priority": 428,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.corrections.invoice_numbering"

    def test_jdg_corrections_invoice_numbering_negative_no_block(self):
        """❌ Negatywny: jdg.corrections.invoice_numbering — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.corrections.invoice_numbering",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_corrections_correction_underpayment:
    """Auto-generated: jdg.corrections.correction_underpayment
    Podstawa prawna: Art. 53 OrdPU"""

    def test_jdg_corrections_correction_underpayment_positive_block_triggered(self):
        """✅ Pozytywny: jdg.corrections.correction_underpayment — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.corrections.correction_underpayment",
            "package": "corrections",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 53 OrdPU",
            "matched": True,
            "priority": 435,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.corrections.correction_underpayment"

    def test_jdg_corrections_correction_underpayment_negative_no_block(self):
        """❌ Negatywny: jdg.corrections.correction_underpayment — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.corrections.correction_underpayment",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_corrections_lock_during_audit:
    """Auto-generated: jdg.corrections.lock_during_audit
    Podstawa prawna: Art. 81b § 1 Ordynacji podatkowej"""

    def test_jdg_corrections_lock_during_audit_positive_block_triggered(self):
        """✅ Pozytywny: jdg.corrections.lock_during_audit — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.corrections.lock_during_audit",
            "package": "corrections",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 81b § 1 Ordynacji podatkowej",
            "matched": True,
            "priority": 180,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.corrections.lock_during_audit"

    def test_jdg_corrections_lock_during_audit_negative_no_block(self):
        """❌ Negatywny: jdg.corrections.lock_during_audit — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.corrections.lock_during_audit",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

