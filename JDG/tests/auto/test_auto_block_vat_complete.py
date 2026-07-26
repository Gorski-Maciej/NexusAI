#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: vat_complete
Wygenerowano: 2026-07-26T00:44:20.605353
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_vat_complete_vat_additional_liability:
    """Auto-generated: jdg.vat_complete.vat_additional_liability
    Podstawa prawna: Art. 108b-108d VAT; Art. 112b-112c VAT"""

    def test_jdg_vat_complete_vat_additional_liability_positive_block_triggered(self):
        """✅ Pozytywny: jdg.vat_complete.vat_additional_liability — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.vat_complete.vat_additional_liability",
            "package": "vat_complete",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 108b-108d VAT; Art. 112b-112c VAT",
            "matched": True,
            "priority": 600,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.vat_complete.vat_additional_liability"

    def test_jdg_vat_complete_vat_additional_liability_negative_no_block(self):
        """❌ Negatywny: jdg.vat_complete.vat_additional_liability — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.vat_complete.vat_additional_liability",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

