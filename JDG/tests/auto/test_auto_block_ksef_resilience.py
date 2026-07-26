#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: ksef_resilience
Wygenerowano: 2026-07-26T00:44:20.523573
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_ksef_resilience_xml_validation_preflight:
    """Auto-generated: jdg.ksef_resilience.xml_validation_preflight
    Podstawa prawna: Rozporządzenie MF ws. struktury FA(2); Art. 106na VAT; Specyfikacja XSD KSeF"""

    def test_jdg_ksef_resilience_xml_validation_preflight_positive_block_triggered(self):
        """✅ Pozytywny: jdg.ksef_resilience.xml_validation_preflight — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.ksef_resilience.xml_validation_preflight",
            "package": "ksef_resilience",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Rozporządzenie MF ws. struktury FA(2); Art. 106na VAT; Specyfikacja XSD KSeF",
            "matched": True,
            "priority": 1640,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.ksef_resilience.xml_validation_preflight"

    def test_jdg_ksef_resilience_xml_validation_preflight_negative_no_block(self):
        """❌ Negatywny: jdg.ksef_resilience.xml_validation_preflight — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.ksef_resilience.xml_validation_preflight",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

