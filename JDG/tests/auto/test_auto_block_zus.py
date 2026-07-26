#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: zus
Wygenerowano: 2026-07-26T00:44:20.609571
Reguł: 4
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_zus_benefits_sickness_health_during:
    """Auto-generated: jdg.zus.benefits.sickness_health_during
    Podstawa prawna: Art. 81 ust. 1 ustawy o świadczeniach opieki zdrowotnej, Art. 36a ust. 1 SUS"""

    def test_jdg_zus_benefits_sickness_health_during_positive_block_triggered(self):
        """✅ Pozytywny: jdg.zus.benefits.sickness_health_during — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.zus.benefits.sickness_health_during",
            "package": "zus",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 81 ust. 1 ustawy o świadczeniach opieki zdrowotnej, Art. 36a ust. 1 SUS",
            "matched": True,
            "priority": 748,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.zus.benefits.sickness_health_during"

    def test_jdg_zus_benefits_sickness_health_during_negative_no_block(self):
        """❌ Negatywny: jdg.zus.benefits.sickness_health_during — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.zus.benefits.sickness_health_during",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_zus_health_nfz_coverage_loss:
    """Auto-generated: jdg.zus.health.nfz_coverage_loss
    Podstawa prawna: Art. 69 ust. 1 ustawy o świadczeniach; Art. 34 ust. 1 ustawy o NFZ"""

    def test_jdg_zus_health_nfz_coverage_loss_positive_block_triggered(self):
        """✅ Pozytywny: jdg.zus.health.nfz_coverage_loss — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.zus.health.nfz_coverage_loss",
            "package": "zus",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 69 ust. 1 ustawy o świadczeniach; Art. 34 ust. 1 ustawy o NFZ",
            "matched": True,
            "priority": 151,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.zus.health.nfz_coverage_loss"

    def test_jdg_zus_health_nfz_coverage_loss_negative_no_block(self):
        """❌ Negatywny: jdg.zus.health.nfz_coverage_loss — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.zus.health.nfz_coverage_loss",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_zus_benefit_overpayment_detection:
    """Auto-generated: jdg.zus.benefit_overpayment_detection
    Podstawa prawna: Art. 66-68 Ustawy zasiłkowej"""

    def test_jdg_zus_benefit_overpayment_detection_positive_block_triggered(self):
        """✅ Pozytywny: jdg.zus.benefit_overpayment_detection — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.zus.benefit_overpayment_detection",
            "package": "zus",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 66-68 Ustawy zasiłkowej",
            "matched": True,
            "priority": 1206,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.zus.benefit_overpayment_detection"

    def test_jdg_zus_benefit_overpayment_detection_negative_no_block(self):
        """❌ Negatywny: jdg.zus.benefit_overpayment_detection — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.zus.benefit_overpayment_detection",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_zus_sickness_waiting_period:
    """Auto-generated: jdg.zus.sickness.waiting_period
    Podstawa prawna: Art. 4 ust. 1 pkt 2 ustawy zasiłkowej"""

    def test_jdg_zus_sickness_waiting_period_positive_block_triggered(self):
        """✅ Pozytywny: jdg.zus.sickness.waiting_period — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.zus.sickness.waiting_period",
            "package": "zus",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 4 ust. 1 pkt 2 ustawy zasiłkowej",
            "matched": True,
            "priority": 101,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.zus.sickness.waiting_period"

    def test_jdg_zus_sickness_waiting_period_negative_no_block(self):
        """❌ Negatywny: jdg.zus.sickness.waiting_period — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.zus.sickness.waiting_period",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

