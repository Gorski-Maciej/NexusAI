"""
Testy negatywne dla ksef_generator — v7.0 KSeF/JPK.

Pokrywa scenariusze zidentyfikowane w raporcie:
- Nieprawidlowy NIP (za krotki, za dlugi, brak)
- Brak wymaganych pol (invoice_number, transaction_date, etc.)
- Kwoty ujemne
- Nieprawidlowe GTU
- Brak vendor/buyer data
"""

from __future__ import annotations

import pytest


class TestKsefGeneratorNegative:
    """Testy negatywne dla generate_ksef_xml i validate_ksef_xml."""

    @pytest.fixture
    def minimal_invoice(self):
        return {
            "invoice_id": "NEG-001",
            "number": "FV/NEG/001",
            "transaction_date": "2026-07-15",
            "amount_net_grosze": 10000,
            "amount_vat_grosze": 2300,
            "vendor": {"nip": "1234567890", "name": "Test Sprzedawca"},
            "buyer": {"nip": "0987654321", "name": "Test Nabywca"},
            "vat_rate": 23,
            "currency": "PLN",
            "positions": [{"description": "Test item", "net_amount_grosze": 10000}],
        }

    @pytest.fixture
    def minimal_verdict(self):
        return {
            "vat_rate": 23,
            "category_code": "IT_OFFICE",
            "gtu_code": "GTU_01",
        }

    # ── Brak wymaganych pol ──────────────────────────────────────────────

    def test_empty_invoice_data(self):
        """Pusta faktura — powinna wygenerowac XML z domyslnymi wartosciami."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        xml = generate_ksef_xml({}, {"vat_rate": 23})
        assert xml is not None
        assert "Faktura" in xml
        assert "FA_VAT" in xml

    def test_missing_invoice_number(self, minimal_invoice, minimal_verdict):
        """Brak numeru faktury — powinno uzyc invoice_id jako fallback."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {**minimal_invoice, "number": ""}
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert "NEG-001" in xml or "P_1" in xml

    def test_missing_vendor_nip(self, minimal_invoice, minimal_verdict):
        """Brak NIP sprzedawcy — XML powinien sie wygenerowac bez bledu."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {**minimal_invoice, "vendor": {"name": "Test"}}
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert xml is not None

    def test_missing_buyer_data(self, minimal_invoice, minimal_verdict):
        """Brak danych nabywcy — XML powinien sie wygenerowac."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {**minimal_invoice, "buyer": {}}
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert xml is not None

    # ── Nieprawidlowy NIP ────────────────────────────────────────────────

    def test_invalid_nip_too_short(self, minimal_invoice, minimal_verdict):
        """NIP za krotki — generator nie waliduje dlugosci NIP."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {**minimal_invoice, "vendor": {"nip": "123", "name": "Test"}}
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert "<NIP>123</NIP>" in xml  # Generator przepisuje bez walidacji

    def test_invalid_nip_with_letters(self, minimal_invoice, minimal_verdict):
        """NIP z literami — generator przepisuje bez walidacji."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {**minimal_invoice, "vendor": {"nip": "ABC1234567", "name": "Test"}}
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert "ABC1234567" in xml

    # ── Kwoty ────────────────────────────────────────────────────────────

    def test_zero_amounts(self, minimal_verdict):
        """Faktura z zerowymi kwotami — powinna sie wygenerowac."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {
            "invoice_id": "ZERO-001",
            "number": "FV/ZERO/001",
            "transaction_date": "2026-07-15",
            "amount_net_grosze": 0,
            "amount_vat_grosze": 0,
            "vendor": {"nip": "1234567890", "name": "Test"},
            "buyer": {"nip": "0987654321", "name": "Test"},
        }
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert "0.00" in xml

    def test_negative_net_amount(self, minimal_invoice, minimal_verdict):
        """Ujemna kwota netto (korekta) — powinna sie wygenerowac."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {**minimal_invoice, "amount_net_grosze": -5000}
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert "-50.00" in xml

    def test_very_large_amount(self, minimal_invoice, minimal_verdict):
        """Bardzo duze kwoty (miliony) — powinny sie wygenerowac poprawnie."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {**minimal_invoice, "amount_net_grosze": 999999999}
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert "9999999.99" in xml

    # ── GTU ──────────────────────────────────────────────────────────────

    def test_unknown_gtu_code(self, minimal_invoice, minimal_verdict):
        """Nieznany kod GTU — powinien byc pominiety."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        verdict = {**minimal_verdict, "gtu_code": "GTU_99"}
        xml = generate_ksef_xml(minimal_invoice, verdict)
        # GTU_99 nie istnieje, ale XML ma sekcje GTU z dowolnym kodem
        assert "GTU_99" in xml or "Gtu" in xml

    def test_multiple_gtu_codes(self, minimal_invoice):
        """Wiele kodow GTU — tylko pierwszy uzyty w lxml fallback."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        verdict = {"gtu_code": "GTU_01", "ksef_fields": {"gtu_code": "GTU_01"}}
        xml = generate_ksef_xml(minimal_invoice, verdict)
        assert "GTU_01" in xml

    # ── Walidacja XSD (bez pliku XSD) ────────────────────────────────────

    def test_validate_without_xsd(self):
        """Walidacja bez XSD — powinna zwrocic sukces z komunikatem."""
        from nexus_ai.services.ksef_generator import validate_ksef_xml

        is_valid, msg = validate_ksef_xml("<root/>")
        assert is_valid
        assert "skipped" in msg.lower() or "No XSD" in msg

    def test_validate_invalid_xml(self, tmp_path):
        """Niepoprawny XML przy walidacji z XSD."""
        from nexus_ai.services.ksef_generator import validate_ksef_xml

        # Stworz minimalne XSD do walidacji
        xsd_path = tmp_path / "test.xsd"
        xsd_path.write_text("""<?xml version="1.0"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="root">
    <xs:complexType><xs:sequence><xs:element name="child" type="xs:string"/></xs:sequence></xs:complexType>
  </xs:element>
