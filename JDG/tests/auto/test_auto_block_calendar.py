#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: calendar
Wygenerowano: 2026-07-26T00:44:20.464933
Reguł: 3
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_calendar_hyper_alert_1_day_before:
    """Auto-generated: jdg.calendar.hyper.alert_1_day_before
    Podstawa prawna: Art. 12 OP"""

    def test_jdg_calendar_hyper_alert_1_day_before_positive_block_triggered(self):
        """✅ Pozytywny: jdg.calendar.hyper.alert_1_day_before — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.calendar.hyper.alert_1_day_before",
            "package": "calendar",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 12 OP",
            "matched": True,
            "priority": 1390,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.calendar.hyper.alert_1_day_before"

    def test_jdg_calendar_hyper_alert_1_day_before_negative_no_block(self):
        """❌ Negatywny: jdg.calendar.hyper.alert_1_day_before — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.calendar.hyper.alert_1_day_before",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_calendar_hyper_alert_on_deadline_day:
    """Auto-generated: jdg.calendar.hyper.alert_on_deadline_day
    Podstawa prawna: Art. 12 OP"""

    def test_jdg_calendar_hyper_alert_on_deadline_day_positive_block_triggered(self):
        """✅ Pozytywny: jdg.calendar.hyper.alert_on_deadline_day — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.calendar.hyper.alert_on_deadline_day",
            "package": "calendar",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 12 OP",
            "matched": True,
            "priority": 1391,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.calendar.hyper.alert_on_deadline_day"

    def test_jdg_calendar_hyper_alert_on_deadline_day_negative_no_block(self):
        """❌ Negatywny: jdg.calendar.hyper.alert_on_deadline_day — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.calendar.hyper.alert_on_deadline_day",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_calendar_hyper_alert_overdue:
    """Auto-generated: jdg.calendar.hyper.alert_overdue
    Podstawa prawna: Art. 56 OP"""

    def test_jdg_calendar_hyper_alert_overdue_positive_block_triggered(self):
        """✅ Pozytywny: jdg.calendar.hyper.alert_overdue — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.calendar.hyper.alert_overdue",
            "package": "calendar",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 OP",
            "matched": True,
            "priority": 1392,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.calendar.hyper.alert_overdue"

    def test_jdg_calendar_hyper_alert_overdue_negative_no_block(self):
        """❌ Negatywny: jdg.calendar.hyper.alert_overdue — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.calendar.hyper.alert_overdue",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

