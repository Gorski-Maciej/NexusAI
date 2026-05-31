"""
Enhanced resilience module with retry policies, DLQ helpers, and exception taxonomy.

Provides:
- async_retry decorator with exponential backoff
- Task-specific retry policies with configurable exceptions
- DLQ submission helpers
- RetryPolicy dataclass for declarative configuration
"""
from __future__ import annotations

import asyncio
import json
import logging
import traceback
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import StrEnum
from typing import Any, Callable
from functools import wraps

logger = logging.getLogger("nexus.core.resilience")


# ── Exception types for retry classification ─────────────────────────────────


class RetryableException(Exception):
    """Base for exceptions that should trigger a retry."""
    pass


class NonRetryableException(Exception):
    """Base for exceptions that should NOT be retried (immediate fail)."""
    pass


class TransientError(RetryableException):
    """Temporary issues like network timeouts, connection resets."""
    pass


class ServiceUnavailableError(RetryableException):
    """Downstream service is unavailable."""
    pass


class RateLimitedError(RetryableException):
    """Rate limited by downstream service."""
    pass


class ValidationError(NonRetryableException):
    """Invalid input data — retrying won't help."""
    pass


class ConfigurationError(NonRetryableException):
    """Misconfiguration — retrying won't help."""
    pass


# ── Retry policy ─────────────────────────────────────────────────────────────


@dataclass
class RetryPolicy:
    """Declarative retry policy for a specific task type.

    Attributes:
        max_retries: Maximum number of retry attempts.
        base_delay: Initial delay in seconds (exponential backoff).
        max_delay: Maximum delay in seconds.
        retryable_exceptions: Tuple of exception types that trigger a retry.
        fatal_exceptions: Tuple of exception types that immediately fail (no retry).
        jitter: Add random jitter to delay (0.0-1.0 fraction).
    """
    max_retries: int = 3
    base_delay: float = 1.0
    max_delay: float = 30.0
    retryable_exceptions: tuple = (RetryableException, TransientError, ConnectionError, TimeoutError, OSError)
    fatal_exceptions: tuple = (NonRetryableException, ValidationError, ConfigurationError)
    jitter: float = 0.1


# ── Task-type specific policies ──────────────────────────────────────────────

TASK_RETRY_POLICIES: dict[str, RetryPolicy] = {
    # Invoice processing — transient AI/model failures are retryable
    "process_invoice": RetryPolicy(
        max_retries=3,
        base_delay=1.0,
        max_delay=10.0,
        retryable_exceptions=(TransientError, TimeoutError, ConnectionError, ServiceUnavailableError),
        fatal_exceptions=(ValidationError, ValueError),
    ),
    # OCR — network and service issues are retryable
    "ocr_process": RetryPolicy(
        max_retries=3,
        base_delay=2.0,
        max_delay=15.0,
    ),
    # KSeF submission — external API may be temporarily down
    "ksef_submit": RetryPolicy(
        max_retries=5,
        base_delay=5.0,
        max_delay=60.0,
        retryable_exceptions=(TransientError, TimeoutError, ConnectionError, ServiceUnavailableError),
        fatal_exceptions=(ValidationError, ConfigurationError),
    ),
    # Shadow ledger sync — transient TigerBeetle connection issues
    "shadow_ledger_sync": RetryPolicy(
        max_retries=3,
        base_delay=1.0,
        max_delay=5.0,
    ),
    # Audit report generation — can retry on any exception
    "generate_audit_report": RetryPolicy(
        max_retries=2,
        base_delay=1.0,
        max_delay=5.0,
    ),
    # Email notifications — retry on transient errors
    "send_email": RetryPolicy(
        max_retries=3,
        base_delay=0.5,
        max_delay=5.0,
    ),
    # Default for any unregistered task types
    "default": RetryPolicy(
        max_retries=3,
        base_delay=1.0,
        max_delay=10.0,
    ),
}

# ── DLQ helpers ──────────────────────────────────────────────────────────────


async def submit_to_dlq(
    db_engine: Any,
    *,
    task_name: str,
    task_id: str | None = None,
    payload: str = "{}",
    error_type: str = "UnknownError",
    error_message: str = "",
    stack_trace: str | None = None,
    retry_count: int = 0,
    max_retries: int = 3,
) -> str | None:
    """Submit a failed task to the Dead Letter Queue (failed_tasks table).

    Returns the failed_task ID if successful, None otherwise.
    """
    import uuid

    try:
        from sqlalchemy import text

        failed_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()

        async with db_engine.connect() as conn:
            await conn.execute(
                text(
                    """INSERT INTO failed_tasks
                       (id, task_name, task_id, payload, error_type, error_message,
                        stack_trace, retry_count, max_retries, failed_at, created_at)
                       VALUES
                       (:id, :task_name, :task_id, :payload, :error_type, :error_message,
                        :stack_trace, :retry_count, :max_retries, :failed_at, :created_at)"""
                ),
                {
                    "id": failed_id,
                    "task_name": task_name,
                    "task_id": task_id or "",
                    "payload": payload,
                    "error_type": error_type,
                    "error_message": error_message[:1000],  # Truncate for DB
                    "stack_trace": (stack_trace or "")[:5000],  # Truncate for DB
                    "retry_count": retry_count,
                    "max_retries": max_retries,
                    "failed_at": now,
                    "created_at": now,
                },
            )
            await conn.commit()

        logger.warning(
            "Task %s (id=%s) sent to DLQ after %d/%d retries. Error: %s",
            task_name, task_id, retry_count, max_retries, error_message,
        )
        return failed_id
    except Exception as exc:
        logger.error("Failed to submit task to DLQ: %s", exc)
        return None


