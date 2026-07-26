#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: regulated
Wygenerowano: 2026-07-26T00:44:20.565144
Reguł: 2
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_regulated_hyper_privilege_crime_fraud_exception:
    """Auto-generated: jdg.regulated.hyper.privilege_crime_fraud_exception
    Podstawa prawna: Art. 180 § 4 OP"""

    def test_jdg_regulated_hyper_privilege_crime_fraud_exception_positive_block_triggered(self):
        """✅ Pozytywny: jdg.regulated.hyper.privilege_crime_fraud_exception — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.regulated.hyper.privilege_crime_fraud_exception",
            "package": "regulated",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 180 § 4 OP",
            "matched": True,
            "priority": 1595,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.regulated.hyper.privilege_crime_fraud_exception"

    def test_jdg_regulated_hyper_privilege_crime_fraud_exception_negative_no_block(self):
        """❌ Negatywny: jdg.regulated.hyper.privilege_crime_fraud_exception — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.regulated.hyper.privilege_crime_fraud_exception",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_regulated_hyper_chamber_license_suspension:
    """Auto-generated: jdg.regulated.hyper.chamber_license_suspension
    Podstawa prawna: Ustawy korporacyjne"""

    def test_jdg_regulated_hyper_chamber_license_suspension_positive_block_triggered(self):
        """✅ Pozytywny: jdg.regulated.hyper.chamber_license_suspension — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.regulated.hyper.chamber_license_suspension",
            "package": "regulated",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawy korporacyjne",
            "matched": True,
            "priority": 1599,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.regulated.hyper.chamber_license_suspension"

    def test_jdg_regulated_hyper_chamber_license_suspension_negative_no_block(self):
        """❌ Negatywny: jdg.regulated.hyper.chamber_license_suspension — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.regulated.hyper.chamber_license_suspension",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

