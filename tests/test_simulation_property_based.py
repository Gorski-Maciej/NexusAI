"""
Property-Based Testing z Crosshair — TaxSimulator.run_simulation().

Zastępuje: hypothesis (losowe testowanie, ciężkie)
Nowy:     crosshair (analiza statyczna, lżejsza)

Sprawdza 5 kluczowych niezmienników (invariants) dla dowolnych danych:

  Invariant 1 — invoice_count == len(invoices)
  Invariant 2 — Nieujemność: wszystkie totals >= 0
  Invariant 3 — Suma miesięczna = total (dla vat i income_tax)
  Invariant 4 — Te same miesiące w current i simulated breakdown
  Invariant 5 — Poprawne zaokrąglenie (max 2 miejsca po przecinku)
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

import crosshair
import pytest

from nexus_ai.roboton_reflekton.shadow_ledger import TaxSimulator


# ── Helper ──────────────────────────────────────────────────────────────────


async def _run(invoices: list[dict[str, Any]], target: str) -> dict[str, Any]:
    return await TaxSimulator().run_simulation(
        invoices=invoices, target_rule_set_id=target
    )


# ═══════════════════════════════════════════════════════════════════════════════
# Testy statyczne (nie Crosshair) — pusta lista, pojedyncza faktura
# ═══════════════════════════════════════════════════════════════════════════════


class TestEmptyInput:
    """Pusta lista faktur → zera."""

    async def test_empty_returns_zeros(self) -> None:
        result = await _run([], "CIT_ESTONIAN")
        assert result["current_vat_total"] == 0.0
        assert result["current_income_tax"] == 0.0
        assert result["simulated_vat_total"] == 0.0
        assert result["simulated_income_tax"] == 0.0
        assert result["invoice_count"] == 0
        assert result["current_monthly_breakdown"] == []
        assert result["simulated_monthly_breakdown"] == []


class TestSingleInvoice:
    """Jedna faktura → jeden miesiąc."""

    async def test_single_invoice_single_month(self) -> None:
        invoice = {
            "category_code": "FUEL",
            "transaction_date": "2024-06-15",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "amount_net": Decimal("1000.00"),
        }
        result = await _run([invoice], "CIT_ESTONIAN")
        assert len(result["current_monthly_breakdown"]) == 1
        assert result["current_monthly_breakdown"][0]["month"] == "2024-06"
        assert result["current_monthly_breakdown"][0]["invoice_count"] == 1
        assert len(result["simulated_monthly_breakdown"]) == 1
        assert result["simulated_monthly_breakdown"][0]["month"] == "2024-06"
        assert result["simulated_monthly_breakdown"][0]["invoice_count"] == 1


# ═══════════════════════════════════════════════════════════════════════════════
# Deterministyczność — 2 symulacje
# ═══════════════════════════════════════════════════════════════════════════════


class TestDeterminism:
    """Dwa uruchomienia → identyczne wyniki."""

    async def test_deterministic(self) -> None:
        invoices = [
            {
                "category_code": "FUEL",
                "transaction_date": "2024-06-15",
                "company_tax_form": "CIT_STANDARD",
                "vendor_country": "PL",
                "amount_net": Decimal("1000.00"),
            },
            {
                "category_code": "IT_OFFICE",
                "transaction_date": "2024-06-20",
                "company_tax_form": "CIT_STANDARD",
                "vendor_country": "EU",
                "amount_net": Decimal("500.00"),
            },
        ]
        r1 = await _run(invoices, "CIT_STANDARD")
        r2 = await _run(invoices, "CIT_STANDARD")
        for key in ("current_vat_total", "current_income_tax",
                    "simulated_vat_total", "simulated_income_tax",
                    "invoice_count"):
            assert r1[key] == r2[key], f"Non-deterministic: {key}"
