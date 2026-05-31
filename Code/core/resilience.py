# core/resilience.py
"""
Resilience and retry utilities for NexusAI.

Provides:
- ``async_retry`` — decorator for exponential backoff retry on async functions
- ``compute_backoff_delay`` — pure function for exponential backoff with jitter
- ``RetryHandler`` — configurable retry state machine for inline use
- ``submit_with_retry`` — retry a callable directly with backoff
"""

from __future__ import annotations

import asyncio
import logging
import random
from dataclasses import dataclass, field
from typing import Callable, Any, TypeVar
from functools import wraps

logger = logging.getLogger("nexus.core.resilience")

T = TypeVar("T")


def compute_backoff_delay(
    attempt: int,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    jitter: bool = True,
) -> float:
    """
    Compute exponential backoff delay with optional jitter.

    Args:
        attempt: Current attempt number (0-indexed).
        base_delay: Base delay in seconds (default 1.0).
        max_delay: Maximum delay cap (default 60.0).
        jitter: Add random jitter ±25% to spread retries.

    Returns:
        Delay in seconds before the next retry.

    Examples:
        >>> compute_backoff_delay(0)  # ~1s
        >>> compute_backoff_delay(1)  # ~2s
        >>> compute_backoff_delay(2)  # ~4s
        >>> compute_backoff_delay(3)  # ~8s
    """
    delay = min(base_delay * (2 ** attempt), max_delay)
    if jitter:
        # Add ±25% jitter
        jitter_range = delay * 0.25
        delay += random.uniform(-jitter_range, jitter_range)
        delay = max(0.1, delay)  # Ensure minimum delay
    return round(delay, 3)


@dataclass
class RetryHandler:
    """
    Configurable retry state machine for inline use.

    Tracks retry count and computes backoff delays automatically.
    Useful when you want to control retries inline without a decorator.

    Usage::
        retry = RetryHandler(max_retries=3, base_delay=1.0)
        while retry.should_retry():
            try:
                result = await some_operation()
                retry.record_success()
                break
            except Exception as e:
                delay = retry.record_failure()
                if retry.exhausted:
                    raise  # Max retries reached
                await asyncio.sleep(delay)
    """

    max_retries: int = 3
    base_delay: float = 1.0
    max_delay: float = 60.0
    jitter: bool = True

    _attempts: int = field(default=0, init=False)
    _success: bool = field(default=False, init=False)

    @property
    def exhausted(self) -> bool:
        """True if max retries have been exhausted without success."""
        return self._attempts > self.max_retries and not self._success

    @property
    def attempt_count(self) -> int:
        return self._attempts

    def should_retry(self) -> bool:
        """Check if another retry attempt is allowed."""
        if self._success:
            return False
        return self._attempts <= self.max_retries

    def record_success(self) -> None:
        """Mark the operation as successfully completed."""
        self._success = True

    def record_failure(self) -> float:
        """
        Record a failure and return the delay before the next retry.

        Returns:
            Delay in seconds (0.0 if max retries exhausted).
        """
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
    """
    Execute an async callable with exponential backoff retry.

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
            await asyncio.sleep(delay)

    # Should not reach here, but defensive
    raise RuntimeError("Unexpected state in submit_with_retry")


class async_retry:
    """
    Decorator that retries an async function with exponential backoff.

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
        @wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            return await submit_with_retry(
                func,
                *args,
                max_retries=self.max_retries,
                base_delay=self.base_delay,
                max_delay=self.max_delay,
                exceptions=self.exceptions,
                **kwargs,
            )
        return wrapper
