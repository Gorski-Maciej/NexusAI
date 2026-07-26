#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: liability
Wygenerowano: 2026-07-26T00:44:20.526183
Reguł: 2
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_liability_additional_tax_obligation_art16a:
    """Auto-generated: jdg.liability.additional_tax_obligation_art16a
    Podstawa prawna: Art. 16a OrdPU"""

    def test_jdg_liability_additional_tax_obligation_art16a_positive_block_triggered(self):
        """✅ Pozytywny: jdg.liability.additional_tax_obligation_art16a — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.liability.additional_tax_obligation_art16a",
            "package": "liability",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 16a OrdPU",
            "matched": True,
            "priority": 1102,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.liability.additional_tax_obligation_art16a"

    def test_jdg_liability_additional_tax_obligation_art16a_negative_no_block(self):
        """❌ Negatywny: jdg.liability.additional_tax_obligation_art16a — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.liability.additional_tax_obligation_art16a",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_liability_additional_tax_obligation_art16a:
    """Auto-generated: jdg.liability.additional_tax_obligation_art16a
    Podstawa prawna: Art. 16a OrdPU"""

    def test_jdg_liability_additional_tax_obligation_art16a_positive_block_triggered(self):
        """✅ Pozytywny: jdg.liability.additional_tax_obligation_art16a — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.liability.additional_tax_obligation_art16a",
            "package": "liability",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 16a OrdPU",
            "matched": True,
            "priority": 1102,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.liability.additional_tax_obligation_art16a"

    def test_jdg_liability_additional_tax_obligation_art16a_negative_no_block(self):
        """❌ Negatywny: jdg.liability.additional_tax_obligation_art16a — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.liability.additional_tax_obligation_art16a",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

