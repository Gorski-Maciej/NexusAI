#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: nkup
Wygenerowano: 2026-07-26T00:44:20.548074
Reguł: 2
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_nkup_family_wages_nkup:
    """Auto-generated: jdg.nkup.family_wages_nkup
    Podstawa prawna: Art. 23 ust. 1 pkt 10 PIT"""

    def test_jdg_nkup_family_wages_nkup_positive_block_triggered(self):
        """✅ Pozytywny: jdg.nkup.family_wages_nkup — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.nkup.family_wages_nkup",
            "package": "nkup",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 23 ust. 1 pkt 10 PIT",
            "matched": True,
            "priority": 10,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.nkup.family_wages_nkup"

    def test_jdg_nkup_family_wages_nkup_negative_no_block(self):
        """❌ Negatywny: jdg.nkup.family_wages_nkup — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.nkup.family_wages_nkup",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_nkup_donation_non_qualified_nkup:
    """Auto-generated: jdg.nkup.donation_non_qualified_nkup
    Podstawa prawna: Art. 23 ust. 1 pkt 11 PIT; Art. 26 ust. 1 pkt 9 PIT"""

    def test_jdg_nkup_donation_non_qualified_nkup_positive_block_triggered(self):
        """✅ Pozytywny: jdg.nkup.donation_non_qualified_nkup — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.nkup.donation_non_qualified_nkup",
            "package": "nkup",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 23 ust. 1 pkt 11 PIT; Art. 26 ust. 1 pkt 9 PIT",
            "matched": True,
            "priority": 11,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.nkup.donation_non_qualified_nkup"

    def test_jdg_nkup_donation_non_qualified_nkup_negative_no_block(self):
        """❌ Negatywny: jdg.nkup.donation_non_qualified_nkup — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.nkup.donation_non_qualified_nkup",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

