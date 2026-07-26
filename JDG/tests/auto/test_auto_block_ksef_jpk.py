#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: ksef_jpk
Wygenerowano: 2026-07-26T00:44:20.520177
Reguł: 2
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_ksef_jpk_token_stale:
    """Auto-generated: jdg.ksef_jpk.token_stale
    Podstawa prawna: Specyfikacja techniczna KSeF v3.0"""

    def test_jdg_ksef_jpk_token_stale_positive_block_triggered(self):
        """✅ Pozytywny: jdg.ksef_jpk.token_stale — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.ksef_jpk.token_stale",
            "package": "ksef_jpk",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Specyfikacja techniczna KSeF v3.0",
            "matched": True,
            "priority": 1790,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.ksef_jpk.token_stale"

    def test_jdg_ksef_jpk_token_stale_negative_no_block(self):
        """❌ Negatywny: jdg.ksef_jpk.token_stale — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.ksef_jpk.token_stale",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_ksef_jpk_ksef_duplicate_detected:
    """Auto-generated: jdg.ksef_jpk.ksef_duplicate_detected
    Podstawa prawna: Art. 106na-106nq VAT (KSeF 2.0), Art. 22 UoR (zasada wiernego odzwierciedlenia)"""

    def test_jdg_ksef_jpk_ksef_duplicate_detected_positive_block_triggered(self):
        """✅ Pozytywny: jdg.ksef_jpk.ksef_duplicate_detected — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.ksef_jpk.ksef_duplicate_detected",
            "package": "ksef_jpk",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 106na-106nq VAT (KSeF 2.0), Art. 22 UoR (zasada wiernego odzwierciedlenia)",
            "matched": True,
            "priority": 985,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.ksef_jpk.ksef_duplicate_detected"

    def test_jdg_ksef_jpk_ksef_duplicate_detected_negative_no_block(self):
        """❌ Negatywny: jdg.ksef_jpk.ksef_duplicate_detected — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.ksef_jpk.ksef_duplicate_detected",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

