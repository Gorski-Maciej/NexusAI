"""
v7.0 INNOWACJA 14: VAT Cashflow Predictor — Prognoza zobowiązań VAT na 90 dni.

Prognozuje:
- Należny VAT od sprzedaży (na podstawie pipeline'u i historycznych wzorców)
- Naliczony VAT od zakupów (prognoza kosztów stałych + zmiennych)
- Saldo VAT (do zapłaty / do zwrotu)
- Wykrywanie luk płynności (VAT do zapłaty > środki na rachunku VAT)
- Sezonowość miesięczna z modelowaniem trendów

Integracja z DuckDB dla analizy historycznej i TigerBeetle dla sald bieżących.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.services.vat_cashflow")


# ── Configuration ────────────────────────────────────────────────────────────

FORECAST_DAYS = 90
SEASONALITY_FACTORS: dict[int, float] = {
    1: 0.85, 2: 0.80, 3: 1.05, 4: 1.10, 5: 1.05, 6: 1.10,
    7: 1.15, 8: 0.90, 9: 1.10, 10: 1.15, 11: 1.20, 12: 1.25,
}
LIQUIDITY_CRITICAL_RATIO = 0.70  # VAT do zapłaty > 70% środków na rachunku VAT
LIQUIDITY_WARNING_RATIO = 0.50


@dataclass
class MonthlyVATForecast:
    """Prognoza VAT na pojedynczy miesiąc."""
    month: str  # YYYY-MM
    month_label: str  # Styczeń 2026
    sales_net: float
    vat_output: float  # VAT należny
    purchases_net: float
    vat_input: float  # VAT naliczony
    vat_balance: float  # Dodatnie = do zapłaty, ujemne = do zwrotu
    cumulative_balance: float
    estimated_vat_account_balance: float
    liquidity_ratio: float  # vat_balance / vat_account_balance
    liquidity_status: str  # SAFE, WARNING, CRITICAL
    seasonality_applied: float


@dataclass
class VATCashflowForecast:
    """Pełna prognoza VAT cashflow."""
    generated_at: str
    forecast_start: str
    forecast_end: str  # +90 dni
    jdg_id: str = ""
    monthly_forecasts: list[MonthlyVATForecast] = field(default_factory=list)
    total_vat_to_pay: float = 0.0
    total_vat_to_refund: float = 0.0
    net_cashflow_impact: float = 0.0
    critical_months: list[str] = field(default_factory=list)  # Miesiące z liquidity CRITICAL
    recommendations: list[str] = field(default_factory=list)
    alerts: list[str] = field(default_factory=list)


class VATCashflowPredictor:
    """v7.0 INNOWACJA 14: Predyktor przepływów VAT.

    Prognozuje zobowiązania VAT na 90 dni z modelowaniem sezonowości.
    """

    def __init__(self, duckdb: Any = None, tigerbeetle: Any = None) -> None:
        self._duckdb = duckdb
        self._tb = tigerbeetle

    def predict(
        self,
        sales_pipeline: list[dict[str, Any]],
        historical_invoices: list[dict[str, Any]],
        recurring_costs: list[dict[str, Any]] | None = None,
        vat_account_balance: float = 0.0,
        jdg_id: str = "",
        months_ahead: int = 3,
    ) -> VATCashflowForecast:
        """Prognozuj VAT cashflow na kolejne miesiące.

        Args:
            sales_pipeline: Planowane faktury sprzedaży (z datami i kwotami).
            historical_invoices: Historyczne faktury (do modelowania wzorców).
            recurring_costs: Koszty stałe (czynsz, subskrypcje, leasing).
            vat_account_balance: Aktualne saldo rachunku VAT.
            jdg_id: Identyfikator JDG.
            months_ahead: Liczba miesięcy prognozy (domyślnie 3 = ~90 dni).

        Returns:
            VATCashflowForecast z miesięcznymi prognozami.
        """
        today = pendulum.today("Europe/Warsaw")
        forecast_start = today.start_of("month")
        monthly: dict[str, MonthlyVATForecast] = {}

        # ── Oblicz średnie miesięczne z historii ──────────────────────
        avg_monthly_sales, avg_monthly_vat_output = self._compute_historical_averages(
            historical_invoices, direction="SALE"
        )
        avg_monthly_purchases, avg_monthly_vat_input = self._compute_historical_averages(
            historical_invoices, direction="PURCHASE"
        )

        # ── Grupuj pipeline sprzedaży miesięcznie ─────────────────────
        pipeline_monthly: dict[str, dict[str, float]] = {}
        for deal in sales_pipeline:
            date = deal.get("expected_close_date", deal.get("date", ""))
            if not date:
                continue
            month_key = date[:7]  # YYYY-MM
            if month_key not in pipeline_monthly:
                pipeline_monthly[month_key] = {"net": 0.0, "vat": 0.0}
            net = float(deal.get("amount_net", 0))
            vat_rate = float(deal.get("vat_rate", "0.23"))
            pipeline_monthly[month_key]["net"] += net
            pipeline_monthly[month_key]["vat"] += net * vat_rate

        # ── Generuj prognozy miesięczne ───────────────────────────────
        cumulative = 0.0
        total_to_pay = 0.0
        total_to_refund = 0.0
        critical_months: list[str] = []
        alerts: list[str] = []
        recommendations: list[str] = []
        running_balance = vat_account_balance

        for i in range(months_ahead):
            month_date = forecast_start.add(months=i)
            month_key = month_date.format("YYYY-MM")
            month_label = month_date.format("MMMM YYYY", locale="pl")

            # Sezonowość
            seasonality = SEASONALITY_FACTORS.get(month_date.month, 1.0)

            # Sprzedaż: pipeline + historyczna średnia jako fallback
            pipe = pipeline_monthly.get(month_key, {"net": 0.0, "vat": 0.0})
            sales_net = pipe["net"] if pipe["net"] > 0 else avg_monthly_sales * seasonality
            vat_output = pipe["vat"] if pipe["vat"] > 0 else avg_monthly_vat_output * seasonality

            # Zakupy: koszty stałe + średnia historyczna
            recurring = self._sum_recurring_costs(recurring_costs, month_key)
            purchases_net = recurring + (avg_monthly_purchases * seasonality * 0.5)
            vat_input = purchases_net * 0.23  # uproszczona stawka

            # Saldo
            vat_balance = vat_output - vat_input
            cumulative += vat_balance

            if vat_balance > 0:
                total_to_pay += vat_balance
            else:
                total_to_refund += abs(vat_balance)

            # Płynność
            running_balance += vat_input - vat_output
            estimated_balance = max(running_balance, 0.0)
            liquidity_ratio = vat_balance / max(estimated_balance, 0.01) if vat_balance > 0 else 0.0

            if liquidity_ratio > LIQUIDITY_CRITICAL_RATIO and vat_balance > 1000:
                liquidity_status = "CRITICAL"
                critical_months.append(month_key)
                alerts.append(
                    f"KRYTYCZNE {month_label}: VAT do zapłaty {vat_balance:,.0f} PLN "
                    f"przekracza {LIQUIDITY_CRITICAL_RATIO*100:.0f}% środków na rachunku VAT "
                    f"({estimated_balance:,.0f} PLN)!"
                )
            elif liquidity_ratio > LIQUIDITY_WARNING_RATIO:
                liquidity_status = "WARNING"
                alerts.append(
                    f"UWAGA {month_label}: VAT do zapłaty {vat_balance:,.0f} PLN — "
                    f"monitoruj saldo rachunku VAT ({estimated_balance:,.0f} PLN)"
                )
            else:
                liquidity_status = "SAFE"

            monthly[month_key] = MonthlyVATForecast(
                month=month_key,
                month_label=month_label,
                sales_net=round(sales_net, 2),
                vat_output=round(vat_output, 2),
                purchases_net=round(purchases_net, 2),
                vat_input=round(vat_input, 2),
                vat_balance=round(vat_balance, 2),
                cumulative_balance=round(cumulative, 2),
                estimated_vat_account_balance=round(estimated_balance, 2),
                liquidity_ratio=round(liquidity_ratio, 2),
                liquidity_status=liquidity_status,
                seasonality_applied=round(seasonality, 2),
            )

        # ── Rekomendacje ─────────────────────────────────────────────
        if critical_months:
            recommendations.append(
                f"Zaplanuj dodatkowe środki na rachunku VAT przed {critical_months[0]}. "
                f"Rozważ przyspieszenie zwrotu VAT (25 dni zamiast 60) lub "
                f"przesunięcie terminów płatności faktur zakupowych."
            )
        if total_to_pay > vat_account_balance * 2:
            recommendations.append(
                "Suma VAT do zapłaty znacząco przekracza saldo rachunku VAT. "
                "Rozważ kwartalne rozliczenie VAT dla poprawy cashflow."
            )

        return VATCashflowForecast(
            generated_at=today.isoformat(),
            forecast_start=forecast_start.to_date_string(),
            forecast_end=forecast_start.add(months=months_ahead).end_of("month").to_date_string(),
            jdg_id=jdg_id,
            monthly_forecasts=list(monthly.values()),
            total_vat_to_pay=round(total_to_pay, 2),
            total_vat_to_refund=round(total_to_refund, 2),
            net_cashflow_impact=round(total_to_refund - total_to_pay, 2),
            critical_months=critical_months,
            recommendations=recommendations,
            alerts=alerts,
        )

    @staticmethod
    def _compute_historical_averages(
        invoices: list[dict[str, Any]],
        direction: str,
    ) -> tuple[float, float]:
        """Oblicz średnią miesięczną sprzedaży/zakupów z historii."""
        # Grupuj miesięcznie
        monthly_totals: dict[str, dict[str, float]] = {}
        for inv in invoices:
            if inv.get("direction", "SALE") != direction:
                continue
            date = inv.get("transaction_date", inv.get("date", ""))
            if not date or len(date) < 7:
                continue
            month_key = date[:7]
            if month_key not in monthly_totals:
                monthly_totals[month_key] = {"net": 0.0, "vat": 0.0}
            net = float(inv.get("amount_net", 0))
            vat = float(inv.get("amount_vat", net * 0.23))
            monthly_totals[month_key]["net"] += net
            monthly_totals[month_key]["vat"] += vat

        if not monthly_totals:
            return 0.0, 0.0

        months = len(monthly_totals)
        total_net = sum(m["net"] for m in monthly_totals.values())
        total_vat = sum(m["vat"] for m in monthly_totals.values())

        return total_net / months, total_vat / months

    @staticmethod
    def _sum_recurring_costs(
        costs: list[dict[str, Any]] | None,
        month_key: str,
    ) -> float:
        """Sumuj koszty stałe dla danego miesiąca."""
        if not costs:
            return 0.0
        total = 0.0
        for cost in costs:
            start = cost.get("valid_from", "2000-01")
            end = cost.get("valid_to", "2099-12")
            if start <= month_key <= end:
                total += float(cost.get("amount_net", 0))
        return total

    def get_liquidity_chart_data(
        self, forecast: VATCashflowForecast,
    ) -> dict[str, list[Any]]:
        """Generuj dane do wykresu płynności VAT."""
        months = [m.month_label for m in forecast.monthly_forecasts]
        vat_output = [m.vat_output for m in forecast.monthly_forecasts]
        vat_input = [m.vat_input for m in forecast.monthly_forecasts]
        balance = [m.vat_balance for m in forecast.monthly_forecasts]
        cumulative = [m.cumulative_balance for m in forecast.monthly_forecasts]
        account_balance = [m.estimated_vat_account_balance for m in forecast.monthly_forecasts]

        return {
            "months": months,
            "vat_output": vat_output,
            "vat_input": vat_input,
            "vat_balance": balance,
            "cumulative_balance": cumulative,
            "vat_account_balance": account_balance,
            "critical_months": forecast.critical_months,
        }