async def move_to_dlq_on_final_failure(
    db_engine: Any,
    *,
    task_name: str,
    task_id: str | None = None,
    payload: dict | str = {},
    exception: Exception,
    retry_count: int,
    max_retries: int,
) -> str | None:
    """Convenience: move a task to DLQ after exhausting retries."""
    payload_str = json.dumps(payload) if isinstance(payload, dict) else str(payload)
    tb = traceback.format_exc() if hasattr(exception, "__traceback__") and exception.__traceback__ else str(exception)
    return await submit_to_dlq(
        db_engine,
        task_name=task_name,
        task_id=task_id,
        payload=payload_str,
        error_type=type(exception).__name__,
        error_message=str(exception),
        stack_trace=tb,
        retry_count=retry_count,
        max_retries=max_retries,
    )


# ── Retry decorator ──────────────────────────────────────────────────────────


def get_policy(task_type: str) -> RetryPolicy:
    """Get retry policy for a specific task type, falling back to 'default'."""
    return TASK_RETRY_POLICIES.get(task_type, TASK_RETRY_POLICIES["default"])


def async_retry(
    max_retries: int | None = None,
    base_delay: float | None = None,
    max_delay: float | None = None,
    exceptions: tuple | None = None,
    task_type: str | None = None,
    db_engine: Any = None,
    task_id: str | None = None,
    payload: dict | str | None = None,
):
    """Enhanced async retry decorator with DLQ support.

    If a task_type is provided, uses the corresponding RetryPolicy.
    If db_engine is provided, exhausted tasks are moved to DLQ.

    Args:
        max_retries: Override max retries.
        base_delay: Override base delay in seconds.
        max_delay: Override max delay in seconds.
        exceptions: Override retryable exception types.
        task_type: Task type name for policy lookup.
        db_engine: If provided, submit exhausted tasks to DLQ.
        task_id: Task ID for DLQ submission.
        payload: Task payload for DLQ submission.
    """
    # Resolve policy
    if task_type:
        policy = get_policy(task_type)
        max_retries = max_retries if max_retries is not None else policy.max_retries
        base_delay = base_delay if base_delay is not None else policy.base_delay
        max_delay = max_delay if max_delay is not None else policy.max_delay
        exceptions = exceptions if exceptions is not None else policy.retryable_exceptions
        fatal_exceptions = policy.fatal_exceptions
    else:
        max_retries = max_retries if max_retries is not None else 3
        base_delay = base_delay if base_delay is not None else 1.0
        max_delay = max_delay if max_delay is not None else 10.0
        exceptions = exceptions if exceptions is not None else (Exception,)
        fatal_exceptions = ()

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            retries = 0
            delay = base_delay
            last_exception: Exception | None = None

            while True:
                try:
                    return await func(*args, **kwargs)
                except fatal_exceptions as e:
                    # Fatal — do NOT retry, log and raise immediately
                    logger.error(
                        "Fatal error in %s (task_type=%s): %s — not retrying.",
                        func.__name__, task_type, e,
                    )
                    raise
                except exceptions as e:
                    retries += 1
                    last_exception = e

                    if retries > max_retries:
                        logger.error(
                            "Exhausted %d retries for %s (task_type=%s). Error: %s",
                            max_retries, func.__name__, task_type, e,
                        )
                        # Submit to DLQ if db_engine is available
                        if db_engine is not None:
                            await move_to_dlq_on_final_failure(
                                db_engine,
                                task_name=task_type or func.__name__,
                                task_id=task_id or kwargs.get("task_id"),
                                payload=payload or {},
                                exception=e,
                                retry_count=retries - 1,
                                max_retries=max_retries,
                            )
                        raise

                    # Exponential backoff with optional jitter
                    import random
                    jitter = delay * 0.1 * random.random()  # 10% jitter
                    logger.warning(
                        "Retry %d/%d for %s (task_type=%s). Waiting %.2fs. Error: %s",
                        retries, max_retries, func.__name__, task_type, delay + jitter, e,
                    )
                    await asyncio.sleep(delay + jitter)
                    delay = min(delay * 2, max_delay)

                except Exception as e:
                    # Catch-all for any other exception type
                    retries += 1
                    last_exception = e

                    if retries > max_retries:
                        if db_engine is not None:
                            await move_to_dlq_on_final_failure(
                                db_engine,
                                task_name=task_type or func.__name__,
                                task_id=task_id or kwargs.get("task_id"),
                                payload=payload or {},
                                exception=e,
                                retry_count=retries - 1,
                                max_retries=max_retries,
                            )
                        raise

                    import random
                    jitter = delay * 0.1 * random.random()
                    logger.warning(
                        "Retry %d/%d for %s. Waiting %.2fs. Error: %s",
                        retries, max_retries, func.__name__, delay + jitter, e,
                    )
                    await asyncio.sleep(delay + jitter)
                    delay = min(delay * 2, max_delay)

        return wrapper
    return decorator
