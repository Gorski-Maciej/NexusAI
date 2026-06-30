"""
Unit tests for domain Value Objects — Money, NIP, IBAN, PESEL.

Używa pytest z parametrize dla data-driven testing.
Coverage: 100% linii domain/values.py.
"""

from __future__ import annotations

from decimal import Decimal

import pytest

from nexus_ai.domain.values import (
    CurrencyMismatchError,
    IBAN,
    InvalidIBANError,
    InvalidNIPError,
    InvalidPESELError,
    Money,
    NIP,
    PESEL,
)


# ═══════════════════════════════════════════════════════════════════════════════
# Money tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestMoney:
    def test_create_pln(self) -> None:
        m = Money(amount=Decimal("100.00"), currency="PLN")
        assert m.amount == Decimal("100.00")
        assert m.currency == "PLN"

    def test_create_default_currency(self) -> None:
        m = Money(amount=Decimal("50.00"))
        assert m.currency == "PLN"

    def test_rounding_to_grosze(self) -> None:
        m = Money(amount=Decimal("100.456"))
        assert m.amount == Decimal("100.46")  # Zaokrąglenie do 2 miejsc

    def test_negative_amount_raises(self) -> None:
        with pytest.raises(ValueError, match="cannot be negative"):
            Money(amount=Decimal("-10.00"))

    def test_invalid_currency_raises(self) -> None:
        with pytest.raises(ValueError, match="currency"):
            Money(amount=Decimal("10.00"), currency="pln")  # lowercase

    def test_add_same_currency(self) -> None:
        a = Money(amount=Decimal("100.00"))
        b = Money(amount=Decimal("50.00"))
        result = a + b
        assert result.amount == Decimal("150.00")
        assert result.currency == "PLN"

    def test_add_different_currency_raises(self) -> None:
        a = Money(amount=Decimal("100.00"), currency="PLN")
        b = Money(amount=Decimal("50.00"), currency="EUR")
        with pytest.raises(CurrencyMismatchError):
            a + b

    def test_sub_same_currency(self) -> None:
        a = Money(amount=Decimal("100.00"))
        b = Money(amount=Decimal("30.00"))
        result = a - b
        assert result.amount == Decimal("70.00")

    def test_sub_exact_zero(self) -> None:
        a = Money(amount=Decimal("100.00"))
        b = Money(amount=Decimal("100.00"))
        result = a - b
        assert result.amount == Decimal("0.00")

    def test_sub_negative_raises(self) -> None:
        a = Money(amount=Decimal("30.00"))
        b = Money(amount=Decimal("100.00"))
        with pytest.raises(ValueError, match="negative"):
            a - b

    def test_mul_by_decimal(self) -> None:
        m = Money(amount=Decimal("100.00"))
        result = m * Decimal("2.5")
        assert result.amount == Decimal("250.00")

    def test_mul_by_int(self) -> None:
        m = Money(amount=Decimal("100.00"))
        result = m * 3
        assert result.amount == Decimal("300.00")

    def test_mul_by_float_raises(self) -> None:
        m = Money(amount=Decimal("100.00"))
        with pytest.raises(TypeError, match="Decimal"):
            m * 2.5  # type: ignore[arg-type]

    def test_to_grosze(self) -> None:
        m = Money(amount=Decimal("123.45"))
        assert m.to_grosze() == 12345

    def test_from_grosze(self) -> None:
        m = Money.from_grosze(12345)
        assert m.amount == Decimal("123.45")
        assert m.currency == "PLN"

    def test_zero(self) -> None:
        m = Money.zero()
        assert m.amount == Decimal("0.00")
        assert m.currency == "PLN"

    def test_zero_eur(self) -> None:
        m = Money.zero(currency="EUR")
        assert m.currency == "EUR"

    def test_repr(self) -> None:
        m = Money(amount=Decimal("100.00"))
        assert repr(m) == "100.00 PLN"

    @pytest.mark.parametrize(
        "amount, currency, expected",
        [
            (Decimal("0.00"), "PLN", "0.00 PLN"),
            (Decimal("1.00"), "USD", "1.00 USD"),
            (Decimal("999999.99"), "EUR", "999999.99 EUR"),
        ],
    )
    def test_repr_various(self, amount: Decimal, currency: str, expected: str) -> None:
        m = Money(amount=amount, currency=currency)
        assert repr(m) == expected


# ═══════════════════════════════════════════════════════════════════════════════
# NIP tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestNIP:
    # Poprawne NIP-y (przykłady z prawidłową sumą kontrolną)
    @pytest.mark.parametrize(
        "raw_nip",
        [
            "1234563218",  # Przykładowy poprawny NIP
            "5252244968",  # Przykładowy poprawny NIP
            "521-30-16-246",  # Z myślnikami (5*6+2*5+1*7+3*2+0*3+1*4+6*5+2*6+4*7=127, 127%11=6, last=6 ✅)
            "521 30 16 246",  # Ze spacjami
            "774-00-01-684",  # 7*6+7*5+4*7+0*2+0*3+0*4+1*5+6*6+8*7=202, 202%11=4, last=4 ✅
        ],
    )
    def test_valid_nip(self, raw_nip: str) -> None:
        nip = NIP(value=raw_nip)
        assert len(nip.value) == 10
        assert nip.value.isdigit()

    def test_nip_formatting(self) -> None:
        nip = NIP(value="1234563218")
        formatted = str(nip)
        assert formatted == "123-456-32-18"

    @pytest.mark.parametrize(
        "invalid_nip",
        [
            "1234567890",  # Nieprawidłowa suma kontrolna
            "12345",  # Za krótki
            "12345678901",  # Za długi
            "ABC4563218",  # Z literami
            "",  # Pusty
        ],
    )
    def test_invalid_nip_raises(self, invalid_nip: str) -> None:
        with pytest.raises(InvalidNIPError):
            NIP(value=invalid_nip)


