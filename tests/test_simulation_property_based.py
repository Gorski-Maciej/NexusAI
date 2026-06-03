"""
Property-Based Testing z Hypothesis — TaxSimulator.run_simulation().

Sprawdza 5 kluczowych niezmienników (invariants) dla dowolnych danych:

  Invariant 1 — invoice_count == len(invoices)
  Invariant 2 — Nieujemność: wszystkie totals >= 0
  Invariant 3 — Suma miesięczna = total (dla vat i income_tax)
  Invariant 4 — Te same miesiące w current i simulated breakdown
  Invariant 5 — Poprawne zaokrąglenie (max 2 miejsca po przecinku)

Dodatkowo:
  - Pusta lista → zera (test statyczny, nie Hypothesis)
  - Różne zestawy reguł → różne income_tax (dla uproszczenia sprawdza tylko CIT vs EST)
  - Deterministyczność (2× call, te same wyniki)
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

from hypothesis import given, settings
from hypothesis import strategies as st

from Code.Roboton_Reflekton.shadow_ledger import TaxSimulator


# ── Hypothesis strategies ────────────────────────────────────────────────────

known_categories = st.sampled_from([
    "FUEL", "IT_OFFICE", "FOOD", "EDUCATION", "HEALTHCARE", "BOOKS",
])

vendor_countries = st.sampled_from(["PL", "EU", "NON_EU"])

positive_net = st.decimals(
    min_value=Decimal("0.01"),
    max_value=Decimal("100_000.00"),
    places=2,
)

transaction_dates = st.dates(
    min_value=__import__("datetime").date(2024, 1, 1),
    max_value=__import__("datetime").date(2024, 12, 31),
).map(lambda d: d.isoformat())

# Pojedyncza faktura
single_invoice = st.fixed_dictionaries({
    "category_code": known_categories,
    "transaction_date": transaction_dates,
    "company_tax_form": st.just("CIT_STANDARD"),
    "vendor_country": vendor_countries,
    "amount_net": positive_net,
})  # type: ignore[arg-type]

# Lista faktur (1-5) — małe listy dla szybkich testów
invoice_lists = st.lists(single_invoice, min_size=1, max_size=5)

# Dostępne zestawy reguł
SIM_RULE_SETS = ["CIT_STANDARD", "CIT_ESTONIAN", "LINEAR", "LUMP_SUM"]
target_rule_sets = st.sampled_from(SIM_RULE_SETS)

# Każda symulacja ~3-5s (DuckDB + seed rulek). Niska liczba przykładów.
DEADLINE_MS = 120_000
N = 5  # 5 przykładów × (1-2 symulacje) × ~4s = ~20-40s na test


# ── Helper ──────────────────────────────────────────────────────────────────

async def _run(invoices: list[dict[str, Any]], target: str) -> dict[str, Any]:
    return await TaxSimulator().run_simulation(
        invoices=invoices, target_rule_set_id=target
    )


# ═══════════════════════════════════════════════════════════════════════════════
# Główny test — jeden przebieg, 5 niezmienników
# ═══════════════════════════════════════════════════════════════════════════════


class TestSimulationInvariants:
    """Pięć niezmienników sprawdzanych w JEDNEJ symulacji."""

    @given(invoice_lists, target_rule_sets)
    @settings(max_examples=N, deadline=DEADLINE_MS)
    async def test_all_invariants(
        self, invoices: list[dict[str, Any]], target: str,
    ) -> None:
        """Uruchamia symulację RAZ i sprawdza wszystkie invariants."""

        # ── Uruchom symulację ─────────────────────────────────────────
        result = await _run(invoices, target)

        # ── Invariant 1: licznik faktur ───────────────────────────────
        assert result["invoice_count"] == len(invoices)

        # ── Invariant 2: nieujemność ──────────────────────────────────
        assert result["current_vat_total"] >= 0
        assert result["current_income_tax"] >= 0
        assert result["simulated_vat_total"] >= 0
        assert result["simulated_income_tax"] >= 0

        # ── Invariant 3: suma miesięczna = total ──────────────────────
        curr_vat = sum(m["vat"] for m in result["current_monthly_breakdown"])
        curr_inc = sum(m["income_tax"] for m in result["current_monthly_breakdown"])
        sim_vat = sum(m["vat"] for m in result["simulated_monthly_breakdown"])
        sim_inc = sum(m["income_tax"] for m in result["simulated_monthly_breakdown"])

        assert abs(curr_vat - result["current_vat_total"]) < 0.01
        assert abs(curr_inc - result["current_income_tax"]) < 0.01
        assert abs(sim_vat - result["simulated_vat_total"]) < 0.01
        assert abs(sim_inc - result["simulated_income_tax"]) < 0.01

        # Invoice count w breakdown też sumuje się do total
        curr_cnt = sum(m["invoice_count"] for m in result["current_monthly_breakdown"])
        sim_cnt = sum(m["invoice_count"] for m in result["simulated_monthly_breakdown"])
        assert curr_cnt == result["invoice_count"]
        assert sim_cnt == result["invoice_count"]

        # ── Invariant 4: te same miesiące w obu breakdownach ──────────
        curr_months = [m["month"] for m in result["current_monthly_breakdown"]]
        sim_months = [m["month"] for m in result["simulated_monthly_breakdown"]]
        assert curr_months == sim_months, (
            f"Month mismatch: current={curr_months}, simulated={sim_months}"
        )

        # ── Invariant 5: zaokrąglenie do 2 miejsc ─────────────────────
        for key in ("current_vat_total", "current_income_tax",
                    "simulated_vat_total", "simulated_income_tax"):
            val = result[key]
            assert round(val, 2) == val, f"{key}={val} not rounded to 2dp"

        for entry in result["current_monthly_breakdown"]:
            assert round(entry["vat"], 2) == entry["vat"]
            assert round(entry["income_tax"], 2) == entry["income_tax"]
        for entry in result["simulated_monthly_breakdown"]:
            assert round(entry["vat"], 2) == entry["vat"]
            assert round(entry["income_tax"], 2) == entry["income_tax"]


# ═══════════════════════════════════════════════════════════════════════════════
# Deterministyczność — 2 symulacje na przykład
# ═══════════════════════════════════════════════════════════════════════════════


class TestDeterminism:
    """Dwa uruchomienia → identyczne wyniki."""

    @given(invoice_lists, target_rule_sets)
    @settings(max_examples=N, deadline=DEADLINE_MS)
    async def test_deterministic(self, invoices: list[dict[str, Any]], target: str) -> None:
        r1 = await _run(invoices, target)
        r2 = await _run(invoices, target)
        for key in ("current_vat_total", "current_income_tax",
                    "simulated_vat_total", "simulated_income_tax",
                    "invoice_count"):
            assert r1[key] == r2[key], f"Non-deterministic: {key}"


# ═══════════════════════════════════════════════════════════════════════════════
# Różne zestawy reguł — 2 symulacje na przykład
# ═══════════════════════════════════════════════════════════════════════════════


class TestDifferentRuleSets:
    """CIT_STANDARD ≠ CIT_ESTONIAN dla income tax (2 symulacje)."""

    @given(invoice_lists)
    @settings(max_examples=N, deadline=DEADLINE_MS)
    async def test_cit_differs(self, invoices: list[dict[str, Any]]) -> None:
        r_std = await _run(invoices, "CIT_STANDARD")
        r_est = await _run(invoices, "CIT_ESTONIAN")
        assert r_est["simulated_income_tax"] != r_std["simulated_income_tax"], (
            "CIT_STANDARD and CIT_ESTONIAN income tax should differ"
        )


# ═══════════════════════════════════════════════════════════════════════════════
# Pusta lista — test statyczny (nie Hypothesis)
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


# ═══════════════════════════════════════════════════════════════════════════════
# Pojedyncza faktura — test statyczny (nie Hypothesis)
# ═══════════════════════════════════════════════════════════════════════════════


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
# VAT vs Income Tax — CIT_STANDARD (23% > 9%)
# ═══════════════════════════════════════════════════════════════════════════════


class TestVatVsIncomeTax:
    """Dla CIT_STANDARD: VAT >= income tax (23% vs 9%)."""

    @given(invoice_lists)
    @settings(max_examples=N, deadline=DEADLINE_MS)
    async def test_vat_geq_income_tax(self, invoices: list[dict[str, Any]]) -> None:
        result = await _run(invoices, "CIT_STANDARD")
        if result["simulated_vat_total"] > 0:
            assert result["simulated_vat_total"] >= result["simulated_income_tax"]
