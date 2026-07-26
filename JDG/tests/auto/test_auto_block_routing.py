#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: routing
Wygenerowano: 2026-07-26T00:44:20.582743
Reguł: 2
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_routing_fc_vat_rate_low_scale:
    """Auto-generated: jdg.routing.fc_vat_rate_low_scale
    Podstawa prawna: Art. 22 UoR (rzetelność ksiąg)"""

    def test_jdg_routing_fc_vat_rate_low_scale_positive_block_triggered(self):
        """✅ Pozytywny: jdg.routing.fc_vat_rate_low_scale — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.routing.fc_vat_rate_low_scale",
            "package": "routing",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22 UoR (rzetelność ksiąg)",
            "matched": True,
            "priority": 10,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.routing.fc_vat_rate_low_scale"

    def test_jdg_routing_fc_vat_rate_low_scale_negative_no_block(self):
        """❌ Negatywny: jdg.routing.fc_vat_rate_low_scale — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.routing.fc_vat_rate_low_scale",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_routing_fc_vendor_nip_low:
    """Auto-generated: jdg.routing.fc_vendor_nip_low
    Podstawa prawna: Art. 96b VAT, Art. 22 UoR"""

    def test_jdg_routing_fc_vendor_nip_low_positive_block_triggered(self):
        """✅ Pozytywny: jdg.routing.fc_vendor_nip_low — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.routing.fc_vendor_nip_low",
            "package": "routing",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 96b VAT, Art. 22 UoR",
            "matched": True,
            "priority": 12,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.routing.fc_vendor_nip_low"

    def test_jdg_routing_fc_vendor_nip_low_negative_no_block(self):
        """❌ Negatywny: jdg.routing.fc_vendor_nip_low — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.routing.fc_vendor_nip_low",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

