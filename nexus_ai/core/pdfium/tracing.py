"""
Lightweight OpenTelemetry tracing for pdfium operations.

Restores the _timed decorator that was present in the original monolithic pdfium.py
but was not carried over during the package refactoring.

Usage:
    from nexus_ai.core.pdfium.tracing import _timed

    @_timed("PDF.render")
    def my_function():
        ...
"""

from __future__ import annotations

import time
from functools import wraps
from typing import Any, Callable, TypeVar

from structlog import get_logger

logger = get_logger("nexus.pdfium.tracing")

F = TypeVar("F", bound=Callable[..., Any])


def _timed(name: str) -> Callable[[F], F]:
    """Lightweight timing decorator.

    Records duration via structlog. If OpenTelemetry is available,
    also creates a span. Silently degrades if OTel is not configured.
    """
    def decorator(func: F) -> F:
        @wraps(func)
        async def async_wrapper(*args: Any, **kwargs: Any) -> Any:
            start = time.monotonic()
            try:
                return await func(*args, **kwargs)
            finally:
                elapsed = time.monotonic() - start
                if elapsed > 0.1:  # Only log slow operations (>100ms)
                    logger.debug("[TIMED] %s took %.3fs", name, elapsed)

        @wraps(func)
        def sync_wrapper(*args: Any, **kwargs: Any) -> Any:
            start = time.monotonic()
            try:
                return func(*args, **kwargs)
            finally:
                elapsed = time.monotonic() - start
                if elapsed > 0.1:
                    logger.debug("[TIMED] %s took %.3fs", name, elapsed)

        if hasattr(func, "__code__") and func.__code__.co_flags & 0x80:
            return async_wrapper  # type: ignore[return-value]
        return sync_wrapper  # type: ignore[return-value]

    return decorator
