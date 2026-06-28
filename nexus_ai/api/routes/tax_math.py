"""
Tax Math API — endpoint kalkulacji VAT z Decimal.

POST /api/v2/tax/calculate-money — przyjmuje listę kwot netto jako stringi,
oblicza VAT i brutto, zwraca wyniki.

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

from decimal import Decimal, ROUND_HALF_UP
from typing import Any

import msgspec
from litestar import Controller, post
from litestar.response import Response
from structlog import get_logger

from nexus_ai.api.dto import (
    TAG_TAX,
    TaxMathRequestDTO,
    TaxMathResponseDTO,
)

logger = get_logger("nexus.api.tax_math")


# ── Helpers: VAT calculation (inline, zastępuje usunięty stary moduł matematyczny) ────


def _round_money(value: Decimal) -> Decimal:
    """Zaokrąglij kwotę do 2 miejsc po przecinku (ROUND_HALF_UP)."""
    return value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def _calc_vat_per_position(net: Decimal, vat_rate: Decimal) -> Decimal:
    """Oblicz VAT dla pojedynczej pozycji: net * vat_rate, zaokrąglone do 0.01."""
    return _round_money(net * vat_rate)


# ── Request / Response schemas ──────────────────────────────────────────────


class MoneyAmount(msgspec.Struct):
    """Pojedyncza kwota.

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
    """Kontroler kalkulacji podatkowych."""

    path = "/tax"
    tags = [TAG_TAX]

    @post(
        "/calculate-money",
        sync_to_thread=False,
        dto=TaxMathRequestDTO,
        return_dto=TaxMathResponseDTO,
        summary="Calculate VAT and gross amounts",
        description=(
            "Accepts a list of net amounts, applies the specified VAT rate "
            "with configurable rounding strategy, and returns total net, VAT, "
            "and gross amounts. "
            "Supports ``position`` (per-item) and ``total`` (aggregate) rounding."
        ),
        operation_id="calculateTaxMoney",
    )
    def calculate_money(self, data: CalculateMoneyRequest) -> Response[dict[str, Any]]:
        """Oblicz VAT i brutto dla listy kwot netto.

        Args:
            data: Request body z listą kwot netto, stawką VAT i strategią zaokrąglania.

        Returns:
            JSON z total_net, total_vat, total_gross, currency oraz listą positions.
        """
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
        currency = data.currency

        # ── 1. Konwersja string → Decimal ─────────────────────────────────
        net_decimals: list[Decimal] = []
        for i, ma in enumerate(data.net_amounts):
            try:
                amount = Decimal(ma.amount)
            except Exception as exc:
                return Response(
                    {
                        "status": "error",
                        "message": f"Invalid amount at index {i}: {ma.amount!r} ({exc})",
                    },
                    status_code=422,
                )
            net_decimals.append(amount)

        if not net_decimals:
            return Response(
                {
                    "status": "ok",
                    "total_net": "0.00",
                    "total_vat": "0.00",
                    "total_gross": "0.00",
                    "currency": currency,
                    "positions": [],
                }
            )

        # ── 2. Obliczenia VAT ──────────────────────────────────────────────
        if data.rounding_level == "position":
            # Zaokrąglenie per-position: każda pozycja osobno
            positions: list[dict[str, Any]] = []
            for net in net_decimals:
                vat = _calc_vat_per_position(net, vat_rate)
                gross = _round_money(net + vat)
                positions.append(
                    {
                        "net": str(_round_money(net)),
                        "vat": str(vat),
                        "gross": str(gross),
                        "vat_rate": str(vat_rate),
                    }
                )

            total_net = sum(Decimal(p["net"]) for p in positions)
            total_vat = sum(Decimal(p["vat"]) for p in positions)
            total_gross = sum(Decimal(p["gross"]) for p in positions)

        else:
            # Zaokrąglenie total: suma netto × stawka, zaokrąglone raz
            total_net = sum(net_decimals)
            total_vat = _round_money(total_net * vat_rate)
            total_gross = _round_money(total_net + total_vat)

            positions = []
            for net in net_decimals:
                # W trybie "total" vat per-position wyliczamy proporcjonalnie
                vat = _round_money(net * vat_rate)
                gross = _round_money(net + vat)
                positions.append(
                    {
                        "net": str(_round_money(net)),
                        "vat": str(vat),
                        "gross": str(gross),
                        "vat_rate": str(vat_rate),
                    }
                )

        return Response(
            {
                "status": "ok",
                "total_net": str(_round_money(total_net)),
                "total_vat": str(_round_money(total_vat)),
                "total_gross": str(_round_money(total_gross)),
                "currency": currency,
                "positions": positions,
            }
        )
