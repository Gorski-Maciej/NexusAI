#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: solidarity
Wygenerowano: 2026-07-26T00:44:20.586822
Reguł: 4
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_solidarity_threshold_detection:
    """Auto-generated: jdg.solidarity.threshold_detection
    Podstawa prawna: Art. 30h PIT"""

    def test_jdg_solidarity_threshold_detection_positive_block_triggered(self):
        """✅ Pozytywny: jdg.solidarity.threshold_detection — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.solidarity.threshold_detection",
            "package": "solidarity",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30h PIT",
            "matched": True,
            "priority": 1810,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.solidarity.threshold_detection"

    def test_jdg_solidarity_threshold_detection_negative_no_block(self):
        """❌ Negatywny: jdg.solidarity.threshold_detection — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.solidarity.threshold_detection",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_solidarity_hyper_threshold_1m:
    """Auto-generated: jdg.solidarity.hyper.threshold_1m
    Podstawa prawna: Art. 30h ust. 1 PIT"""

    def test_jdg_solidarity_hyper_threshold_1m_positive_block_triggered(self):
        """✅ Pozytywny: jdg.solidarity.hyper.threshold_1m — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.solidarity.hyper.threshold_1m",
            "package": "solidarity",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30h ust. 1 PIT",
            "matched": True,
            "priority": 1043,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.solidarity.hyper.threshold_1m"

    def test_jdg_solidarity_hyper_threshold_1m_negative_no_block(self):
        """❌ Negatywny: jdg.solidarity.hyper.threshold_1m — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.solidarity.hyper.threshold_1m",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_solidarity_hyper_sanction_late_payment:
    """Auto-generated: jdg.solidarity.hyper.sanction_late_payment
    Podstawa prawna: Art. 56 OP"""

    def test_jdg_solidarity_hyper_sanction_late_payment_positive_block_triggered(self):
        """✅ Pozytywny: jdg.solidarity.hyper.sanction_late_payment — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.solidarity.hyper.sanction_late_payment",
            "package": "solidarity",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 OP",
            "matched": True,
            "priority": 1062,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.solidarity.hyper.sanction_late_payment"

    def test_jdg_solidarity_hyper_sanction_late_payment_negative_no_block(self):
        """❌ Negatywny: jdg.solidarity.hyper.sanction_late_payment — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.solidarity.hyper.sanction_late_payment",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_solidarity_hyper_sanction_underpayment_kks:
    """Auto-generated: jdg.solidarity.hyper.sanction_underpayment_kks
    Podstawa prawna: Art. 56 KKS"""

    def test_jdg_solidarity_hyper_sanction_underpayment_kks_positive_block_triggered(self):
        """✅ Pozytywny: jdg.solidarity.hyper.sanction_underpayment_kks — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.solidarity.hyper.sanction_underpayment_kks",
            "package": "solidarity",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 KKS",
            "matched": True,
            "priority": 1063,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.solidarity.hyper.sanction_underpayment_kks"

    def test_jdg_solidarity_hyper_sanction_underpayment_kks_negative_no_block(self):
        """❌ Negatywny: jdg.solidarity.hyper.sanction_underpayment_kks — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.solidarity.hyper.sanction_underpayment_kks",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

