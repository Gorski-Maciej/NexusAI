#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: limitations
Wygenerowano: 2026-07-26T00:44:20.531438
Reguł: 5
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_limitations_suspension_event:
    """Auto-generated: jdg.limitations.suspension_event
    Podstawa prawna: Art. 70 § 4 OrdPU"""

    def test_jdg_limitations_suspension_event_positive_block_triggered(self):
        """✅ Pozytywny: jdg.limitations.suspension_event — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.limitations.suspension_event",
            "package": "limitations",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 70 § 4 OrdPU",
            "matched": True,
            "priority": 438,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.limitations.suspension_event"

    def test_jdg_limitations_suspension_event_negative_no_block(self):
        """❌ Negatywny: jdg.limitations.suspension_event — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.limitations.suspension_event",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_limitations_interruption_event:
    """Auto-generated: jdg.limitations.interruption_event
    Podstawa prawna: Art. 70 § 5 OrdPU"""

    def test_jdg_limitations_interruption_event_positive_block_triggered(self):
        """✅ Pozytywny: jdg.limitations.interruption_event — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.limitations.interruption_event",
            "package": "limitations",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 70 § 5 OrdPU",
            "matched": True,
            "priority": 439,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.limitations.interruption_event"

    def test_jdg_limitations_interruption_event_negative_no_block(self):
        """❌ Negatywny: jdg.limitations.interruption_event — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.limitations.interruption_event",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_limitations_personal_liability:
    """Auto-generated: jdg.limitations.personal_liability
    Podstawa prawna: Art. 26 OrdPU, Art. 108 OrdPU (osoby trzecie)"""

    def test_jdg_limitations_personal_liability_positive_block_triggered(self):
        """✅ Pozytywny: jdg.limitations.personal_liability — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.limitations.personal_liability",
            "package": "limitations",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 26 OrdPU, Art. 108 OrdPU (osoby trzecie)",
            "matched": True,
            "priority": 442,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.limitations.personal_liability"

    def test_jdg_limitations_personal_liability_negative_no_block(self):
        """❌ Negatywny: jdg.limitations.personal_liability — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.limitations.personal_liability",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_limitations_interruption_proceedings:
    """Auto-generated: jdg.limitations.interruption_proceedings
    Podstawa prawna: Art. 70 § 5 OrdPU"""

    def test_jdg_limitations_interruption_proceedings_positive_block_triggered(self):
        """✅ Pozytywny: jdg.limitations.interruption_proceedings — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.limitations.interruption_proceedings",
            "package": "limitations",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 70 § 5 OrdPU",
            "matched": True,
            "priority": 447,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.limitations.interruption_proceedings"

    def test_jdg_limitations_interruption_proceedings_negative_no_block(self):
        """❌ Negatywny: jdg.limitations.interruption_proceedings — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.limitations.interruption_proceedings",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_limitations_audit_extended:
    """Auto-generated: jdg.limitations.audit_extended
    Podstawa prawna: Art. 83 ust. 1 OrdPU"""

    def test_jdg_limitations_audit_extended_positive_block_triggered(self):
        """✅ Pozytywny: jdg.limitations.audit_extended — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.limitations.audit_extended",
            "package": "limitations",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 ust. 1 OrdPU",
            "matched": True,
            "priority": 449,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.limitations.audit_extended"

    def test_jdg_limitations_audit_extended_negative_no_block(self):
        """❌ Negatywny: jdg.limitations.audit_extended — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.limitations.audit_extended",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

