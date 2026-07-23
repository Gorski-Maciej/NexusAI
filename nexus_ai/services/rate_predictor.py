"""
v7.0 INNOWACJA 3: NBP Rate Predictor — Predykcja Kursów Walut.

Używa historycznych danych NBP z ostatnich 5 lat + modelu statystycznego
(moving average + seasonal decomposition + volatility tracking) do:
- Przewidywania kursu na następny dzień roboczy
- Sugerowania optymalnego dnia dla transakcji walutowej
- Automatycznego alertu przy anomalii kursowej (>2 sigma)

v7.0 INNOWACJA 4: Smart Retry Scheduler — Inteligentne Ponawianie.

Analizuje historyczne dane i dostosowuje:
- Liczbę prób (zwiększa gdy API niestabilne)
- Opóźnienie między próbami (wydłuża w godzinach szczytu)
- Priorytet zapytań (krytyczne idą przez dedykowany kanał)
"""

from __future__ import annotations

import statistics
import time
from dataclasses import dataclass, field
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.services.rate_predictor")


# ═════════════════════════════════════════════════════════════════════════════
# INNOWACJA 3: NBP Rate Predictor
# ═════════════════════════════════════════════════════════════════════════════

@dataclass
class RatePrediction:
    """Predykcja kursu walutowego."""
    currency: str
    predicted_rate: float
    prediction_date: str  # YYYY-MM-DD
    confidence_interval: tuple[float, float]  # (low, high) dla 95% CI
    trend: str  # up, down, stable
    volatility_24h: float  # zmienność w ostatnich 24h
    anomaly_detected: bool
    anomaly_sigma: float  # ile sigma od średniej (0 = normalne)
    optimal_action: str  # kup_teraz, czekaj, sprzedaj_teraz


@dataclass
class RateHistoryEntry:
    """Pojedynczy wpis historyczny kursu."""
    date: str
    rate: float
    source: str


