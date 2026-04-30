from __future__ import annotations

import time
from contextvars import ContextVar
from datetime import datetime, timezone
from functools import wraps
from typing import Any, Awaitable, Callable, TypeVar

from db.analytics import DuckDBManager

try:
    import GPUtil
except Exception:  # pragma: no cover - optional dependency
    GPUtil = None

F = TypeVar("F", bound=Callable[..., Awaitable[Any]])

_trace_id_ctx: ContextVar[str] = ContextVar("telemetry_trace_id", default="unknown")


def set_trace_id(trace_id: str) -> object:
    return _trace_id_ctx.set(trace_id)


def reset_trace_id(token: object) -> None:
    _trace_id_ctx.reset(token)


def get_trace_id() -> str:
    return _trace_id_ctx.get()


def _vram_usage_mb() -> float | None:
    if GPUtil is None:
        return None
    gpus = GPUtil.getGPUs()
    if not gpus:
        return None
    return float(sum(gpu.memoryUsed for gpu in gpus))


def ensure_telemetry_schema(duckdb: DuckDBManager) -> None:
    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS telemetry (
            timestamp TIMESTAMP,
            trace_id VARCHAR,
            stage_name VARCHAR,
            duration_ms DOUBLE,
            vram_usage_mb DOUBLE
        )
        """
    )
    duckdb.execute("CREATE INDEX IF NOT EXISTS idx_telemetry_timestamp ON telemetry(timestamp)")
    duckdb.execute("CREATE INDEX IF NOT EXISTS idx_telemetry_stage ON telemetry(stage_name)")


def track_performance(stage_name: str, *, duckdb_provider: Callable[[], DuckDBManager]) -> Callable[[F], F]:
    """Decorator for worker stages that writes timing + VRAM telemetry to DuckDB."""

    def decorator(func: F) -> F:
        @wraps(func)
        async def wrapper(*args: Any, **kwargs: Any):
            started = time.perf_counter()
            try:
                return await func(*args, **kwargs)
            finally:
                duration_ms = (time.perf_counter() - started) * 1000.0
                duckdb = duckdb_provider()
                ensure_telemetry_schema(duckdb)
                duckdb.execute(
                    "INSERT INTO telemetry (timestamp, trace_id, stage_name, duration_ms, vram_usage_mb) VALUES (?, ?, ?, ?, ?)",
                    (
                        datetime.now(timezone.utc),
                        get_trace_id(),
                        stage_name,
                        duration_ms,
                        _vram_usage_mb(),
                    ),
                )

        return wrapper  # type: ignore[return-value]

    return decorator
