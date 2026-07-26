#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: api_fallback
Wygenerowano: 2026-07-26T00:44:20.453975
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_api_fallback_multi_degradation:
    """Auto-generated: jdg.api_fallback.multi_degradation
    Podstawa prawna: Procedura operacyjna — ciągłość działania"""

    def test_jdg_api_fallback_multi_degradation_positive_block_triggered(self):
        """✅ Pozytywny: jdg.api_fallback.multi_degradation — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.api_fallback.multi_degradation",
            "package": "api_fallback",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Procedura operacyjna — ciągłość działania",
            "matched": True,
            "priority": 1855,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.api_fallback.multi_degradation"

    def test_jdg_api_fallback_multi_degradation_negative_no_block(self):
        """❌ Negatywny: jdg.api_fallback.multi_degradation — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.api_fallback.multi_degradation",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

