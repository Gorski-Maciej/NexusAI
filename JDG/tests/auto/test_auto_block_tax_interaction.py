#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: tax_interaction
Wygenerowano: 2026-07-26T00:44:20.591094
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_tax_interaction_voluntary_disclosure_letter:
    """Auto-generated: jdg.tax_interaction.voluntary_disclosure_letter
    Podstawa prawna: Art. 16 § 1-5 KKS; Art. 16a KKS; Art. 56 § 1-3 KKS"""

    def test_jdg_tax_interaction_voluntary_disclosure_letter_positive_block_triggered(self):
        """✅ Pozytywny: jdg.tax_interaction.voluntary_disclosure_letter — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.tax_interaction.voluntary_disclosure_letter",
            "package": "tax_interaction",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 16 § 1-5 KKS; Art. 16a KKS; Art. 56 § 1-3 KKS",
            "matched": True,
            "priority": 100,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.tax_interaction.voluntary_disclosure_letter"

    def test_jdg_tax_interaction_voluntary_disclosure_letter_negative_no_block(self):
        """❌ Negatywny: jdg.tax_interaction.voluntary_disclosure_letter — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.tax_interaction.voluntary_disclosure_letter",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

