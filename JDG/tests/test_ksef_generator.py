"""
Tests for Part IX — KSeF XML Generator.

Covers:
  - Basic XML generation
  - XML includes required fields
  - GTU codes included when present
  - Procedure codes included
"""

from __future__ import annotations

import pytest

pytest.importorskip("nexus_ai", reason="legacy nexus_ai package nieobecny w repo (JDG = OPA/Rego)")

from nexus_ai.services.ksef_generator import generate_ksef_xml


class TestKsefGenerator:
    def test_generate_basic_xml(self) -> None:
        """Basic invoice → valid XML string."""
        invoice = {
            "invoice_id": "test-123",
            "number": "FV/2025/001",
            "transaction_date": "2025-06-01",
            "amount_net_grosze": 10000,
            "amount_vat_grosze": 2300,
            "vendor": {"nip": "1234567890"},
            "buyer": {"nip": "0987654321"},
        }
        verdict = {"vat_rate": "0.23", "rounding_level": "position"}

        xml_str = generate_ksef_xml(invoice, verdict)
        assert xml_str.startswith("<?xml")
        assert "Faktura" in xml_str
        assert "FV/2025/001" in xml_str
        assert "100.00" in xml_str  # 10000 gr = 100.00 PLN
        assert "23.00" in xml_str  # 2300 gr = 23.00 VAT
        assert "123.00" in xml_str  # 12300 gr = 123.00 brutto

    def test_generate_with_gtu_code(self) -> None:
        """Verdict with GTU code → GTU element in XML."""
        invoice = {
            "invoice_id": "test-456",
            "number": "FV/2025/002",
            "transaction_date": "2025-06-01",
            "amount_net_grosze": 5000,
            "amount_vat_grosze": 1150,
            "vendor": {"nip": "1234567890"},
        }
        verdict = {"vat_rate": "0.23", "gtu_code": "GTU_04"}

        xml_str = generate_ksef_xml(invoice, verdict)
        assert "GTU_04" in xml_str

    def test_generate_with_procedure(self) -> None:
        """Verdict with procedure → procedure element."""
        invoice = {
            "invoice_id": "test-789",
            "number": "FV/2025/003",
            "transaction_date": "2025-06-01",
            "amount_net_grosze": 10000,
            "amount_vat_grosze": 0,
        }
        verdict = {"vat_rate": "0.00", "procedure": "VAT_REVERSE_CHARGE"}

        xml_str = generate_ksef_xml(invoice, verdict)
        assert "VAT_REVERSE_CHARGE" in xml_str
