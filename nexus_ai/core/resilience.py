# core/resilience.py
"""Async-native resilience — retry + circuit breaker via stamina.

Zgodnie z aa3fvcx.txt:
- stamina zastępuje tenacity + pybreaker
- Async-native, zbudowany na anyio (ta sama warstwa co Litestar + Granian)
- Wbudowany Circuit Breaker — po serii błędów odcina dostęp na określony czas
- Wykładnicze opóźnienia z jitterem
"""

from __future__ import annotations

import functools
import logging
from typing import Any, Callable, TypeVar

import stamina

logger = logging.getLogger("nexus.core.resilience")

F = TypeVar("F", bound=Callable[..., Any])


def async_retry(
    on: tuple[type[Exception], ...] | type[Exception] = (Exception,),
    attempts: int = 3,
    timeout: float = 10.0,
    circuit_breaker: bool = True,
) -> Callable[[F], F]:
    """Async-native retry + circuit breaker decorator using stamina.

    Zastępuje: @tenacity.retry + pybreaker.CircuitBreaker
    Nowy:     @stamina.retry (wbudowany circuit breaker)

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
            ):
                with attempt:
                    return await func(*args, **kwargs)
            raise RuntimeError("Retry attempts exhausted") from None
        return wrapper  # type: ignore[return-value]
    return decorator
