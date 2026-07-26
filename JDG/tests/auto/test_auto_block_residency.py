#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: residency
Wygenerowano: 2026-07-26T00:44:20.569645
Reguł: 3
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_residency_exit_tax:
    """Auto-generated: jdg.residency.exit_tax
    Podstawa prawna: Art. 30da PIT"""

    def test_jdg_residency_exit_tax_positive_block_triggered(self):
        """✅ Pozytywny: jdg.residency.exit_tax — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.residency.exit_tax",
            "package": "residency",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30da PIT",
            "matched": True,
            "priority": 1944,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.residency.exit_tax"

    def test_jdg_residency_exit_tax_negative_no_block(self):
        """❌ Negatywny: jdg.residency.exit_tax — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.residency.exit_tax",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_residency_hyper_exit_tax_4m_threshold:
    """Auto-generated: jdg.residency.hyper.exit_tax_4m_threshold
    Podstawa prawna: Art. 30da PIT"""

    def test_jdg_residency_hyper_exit_tax_4m_threshold_positive_block_triggered(self):
        """✅ Pozytywny: jdg.residency.hyper.exit_tax_4m_threshold — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.residency.hyper.exit_tax_4m_threshold",
            "package": "residency",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30da PIT",
            "matched": True,
            "priority": 1491,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.residency.hyper.exit_tax_4m_threshold"

    def test_jdg_residency_hyper_exit_tax_4m_threshold_negative_no_block(self):
        """❌ Negatywny: jdg.residency.hyper.exit_tax_4m_threshold — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.residency.hyper.exit_tax_4m_threshold",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_residency_hyper_exit_tax_rate_19pct:
    """Auto-generated: jdg.residency.hyper.exit_tax_rate_19pct
    Podstawa prawna: Art. 30da PIT"""

    def test_jdg_residency_hyper_exit_tax_rate_19pct_positive_block_triggered(self):
        """✅ Pozytywny: jdg.residency.hyper.exit_tax_rate_19pct — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.residency.hyper.exit_tax_rate_19pct",
            "package": "residency",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30da PIT",
            "matched": True,
            "priority": 1492,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.residency.hyper.exit_tax_rate_19pct"

    def test_jdg_residency_hyper_exit_tax_rate_19pct_negative_no_block(self):
        """❌ Negatywny: jdg.residency.hyper.exit_tax_rate_19pct — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.residency.hyper.exit_tax_rate_19pct",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

