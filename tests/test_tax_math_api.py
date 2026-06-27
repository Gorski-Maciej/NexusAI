"""
Tests for Business Logic of POST /api/v2/tax/calculate-money.

Ze względu na:
- metaclass conflict w litestar 2.23.0 na Python 3.13
- brak duckdb (importowanego przez tax/__init__.py → tax/rules.py)

Testujemy logikę kalkulacji VAT w groszach (int) — która jest tą samą kalkulacją,
jakiej używa endpoint, tylko bez warstwy Money.
"""

from __future__ import annotations

import importlib.util
import sys
from decimal import Decimal
from pathlib import Path

import pytest


# ── Load tax.math_engine directly via importlib (bypass tax/__init__.py) ─────

_MATH_ENGINE_PATH = (
    Path(__file__).resolve().parents[1] / "Code" / "tax" / "math_engine.py"
)
_SPEC = importlib.util.spec_from_file_location(
    "tax.math_engine", str(_MATH_ENGINE_PATH),
)
assert _SPEC is not None and _SPEC.loader is not None
_MATH = importlib.util.module_from_spec(_SPEC)
sys.modules["tax.math_engine"] = _MATH
_SPEC.loader.exec_module(_MATH)

multiply_net_by_vat = _MATH.multiply_net_by_vat
add_tax = _MATH.add_tax
to_grosze = _MATH.to_grosze
to_zlotowki = _MATH.to_zlotowki
calculate_vat_by_policy = _MATH.calculate_vat_by_policy
InvoicePositions = _MATH.InvoicePositions
validate_invariants = _MATH.validate_invariants
InvoiceSummary = _MATH.InvoiceSummary
TaxMathEngine = _MATH.TaxMathEngine
RoundingPolicy = _MATH.RoundingPolicy
parse_rate = _MATH.parse_rate


# ── Helper: symuluje logikę endpointu bez Money i bez TaxMathEngine class ───


def _simulate_calculate_grosze(
    net_amounts_gr: list[int],
    vat_rate: Decimal,
    rounding_level: str = "position",
) -> dict:
    """Symuluje logikę endpointu używając groszy (int)."""
    if not net_amounts_gr:
        return {
            "status": "ok",
            "total_net_gr": 0,
            "total_vat_gr": 0,
            "total_gross_gr": 0,
            "positions": [],
        }

    if rounding_level not in ("position", "total"):
        return {"status": "error", "message": f"Unknown rounding_level: {rounding_level!r}"}

    total_vat_gr, inv_positions = _calculate_positions_vat_grosze(
        net_amounts_gr, vat_rate, rounding_level,
    )

    total_net_gr = sum(net_amounts_gr)
    total_gross_gr = add_tax(total_net_gr, total_vat_gr)

    positions = []
    for net_gr in net_amounts_gr:
        vat_gr = multiply_net_by_vat(net_gr, vat_rate)
        gross_gr = add_tax(net_gr, vat_gr)
        positions.append({
            "net_gr": net_gr,
            "vat_gr": vat_gr,
            "gross_gr": gross_gr,
            "vat_rate": str(vat_rate),
        })

    return {
        "status": "ok",
        "total_net_gr": total_net_gr,
        "total_vat_gr": total_vat_gr,
        "total_gross_gr": total_gross_gr,
        "positions": positions,
    }


def _calculate_positions_vat_grosze(
    net_amounts_gr: list[int],
    vat_rate: Decimal,
    rounding_level: str,
) -> tuple[int, list]:
    inv_positions = [
        InvoicePositions(net_grosze=net_gr, vat_rate=vat_rate)
        for net_gr in net_amounts_gr
    ]
    total_vat = calculate_vat_by_policy(inv_positions, vat_rate, rounding_level)
    return total_vat, inv_positions


def _to_gr(amount: str) -> int:
    """Convert decimal string to grosze."""
    return to_grosze(Decimal(amount))


# ── Tests ───────────────────────────────────────────────────────────────────


