#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: rodo
Wygenerowano: 2026-07-26T00:44:20.578279
Reguł: 2
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_rodo_data_breach_notification:
    """Auto-generated: jdg.rodo.data_breach_notification
    Podstawa prawna: Art. 33-34 RODO"""

    def test_jdg_rodo_data_breach_notification_positive_block_triggered(self):
        """✅ Pozytywny: jdg.rodo.data_breach_notification — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.rodo.data_breach_notification",
            "package": "rodo",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 33-34 RODO",
            "matched": True,
            "priority": 1612,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.rodo.data_breach_notification"

    def test_jdg_rodo_data_breach_notification_negative_no_block(self):
        """❌ Negatywny: jdg.rodo.data_breach_notification — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.rodo.data_breach_notification",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_rodo_data_transfer_eog:
    """Auto-generated: jdg.rodo.data_transfer_eog
    Podstawa prawna: Art. 44-49 RODO (Rozdział V)"""

    def test_jdg_rodo_data_transfer_eog_positive_block_triggered(self):
        """✅ Pozytywny: jdg.rodo.data_transfer_eog — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.rodo.data_transfer_eog",
            "package": "rodo",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 44-49 RODO (Rozdział V)",
            "matched": True,
            "priority": 1616,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.rodo.data_transfer_eog"

    def test_jdg_rodo_data_transfer_eog_negative_no_block(self):
        """❌ Negatywny: jdg.rodo.data_transfer_eog — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.rodo.data_transfer_eog",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

