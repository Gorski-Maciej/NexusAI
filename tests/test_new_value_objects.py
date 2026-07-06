"""Testy dla nowych Value Objects: VatRate, AccountCode, BusinessKind, KSeFMetadata.

Oraz UnitOfWork pattern.
"""

from decimal import Decimal

import msgspec
from nexus_ai.domain.values import (
    AccountCode,
    BusinessKind,
    KSeFMetadata,
    VatRate,
)


class TestVatRate:
    """Testy dla VatRate Value Object."""

    def test_standard_rates(self):
        assert VatRate(value_bp=2300).rate_23
        assert VatRate(value_bp=800).rate_8
        assert VatRate(value_bp=500).rate_5
        assert VatRate(value_bp=0).rate_0

    def test_label(self):
        assert VatRate(value_bp=2300).label == "23%"
        assert VatRate(value_bp=800).label == "8%"
        assert VatRate(value_bp=0).label == "0%"

    def test_from_percent(self):
        assert VatRate.from_percent(23).rate_23
        assert VatRate.from_percent(8).rate_8
        assert VatRate.from_percent(5).rate_5
        assert VatRate.from_percent(0).rate_0

    def test_backward_compatible_value_property(self):
        """VatRate.value property returns Decimal for backward compatibility."""
        vat = VatRate(value_bp=2300)
        assert vat.value == Decimal("0.23")
        assert vat.as_decimal == Decimal("0.23")

    def test_invalid_rate_raises(self):
        try:
            VatRate(value_bp=1500)
            raise AssertionError("Should have raised ValueError")
        except ValueError:
            pass

    def test_invalid_percent_raises(self):
        try:
            VatRate.from_percent(15)
            raise AssertionError("Should have raised ValueError")
        except ValueError:
            pass

    def test_immutable(self):
        vat = VatRate(value_bp=2300)
        try:
            vat.value_bp = 800  # type: ignore
            raise AssertionError("Should be frozen")
        except (AttributeError, msgspec.ValidationError):
            pass


class TestAccountCode:
    """Testy dla AccountCode Value Object."""

    def test_expense_account(self):
        acct = AccountCode(value="401-1")
        assert acct.is_expense
        assert not acct.is_revenue
        assert acct.team == "4"

    def test_revenue_account(self):
        acct = AccountCode(value="701")
        assert acct.is_revenue
        assert not acct.is_expense
        assert acct.team == "7"

    def test_asset_account(self):
        acct = AccountCode(value="010")
        assert acct.is_asset
        assert acct.team == "0"

    def test_liability_account(self):
        acct = AccountCode(value="202")
        assert acct.is_liability
        assert acct.team == "2"

    def test_invalid_code_raises(self):
        try:
            AccountCode(value="abc")
            raise AssertionError("Should have raised ValueError")
        except ValueError:
            pass

    def test_immutable(self):
        acct = AccountCode(value="401")
        try:
            acct.value = "402"  # type: ignore
            raise AssertionError("Should be frozen")
        except (AttributeError, msgspec.ValidationError):
            pass


class TestBusinessKind:
    """Testy dla BusinessKind Value Object."""

    def test_service_kind(self):
        kind = BusinessKind(value="it")
        assert kind.is_service
        assert not kind.is_trade
        assert not kind.is_production

    def test_trade_kind(self):
        kind = BusinessKind(value="retail")
        assert kind.is_trade
        assert not kind.is_service

    def test_production_kind(self):
        kind = BusinessKind(value="manufacturing")
        assert kind.is_production

    def test_other_kind(self):
        kind = BusinessKind(value="other")
        assert not kind.is_service
        assert not kind.is_trade
        assert not kind.is_production

    def test_default(self):
        assert BusinessKind.default().value == "other"

    def test_invalid_kind_raises(self):
        try:
            BusinessKind(value="invalid_kind")
            raise AssertionError("Should have raised ValueError")
        except ValueError:
            pass

    def test_immutable(self):
        kind = BusinessKind(value="it")
        try:
            kind.value = "retail"  # type: ignore
            raise AssertionError("Should be frozen")
        except (AttributeError, msgspec.ValidationError):
            pass


class TestKSeFMetadata:
    """Testy dla KSeFMetadata Value Object."""

    def test_registered(self):
        meta = KSeFMetadata(ksef_id="1234567890ABCDEF")
        assert meta.is_registered

    def test_not_registered(self):
        meta = KSeFMetadata()
        assert not meta.is_registered

    def test_verification_url(self):
        meta = KSeFMetadata(ksef_id="1234567890ABCDEF")
        url = meta.verification_url
        assert url is not None
        assert "1234567890ABCDEF" in url

    def test_no_verification_url_when_not_registered(self):
        meta = KSeFMetadata()
        assert meta.verification_url is None

    def test_schema_version_default(self):
        meta = KSeFMetadata()
        assert meta.schema_version == "FA2"

    def test_short_ksef_id_raises(self):
        try:
            KSeFMetadata(ksef_id="12345")
            raise AssertionError("Should have raised ValueError")
        except ValueError:
            pass

    def test_immutable(self):
        meta = KSeFMetadata(ksef_id="1234567890ABCDEF")
        try:
            meta.ksef_id = None  # type: ignore
            raise AssertionError("Should be frozen")
        except (AttributeError, msgspec.ValidationError):
            pass
