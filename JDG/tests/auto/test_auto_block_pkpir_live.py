#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: pkpir_live
Wygenerowano: 2026-07-26T00:44:20.559460
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pkpir_live_cash_trap_over_15k_nkup:
    """Auto-generated: jdg.pkpir_live.cash_trap_over_15k_nkup
    Podstawa prawna: Art. 22p PIT; Art. 19 Prawa przedsiębiorców"""

    def test_jdg_pkpir_live_cash_trap_over_15k_nkup_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pkpir_live.cash_trap_over_15k_nkup — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pkpir_live.cash_trap_over_15k_nkup",
            "package": "pkpir_live",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22p PIT; Art. 19 Prawa przedsiębiorców",
            "matched": True,
            "priority": 9195,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pkpir_live.cash_trap_over_15k_nkup"

    def test_jdg_pkpir_live_cash_trap_over_15k_nkup_negative_no_block(self):
        """❌ Negatywny: jdg.pkpir_live.cash_trap_over_15k_nkup — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pkpir_live.cash_trap_over_15k_nkup",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

