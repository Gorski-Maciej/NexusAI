"""What-If ML Simulator — predykcyjny symulator finansowy z Machine Learning.

v7.0 INNOWACJA #2 (Raport TigerBeetle Shadow Ledger, sekcja 10):
  "What-If ML Simulator: Predykcyjny symulator na Shadow Ledger z ML"

Rozszerza ShadowSimulator o:
- Model predykcji cash flow na podstawie 12-miesięcznej historii
- Symulacje "co by było gdyby": zmiana formy opodatkowania,
  zakup środka trwałego, zmiana stawek VAT
- Automatyczną rekomendację optymalnej formy opodatkowania
- Uczenie na historycznych danych z DuckDB

Działa w dwóch trybach:
1. Rule-based (teraz) — prosta regresja liniowa + reguły biznesowe
2. ML-ready (future) — interfejs gotowy na LSTM/Prophet/XGBoost
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from typing import Any, Callable, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.ml.simulator")


# ── Data Structures ──────────────────────────────────────────────────────


@dataclass
class MLPrediction:
    """Predykcja ML dla pojedynczego wariantu."""

    variant_id: str
    predicted_cash_flow_30d: float
    predicted_vat_30d: float
    predicted_pit_quarterly: float
    confidence: float  # 0.0-1.0
    model_used: str = "linear_regression"
    features_used: list[str] = field(default_factory=list)
    recommendation: str = ""


@dataclass
class WhatIfScenario:
    """Scenariusz "co by było gdyby"."""

    scenario_id: str
    description: str
    tax_form_change: str | None = None  # Nowa forma opodatkowania
    asset_purchase: float | None = None  # Zakup środka trwałego
    vat_rate_change: float | None = None  # Zmiana stawki VAT
    monthly_revenue_change: float | None = None  # Zmiana przychodów


@dataclass
class WhatIfResult:
    """Wynik symulacji what-if."""

    scenario: WhatIfScenario
    current_annual_tax: float
    simulated_annual_tax: float
    tax_savings: float
    current_monthly_cash: float
    simulated_monthly_cash: float
    recommendation: str
    confidence: float = 0.8


# ── Simple Linear Regression ────────────────────────────────────────────


class SimpleLinearRegression:
    """Prosta regresja liniowa dla predykcji trendów.

    Używana jako baseline model przed integracją z LSTM/Prophet.
    """

    def __init__(self):
        self._slope: float = 0.0
        self._intercept: float = 0.0
        self._fitted: bool = False

    def fit(self, x: list[float], y: list[float]) -> None:
        """Dopasuj model do danych."""
        if len(x) < 2:
            return

        n = len(x)
        sum_x = sum(x)
        sum_y = sum(y)
        sum_xy = sum(xi * yi for xi, yi in zip(x, y))
        sum_x2 = sum(xi * xi for xi in x)

        denominator = n * sum_x2 - sum_x * sum_x
        if abs(denominator) < 1e-10:
            self._slope = 0.0
        else:
            self._slope = (n * sum_xy - sum_x * sum_y) / denominator

        self._intercept = (sum_y - self._slope * sum_x) / n
        self._fitted = True

    def predict(self, x: float) -> float:
        """Przewiduj wartość dla danego x."""
        if not self._fitted:
            return 0.0
        return self._slope * x + self._intercept

    def predict_batch(self, xs: list[float]) -> list[float]:
        """Przewiduj wartości dla listy x."""
        return [self.predict(x) for x in xs]

    @property
    def trend(self) -> str:
        """Kierunek trendu."""
        if abs(self._slope) < 0.001:
            return "stable"
        return "upward" if self._slope > 0 else "downward"

    @property
    def slope(self) -> float:
        return self._slope


# ── ML What-If Simulator ────────────────────────────────────────────────


@final
class MLWhatIfSimulator:
    """Predykcyjny symulator finansowy z ML (v7.0 Innowacja #2).

    Rozszerza ShadowSimulator o predykcje ML:
    - Trend cash flow na podstawie 12-miesięcznej historii
    - Optymalna forma opodatkowania
    - Symulacje what-if z predykcją skutków

    Usage:
        sim = MLWhatIfSimulator(duckdb_conn)
        pred = sim.predict_cash_flow(historical_data)
        best_form = sim.recommend_tax_form(company_data)
    """

    # Stałe dla polskiego systemu podatkowego 2026
    # Deleguj do tax_strategies.py gdzie to możliwe
    TAX_FORMS = {
        "linear": {"rate": 0.19, "description": "Podatek liniowy 19%"},
        "scale": {"rates": [0.12, 0.32], "thresholds": [120000], "description": "Skala podatkowa"},
        "lump_sum": {"rates": [0.02, 0.03, 0.055, 0.085, 0.12, 0.14, 0.17],
                      "description": "Ryczałt od przychodów"},
    }

    # v7.0: Próbuj użyć StrategyRegistry jeśli dostępne
    _strategy_registry = None

    def _get_tax_form_rates(self) -> dict[str, dict]:
        """Pobierz stawki podatkowe — z StrategyRegistry lub z hardcoded fallback."""
        try:
            if self._strategy_registry is None:
                from nexus_ai.services.tax_strategies import StrategyRegistry
                type(self)._strategy_registry = StrategyRegistry()
            strategies = self._strategy_registry._strategies
            if strategies:
                # Konwertuj StrategyRegistry na format TAX_FORMS
                result = {}
                for name, strategy in strategies.items():
                    result[name.value if hasattr(name, 'value') else str(name)] = {
                        "rate": getattr(strategy, 'rate', 0.19),
                        "description": getattr(strategy, 'description', ''),
                    }
                if result:
                    return result
        except Exception:
            pass
        return self.TAX_FORMS

    def _get_applicable_tax_forms(self, legal_form: str) -> list[str]:
        """Pobierz formy opodatkowania dostępne dla formy prawnej."""
        if legal_form in ("jdg", "civil_partnership"):
            return ["linear", "scale", "lump_sum"]
        else:
            return ["linear", "scale"]  # Spółki nie mogą być na ryczałcie

    def __init__(
        self,
        duckdb_conn=None,
        *,
        ml_model: Any = None,
        custom_predictor: Callable | None = None,
    ) -> None:
        self._duckdb = duckdb_conn
        self._ml_model = ml_model  # Future: LSTM/Prophet/XGBoost
        self._custom_predictor = custom_predictor
        self._linear_model = SimpleLinearRegression()
        self._predictions: list[MLPrediction] = []

    # ── Cash Flow Prediction ──────────────────────────────────────────

    def predict_cash_flow(
        self,
        historical_data: list[dict[str, Any]],
        *,
        months_ahead: int = 3,
    ) -> list[MLPrediction]:
        """Przewiduj cash flow na podstawie 12-miesięcznej historii.

        Args:
            historical_data: Lista miesięcznych danych (revenue, expenses, vat, pit).
            months_ahead: Liczba miesięcy do przodu.

        Returns:
            Lista MLPrediction dla każdego miesiąca.
        """
        if self._custom_predictor:
            return self._custom_predictor(historical_data, months_ahead)

        # Ekstrakcja cech
        revenues = [float(m.get("revenue", 0)) for m in historical_data]
        expenses = [float(m.get("expenses", 0)) for m in historical_data]
        vat_paid = [float(m.get("vat_paid", 0)) for m in historical_data]
        months = list(range(len(historical_data)))

        # Trenuj modele
        rev_model = SimpleLinearRegression()
        rev_model.fit([float(x) for x in months], revenues)

        exp_model = SimpleLinearRegression()
        exp_model.fit([float(x) for x in months], expenses)

        # Predykcje
        predictions = []
        for i in range(1, months_ahead + 1):
            future_x = float(len(historical_data) + i - 1)
            pred_revenue = rev_model.predict(future_x)
            pred_expense = exp_model.predict(future_x)

            # VAT: output VAT = revenue * rate, input VAT = expenses * deductible_ratio * rate
            deductible_ratio = 0.8  # 80% wydatków z VAT do odliczenia
            pred_output_vat = pred_revenue * 0.23
            pred_input_vat = pred_expense * deductible_ratio * 0.23
            pred_vat = max(0, pred_output_vat - pred_input_vat)
            pred_cash = pred_revenue - pred_expense - pred_vat

            # Confidence: maleje z odległością predykcji
            confidence = max(0.3, 1.0 - (i * 0.1))

            predictions.append(MLPrediction(
                variant_id=f"cash-flow-m{i}",
                predicted_cash_flow_30d=round(pred_cash, 2),
                predicted_vat_30d=round(pred_vat, 2),
                predicted_pit_quarterly=round((pred_revenue - pred_expense) * 0.19, 2),
                confidence=round(confidence, 2),
                model_used="linear_regression",
                features_used=["revenue_trend", "expense_trend", "month_index"],
                recommendation=(
                    "Trend przychodów rośnie — rozważ inwestycje"
                    if rev_model.trend == "upward"
                    else "Trend spadkowy — zoptymalizuj koszty"
                ),
            ))

        self._predictions.extend(predictions)
        return predictions

    # ── Tax Form Optimization ─────────────────────────────────────────

    def recommend_tax_form(
        self,
        company_data: dict[str, Any],
    ) -> WhatIfResult:
        """Rekomenduj optymalną formę opodatkowania.

        Porównuje wszystkie dostępne formy na podstawie rzeczywistych
        danych i zwraca najlepszą z oszczędnościami.

        Args:
            company_data: Dane firmy (annual_revenue, annual_expenses, legal_form).

        Returns:
            WhatIfResult z rekomendacją.
        """
        annual_revenue = float(company_data.get("annual_revenue", 0))
        annual_expenses = float(company_data.get("annual_expenses", 0))
        legal_form = company_data.get("legal_form", "jdg")
        current_form = company_data.get("tax_form", "linear")

        taxable_income = max(0, annual_revenue - annual_expenses)

        # Oblicz podatek dla każdej formy
        tax_costs = {}

        # Liniowy 19%
        linear_tax = taxable_income * 0.19
        tax_costs["linear"] = linear_tax

        # Skala podatkowa
        if taxable_income <= 120000:
            scale_tax = taxable_income * 0.12
        else:
            scale_tax = 120000 * 0.12 + (taxable_income - 120000) * 0.32
        tax_costs["scale"] = scale_tax

        # Ryczałt (tylko JDG)
        if legal_form in ("jdg", "civil_partnership"):
            # Uproszczone — stawka zależna od branży
            lump_sum_rate = 0.085  # domyślnie 8.5% dla usług
            lump_sum_tax = annual_revenue * lump_sum_rate
            tax_costs["lump_sum"] = lump_sum_tax

        # Znajdź najlepszą
        best_form = min(tax_costs, key=tax_costs.get)
        best_tax = tax_costs[best_form]
        current_tax = tax_costs.get(current_form, linear_tax)
        savings = current_tax - best_tax

        return WhatIfResult(
            scenario=WhatIfScenario(
                scenario_id=f"tax-opt-{best_form}",
                description=f"Optymalizacja: {current_form} → {best_form}",
                tax_form_change=best_form,
            ),
            current_annual_tax=round(current_tax, 2),
            simulated_annual_tax=round(best_tax, 2),
            tax_savings=round(savings, 2),
            current_monthly_cash=round((annual_revenue - annual_expenses - current_tax) / 12, 2),
            simulated_monthly_cash=round((annual_revenue - annual_expenses - best_tax) / 12, 2),
            recommendation=(
                f"Zmień formę opodatkowania na {best_form}. "
                f"Zaoszczędzisz {savings:,.2f} PLN rocznie."
                if savings > 100
                else f"Twoja obecna forma ({current_form}) jest optymalna."
            ),
            confidence=0.85,
        )

    # ── What-If Scenarios ────────────────────────────────────────────

    def run_what_if(
        self,
        company_data: dict[str, Any],
        scenarios: list[WhatIfScenario],
    ) -> list[WhatIfResult]:
        """Uruchom wiele scenariuszy what-if.

        Args:
            company_data: Dane bazowe firmy.
            scenarios: Lista scenariuszy do zasymulowania.

        Returns:
            Lista WhatIfResult posortowana po oszczędnościach.
        """
        results = []

        for scenario in scenarios:
            modified_data = dict(company_data)

            if scenario.tax_form_change:
                modified_data["tax_form"] = scenario.tax_form_change

            if scenario.asset_purchase:
                modified_data["annual_expenses"] = (
                    float(modified_data.get("annual_expenses", 0))
                    + scenario.asset_purchase
                )

            if scenario.monthly_revenue_change:
                modified_data["annual_revenue"] = (
                    float(modified_data.get("annual_revenue", 0))
                    + scenario.monthly_revenue_change * 12
                )

            result = self.recommend_tax_form(modified_data)
            result.scenario = scenario
            results.append(result)

        # Sortuj po oszczędnościach
        results.sort(key=lambda r: r.tax_savings, reverse=True)
        return results

    # ── ML Model Interface ───────────────────────────────────────────

    def set_ml_model(self, model: Any) -> None:
        """Ustaw zewnętrzny model ML (LSTM, Prophet, XGBoost).

        Args:
            model: Wytrenowany model z metodą predict().
        """
        self._ml_model = model
        logger.info("[ML-SIM] External ML model set: %s", type(model).__name__)

    def set_custom_predictor(self, predictor: Callable) -> None:
        """Ustaw niestandardową funkcję predykcji.

        Args:
            predictor: Callable(historical_data, months_ahead) -> list[MLPrediction].
        """
        self._custom_predictor = predictor
        logger.info("[ML-SIM] Custom predictor set")

    @property
    def predictions_history(self) -> list[MLPrediction]:
        return self._predictions
