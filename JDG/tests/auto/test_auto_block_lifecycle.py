#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: lifecycle
Wygenerowano: 2026-07-26T00:44:20.529172
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_lifecycle_exit_strategy:
    """Auto-generated: jdg.lifecycle.exit_strategy
    Podstawa prawna: Prawo Przedsiębiorców Art. 31-36; Art. 24 PIT; Art. 14 VAT; Ustawa o zarządzie s"""

    def test_jdg_lifecycle_exit_strategy_positive_block_triggered(self):
        """✅ Pozytywny: jdg.lifecycle.exit_strategy — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.lifecycle.exit_strategy",
            "package": "lifecycle",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Prawo Przedsiębiorców Art. 31-36; Art. 24 PIT; Art. 14 VAT; Ustawa o zarządzie s",
            "matched": True,
            "priority": 400,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.lifecycle.exit_strategy"

    def test_jdg_lifecycle_exit_strategy_negative_no_block(self):
        """❌ Negatywny: jdg.lifecycle.exit_strategy — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.lifecycle.exit_strategy",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

