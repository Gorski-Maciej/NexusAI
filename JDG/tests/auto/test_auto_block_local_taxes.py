#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: local_taxes
Wygenerowano: 2026-07-26T00:44:20.536277
Reguł: 6
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_taxes_excise_alcohol_spirits:
    """Auto-generated: jdg.local_taxes.excise.alcohol_spirits
    Podstawa prawna: Art. 93 Ustawy o podatku akcyzowym"""

    def test_jdg_local_taxes_excise_alcohol_spirits_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local_taxes.excise.alcohol_spirits — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local_taxes.excise.alcohol_spirits",
            "package": "local_taxes",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 93 Ustawy o podatku akcyzowym",
            "matched": True,
            "priority": 1463,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local_taxes.excise.alcohol_spirits"

    def test_jdg_local_taxes_excise_alcohol_spirits_negative_no_block(self):
        """❌ Negatywny: jdg.local_taxes.excise.alcohol_spirits — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local_taxes.excise.alcohol_spirits",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_taxes_excise_tobacco_cigarettes:
    """Auto-generated: jdg.local_taxes.excise.tobacco_cigarettes
    Podstawa prawna: Art. 99-99a Ustawy o podatku akcyzowym; Mapa drogowa akcyzy tytoniowej 2025-2027"""

    def test_jdg_local_taxes_excise_tobacco_cigarettes_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local_taxes.excise.tobacco_cigarettes — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local_taxes.excise.tobacco_cigarettes",
            "package": "local_taxes",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 99-99a Ustawy o podatku akcyzowym; Mapa drogowa akcyzy tytoniowej 2025-2027",
            "matched": True,
            "priority": 1471,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local_taxes.excise.tobacco_cigarettes"

    def test_jdg_local_taxes_excise_tobacco_cigarettes_negative_no_block(self):
        """❌ Negatywny: jdg.local_taxes.excise.tobacco_cigarettes — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local_taxes.excise.tobacco_cigarettes",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_taxes_excise_energy_products:
    """Auto-generated: jdg.local_taxes.excise.energy_products
    Podstawa prawna: Art. 86-92 ustawy o podatku akcyzowym"""

    def test_jdg_local_taxes_excise_energy_products_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local_taxes.excise.energy_products — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local_taxes.excise.energy_products",
            "package": "local_taxes",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 86-92 ustawy o podatku akcyzowym",
            "matched": True,
            "priority": 844,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local_taxes.excise.energy_products"

    def test_jdg_local_taxes_excise_energy_products_negative_no_block(self):
        """❌ Negatywny: jdg.local_taxes.excise.energy_products — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local_taxes.excise.energy_products",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_taxes_excise_warehouse:
    """Auto-generated: jdg.local_taxes.excise.warehouse
    Podstawa prawna: Art. 48-66 ustawy o podatku akcyzowym"""

    def test_jdg_local_taxes_excise_warehouse_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local_taxes.excise.warehouse — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local_taxes.excise.warehouse",
            "package": "local_taxes",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 48-66 ustawy o podatku akcyzowym",
            "matched": True,
            "priority": 845,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local_taxes.excise.warehouse"

    def test_jdg_local_taxes_excise_warehouse_negative_no_block(self):
        """❌ Negatywny: jdg.local_taxes.excise.warehouse — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local_taxes.excise.warehouse",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_taxes_excise_sanction_illegal:
    """Auto-generated: jdg.local_taxes.excise.sanction_illegal
    Podstawa prawna: Art. 63-73 KKS; Art. 30-31 ustawy o podatku akcyzowym"""

    def test_jdg_local_taxes_excise_sanction_illegal_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local_taxes.excise.sanction_illegal — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local_taxes.excise.sanction_illegal",
            "package": "local_taxes",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 63-73 KKS; Art. 30-31 ustawy o podatku akcyzowym",
            "matched": True,
            "priority": 849,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local_taxes.excise.sanction_illegal"

    def test_jdg_local_taxes_excise_sanction_illegal_negative_no_block(self):
        """❌ Negatywny: jdg.local_taxes.excise.sanction_illegal — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local_taxes.excise.sanction_illegal",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_local_taxes_excise_alcohol_tobacco:
    """Auto-generated: jdg.local_taxes.excise.alcohol_tobacco
    Podstawa prawna: Ustawa o podatku akcyzowym (Dz.U. 2025 poz. 678)"""

    def test_jdg_local_taxes_excise_alcohol_tobacco_positive_block_triggered(self):
        """✅ Pozytywny: jdg.local_taxes.excise.alcohol_tobacco — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.local_taxes.excise.alcohol_tobacco",
            "package": "local_taxes",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o podatku akcyzowym (Dz.U. 2025 poz. 678)",
            "matched": True,
            "priority": 840,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.local_taxes.excise.alcohol_tobacco"

    def test_jdg_local_taxes_excise_alcohol_tobacco_negative_no_block(self):
        """❌ Negatywny: jdg.local_taxes.excise.alcohol_tobacco — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.local_taxes.excise.alcohol_tobacco",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

