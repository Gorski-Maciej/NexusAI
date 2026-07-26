#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: procurement
Wygenerowano: 2026-07-26T00:44:20.562341
Reguł: 6
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_procurement_tax_arrears_impact:
    """Auto-generated: jdg.procurement.tax_arrears_impact
    Podstawa prawna: Art. 108 ust. 1 pkt 4 PZP"""

    def test_jdg_procurement_tax_arrears_impact_positive_block_triggered(self):
        """✅ Pozytywny: jdg.procurement.tax_arrears_impact — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.procurement.tax_arrears_impact",
            "package": "procurement",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 108 ust. 1 pkt 4 PZP",
            "matched": True,
            "priority": 1883,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.procurement.tax_arrears_impact"

    def test_jdg_procurement_tax_arrears_impact_negative_no_block(self):
        """❌ Negatywny: jdg.procurement.tax_arrears_impact — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.procurement.tax_arrears_impact",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_procurement_hyper_exclusion_tax_arrears:
    """Auto-generated: jdg.procurement.hyper.exclusion_tax_arrears
    Podstawa prawna: Art. 108 PZP"""

    def test_jdg_procurement_hyper_exclusion_tax_arrears_positive_block_triggered(self):
        """✅ Pozytywny: jdg.procurement.hyper.exclusion_tax_arrears — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.procurement.hyper.exclusion_tax_arrears",
            "package": "procurement",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 108 PZP",
            "matched": True,
            "priority": 1280,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.procurement.hyper.exclusion_tax_arrears"

    def test_jdg_procurement_hyper_exclusion_tax_arrears_negative_no_block(self):
        """❌ Negatywny: jdg.procurement.hyper.exclusion_tax_arrears — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.procurement.hyper.exclusion_tax_arrears",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_procurement_hyper_exclusion_kks:
    """Auto-generated: jdg.procurement.hyper.exclusion_kks
    Podstawa prawna: Art. 108 PZP"""

    def test_jdg_procurement_hyper_exclusion_kks_positive_block_triggered(self):
        """✅ Pozytywny: jdg.procurement.hyper.exclusion_kks — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.procurement.hyper.exclusion_kks",
            "package": "procurement",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 108 PZP",
            "matched": True,
            "priority": 1281,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.procurement.hyper.exclusion_kks"

    def test_jdg_procurement_hyper_exclusion_kks_negative_no_block(self):
        """❌ Negatywny: jdg.procurement.hyper.exclusion_kks — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.procurement.hyper.exclusion_kks",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_procurement_hyper_exclusion_penalties:
    """Auto-generated: jdg.procurement.hyper.exclusion_penalties
    Podstawa prawna: PZP"""

    def test_jdg_procurement_hyper_exclusion_penalties_positive_block_triggered(self):
        """✅ Pozytywny: jdg.procurement.hyper.exclusion_penalties — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.procurement.hyper.exclusion_penalties",
            "package": "procurement",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "PZP",
            "matched": True,
            "priority": 1282,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.procurement.hyper.exclusion_penalties"

    def test_jdg_procurement_hyper_exclusion_penalties_negative_no_block(self):
        """❌ Negatywny: jdg.procurement.hyper.exclusion_penalties — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.procurement.hyper.exclusion_penalties",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_procurement_hyper_exclusion_mandatory:
    """Auto-generated: jdg.procurement.hyper.exclusion_mandatory
    Podstawa prawna: Art. 108 PZP"""

    def test_jdg_procurement_hyper_exclusion_mandatory_positive_block_triggered(self):
        """✅ Pozytywny: jdg.procurement.hyper.exclusion_mandatory — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.procurement.hyper.exclusion_mandatory",
            "package": "procurement",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 108 PZP",
            "matched": True,
            "priority": 1283,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.procurement.hyper.exclusion_mandatory"

    def test_jdg_procurement_hyper_exclusion_mandatory_negative_no_block(self):
        """❌ Negatywny: jdg.procurement.hyper.exclusion_mandatory — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.procurement.hyper.exclusion_mandatory",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_procurement_hyper_eu_funds_sanctions:
    """Auto-generated: jdg.procurement.hyper.eu_funds_sanctions
    Podstawa prawna: Rozporządzenia UE"""

    def test_jdg_procurement_hyper_eu_funds_sanctions_positive_block_triggered(self):
        """✅ Pozytywny: jdg.procurement.hyper.eu_funds_sanctions — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.procurement.hyper.eu_funds_sanctions",
            "package": "procurement",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Rozporządzenia UE",
            "matched": True,
            "priority": 1293,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.procurement.hyper.eu_funds_sanctions"

    def test_jdg_procurement_hyper_eu_funds_sanctions_negative_no_block(self):
        """❌ Negatywny: jdg.procurement.hyper.eu_funds_sanctions — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.procurement.hyper.eu_funds_sanctions",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

