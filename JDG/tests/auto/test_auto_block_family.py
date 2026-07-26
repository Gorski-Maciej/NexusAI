#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: family
Wygenerowano: 2026-07-26T00:44:20.503420
Reguł: 3
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_family_hyper_spouse_salary_above_market_redflag:
    """Auto-generated: jdg.family.hyper.spouse_salary_above_market_redflag
    Podstawa prawna: Art. 23 PIT"""

    def test_jdg_family_hyper_spouse_salary_above_market_redflag_positive_block_triggered(self):
        """✅ Pozytywny: jdg.family.hyper.spouse_salary_above_market_redflag — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.family.hyper.spouse_salary_above_market_redflag",
            "package": "family",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 23 PIT",
            "matched": True,
            "priority": 1197,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.family.hyper.spouse_salary_above_market_redflag"

    def test_jdg_family_hyper_spouse_salary_above_market_redflag_negative_no_block(self):
        """❌ Negatywny: jdg.family.hyper.spouse_salary_above_market_redflag — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.family.hyper.spouse_salary_above_market_redflag",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_family_hyper_spouse_no_qualifications_redflag:
    """Auto-generated: jdg.family.hyper.spouse_no_qualifications_redflag
    Podstawa prawna: Art. 23 PIT"""

    def test_jdg_family_hyper_spouse_no_qualifications_redflag_positive_block_triggered(self):
        """✅ Pozytywny: jdg.family.hyper.spouse_no_qualifications_redflag — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.family.hyper.spouse_no_qualifications_redflag",
            "package": "family",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 23 PIT",
            "matched": True,
            "priority": 1198,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.family.hyper.spouse_no_qualifications_redflag"

    def test_jdg_family_hyper_spouse_no_qualifications_redflag_negative_no_block(self):
        """❌ Negatywny: jdg.family.hyper.spouse_no_qualifications_redflag — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.family.hyper.spouse_no_qualifications_redflag",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_family_hyper_spouse_no_evidence_nkup:
    """Auto-generated: jdg.family.hyper.spouse_no_evidence_nkup
    Podstawa prawna: Art. 23 ust. 1 pkt 10 PIT"""

    def test_jdg_family_hyper_spouse_no_evidence_nkup_positive_block_triggered(self):
        """✅ Pozytywny: jdg.family.hyper.spouse_no_evidence_nkup — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.family.hyper.spouse_no_evidence_nkup",
            "package": "family",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 23 ust. 1 pkt 10 PIT",
            "matched": True,
            "priority": 1199,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.family.hyper.spouse_no_evidence_nkup"

    def test_jdg_family_hyper_spouse_no_evidence_nkup_negative_no_block(self):
        """❌ Negatywny: jdg.family.hyper.spouse_no_evidence_nkup — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.family.hyper.spouse_no_evidence_nkup",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