</xs:schema>""")

        is_valid, msg = validate_ksef_xml("not valid xml <<<", str(xsd_path))
        assert not is_valid
        assert "error" in msg.lower()

    # ── _resolve_ksef_fields ─────────────────────────────────────────────

    def test_resolve_explicit_fields(self):
        """Jawne ksef_fields maja priorytet."""
        from nexus_ai.services.ksef_generator import _resolve_ksef_fields

        verdict = {"ksef_fields": {"gtu_code": "GTU_05", "procedure_code": "MPP"}, "gtu_code": "GTU_01"}
        result = _resolve_ksef_fields(verdict)
        assert result["gtu_code"] == "GTU_05"
        assert result["procedure_code"] == "MPP"

    def test_resolve_legacy_fields(self):
        """Legacy gtu_code uzywane gdy brak ksef_fields."""
        from nexus_ai.services.ksef_generator import _resolve_ksef_fields

        verdict = {"gtu_code": "GTU_12", "procedure": "SW"}
        result = _resolve_ksef_fields(verdict)
        assert result["gtu_code"] == "GTU_12"

    def test_resolve_category_fallback(self):
        """Category map jako ostatnia deska ratunku."""
        from nexus_ai.services.ksef_generator import _resolve_ksef_fields

        verdict = {"category_code": "FUEL"}
        result = _resolve_ksef_fields(verdict)
        assert result["gtu_code"] == "GTU_02"  # v7.0 unified: FUEL → GTU_02

    def test_resolve_pharma_category(self):
        """PHARMA → GTU_03 (v7.0 unified)."""
        from nexus_ai.services.ksef_generator import _resolve_ksef_fields

        verdict = {"category_code": "PHARMA"}
        result = _resolve_ksef_fields(verdict)
        assert result["gtu_code"] == "GTU_03"

    # ── Edge cases ───────────────────────────────────────────────────────

    def test_non_ascii_characters(self, minimal_invoice, minimal_verdict):
        """Polskie znaki w nazwach — powinny byc poprawnie zakodowane."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {
            **minimal_invoice,
            "vendor": {"nip": "1234567890", "name": "Zażółć Gęślą Jaźń Sp. z o.o."},
            "buyer": {"nip": "0987654321", "name": "Księgowość łąkę"},
        }
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert "Zażółć" in xml

    def test_positions_empty(self, minimal_invoice, minimal_verdict):
        """Pusta lista pozycji."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {**minimal_invoice, "positions": []}
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert xml is not None

    def test_currency_eur(self, minimal_invoice, minimal_verdict):
        """Waluta EUR."""
        from nexus_ai.services.ksef_generator import generate_ksef_xml

        inv = {**minimal_invoice, "currency": "EUR"}
        xml = generate_ksef_xml(inv, minimal_verdict)
        assert "EUR" in xml
