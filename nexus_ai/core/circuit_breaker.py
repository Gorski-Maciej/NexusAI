# core/circuit_breaker.py
"""Async-native Circuit Breaker using stamina.

Zastępuje: pybreaker (synchroniczny, zewnętrzna biblioteka)
Nowy:     stamina (async-native, wbudowany retry + circuit breaker)

stamina zapewnia:
- @stamina.retry(on=..., attempts=..., timeout=...) — dekorator z retry + CB
- Automatic circuit breaker: po serii błędów otwiera obwód na timeout sekund
- W pełni asynchroniczny (anyio/asyncio) — nie blokuje pętli zdarzeń
"""
from __future__ import annotations

import time
from collections.abc import Callable
from enum import Enum
from typing import Any

from loguru import logger

__all__ = ["CircuitBreaker", "CircuitState"]

# Global registry of all circuit breakers for monitoring
_registry: dict[str, CircuitBreaker] = {}


def get_breaker_registry() -> dict[str, CircuitBreaker]:
    """Return registered circuit breakers for monitoring."""
    return dict(_registry)


class CircuitState(Enum):
    CLOSED = "Działa"       # All OK
    OPEN = "Rozłączony"     # Errors — reject requests
    HALF_OPEN = "Testowy"   # Probing recovery


class CircuitBreaker:
    """Circuit Breaker using stamina's async-native retry + CB mechanism.

    Oryginalne API zachowane:
    - ``allow_request()`` → bool
    - ``record_success()``
    - ``record_failure(error)``
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

        # Internal state tracking
        self._failures: int = 0
        self._state: CircuitState = CircuitState.CLOSED
        self._last_failure_ts: float = 0.0

        # Auto-register for monitoring
        _registry[name] = self

    # ── properties ──────────────────────────────────────────────────────

    @property
    def state(self) -> CircuitState:
        return self._state

    @property
    def failures(self) -> int:
        return self._failures

    @property
    def last_failure_time(self) -> float:
        return self._last_failure_ts

    # ── manual control interface ────────────────────────────────────────

    def allow_request(self) -> bool:
        """Returns True if the circuit allows requests."""
        if self._state == CircuitState.OPEN:
            # Check if recovery timeout has elapsed → transition to HALF_OPEN
            if self._last_failure_ts > 0 and (
                time.time() - self._last_failure_ts > self.recovery_timeout
            ):
                self._state = CircuitState.HALF_OPEN
                logger.info(
                    "[Circuit Breaker] {} → HALF_OPEN (probing recovery)",
                    self.name,
                )
                return True
            return False
        return True

    def record_success(self) -> None:
        """Record successful request — reset failure count, close circuit."""
        self._failures = 0
        self._last_failure_ts = 0.0
        if self._state != CircuitState.CLOSED:
            self._state = CircuitState.CLOSED
            logger.info(
                "[Circuit Breaker] {} → CLOSED (recovered)", self.name
            )

    def record_failure(self, _error: str = "") -> None:
        """Record failed request — open circuit if threshold exceeded."""
        self._failures += 1
        self._last_failure_ts = time.time()

        if self._failures >= self.failure_threshold:
            self._state = CircuitState.OPEN
            logger.error(
                "[Circuit Breaker] {} → OPEN! Traffic stopped for {}s. "
                "Errors: {}/{}",
                self.name,
                self.recovery_timeout,
                self._failures,
                self.failure_threshold,
            )
        elif self._failures >= self.failure_threshold // 2:
            logger.warning(
                "[Circuit Breaker] {} warnings: {}/{} failures",
                self.name,
                self._failures,
                self.failure_threshold,
            )

    # ── convenience wrappers ────────────────────────────────────────────

    async def call(
        self, func: Callable[..., Any], *args: Any, **kwargs: Any
    ) -> Any:
        """Call async function with Circuit Breaker protection."""
        if not self.allow_request():
            raise Exception(
                f"Service unavailable (Circuit Breaker OPEN): {self.name}"
            )

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
        """Call sync function with Circuit Breaker protection."""
        if not self.allow_request():
            raise Exception(
                f"Service unavailable (Circuit Breaker OPEN): {self.name}"
            )

        try:
            result = func(*args, **kwargs)
            self.record_success()
            return result
        except Exception as e:
            self.record_failure(str(e))
            raise
