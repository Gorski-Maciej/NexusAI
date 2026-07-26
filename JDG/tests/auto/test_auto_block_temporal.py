#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: temporal
Wygenerowano: 2026-07-26T00:44:20.593670
Reguł: 3
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_temporal_statute_limitations_5yr:
    """Auto-generated: jdg.temporal.statute_limitations_5yr
    Podstawa prawna: Art. 70 § 1 Ordynacja podatkowa"""

    def test_jdg_temporal_statute_limitations_5yr_positive_block_triggered(self):
        """✅ Pozytywny: jdg.temporal.statute_limitations_5yr — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.temporal.statute_limitations_5yr",
            "package": "temporal",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 70 § 1 Ordynacja podatkowa",
            "matched": True,
            "priority": 1600,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.temporal.statute_limitations_5yr"

    def test_jdg_temporal_statute_limitations_5yr_negative_no_block(self):
        """❌ Negatywny: jdg.temporal.statute_limitations_5yr — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.temporal.statute_limitations_5yr",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_temporal_statute_limitations_10yr:
    """Auto-generated: jdg.temporal.statute_limitations_10yr
    Podstawa prawna: Art. 70 § 2 Ordynacja podatkowa (w zw. z art. 44 KKS)"""

    def test_jdg_temporal_statute_limitations_10yr_positive_block_triggered(self):
        """✅ Pozytywny: jdg.temporal.statute_limitations_10yr — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.temporal.statute_limitations_10yr",
            "package": "temporal",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 70 § 2 Ordynacja podatkowa (w zw. z art. 44 KKS)",
            "matched": True,
            "priority": 1602,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.temporal.statute_limitations_10yr"

    def test_jdg_temporal_statute_limitations_10yr_negative_no_block(self):
        """❌ Negatywny: jdg.temporal.statute_limitations_10yr — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.temporal.statute_limitations_10yr",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_temporal_statute_suspended:
    """Auto-generated: jdg.temporal.statute_suspended
    Podstawa prawna: Art. 70 § 6-7 Ordynacja podatkowa"""

    def test_jdg_temporal_statute_suspended_positive_block_triggered(self):
        """✅ Pozytywny: jdg.temporal.statute_suspended — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.temporal.statute_suspended",
            "package": "temporal",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 70 § 6-7 Ordynacja podatkowa",
            "matched": True,
            "priority": 1603,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.temporal.statute_suspended"

    def test_jdg_temporal_statute_suspended_negative_no_block(self):
        """❌ Negatywny: jdg.temporal.statute_suspended — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.temporal.statute_suspended",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

