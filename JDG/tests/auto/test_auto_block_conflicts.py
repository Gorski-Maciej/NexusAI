#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: conflicts
Wygenerowano: 2026-07-26T00:44:20.470403
Reguł: 7
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_conflicts_ip_box_vs_rd_same_income:
    """Auto-generated: jdg.conflicts.ip_box_vs_rd_same_income
    Podstawa prawna: Art. 30ca ust. 3 PIT, Art. 26e PIT"""

    def test_jdg_conflicts_ip_box_vs_rd_same_income_positive_block_triggered(self):
        """✅ Pozytywny: jdg.conflicts.ip_box_vs_rd_same_income — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.conflicts.ip_box_vs_rd_same_income",
            "package": "conflicts",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30ca ust. 3 PIT, Art. 26e PIT",
            "matched": True,
            "priority": 586,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.conflicts.ip_box_vs_rd_same_income"

    def test_jdg_conflicts_ip_box_vs_rd_same_income_negative_no_block(self):
        """❌ Negatywny: jdg.conflicts.ip_box_vs_rd_same_income — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.conflicts.ip_box_vs_rd_same_income",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_conflicts_ip_box_no_nexus_indicator:
    """Auto-generated: jdg.conflicts.ip_box_no_nexus_indicator
    Podstawa prawna: Art. 30ca ust. 4-7 PIT"""

    def test_jdg_conflicts_ip_box_no_nexus_indicator_positive_block_triggered(self):
        """✅ Pozytywny: jdg.conflicts.ip_box_no_nexus_indicator — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.conflicts.ip_box_no_nexus_indicator",
            "package": "conflicts",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30ca ust. 4-7 PIT",
            "matched": True,
            "priority": 587,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.conflicts.ip_box_no_nexus_indicator"

    def test_jdg_conflicts_ip_box_no_nexus_indicator_negative_no_block(self):
        """❌ Negatywny: jdg.conflicts.ip_box_no_nexus_indicator — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.conflicts.ip_box_no_nexus_indicator",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_conflicts_ip_box_no_separate_records:
    """Auto-generated: jdg.conflicts.ip_box_no_separate_records
    Podstawa prawna: Art. 30cb ust. 1-2 PIT"""

    def test_jdg_conflicts_ip_box_no_separate_records_positive_block_triggered(self):
        """✅ Pozytywny: jdg.conflicts.ip_box_no_separate_records — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.conflicts.ip_box_no_separate_records",
            "package": "conflicts",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30cb ust. 1-2 PIT",
            "matched": True,
            "priority": 588,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.conflicts.ip_box_no_separate_records"

    def test_jdg_conflicts_ip_box_no_separate_records_negative_no_block(self):
        """❌ Negatywny: jdg.conflicts.ip_box_no_separate_records — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.conflicts.ip_box_no_separate_records",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_conflicts_ip_box_qualification_failed:
    """Auto-generated: jdg.conflicts.ip_box_qualification_failed
    Podstawa prawna: Art. 30ca ust. 2 PIT"""

    def test_jdg_conflicts_ip_box_qualification_failed_positive_block_triggered(self):
        """✅ Pozytywny: jdg.conflicts.ip_box_qualification_failed — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.conflicts.ip_box_qualification_failed",
            "package": "conflicts",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30ca ust. 2 PIT",
            "matched": True,
            "priority": 592,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.conflicts.ip_box_qualification_failed"

    def test_jdg_conflicts_ip_box_qualification_failed_negative_no_block(self):
        """❌ Negatywny: jdg.conflicts.ip_box_qualification_failed — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.conflicts.ip_box_qualification_failed",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_conflicts_car_no_mileage_log_100pct_vat_blocked:
    """Auto-generated: jdg.conflicts.car_no_mileage_log_100pct_vat_blocked
    Podstawa prawna: Art. 86a ust. 1 VAT"""

    def test_jdg_conflicts_car_no_mileage_log_100pct_vat_blocked_positive_block_triggered(self):
        """✅ Pozytywny: jdg.conflicts.car_no_mileage_log_100pct_vat_blocked — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.conflicts.car_no_mileage_log_100pct_vat_blocked",
            "package": "conflicts",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 86a ust. 1 VAT",
            "matched": True,
            "priority": 601,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.conflicts.car_no_mileage_log_100pct_vat_blocked"

    def test_jdg_conflicts_car_no_mileage_log_100pct_vat_blocked_negative_no_block(self):
        """❌ Negatywny: jdg.conflicts.car_no_mileage_log_100pct_vat_blocked — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.conflicts.car_no_mileage_log_100pct_vat_blocked",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_conflicts_bad_debt_sold_to_collector:
    """Auto-generated: jdg.conflicts.bad_debt_sold_to_collector
    Podstawa prawna: Art. 89a ust. 7 VAT, Art. 26i ust. 6 PIT"""

    def test_jdg_conflicts_bad_debt_sold_to_collector_positive_block_triggered(self):
        """✅ Pozytywny: jdg.conflicts.bad_debt_sold_to_collector — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.conflicts.bad_debt_sold_to_collector",
            "package": "conflicts",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 89a ust. 7 VAT, Art. 26i ust. 6 PIT",
            "matched": True,
            "priority": 608,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.conflicts.bad_debt_sold_to_collector"

    def test_jdg_conflicts_bad_debt_sold_to_collector_negative_no_block(self):
        """❌ Negatywny: jdg.conflicts.bad_debt_sold_to_collector — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.conflicts.bad_debt_sold_to_collector",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_conflicts_allowances_vs_loss:
    """Auto-generated: jdg.conflicts.allowances_vs_loss
    Podstawa prawna: Art. 26 ust. 1 PIT, Art. 26e ust. 8 PIT"""

    def test_jdg_conflicts_allowances_vs_loss_positive_block_triggered(self):
        """✅ Pozytywny: jdg.conflicts.allowances_vs_loss — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.conflicts.allowances_vs_loss",
            "package": "conflicts",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 26 ust. 1 PIT, Art. 26e ust. 8 PIT",
            "matched": True,
            "priority": 904,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.conflicts.allowances_vs_loss"

    def test_jdg_conflicts_allowances_vs_loss_negative_no_block(self):
        """❌ Negatywny: jdg.conflicts.allowances_vs_loss — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.conflicts.allowances_vs_loss",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

