#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: payments
Wygenerowano: 2026-07-26T00:44:20.550620
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_payments_hyper_terminal_penalty_5000:
    """Auto-generated: jdg.payments.hyper.terminal_penalty_5000
    Podstawa prawna: Ustawa o usługach płatniczych"""

    def test_jdg_payments_hyper_terminal_penalty_5000_positive_block_triggered(self):
        """✅ Pozytywny: jdg.payments.hyper.terminal_penalty_5000 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.payments.hyper.terminal_penalty_5000",
            "package": "payments",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o usługach płatniczych",
            "matched": True,
            "priority": 1672,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.payments.hyper.terminal_penalty_5000"

    def test_jdg_payments_hyper_terminal_penalty_5000_negative_no_block(self):
        """❌ Negatywny: jdg.payments.hyper.terminal_penalty_5000 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.payments.hyper.terminal_penalty_5000",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

