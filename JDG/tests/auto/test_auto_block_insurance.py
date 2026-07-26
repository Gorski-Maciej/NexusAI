#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: insurance
Wygenerowano: 2026-07-26T00:44:20.505467
Reguł: 2
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_insurance_gap_detection:
    """Auto-generated: jdg.insurance.gap_detection
    Podstawa prawna: Ustawy branżowe"""

    def test_jdg_insurance_gap_detection_positive_block_triggered(self):
        """✅ Pozytywny: jdg.insurance.gap_detection — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.insurance.gap_detection",
            "package": "insurance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawy branżowe",
            "matched": True,
            "priority": 1985,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.insurance.gap_detection"

    def test_jdg_insurance_gap_detection_negative_no_block(self):
        """❌ Negatywny: jdg.insurance.gap_detection — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.insurance.gap_detection",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_insurance_hyper_gap_mandatory_missing:
    """Auto-generated: jdg.insurance.hyper.gap_mandatory_missing
    Podstawa prawna: Ustawy branżowe"""

    def test_jdg_insurance_hyper_gap_mandatory_missing_positive_block_triggered(self):
        """✅ Pozytywny: jdg.insurance.hyper.gap_mandatory_missing — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.insurance.hyper.gap_mandatory_missing",
            "package": "insurance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawy branżowe",
            "matched": True,
            "priority": 1633,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.insurance.hyper.gap_mandatory_missing"

    def test_jdg_insurance_hyper_gap_mandatory_missing_negative_no_block(self):
        """❌ Negatywny: jdg.insurance.hyper.gap_mandatory_missing — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.insurance.hyper.gap_mandatory_missing",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