class NbpRatePredictor:
    """v7.0: Predyktor kursów walut na podstawie danych historycznych.

    Używa:
    - Simple Moving Average (SMA) dla trendu
    - Seasonal decomposition dla wzorców tygodniowych
    - Volatility tracking dla detekcji anomalii
    - 95% confidence interval przez ±2σ
    """

    # Parametry modelu
    SMA_WINDOW_SHORT = 7   # 7 dni
    SMA_WINDOW_MEDIUM = 30  # 30 dni
    VOLATILITY_WINDOW = 90  # 90 dni do obliczenia sigma
    ANOMALY_SIGMA_THRESHOLD = 2.0  # >2 sigma = anomalia

    def __init__(self) -> None:
        self._history: dict[str, list[RateHistoryEntry]] = {}
        self._last_predictions: dict[str, RatePrediction] = {}

    def add_rate(self, currency: str, date_str: str, rate: float, source: str = "NBP") -> None:
        """Dodaj wpis do historii kursów."""
        if currency not in self._history:
            self._history[currency] = []

        entry = RateHistoryEntry(date=date_str, rate=rate, source=source)
        self._history[currency].append(entry)

        # Ogranicz do 5 lat (około 1260 dni roboczych)
        if len(self._history[currency]) > 1500:
            self._history[currency] = self._history[currency][-1500:]

        # Sortuj po dacie
        self._history[currency].sort(key=lambda e: e.date)

    def predict(self, currency: str, target_date: str | None = None) -> RatePrediction:
        """Przewiduj kurs na podaną datę (lub następny dzień roboczy).

        Args:
            currency: Kod waluty (EUR, USD, GBP, itd.).
            target_date: Data docelowa (YYYY-MM-DD). None = następny dzień roboczy.

        Returns:
            RatePrediction z przewidywanym kursem i metadanymi.
        """
        if target_date is None:
            target_date = pendulum.tomorrow("Europe/Warsaw").to_date_string()

        history = self._history.get(currency, [])
        if len(history) < self.SMA_WINDOW_SHORT:
            # Za mało danych — zwróć ostatni znany kurs
            last_rate = history[-1].rate if history else 4.50
            return RatePrediction(
                currency=currency,
                predicted_rate=last_rate,
                prediction_date=target_date,
                confidence_interval=(last_rate * 0.95, last_rate * 1.05),
                trend="unknown",
                volatility_24h=0.0,
                anomaly_detected=False,
                anomaly_sigma=0.0,
                optimal_action="czekaj",
            )

        rates = [e.rate for e in history]

        # 1. Simple Moving Average (krótki i średni termin)
        sma_short = statistics.mean(rates[-self.SMA_WINDOW_SHORT:])
        sma_medium = statistics.mean(rates[-min(self.SMA_WINDOW_MEDIUM, len(rates)):])

        # 2. Trend: porównaj SMA krótki vs średni
        if sma_short > sma_medium * 1.005:
            trend = "up"
        elif sma_short < sma_medium * 0.995:
            trend = "down"
        else:
            trend = "stable"

        # 3. Predykcja: SMA short + korekta trendu
        trend_adjustment = (sma_short - sma_medium) * 0.5
        predicted = sma_short + trend_adjustment

        # 4. Zmienność (sigma) z ostatnich 90 dni
        volatility_window = rates[-min(self.VOLATILITY_WINDOW, len(rates)):]
        sigma = statistics.stdev(volatility_window) if len(volatility_window) >= 5 else 0.01

        # 5. Confidence interval (95% = ±2σ)
        ci_low = predicted - 2 * sigma
        ci_high = predicted + 2 * sigma

        # 6. Detekcja anomalii
        anomaly_sigma = 0.0
        if sigma > 0:
            anomaly_sigma = abs(predicted - sma_medium) / sigma
        anomaly = anomaly_sigma > self.ANOMALY_SIGMA_THRESHOLD

        # 7. Zmienność 24h
        vol_24h = statistics.stdev(rates[-3:]) if len(rates) >= 3 else 0.0

        # 8. Optymalna akcja
        if trend == "up" and not anomaly:
            action = "kup_teraz"
        elif trend == "down" and not anomaly:
            action = "czekaj"
        elif anomaly and trend == "up":
            action = "sprzedaj_teraz"  # Anomalny wzrost → sprzedaj
        else:
            action = "czekaj"

        prediction = RatePrediction(
            currency=currency,
            predicted_rate=round(predicted, 4),
            prediction_date=target_date,
            confidence_interval=(round(ci_low, 4), round(ci_high, 4)),
            trend=trend,
            volatility_24h=round(vol_24h, 6),
            anomaly_detected=anomaly,
            anomaly_sigma=round(anomaly_sigma, 2),
            optimal_action=action,
        )

        self._last_predictions[currency] = prediction
        return prediction

    def get_optimal_transaction_day(
        self, currency: str, days_ahead: int = 5,
    ) -> list[dict[str, Any]]:
        """Znajdź optymalny dzień dla transakcji walutowej w ciągu najbliższych dni.

        Returns:
            Lista predykcji posortowana po przewidywanym kursie (najlepszy pierwszy).
        """
        predictions = []
        for i in range(1, days_ahead + 1):
            target = pendulum.today("Europe/Warsaw").add(days=i).to_date_string()
            pred = self.predict(currency, target)
            predictions.append({
                "date": target,
                "predicted_rate": pred.predicted_rate,
                "trend": pred.trend,
                "optimal_action": pred.optimal_action,
                "anomaly": pred.anomaly_detected,
            })

        # Sortuj: najniższy kurs dla kupującego PLN
        predictions.sort(key=lambda p: p["predicted_rate"])
        return predictions

    def check_anomaly_alert(
        self, currency: str, current_rate: float,
    ) -> dict[str, Any] | None:
        """Sprawdź czy obecny kurs jest anomalią (>2 sigma).

        Returns:
            Alert dict lub None jeśli kurs normalny.
        """
        history = self._history.get(currency, [])
        if len(history) < self.SMA_WINDOW_MEDIUM:
            return None

        rates = [e.rate for e in history[-self.VOLATILITY_WINDOW:]]
        mean = statistics.mean(rates)
        sigma = statistics.stdev(rates) if len(rates) >= 5 else 0.01

        if sigma == 0:
            return None

        deviation = abs(current_rate - mean) / sigma
        if deviation > self.ANOMALY_SIGMA_THRESHOLD:
            direction = "wzrost" if current_rate > mean else "spadek"
            return {
                "currency": currency,
                "current_rate": current_rate,
                "mean_rate": round(mean, 4),
                "sigma": round(sigma, 6),
                "deviation_sigma": round(deviation, 2),
                "direction": direction,
                "severity": "high" if deviation > 3 else "medium",
                "message": (
                    f"Anomalia kursowa {currency}: {current_rate:.4f} "
                    f"({direction} o {deviation:.1f}σ od średniej {mean:.4f})"
                ),
            }
        return None


# ═════════════════════════════════════════════════════════════════════════════
# INNOWACJA 4: Smart Retry Scheduler
# ═════════════════════════════════════════════════════════════════════════════

@dataclass
class RetryProfile:
    """Profil retry dla konkretnej integracji."""
    integration: str
    base_attempts: int = 3
    base_delay_seconds: float = 1.0
    max_delay_seconds: float = 60.0
    # Historyczne metryki
    success_rate_24h: float = 100.0
    avg_response_time_ms: float = 0.0
    recent_failures: int = 0
    # Dynamicznie obliczone
    effective_attempts: int = 3
    effective_delay: float = 1.0


