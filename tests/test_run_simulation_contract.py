"""
Contract tests for TaxSimulator.run_simulation().

Sprawdza, że zwracany słownik zawiera wszystkie wymagane klucze
z poprawnymi typami — dla pustej listy, pojedynczej faktury
i wielu faktur.

Jeśli w przyszłości zmieni się struktura zwracanego słownika,
te testy powinny jako pierwsze wskazać niezgodność.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

from Code.Roboton_Reflekton.shadow_ledger import TaxSimulator


# ── Oczekiwana struktura odpowiedzi ──────────────────────────────────────────

REQUIRED_TOP_LEVEL_KEYS: dict[str, type] = {
    "current_vat_total": float,
    "current_income_tax": float,
    "simulated_vat_total": float,
    "simulated_income_tax": float,
    "invoice_count": int,
    "current_monthly_breakdown": list,
    "simulated_monthly_breakdown": list,
}

REQUIRED_MONTHLY_KEYS: dict[str, type] = {
    "month": str,
    "vat": float,
    "income_tax": float,
    "invoice_count": int,
}

# simulated_monthly_breakdown ma dodatkowo net_total
REQUIRED_MONTHLY_SIM_KEYS: dict[str, type] = {
    **REQUIRED_MONTHLY_KEYS,
    "net_total": float,
}


# ── Helper ──────────────────────────────────────────────────────────────────

async def _run(
    invoices: list[dict[str, Any]],
    target: str = "CIT_ESTONIAN",
) -> dict[str, Any]:
    return await TaxSimulator().run_simulation(
        invoices=invoices, target_rule_set_id=target,
    )


_SAMPLE_INVOICE = {
    "category_code": "FUEL",
    "transaction_date": "2024-06-15",
    "company_tax_form": "CIT_STANDARD",
    "vendor_country": "PL",
    "amount_net": Decimal("1000.00"),
}


# ═══════════════════════════════════════════════════════════════════════════════
# Testy kontraktowe — struktura odpowiedzi
# ═══════════════════════════════════════════════════════════════════════════════


class TestRunSimulationContract:
    """Weryfikuje kontrakt API: lista kluczy i typy."""

    async def test_empty_invoices_returns_all_keys(self) -> None:
        """Pusta lista → wszystkie klucze obecne."""
        result = await _run([])
        self._assert_top_level_keys(result)

    async def test_empty_invoices_returns_empty_breakdowns(self) -> None:
        """Pusta lista → breakdowns to puste listy."""
        result = await _run([])
        assert result["current_monthly_breakdown"] == []
        assert result["simulated_monthly_breakdown"] == []

    async def test_single_invoice_returns_all_keys(self) -> None:
        """Jedna faktura → wszystkie klucze obecne, 1 wpis w breakdown."""
        result = await _run([_SAMPLE_INVOICE])
        self._assert_top_level_keys(result)
        assert len(result["current_monthly_breakdown"]) == 1
        assert len(result["simulated_monthly_breakdown"]) == 1
        self._assert_monthly_keys(result["current_monthly_breakdown"], sim=False)
        self._assert_monthly_keys(result["simulated_monthly_breakdown"], sim=True)

    async def test_single_invoice_count(self) -> None:
        """Jedna faktura → invoice_count == 1."""
        result = await _run([_SAMPLE_INVOICE])
        assert result["invoice_count"] == 1

    async def test_multiple_invoices_returns_all_keys(self) -> None:
        """Wiele faktur → wszystkie klucze, wszystkie miesiące."""
        invoices = [
            {"category_code": "FUEL", "transaction_date": "2024-06-01",
             "company_tax_form": "CIT_STANDARD", "vendor_country": "PL",
             "amount_net": Decimal("500.00")},
            {"category_code": "IT_OFFICE", "transaction_date": "2024-06-15",
             "company_tax_form": "CIT_STANDARD", "vendor_country": "PL",
             "amount_net": Decimal("1500.00")},
            {"category_code": "FOOD", "transaction_date": "2024-05-20",
             "company_tax_form": "CIT_STANDARD", "vendor_country": "PL",
             "amount_net": Decimal("300.00")},
        ]
        result = await _run(invoices)
        self._assert_top_level_keys(result)
        self._assert_monthly_keys(result["current_monthly_breakdown"], sim=False)
        self._assert_monthly_keys(result["simulated_monthly_breakdown"], sim=True)
        assert result["invoice_count"] == 3
        # Oba breakdowny mają tę samą liczbę miesięcy (te same faktury)
        assert len(result["current_monthly_breakdown"]) == len(result["simulated_monthly_breakdown"])

    async def test_all_targets_return_correct_structure_and_types(self) -> None:
        """Wszystkie 4 target_rule_set_id → struktura + typy w jednej pętli."""
        for target in ("CIT_STANDARD", "CIT_ESTONIAN", "LINEAR", "LUMP_SUM"):
            result = await _run([_SAMPLE_INVOICE], target)
            self._assert_top_level_keys(result)
            self._assert_monthly_keys(result["current_monthly_breakdown"], sim=False)
            self._assert_monthly_keys(result["simulated_monthly_breakdown"], sim=True)
            for key, expected_type in REQUIRED_TOP_LEVEL_KEYS.items():
                val = result[key]
                assert isinstance(val, expected_type), (
                    f"target={target}: {key} is {type(val).__name__}, "
                    f"expected {expected_type.__name__}"
                )

    async def test_current_breakdown_has_no_net_total(self) -> None:
        """current_monthly_breakdown NIE ma pola net_total."""
        result = await _run([_SAMPLE_INVOICE])
        for entry in result["current_monthly_breakdown"]:
            assert "net_total" not in entry, (
                "current_monthly_breakdown should not have net_total"
            )

    async def test_simulated_breakdown_has_net_total(self) -> None:
        """simulated_monthly_breakdown MA pole net_total."""
        result = await _run([_SAMPLE_INVOICE])
        for entry in result["simulated_monthly_breakdown"]:
            assert "net_total" in entry, (
                "simulated_monthly_breakdown should have net_total"
            )

    # ── Prywatne helpery asercji ───────────────────────────────────────

    def _assert_top_level_keys(self, result: dict[str, Any]) -> None:
        """Sprawdza, że wszystkie wymagane klucze najwyższego poziomu istnieją.
        Nie sprawdza, czy nie ma nadmiarowych — to pozwala na dodawanie nowych pól
        w przyszłości bez łamania testu (backward-compatible).
        """
        for key, expected_type in REQUIRED_TOP_LEVEL_KEYS.items():
            assert key in result, f"Missing top-level key: {key}"
            assert isinstance(result[key], expected_type), (
                f"Key {key} has type {type(result[key]).__name__}, "
                f"expected {expected_type.__name__}"
            )

    def _assert_monthly_keys(
        self,
        breakdown: list[dict[str, Any]],
        sim: bool = False,
    ) -> None:
        """Sprawdza klucze w każdym wpisie monthly_breakdown."""
        required = REQUIRED_MONTHLY_SIM_KEYS if sim else REQUIRED_MONTHLY_KEYS
        forbidding = set() if sim else {"net_total"}

        for entry in breakdown:
            for key, expected_type in required.items():
                assert key in entry, f"Missing key in monthly entry: {key}"
                assert isinstance(entry[key], expected_type), (
                    f"Monthly key {key} has type {type(entry[key]).__name__}, "
                    f"expected {expected_type.__name__}"
                )
            for forbidden in forbidding:
                assert forbidden not in entry, (
                    f"Unexpected key '{forbidden}' in monthly entry"
                )
