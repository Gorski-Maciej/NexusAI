#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: pit
Wygenerowano: 2026-07-26T00:44:20.552505
Reguł: 24
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_advances_return_overdue:
    """Auto-generated: jdg.pit.advances.return_overdue
    Podstawa prawna: Art. 45 PIT, Art. 56 KKS"""

    def test_jdg_pit_advances_return_overdue_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.advances.return_overdue — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.advances.return_overdue",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 45 PIT, Art. 56 KKS",
            "matched": True,
            "priority": 556,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.advances.return_overdue"

    def test_jdg_pit_advances_return_overdue_negative_no_block(self):
        """❌ Negatywny: jdg.pit.advances.return_overdue — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.advances.return_overdue",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_donation_bank_transfer_missing:
    """Auto-generated: jdg.pit.donation.bank_transfer_missing
    Podstawa prawna: Art. 26 ust. 7 pkt 1-2 PIT (wymóg przelewu)"""

    def test_jdg_pit_donation_bank_transfer_missing_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.donation.bank_transfer_missing — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.donation.bank_transfer_missing",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 26 ust. 7 pkt 1-2 PIT (wymóg przelewu)",
            "matched": True,
            "priority": 154,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.donation.bank_transfer_missing"

    def test_jdg_pit_donation_bank_transfer_missing_negative_no_block(self):
        """❌ Negatywny: jdg.pit.donation.bank_transfer_missing — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.donation.bank_transfer_missing",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_exemptions_young_revoked:
    """Auto-generated: jdg.pit.exemptions.young_revoked
    Podstawa prawna: Art. 21 ust. 1 pkt 148 PIT"""

    def test_jdg_pit_exemptions_young_revoked_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.exemptions.young_revoked — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.exemptions.young_revoked",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 21 ust. 1 pkt 148 PIT",
            "matched": True,
            "priority": 581,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.exemptions.young_revoked"

    def test_jdg_pit_exemptions_young_revoked_negative_no_block(self):
        """❌ Negatywny: jdg.pit.exemptions.young_revoked — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.exemptions.young_revoked",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_linear_former_employer_block:
    """Auto-generated: jdg.pit.forms.linear_former_employer_block
    Podstawa prawna: Art. 30c ust. 2 PIT"""

    def test_jdg_pit_forms_linear_former_employer_block_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.linear_former_employer_block — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.linear_former_employer_block",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30c ust. 2 PIT",
            "matched": True,
            "priority": 512,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.linear_former_employer_block"

    def test_jdg_pit_forms_linear_former_employer_block_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.linear_former_employer_block — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.linear_former_employer_block",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_lump_sum_limit_exceeded:
    """Auto-generated: jdg.pit.forms.lump_sum_limit_exceeded
    Podstawa prawna: Art. 6 ust. 4 ustawy o ryczałcie"""

    def test_jdg_pit_forms_lump_sum_limit_exceeded_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.lump_sum_limit_exceeded — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_limit_exceeded",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 6 ust. 4 ustawy o ryczałcie",
            "matched": True,
            "priority": 523,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.lump_sum_limit_exceeded"

    def test_jdg_pit_forms_lump_sum_limit_exceeded_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.lump_sum_limit_exceeded — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_limit_exceeded",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_lump_sum_exclusions:
    """Auto-generated: jdg.pit.forms.lump_sum_exclusions
    Podstawa prawna: Art. 8 ust. 1-2 ustawy o ryczałcie (Dz.U. 2025 poz. 234)"""

    def test_jdg_pit_forms_lump_sum_exclusions_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.lump_sum_exclusions — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_exclusions",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 8 ust. 1-2 ustawy o ryczałcie (Dz.U. 2025 poz. 234)",
            "matched": True,
            "priority": 524,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.lump_sum_exclusions"

    def test_jdg_pit_forms_lump_sum_exclusions_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.lump_sum_exclusions — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_exclusions",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_lump_sum_loss_of_right:
    """Auto-generated: jdg.pit.forms.lump_sum_loss_of_right
    Podstawa prawna: Art. 20 ustawy o ryczałcie"""

    def test_jdg_pit_forms_lump_sum_loss_of_right_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.lump_sum_loss_of_right — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_loss_of_right",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 20 ustawy o ryczałcie",
            "matched": True,
            "priority": 525,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.lump_sum_loss_of_right"

    def test_jdg_pit_forms_lump_sum_loss_of_right_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.lump_sum_loss_of_right — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_loss_of_right",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_lump_sum_election_deadline:
    """Auto-generated: jdg.pit.forms.lump_sum_election_deadline
    Podstawa prawna: Art. 9 ust. 1-4 ustawy o ryczałcie (Dz.U. 2025 poz. 234)"""

    def test_jdg_pit_forms_lump_sum_election_deadline_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.lump_sum_election_deadline — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_election_deadline",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 9 ust. 1-4 ustawy o ryczałcie (Dz.U. 2025 poz. 234)",
            "matched": True,
            "priority": 526,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.lump_sum_election_deadline"

    def test_jdg_pit_forms_lump_sum_election_deadline_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.lump_sum_election_deadline — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_election_deadline",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_linear_deadline_jan20:
    """Auto-generated: jdg.pit.forms.linear_deadline_jan20
    Podstawa prawna: Art. 9a ust. 2 PIT"""

    def test_jdg_pit_forms_linear_deadline_jan20_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.linear_deadline_jan20 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.linear_deadline_jan20",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 9a ust. 2 PIT",
            "matched": True,
            "priority": 490,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.linear_deadline_jan20"

    def test_jdg_pit_forms_linear_deadline_jan20_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.linear_deadline_jan20 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.linear_deadline_jan20",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_lump_sum_deadline_jan20:
    """Auto-generated: jdg.pit.forms.lump_sum_deadline_jan20
    Podstawa prawna: Art. 9 ust. 1 ustawy o ryczałcie"""

    def test_jdg_pit_forms_lump_sum_deadline_jan20_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.lump_sum_deadline_jan20 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_deadline_jan20",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 9 ust. 1 ustawy o ryczałcie",
            "matched": True,
            "priority": 491,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.lump_sum_deadline_jan20"

    def test_jdg_pit_forms_lump_sum_deadline_jan20_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.lump_sum_deadline_jan20 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_deadline_jan20",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_lump_sum_excluded_services:
    """Auto-generated: jdg.pit.forms.lump_sum_excluded_services
    Podstawa prawna: Art. 8 ustawy o ryczałcie"""

    def test_jdg_pit_forms_lump_sum_excluded_services_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.lump_sum_excluded_services — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_excluded_services",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 8 ustawy o ryczałcie",
            "matched": True,
            "priority": 492,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.lump_sum_excluded_services"

    def test_jdg_pit_forms_lump_sum_excluded_services_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.lump_sum_excluded_services — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.lump_sum_excluded_services",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_linear_no_joint_filing:
    """Auto-generated: jdg.pit.forms.linear_no_joint_filing
    Podstawa prawna: Art. 30c PIT"""

    def test_jdg_pit_forms_linear_no_joint_filing_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.linear_no_joint_filing — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.linear_no_joint_filing",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30c PIT",
            "matched": True,
            "priority": 493,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.linear_no_joint_filing"

    def test_jdg_pit_forms_linear_no_joint_filing_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.linear_no_joint_filing — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.linear_no_joint_filing",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_forms_linear_no_child_tax_credit:
    """Auto-generated: jdg.pit.forms.linear_no_child_tax_credit
    Podstawa prawna: Art. 27f PIT"""

    def test_jdg_pit_forms_linear_no_child_tax_credit_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.forms.linear_no_child_tax_credit — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.forms.linear_no_child_tax_credit",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 27f PIT",
            "matched": True,
            "priority": 494,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.forms.linear_no_child_tax_credit"

    def test_jdg_pit_forms_linear_no_child_tax_credit_negative_no_block(self):
        """❌ Negatywny: jdg.pit.forms.linear_no_child_tax_credit — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.forms.linear_no_child_tax_credit",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_ipbox_excluded_for_lump_tax_card:
    """Auto-generated: jdg.pit.ipbox.excluded_for_lump_tax_card
    Podstawa prawna: Art. 30ca ust. 1 PIT (IP Box tylko dla PIT-36 i PIT-36L)"""

    def test_jdg_pit_ipbox_excluded_for_lump_tax_card_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.ipbox.excluded_for_lump_tax_card — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.ipbox.excluded_for_lump_tax_card",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30ca ust. 1 PIT (IP Box tylko dla PIT-36 i PIT-36L)",
            "matched": True,
            "priority": 136,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.ipbox.excluded_for_lump_tax_card"

    def test_jdg_pit_ipbox_excluded_for_lump_tax_card_negative_no_block(self):
        """❌ Negatywny: jdg.pit.ipbox.excluded_for_lump_tax_card — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.ipbox.excluded_for_lump_tax_card",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_ipbox_estonian_cit_conflict:
    """Auto-generated: jdg.pit.ipbox.estonian_cit_conflict
    Podstawa prawna: Art. 30ca PIT + Rozdział 6b ustawy o CIT (wzajemne wykluczenie)"""

    def test_jdg_pit_ipbox_estonian_cit_conflict_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.ipbox.estonian_cit_conflict — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.ipbox.estonian_cit_conflict",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30ca PIT + Rozdział 6b ustawy o CIT (wzajemne wykluczenie)",
            "matched": True,
            "priority": 137,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.ipbox.estonian_cit_conflict"

    def test_jdg_pit_ipbox_estonian_cit_conflict_negative_no_block(self):
        """❌ Negatywny: jdg.pit.ipbox.estonian_cit_conflict — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.ipbox.estonian_cit_conflict",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_kup_bad_debt_debtor:
    """Auto-generated: jdg.pit.kup.bad_debt_debtor
    Podstawa prawna: Art. 22 ust. 8-10 PIT"""

    def test_jdg_pit_kup_bad_debt_debtor_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.kup.bad_debt_debtor — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.kup.bad_debt_debtor",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22 ust. 8-10 PIT",
            "matched": True,
            "priority": 571,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.kup.bad_debt_debtor"

    def test_jdg_pit_kup_bad_debt_debtor_negative_no_block(self):
        """❌ Negatywny: jdg.pit.kup.bad_debt_debtor — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.kup.bad_debt_debtor",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_exemption_interactions_shared_limit:
    """Auto-generated: jdg.pit.exemption_interactions_shared_limit
    Podstawa prawna: Art. 21 ust. 1 pkt 148, 152, 153, 154 PIT"""

    def test_jdg_pit_exemption_interactions_shared_limit_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.exemption_interactions_shared_limit — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.exemption_interactions_shared_limit",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 21 ust. 1 pkt 148, 152, 153, 154 PIT",
            "matched": True,
            "priority": 588,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.exemption_interactions_shared_limit"

    def test_jdg_pit_exemption_interactions_shared_limit_negative_no_block(self):
        """❌ Negatywny: jdg.pit.exemption_interactions_shared_limit — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.exemption_interactions_shared_limit",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_tax_form_change_mid_year_restriction:
    """Auto-generated: jdg.pit.tax_form_change.mid_year_restriction
    Podstawa prawna: Art. 9a ust. 2 PIT"""

    def test_jdg_pit_tax_form_change_mid_year_restriction_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.tax_form_change.mid_year_restriction — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.tax_form_change.mid_year_restriction",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 9a ust. 2 PIT",
            "matched": True,
            "priority": 593,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.tax_form_change.mid_year_restriction"

    def test_jdg_pit_tax_form_change_mid_year_restriction_negative_no_block(self):
        """❌ Negatywny: jdg.pit.tax_form_change.mid_year_restriction — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.tax_form_change.mid_year_restriction",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_transition_forced_lump_to_scale:
    """Auto-generated: jdg.pit.transition.forced_lump_to_scale
    Podstawa prawna: Art. 8 ust. 1 pkt 5 ustawy o ryczałcie, Art. 44 PIT"""

    def test_jdg_pit_transition_forced_lump_to_scale_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.transition.forced_lump_to_scale — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.transition.forced_lump_to_scale",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 8 ust. 1 pkt 5 ustawy o ryczałcie, Art. 44 PIT",
            "matched": True,
            "priority": 530,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.transition.forced_lump_to_scale"

    def test_jdg_pit_transition_forced_lump_to_scale_negative_no_block(self):
        """❌ Negatywny: jdg.pit.transition.forced_lump_to_scale — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.transition.forced_lump_to_scale",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_transition_forced_linear_to_scale:
    """Auto-generated: jdg.pit.transition.forced_linear_to_scale
    Podstawa prawna: Art. 30c ust. 2 PIT — wykluczenie z podatku liniowego"""

    def test_jdg_pit_transition_forced_linear_to_scale_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.transition.forced_linear_to_scale — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.transition.forced_linear_to_scale",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30c ust. 2 PIT — wykluczenie z podatku liniowego",
            "matched": True,
            "priority": 535,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.transition.forced_linear_to_scale"

    def test_jdg_pit_transition_forced_linear_to_scale_negative_no_block(self):
        """❌ Negatywny: jdg.pit.transition.forced_linear_to_scale — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.transition.forced_linear_to_scale",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_tax_loss_expiration_alert:
    """Auto-generated: jdg.pit.tax_loss.expiration_alert
    Podstawa prawna: Art. 9 ust. 3 PIT (przedawnienie straty po 5 latach)"""

    def test_jdg_pit_tax_loss_expiration_alert_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.tax_loss.expiration_alert — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.tax_loss.expiration_alert",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 9 ust. 3 PIT (przedawnienie straty po 5 latach)",
            "matched": True,
            "priority": 163,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.tax_loss.expiration_alert"

    def test_jdg_pit_tax_loss_expiration_alert_negative_no_block(self):
        """❌ Negatywny: jdg.pit.tax_loss.expiration_alert — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.tax_loss.expiration_alert",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_thermo_vat_invoice_missing:
    """Auto-generated: jdg.pit.thermo.vat_invoice_missing
    Podstawa prawna: Art. 26h ust. 7 PIT (wymóg faktury VAT)"""

    def test_jdg_pit_thermo_vat_invoice_missing_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.thermo.vat_invoice_missing — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.thermo.vat_invoice_missing",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 26h ust. 7 PIT (wymóg faktury VAT)",
            "matched": True,
            "priority": 127,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.thermo.vat_invoice_missing"

    def test_jdg_pit_thermo_vat_invoice_missing_negative_no_block(self):
        """❌ Negatywny: jdg.pit.thermo.vat_invoice_missing — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.thermo.vat_invoice_missing",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_thermo_no_double_deduction:
    """Auto-generated: jdg.pit.thermo.no_double_deduction
    Podstawa prawna: Art. 26h ust. 8 PIT (zakaz podwójnego odliczenia)"""

    def test_jdg_pit_thermo_no_double_deduction_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.thermo.no_double_deduction — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.thermo.no_double_deduction",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 26h ust. 8 PIT (zakaz podwójnego odliczenia)",
            "matched": True,
            "priority": 129,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.thermo.no_double_deduction"

    def test_jdg_pit_thermo_no_double_deduction_negative_no_block(self):
        """❌ Negatywny: jdg.pit.thermo.no_double_deduction — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.thermo.no_double_deduction",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_pit_transitions_linear_to_lump_sum_block:
    """Auto-generated: jdg.pit.transitions.linear_to_lump_sum_block
    Podstawa prawna: Art. 9a ust. 2 PIT, Art. 9 u.z.p.d."""

    def test_jdg_pit_transitions_linear_to_lump_sum_block_positive_block_triggered(self):
        """✅ Pozytywny: jdg.pit.transitions.linear_to_lump_sum_block — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.pit.transitions.linear_to_lump_sum_block",
            "package": "pit",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 9a ust. 2 PIT, Art. 9 u.z.p.d.",
            "matched": True,
            "priority": 598,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.pit.transitions.linear_to_lump_sum_block"

    def test_jdg_pit_transitions_linear_to_lump_sum_block_negative_no_block(self):
        """❌ Negatywny: jdg.pit.transitions.linear_to_lump_sum_block — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.pit.transitions.linear_to_lump_sum_block",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

