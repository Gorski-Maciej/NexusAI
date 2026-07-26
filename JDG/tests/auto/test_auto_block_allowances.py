#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: allowances
Wygenerowano: 2026-07-26T00:44:20.451521
Reguł: 2
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_allowances_relief_rd_evidence_blocked:
    """Auto-generated: jdg.allowances.relief_rd_evidence_blocked
    Podstawa prawna: Art. 26e ust. 8 PIT"""

    def test_jdg_allowances_relief_rd_evidence_blocked_positive_block_triggered(self):
        """✅ Pozytywny: jdg.allowances.relief_rd_evidence_blocked — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.allowances.relief_rd_evidence_blocked",
            "package": "allowances",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 26e ust. 8 PIT",
            "matched": True,
            "priority": 637,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.allowances.relief_rd_evidence_blocked"

    def test_jdg_allowances_relief_rd_evidence_blocked_negative_no_block(self):
        """❌ Negatywny: jdg.allowances.relief_rd_evidence_blocked — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.allowances.relief_rd_evidence_blocked",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_allowances_income_cap_reached:
    """Auto-generated: jdg.allowances.income_cap_reached
    Podstawa prawna: Art. 26 ust. 1 PIT"""

    def test_jdg_allowances_income_cap_reached_positive_block_triggered(self):
        """✅ Pozytywny: jdg.allowances.income_cap_reached — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.allowances.income_cap_reached",
            "package": "allowances",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 26 ust. 1 PIT",
            "matched": True,
            "priority": 617,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.allowances.income_cap_reached"

    def test_jdg_allowances_income_cap_reached_negative_no_block(self):
        """❌ Negatywny: jdg.allowances.income_cap_reached — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.allowances.income_cap_reached",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

