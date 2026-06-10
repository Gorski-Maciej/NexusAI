from __future__ import annotations

import anyio
import importlib.util
import os
import time
from collections.abc import Awaitable, Callable
from contextvars import ContextVar
from functools import wraps
from typing import Any, TypeVar

import pendulum

from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.services.otel_fallback import FileSpanBuffer


def _load_gputil_module():
    if importlib.util.find_spec("GPUtil") is None:
        return None
    import GPUtil
    return GPUtil


GPUtil = _load_gputil_module()

F = TypeVar("F", bound=Callable[..., Awaitable[Any]])


def _resolve_otel_buffer_max_records() -> int:
    raw = os.getenv("NEXUS_OTEL_BUFFER_MAX_RECORDS", "50000").strip()
    try:
        value = int(raw)
    except ValueError:
        return 50000
    return max(value, 1000)


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
                span_payload = {
                    "trace_id": get_trace_id(),
                    "name": stage_name,
                    "start_ts": pendulum.now("UTC"),
                    "end_ts": pendulum.now("UTC"),
                    "attributes": {
                        "duration_ms": duration_ms,
                        "vram_usage_mb": _vram_usage_mb(),
                    },
                }
                try:
                    duckdb = duckdb_provider()
                    ensure_telemetry_schema(duckdb)
                    duckdb.execute(
                        "INSERT INTO telemetry (timestamp, trace_id, stage_name, duration_ms, vram_usage_mb) VALUES (?, ?, ?, ?, ?)",
                        (
                            pendulum.now("UTC"),
                            span_payload["trace_id"],
                            span_payload["name"],
                            duration_ms,
                            span_payload["attributes"]["vram_usage_mb"],
                        ),
                    )
                except Exception:
                    FileSpanBuffer().append(
                        trace_id=span_payload["trace_id"],
                        name=span_payload["name"],
                        start_ts=span_payload["start_ts"],
                        end_ts=span_payload["end_ts"],
                        attributes=span_payload["attributes"],
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
            pendulum.now("UTC"),
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


async def flush_fallback_spans(duckdb_provider: Callable[[], DuckDBManager], *, retries: int = 3, base_delay: float = 0.5) -> dict[str, int]:
    """Replay file-buffered telemetry spans into DuckDB with retry/backoff."""
    buffer = FileSpanBuffer(max_records=_resolve_otel_buffer_max_records())
    queue_before = len(buffer.read_all())

    db = duckdb_provider()
    ensure_telemetry_schema(db)

    def _sender(record: dict[str, Any]) -> bool:
        db.execute(
            "INSERT INTO telemetry (timestamp, trace_id, stage_name, duration_ms, vram_usage_mb) VALUES (?, ?, ?, ?, ?)",
            (
                pendulum.now("UTC"),
                str(record.get("trace_id", "unknown")),
                str(record.get("name", "unknown")),
                float((record.get("attributes") or {}).get("duration_ms", 0.0)),
                (record.get("attributes") or {}).get("vram_usage_mb"),
            ),
        )
        return True

    try:
        for attempt in range(retries):
            try:
                sent = buffer.replay(_sender)
                remaining = len(buffer.read_all())
                return {"sent": int(sent), "remaining": int(remaining), "queue_before": int(queue_before), "attempts": int(attempt + 1)}
            except Exception:
                if attempt >= retries - 1:
                    break
                await anyio.sleep(base_delay * (2 ** attempt))

        return {"sent": 0, "remaining": len(buffer.read_all()), "queue_before": int(queue_before), "attempts": int(retries)}
    finally:
        try:
            db.close()
        except Exception:
            pass