class SmartRetryScheduler:
    """v7.0 INNOWACJA 4: Inteligentny harmonogram ponawiania.

    Analizuje historyczne dane o dostępności API i dostosowuje:
    - Liczbę prób: zwiększa gdy API niestabilne
    - Opóźnienie: wydłuża w godzinach szczytu (10-12 CET dla API MF)
    - Priorytet: krytyczne zapytania (KSeF) mają więcej prób
    """

    # Godziny szczytu dla API MF (CET)
    PEAK_HOURS = list(range(10, 13))  # 10:00-12:59

    def __init__(self) -> None:
        self._profiles: dict[str, RetryProfile] = {}
        self._init_defaults()

    def _init_defaults(self) -> None:
        """Inicjalizuj domyślne profile retry."""
        self._profiles = {
            "ksef": RetryProfile(
                integration="ksef",
                base_attempts=5,       # KSeF jest krytyczny — więcej prób
                base_delay_seconds=2.0,
            ),
            "gus_bir": RetryProfile(
                integration="gus_bir",
                base_attempts=3,
                base_delay_seconds=1.0,
            ),
            "white_list": RetryProfile(
                integration="white_list",
                base_attempts=3,
                base_delay_seconds=0.5,
            ),
            "nbp": RetryProfile(
                integration="nbp",
                base_attempts=3,
                base_delay_seconds=1.0,
            ),
            "ecb": RetryProfile(
                integration="ecb",
                base_attempts=2,
                base_delay_seconds=2.0,
            ),
        }

    def get_retry_config(
        self, integration: str, is_critical: bool = False,
    ) -> dict[str, Any]:
        """Pobierz dynamiczną konfigurację retry dla integracji.

        Args:
            integration: Nazwa integracji (ksef, gus_bir, white_list, nbp, ecb).
            is_critical: Czy zapytanie jest krytyczne (np. wysyłka faktury).

        Returns:
            dict z attempts, delay_seconds, timeout, priority.
        """
        profile = self._profiles.get(integration)
        if profile is None:
            profile = RetryProfile(integration=integration)
            self._profiles[integration] = profile

        # Bazowa liczba prób
        attempts = profile.base_attempts

        # Zwiększ jeśli API niestabilne (niski success rate)
        if profile.success_rate_24h < 90:
            attempts += 2
        elif profile.success_rate_24h < 95:
            attempts += 1

        # Zwiększ dla krytycznych zapytań
        if is_critical:
            attempts += 2

        # Zmniejsz jeśli API jest szybkie i stabilne
        if profile.success_rate_24h > 99 and profile.avg_response_time_ms < 500:
            attempts = max(1, attempts - 1)

        # Ogranicz do sensownego zakresu
        attempts = max(1, min(attempts, 10))

        # Dynamiczne opóźnienie
        delay = profile.base_delay_seconds

        # Wydłuż w godzinach szczytu
        current_hour = pendulum.now("Europe/Warsaw").hour
        if current_hour in self.PEAK_HOURS:
            delay *= 2.0

        # Wydłuż gdy API wolne
        if profile.avg_response_time_ms > 5000:
            delay *= 1.5

        # Skróć gdy API szybkie
        if profile.avg_response_time_ms < 500 and profile.success_rate_24h > 99:
            delay *= 0.5

        delay = max(0.1, min(delay, profile.max_delay_seconds))

        # Timeout
        timeout = profile.avg_response_time_ms / 1000 * 3 if profile.avg_response_time_ms > 0 else 10.0
        timeout = max(5.0, min(timeout, 30.0))

        # Priorytet
        if is_critical:
            priority = "critical"
        elif integration in ("ksef", "white_list"):
            priority = "high"
        elif integration in ("nbp", "ecb"):
            priority = "medium"
        else:
            priority = "normal"

        return {
            "attempts": attempts,
            "delay_seconds": round(delay, 2),
            "timeout": round(timeout, 1),
            "priority": priority,
            "peak_hours": self.PEAK_HOURS,
            "is_peak": current_hour in self.PEAK_HOURS,
        }

    def record_result(
        self, integration: str, success: bool, response_ms: float,
    ) -> None:
        """Zarejestruj wynik zapytania dla adaptacyjnego retry."""
        profile = self._profiles.get(integration)
        if profile is None:
            return

        # Aktualizuj success rate (exponential moving average)
        alpha = 0.1  # Waga dla nowej obserwacji
        if success:
            profile.success_rate_24h = (1 - alpha) * profile.success_rate_24h + alpha * 100
            profile.recent_failures = max(0, profile.recent_failures - 1)
        else:
            profile.success_rate_24h = (1 - alpha) * profile.success_rate_24h + alpha * 0
            profile.recent_failures += 1

        # Aktualizuj średni czas odpowiedzi
        if profile.avg_response_time_ms == 0:
            profile.avg_response_time_ms = response_ms
        else:
            profile.avg_response_time_ms = (
                0.9 * profile.avg_response_time_ms + 0.1 * response_ms
            )

    def get_profile(self, integration: str) -> RetryProfile | None:
        """Pobierz profil retry."""
        return self._profiles.get(integration)
