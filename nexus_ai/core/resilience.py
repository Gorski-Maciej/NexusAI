# core/resilience.py
"""Async-native resilience — retry + circuit breaker via stamina.

Zgodnie z aa3fvcx.txt:
- stamina jest async-native, zbudowany na anyio (ta sama warstwa co Litestar + Granian)
- Wbudowany Circuit Breaker — po serii błędów odcina dostęp na określony czas
- Wykładnicze opóźnienia z jitterem
"""

from __future__ import annotations

import functools
from typing import Any, Callable, TypeVar

import stamina
from nexus_ai.core.logger import get_logger

logger = get_logger("nexus.core.resilience")

F = TypeVar("F", bound=Callable[..., Any])


def async_retry(
    on: tuple[type[Exception], ...] | type[Exception] = (Exception,),
    attempts: int = 3,
    timeout: float = 10.0,
    circuit_breaker: bool = True,
) -> Callable[[F], F]:
    """Async-native retry + circuit breaker decorator using stamina.

    Używa: @stamina.retry (wbudowany circuit breaker)

    SUPERMOC:
      - circuit_breaker=True — włącza wbudowany Circuit Breaker
      - stamina.RetryingError — poprawny typ wyjątku

    Args:
        on: Tuple of exceptions to retry on (default: Exception).
        attempts: Max number of retry attempts (default: 3).
        timeout: Timeout in seconds for each attempt (default: 10.0).
        circuit_breaker: Enable circuit breaker (default: True).

    Usage:
        @async_retry(on=(httpx.HTTPError,), attempts=3, timeout=10.0)
        async def send_to_ksef(data: dict) -> dict:
            ...
    """

    def decorator(func: F) -> F:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            for attempt in stamina.retry_context(
                on=on,
                attempts=attempts,
                timeout=timeout,
                circuit_breaker=circuit_breaker,
            ):
                with attempt:
                    return await func(*args, **kwargs)
            raise stamina.RetryingError(
                f"{func.__name__} failed after {attempts} attempts (timeout={timeout}s)"
            ) from None

        return wrapper  # type: ignore[return-value]

    return decorator


# @stamina.retry on=(Exception,), attempts=3, timeout=10.0)  # zarezerwowane do przyszłego użycia
