"""Predictive Cash Flow ML Engine — predykcyjny silnik płynności z ML.

v7.0 INNOWACJA #7 (Raport TigerBeetle Shadow Ledger, sekcja 10):
  "Predictive Cash Flow Engine: Predykcyjny silnik płynności z ML"

Rozszerza LiquidityOracle o:
- Model predykcji cash flow 90-dniowej
- Cechy: historia wpływów/wypłat, sezonowość, dzień miesiąca
- Integracja z KSeF: faktury do zapłaty + oczekujące płatności
- Alerty: "Za 30 dni może zabraknąć X PLN na ZUS"
- Automatyczne rekomendacje: faktoring, przesunięcie płatności

Działa w dwóch trybach:
1. Rule-based (teraz) — regresja liniowa + sezonowość
2. ML-ready (future) — LSTM/Prophet interface
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from typing import Any, Callable, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.ml.cashflow")


# ── Data Structures ──────────────────────────────────────────────────────


@dataclass
class DailyCashFlowPrediction:
    """Predykcja cash flow na jeden dzień."""

    date: str
    predicted_inflow: float
    predicted_outflow: float
    predicted_balance: float
    confidence_interval_low: float
    confidence_interval_high: float
    risk_level: str  # "low", "medium", "high", "critical"


@dataclass
class CashFlowAlert:
    """Alert płynnościowy."""

    alert_id: str
    date: str
    severity: str  # "warning", "critical"
    message: str
    predicted_shortfall: float
    recommendation: str
    actionable: bool = True


@dataclass
class CashFlowForecast:
    """Pełna prognoza cash flow."""

    forecast_id: str
    generated_at: str
    days_ahead: int
    predictions: list[DailyCashFlowPrediction] = field(default_factory=list)
    alerts: list[CashFlowAlert] = field(default_factory=list)
    min_balance: float = float("inf")
    max_balance: float = float("-inf")
    days_critical: int = 0
    summary: str = ""


# ── Seasonality Detector ─────────────────────────────────────────────────


class SeasonalityDetector:
    """Wykrywanie sezonowości w danych finansowych.

    Analizuje wzorce dobowe, tygodniowe i miesięczne.
    """

    @staticmethod
    def detect_weekly_pattern(daily_data: list[float]) -> dict[int, float]:
        """Wykryj wzorzec tygodniowy.

        Returns:
            Mapa {dzień_tygodnia (0=pon, 6=nie): średnia wartość}.
        """
        if len(daily_data) < 7:
            return {}

        # Zakładamy, że dane są uporządkowane chronologicznie
        # i zaczynają się od poniedziałku
        day_sums: dict[int, list[float]] = {i: [] for i in range(7)}

        for i, value in enumerate(daily_data):
            day = i % 7
            day_sums[day].append(value)

        return {
            day: sum(vals) / len(vals) if vals else 0.0
            for day, vals in day_sums.items()
        }

    @staticmethod
    def detect_monthly_pattern(monthly_data: list[float]) -> dict[int, float]:
        """Wykryj wzorzec miesięczny.

        Returns:
            Mapa {miesiąc (1-12): średnia wartość}.
        """
        if len(monthly_data) < 12:
            return {}

        month_sums: dict[int, list[float]] = {i + 1: [] for i in range(12)}

        for i, value in enumerate(monthly_data):
            month = (i % 12) + 1
            month_sums[month].append(value)

        return {
            month: sum(vals) / len(vals) if vals else 0.0
            for month, vals in month_sums.items()
        }

    @staticmethod
    def get_seasonality_factor(
        day_of_week: int,
        day_of_month: int,
        week_pattern: dict[int, float],
        avg: float,
    ) -> float:
        """Oblicz współczynnik sezonowości dla danego dnia."""
        if not week_pattern or avg == 0:
            return 1.0

        day_factor = week_pattern.get(day_of_week, avg) / avg if avg > 0 else 1.0

        # Dni 1-5 miesiąca: wyższe wpływy (pensje)
        if day_of_month <= 5:
            day_factor *= 1.1
        # Dni 10-15: płatności ZUS/VAT
        elif 10 <= day_of_month <= 15:
            day_factor *= 0.8  # Wyższe wypływy

        return max(0.5, min(2.0, day_factor))


# ── KSeF Integration ─────────────────────────────────────────────────────


@dataclass
class KSeFCommitment:
    """Zobowiązanie z faktury KSeF."""

    invoice_id: str
    due_date: str
    amount_gross: float
    contractor_nip: str
    is_vat_mpp: bool = False  # Split payment


class KSeFCashFlowIntegrator:
    """Integracja prognozy cash flow z fakturami KSeF.

    Uwzględnia faktury do zapłaty i oczekujące płatności.
    """

    @staticmethod
    def get_upcoming_payments(
        ksef_invoices: list[dict[str, Any]],
        days_ahead: int = 90,
    ) -> list[KSeFCommitment]:
        """Pobierz nadchodzące płatności z KSeF.

        Args:
            ksef_invoices: Lista faktur KSeF.
            days_ahead: Horyzont prognozy.

        Returns:
            Lista zobowiązań posortowana po dacie.
        """
        today = pendulum.now().date()
        cutoff = today.add(days=days_ahead)

        commitments = []
        for inv in ksef_invoices:
            due_date_str = inv.get("due_date", "")
            if not due_date_str:
                continue

            try:
                due_date = pendulum.parse(due_date_str).date()
            except (ValueError, pendulum.ParserError):
                continue

            if due_date < today or due_date > cutoff:
                continue

            commitments.append(KSeFCommitment(
                invoice_id=str(inv.get("id", "")),
                due_date=due_date.isoformat(),
                amount_gross=float(inv.get("amount_gross", 0)),
                contractor_nip=str(inv.get("contractor_nip", "")),
                is_vat_mpp=float(inv.get("amount_gross", 0)) >= 15000,
            ))

        commitments.sort(key=lambda c: c.due_date)
        return commitments


# ── Predictive Cash Flow Engine ──────────────────────────────────────────


@final
class PredictiveCashFlowEngine:
    """Predykcyjny silnik płynności z ML (v7.0 Innowacja #7).

    Generuje 90-dniową prognozę cash flow z:
    - Analizą sezonowości
    - Integracją KSeF
    - Automatycznymi alertami
    - Rekomendacjami

    Usage:
        engine = PredictiveCashFlowEngine(duckdb_conn)
        forecast = engine.forecast(historical_data, ksef_invoices, days_ahead=90)
        for alert in forecast.alerts:
            print(f"⚠️ {alert.message}")
    """

    # Stałe progowe
    CRITICAL_BALANCE_RATIO = 0.5  # Saldo < 50% miesięcznych kosztów
    WARNING_BALANCE_RATIO = 1.0   # Saldo < 100% miesięcznych kosztów

    def __init__(
        self,
        duckdb_conn=None,
        *,
        ml_model: Any = None,
        custom_predictor: Callable | None = None,
    ) -> None:
        self._duckdb = duckdb_conn
        self._ml_model = ml_model
        self._custom_predictor = custom_predictor
        self._seasonality = SeasonalityDetector()
        self._ksef = KSeFCashFlowIntegrator()

    # ── Main Forecast ──────────────────────────────────────────────────

    def forecast(
        self,
        historical_data: list[dict[str, Any]],
        ksef_invoices: list[dict[str, Any]] | None = None,
        *,
        days_ahead: int = 90,
        current_balance: float = 0.0,
        monthly_fixed_costs: float = 0.0,
    ) -> CashFlowForecast:
        """Wygeneruj 90-dniową prognozę cash flow.

        Args:
            historical_data: Dane historyczne (min. 30 dni).
            ksef_invoices: Faktury KSeF (do zapłaty + oczekujące).
            days_ahead: Horyzont prognozy.
            current_balance: Bieżące saldo.
            monthly_fixed_costs: Stałe koszty miesięczne.

        Returns:
            CashFlowForecast z predykcjami i alertami.
        """
        import uuid

        forecast_id = f"CF-{uuid.uuid4().hex[:8]}"
        today = pendulum.now()

        # Jeśli mamy custom predictor, deleguj
        if self._custom_predictor:
            return self._custom_predictor(
                historical_data, ksef_invoices, days_ahead, current_balance
            )

        # Ekstrakcja cech
        daily_inflows = [float(m.get("inflow", 0)) for m in historical_data[-90:]]
        daily_outflows = [float(m.get("outflow", 0)) for m in historical_data[-90:]]

        # Średnie
        avg_daily_inflow = sum(daily_inflows) / max(len(daily_inflows), 1)
        avg_daily_outflow = sum(daily_outflows) / max(len(daily_outflows), 1)

        # Sezonowość tygodniowa
        week_pattern = self._seasonality.detect_weekly_pattern(daily_inflows)

        # KSeF commitments
        ksef_commitments = []
        if ksef_invoices:
            ksef_commitments = self._ksef.get_upcoming_payments(ksef_invoices, days_ahead)

        # Generuj predykcje
        balance = current_balance
        predictions = []
        alerts = []
        min_balance = balance
        max_balance = balance
        days_critical = 0

        for day_offset in range(days_ahead):
            day = today.add(days=day_offset)
            day_of_week = day.day_of_week
            day_of_month = day.day

            # Współczynnik sezonowości
            season_factor = self._seasonality.get_seasonality_factor(
                day_of_week, day_of_month, week_pattern,
                avg_daily_inflow if avg_daily_inflow > 0 else 1.0,
            )

            # Predykcja wpływów
            predicted_inflow = avg_daily_inflow * season_factor

            # Predykcja wypływów
            predicted_outflow = avg_daily_outflow

            # Dodaj zobowiązania KSeF
            day_str = day.format("YYYY-MM-DD")
            for comm in ksef_commitments:
                if comm.due_date == day_str:
                    predicted_outflow += comm.amount_gross

            # ZUS — stała kwota, nie procent (2026: ~1600 PLN dla JDG)
            ZUS_MONTHLY = 1600.0
            if day_of_month in (10, 15, 20) and monthly_fixed_costs > 0:
                predicted_outflow += ZUS_MONTHLY / 3  # Rozłożone na 3 raty

            # VAT — zależny od przychodów, nie kosztów
            if day_of_month == 25 and avg_daily_inflow > 0:
                predicted_outflow += avg_daily_inflow * 30 * 0.23 * 0.3  # ~30% miesięcznych przychodów jako VAT

            # Aktualizuj saldo
            balance += predicted_inflow - predicted_outflow
            min_balance = min(min_balance, balance)
            max_balance = max(max_balance, balance)

            # Określ ryzyko
            threshold = monthly_fixed_costs if monthly_fixed_costs > 0 else 10000
            if balance < threshold * self.CRITICAL_BALANCE_RATIO:
                risk = "critical"
                days_critical += 1
            elif balance < threshold * self.WARNING_BALANCE_RATIO:
                risk = "high"
            elif balance < threshold * 2:
                risk = "medium"
            else:
                risk = "low"

            # Confidence interval — based on historical volatility
            if len(daily_inflows) >= 2:
                import statistics
                inflow_std = statistics.stdev(daily_inflows) if len(set(daily_inflows)) > 1 else avg_daily_inflow * 0.1
                outflow_std = statistics.stdev(daily_outflows) if len(set(daily_outflows)) > 1 else avg_daily_outflow * 0.1
                combined_std = math.sqrt(inflow_std**2 + outflow_std**2)
            else:
                combined_std = abs(avg_daily_inflow - avg_daily_outflow) * 0.2

            predictions.append(DailyCashFlowPrediction(
                date=day_str,
                predicted_inflow=round(predicted_inflow, 2),
                predicted_outflow=round(predicted_outflow, 2),
                predicted_balance=round(balance, 2),
                confidence_interval_low=round(balance - combined_std * 1.96, 2),
                confidence_interval_high=round(balance + combined_std * 1.96, 2),
                risk_level=risk,
            ))

            # Generuj alerty
            if risk == "critical":
                alerts.append(CashFlowAlert(
                    alert_id=f"ALERT-{day_str}",
                    date=day_str,
                    severity="critical",
                    message=f"KRYTYCZNE: Saldo {balance:,.2f} PLN dnia {day_str}. "
                            f"Może zabraknąć na ZUS/VAT!",
                    predicted_shortfall=round(abs(balance - threshold), 2),
                    recommendation=(
                        "Rozważ faktoring należności lub przesunięcie płatności."
                        if predicted_inflow > 0
                        else "Natychmiast zabezpiecz finansowanie pomostowe."
                    ),
                ))
            elif risk == "high":
                alerts.append(CashFlowAlert(
                    alert_id=f"WARN-{day_str}",
                    date=day_str,
                    severity="warning",
                    message=f"UWAGA: Niskie saldo {balance:,.2f} PLN dnia {day_str}.",
                    predicted_shortfall=round(abs(balance - threshold), 2),
                    recommendation="Monitoruj płatności i rozważ opóźnienie mniej pilnych wydatków.",
                ))

        # Podsumowanie
        if days_critical > 0:
            summary = (
                f"⚠️ {days_critical}/{days_ahead} dni z krytycznie niskim saldem. "
                f"Minimalne saldo: {min_balance:,.2f} PLN."
            )
        elif min_balance < 0:
            summary = f"UWAGA: Przewidywane ujemne saldo ({min_balance:,.2f} PLN)."
        else:
            summary = f"✅ Płynność stabilna przez {days_ahead} dni. Min: {min_balance:,.2f} PLN."

        return CashFlowForecast(
            forecast_id=forecast_id,
            generated_at=today.isoformat(),
            days_ahead=days_ahead,
            predictions=predictions,
            alerts=alerts,
            min_balance=round(min_balance, 2),
            max_balance=round(max_balance, 2),
            days_critical=days_critical,
            summary=summary,
        )

    # ── ML Model Interface ───────────────────────────────────────────

    def set_ml_model(self, model: Any) -> None:
        """Ustaw zewnętrzny model ML (LSTM/Prophet)."""
        self._ml_model = model
        logger.info("[ML-CASHFLOW] ML model set: %s", type(model).__name__)

    def set_custom_predictor(self, predictor: Callable) -> None:
        """Ustaw niestandardową funkcję predykcji."""
        self._custom_predictor = predictor