class TestVatCalculationGrosze:
    """Testy kalkulacji VAT w groszach."""

    def test_single_position_position_rounding(self):
        data = _simulate_calculate_grosze([_to_gr("100.00")], Decimal("0.23"))
        assert data["status"] == "ok"
        assert data["total_net_gr"] == 10000
        assert data["total_vat_gr"] == 2300
        assert data["total_gross_gr"] == 12300
        assert len(data["positions"]) == 1
        assert data["positions"][0]["net_gr"] == 10000
        assert data["positions"][0]["vat_gr"] == 2300
        assert data["positions"][0]["gross_gr"] == 12300

    def test_multiple_positions(self):
        data = _simulate_calculate_grosze(
            [_to_gr("100.00"), _to_gr("200.00"), _to_gr("50.00")],
            Decimal("0.23"),
        )
        assert data["total_net_gr"] == 35000
        assert data["total_vat_gr"] == 8050
        assert data["total_gross_gr"] == 43050
        assert len(data["positions"]) == 3

    def test_total_rounding(self):
        data = _simulate_calculate_grosze(
            [_to_gr("100.00"), _to_gr("200.00")],
            Decimal("0.23"),
            rounding_level="total",
        )
        assert data["total_net_gr"] == 30000
        assert data["total_vat_gr"] == 6900  # 30000*0.23
        assert data["total_gross_gr"] == 36900

    def test_vat_rate_8pct(self):
        data = _simulate_calculate_grosze([_to_gr("150.00")], Decimal("0.08"))
        assert data["total_vat_gr"] == 1200  # 12.00

    def test_vat_rate_5_5pct(self):
        data = _simulate_calculate_grosze([_to_gr("100.00")], Decimal("0.055"))
        assert data["total_vat_gr"] == 550  # 5.50

    def test_zero_vat_rate(self):
        data = _simulate_calculate_grosze([_to_gr("100.00")], Decimal("0.00"))
        assert data["total_vat_gr"] == 0
        assert data["total_gross_gr"] == 10000

    def test_negative_amount(self):
        data = _simulate_calculate_grosze([_to_gr("-50.00")], Decimal("0.23"))
        assert data["total_net_gr"] == -5000
        assert data["total_vat_gr"] == -1150
        assert data["total_gross_gr"] == -6150

    def test_large_amount(self):
        """9,999,999.99 PLN = 999,999,999 gr."""
        data = _simulate_calculate_grosze([999999999], Decimal("0.23"))
        # 999999999 * 0.23 = 229999999.77 → round HALF_UP → 230000000 gr
        assert data["total_vat_gr"] == 230000000

    def test_three_positions_vat_sum(self):
        data = _simulate_calculate_grosze(
            [_to_gr("123.45"), _to_gr("67.89"), _to_gr("250.00")],
            Decimal("0.23"),
        )
        # 12345*0.23=2839.35→2839, 6789*0.23=1561.47→1561, 25000*0.23=5750→5750
        # Sum = 2839+1561+5750 = 10150
        assert data["total_vat_gr"] == 10150
        position_vat_sum = sum(p["vat_gr"] for p in data["positions"])
        assert position_vat_sum == 10150


class TestEdgeCases:
    """Testy brzegowe."""

    def test_empty_list(self):
        data = _simulate_calculate_grosze([], Decimal("0.23"))
        assert data["total_net_gr"] == 0
        assert data["total_vat_gr"] == 0
        assert data["positions"] == []

    def test_zero_amount(self):
        data = _simulate_calculate_grosze([0], Decimal("0.23"))
        assert data["total_vat_gr"] == 0

    def test_invalid_rounding_level(self):
        data = _simulate_calculate_grosze([10000], Decimal("0.23"), "INVALID")
        assert data["status"] == "error"

    def test_position_vs_total_rounding_differ(self):
        """Position and total rounding give different results for split cents."""
        amounts_gr = [33, 33, 34]  # sum = 100
        pos = _simulate_calculate_grosze(amounts_gr, Decimal("0.23"), "position")
        tot = _simulate_calculate_grosze(amounts_gr, Decimal("0.23"), "total")
        assert pos["total_vat_gr"] == 24  # 8+8+8
        assert tot["total_vat_gr"] == 23  # 100*0.23

    def test_single_grosz_rounding_halv_up(self):
        """ROUND_HALF_UP boundary: 0.5 rounds up, 0.49 rounds down."""
        assert multiply_net_by_vat(2, Decimal("0.25")) == 1  # 2*0.25=0.5→1
        assert multiply_net_by_vat(2, Decimal("0.24")) == 0  # 2*0.24=0.48→0


class TestGroszeRoundTrip:
    """Testy round-trip to_grosze ↔ to_zlotowki."""

    def test_clean_values(self):
        for gr in [0, 1, 100, 12345, 99999999]:
            assert to_grosze(to_zlotowki(gr)) == gr

    def test_fractional_zlotowki(self):
        """to_grosze rounds HALF_UP."""
        assert to_grosze(Decimal("1.234")) == 123  # 1.234*100=123.4→123
        assert to_grosze(Decimal("1.235")) == 124  # 1.235*100=123.5→124


class TestValidateInvariants:
    """Testy niezmienników matematycznych."""

    def test_valid(self):
        positions = [
            InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23")),
            InvoicePositions(net_grosze=20000, vat_rate=Decimal("0.23")),
        ]
        summary = InvoiceSummary(
            netto_grosze=30000,
            vat_grosze=6900,  # 2300+4600
            brutto_grosze=36900,
        )
        result = validate_invariants(positions, summary)
        assert result.is_valid

    def test_invariant_1_failure(self):
        positions = [InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23"))]
        summary = InvoiceSummary(netto_grosze=9999, vat_grosze=2300, brutto_grosze=12299)
        result = validate_invariants(positions, summary)
        assert not result.is_valid

    def test_invariant_3_failure(self):
        """Netto + VAT != Brutto."""
        positions = [InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23"))]
        # VAT = 2300, so Brutto should be 12300, not 12000
        summary = InvoiceSummary(netto_grosze=10000, vat_grosze=2300, brutto_grosze=12000)
        result = validate_invariants(positions, summary)
        assert not result.is_valid
        assert "Invariant 3" in result.error_message
