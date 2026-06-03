"""
Tax Math API — endpoint kalkulacji VAT z Money (Fowler's Money).

POST /api/v2/tax/calculate-money — przyjmuje listę kwot netto jako Money,
oblicza VAT i brutto, zwraca wyniki jako Money.

Usage:
    curl -X POST http://localhost:8000/api/v2/tax/calculate-money \\
        -H "Content-Type: application/json" \\
        -d '{
              "net_amounts": [
                {"amount": "100.00", "currency": "PLN"},
                {"amount": "200.00", "currency": "PLN"}
              ],
              "vat_rate": "0.23",
              "rounding_level": "position",
              "currency": "PLN"
            }'
"""

from __future__ import annotations

import logging
from decimal import Decimal
from typing import Any

from litestar import Controller, post
from litestar.response import Response
import msgspec

from tax.math_engine import (
    TaxMathEngine,
    multiply_net_by_vat_money,
    add_tax_money,
)

logger = logging.getLogger("nexus.api.tax_math")


# ── Request / Response schemas ──────────────────────────────────────────────


class MoneyAmount(msgspec.Struct):
    """Pojedyncza kwota wyrażona jako Money.

    Attributes:
        amount: Kwota jako string dziesiętny (np. ``"100.00"``).
        currency: Kod waluty (np. ``"PLN"``, ``"EUR"``).
    """

    amount: str
    currency: str = "PLN"


class CalculateMoneyRequest(msgspec.Struct):
    """Request body dla ``POST /api/v2/tax/calculate-money``.

    Attributes:
        net_amounts: Lista kwot netto jako MoneyAmount.
        vat_rate: Stawka VAT jako string (np. ``"0.23"``).
        rounding_level: Strategia zaokrąglania — ``"position"`` lub ``"total"``.
        currency: Waluta dla wyników (domyślnie ``"PLN"``).
    """

    net_amounts: list[MoneyAmount]
    vat_rate: str = "0.23"
    rounding_level: str = "position"
    currency: str = "PLN"


# ── Controller ──────────────────────────────────────────────────────────────


class TaxMathController(Controller):
    """Kontroler kalkulacji podatkowych z obsługą Fowler's Money."""

    path = "/api/v2/tax"

    @post("/calculate-money", sync_to_thread=False)
    def calculate_money(self, data: CalculateMoneyRequest) -> Response[dict[str, Any]]:
        """Oblicz VAT i brutto dla listy kwot netto, zwracając wyniki jako Money.

        Args:
            data: Request body z listą kwot netto, stawką VAT i strategią zaokrąglania.

        Returns:
            JSON z total_net, total_vat, total_gross (serializowane jako float
            przez ``msgspec_money_enc_hook``), currency, oraz listą positions.
        """
        from services.currency_converter import Money

        # ── 0. Walidacja rounding_level ───────────────────────────────────
        if data.rounding_level not in ("position", "total"):
            return Response(
                {
                    "status": "error",
                    "message": (
                        f"Unknown rounding_level: {data.rounding_level!r}; "
                        f"expected 'position' or 'total'"
                    ),
                },
                status_code=422,
            )

        vat_rate = Decimal(data.vat_rate)

        # ── 1. Konwersja MoneyAmount → Money ──────────────────────────────
        net_money_list: list[Money] = []
        for i, ma in enumerate(data.net_amounts):
            try:
                money = Money(ma.amount, ma.currency)
            except Exception as exc:
                return Response(
                    {
                        "status": "error",
                        "message": f"Invalid amount at index {i}: {ma.amount!r} ({exc})",
                    },
                    status_code=422,
                )
            net_money_list.append(money)

        if not net_money_list:
            return Response({
                "status": "ok",
                "total_net": Money.zero(data.currency),
                "total_vat": Money.zero(data.currency),
                "total_gross": Money.zero(data.currency),
                "currency": data.currency,
                "positions": [],
            })

        # ── 2. Walidacja waluty ───────────────────────────────────────────
        first_currency = net_money_list[0].currency_code
        for i, m in enumerate(net_money_list):
            if m.currency_code != first_currency:
                return Response(
                    {
                        "status": "error",
                        "message": (
                            f"Currency mismatch at index {i}: "
                            f"expected {first_currency}, got {m.currency_code}"
                        ),
                    },
                    status_code=422,
                )

        # ── 3. Obliczenia VAT ──────────────────────────────────────────────
        total_vat_money, inv_positions = TaxMathEngine.calculate_positions_vat_money(
            net_money_list,
            vat_rate,
            data.rounding_level,
        )

        total_net_money = TaxMathEngine.sum_positions_net_money(net_money_list)
        total_gross_money = add_tax_money(total_net_money, total_vat_money)

        # ── 4. Szczegóły pozycji ──────────────────────────────────────────
        positions_result: list[dict[str, Any]] = []
        for np_net, inv_pos in zip(net_money_list, inv_positions):
            vat_money = multiply_net_by_vat_money(np_net, vat_rate)
            gross_money = add_tax_money(np_net, vat_money)
            positions_result.append({
                "net": np_net,
                "vat": vat_money,
                "gross": gross_money,
                "vat_rate": str(vat_rate),
            })

        return Response({
            "status": "ok",
            "total_net": total_net_money,
            "total_vat": total_vat_money,
            "total_gross": total_gross_money,
            "currency": first_currency,
            "positions": positions_result,
        })
