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
    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS finops_cost_snapshots (
            timestamp TIMESTAMP,
            invoices_count BIGINT,
            estimated_cpu_cost DOUBLE,
            estimated_memory_cost DOUBLE,
            estimated_total_cost DOUBLE,
            cost_per_invoice DOUBLE
        )
        """
    )


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


def store_finops_snapshot(
    duckdb: DuckDBManager,
    *,
    invoices_count: int,
    cpu_hours: float,
    ram_gb_hours: float,
    cpu_hour_rate: float = 0.12,
    ram_gb_hour_rate: float = 0.015,
) -> dict[str, float]:
    """Store estimated self-hosting infrastructure cost metrics."""
    ensure_telemetry_schema(duckdb)
    estimated_cpu_cost = cpu_hours * cpu_hour_rate
    estimated_memory_cost = ram_gb_hours * ram_gb_hour_rate
    estimated_total = estimated_cpu_cost + estimated_memory_cost
    cost_per_invoice = estimated_total / invoices_count if invoices_count > 0 else 0.0
    duckdb.execute(
        """
        INSERT INTO finops_cost_snapshots
        (timestamp, invoices_count, estimated_cpu_cost, estimated_memory_cost, estimated_total_cost, cost_per_invoice)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            datetime.now(timezone.utc),
            int(invoices_count),
            float(estimated_cpu_cost),
            float(estimated_memory_cost),
            float(estimated_total),
            float(cost_per_invoice),
        ),
    )
    return {
        "estimated_cpu_cost": estimated_cpu_cost,
        "estimated_memory_cost": estimated_memory_cost,
        "estimated_total_cost": estimated_total,
        "cost_per_invoice": cost_per_invoice,
    }
