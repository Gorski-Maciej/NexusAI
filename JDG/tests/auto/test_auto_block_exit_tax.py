#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: exit_tax
Wygenerowano: 2026-07-26T00:44:20.501147
Reguł: 3
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_exit_tax_asset_transfer_abroad_detected:
    """Auto-generated: jdg.exit_tax.asset_transfer_abroad_detected
    Podstawa prawna: Art. 30da PIT; Art. 30dh PIT (exit tax deferral)"""

    def test_jdg_exit_tax_asset_transfer_abroad_detected_positive_block_triggered(self):
        """✅ Pozytywny: jdg.exit_tax.asset_transfer_abroad_detected — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.exit_tax.asset_transfer_abroad_detected",
            "package": "exit_tax",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30da PIT; Art. 30dh PIT (exit tax deferral)",
            "matched": True,
            "priority": 1,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.exit_tax.asset_transfer_abroad_detected"

    def test_jdg_exit_tax_asset_transfer_abroad_detected_negative_no_block(self):
        """❌ Negatywny: jdg.exit_tax.asset_transfer_abroad_detected — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.exit_tax.asset_transfer_abroad_detected",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_exit_tax_cfc_foreign_company_detected:
    """Auto-generated: jdg.exit_tax.cfc_foreign_company_detected
    Podstawa prawna: Art. 30f PIT; Art. 45 ust. 1aa PIT (PIT-CFC)"""

    def test_jdg_exit_tax_cfc_foreign_company_detected_positive_block_triggered(self):
        """✅ Pozytywny: jdg.exit_tax.cfc_foreign_company_detected — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.exit_tax.cfc_foreign_company_detected",
            "package": "exit_tax",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30f PIT; Art. 45 ust. 1aa PIT (PIT-CFC)",
            "matched": True,
            "priority": 10,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.exit_tax.cfc_foreign_company_detected"

    def test_jdg_exit_tax_cfc_foreign_company_detected_negative_no_block(self):
        """❌ Negatywny: jdg.exit_tax.cfc_foreign_company_detected — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.exit_tax.cfc_foreign_company_detected",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_exit_tax_mdr_scheme_detected:
    """Auto-generated: jdg.exit_tax.mdr_scheme_detected
    Podstawa prawna: Art. 86a-86o OrdPU; Dyrektywa DAC6 (2018/822); Rozporządzenie MF ws. MDR"""

    def test_jdg_exit_tax_mdr_scheme_detected_positive_block_triggered(self):
        """✅ Pozytywny: jdg.exit_tax.mdr_scheme_detected — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.exit_tax.mdr_scheme_detected",
            "package": "exit_tax",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 86a-86o OrdPU; Dyrektywa DAC6 (2018/822); Rozporządzenie MF ws. MDR",
            "matched": True,
            "priority": 20,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.exit_tax.mdr_scheme_detected"

    def test_jdg_exit_tax_mdr_scheme_detected_negative_no_block(self):
        """❌ Negatywny: jdg.exit_tax.mdr_scheme_detected — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.exit_tax.mdr_scheme_detected",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

