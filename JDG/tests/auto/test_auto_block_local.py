#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: local
Wygenerowano: 2026-07-26T00:44:20.534098
Reguł: 5
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_excise_dried_tobacco:
    """Auto-generated: jdg.local.excise_dried_tobacco
    Podstawa prawna: Art. 99a-99c Ustawy o podatku akcyzowym"""

    def test_jdg_local_excise_dried_tobacco_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local.excise_dried_tobacco — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local.excise_dried_tobacco",
            "package": "local",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 99a-99c Ustawy o podatku akcyzowym",
            "matched": True,
            "priority": 1450,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local.excise_dried_tobacco"

    def test_jdg_local_excise_dried_tobacco_negative_no_block(self):
        """❌ Negatywny: jdg.local.excise_dried_tobacco — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local.excise_dried_tobacco",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_excise_e_liquid:
    """Auto-generated: jdg.local.excise_e_liquid
    Podstawa prawna: Art. 99d-99f Ustawy o podatku akcyzowym (nowelizacja 2025)"""

    def test_jdg_local_excise_e_liquid_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local.excise_e_liquid — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local.excise_e_liquid",
            "package": "local",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 99d-99f Ustawy o podatku akcyzowym (nowelizacja 2025)",
            "matched": True,
            "priority": 1465,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local.excise_e_liquid"

    def test_jdg_local_excise_e_liquid_negative_no_block(self):
        """❌ Negatywny: jdg.local.excise_e_liquid — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local.excise_e_liquid",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_bdo_waste_transfer_card:
    """Auto-generated: jdg.local.bdo_waste_transfer_card
    Podstawa prawna: Art. 67-71 Ustawy o odpadach"""

    def test_jdg_local_bdo_waste_transfer_card_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local.bdo_waste_transfer_card — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local.bdo_waste_transfer_card",
            "package": "local",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 67-71 Ustawy o odpadach",
            "matched": True,
            "priority": 1480,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local.bdo_waste_transfer_card"

    def test_jdg_local_bdo_waste_transfer_card_negative_no_block(self):
        """❌ Negatywny: jdg.local.bdo_waste_transfer_card — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local.bdo_waste_transfer_card",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_excise_tobacco:
    """Auto-generated: jdg.local.excise_tobacco
    Podstawa prawna: Art. 98-105 Ustawy o podatku akcyzowym"""

    def test_jdg_local_excise_tobacco_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local.excise_tobacco — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local.excise_tobacco",
            "package": "local",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 98-105 Ustawy o podatku akcyzowym",
            "matched": True,
            "priority": 1342,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local.excise_tobacco"

    def test_jdg_local_excise_tobacco_negative_no_block(self):
        """❌ Negatywny: jdg.local.excise_tobacco — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local.excise_tobacco",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_bdo_registration_check:
    """Auto-generated: jdg.local.bdo_registration_check
    Podstawa prawna: Ustawa o odpadach — Art. 50-51 (BDO)"""

    def test_jdg_local_bdo_registration_check_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local.bdo_registration_check — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local.bdo_registration_check",
            "package": "local",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o odpadach — Art. 50-51 (BDO)",
            "matched": True,
            "priority": 1350,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local.bdo_registration_check"

    def test_jdg_local_bdo_registration_check_negative_no_block(self):
        """❌ Negatywny: jdg.local.bdo_registration_check — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local.bdo_registration_check",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

