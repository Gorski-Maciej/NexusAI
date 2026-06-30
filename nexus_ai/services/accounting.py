from __future__ import annotations

from decimal import ROUND_HALF_UP, Decimal
from typing import final

from nexus_ai.domain.values import Money


@final
class AccountingService:
    """Centralny serwis księgowy.

    Używa Money (msgspec.Struct) zamiast gołych Decimal.
    """

    @staticmethod
    def validate_amounts(net: Decimal, gross: Decimal) -> bool:
        if net <= 0 or gross <= 0 or gross < net:
            return False

        vat_amount = gross - net
        if vat_amount == 0:
            return True

        effective_rate = (vat_amount / net).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        valid_rates = [Decimal("0.23"), Decimal("0.08"), Decimal("0.05"), Decimal("0.00")]

        if effective_rate in valid_rates:
            return True

        calculated_rates = [
            round(net * Decimal("1.23"), 2),
            round(net * Decimal("1.08"), 2),
            round(net * Decimal("1.05"), 2),
        ]
        return round(gross, 2) in calculated_rates

    @staticmethod
    def calculate_vat(net: Decimal, rate: float = 0.23) -> Decimal:
        """Oblicz VAT używając Money."""
        vat = net * Decimal(str(rate))
        return vat.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    @staticmethod
    def calculate_vat_money(net: Money, rate: Decimal = Decimal("0.23")) -> Money:
        """Oblicz VAT dla kwoty Money.

        Args:
            net: Kwota netto jako Money.
            rate: Stawka VAT (domyślnie 23%%).

        Returns:
            VAT jako Money.
        """
        return net * rate

    @staticmethod
    def validate_net_vat_gross(net: Money, vat: Money, gross: Money) -> bool:
        """Sprawdź czy netto + VAT = brutto."""
        try:
            return (net + vat).amount == gross.amount
        except Exception:
            return False
