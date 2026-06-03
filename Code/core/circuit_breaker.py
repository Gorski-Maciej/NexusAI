# core/circuit_breaker.py
from __future__ import annotations

import time
from enum import Enum
from typing import Any, Callable

from loguru import logger
import pybreaker

__all__ = ["CircuitBreaker", "CircuitState"]

# Global registry of all circuit breakers for monitoring (Rozwiązanie 21)
_registry: dict[str, "CircuitBreaker"] = {}


def get_breaker_registry() -> dict[str, "CircuitBreaker"]:
    """Return registered circuit breakers for monitoring."""
    return dict(_registry)


class CircuitState(Enum):
    CLOSED = "Działa"       # Wszystko OK
    OPEN = "Rozłączony"     # Błędy — nie wysyłaj zapytań
    HALF_OPEN = "Testowy"   # Próba powrotu


# Map pybreaker current_state strings → our CircuitState enum
_PY_STATE_MAP: dict[str, CircuitState] = {
    pybreaker.STATE_CLOSED: CircuitState.CLOSED,
    pybreaker.STATE_OPEN: CircuitState.OPEN,
    pybreaker.STATE_HALF_OPEN: CircuitState.HALF_OPEN,
}


class CircuitBreaker:
    """Adapter wokół ``pybreaker.CircuitBreaker`` z zachowaniem oryginalnego API.

    Oryginalne API:
    - ``allow_request()`` → bool  (sprawdza czy obwód przepuszcza zapytanie)
    - ``record_success()``       (resetuje licznik błędów, zamyka obwód)
    - ``record_failure(error)``  (inkrementuje licznik, otwiera obwód po progu)
    - ``call(func, *args, **kwargs)``  (async wrapper z ochroną CB)
    - ``call_sync(func, *args, **kwargs)``  (sync wrapper z ochroną CB)

    Właściwości: ``state``, ``failures``, ``failure_threshold``,
    ``recovery_timeout``, ``last_failure_time``, ``name``.
    """

    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: int = 60,
        name: str = "unnamed",
    ) -> None:
        self.name = name
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout

        # Ostatnia chwila błędu (timestamp) — pybreaker nie eksponuje tego
        self._last_failure_ts: float = 0.0

        # Wewnętrzny breaker z pybreaker
        self._breaker = pybreaker.CircuitBreaker(
            fail_max=failure_threshold,
            reset_timeout=recovery_timeout,
            name=name,
        )

        # Auto-register for monitoring
        _registry[name] = self

    # ── właściwości (odwzorowują oryginalne atrybuty) ──────────────────

    @property
    def state(self) -> CircuitState:
        return _PY_STATE_MAP.get(
            self._breaker.current_state, CircuitState.CLOSED
        )

    @property
    def failures(self) -> int:
        return self._breaker.fail_counter

    @property
    def last_failure_time(self) -> float:
        return self._last_failure_ts

    # ── manualny interfejs sterowania (używany bezpośrednio w kodzie) ──

    def allow_request(self) -> bool:
        """Zwraca ``True`` jeśli obwód pozwala na wykonanie zapytania."""
        if self._breaker.current_state == pybreaker.STATE_OPEN:
            # Sprawdź czy timeout minął → przejdź do HALF_OPEN
            if self._last_failure_ts > 0 and (
                time.time() - self._last_failure_ts > self.recovery_timeout
            ):
                self._breaker.half_open()
                return True
            return False
        return True

    def record_success(self) -> None:
        """Rejestruje udane zapytanie — resetuje licznik błędów."""
        self._last_failure_ts = 0.0
        self._breaker.close()

    def record_failure(self, _error: str = "") -> None:
        """Rejestruje nieudane zapytanie — otwiera obwód po przekroczeniu progu."""
        self._last_failure_ts = time.time()
        self._breaker._inc_counter()

        if self._breaker.fail_counter >= self._breaker.fail_max:
            self._breaker.open()
            logger.error(
                f"[Circuit Breaker] Obwód OTWARTY! Ruch zatrzymany na "
                f"{self.recovery_timeout}s. "
                f"Błędy: {self._breaker.fail_counter}/{self.failure_threshold}"
            )

    # ── wygodne wrappery (call / call_sync) ────────────────────────────

    async def call(
        self, func: Callable[..., Any], *args: Any, **kwargs: Any
    ) -> Any:
        """Wywołuje funkcję **async** z ochroną Circuit Breaker."""
        if not self.allow_request():
            raise Exception("Usługa niedostępna (Circuit Breaker OPEN)")

        try:
            result = await func(*args, **kwargs)
            self.record_success()
            return result
        except Exception as e:
            self.record_failure(str(e))
            raise

    def call_sync(
        self, func: Callable[..., Any], *args: Any, **kwargs: Any
    ) -> Any:
        """Wywołuje funkcję **synchroniczną** z ochroną Circuit Breaker."""
        if not self.allow_request():
            raise Exception("Usługa niedostępna (Circuit Breaker OPEN)")

        try:
            result = func(*args, **kwargs)
            self.record_success()
            return result
        except Exception as e:
            self.record_failure(str(e))
            raise
