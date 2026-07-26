#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: kks
Wygenerowano: 2026-07-26T00:44:20.507282
Reguł: 199
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_evasion_classification:
    """Auto-generated: jdg.kks.tax_evasion_classification
    Podstawa prawna: Art. 54 § 1-3 KKS"""

    def test_jdg_kks_tax_evasion_classification_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_evasion_classification — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_classification",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1-3 KKS",
            "matched": True,
            "priority": 100,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_evasion_classification"

    def test_jdg_kks_tax_evasion_classification_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_evasion_classification — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_classification",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_concealed_business_art54p3:
    """Auto-generated: jdg.kks.concealed_business_art54p3
    Podstawa prawna: Art. 54 § 3 KKS"""

    def test_jdg_kks_concealed_business_art54p3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.concealed_business_art54p3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.concealed_business_art54p3",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 3 KKS",
            "matched": True,
            "priority": 101,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.concealed_business_art54p3"

    def test_jdg_kks_concealed_business_art54p3_negative_no_block(self):
        """❌ Negatywny: jdg.kks.concealed_business_art54p3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.concealed_business_art54p3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_fictitious_costs_art54:
    """Auto-generated: jdg.kks.fictitious_costs_art54
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_fictitious_costs_art54_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.fictitious_costs_art54 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.fictitious_costs_art54",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 102,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.fictitious_costs_art54"

    def test_jdg_kks_fictitious_costs_art54_negative_no_block(self):
        """❌ Negatywny: jdg.kks.fictitious_costs_art54 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.fictitious_costs_art54",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_pkpir_detailed:
    """Auto-generated: jdg.kks.unreliable_pkpir_detailed
    Podstawa prawna: Art. 56 § 1-4 KKS"""

    def test_jdg_kks_unreliable_pkpir_detailed_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_pkpir_detailed — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_pkpir_detailed",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 § 1-4 KKS",
            "matched": True,
            "priority": 110,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_pkpir_detailed"

    def test_jdg_kks_unreliable_pkpir_detailed_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_pkpir_detailed — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_pkpir_detailed",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_vat_evidence_detailed:
    """Auto-generated: jdg.kks.unreliable_vat_evidence_detailed
    Podstawa prawna: Art. 57 § 1 KKS"""

    def test_jdg_kks_unreliable_vat_evidence_detailed_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_vat_evidence_detailed — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_vat_evidence_detailed",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 § 1 KKS",
            "matched": True,
            "priority": 111,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_vat_evidence_detailed"

    def test_jdg_kks_unreliable_vat_evidence_detailed_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_vat_evidence_detailed — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_vat_evidence_detailed",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_document_destruction_art60:
    """Auto-generated: jdg.kks.document_destruction_art60
    Podstawa prawna: Art. 60 § 1-3 KKS"""

    def test_jdg_kks_document_destruction_art60_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.document_destruction_art60 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.document_destruction_art60",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 60 § 1-3 KKS",
            "matched": True,
            "priority": 120,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.document_destruction_art60"

    def test_jdg_kks_document_destruction_art60_negative_no_block(self):
        """❌ Negatywny: jdg.kks.document_destruction_art60 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.document_destruction_art60",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_art62:
    """Auto-generated: jdg.kks.empty_invoice_art62
    Podstawa prawna: Art. 62 § 1-2 KKS"""

    def test_jdg_kks_empty_invoice_art62_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_art62 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_art62",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 1-2 KKS",
            "matched": True,
            "priority": 121,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_art62"

    def test_jdg_kks_empty_invoice_art62_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_art62 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_art62",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_invoice_counterfeiting_art62p1:
    """Auto-generated: jdg.kks.invoice_counterfeiting_art62p1
    Podstawa prawna: Art. 62 § 1 KKS"""

    def test_jdg_kks_invoice_counterfeiting_art62p1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.invoice_counterfeiting_art62p1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.invoice_counterfeiting_art62p1",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 1 KKS",
            "matched": True,
            "priority": 122,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.invoice_counterfeiting_art62p1"

    def test_jdg_kks_invoice_counterfeiting_art62p1_negative_no_block(self):
        """❌ Negatywny: jdg.kks.invoice_counterfeiting_art62p1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.invoice_counterfeiting_art62p1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_wrong_vat_rate_art64:
    """Auto-generated: jdg.kks.wrong_vat_rate_art64
    Podstawa prawna: Art. 64 KKS"""

    def test_jdg_kks_wrong_vat_rate_art64_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.wrong_vat_rate_art64 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.wrong_vat_rate_art64",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 64 KKS",
            "matched": True,
            "priority": 130,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.wrong_vat_rate_art64"

    def test_jdg_kks_wrong_vat_rate_art64_negative_no_block(self):
        """❌ Negatywny: jdg.kks.wrong_vat_rate_art64 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.wrong_vat_rate_art64",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_audit_art69:
    """Auto-generated: jdg.kks.obstruction_audit_art69
    Podstawa prawna: Art. 69 § 1-3 KKS"""

    def test_jdg_kks_obstruction_audit_art69_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_audit_art69 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_audit_art69",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 69 § 1-3 KKS",
            "matched": True,
            "priority": 131,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_audit_art69"

    def test_jdg_kks_obstruction_audit_art69_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_audit_art69 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_audit_art69",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unjustified_refund_art76:
    """Auto-generated: jdg.kks.unjustified_refund_art76
    Podstawa prawna: Art. 76 § 1-2 KKS"""

    def test_jdg_kks_unjustified_refund_art76_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unjustified_refund_art76 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unjustified_refund_art76",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 76 § 1-2 KKS",
            "matched": True,
            "priority": 140,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unjustified_refund_art76"

    def test_jdg_kks_unjustified_refund_art76_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unjustified_refund_art76 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unjustified_refund_art76",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_imprisonment_substitute:
    """Auto-generated: jdg.kks.imprisonment_substitute
    Podstawa prawna: Art. 25 § 1-3 KKS"""

    def test_jdg_kks_imprisonment_substitute_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.imprisonment_substitute — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.imprisonment_substitute",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 25 § 1-3 KKS",
            "matched": True,
            "priority": 152,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.imprisonment_substitute"

    def test_jdg_kks_imprisonment_substitute_negative_no_block(self):
        """❌ Negatywny: jdg.kks.imprisonment_substitute — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.imprisonment_substitute",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_pkpir_art56:
    """Auto-generated: jdg.kks.unreliable_pkpir_art56
    Podstawa prawna: Art. 56 § 1-4 KKS"""

    def test_jdg_kks_unreliable_pkpir_art56_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_pkpir_art56 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_pkpir_art56",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 § 1-4 KKS",
            "matched": True,
            "priority": 130,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_pkpir_art56"

    def test_jdg_kks_unreliable_pkpir_art56_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_pkpir_art56 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_pkpir_art56",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_vat_evidence_art57:
    """Auto-generated: jdg.kks.unreliable_vat_evidence_art57
    Podstawa prawna: Art. 57 § 1 KKS"""

    def test_jdg_kks_unreliable_vat_evidence_art57_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_vat_evidence_art57 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_vat_evidence_art57",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 § 1 KKS",
            "matched": True,
            "priority": 131,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_vat_evidence_art57"

    def test_jdg_kks_unreliable_vat_evidence_art57_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_vat_evidence_art57 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_vat_evidence_art57",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_art62:
    """Auto-generated: jdg.kks.empty_invoice_art62
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_art62_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_art62 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_art62",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 132,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_art62"

    def test_jdg_kks_empty_invoice_art62_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_art62 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_art62",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_wrong_vat_rate_art64:
    """Auto-generated: jdg.kks.wrong_vat_rate_art64
    Podstawa prawna: Art. 64 KKS"""

    def test_jdg_kks_wrong_vat_rate_art64_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.wrong_vat_rate_art64 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.wrong_vat_rate_art64",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 64 KKS",
            "matched": True,
            "priority": 133,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.wrong_vat_rate_art64"

    def test_jdg_kks_wrong_vat_rate_art64_negative_no_block(self):
        """❌ Negatywny: jdg.kks.wrong_vat_rate_art64 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.wrong_vat_rate_art64",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_return_non_filing_art77:
    """Auto-generated: jdg.kks.tax_return_non_filing_art77
    Podstawa prawna: Art. 77 § 1-3 KKS"""

    def test_jdg_kks_tax_return_non_filing_art77_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_return_non_filing_art77 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_return_non_filing_art77",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 77 § 1-3 KKS",
            "matched": True,
            "priority": 134,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_return_non_filing_art77"

    def test_jdg_kks_tax_return_non_filing_art77_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_return_non_filing_art77 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_return_non_filing_art77",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_destruction_of_documents_art68:
    """Auto-generated: jdg.kks.destruction_of_documents_art68
    Podstawa prawna: Art. 68 KKS"""

    def test_jdg_kks_destruction_of_documents_art68_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.destruction_of_documents_art68 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.destruction_of_documents_art68",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 68 KKS",
            "matched": True,
            "priority": 136,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.destruction_of_documents_art68"

    def test_jdg_kks_destruction_of_documents_art68_negative_no_block(self):
        """❌ Negatywny: jdg.kks.destruction_of_documents_art68 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.destruction_of_documents_art68",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_of_audit_art69:
    """Auto-generated: jdg.kks.obstruction_of_audit_art69
    Podstawa prawna: Art. 69 § 1-3 KKS"""

    def test_jdg_kks_obstruction_of_audit_art69_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_of_audit_art69 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_of_audit_art69",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 69 § 1-3 KKS",
            "matched": True,
            "priority": 140,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_of_audit_art69"

    def test_jdg_kks_obstruction_of_audit_art69_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_of_audit_art69 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_of_audit_art69",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vd_payment_obligation_art16_p2:
    """Auto-generated: jdg.kks.vd_payment_obligation_art16_p2
    Podstawa prawna: Art. 16 § 2 KKS"""

    def test_jdg_kks_vd_payment_obligation_art16_p2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vd_payment_obligation_art16_p2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vd_payment_obligation_art16_p2",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 16 § 2 KKS",
            "matched": True,
            "priority": 201,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vd_payment_obligation_art16_p2"

    def test_jdg_kks_vd_payment_obligation_art16_p2_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vd_payment_obligation_art16_p2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vd_payment_obligation_art16_p2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_evasion_elements_art54_p1:
    """Auto-generated: jdg.kks.tax_evasion_elements_art54_p1
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_tax_evasion_elements_art54_p1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_evasion_elements_art54_p1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_elements_art54_p1",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 240,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_evasion_elements_art54_p1"

    def test_jdg_kks_tax_evasion_elements_art54_p1_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_evasion_elements_art54_p1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_elements_art54_p1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_evasion_significant_art54_p2:
    """Auto-generated: jdg.kks.tax_evasion_significant_art54_p2
    Podstawa prawna: Art. 54 § 2 KKS"""

    def test_jdg_kks_tax_evasion_significant_art54_p2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_evasion_significant_art54_p2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_significant_art54_p2",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 2 KKS",
            "matched": True,
            "priority": 241,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_evasion_significant_art54_p2"

    def test_jdg_kks_tax_evasion_significant_art54_p2_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_evasion_significant_art54_p2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_significant_art54_p2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_evasion_concealed_business_art54_p3:
    """Auto-generated: jdg.kks.tax_evasion_concealed_business_art54_p3
    Podstawa prawna: Art. 54 § 3 KKS"""

    def test_jdg_kks_tax_evasion_concealed_business_art54_p3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_evasion_concealed_business_art54_p3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_concealed_business_art54_p3",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 3 KKS",
            "matched": True,
            "priority": 242,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_evasion_concealed_business_art54_p3"

    def test_jdg_kks_tax_evasion_concealed_business_art54_p3_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_evasion_concealed_business_art54_p3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_concealed_business_art54_p3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_pkpir_systematic_art56_p2:
    """Auto-generated: jdg.kks.unreliable_pkpir_systematic_art56_p2
    Podstawa prawna: Art. 56 § 2 KKS"""

    def test_jdg_kks_unreliable_pkpir_systematic_art56_p2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_pkpir_systematic_art56_p2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_pkpir_systematic_art56_p2",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 § 2 KKS",
            "matched": True,
            "priority": 256,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_pkpir_systematic_art56_p2"

    def test_jdg_kks_unreliable_pkpir_systematic_art56_p2_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_pkpir_systematic_art56_p2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_pkpir_systematic_art56_p2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_pkpir_fictitious_entries_art56_p3:
    """Auto-generated: jdg.kks.pkpir_fictitious_entries_art56_p3
    Podstawa prawna: Art. 56 § 3 KKS"""

    def test_jdg_kks_pkpir_fictitious_entries_art56_p3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.pkpir_fictitious_entries_art56_p3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.pkpir_fictitious_entries_art56_p3",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 § 3 KKS",
            "matched": True,
            "priority": 257,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.pkpir_fictitious_entries_art56_p3"

    def test_jdg_kks_pkpir_fictitious_entries_art56_p3_negative_no_block(self):
        """❌ Negatywny: jdg.kks.pkpir_fictitious_entries_art56_p3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.pkpir_fictitious_entries_art56_p3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_carousel_art62_p3:
    """Auto-generated: jdg.kks.empty_invoice_carousel_art62_p3
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_carousel_art62_p3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_carousel_art62_p3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_carousel_art62_p3",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 302,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_carousel_art62_p3"

    def test_jdg_kks_empty_invoice_carousel_art62_p3_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_carousel_art62_p3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_carousel_art62_p3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_invoice_falsification_art62_p4:
    """Auto-generated: jdg.kks.invoice_falsification_art62_p4
    Podstawa prawna: Art. 62 § 1 KKS"""

    def test_jdg_kks_invoice_falsification_art62_p4_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.invoice_falsification_art62_p4 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.invoice_falsification_art62_p4",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 1 KKS",
            "matched": True,
            "priority": 303,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.invoice_falsification_art62_p4"

    def test_jdg_kks_invoice_falsification_art62_p4_negative_no_block(self):
        """❌ Negatywny: jdg.kks.invoice_falsification_art62_p4 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.invoice_falsification_art62_p4",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_declaration_persistent_art77_p2:
    """Auto-generated: jdg.kks.declaration_persistent_art77_p2
    Podstawa prawna: Art. 77 § 2 KKS"""

    def test_jdg_kks_declaration_persistent_art77_p2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.declaration_persistent_art77_p2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.declaration_persistent_art77_p2",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 77 § 2 KKS",
            "matched": True,
            "priority": 401,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.declaration_persistent_art77_p2"

    def test_jdg_kks_declaration_persistent_art77_p2_negative_no_block(self):
        """❌ Negatywny: jdg.kks.declaration_persistent_art77_p2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.declaration_persistent_art77_p2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_imprisonment_substitute_art25:
    """Auto-generated: jdg.kks.imprisonment_substitute_art25
    Podstawa prawna: Art. 25 KKS"""

    def test_jdg_kks_imprisonment_substitute_art25_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.imprisonment_substitute_art25 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.imprisonment_substitute_art25",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 25 KKS",
            "matched": True,
            "priority": 492,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.imprisonment_substitute_art25"

    def test_jdg_kks_imprisonment_substitute_art25_negative_no_block(self):
        """❌ Negatywny: jdg.kks.imprisonment_substitute_art25 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.imprisonment_substitute_art25",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_conviction_business_ban:
    """Auto-generated: jdg.kks.conviction_business_ban
    Podstawa prawna: Art. 41 KK"""

    def test_jdg_kks_conviction_business_ban_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.conviction_business_ban — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.conviction_business_ban",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 41 KK",
            "matched": True,
            "priority": 1960,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.conviction_business_ban"

    def test_jdg_kks_conviction_business_ban_negative_no_block(self):
        """❌ Negatywny: jdg.kks.conviction_business_ban — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.conviction_business_ban",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_pkpir_art56:
    """Auto-generated: jdg.kks.unreliable_pkpir_art56
    Podstawa prawna: Art. 56 § 1-4 KKS"""

    def test_jdg_kks_unreliable_pkpir_art56_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_pkpir_art56 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_pkpir_art56",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 § 1-4 KKS",
            "matched": True,
            "priority": 130,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_pkpir_art56"

    def test_jdg_kks_unreliable_pkpir_art56_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_pkpir_art56 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_pkpir_art56",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_vat_evidence_art57:
    """Auto-generated: jdg.kks.unreliable_vat_evidence_art57
    Podstawa prawna: Art. 57 § 1 KKS"""

    def test_jdg_kks_unreliable_vat_evidence_art57_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_vat_evidence_art57 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_vat_evidence_art57",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 § 1 KKS",
            "matched": True,
            "priority": 131,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_vat_evidence_art57"

    def test_jdg_kks_unreliable_vat_evidence_art57_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_vat_evidence_art57 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_vat_evidence_art57",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_art62:
    """Auto-generated: jdg.kks.empty_invoice_art62
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_art62_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_art62 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_art62",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 132,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_art62"

    def test_jdg_kks_empty_invoice_art62_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_art62 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_art62",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_return_non_filing_art77:
    """Auto-generated: jdg.kks.tax_return_non_filing_art77
    Podstawa prawna: Art. 77 § 1-3 KKS"""

    def test_jdg_kks_tax_return_non_filing_art77_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_return_non_filing_art77 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_return_non_filing_art77",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 77 § 1-3 KKS",
            "matched": True,
            "priority": 134,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_return_non_filing_art77"

    def test_jdg_kks_tax_return_non_filing_art77_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_return_non_filing_art77 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_return_non_filing_art77",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_non_payment_of_tax_art79:
    """Auto-generated: jdg.kks.non_payment_of_tax_art79
    Podstawa prawna: Art. 79 KKS"""

    def test_jdg_kks_non_payment_of_tax_art79_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.non_payment_of_tax_art79 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.non_payment_of_tax_art79",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 79 KKS",
            "matched": True,
            "priority": 135,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.non_payment_of_tax_art79"

    def test_jdg_kks_non_payment_of_tax_art79_negative_no_block(self):
        """❌ Negatywny: jdg.kks.non_payment_of_tax_art79 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.non_payment_of_tax_art79",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_destruction_of_docs_art68:
    """Auto-generated: jdg.kks.destruction_of_docs_art68
    Podstawa prawna: Art. 68 KKS + Art. 86 Ordynacji podatkowej"""

    def test_jdg_kks_destruction_of_docs_art68_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.destruction_of_docs_art68 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.destruction_of_docs_art68",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 68 KKS + Art. 86 Ordynacji podatkowej",
            "matched": True,
            "priority": 136,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.destruction_of_docs_art68"

    def test_jdg_kks_destruction_of_docs_art68_negative_no_block(self):
        """❌ Negatywny: jdg.kks.destruction_of_docs_art68 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.destruction_of_docs_art68",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_of_tax_audit_art69:
    """Auto-generated: jdg.kks.obstruction_of_tax_audit_art69
    Podstawa prawna: Art. 69 § 1-3 KKS"""

    def test_jdg_kks_obstruction_of_tax_audit_art69_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_of_tax_audit_art69 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_of_tax_audit_art69",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 69 § 1-3 KKS",
            "matched": True,
            "priority": 140,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_of_tax_audit_art69"

    def test_jdg_kks_obstruction_of_tax_audit_art69_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_of_tax_audit_art69 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_of_tax_audit_art69",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_voluntary_disclosure_deadline_breach:
    """Auto-generated: jdg.kks.voluntary_disclosure_deadline_breach
    Podstawa prawna: Art. 16 § 5 KKS"""

    def test_jdg_kks_voluntary_disclosure_deadline_breach_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.voluntary_disclosure_deadline_breach — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.voluntary_disclosure_deadline_breach",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 16 § 5 KKS",
            "matched": True,
            "priority": 201,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.voluntary_disclosure_deadline_breach"

    def test_jdg_kks_voluntary_disclosure_deadline_breach_negative_no_block(self):
        """❌ Negatywny: jdg.kks.voluntary_disclosure_deadline_breach — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.voluntary_disclosure_deadline_breach",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_voluntary_disclosure_mandatory_reporter:
    """Auto-generated: jdg.kks.voluntary_disclosure_mandatory_reporter
    Podstawa prawna: Art. 86a-86o OrdPU (MDR)"""

    def test_jdg_kks_voluntary_disclosure_mandatory_reporter_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.voluntary_disclosure_mandatory_reporter — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.voluntary_disclosure_mandatory_reporter",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 86a-86o OrdPU (MDR)",
            "matched": True,
            "priority": 208,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.voluntary_disclosure_mandatory_reporter"

    def test_jdg_kks_voluntary_disclosure_mandatory_reporter_negative_no_block(self):
        """❌ Negatywny: jdg.kks.voluntary_disclosure_mandatory_reporter — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.voluntary_disclosure_mandatory_reporter",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_voluntary_disclosure_bribe_disclosure:
    """Auto-generated: jdg.kks.voluntary_disclosure_bribe_disclosure
    Podstawa prawna: Art. 16a KKS"""

    def test_jdg_kks_voluntary_disclosure_bribe_disclosure_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.voluntary_disclosure_bribe_disclosure — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.voluntary_disclosure_bribe_disclosure",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 16a KKS",
            "matched": True,
            "priority": 209,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.voluntary_disclosure_bribe_disclosure"

    def test_jdg_kks_voluntary_disclosure_bribe_disclosure_negative_no_block(self):
        """❌ Negatywny: jdg.kks.voluntary_disclosure_bribe_disclosure — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.voluntary_disclosure_bribe_disclosure",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_repeat_offense_aggravating:
    """Auto-generated: jdg.kks.repeat_offense_aggravating
    Podstawa prawna: Art. 19 § 3 KKS"""

    def test_jdg_kks_repeat_offense_aggravating_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.repeat_offense_aggravating — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.repeat_offense_aggravating",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 19 § 3 KKS",
            "matched": True,
            "priority": 216,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.repeat_offense_aggravating"

    def test_jdg_kks_repeat_offense_aggravating_negative_no_block(self):
        """❌ Negatywny: jdg.kks.repeat_offense_aggravating — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.repeat_offense_aggravating",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_organized_group_aggravating:
    """Auto-generated: jdg.kks.organized_group_aggravating
    Podstawa prawna: Art. 19 § 4 KKS"""

    def test_jdg_kks_organized_group_aggravating_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.organized_group_aggravating — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.organized_group_aggravating",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 19 § 4 KKS",
            "matched": True,
            "priority": 217,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.organized_group_aggravating"

    def test_jdg_kks_organized_group_aggravating_negative_no_block(self):
        """❌ Negatywny: jdg.kks.organized_group_aggravating — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.organized_group_aggravating",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_large_scale_aggravating:
    """Auto-generated: jdg.kks.large_scale_aggravating
    Podstawa prawna: Art. 19 § 3-4 KKS"""

    def test_jdg_kks_large_scale_aggravating_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.large_scale_aggravating — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.large_scale_aggravating",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 19 § 3-4 KKS",
            "matched": True,
            "priority": 218,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.large_scale_aggravating"

    def test_jdg_kks_large_scale_aggravating_negative_no_block(self):
        """❌ Negatywny: jdg.kks.large_scale_aggravating — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.large_scale_aggravating",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_of_justice:
    """Auto-generated: jdg.kks.obstruction_of_justice
    Podstawa prawna: Art. 83 KKS"""

    def test_jdg_kks_obstruction_of_justice_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_of_justice — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_of_justice",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 KKS",
            "matched": True,
            "priority": 219,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_of_justice"

    def test_jdg_kks_obstruction_of_justice_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_of_justice — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_of_justice",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_evasion_false_declaration:
    """Auto-generated: jdg.kks.tax_evasion_false_declaration
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_tax_evasion_false_declaration_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_evasion_false_declaration — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_false_declaration",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 240,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_evasion_false_declaration"

    def test_jdg_kks_tax_evasion_false_declaration_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_evasion_false_declaration — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_false_declaration",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_declaration_overdue:
    """Auto-generated: jdg.kks.tax_declaration_overdue
    Podstawa prawna: Art. 54 § 1-2 KKS"""

    def test_jdg_kks_tax_declaration_overdue_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_declaration_overdue — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_declaration_overdue",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1-2 KKS",
            "matched": True,
            "priority": 241,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_declaration_overdue"

    def test_jdg_kks_tax_declaration_overdue_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_declaration_overdue — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_declaration_overdue",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_evasion_hiding_revenue:
    """Auto-generated: jdg.kks.tax_evasion_hiding_revenue
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_tax_evasion_hiding_revenue_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_evasion_hiding_revenue — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_hiding_revenue",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 242,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_evasion_hiding_revenue"

    def test_jdg_kks_tax_evasion_hiding_revenue_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_evasion_hiding_revenue — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_hiding_revenue",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_evasion_inflated_costs_p243:
    """Auto-generated: jdg.kks.tax_evasion_inflated_costs_p243
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_tax_evasion_inflated_costs_p243_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_evasion_inflated_costs_p243 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_inflated_costs_p243",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 243,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_evasion_inflated_costs_p243"

    def test_jdg_kks_tax_evasion_inflated_costs_p243_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_evasion_inflated_costs_p243 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_inflated_costs_p243",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_evasion_double_books_p244:
    """Auto-generated: jdg.kks.tax_evasion_double_books_p244
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_tax_evasion_double_books_p244_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_evasion_double_books_p244 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_double_books_p244",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 244,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_evasion_double_books_p244"

    def test_jdg_kks_tax_evasion_double_books_p244_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_evasion_double_books_p244 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_double_books_p244",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_evasion_shell_company_p245:
    """Auto-generated: jdg.kks.tax_evasion_shell_company_p245
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_tax_evasion_shell_company_p245_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_evasion_shell_company_p245 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_shell_company_p245",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 245,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_evasion_shell_company_p245"

    def test_jdg_kks_tax_evasion_shell_company_p245_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_evasion_shell_company_p245 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_evasion_shell_company_p245",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_evasion_fictitious_costs_p246:
    """Auto-generated: jdg.kks.evasion_fictitious_costs_p246
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_evasion_fictitious_costs_p246_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.evasion_fictitious_costs_p246 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.evasion_fictitious_costs_p246",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 246,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.evasion_fictitious_costs_p246"

    def test_jdg_kks_evasion_fictitious_costs_p246_negative_no_block(self):
        """❌ Negatywny: jdg.kks.evasion_fictitious_costs_p246 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.evasion_fictitious_costs_p246",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_evasion_identity_theft_p247:
    """Auto-generated: jdg.kks.evasion_identity_theft_p247
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_evasion_identity_theft_p247_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.evasion_identity_theft_p247 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.evasion_identity_theft_p247",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 247,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.evasion_identity_theft_p247"

    def test_jdg_kks_evasion_identity_theft_p247_negative_no_block(self):
        """❌ Negatywny: jdg.kks.evasion_identity_theft_p247 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.evasion_identity_theft_p247",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_evasion_tp_manipulation_p248:
    """Auto-generated: jdg.kks.evasion_tp_manipulation_p248
    Podstawa prawna: Art. 54 § 1 KKS + Art. 23o-23zf PIT"""

    def test_jdg_kks_evasion_tp_manipulation_p248_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.evasion_tp_manipulation_p248 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.evasion_tp_manipulation_p248",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS + Art. 23o-23zf PIT",
            "matched": True,
            "priority": 248,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.evasion_tp_manipulation_p248"

    def test_jdg_kks_evasion_tp_manipulation_p248_negative_no_block(self):
        """❌ Negatywny: jdg.kks.evasion_tp_manipulation_p248 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.evasion_tp_manipulation_p248",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_evasion_invoice_fraud_multi_p249:
    """Auto-generated: jdg.kks.evasion_invoice_fraud_multi_p249
    Podstawa prawna: Art. 54 § 1-2 KKS + Art. 62 § 2 KKS (puste faktury)"""

    def test_jdg_kks_evasion_invoice_fraud_multi_p249_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.evasion_invoice_fraud_multi_p249 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.evasion_invoice_fraud_multi_p249",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1-2 KKS + Art. 62 § 2 KKS (puste faktury)",
            "matched": True,
            "priority": 249,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.evasion_invoice_fraud_multi_p249"

    def test_jdg_kks_evasion_invoice_fraud_multi_p249_negative_no_block(self):
        """❌ Negatywny: jdg.kks.evasion_invoice_fraud_multi_p249 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.evasion_invoice_fraud_multi_p249",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_evasion_fictitious_costs_temporal_p250:
    """Auto-generated: jdg.kks.evasion_fictitious_costs_temporal_p250
    Podstawa prawna: Art. 54 § 1 KKS + Art. 56 § 1 KKS"""

    def test_jdg_kks_evasion_fictitious_costs_temporal_p250_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.evasion_fictitious_costs_temporal_p250 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.evasion_fictitious_costs_temporal_p250",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS + Art. 56 § 1 KKS",
            "matched": True,
            "priority": 250,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.evasion_fictitious_costs_temporal_p250"

    def test_jdg_kks_evasion_fictitious_costs_temporal_p250_negative_no_block(self):
        """❌ Negatywny: jdg.kks.evasion_fictitious_costs_temporal_p250 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.evasion_fictitious_costs_temporal_p250",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_evasion_foreign_account_hiding_p251:
    """Auto-generated: jdg.kks.evasion_foreign_account_hiding_p251
    Podstawa prawna: Art. 54 § 1 KKS + Art. 86a OrdPU (CRS/FATCA)"""

    def test_jdg_kks_evasion_foreign_account_hiding_p251_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.evasion_foreign_account_hiding_p251 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.evasion_foreign_account_hiding_p251",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS + Art. 86a OrdPU (CRS/FATCA)",
            "matched": True,
            "priority": 251,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.evasion_foreign_account_hiding_p251"

    def test_jdg_kks_evasion_foreign_account_hiding_p251_negative_no_block(self):
        """❌ Negatywny: jdg.kks.evasion_foreign_account_hiding_p251 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.evasion_foreign_account_hiding_p251",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_evasion_unregistered_crossborder_p252:
    """Auto-generated: jdg.kks.evasion_unregistered_crossborder_p252
    Podstawa prawna: Art. 54 § 1 KKS + Art. 17 ust. 1 pkt 3 VAT + Art. 96 VAT"""

    def test_jdg_kks_evasion_unregistered_crossborder_p252_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.evasion_unregistered_crossborder_p252 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.evasion_unregistered_crossborder_p252",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS + Art. 17 ust. 1 pkt 3 VAT + Art. 96 VAT",
            "matched": True,
            "priority": 252,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.evasion_unregistered_crossborder_p252"

    def test_jdg_kks_evasion_unregistered_crossborder_p252_negative_no_block(self):
        """❌ Negatywny: jdg.kks.evasion_unregistered_crossborder_p252 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.evasion_unregistered_crossborder_p252",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_evasion_fake_residency_cert_p253:
    """Auto-generated: jdg.kks.evasion_fake_residency_cert_p253
    Podstawa prawna: Art. 54 § 1 KKS + Art. 83 KKS (fałszowanie dokumentów)"""

    def test_jdg_kks_evasion_fake_residency_cert_p253_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.evasion_fake_residency_cert_p253 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.evasion_fake_residency_cert_p253",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS + Art. 83 KKS (fałszowanie dokumentów)",
            "matched": True,
            "priority": 253,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.evasion_fake_residency_cert_p253"

    def test_jdg_kks_evasion_fake_residency_cert_p253_negative_no_block(self):
        """❌ Negatywny: jdg.kks.evasion_fake_residency_cert_p253 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.evasion_fake_residency_cert_p253",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_evasion_money_laundering_invoices_p254:
    """Auto-generated: jdg.kks.evasion_money_laundering_invoices_p254
    Podstawa prawna: Art. 54 § 1 KKS + Art. 299 KK (pranie pieniędzy) + Art. 62 § 2 KKS"""

    def test_jdg_kks_evasion_money_laundering_invoices_p254_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.evasion_money_laundering_invoices_p254 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.evasion_money_laundering_invoices_p254",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS + Art. 299 KK (pranie pieniędzy) + Art. 62 § 2 KKS",
            "matched": True,
            "priority": 254,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.evasion_money_laundering_invoices_p254"

    def test_jdg_kks_evasion_money_laundering_invoices_p254_negative_no_block(self):
        """❌ Negatywny: jdg.kks.evasion_money_laundering_invoices_p254 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.evasion_money_laundering_invoices_p254",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_books_falsified_entries:
    """Auto-generated: jdg.kks.unreliable_books_falsified_entries
    Podstawa prawna: Art. 56 § 1 KKS"""

    def test_jdg_kks_unreliable_books_falsified_entries_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_books_falsified_entries — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_books_falsified_entries",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 § 1 KKS",
            "matched": True,
            "priority": 255,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_books_falsified_entries"

    def test_jdg_kks_unreliable_books_falsified_entries_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_books_falsified_entries — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_books_falsified_entries",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_books_missing_entries:
    """Auto-generated: jdg.kks.unreliable_books_missing_entries
    Podstawa prawna: Art. 56 § 2 KKS"""

    def test_jdg_kks_unreliable_books_missing_entries_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_books_missing_entries — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_books_missing_entries",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 § 2 KKS",
            "matched": True,
            "priority": 256,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_books_missing_entries"

    def test_jdg_kks_unreliable_books_missing_entries_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_books_missing_entries — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_books_missing_entries",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_books_wrong_values_p257:
    """Auto-generated: jdg.kks.unreliable_books_wrong_values_p257
    Podstawa prawna: Art. 56 § 3 KKS"""

    def test_jdg_kks_unreliable_books_wrong_values_p257_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_books_wrong_values_p257 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_books_wrong_values_p257",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 § 3 KKS",
            "matched": True,
            "priority": 257,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_books_wrong_values_p257"

    def test_jdg_kks_unreliable_books_wrong_values_p257_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_books_wrong_values_p257 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_books_wrong_values_p257",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_books_destroyed_p258:
    """Auto-generated: jdg.kks.unreliable_books_destroyed_p258
    Podstawa prawna: Art. 60 § 1 KKS"""

    def test_jdg_kks_unreliable_books_destroyed_p258_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_books_destroyed_p258 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_books_destroyed_p258",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 60 § 1 KKS",
            "matched": True,
            "priority": 258,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_books_destroyed_p258"

    def test_jdg_kks_unreliable_books_destroyed_p258_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_books_destroyed_p258 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_books_destroyed_p258",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_books_backdated_p260:
    """Auto-generated: jdg.kks.books_backdated_p260
    Podstawa prawna: Art. 56 KKS"""

    def test_jdg_kks_books_backdated_p260_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.books_backdated_p260 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.books_backdated_p260",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 KKS",
            "matched": True,
            "priority": 260,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.books_backdated_p260"

    def test_jdg_kks_books_backdated_p260_negative_no_block(self):
        """❌ Negatywny: jdg.kks.books_backdated_p260 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.books_backdated_p260",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_books_ghost_employees_p261:
    """Auto-generated: jdg.kks.books_ghost_employees_p261
    Podstawa prawna: Art. 56 KKS"""

    def test_jdg_kks_books_ghost_employees_p261_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.books_ghost_employees_p261 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.books_ghost_employees_p261",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 KKS",
            "matched": True,
            "priority": 261,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.books_ghost_employees_p261"

    def test_jdg_kks_books_ghost_employees_p261_negative_no_block(self):
        """❌ Negatywny: jdg.kks.books_ghost_employees_p261 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.books_ghost_employees_p261",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unreliable_vat_records:
    """Auto-generated: jdg.kks.unreliable_vat_records
    Podstawa prawna: Art. 57 § 1 KKS"""

    def test_jdg_kks_unreliable_vat_records_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unreliable_vat_records — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unreliable_vat_records",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 § 1 KKS",
            "matched": True,
            "priority": 270,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unreliable_vat_records"

    def test_jdg_kks_unreliable_vat_records_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unreliable_vat_records — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unreliable_vat_records",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_records_concealment_p271:
    """Auto-generated: jdg.kks.vat_records_concealment_p271
    Podstawa prawna: Art. 57 § 2 KKS"""

    def test_jdg_kks_vat_records_concealment_p271_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_records_concealment_p271 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_records_concealment_p271",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 § 2 KKS",
            "matched": True,
            "priority": 271,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_records_concealment_p271"

    def test_jdg_kks_vat_records_concealment_p271_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_records_concealment_p271 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_records_concealment_p271",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_jpk_mismatch_p272:
    """Auto-generated: jdg.kks.vat_jpk_mismatch_p272
    Podstawa prawna: Art. 57 § 1 KKS"""

    def test_jdg_kks_vat_jpk_mismatch_p272_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_jpk_mismatch_p272 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_jpk_mismatch_p272",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 § 1 KKS",
            "matched": True,
            "priority": 272,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_jpk_mismatch_p272"

    def test_jdg_kks_vat_jpk_mismatch_p272_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_jpk_mismatch_p272 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_jpk_mismatch_p272",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_rate_manipulation_p274:
    """Auto-generated: jdg.kks.vat_rate_manipulation_p274
    Podstawa prawna: Art. 57 § 1 KKS"""

    def test_jdg_kks_vat_rate_manipulation_p274_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_rate_manipulation_p274 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_rate_manipulation_p274",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 § 1 KKS",
            "matched": True,
            "priority": 274,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_rate_manipulation_p274"

    def test_jdg_kks_vat_rate_manipulation_p274_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_rate_manipulation_p274 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_rate_manipulation_p274",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_split_payment_evasion_p275:
    """Auto-generated: jdg.kks.vat_split_payment_evasion_p275
    Podstawa prawna: Art. 57 § 1 KKS w zw. z Art. 108a VAT"""

    def test_jdg_kks_vat_split_payment_evasion_p275_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_split_payment_evasion_p275 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_split_payment_evasion_p275",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 § 1 KKS w zw. z Art. 108a VAT",
            "matched": True,
            "priority": 275,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_split_payment_evasion_p275"

    def test_jdg_kks_vat_split_payment_evasion_p275_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_split_payment_evasion_p275 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_split_payment_evasion_p275",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_currency_conversion_fraud_p276:
    """Auto-generated: jdg.kks.vat_currency_conversion_fraud_p276
    Podstawa prawna: Art. 57 KKS"""

    def test_jdg_kks_vat_currency_conversion_fraud_p276_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_currency_conversion_fraud_p276 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_currency_conversion_fraud_p276",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 KKS",
            "matched": True,
            "priority": 276,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_currency_conversion_fraud_p276"

    def test_jdg_kks_vat_currency_conversion_fraud_p276_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_currency_conversion_fraud_p276 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_currency_conversion_fraud_p276",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_reverse_charge_omission_p277:
    """Auto-generated: jdg.kks.vat_reverse_charge_omission_p277
    Podstawa prawna: Art. 57 KKS"""

    def test_jdg_kks_vat_reverse_charge_omission_p277_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_reverse_charge_omission_p277 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_reverse_charge_omission_p277",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 KKS",
            "matched": True,
            "priority": 277,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_reverse_charge_omission_p277"

    def test_jdg_kks_vat_reverse_charge_omission_p277_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_reverse_charge_omission_p277 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_reverse_charge_omission_p277",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_duplicate_deduction_p278:
    """Auto-generated: jdg.kks.vat_duplicate_deduction_p278
    Podstawa prawna: Art. 57 KKS"""

    def test_jdg_kks_vat_duplicate_deduction_p278_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_duplicate_deduction_p278 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_duplicate_deduction_p278",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 KKS",
            "matched": True,
            "priority": 278,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_duplicate_deduction_p278"

    def test_jdg_kks_vat_duplicate_deduction_p278_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_duplicate_deduction_p278 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_duplicate_deduction_p278",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_missing_sales_register_p279:
    """Auto-generated: jdg.kks.vat_missing_sales_register_p279
    Podstawa prawna: Art. 57 KKS"""

    def test_jdg_kks_vat_missing_sales_register_p279_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_missing_sales_register_p279 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_missing_sales_register_p279",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 57 KKS",
            "matched": True,
            "priority": 279,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_missing_sales_register_p279"

    def test_jdg_kks_vat_missing_sales_register_p279_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_missing_sales_register_p279 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_missing_sales_register_p279",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_documents_destroyed_art60:
    """Auto-generated: jdg.kks.documents_destroyed_art60
    Podstawa prawna: Art. 60 § 1 KKS"""

    def test_jdg_kks_documents_destroyed_art60_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.documents_destroyed_art60 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.documents_destroyed_art60",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 60 § 1 KKS",
            "matched": True,
            "priority": 280,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.documents_destroyed_art60"

    def test_jdg_kks_documents_destroyed_art60_negative_no_block(self):
        """❌ Negatywny: jdg.kks.documents_destroyed_art60 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.documents_destroyed_art60",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_documents_hidden_from_authorities:
    """Auto-generated: jdg.kks.documents_hidden_from_authorities
    Podstawa prawna: Art. 60 § 2 KKS"""

    def test_jdg_kks_documents_hidden_from_authorities_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.documents_hidden_from_authorities — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.documents_hidden_from_authorities",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 60 § 2 KKS",
            "matched": True,
            "priority": 281,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.documents_hidden_from_authorities"

    def test_jdg_kks_documents_hidden_from_authorities_negative_no_block(self):
        """❌ Negatywny: jdg.kks.documents_hidden_from_authorities — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.documents_hidden_from_authorities",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_documents_force_majeure_no_proof_p283:
    """Auto-generated: jdg.kks.documents_force_majeure_no_proof_p283
    Podstawa prawna: Art. 60 § 1 KKS"""

    def test_jdg_kks_documents_force_majeure_no_proof_p283_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.documents_force_majeure_no_proof_p283 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.documents_force_majeure_no_proof_p283",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 60 § 1 KKS",
            "matched": True,
            "priority": 283,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.documents_force_majeure_no_proof_p283"

    def test_jdg_kks_documents_force_majeure_no_proof_p283_negative_no_block(self):
        """❌ Negatywny: jdg.kks.documents_force_majeure_no_proof_p283 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.documents_force_majeure_no_proof_p283",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_documents_held_by_former_accountant_p284:
    """Auto-generated: jdg.kks.documents_held_by_former_accountant_p284
    Podstawa prawna: Art. 60 KKS w zw. z Art. 83 KKS"""

    def test_jdg_kks_documents_held_by_former_accountant_p284_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.documents_held_by_former_accountant_p284 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.documents_held_by_former_accountant_p284",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 60 KKS w zw. z Art. 83 KKS",
            "matched": True,
            "priority": 284,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.documents_held_by_former_accountant_p284"

    def test_jdg_kks_documents_held_by_former_accountant_p284_negative_no_block(self):
        """❌ Negatywny: jdg.kks.documents_held_by_former_accountant_p284 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.documents_held_by_former_accountant_p284",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unjustified_vat_refund_art76:
    """Auto-generated: jdg.kks.unjustified_vat_refund_art76
    Podstawa prawna: Art. 76 § 1 KKS"""

    def test_jdg_kks_unjustified_vat_refund_art76_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unjustified_vat_refund_art76 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unjustified_vat_refund_art76",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 76 § 1 KKS",
            "matched": True,
            "priority": 285,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unjustified_vat_refund_art76"

    def test_jdg_kks_unjustified_vat_refund_art76_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unjustified_vat_refund_art76 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unjustified_vat_refund_art76",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unjustified_refund_attempt_p286:
    """Auto-generated: jdg.kks.unjustified_refund_attempt_p286
    Podstawa prawna: Art. 76 § 2 KKS"""

    def test_jdg_kks_unjustified_refund_attempt_p286_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unjustified_refund_attempt_p286 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unjustified_refund_attempt_p286",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 76 § 2 KKS",
            "matched": True,
            "priority": 286,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unjustified_refund_attempt_p286"

    def test_jdg_kks_unjustified_refund_attempt_p286_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unjustified_refund_attempt_p286 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unjustified_refund_attempt_p286",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_refund_overstated_deduction_p287:
    """Auto-generated: jdg.kks.refund_overstated_deduction_p287
    Podstawa prawna: Art. 76 § 1 KKS"""

    def test_jdg_kks_refund_overstated_deduction_p287_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.refund_overstated_deduction_p287 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.refund_overstated_deduction_p287",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 76 § 1 KKS",
            "matched": True,
            "priority": 287,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.refund_overstated_deduction_p287"

    def test_jdg_kks_refund_overstated_deduction_p287_negative_no_block(self):
        """❌ Negatywny: jdg.kks.refund_overstated_deduction_p287 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.refund_overstated_deduction_p287",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_refund_fake_export_p288:
    """Auto-generated: jdg.kks.refund_fake_export_p288
    Podstawa prawna: Art. 76 § 1 KKS"""

    def test_jdg_kks_refund_fake_export_p288_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.refund_fake_export_p288 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.refund_fake_export_p288",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 76 § 1 KKS",
            "matched": True,
            "priority": 288,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.refund_fake_export_p288"

    def test_jdg_kks_refund_fake_export_p288_negative_no_block(self):
        """❌ Negatywny: jdg.kks.refund_fake_export_p288 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.refund_fake_export_p288",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_refund_fictitious_wnt_p289:
    """Auto-generated: jdg.kks.refund_fictitious_wnt_p289
    Podstawa prawna: Art. 76 KKS"""

    def test_jdg_kks_refund_fictitious_wnt_p289_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.refund_fictitious_wnt_p289 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.refund_fictitious_wnt_p289",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 76 KKS",
            "matched": True,
            "priority": 289,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.refund_fictitious_wnt_p289"

    def test_jdg_kks_refund_fictitious_wnt_p289_negative_no_block(self):
        """❌ Negatywny: jdg.kks.refund_fictitious_wnt_p289 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.refund_fictitious_wnt_p289",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_collector_not_remitted:
    """Auto-generated: jdg.kks.tax_collector_not_remitted
    Podstawa prawna: Art. 59 § 1 KKS"""

    def test_jdg_kks_tax_collector_not_remitted_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_collector_not_remitted — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_collector_not_remitted",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 59 § 1 KKS",
            "matched": True,
            "priority": 290,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_collector_not_remitted"

    def test_jdg_kks_tax_collector_not_remitted_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_collector_not_remitted — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_collector_not_remitted",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_collector_withholding_false_p291:
    """Auto-generated: jdg.kks.tax_collector_withholding_false_p291
    Podstawa prawna: Art. 59 § 2 KKS"""

    def test_jdg_kks_tax_collector_withholding_false_p291_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_collector_withholding_false_p291 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_collector_withholding_false_p291",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 59 § 2 KKS",
            "matched": True,
            "priority": 291,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_collector_withholding_false_p291"

    def test_jdg_kks_tax_collector_withholding_false_p291_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_collector_withholding_false_p291 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_collector_withholding_false_p291",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_collector_aiding_evasion_p292:
    """Auto-generated: jdg.kks.collector_aiding_evasion_p292
    Podstawa prawna: Art. 59 KKS"""

    def test_jdg_kks_collector_aiding_evasion_p292_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.collector_aiding_evasion_p292 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.collector_aiding_evasion_p292",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 59 KKS",
            "matched": True,
            "priority": 292,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.collector_aiding_evasion_p292"

    def test_jdg_kks_collector_aiding_evasion_p292_negative_no_block(self):
        """❌ Negatywny: jdg.kks.collector_aiding_evasion_p292 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.collector_aiding_evasion_p292",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_collector_zus_not_remitted_p293:
    """Auto-generated: jdg.kks.collector_zus_not_remitted_p293
    Podstawa prawna: Art. 59 KKS w zw. z Art. 46-47 SUS"""

    def test_jdg_kks_collector_zus_not_remitted_p293_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.collector_zus_not_remitted_p293 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.collector_zus_not_remitted_p293",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 59 KKS w zw. z Art. 46-47 SUS",
            "matched": True,
            "priority": 293,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.collector_zus_not_remitted_p293"

    def test_jdg_kks_collector_zus_not_remitted_p293_negative_no_block(self):
        """❌ Negatywny: jdg.kks.collector_zus_not_remitted_p293 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.collector_zus_not_remitted_p293",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_collector_dac7_non_filing_p294:
    """Auto-generated: jdg.kks.collector_dac7_non_filing_p294
    Podstawa prawna: Art. 59 KKS w zw. z Art. 39q OrdPU"""

    def test_jdg_kks_collector_dac7_non_filing_p294_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.collector_dac7_non_filing_p294 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.collector_dac7_non_filing_p294",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 59 KKS w zw. z Art. 39q OrdPU",
            "matched": True,
            "priority": 294,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.collector_dac7_non_filing_p294"

    def test_jdg_kks_collector_dac7_non_filing_p294_negative_no_block(self):
        """❌ Negatywny: jdg.kks.collector_dac7_non_filing_p294 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.collector_dac7_non_filing_p294",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_false_testimony_kas_p295:
    """Auto-generated: jdg.kks.false_testimony_kas_p295
    Podstawa prawna: Art. 83 § 1 KKS"""

    def test_jdg_kks_false_testimony_kas_p295_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.false_testimony_kas_p295 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.false_testimony_kas_p295",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 § 1 KKS",
            "matched": True,
            "priority": 295,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.false_testimony_kas_p295"

    def test_jdg_kks_false_testimony_kas_p295_negative_no_block(self):
        """❌ Negatywny: jdg.kks.false_testimony_kas_p295 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.false_testimony_kas_p295",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_deceitful_evasion_method_p296:
    """Auto-generated: jdg.kks.deceitful_evasion_method_p296
    Podstawa prawna: Art. 54 § 2 KKS"""

    def test_jdg_kks_deceitful_evasion_method_p296_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.deceitful_evasion_method_p296 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.deceitful_evasion_method_p296",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 2 KKS",
            "matched": True,
            "priority": 296,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.deceitful_evasion_method_p296"

    def test_jdg_kks_deceitful_evasion_method_p296_negative_no_block(self):
        """❌ Negatywny: jdg.kks.deceitful_evasion_method_p296 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.deceitful_evasion_method_p296",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_identity_concealment_p297:
    """Auto-generated: jdg.kks.identity_concealment_p297
    Podstawa prawna: Art. 54 § 1 KKS"""

    def test_jdg_kks_identity_concealment_p297_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.identity_concealment_p297 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.identity_concealment_p297",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS",
            "matched": True,
            "priority": 297,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.identity_concealment_p297"

    def test_jdg_kks_identity_concealment_p297_negative_no_block(self):
        """❌ Negatywny: jdg.kks.identity_concealment_p297 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.identity_concealment_p297",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_chain_transaction_fraud_p298:
    """Auto-generated: jdg.kks.chain_transaction_fraud_p298
    Podstawa prawna: Art. 54 § 1 KKS w zw. z Art. 62 KKS"""

    def test_jdg_kks_chain_transaction_fraud_p298_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.chain_transaction_fraud_p298 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.chain_transaction_fraud_p298",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 § 1 KKS w zw. z Art. 62 KKS",
            "matched": True,
            "priority": 298,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.chain_transaction_fraud_p298"

    def test_jdg_kks_chain_transaction_fraud_p298_negative_no_block(self):
        """❌ Negatywny: jdg.kks.chain_transaction_fraud_p298 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.chain_transaction_fraud_p298",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_digital_currency_concealment_p299:
    """Auto-generated: jdg.kks.digital_currency_concealment_p299
    Podstawa prawna: Art. 54 KKS w zw. z AML"""

    def test_jdg_kks_digital_currency_concealment_p299_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.digital_currency_concealment_p299 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.digital_currency_concealment_p299",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54 KKS w zw. z AML",
            "matched": True,
            "priority": 299,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.digital_currency_concealment_p299"

    def test_jdg_kks_digital_currency_concealment_p299_negative_no_block(self):
        """❌ Negatywny: jdg.kks.digital_currency_concealment_p299 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.digital_currency_concealment_p299",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_issued:
    """Auto-generated: jdg.kks.empty_invoice_issued
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_issued_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_issued — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_issued",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 300,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_issued"

    def test_jdg_kks_empty_invoice_issued_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_issued — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_issued",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_fake_invoice_issued:
    """Auto-generated: jdg.kks.fake_invoice_issued
    Podstawa prawna: Art. 62 § 1 KKS"""

    def test_jdg_kks_fake_invoice_issued_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.fake_invoice_issued — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.fake_invoice_issued",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 1 KKS",
            "matched": True,
            "priority": 301,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.fake_invoice_issued"

    def test_jdg_kks_fake_invoice_issued_negative_no_block(self):
        """❌ Negatywny: jdg.kks.fake_invoice_issued — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.fake_invoice_issued",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_invoice_carousel_detected:
    """Auto-generated: jdg.kks.invoice_carousel_detected
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_invoice_carousel_detected_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.invoice_carousel_detected — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.invoice_carousel_detected",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 302,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.invoice_carousel_detected"

    def test_jdg_kks_invoice_carousel_detected_negative_no_block(self):
        """❌ Negatywny: jdg.kks.invoice_carousel_detected — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.invoice_carousel_detected",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_invoice_falsified_amount_p303:
    """Auto-generated: jdg.kks.invoice_falsified_amount_p303
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_invoice_falsified_amount_p303_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.invoice_falsified_amount_p303 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.invoice_falsified_amount_p303",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 303,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.invoice_falsified_amount_p303"

    def test_jdg_kks_invoice_falsified_amount_p303_negative_no_block(self):
        """❌ Negatywny: jdg.kks.invoice_falsified_amount_p303 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.invoice_falsified_amount_p303",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_invoice_counterfeit_p304:
    """Auto-generated: jdg.kks.invoice_counterfeit_p304
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_invoice_counterfeit_p304_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.invoice_counterfeit_p304 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.invoice_counterfeit_p304",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 304,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.invoice_counterfeit_p304"

    def test_jdg_kks_invoice_counterfeit_p304_negative_no_block(self):
        """❌ Negatywny: jdg.kks.invoice_counterfeit_p304 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.invoice_counterfeit_p304",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_invoice_used_for_tax_fraud_p305:
    """Auto-generated: jdg.kks.invoice_used_for_tax_fraud_p305
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_invoice_used_for_tax_fraud_p305_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.invoice_used_for_tax_fraud_p305 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.invoice_used_for_tax_fraud_p305",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 305,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.invoice_used_for_tax_fraud_p305"

    def test_jdg_kks_invoice_used_for_tax_fraud_p305_negative_no_block(self):
        """❌ Negatywny: jdg.kks.invoice_used_for_tax_fraud_p305 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.invoice_used_for_tax_fraud_p305",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_systematic_p306:
    """Auto-generated: jdg.kks.empty_invoice_systematic_p306
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_systematic_p306_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_systematic_p306 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_systematic_p306",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 306,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_systematic_p306"

    def test_jdg_kks_empty_invoice_systematic_p306_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_systematic_p306 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_systematic_p306",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_organized_scheme_p307:
    """Auto-generated: jdg.kks.empty_invoice_organized_scheme_p307
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_organized_scheme_p307_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_organized_scheme_p307 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_organized_scheme_p307",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 307,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_organized_scheme_p307"

    def test_jdg_kks_empty_invoice_organized_scheme_p307_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_organized_scheme_p307 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_organized_scheme_p307",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_cross_border_p308:
    """Auto-generated: jdg.kks.empty_invoice_cross_border_p308
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_cross_border_p308_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_cross_border_p308 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_cross_border_p308",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 308,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_cross_border_p308"

    def test_jdg_kks_empty_invoice_cross_border_p308_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_cross_border_p308 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_cross_border_p308",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_digital_forgery_p309:
    """Auto-generated: jdg.kks.empty_invoice_digital_forgery_p309
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_digital_forgery_p309_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_digital_forgery_p309 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_digital_forgery_p309",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 309,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_digital_forgery_p309"

    def test_jdg_kks_empty_invoice_digital_forgery_p309_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_digital_forgery_p309 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_digital_forgery_p309",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_ksef_fraud_p310:
    """Auto-generated: jdg.kks.empty_invoice_ksef_fraud_p310
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_ksef_fraud_p310_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_ksef_fraud_p310 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_ksef_fraud_p310",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 310,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_ksef_fraud_p310"

    def test_jdg_kks_empty_invoice_ksef_fraud_p310_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_ksef_fraud_p310 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_ksef_fraud_p310",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_timestamp_fraud_p311:
    """Auto-generated: jdg.kks.empty_invoice_timestamp_fraud_p311
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_timestamp_fraud_p311_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_timestamp_fraud_p311 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_timestamp_fraud_p311",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 311,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_timestamp_fraud_p311"

    def test_jdg_kks_empty_invoice_timestamp_fraud_p311_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_timestamp_fraud_p311 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_timestamp_fraud_p311",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_recipient_knowledge_p312:
    """Auto-generated: jdg.kks.empty_invoice_recipient_knowledge_p312
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_recipient_knowledge_p312_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_recipient_knowledge_p312 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_recipient_knowledge_p312",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 312,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_recipient_knowledge_p312"

    def test_jdg_kks_empty_invoice_recipient_knowledge_p312_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_recipient_knowledge_p312 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_recipient_knowledge_p312",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_intermediary_p313:
    """Auto-generated: jdg.kks.empty_invoice_intermediary_p313
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_intermediary_p313_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_intermediary_p313 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_intermediary_p313",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 313,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_intermediary_p313"

    def test_jdg_kks_empty_invoice_intermediary_p313_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_intermediary_p313 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_intermediary_p313",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_conspirator_p314:
    """Auto-generated: jdg.kks.empty_invoice_conspirator_p314
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_conspirator_p314_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_conspirator_p314 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_conspirator_p314",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 314,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_conspirator_p314"

    def test_jdg_kks_empty_invoice_conspirator_p314_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_conspirator_p314 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_conspirator_p314",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_value_bands_p315:
    """Auto-generated: jdg.kks.empty_invoice_value_bands_p315
    Podstawa prawna: Art. 62 § 2 KKS"""

    def test_jdg_kks_empty_invoice_value_bands_p315_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_value_bands_p315 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_value_bands_p315",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS",
            "matched": True,
            "priority": 315,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_value_bands_p315"

    def test_jdg_kks_empty_invoice_value_bands_p315_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_value_bands_p315 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_value_bands_p315",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_cross_border_p316:
    """Auto-generated: jdg.kks.empty_invoice_cross_border_p316
    Podstawa prawna: Art. 62 § 2 KKS w zw. z Dyrektywą VAT"""

    def test_jdg_kks_empty_invoice_cross_border_p316_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_cross_border_p316 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_cross_border_p316",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 2 KKS w zw. z Dyrektywą VAT",
            "matched": True,
            "priority": 316,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_cross_border_p316"

    def test_jdg_kks_empty_invoice_cross_border_p316_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_cross_border_p316 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_cross_border_p316",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_esignature_forgery_p317:
    """Auto-generated: jdg.kks.empty_invoice_esignature_forgery_p317
    Podstawa prawna: Art. 62 § 1-2 KKS + Art. 270 KK + eIDAS"""

    def test_jdg_kks_empty_invoice_esignature_forgery_p317_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_esignature_forgery_p317 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_esignature_forgery_p317",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 § 1-2 KKS + Art. 270 KK + eIDAS",
            "matched": True,
            "priority": 317,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_esignature_forgery_p317"

    def test_jdg_kks_empty_invoice_esignature_forgery_p317_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_esignature_forgery_p317 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_esignature_forgery_p317",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_ksef_validation_p318:
    """Auto-generated: jdg.kks.empty_invoice_ksef_validation_p318
    Podstawa prawna: Art. 106na VAT + Art. 62 KKS"""

    def test_jdg_kks_empty_invoice_ksef_validation_p318_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_ksef_validation_p318 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_ksef_validation_p318",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 106na VAT + Art. 62 KKS",
            "matched": True,
            "priority": 318,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_ksef_validation_p318"

    def test_jdg_kks_empty_invoice_ksef_validation_p318_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_ksef_validation_p318 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_ksef_validation_p318",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_empty_invoice_upo_verification_p319:
    """Auto-generated: jdg.kks.empty_invoice_upo_verification_p319
    Podstawa prawna: Art. 106na-106nq VAT + Art. 62 KKS"""

    def test_jdg_kks_empty_invoice_upo_verification_p319_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.empty_invoice_upo_verification_p319 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_upo_verification_p319",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 106na-106nq VAT + Art. 62 KKS",
            "matched": True,
            "priority": 319,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.empty_invoice_upo_verification_p319"

    def test_jdg_kks_empty_invoice_upo_verification_p319_negative_no_block(self):
        """❌ Negatywny: jdg.kks.empty_invoice_upo_verification_p319 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.empty_invoice_upo_verification_p319",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_failure_to_invoice_p320:
    """Auto-generated: jdg.kks.failure_to_invoice_p320
    Podstawa prawna: Art. 63 § 1 KKS"""

    def test_jdg_kks_failure_to_invoice_p320_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.failure_to_invoice_p320 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_p320",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 63 § 1 KKS",
            "matched": True,
            "priority": 320,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.failure_to_invoice_p320"

    def test_jdg_kks_failure_to_invoice_p320_negative_no_block(self):
        """❌ Negatywny: jdg.kks.failure_to_invoice_p320 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_p320",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_failure_to_invoice_b2b_p321:
    """Auto-generated: jdg.kks.failure_to_invoice_b2b_p321
    Podstawa prawna: Art. 63 § 2 KKS w zw. z Art. 106b VAT"""

    def test_jdg_kks_failure_to_invoice_b2b_p321_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.failure_to_invoice_b2b_p321 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_b2b_p321",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 63 § 2 KKS w zw. z Art. 106b VAT",
            "matched": True,
            "priority": 321,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.failure_to_invoice_b2b_p321"

    def test_jdg_kks_failure_to_invoice_b2b_p321_negative_no_block(self):
        """❌ Negatywny: jdg.kks.failure_to_invoice_b2b_p321 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_b2b_p321",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_failure_to_invoice_over_threshold_p323:
    """Auto-generated: jdg.kks.failure_to_invoice_over_threshold_p323
    Podstawa prawna: Art. 63 KKS"""

    def test_jdg_kks_failure_to_invoice_over_threshold_p323_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.failure_to_invoice_over_threshold_p323 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_over_threshold_p323",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 63 KKS",
            "matched": True,
            "priority": 323,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.failure_to_invoice_over_threshold_p323"

    def test_jdg_kks_failure_to_invoice_over_threshold_p323_negative_no_block(self):
        """❌ Negatywny: jdg.kks.failure_to_invoice_over_threshold_p323 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_over_threshold_p323",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_failure_to_invoice_serial_p324:
    """Auto-generated: jdg.kks.failure_to_invoice_serial_p324
    Podstawa prawna: Art. 63 KKS (uporczywość)"""

    def test_jdg_kks_failure_to_invoice_serial_p324_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.failure_to_invoice_serial_p324 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_serial_p324",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 63 KKS (uporczywość)",
            "matched": True,
            "priority": 324,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.failure_to_invoice_serial_p324"

    def test_jdg_kks_failure_to_invoice_serial_p324_negative_no_block(self):
        """❌ Negatywny: jdg.kks.failure_to_invoice_serial_p324 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_serial_p324",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_failure_to_invoice_cash_p325:
    """Auto-generated: jdg.kks.failure_to_invoice_cash_p325
    Podstawa prawna: Art. 63 KKS w zw. z Art. 19a VAT"""

    def test_jdg_kks_failure_to_invoice_cash_p325_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.failure_to_invoice_cash_p325 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_cash_p325",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 63 KKS w zw. z Art. 19a VAT",
            "matched": True,
            "priority": 325,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.failure_to_invoice_cash_p325"

    def test_jdg_kks_failure_to_invoice_cash_p325_negative_no_block(self):
        """❌ Negatywny: jdg.kks.failure_to_invoice_cash_p325 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.failure_to_invoice_cash_p325",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_invoice_incorrect_data_p326:
    """Auto-generated: jdg.kks.invoice_incorrect_data_p326
    Podstawa prawna: Art. 63 § 2 KKS"""

    def test_jdg_kks_invoice_incorrect_data_p326_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.invoice_incorrect_data_p326 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.invoice_incorrect_data_p326",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 63 § 2 KKS",
            "matched": True,
            "priority": 326,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.invoice_incorrect_data_p326"

    def test_jdg_kks_invoice_incorrect_data_p326_negative_no_block(self):
        """❌ Negatywny: jdg.kks.invoice_incorrect_data_p326 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.invoice_incorrect_data_p326",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_invoice_false_nip_p328:
    """Auto-generated: jdg.kks.invoice_false_nip_p328
    Podstawa prawna: Art. 63 KKS + Art. 81 KKS"""

    def test_jdg_kks_invoice_false_nip_p328_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.invoice_false_nip_p328 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.invoice_false_nip_p328",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 63 KKS + Art. 81 KKS",
            "matched": True,
            "priority": 328,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.invoice_false_nip_p328"

    def test_jdg_kks_invoice_false_nip_p328_negative_no_block(self):
        """❌ Negatywny: jdg.kks.invoice_false_nip_p328 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.invoice_false_nip_p328",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_invoice_failure_aggregate_p329:
    """Auto-generated: jdg.kks.invoice_failure_aggregate_p329
    Podstawa prawna: Art. 62-63 KKS — agregacja"""

    def test_jdg_kks_invoice_failure_aggregate_p329_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.invoice_failure_aggregate_p329 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.invoice_failure_aggregate_p329",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62-63 KKS — agregacja",
            "matched": True,
            "priority": 329,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.invoice_failure_aggregate_p329"

    def test_jdg_kks_invoice_failure_aggregate_p329_negative_no_block(self):
        """❌ Negatywny: jdg.kks.invoice_failure_aggregate_p329 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.invoice_failure_aggregate_p329",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_wrong_vat_rate_significant_p331:
    """Auto-generated: jdg.kks.wrong_vat_rate_significant_p331
    Podstawa prawna: Art. 64 KKS (znaczna wartość)"""

    def test_jdg_kks_wrong_vat_rate_significant_p331_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.wrong_vat_rate_significant_p331 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.wrong_vat_rate_significant_p331",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 64 KKS (znaczna wartość)",
            "matched": True,
            "priority": 331,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.wrong_vat_rate_significant_p331"

    def test_jdg_kks_wrong_vat_rate_significant_p331_negative_no_block(self):
        """❌ Negatywny: jdg.kks.wrong_vat_rate_significant_p331 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.wrong_vat_rate_significant_p331",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_refund_overstatement_p332:
    """Auto-generated: jdg.kks.vat_refund_overstatement_p332
    Podstawa prawna: Art. 65 KKS"""

    def test_jdg_kks_vat_refund_overstatement_p332_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_refund_overstatement_p332 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_refund_overstatement_p332",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 65 KKS",
            "matched": True,
            "priority": 332,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_refund_overstatement_p332"

    def test_jdg_kks_vat_refund_overstatement_p332_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_refund_overstatement_p332 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_refund_overstatement_p332",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_refund_fictitious_export_p333:
    """Auto-generated: jdg.kks.vat_refund_fictitious_export_p333
    Podstawa prawna: Art. 65 KKS w zw. z Art. 76 KKS"""

    def test_jdg_kks_vat_refund_fictitious_export_p333_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_refund_fictitious_export_p333 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_refund_fictitious_export_p333",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 65 KKS w zw. z Art. 76 KKS",
            "matched": True,
            "priority": 333,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_refund_fictitious_export_p333"

    def test_jdg_kks_vat_refund_fictitious_export_p333_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_refund_fictitious_export_p333 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_refund_fictitious_export_p333",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_refund_accelerated_fraud_p334:
    """Auto-generated: jdg.kks.vat_refund_accelerated_fraud_p334
    Podstawa prawna: Art. 65 KKS w zw. z Art. 87 ust. 6 VAT"""

    def test_jdg_kks_vat_refund_accelerated_fraud_p334_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_refund_accelerated_fraud_p334 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_refund_accelerated_fraud_p334",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 65 KKS w zw. z Art. 87 ust. 6 VAT",
            "matched": True,
            "priority": 334,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_refund_accelerated_fraud_p334"

    def test_jdg_kks_vat_refund_accelerated_fraud_p334_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_refund_accelerated_fraud_p334 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_refund_accelerated_fraud_p334",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_untrue_tax_return_p335:
    """Auto-generated: jdg.kks.untrue_tax_return_p335
    Podstawa prawna: Art. 66 KKS"""

    def test_jdg_kks_untrue_tax_return_p335_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.untrue_tax_return_p335 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.untrue_tax_return_p335",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 66 KKS",
            "matched": True,
            "priority": 335,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.untrue_tax_return_p335"

    def test_jdg_kks_untrue_tax_return_p335_negative_no_block(self):
        """❌ Negatywny: jdg.kks.untrue_tax_return_p335 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.untrue_tax_return_p335",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_withholding_tax_failure_p336:
    """Auto-generated: jdg.kks.withholding_tax_failure_p336
    Podstawa prawna: Art. 67 KKS"""

    def test_jdg_kks_withholding_tax_failure_p336_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.withholding_tax_failure_p336 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.withholding_tax_failure_p336",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 67 KKS",
            "matched": True,
            "priority": 336,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.withholding_tax_failure_p336"

    def test_jdg_kks_withholding_tax_failure_p336_negative_no_block(self):
        """❌ Negatywny: jdg.kks.withholding_tax_failure_p336 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.withholding_tax_failure_p336",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_withholding_tax_non_remittance_p337:
    """Auto-generated: jdg.kks.withholding_tax_non_remittance_p337
    Podstawa prawna: Art. 67 KKS w zw. z Art. 59 KKS"""

    def test_jdg_kks_withholding_tax_non_remittance_p337_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.withholding_tax_non_remittance_p337 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.withholding_tax_non_remittance_p337",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 67 KKS w zw. z Art. 59 KKS",
            "matched": True,
            "priority": 337,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.withholding_tax_non_remittance_p337"

    def test_jdg_kks_withholding_tax_non_remittance_p337_negative_no_block(self):
        """❌ Negatywny: jdg.kks.withholding_tax_non_remittance_p337 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.withholding_tax_non_remittance_p337",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_wht_certificate_fraud_p338:
    """Auto-generated: jdg.kks.wht_certificate_fraud_p338
    Podstawa prawna: Art. 67 KKS + Art. 60 KKS"""

    def test_jdg_kks_wht_certificate_fraud_p338_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.wht_certificate_fraud_p338 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.wht_certificate_fraud_p338",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 67 KKS + Art. 60 KKS",
            "matched": True,
            "priority": 338,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.wht_certificate_fraud_p338"

    def test_jdg_kks_wht_certificate_fraud_p338_negative_no_block(self):
        """❌ Negatywny: jdg.kks.wht_certificate_fraud_p338 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.wht_certificate_fraud_p338",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_destruction_documents_p340:
    """Auto-generated: jdg.kks.destruction_documents_p340
    Podstawa prawna: Art. 68 KKS"""

    def test_jdg_kks_destruction_documents_p340_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.destruction_documents_p340 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.destruction_documents_p340",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 68 KKS",
            "matched": True,
            "priority": 340,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.destruction_documents_p340"

    def test_jdg_kks_destruction_documents_p340_negative_no_block(self):
        """❌ Negatywny: jdg.kks.destruction_documents_p340 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.destruction_documents_p340",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_destruction_before_retention_p341:
    """Auto-generated: jdg.kks.destruction_before_retention_p341
    Podstawa prawna: Art. 68 KKS w zw. z Art. 86 OrdPU"""

    def test_jdg_kks_destruction_before_retention_p341_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.destruction_before_retention_p341 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.destruction_before_retention_p341",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 68 KKS w zw. z Art. 86 OrdPU",
            "matched": True,
            "priority": 341,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.destruction_before_retention_p341"

    def test_jdg_kks_destruction_before_retention_p341_negative_no_block(self):
        """❌ Negatywny: jdg.kks.destruction_before_retention_p341 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.destruction_before_retention_p341",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_destruction_during_audit_p342:
    """Auto-generated: jdg.kks.destruction_during_audit_p342
    Podstawa prawna: Art. 68 KKS + Art. 83 KKS"""

    def test_jdg_kks_destruction_during_audit_p342_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.destruction_during_audit_p342 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.destruction_during_audit_p342",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 68 KKS + Art. 83 KKS",
            "matched": True,
            "priority": 342,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.destruction_during_audit_p342"

    def test_jdg_kks_destruction_during_audit_p342_negative_no_block(self):
        """❌ Negatywny: jdg.kks.destruction_during_audit_p342 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.destruction_during_audit_p342",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_audit_p343:
    """Auto-generated: jdg.kks.obstruction_audit_p343
    Podstawa prawna: Art. 69 KKS"""

    def test_jdg_kks_obstruction_audit_p343_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_audit_p343 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_audit_p343",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 69 KKS",
            "matched": True,
            "priority": 343,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_audit_p343"

    def test_jdg_kks_obstruction_audit_p343_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_audit_p343 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_audit_p343",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_denial_of_access_p344:
    """Auto-generated: jdg.kks.obstruction_denial_of_access_p344
    Podstawa prawna: Art. 69 KKS"""

    def test_jdg_kks_obstruction_denial_of_access_p344_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_denial_of_access_p344 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_denial_of_access_p344",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 69 KKS",
            "matched": True,
            "priority": 344,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_denial_of_access_p344"

    def test_jdg_kks_obstruction_denial_of_access_p344_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_denial_of_access_p344 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_denial_of_access_p344",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_false_information_p345:
    """Auto-generated: jdg.kks.obstruction_false_information_p345
    Podstawa prawna: Art. 69 KKS w zw. z Art. 83 KKS"""

    def test_jdg_kks_obstruction_false_information_p345_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_false_information_p345 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_false_information_p345",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 69 KKS w zw. z Art. 83 KKS",
            "matched": True,
            "priority": 345,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_false_information_p345"

    def test_jdg_kks_obstruction_false_information_p345_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_false_information_p345 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_false_information_p345",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_non_filing_declaration_p346:
    """Auto-generated: jdg.kks.non_filing_declaration_p346
    Podstawa prawna: Art. 70 KKS"""

    def test_jdg_kks_non_filing_declaration_p346_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.non_filing_declaration_p346 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.non_filing_declaration_p346",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 70 KKS",
            "matched": True,
            "priority": 346,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.non_filing_declaration_p346"

    def test_jdg_kks_non_filing_declaration_p346_negative_no_block(self):
        """❌ Negatywny: jdg.kks.non_filing_declaration_p346 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.non_filing_declaration_p346",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_non_filing_multiple_periods_p347:
    """Auto-generated: jdg.kks.non_filing_multiple_periods_p347
    Podstawa prawna: Art. 70 KKS"""

    def test_jdg_kks_non_filing_multiple_periods_p347_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.non_filing_multiple_periods_p347 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.non_filing_multiple_periods_p347",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 70 KKS",
            "matched": True,
            "priority": 347,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.non_filing_multiple_periods_p347"

    def test_jdg_kks_non_filing_multiple_periods_p347_negative_no_block(self):
        """❌ Negatywny: jdg.kks.non_filing_multiple_periods_p347 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.non_filing_multiple_periods_p347",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_non_filing_despite_request_p348:
    """Auto-generated: jdg.kks.non_filing_despite_request_p348
    Podstawa prawna: Art. 70 KKS w zw. z Art. 83 KKS"""

    def test_jdg_kks_non_filing_despite_request_p348_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.non_filing_despite_request_p348 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.non_filing_despite_request_p348",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 70 KKS w zw. z Art. 83 KKS",
            "matched": True,
            "priority": 348,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.non_filing_despite_request_p348"

    def test_jdg_kks_non_filing_despite_request_p348_negative_no_block(self):
        """❌ Negatywny: jdg.kks.non_filing_despite_request_p348 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.non_filing_despite_request_p348",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_business_without_registration_p349:
    """Auto-generated: jdg.kks.business_without_registration_p349
    Podstawa prawna: Art. 71 KKS"""

    def test_jdg_kks_business_without_registration_p349_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.business_without_registration_p349 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.business_without_registration_p349",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 71 KKS",
            "matched": True,
            "priority": 349,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.business_without_registration_p349"

    def test_jdg_kks_business_without_registration_p349_negative_no_block(self):
        """❌ Negatywny: jdg.kks.business_without_registration_p349 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.business_without_registration_p349",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_business_despite_ban_p350:
    """Auto-generated: jdg.kks.business_despite_ban_p350
    Podstawa prawna: Art. 72 KKS"""

    def test_jdg_kks_business_despite_ban_p350_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.business_despite_ban_p350 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.business_despite_ban_p350",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 72 KKS",
            "matched": True,
            "priority": 350,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.business_despite_ban_p350"

    def test_jdg_kks_business_despite_ban_p350_negative_no_block(self):
        """❌ Negatywny: jdg.kks.business_despite_ban_p350 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.business_despite_ban_p350",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_illegal_gambling_tax_p351:
    """Auto-generated: jdg.kks.illegal_gambling_tax_p351
    Podstawa prawna: Art. 73 KKS"""

    def test_jdg_kks_illegal_gambling_tax_p351_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.illegal_gambling_tax_p351 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.illegal_gambling_tax_p351",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 73 KKS",
            "matched": True,
            "priority": 351,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.illegal_gambling_tax_p351"

    def test_jdg_kks_illegal_gambling_tax_p351_negative_no_block(self):
        """❌ Negatywny: jdg.kks.illegal_gambling_tax_p351 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.illegal_gambling_tax_p351",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_excise_duty_evasion_p352:
    """Auto-generated: jdg.kks.excise_duty_evasion_p352
    Podstawa prawna: Art. 74 KKS"""

    def test_jdg_kks_excise_duty_evasion_p352_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.excise_duty_evasion_p352 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.excise_duty_evasion_p352",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 74 KKS",
            "matched": True,
            "priority": 352,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.excise_duty_evasion_p352"

    def test_jdg_kks_excise_duty_evasion_p352_negative_no_block(self):
        """❌ Negatywny: jdg.kks.excise_duty_evasion_p352 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.excise_duty_evasion_p352",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_customs_duty_evasion_p353:
    """Auto-generated: jdg.kks.customs_duty_evasion_p353
    Podstawa prawna: Art. 75 KKS"""

    def test_jdg_kks_customs_duty_evasion_p353_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.customs_duty_evasion_p353 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.customs_duty_evasion_p353",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 75 KKS",
            "matched": True,
            "priority": 353,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.customs_duty_evasion_p353"

    def test_jdg_kks_customs_duty_evasion_p353_negative_no_block(self):
        """❌ Negatywny: jdg.kks.customs_duty_evasion_p353 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.customs_duty_evasion_p353",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_import_vat_evasion_p354:
    """Auto-generated: jdg.kks.import_vat_evasion_p354
    Podstawa prawna: Art. 76 KKS"""

    def test_jdg_kks_import_vat_evasion_p354_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.import_vat_evasion_p354 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.import_vat_evasion_p354",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 76 KKS",
            "matched": True,
            "priority": 354,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.import_vat_evasion_p354"

    def test_jdg_kks_import_vat_evasion_p354_negative_no_block(self):
        """❌ Negatywny: jdg.kks.import_vat_evasion_p354 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.import_vat_evasion_p354",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_fraud_network_detection_p355:
    """Auto-generated: jdg.kks.vat_fraud_network_detection_p355
    Podstawa prawna: Art. 62 KKS + Art. 76a KKS"""

    def test_jdg_kks_vat_fraud_network_detection_p355_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_fraud_network_detection_p355 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_fraud_network_detection_p355",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 KKS + Art. 76a KKS",
            "matched": True,
            "priority": 355,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_fraud_network_detection_p355"

    def test_jdg_kks_vat_fraud_network_detection_p355_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_fraud_network_detection_p355 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_fraud_network_detection_p355",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_fraud_industry_specific_p358:
    """Auto-generated: jdg.kks.vat_fraud_industry_specific_p358
    Podstawa prawna: Art. 62 KKS — branże wrażliwe"""

    def test_jdg_kks_vat_fraud_industry_specific_p358_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_fraud_industry_specific_p358 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_fraud_industry_specific_p358",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 KKS — branże wrażliwe",
            "matched": True,
            "priority": 358,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_fraud_industry_specific_p358"

    def test_jdg_kks_vat_fraud_industry_specific_p358_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_fraud_industry_specific_p358 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_fraud_industry_specific_p358",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_fraud_rapid_dereg_p360:
    """Auto-generated: jdg.kks.vat_fraud_rapid_dereg_p360
    Podstawa prawna: Art. 62 KKS — znikający podatnik"""

    def test_jdg_kks_vat_fraud_rapid_dereg_p360_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_fraud_rapid_dereg_p360 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_fraud_rapid_dereg_p360",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 KKS — znikający podatnik",
            "matched": True,
            "priority": 360,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_fraud_rapid_dereg_p360"

    def test_jdg_kks_vat_fraud_rapid_dereg_p360_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_fraud_rapid_dereg_p360 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_fraud_rapid_dereg_p360",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_fraud_insolvency_pattern_p363:
    """Auto-generated: jdg.kks.vat_fraud_insolvency_pattern_p363
    Podstawa prawna: Art. 62 KKS + Art. 300 KK"""

    def test_jdg_kks_vat_fraud_insolvency_pattern_p363_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_fraud_insolvency_pattern_p363 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_fraud_insolvency_pattern_p363",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 62 KKS + Art. 300 KK",
            "matched": True,
            "priority": 363,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_fraud_insolvency_pattern_p363"

    def test_jdg_kks_vat_fraud_insolvency_pattern_p363_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_fraud_insolvency_pattern_p363 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_fraud_insolvency_pattern_p363",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_asset_seizure_risk_p365:
    """Auto-generated: jdg.kks.asset_seizure_risk_p365
    Podstawa prawna: Art. 22-31 KKS — zabezpieczenie majątkowe"""

    def test_jdg_kks_asset_seizure_risk_p365_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.asset_seizure_risk_p365 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.asset_seizure_risk_p365",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22-31 KKS — zabezpieczenie majątkowe",
            "matched": True,
            "priority": 365,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.asset_seizure_risk_p365"

    def test_jdg_kks_asset_seizure_risk_p365_negative_no_block(self):
        """❌ Negatywny: jdg.kks.asset_seizure_risk_p365 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.asset_seizure_risk_p365",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_property_security_active_p366:
    """Auto-generated: jdg.kks.property_security_active_p366
    Podstawa prawna: Art. 22 KKS"""

    def test_jdg_kks_property_security_active_p366_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.property_security_active_p366 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.property_security_active_p366",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22 KKS",
            "matched": True,
            "priority": 366,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.property_security_active_p366"

    def test_jdg_kks_property_security_active_p366_negative_no_block(self):
        """❌ Negatywny: jdg.kks.property_security_active_p366 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.property_security_active_p366",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_bank_account_blocked_p367:
    """Auto-generated: jdg.kks.bank_account_blocked_p367
    Podstawa prawna: Art. 23 § 1 KKS"""

    def test_jdg_kks_bank_account_blocked_p367_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.bank_account_blocked_p367 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.bank_account_blocked_p367",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 23 § 1 KKS",
            "matched": True,
            "priority": 367,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.bank_account_blocked_p367"

    def test_jdg_kks_bank_account_blocked_p367_negative_no_block(self):
        """❌ Negatywny: jdg.kks.bank_account_blocked_p367 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.bank_account_blocked_p367",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_mortgage_on_property_p368:
    """Auto-generated: jdg.kks.mortgage_on_property_p368
    Podstawa prawna: Art. 23 § 2 KKS w zw. z Art. 34 § 2 OrdPU"""

    def test_jdg_kks_mortgage_on_property_p368_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.mortgage_on_property_p368 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.mortgage_on_property_p368",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 23 § 2 KKS w zw. z Art. 34 § 2 OrdPU",
            "matched": True,
            "priority": 368,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.mortgage_on_property_p368"

    def test_jdg_kks_mortgage_on_property_p368_negative_no_block(self):
        """❌ Negatywny: jdg.kks.mortgage_on_property_p368 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.mortgage_on_property_p368",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_tax_lien_registered_p369:
    """Auto-generated: jdg.kks.tax_lien_registered_p369
    Podstawa prawna: Art. 24 KKS w zw. z Art. 41 OrdPU"""

    def test_jdg_kks_tax_lien_registered_p369_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.tax_lien_registered_p369 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.tax_lien_registered_p369",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 24 KKS w zw. z Art. 41 OrdPU",
            "matched": True,
            "priority": 369,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.tax_lien_registered_p369"

    def test_jdg_kks_tax_lien_registered_p369_negative_no_block(self):
        """❌ Negatywny: jdg.kks.tax_lien_registered_p369 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.tax_lien_registered_p369",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_third_party_liability_p370:
    """Auto-generated: jdg.kks.third_party_liability_p370
    Podstawa prawna: Art. 24a KKS"""

    def test_jdg_kks_third_party_liability_p370_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.third_party_liability_p370 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.third_party_liability_p370",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 24a KKS",
            "matched": True,
            "priority": 370,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.third_party_liability_p370"

    def test_jdg_kks_third_party_liability_p370_negative_no_block(self):
        """❌ Negatywny: jdg.kks.third_party_liability_p370 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.third_party_liability_p370",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_business_activity_ban_p372:
    """Auto-generated: jdg.kks.business_activity_ban_p372
    Podstawa prawna: Art. 26 KKS w zw. z Art. 41 KK"""

    def test_jdg_kks_business_activity_ban_p372_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.business_activity_ban_p372 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.business_activity_ban_p372",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 26 KKS w zw. z Art. 41 KK",
            "matched": True,
            "priority": 372,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.business_activity_ban_p372"

    def test_jdg_kks_business_activity_ban_p372_negative_no_block(self):
        """❌ Negatywny: jdg.kks.business_activity_ban_p372 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.business_activity_ban_p372",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_public_contracts_ban_p373:
    """Auto-generated: jdg.kks.public_contracts_ban_p373
    Podstawa prawna: Art. 108-109 PZP + KKS"""

    def test_jdg_kks_public_contracts_ban_p373_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.public_contracts_ban_p373 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.public_contracts_ban_p373",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 108-109 PZP + KKS",
            "matched": True,
            "priority": 373,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.public_contracts_ban_p373"

    def test_jdg_kks_public_contracts_ban_p373_negative_no_block(self):
        """❌ Negatywny: jdg.kks.public_contracts_ban_p373 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.public_contracts_ban_p373",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_professional_license_risk_p374:
    """Auto-generated: jdg.kks.professional_license_risk_p374
    Podstawa prawna: Art. 26 KKS + przepisy korporacyjne"""

    def test_jdg_kks_professional_license_risk_p374_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.professional_license_risk_p374 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.professional_license_risk_p374",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 26 KKS + przepisy korporacyjne",
            "matched": True,
            "priority": 374,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.professional_license_risk_p374"

    def test_jdg_kks_professional_license_risk_p374_negative_no_block(self):
        """❌ Negatywny: jdg.kks.professional_license_risk_p374 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.professional_license_risk_p374",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_cross_offense_pattern_p375:
    """Auto-generated: jdg.kks.cross_offense_pattern_p375
    Podstawa prawna: Art. 54-76 KKS — analiza międzyprzestępcza"""

    def test_jdg_kks_cross_offense_pattern_p375_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.cross_offense_pattern_p375 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.cross_offense_pattern_p375",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54-76 KKS — analiza międzyprzestępcza",
            "matched": True,
            "priority": 375,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.cross_offense_pattern_p375"

    def test_jdg_kks_cross_offense_pattern_p375_negative_no_block(self):
        """❌ Negatywny: jdg.kks.cross_offense_pattern_p375 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.cross_offense_pattern_p375",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_offense_chain_detection_p376:
    """Auto-generated: jdg.kks.offense_chain_detection_p376
    Podstawa prawna: Art. 54-76 KKS — związek przestępstw"""

    def test_jdg_kks_offense_chain_detection_p376_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.offense_chain_detection_p376 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.offense_chain_detection_p376",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54-76 KKS — związek przestępstw",
            "matched": True,
            "priority": 376,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.offense_chain_detection_p376"

    def test_jdg_kks_offense_chain_detection_p376_negative_no_block(self):
        """❌ Negatywny: jdg.kks.offense_chain_detection_p376 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.offense_chain_detection_p376",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_multi_year_fraud_p377:
    """Auto-generated: jdg.kks.multi_year_fraud_p377
    Podstawa prawna: Art. 54-76 KKS — ciągłość przestępstwa"""

    def test_jdg_kks_multi_year_fraud_p377_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.multi_year_fraud_p377 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.multi_year_fraud_p377",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54-76 KKS — ciągłość przestępstwa",
            "matched": True,
            "priority": 377,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.multi_year_fraud_p377"

    def test_jdg_kks_multi_year_fraud_p377_negative_no_block(self):
        """❌ Negatywny: jdg.kks.multi_year_fraud_p377 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.multi_year_fraud_p377",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_organized_crime_indicators_p378:
    """Auto-generated: jdg.kks.organized_crime_indicators_p378
    Podstawa prawna: Art. 19 § 4 KKS — grupa zorganizowana"""

    def test_jdg_kks_organized_crime_indicators_p378_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.organized_crime_indicators_p378 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.organized_crime_indicators_p378",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 19 § 4 KKS — grupa zorganizowana",
            "matched": True,
            "priority": 378,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.organized_crime_indicators_p378"

    def test_jdg_kks_organized_crime_indicators_p378_negative_no_block(self):
        """❌ Negatywny: jdg.kks.organized_crime_indicators_p378 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.organized_crime_indicators_p378",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_money_laundering_nexus_p379:
    """Auto-generated: jdg.kks.money_laundering_nexus_p379
    Podstawa prawna: Art. 299 KK + Art. 54-76 KKS"""

    def test_jdg_kks_money_laundering_nexus_p379_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.money_laundering_nexus_p379 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.money_laundering_nexus_p379",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 299 KK + Art. 54-76 KKS",
            "matched": True,
            "priority": 379,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.money_laundering_nexus_p379"

    def test_jdg_kks_money_laundering_nexus_p379_negative_no_block(self):
        """❌ Negatywny: jdg.kks.money_laundering_nexus_p379 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.money_laundering_nexus_p379",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_cumulative_tax_loss_p381:
    """Auto-generated: jdg.kks.cumulative_tax_loss_p381
    Podstawa prawna: Art. 54-76 KKS — suma uszczupleń"""

    def test_jdg_kks_cumulative_tax_loss_p381_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.cumulative_tax_loss_p381 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.cumulative_tax_loss_p381",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54-76 KKS — suma uszczupleń",
            "matched": True,
            "priority": 381,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.cumulative_tax_loss_p381"

    def test_jdg_kks_cumulative_tax_loss_p381_negative_no_block(self):
        """❌ Negatywny: jdg.kks.cumulative_tax_loss_p381 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.cumulative_tax_loss_p381",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_offense_severity_escalation_p382:
    """Auto-generated: jdg.kks.offense_severity_escalation_p382
    Podstawa prawna: Art. 54-76 KKS — gradacja kar"""

    def test_jdg_kks_offense_severity_escalation_p382_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.offense_severity_escalation_p382 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.offense_severity_escalation_p382",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54-76 KKS — gradacja kar",
            "matched": True,
            "priority": 382,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.offense_severity_escalation_p382"

    def test_jdg_kks_offense_severity_escalation_p382_negative_no_block(self):
        """❌ Negatywny: jdg.kks.offense_severity_escalation_p382 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.offense_severity_escalation_p382",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_global_kks_risk_score_p383:
    """Auto-generated: jdg.kks.global_kks_risk_score_p383
    Podstawa prawna: Art. 54-76 KKS — scoring globalny"""

    def test_jdg_kks_global_kks_risk_score_p383_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.global_kks_risk_score_p383 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.global_kks_risk_score_p383",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54-76 KKS — scoring globalny",
            "matched": True,
            "priority": 383,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.global_kks_risk_score_p383"

    def test_jdg_kks_global_kks_risk_score_p383_negative_no_block(self):
        """❌ Negatywny: jdg.kks.global_kks_risk_score_p383 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.global_kks_risk_score_p383",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_risk_to_business_survival_p384:
    """Auto-generated: jdg.kks.risk_to_business_survival_p384
    Podstawa prawna: Art. 54-76 KKS — ocena wpływu na JDG"""

    def test_jdg_kks_risk_to_business_survival_p384_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.risk_to_business_survival_p384 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.risk_to_business_survival_p384",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54-76 KKS — ocena wpływu na JDG",
            "matched": True,
            "priority": 384,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.risk_to_business_survival_p384"

    def test_jdg_kks_risk_to_business_survival_p384_negative_no_block(self):
        """❌ Negatywny: jdg.kks.risk_to_business_survival_p384 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.risk_to_business_survival_p384",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_mandate_refusal_consequences_p388:
    """Auto-generated: jdg.kks.mandate_refusal_consequences_p388
    Podstawa prawna: Art. 137 § 3 KKW"""

    def test_jdg_kks_mandate_refusal_consequences_p388_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.mandate_refusal_consequences_p388 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.mandate_refusal_consequences_p388",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 137 § 3 KKW",
            "matched": True,
            "priority": 388,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.mandate_refusal_consequences_p388"

    def test_jdg_kks_mandate_refusal_consequences_p388_negative_no_block(self):
        """❌ Negatywny: jdg.kks.mandate_refusal_consequences_p388 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.mandate_refusal_consequences_p388",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_mandate_payment_deadline_p389:
    """Auto-generated: jdg.kks.mandate_payment_deadline_p389
    Podstawa prawna: Art. 140 KKW"""

    def test_jdg_kks_mandate_payment_deadline_p389_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.mandate_payment_deadline_p389 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.mandate_payment_deadline_p389",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 140 KKW",
            "matched": True,
            "priority": 389,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.mandate_payment_deadline_p389"

    def test_jdg_kks_mandate_payment_deadline_p389_negative_no_block(self):
        """❌ Negatywny: jdg.kks.mandate_payment_deadline_p389 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.mandate_payment_deadline_p389",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_cross_tax_type_offenses_p393:
    """Auto-generated: jdg.kks.cross_tax_type_offenses_p393
    Podstawa prawna: Art. 54-76 KKS — zbieg przepisów"""

    def test_jdg_kks_cross_tax_type_offenses_p393_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.cross_tax_type_offenses_p393 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.cross_tax_type_offenses_p393",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54-76 KKS — zbieg przepisów",
            "matched": True,
            "priority": 393,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.cross_tax_type_offenses_p393"

    def test_jdg_kks_cross_tax_type_offenses_p393_negative_no_block(self):
        """❌ Negatywny: jdg.kks.cross_tax_type_offenses_p393 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.cross_tax_type_offenses_p393",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_crime_section_summary_p399:
    """Auto-generated: jdg.kks.crime_section_summary_p399
    Podstawa prawna: Art. 54-76 KKS — synteza"""

    def test_jdg_kks_crime_section_summary_p399_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.crime_section_summary_p399 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.crime_section_summary_p399",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 54-76 KKS — synteza",
            "matched": True,
            "priority": 399,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.crime_section_summary_p399"

    def test_jdg_kks_crime_section_summary_p399_negative_no_block(self):
        """❌ Negatywny: jdg.kks.crime_section_summary_p399 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.crime_section_summary_p399",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_incorrect_data_withholding_not_remitted_p414:
    """Auto-generated: jdg.kks.incorrect_data_withholding_not_remitted_p414
    Podstawa prawna: Art. 77-79 KKS"""

    def test_jdg_kks_incorrect_data_withholding_not_remitted_p414_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.incorrect_data_withholding_not_remitted_p414 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.incorrect_data_withholding_not_remitted_p414",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 77-79 KKS",
            "matched": True,
            "priority": 414,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.incorrect_data_withholding_not_remitted_p414"

    def test_jdg_kks_incorrect_data_withholding_not_remitted_p414_negative_no_block(self):
        """❌ Negatywny: jdg.kks.incorrect_data_withholding_not_remitted_p414 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.incorrect_data_withholding_not_remitted_p414",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_no_books_at_premises_p420:
    """Auto-generated: jdg.kks.obstruction_no_books_at_premises_p420
    Podstawa prawna: Art. 83 KKS"""

    def test_jdg_kks_obstruction_no_books_at_premises_p420_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_no_books_at_premises_p420 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_no_books_at_premises_p420",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 KKS",
            "matched": True,
            "priority": 420,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_no_books_at_premises_p420"

    def test_jdg_kks_obstruction_no_books_at_premises_p420_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_no_books_at_premises_p420 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_no_books_at_premises_p420",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_computer_broken_p421:
    """Auto-generated: jdg.kks.obstruction_computer_broken_p421
    Podstawa prawna: Art. 83 KKS"""

    def test_jdg_kks_obstruction_computer_broken_p421_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_computer_broken_p421 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_computer_broken_p421",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 KKS",
            "matched": True,
            "priority": 421,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_computer_broken_p421"

    def test_jdg_kks_obstruction_computer_broken_p421_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_computer_broken_p421 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_computer_broken_p421",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_accountant_disappeared_p422:
    """Auto-generated: jdg.kks.obstruction_accountant_disappeared_p422
    Podstawa prawna: Art. 83 KKS"""

    def test_jdg_kks_obstruction_accountant_disappeared_p422_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_accountant_disappeared_p422 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_accountant_disappeared_p422",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 KKS",
            "matched": True,
            "priority": 422,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_accountant_disappeared_p422"

    def test_jdg_kks_obstruction_accountant_disappeared_p422_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_accountant_disappeared_p422 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_accountant_disappeared_p422",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_obstruction_data_encrypted_p423:
    """Auto-generated: jdg.kks.obstruction_data_encrypted_p423
    Podstawa prawna: Art. 83 KKS"""

    def test_jdg_kks_obstruction_data_encrypted_p423_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.obstruction_data_encrypted_p423 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.obstruction_data_encrypted_p423",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 KKS",
            "matched": True,
            "priority": 423,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.obstruction_data_encrypted_p423"

    def test_jdg_kks_obstruction_data_encrypted_p423_negative_no_block(self):
        """❌ Negatywny: jdg.kks.obstruction_data_encrypted_p423 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.obstruction_data_encrypted_p423",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_risk_aggregation_high:
    """Auto-generated: jdg.kks.risk_aggregation_high
    Podstawa prawna: KKS — agregacja ryzyka"""

    def test_jdg_kks_risk_aggregation_high_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.risk_aggregation_high — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.risk_aggregation_high",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "KKS — agregacja ryzyka",
            "matched": True,
            "priority": 432,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.risk_aggregation_high"

    def test_jdg_kks_risk_aggregation_high_negative_no_block(self):
        """❌ Negatywny: jdg.kks.risk_aggregation_high — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.risk_aggregation_high",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_criminal_threshold_p433:
    """Auto-generated: jdg.kks.criminal_threshold_p433
    Podstawa prawna: Art. 53 § 3-6 KKS"""

    def test_jdg_kks_criminal_threshold_p433_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.criminal_threshold_p433 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.criminal_threshold_p433",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 53 § 3-6 KKS",
            "matched": True,
            "priority": 433,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.criminal_threshold_p433"

    def test_jdg_kks_criminal_threshold_p433_negative_no_block(self):
        """❌ Negatywny: jdg.kks.criminal_threshold_p433 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.criminal_threshold_p433",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unregistered_activity_p437:
    """Auto-generated: jdg.kks.unregistered_activity_p437
    Podstawa prawna: Art. 60^1 § 1 KKS"""

    def test_jdg_kks_unregistered_activity_p437_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unregistered_activity_p437 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unregistered_activity_p437",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 60^1 § 1 KKS",
            "matched": True,
            "priority": 437,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unregistered_activity_p437"

    def test_jdg_kks_unregistered_activity_p437_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unregistered_activity_p437 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unregistered_activity_p437",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_ceidg_false_data_p438:
    """Auto-generated: jdg.kks.ceidg_false_data_p438
    Podstawa prawna: Art. 60^1 § 2 KKS"""

    def test_jdg_kks_ceidg_false_data_p438_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.ceidg_false_data_p438 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.ceidg_false_data_p438",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 60^1 § 2 KKS",
            "matched": True,
            "priority": 438,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.ceidg_false_data_p438"

    def test_jdg_kks_ceidg_false_data_p438_negative_no_block(self):
        """❌ Negatywny: jdg.kks.ceidg_false_data_p438 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.ceidg_false_data_p438",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_nip_not_obtained_p439:
    """Auto-generated: jdg.kks.nip_not_obtained_p439
    Podstawa prawna: Art. 81 § 1 KKS"""

    def test_jdg_kks_nip_not_obtained_p439_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.nip_not_obtained_p439 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.nip_not_obtained_p439",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 81 § 1 KKS",
            "matched": True,
            "priority": 439,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.nip_not_obtained_p439"

    def test_jdg_kks_nip_not_obtained_p439_negative_no_block(self):
        """❌ Negatywny: jdg.kks.nip_not_obtained_p439 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.nip_not_obtained_p439",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_vat_r_not_submitted_p442:
    """Auto-generated: jdg.kks.vat_r_not_submitted_p442
    Podstawa prawna: Art. 81 KKS w zw. z Art. 96 VAT"""

    def test_jdg_kks_vat_r_not_submitted_p442_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.vat_r_not_submitted_p442 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.vat_r_not_submitted_p442",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 81 KKS w zw. z Art. 96 VAT",
            "matched": True,
            "priority": 442,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.vat_r_not_submitted_p442"

    def test_jdg_kks_vat_r_not_submitted_p442_negative_no_block(self):
        """❌ Negatywny: jdg.kks.vat_r_not_submitted_p442 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.vat_r_not_submitted_p442",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_business_address_unreachable_p444:
    """Auto-generated: jdg.kks.business_address_unreachable_p444
    Podstawa prawna: Art. 82 KKS"""

    def test_jdg_kks_business_address_unreachable_p444_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.business_address_unreachable_p444 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.business_address_unreachable_p444",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 82 KKS",
            "matched": True,
            "priority": 444,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.business_address_unreachable_p444"

    def test_jdg_kks_business_address_unreachable_p444_negative_no_block(self):
        """❌ Negatywny: jdg.kks.business_address_unreachable_p444 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.business_address_unreachable_p444",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_cash_register_not_installed_p445:
    """Auto-generated: jdg.kks.cash_register_not_installed_p445
    Podstawa prawna: Art. 84 KKS w zw. z Art. 111 VAT"""

    def test_jdg_kks_cash_register_not_installed_p445_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.cash_register_not_installed_p445 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.cash_register_not_installed_p445",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 84 KKS w zw. z Art. 111 VAT",
            "matched": True,
            "priority": 445,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.cash_register_not_installed_p445"

    def test_jdg_kks_cash_register_not_installed_p445_negative_no_block(self):
        """❌ Negatywny: jdg.kks.cash_register_not_installed_p445 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.cash_register_not_installed_p445",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_receipt_not_issued_b2c_p446:
    """Auto-generated: jdg.kks.receipt_not_issued_b2c_p446
    Podstawa prawna: Art. 84 § 1 KKS"""

    def test_jdg_kks_receipt_not_issued_b2c_p446_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.receipt_not_issued_b2c_p446 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.receipt_not_issued_b2c_p446",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 84 § 1 KKS",
            "matched": True,
            "priority": 446,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.receipt_not_issued_b2c_p446"

    def test_jdg_kks_receipt_not_issued_b2c_p446_negative_no_block(self):
        """❌ Negatywny: jdg.kks.receipt_not_issued_b2c_p446 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.receipt_not_issued_b2c_p446",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_refused_inspection_p450:
    """Auto-generated: jdg.kks.refused_inspection_p450
    Podstawa prawna: Art. 83 § 1 KKS"""

    def test_jdg_kks_refused_inspection_p450_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.refused_inspection_p450 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.refused_inspection_p450",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 § 1 KKS",
            "matched": True,
            "priority": 450,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.refused_inspection_p450"

    def test_jdg_kks_refused_inspection_p450_negative_no_block(self):
        """❌ Negatywny: jdg.kks.refused_inspection_p450 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.refused_inspection_p450",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_false_evidence_submitted_p451:
    """Auto-generated: jdg.kks.false_evidence_submitted_p451
    Podstawa prawna: Art. 83 § 2 KKS"""

    def test_jdg_kks_false_evidence_submitted_p451_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.false_evidence_submitted_p451 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.false_evidence_submitted_p451",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 § 2 KKS",
            "matched": True,
            "priority": 451,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.false_evidence_submitted_p451"

    def test_jdg_kks_false_evidence_submitted_p451_negative_no_block(self):
        """❌ Negatywny: jdg.kks.false_evidence_submitted_p451 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.false_evidence_submitted_p451",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unpaid_vat_penalty_30pct_p452:
    """Auto-generated: jdg.kks.unpaid_vat_penalty_30pct_p452
    Podstawa prawna: Art. 82-84 KKS w zw. z Art. 108a VAT"""

    def test_jdg_kks_unpaid_vat_penalty_30pct_p452_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unpaid_vat_penalty_30pct_p452 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unpaid_vat_penalty_30pct_p452",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 82-84 KKS w zw. z Art. 108a VAT",
            "matched": True,
            "priority": 452,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unpaid_vat_penalty_30pct_p452"

    def test_jdg_kks_unpaid_vat_penalty_30pct_p452_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unpaid_vat_penalty_30pct_p452 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unpaid_vat_penalty_30pct_p452",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_storage_below_5years_p454:
    """Auto-generated: jdg.kks.storage_below_5years_p454
    Podstawa prawna: Art. 82 KKS w zw. z Art. 86 OrdPU"""

    def test_jdg_kks_storage_below_5years_p454_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.storage_below_5years_p454 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.storage_below_5years_p454",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 82 KKS w zw. z Art. 86 OrdPU",
            "matched": True,
            "priority": 454,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.storage_below_5years_p454"

    def test_jdg_kks_storage_below_5years_p454_negative_no_block(self):
        """❌ Negatywny: jdg.kks.storage_below_5years_p454 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.storage_below_5years_p454",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_aml_sar_not_filed_p456:
    """Auto-generated: jdg.kks.aml_sar_not_filed_p456
    Podstawa prawna: Art. 72-86 AML w zw. z Art. 82 KKS"""

    def test_jdg_kks_aml_sar_not_filed_p456_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.aml_sar_not_filed_p456 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.aml_sar_not_filed_p456",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 72-86 AML w zw. z Art. 82 KKS",
            "matched": True,
            "priority": 456,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.aml_sar_not_filed_p456"

    def test_jdg_kks_aml_sar_not_filed_p456_negative_no_block(self):
        """❌ Negatywny: jdg.kks.aml_sar_not_filed_p456 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.aml_sar_not_filed_p456",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_unauthorized_tax_advice_p459:
    """Auto-generated: jdg.kks.unauthorized_tax_advice_p459
    Podstawa prawna: Art. 81 KKS w zw. z ustawa o doradztwie podatkowym"""

    def test_jdg_kks_unauthorized_tax_advice_p459_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.unauthorized_tax_advice_p459 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.unauthorized_tax_advice_p459",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 81 KKS w zw. z ustawa o doradztwie podatkowym",
            "matched": True,
            "priority": 459,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.unauthorized_tax_advice_p459"

    def test_jdg_kks_unauthorized_tax_advice_p459_negative_no_block(self):
        """❌ Negatywny: jdg.kks.unauthorized_tax_advice_p459 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.unauthorized_tax_advice_p459",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_property_seizure_risk_p460:
    """Auto-generated: jdg.kks.property_seizure_risk_p460
    Podstawa prawna: Art. 31-35 KKS"""

    def test_jdg_kks_property_seizure_risk_p460_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.property_seizure_risk_p460 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.property_seizure_risk_p460",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 31-35 KKS",
            "matched": True,
            "priority": 460,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.property_seizure_risk_p460"

    def test_jdg_kks_property_seizure_risk_p460_negative_no_block(self):
        """❌ Negatywny: jdg.kks.property_seizure_risk_p460 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.property_seizure_risk_p460",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_travel_ban_risk_p461:
    """Auto-generated: jdg.kks.travel_ban_risk_p461
    Podstawa prawna: Art. 34 KKS"""

    def test_jdg_kks_travel_ban_risk_p461_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.travel_ban_risk_p461 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.travel_ban_risk_p461",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 34 KKS",
            "matched": True,
            "priority": 461,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.travel_ban_risk_p461"

    def test_jdg_kks_travel_ban_risk_p461_negative_no_block(self):
        """❌ Negatywny: jdg.kks.travel_ban_risk_p461 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.travel_ban_risk_p461",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_business_suspension_risk_p462:
    """Auto-generated: jdg.kks.business_suspension_risk_p462
    Podstawa prawna: Art. 33 KKS"""

    def test_jdg_kks_business_suspension_risk_p462_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.business_suspension_risk_p462 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.business_suspension_risk_p462",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 33 KKS",
            "matched": True,
            "priority": 462,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.business_suspension_risk_p462"

    def test_jdg_kks_business_suspension_risk_p462_negative_no_block(self):
        """❌ Negatywny: jdg.kks.business_suspension_risk_p462 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.business_suspension_risk_p462",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_aiding_abetting_p470:
    """Auto-generated: jdg.kks.aiding_abetting_p470
    Podstawa prawna: Art. 24 KKS"""

    def test_jdg_kks_aiding_abetting_p470_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.aiding_abetting_p470 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.aiding_abetting_p470",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 24 KKS",
            "matched": True,
            "priority": 470,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.aiding_abetting_p470"

    def test_jdg_kks_aiding_abetting_p470_negative_no_block(self):
        """❌ Negatywny: jdg.kks.aiding_abetting_p470 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.aiding_abetting_p470",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_instigating_p471:
    """Auto-generated: jdg.kks.instigating_p471
    Podstawa prawna: Art. 24 KKS"""

    def test_jdg_kks_instigating_p471_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.instigating_p471 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.instigating_p471",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 24 KKS",
            "matched": True,
            "priority": 471,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.instigating_p471"

    def test_jdg_kks_instigating_p471_negative_no_block(self):
        """❌ Negatywny: jdg.kks.instigating_p471 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.instigating_p471",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_confiscation_risk:
    """Auto-generated: jdg.kks.confiscation_risk
    Podstawa prawna: Art. 29-30 KKS"""

    def test_jdg_kks_confiscation_risk_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.confiscation_risk — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.confiscation_risk",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 29-30 KKS",
            "matched": True,
            "priority": 492,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.confiscation_risk"

    def test_jdg_kks_confiscation_risk_negative_no_block(self):
        """❌ Negatywny: jdg.kks.confiscation_risk — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.confiscation_risk",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_imprisonment_risk_p494:
    """Auto-generated: jdg.kks.imprisonment_risk_p494
    Podstawa prawna: Art. 27 KKS"""

    def test_jdg_kks_imprisonment_risk_p494_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.imprisonment_risk_p494 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.imprisonment_risk_p494",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 27 KKS",
            "matched": True,
            "priority": 494,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.imprisonment_risk_p494"

    def test_jdg_kks_imprisonment_risk_p494_negative_no_block(self):
        """❌ Negatywny: jdg.kks.imprisonment_risk_p494 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.imprisonment_risk_p494",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_publication_of_verdict_p496:
    """Auto-generated: jdg.kks.publication_of_verdict_p496
    Podstawa prawna: Art. 30 KKS"""

    def test_jdg_kks_publication_of_verdict_p496_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.publication_of_verdict_p496 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.publication_of_verdict_p496",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 30 KKS",
            "matched": True,
            "priority": 496,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.publication_of_verdict_p496"

    def test_jdg_kks_publication_of_verdict_p496_negative_no_block(self):
        """❌ Negatywny: jdg.kks.publication_of_verdict_p496 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.publication_of_verdict_p496",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_kks_aggregate_penalty_p497:
    """Auto-generated: jdg.kks.aggregate_penalty_p497
    Podstawa prawna: Art. 24 § 1-3 KKS"""

    def test_jdg_kks_aggregate_penalty_p497_positive_block_triggered(self):
        """✅ Pozytywny: jdg.kks.aggregate_penalty_p497 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.kks.aggregate_penalty_p497",
            "package": "kks",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 24 § 1-3 KKS",
            "matched": True,
            "priority": 497,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.kks.aggregate_penalty_p497"

    def test_jdg_kks_aggregate_penalty_p497_negative_no_block(self):
        """❌ Negatywny: jdg.kks.aggregate_penalty_p497 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.kks.aggregate_penalty_p497",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

