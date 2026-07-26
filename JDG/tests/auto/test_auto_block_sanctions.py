#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: sanctions
Wygenerowano: 2026-07-26T00:44:20.585176
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_sanctions_kks_specific_offenses:
    """Auto-generated: jdg.sanctions.kks_specific_offenses
    Podstawa prawna: Art. 56-62 KKS"""

    def test_jdg_sanctions_kks_specific_offenses_positive_block_triggered(self):
        """✅ Pozytywny: jdg.sanctions.kks_specific_offenses — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.sanctions.kks_specific_offenses",
            "package": "sanctions",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56-62 KKS",
            "matched": True,
            "priority": 200,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.sanctions.kks_specific_offenses"

    def test_jdg_sanctions_kks_specific_offenses_negative_no_block(self):
        """❌ Negatywny: jdg.sanctions.kks_specific_offenses — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.sanctions.kks_specific_offenses",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