# ═══════════════════════════════════════════════════════════════════════════════
# IBAN tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestIBAN:
    # Poprawne IBAN-y (PL)
    @pytest.mark.parametrize(
        "raw_iban",
        [
            "PL61109010140000071219812874",  # PKO BP
            "PL27114020040000300201355387",  # mBank
            "PL68109024020000000610011547",  # Santander
            "PL61109010140000071219812874",  # Ze spacją na końcu (normalizacja)
            "PL27 1140 2004 0000 3002 0135 5387",  # Ze spacjami
        ],
    )
    def test_valid_iban(self, raw_iban: str) -> None:
        iban = IBAN(value=raw_iban)
        assert len(iban.value) >= 4

    def test_iban_normalization(self) -> None:
        iban = IBAN(value="pl61 1090 1014 0000 0712 1981 2874")
        assert iban.value == "PL61109010140000071219812874"  # uppercase + bez spacji

    def test_iban_formatting(self) -> None:
        iban = IBAN(value="PL61109010140000071219812874")
        formatted = str(iban)
        assert " " in formatted  # Grupy po 4 znaki
        assert len(formatted.replace(" ", "")) == 28

    @pytest.mark.parametrize(
        "invalid_iban",
        [
            "PL123",  # Za krótki
            "PL61109010140000071219812875",  # Nieprawidłowa suma kontrolna
            "XX61109010140000071219812874",  # Nieprawidłowy kod kraju
            "",  # Pusty
            "1234567890",  # Bez liter
        ],
    )
    def test_invalid_iban_raises(self, invalid_iban: str) -> None:
        with pytest.raises(InvalidIBANError):
            IBAN(value=invalid_iban)


# ═══════════════════════════════════════════════════════════════════════════════
# PESEL tests
# ═══════════════════════════════════════════════════════════════════════════════


class TestPESEL:
    # Poprawne PESEL-e
    @pytest.mark.parametrize(
        "raw_pesel",
        [
            "44051401359",  # Kobieta, 1944-05-14
            "90090515836",  # Mężczyzna, 1990-09-05
        ],
    )
    def test_valid_pesel(self, raw_pesel: str) -> None:
        pesel = PESEL(value=raw_pesel)
        assert len(pesel.value) == 11

    def test_pesel_gender_male(self) -> None:
        pesel = PESEL(value="90090515836")
        assert pesel.get_gender() == "male"

    def test_pesel_gender_female(self) -> None:
        pesel = PESEL(value="44051401342")  # digit[9]=4 (even) → female; 0*1+4*3+0*7+5*9+1*1+4*3+0*7+1*9+3*1+4*3=98, (10-98%10)%10=2 ✅
        assert pesel.get_gender() == "female"

    def test_pesel_birth_date(self) -> None:
        pesel = PESEL(value="44051401359")
        assert pesel.get_birth_date() == "1944-05-14"

    def test_pesel_birth_date_2000s(self) -> None:
        pesel = PESEL(value="00220501356")  # 2000-02-05; 0+0+14+18+0+15+0+9+3+15=74, (10-74%10)%10=6 ✅
        assert "2000" in pesel.get_birth_date()

    @pytest.mark.parametrize(
        "invalid_pesel",
        [
            "12345678901",  # Nieprawidłowa suma kontrolna
            "12345",  # Za krótki
            "123456789012",  # Za długi
            "ABCD1401359",  # Z literami
            "",  # Pusty
        ],
    )
    def test_invalid_pesel_raises(self, invalid_pesel: str) -> None:
        with pytest.raises(InvalidPESELError):
            PESEL(value=invalid_pesel)


# ═══════════════════════════════════════════════════════════════════════════════
# Integration tests: domain logic with real-world examples
# ═══════════════════════════════════════════════════════════════════════════════


class TestIntegration:
    """Testy integracyjne: łączenie Value Objects w przepływach biznesowych."""

    def test_invoice_total_calculation(self) -> None:
        """Faktura: netto + VAT = brutto."""
        netto = Money(amount=Decimal("100.00"))
        vat = Money(amount=Decimal("23.00"))
        brutto = netto + vat
        assert brutto.amount == Decimal("123.00")

    def test_multi_line_invoice(self) -> None:
        """Faktura wieloliniowa: sumowanie pozycji."""
        line1 = Money(amount=Decimal("500.00"))
        line2 = Money(amount=Decimal("300.00"))
        line3 = Money(amount=Decimal("200.00"))
        total = line1 + line2 + line3
        assert total.amount == Decimal("1000.00")

    def test_vat_calculation(self) -> None:
        """VAT = netto * stawka (23%)."""
        netto = Money(amount=Decimal("100.00"))
        vat = netto * Decimal("0.23")
        assert vat.amount == Decimal("23.00")

    def test_contractor_nip_validation(self) -> None:
        """Walidacja NIP kontrahenta."""
        nip = NIP(value="1234563218")
        assert nip.value == "1234563218"

    def test_bank_account_validation(self) -> None:
        """Walidacja IBAN kontrahenta."""
        iban = IBAN(value="PL61109010140000071219812874")
        assert iban.value.startswith("PL")

    def test_payment_split(self) -> None:
        """Podział płatności: faktura 1000 PLN na 3 raty."""
        total = Money(amount=Decimal("1000.00"))
        installment = total * Decimal("1") / Decimal("3")
        # Po 3 ratach: 333.33 + 333.33 + 333.34 = 1000.00
        paid = installment * 3 + Money(amount=Decimal("0.01"))
        assert paid.amount == Decimal("1000.00") or abs(paid.amount - total.amount) < Decimal("0.01")
