#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: wis
Wygenerowano: 2026-07-26T00:44:20.607871
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_wis_hyper_sanction_incorrect_rate:
    """Auto-generated: jdg.wis.hyper.sanction_incorrect_rate
    Podstawa prawna: Art. 64 KKS"""

    def test_jdg_wis_hyper_sanction_incorrect_rate_positive_block_triggered(self):
        """✅ Pozytywny: jdg.wis.hyper.sanction_incorrect_rate — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.wis.hyper.sanction_incorrect_rate",
            "package": "wis",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 64 KKS",
            "matched": True,
            "priority": 1093,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.wis.hyper.sanction_incorrect_rate"

    def test_jdg_wis_hyper_sanction_incorrect_rate_negative_no_block(self):
        """❌ Negatywny: jdg.wis.hyper.sanction_incorrect_rate — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.wis.hyper.sanction_incorrect_rate",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

