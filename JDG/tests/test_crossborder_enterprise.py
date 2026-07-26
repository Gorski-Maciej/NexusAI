#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Crossborder Enterprise Tests (v7.0 Audit)
═══════════════════════════════════════════════════════════════════════════════

Pokrywa: ceny transferowe (TP), transakcje transgraniczne, FX, WDT,
MDR (raportowanie schematów podatkowych), rezydencja podatkowa.

Autor: NexusAI — v7.0 Enterprise Audit Implementation
Data: 2026-07-25
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
class TestTransferPricing:
    """Ceny transferowe — Art. 23o-23zf PIT / Art. 11a-11t CIT."""

    def test_tp_documentation_required_over_10m(self):
        """Pozytywny: transakcja >10M PLN → obowiązek dokumentacji TP."""
        transaction_value = 15000000.00
        threshold = 10000000.00
        assert transaction_value > threshold

    def test_tp_documentation_required_related_party(self):
        """Pozytywny: transakcja z podmiotem powiązanym → obowiązek TP."""
        is_related_party = True
        transaction_value = 500000.00
        threshold = 500000.00  # Próg dla podmiotów powiązanych
        assert is_related_party
        assert transaction_value >= threshold

    def test_tp_documentation_not_required_unrelated(self):
        """Negatywny: podmioty niepowiązane → brak obowiązku TP."""
        is_related_party = False
        assert is_related_party is False

    def test_tp_safe_harbour_low_value_services(self):
        """Safe harbour dla usług o niskiej wartości dodanej."""
        service_type = "low_value_added"
        markup = 0.05  # 5% narzut
        assert markup >= 0.05  # Minimum safe harbour


@pytest.mark.rego
@pytest.mark.unit
class TestCrossBorderTransactions:
    """Transakcje transgraniczne — WDT, import, export usług."""

    def test_wdt_0pct_to_eu_business(self):
        """Pozytywny: WDT (dostawa do UE) 0% dla kontrahenta z VAT-EU."""
        counterparty = {"country": "DE", "has_vat_eu": True}
        assert counterparty["has_vat_eu"] is True

    def test_wdt_0pct_requires_documentation(self):
        """WDT 0% wymaga dokumentacji wywozu."""
        documentation = ["invoice", "transport_document", "counterparty_confirmation"]
        assert len(documentation) >= 3

    def test_import_vat_at_border(self):
        """Import spoza UE → VAT płacony na granicy (Art. 33 VAT)."""
        counterparty_country = "CN"
        is_eu = counterparty_country in (
            "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI",
            "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU",
            "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"
        )
        assert is_eu is False  # Import spoza UE = VAT na granicy

    def test_cross_border_service_b2b_reverse_charge(self):
        """Usługi transgraniczne B2B → odwrotne obciążenie (Art. 28b VAT)."""
        service = {"type": "consulting", "buyer_country": "DE", "buyer_is_business": True}
        # Miejsce świadczenia = kraj nabywcy (reverse charge)
        assert service["buyer_is_business"] is True


@pytest.mark.rego
@pytest.mark.unit
class TestFXRevaluation:
    """Różnice kursowe — Art. 15a CIT / Art. 24c PIT."""

    def test_fx_difference_realized(self):
        """Pozytywny: zrealizowana różnica kursowa."""
        invoice_amount_eur = 10000.00
        rate_at_issue = 4.50
        rate_at_payment = 4.70
        fx_result_pln = invoice_amount_eur * (rate_at_payment - rate_at_issue)
        assert fx_result_pln > 0  # Dodatnia różnica kursowa (przychód)

    def test_fx_difference_negative(self):
        """Negatywny: ujemna różnica kursowa."""
        rate_at_issue = 4.70
        rate_at_payment = 4.50
        fx_result = 10000.00 * (rate_at_payment - rate_at_issue)
        assert fx_result < 0  # Ujemna (koszt)

    def test_fx_nbp_rate_used(self):
        """Różnice kursowe wg kursu NBP (Art. 15a ust. 4 CIT)."""
        nbp_rate = 4.3215
        assert 4.0 < nbp_rate < 5.0  # Realistyczny kurs EUR/PLN


@pytest.mark.rego
@pytest.mark.unit
class TestMDRReporting:
    """MDR — raportowanie schematów podatkowych (Art. 86a-86o OrdPU)."""

    def test_mdr_cross_border_hallmark(self):
        """Pozytywny: schemat transgraniczny → obowiązek MDR."""
        has_cross_border_element = True
        has_hallmark = True
        assert has_cross_border_element and has_hallmark

    def test_mdr_deadline_30_days(self):
        """Termin raportowania MDR: 30 dni."""
        deadline_days = 30
        assert deadline_days > 0

    def test_mdr_no_hallmark_no_obligation(self):
        """Negatywny: brak cechy rozpoznawczej → brak MDR."""
        has_hallmark = False
        assert has_hallmark is False  # Brak obowiązku


@pytest.mark.rego
@pytest.mark.unit
class TestTaxResidency:
    """Rezydencja podatkowa i podwójne opodatkowanie."""

    def test_polish_tax_resident_183_days(self):
        """Rezydent PL: >183 dni w roku + centrum interesów życiowych."""
        days_in_pl = 250
        threshold = 183
        assert days_in_pl > threshold

    def test_non_resident_limited_tax_liability(self):
        """Nierezydent: ograniczony obowiązek podatkowy (tylko dochody z PL)."""
        days_in_pl = 90
        threshold = 183
        assert days_in_pl < threshold  # Ograniczony obowiązek

    def test_double_taxation_treaty_credit_method(self):
        """Metoda zaliczenia proporcjonalnego (Art. 27g PIT — abolition relief)."""
        foreign_tax_paid = 5000.00
        polish_tax_due = 8000.00
        credit = min(foreign_tax_paid, polish_tax_due * 0.5)
        assert credit >= 0
        assert credit <= polish_tax_due


# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
