# core/resilience.py
"""
Resilience and retry utilities for NexusAI.

Replaced custom implementation with ``tenacity`` (well-known battle-tested library).

Provides:
- ``async_retry`` — backward-compatible decorator (same API as before)

Deprecated (kept for backward compatibility, will raise on use):
- ``compute_backoff_delay`` — use ``tenacity.wait_exponential`` directly
- ``RetryHandler`` — use ``tenacity`` retry state machine
- ``submit_with_retry`` — use ``tenacity.retry`` directly
"""

from __future__ import annotations

import logging
import warnings
from typing import Callable, Any

from tenacity import (
    retry as tenacity_retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
    before_sleep_log,
)

logger = logging.getLogger("nexus.core.resilience")


class async_retry:
    """
    Decorator that retries an async function with exponential backoff.
    Backward-compatible wrapper around tenacity.

    Args:
        max_retries: Maximum retry attempts (default 3).
        base_delay: Initial delay in seconds (default 1.0).
        max_delay: Maximum delay cap (default 60.0).
        exceptions: Tuple of exception types to catch (default Exception).

    Usage::
        @async_retry(max_retries=5, base_delay=0.5, max_delay=30.0)
        async def fetch_data(url: str) -> dict:
            ...
    """

    def __init__(
        self,
        max_retries: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 60.0,
        exceptions: tuple[type[Exception], ...] = (Exception,),
    ):
        self.max_retries = max_retries
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.exceptions = exceptions

    def __call__(self, func: Callable[..., Any]) -> Callable[..., Any]:
        # tenacity counts total attempts (initial + retries)
        # Our old API: max_retries = number of retries after initial attempt
        max_attempts = self.max_retries + 1

        decorator = tenacity_retry(
            stop=stop_after_attempt(max_attempts),
            wait=wait_exponential(
                multiplier=self.base_delay,
                min=self.base_delay,
                max=self.max_delay,
            ),
            retry=retry_if_exception_type(self.exceptions),
            reraise=True,
            before_sleep=before_sleep_log(logger, logging.WARNING),
        )
        return decorator(func)


# ── Deprecated exports (backward compatibility) ─────────────────────────────


def compute_backoff_delay(*args: Any, **kwargs: Any) -> float:
    """Deprecated: use ``tenacity.wait_exponential`` directly."""
    warnings.warn(
        "compute_backoff_delay is deprecated, use tenacity.wait_exponential directly",
        DeprecationWarning,
        stacklevel=2,
    )
    # Fall back to the old calculation to not break callers
    from math import pow as math_pow
    attempt = kwargs.get("attempt", args[0] if args else 0)
    base_delay = kwargs.get("base_delay", args[1] if len(args) > 1 else 1.0)
    max_delay = kwargs.get("max_delay", args[2] if len(args) > 2 else 60.0)
    jitter = kwargs.get("jitter", True)
    import random
    delay = min(base_delay * (2 ** attempt), max_delay)
    if jitter:
        jitter_range = delay * 0.25
        delay += random.uniform(-jitter_range, jitter_range)
        delay = max(0.1, delay)
    return round(delay, 3)


class RetryHandler:
    """Deprecated: use ``tenacity`` retry state machine directly."""

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        warnings.warn(
            "RetryHandler is deprecated, use tenacity.retry directly",
            DeprecationWarning,
            stacklevel=2,
        )
        self.max_retries = kwargs.get("max_retries", args[0] if args else 3)
        self.base_delay = kwargs.get("base_delay", args[1] if len(args) > 1 else 1.0)
        self.max_delay = kwargs.get("max_delay", args[2] if len(args) > 2 else 60.0)
        self.jitter = kwargs.get("jitter", True)
        self._attempts = 0
        self._success = False

    @property
    def exhausted(self) -> bool:
        return self._attempts > self.max_retries and not self._success

    @property
    def attempt_count(self) -> int:
        return self._attempts

    def should_retry(self) -> bool:
        if self._success:
            return False
        return self._attempts <= self.max_retries

    def record_success(self) -> None:
        self._success = True

    def record_failure(self) -> float:
        self._attempts += 1
        if self._attempts > self.max_retries:
            return 0.0
        return compute_backoff_delay(
            attempt=self._attempts - 1,
            base_delay=self.base_delay,
            max_delay=self.max_delay,
            jitter=self.jitter,
        )


async def submit_with_retry(
    func: Callable[..., Any],
    *args: Any,
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    exceptions: tuple[type[Exception], ...] = (Exception,),
    on_retry: Callable[[int, float, Exception], None] | None = None,
    **kwargs: Any,
) -> Any:
    """Deprecated: use ``tenacity.retry`` directly.

    Args:
        func: Async callable to invoke.
        *args: Positional arguments for the callable.
        max_retries: Maximum number of retry attempts.
        base_delay: Initial backoff delay in seconds.
        max_delay: Maximum delay cap.
        exceptions: Tuple of exception types to catch and retry.
        on_retry: Optional callback(attempt, delay, exception) before each retry.
        **kwargs: Keyword arguments for the callable.

    Returns:
        The return value of the callable.

    Raises:
        The last exception caught after exhausting retries.
    """
    warnings.warn(
        "submit_with_retry is deprecated, use tenacity.retry directly",
        DeprecationWarning,
        stacklevel=2,
    )
    handler = RetryHandler(
        max_retries=max_retries,
        base_delay=base_delay,
        max_delay=max_delay,
    )

    while handler.should_retry():
        try:
            result = await func(*args, **kwargs)
            handler.record_success()
            return result
        except exceptions as e:
            delay = handler.record_failure()
            if handler.exhausted:
                logger.error(
                    "Retry exhausted for %s after %d attempts: %s",
                    func.__name__,
                    handler.attempt_count,
                    e,
                )
                raise
            logger.warning(
                "Retry %d/%d for %s failed: %s. Retrying in %.1fs...",
                handler.attempt_count,
                max_retries,
                func.__name__,
                e,
                delay,
            )
            if on_retry:
                on_retry(handler.attempt_count, delay, e)
            import asyncio
            await asyncio.sleep(delay)

    raise RuntimeError("Unexpected state in submit_with_retry")
