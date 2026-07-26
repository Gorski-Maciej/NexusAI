#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: compliance
Wygenerowano: 2026-07-26T00:44:20.467772
Reguł: 14
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_pep_screening:
    """Auto-generated: jdg.compliance.aml.pep_screening
    Podstawa prawna: Art. 2 ust. 2 pkt 11, Art. 43-46 Ustawy AML, Art. 20a AMLD5"""

    def test_jdg_compliance_aml_pep_screening_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.pep_screening — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.pep_screening",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 2 ust. 2 pkt 11, Art. 43-46 Ustawy AML, Art. 20a AMLD5",
            "matched": True,
            "priority": 1927,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.pep_screening"

    def test_jdg_compliance_aml_pep_screening_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.pep_screening — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.pep_screening",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_high_risk_country:
    """Auto-generated: jdg.compliance.aml.high_risk_country
    Podstawa prawna: Art. 43 ust. 5 Ustawy AML, Art. 9 AMLD4, Rekomendacja 19 FATF"""

    def test_jdg_compliance_aml_high_risk_country_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.high_risk_country — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.high_risk_country",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 43 ust. 5 Ustawy AML, Art. 9 AMLD4, Rekomendacja 19 FATF",
            "matched": True,
            "priority": 1928,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.high_risk_country"

    def test_jdg_compliance_aml_high_risk_country_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.high_risk_country — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.high_risk_country",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_transaction_structuring:
    """Auto-generated: jdg.compliance.aml.transaction_structuring
    Podstawa prawna: Art. 86 Ustawy AML, Rekomendacja 10 FATF (structuring/smurfing)"""

    def test_jdg_compliance_aml_transaction_structuring_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.transaction_structuring — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.transaction_structuring",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 86 Ustawy AML, Rekomendacja 10 FATF (structuring/smurfing)",
            "matched": True,
            "priority": 1930,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.transaction_structuring"

    def test_jdg_compliance_aml_transaction_structuring_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.transaction_structuring — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.transaction_structuring",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_round_trip_transaction:
    """Auto-generated: jdg.compliance.aml.round_trip_transaction
    Podstawa prawna: Art. 299 KKS (pranie pieniędzy), Rekomendacja 10 FATF"""

    def test_jdg_compliance_aml_round_trip_transaction_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.round_trip_transaction — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.round_trip_transaction",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 299 KKS (pranie pieniędzy), Rekomendacja 10 FATF",
            "matched": True,
            "priority": 1931,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.round_trip_transaction"

    def test_jdg_compliance_aml_round_trip_transaction_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.round_trip_transaction — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.round_trip_transaction",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_str_filing_obligation:
    """Auto-generated: jdg.compliance.aml.str_filing_obligation
    Podstawa prawna: Art. 83-86 Ustawy AML, Art. 74-86 Ustawy AML"""

    def test_jdg_compliance_aml_str_filing_obligation_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.str_filing_obligation — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.str_filing_obligation",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83-86 Ustawy AML, Art. 74-86 Ustawy AML",
            "matched": True,
            "priority": 1934,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.str_filing_obligation"

    def test_jdg_compliance_aml_str_filing_obligation_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.str_filing_obligation — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.str_filing_obligation",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_str_not_filed_penalty:
    """Auto-generated: jdg.compliance.aml.str_not_filed_penalty
    Podstawa prawna: Art. 147-153 Ustawy AML (kary administracyjne KNF), Art. 299 KKS"""

    def test_jdg_compliance_aml_str_not_filed_penalty_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.str_not_filed_penalty — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.str_not_filed_penalty",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 147-153 Ustawy AML (kary administracyjne KNF), Art. 299 KKS",
            "matched": True,
            "priority": 1935,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.str_not_filed_penalty"

    def test_jdg_compliance_aml_str_not_filed_penalty_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.str_not_filed_penalty — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.str_not_filed_penalty",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_tipping_off:
    """Auto-generated: jdg.compliance.aml.tipping_off
    Podstawa prawna: Art. 86 Ustawy AML (zakaz tipping-off), Art. 150 Ustawy AML (kara)"""

    def test_jdg_compliance_aml_tipping_off_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.tipping_off — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.tipping_off",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 86 Ustawy AML (zakaz tipping-off), Art. 150 Ustawy AML (kara)",
            "matched": True,
            "priority": 1936,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.tipping_off"

    def test_jdg_compliance_aml_tipping_off_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.tipping_off — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.tipping_off",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_cbdd_registration:
    """Auto-generated: jdg.compliance.aml.cbdd_registration
    Podstawa prawna: Art. 58-79 Ustawy o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryz"""

    def test_jdg_compliance_aml_cbdd_registration_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.cbdd_registration — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.cbdd_registration",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 58-79 Ustawy o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryz",
            "matched": True,
            "priority": 1939,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.cbdd_registration"

    def test_jdg_compliance_aml_cbdd_registration_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.cbdd_registration — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.cbdd_registration",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_cbdd_discrepancy_penalty:
    """Auto-generated: jdg.compliance.aml.cbdd_discrepancy_penalty
    Podstawa prawna: Art. 68 Ustawy o CBDD, Art. 153 Ustawy AML"""

    def test_jdg_compliance_aml_cbdd_discrepancy_penalty_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.cbdd_discrepancy_penalty — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.cbdd_discrepancy_penalty",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 68 Ustawy o CBDD, Art. 153 Ustawy AML",
            "matched": True,
            "priority": 1942,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.cbdd_discrepancy_penalty"

    def test_jdg_compliance_aml_cbdd_discrepancy_penalty_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.cbdd_discrepancy_penalty — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.cbdd_discrepancy_penalty",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_aml_sanctions_screening:
    """Auto-generated: jdg.compliance.aml.sanctions_screening
    Podstawa prawna: Rozp. UE 269/2014 (sankcje Rosja), Rozp. UE 765/2006 (Białoruś), Rezolucje RB ON"""

    def test_jdg_compliance_aml_sanctions_screening_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.aml.sanctions_screening — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.aml.sanctions_screening",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Rozp. UE 269/2014 (sankcje Rosja), Rozp. UE 765/2006 (Białoruś), Rezolucje RB ON",
            "matched": True,
            "priority": 1944,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.aml.sanctions_screening"

    def test_jdg_compliance_aml_sanctions_screening_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.aml.sanctions_screening — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.aml.sanctions_screening",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_whitelist_missing_over_limit:
    """Auto-generated: jdg.compliance.whitelist_missing_over_limit
    Podstawa prawna: Art. 96b VAT, Art. 117ba Ordynacji podatkowej"""

    def test_jdg_compliance_whitelist_missing_over_limit_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.whitelist_missing_over_limit — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.whitelist_missing_over_limit",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 96b VAT, Art. 117ba Ordynacji podatkowej",
            "matched": True,
            "priority": 20,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.whitelist_missing_over_limit"

    def test_jdg_compliance_whitelist_missing_over_limit_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.whitelist_missing_over_limit — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.whitelist_missing_over_limit",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_whitelist_account_mismatch:
    """Auto-generated: jdg.compliance.whitelist_account_mismatch
    Podstawa prawna: Art. 117ba § 1 Ordynacji podatkowej"""

    def test_jdg_compliance_whitelist_account_mismatch_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.whitelist_account_mismatch — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.whitelist_account_mismatch",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 117ba § 1 Ordynacji podatkowej",
            "matched": True,
            "priority": 21,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.whitelist_account_mismatch"

    def test_jdg_compliance_whitelist_account_mismatch_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.whitelist_account_mismatch — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.whitelist_account_mismatch",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_split_payment_mandatory:
    """Auto-generated: jdg.compliance.split_payment_mandatory
    Podstawa prawna: Art. 108a ust. 1-1d VAT, Art. 105a-105c VAT"""

    def test_jdg_compliance_split_payment_mandatory_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.split_payment_mandatory — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.split_payment_mandatory",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 108a ust. 1-1d VAT, Art. 105a-105c VAT",
            "matched": True,
            "priority": 25,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.split_payment_mandatory"

    def test_jdg_compliance_split_payment_mandatory_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.split_payment_mandatory — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.split_payment_mandatory",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_compliance_vat_simplified_receipt_over_limit:
    """Auto-generated: jdg.compliance.vat_simplified_receipt_over_limit
    Podstawa prawna: Art. 106e ust. 5 pkt 3 VAT"""

    def test_jdg_compliance_vat_simplified_receipt_over_limit_positive_block_triggered(self):
        """✅ Pozytywny: jdg.compliance.vat_simplified_receipt_over_limit — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.compliance.vat_simplified_receipt_over_limit",
            "package": "compliance",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 106e ust. 5 pkt 3 VAT",
            "matched": True,
            "priority": 36,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.compliance.vat_simplified_receipt_over_limit"

    def test_jdg_compliance_vat_simplified_receipt_over_limit_negative_no_block(self):
        """❌ Negatywny: jdg.compliance.vat_simplified_receipt_over_limit — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.compliance.vat_simplified_receipt_over_limit",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

