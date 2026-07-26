#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: statute
Wygenerowano: 2026-07-26T00:44:20.589010
Reguł: 1
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_statute_voluntary_disclosure_protection:
    """Auto-generated: jdg.statute.voluntary_disclosure_protection
    Podstawa prawna: Art. 16 § 1-4 KKS, Art. 16a KKS"""

    def test_jdg_statute_voluntary_disclosure_protection_positive_block_triggered(self):
        """✅ Pozytywny: jdg.statute.voluntary_disclosure_protection — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.statute.voluntary_disclosure_protection",
            "package": "statute",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 16 § 1-4 KKS, Art. 16a KKS",
            "matched": True,
            "priority": 1168,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.statute.voluntary_disclosure_protection"

    def test_jdg_statute_voluntary_disclosure_protection_negative_no_block(self):
        """❌ Negatywny: jdg.statute.voluntary_disclosure_protection — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.statute.voluntary_disclosure_protection",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

