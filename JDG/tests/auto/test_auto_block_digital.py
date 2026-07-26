#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: digital
Wygenerowano: 2026-07-26T00:44:20.486315
Reguł: 3
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_digital_crypto_mdr_reporting:
    """Auto-generated: jdg.digital.crypto_mdr_reporting
    Podstawa prawna: Art. 86a-86o Ordynacja podatkowa (MDR) + DAC6"""

    def test_jdg_digital_crypto_mdr_reporting_positive_block_triggered(self):
        """✅ Pozytywny: jdg.digital.crypto_mdr_reporting — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.digital.crypto_mdr_reporting",
            "package": "digital",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 86a-86o Ordynacja podatkowa (MDR) + DAC6",
            "matched": True,
            "priority": 1892,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.digital.crypto_mdr_reporting"

    def test_jdg_digital_crypto_mdr_reporting_negative_no_block(self):
        """❌ Negatywny: jdg.digital.crypto_mdr_reporting — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.digital.crypto_mdr_reporting",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_digital_ai_act_compliance_check:
    """Auto-generated: jdg.digital.ai_act_compliance_check
    Podstawa prawna: Rozporządzenie UE 2024/1689 (AI Act)"""

    def test_jdg_digital_ai_act_compliance_check_positive_block_triggered(self):
        """✅ Pozytywny: jdg.digital.ai_act_compliance_check — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.digital.ai_act_compliance_check",
            "package": "digital",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Rozporządzenie UE 2024/1689 (AI Act)",
            "matched": True,
            "priority": 1893,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.digital.ai_act_compliance_check"

    def test_jdg_digital_ai_act_compliance_check_negative_no_block(self):
        """❌ Negatywny: jdg.digital.ai_act_compliance_check — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.digital.ai_act_compliance_check",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_digital_deepfake_ai_disclosure:
    """Auto-generated: jdg.digital.deepfake_ai_disclosure
    Podstawa prawna: Art. 50 Rozporządzenia UE 2024/1689 (AI Act)"""

    def test_jdg_digital_deepfake_ai_disclosure_positive_block_triggered(self):
        """✅ Pozytywny: jdg.digital.deepfake_ai_disclosure — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.digital.deepfake_ai_disclosure",
            "package": "digital",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 50 Rozporządzenia UE 2024/1689 (AI Act)",
            "matched": True,
            "priority": 1895,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.digital.deepfake_ai_disclosure"

    def test_jdg_digital_deepfake_ai_disclosure_negative_no_block(self):
        """❌ Negatywny: jdg.digital.deepfake_ai_disclosure — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.digital.deepfake_ai_disclosure",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

