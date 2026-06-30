# api/telemetry_metrics.py
"""
OpenTelemetry metrics definitions for NexusAI.
"""

from __future__ import annotations

from opentelemetry.metrics import Counter, Gauge, Histogram, Meter

# ── Lazy init flag ───────────────────────────────────────────────────────────
_INITIALIZED = False
_METER: Meter | None = None


# ── HTTP request metrics ─────────────────────────────────────────────────────

http_requests_total: Counter | None = None
"""Counter: Total HTTP requests (labels: method, endpoint, status)."""

http_request_duration_seconds: Histogram | None = None
"""Histogram: HTTP request duration in seconds."""

http_requests_in_flight: Gauge | None = None
"""UpDownCounter: Current number of in-flight HTTP requests."""


# ── Business metrics ─────────────────────────────────────────────────────────

invoices_processed_total: Counter | None = None
"""Counter: Total processed invoices (label: status)."""

ai_inference_duration_seconds: Histogram | None = None
"""Histogram: AI inference duration (label: model_name)."""

ocr_duration_seconds: Histogram | None = None
"""Histogram: OCR processing duration."""


# ── Infrastructure metrics ───────────────────────────────────────────────────

nats_events_processed_total: Counter | None = None
"""Counter: NATS events processed (labels: event_type, status)."""

nats_events_queued_total: Counter | None = None
"""Counter: NATS events queued."""

db_connection_pool_size: Gauge | None = None
"""Gauge: Current database connection pool size."""

queue_depth: Gauge | None = None
"""Gauge: Current queue depth (NATS pending messages)."""

worker_up: Gauge | None = None
"""Gauge: Is the Taskiq worker alive (1=up, 0=down)."""

nats_up: Gauge | None = None
"""Gauge: Is the NATS server reachable (1=up, 0=down)."""

model_inference_duration_seconds: Histogram | None = None
"""Alias for ai_inference_duration_seconds, with more specific labels."""

memory_usage_mb: Gauge | None = None
"""Gauge: Current process memory usage in MB."""


# ── Hot-Reload metrics ───────────────────────────────────────────────────────

hot_reload_events_total: Counter | None = None
"""Counter: Hot-reload events processed (label: subject)."""

hot_reload_last_event_seconds: Gauge | None = None
"""Gauge: Unix timestamp of last hot-reload event (label: subject)."""


# ── Task execution metrics ──────────────────────────────────────────────────

task_executions_total: Counter | None = None
"""Counter: Total task executions (labels: task_name, status)."""

task_execution_duration_seconds: Histogram | None = None
"""Histogram: Task execution duration (label: task_name)."""

active_tasks: Gauge | None = None
"""Gauge: Current number of active/queued tasks."""


# ── EventStore metrics ───────────────────────────────────────────────────────

event_store_events_appended_total: Counter | None = None
"""Counter: Total events appended to event store (label: aggregate_type)."""

event_store_append_duration_seconds: Histogram | None = None
"""Histogram: Event store append duration."""

event_store_read_latency_seconds: Histogram | None = None
"""Histogram: Event store read latency (label: operation)."""


# ── System metrics (ObservableGauge) ─────────────────────────────────────────

system_cpu_percent: Any = None
"""ObservableGauge: CPU usage percent."""

system_memory_percent: Any = None
"""ObservableGauge: Memory usage percent."""

system_cpu_temperature_celsius: Any = None
"""ObservableGauge: CPU temperature in Celsius."""

python_gc_collections_total: Any = None
"""ObservableGauge: Python garbage collector collections by generation."""


# ── Convenience recorders (safe to call before init_metrics) ──────────────────


def record_http_request(method: str, endpoint: str, status: int, duration: float) -> None:
    """Record a completed HTTP request."""
    if http_requests_total is not None:
        http_requests_total.add(1, {"method": method, "endpoint": endpoint, "status": str(status)})
    if http_request_duration_seconds is not None:
        http_request_duration_seconds.record(duration, {"method": method, "endpoint": endpoint})


def record_invoice_processed(status: str = "success") -> None:
    """Record an invoice processing result."""
    if invoices_processed_total is not None:
        invoices_processed_total.add(1, {"status": status})


def record_ai_inference(duration_seconds: float, model: str = "unknown") -> None:
    """Record AI inference duration for a specific model."""
    if ai_inference_duration_seconds is not None:
        ai_inference_duration_seconds.record(duration_seconds, {"model_name": model})


def record_ocr_duration(duration_seconds: float, engine: str = "unknown") -> None:
    """Record OCR processing duration."""
    if ocr_duration_seconds is not None:
        ocr_duration_seconds.record(duration_seconds, {"engine": engine})


def record_task_execution(task_name: str, duration_ms: float, status: str = "SUCCESS") -> None:
    """Record a task execution metric."""
    if task_executions_total is not None:
        task_executions_total.add(1, {"task_name": task_name, "status": status})
    if task_execution_duration_seconds is not None:
        task_execution_duration_seconds.record(
            duration_ms / 1000.0,
            {"task_name": task_name},
        )


def set_active_tasks(count: int) -> None:
    if active_tasks is not None:
        active_tasks.set(count)


def record_event_store_append(
    aggregate_type: str, event_count: int, duration_seconds: float
) -> None:
    if event_store_events_appended_total is not None:
        event_store_events_appended_total.add(event_count, {"aggregate_type": aggregate_type})
    if event_store_append_duration_seconds is not None:
        event_store_append_duration_seconds.record(
            duration_seconds, {"aggregate_type": aggregate_type}
        )


def record_event_store_read(operation: str, duration_seconds: float) -> None:
    if event_store_read_latency_seconds is not None:
        event_store_read_latency_seconds.record(duration_seconds, {"operation": operation})


def record_nats_event(event_type: str, status: str = "processed") -> None:
    if nats_events_processed_total is not None:
        nats_events_processed_total.add(1, {"event_type": event_type, "status": status})


def set_db_pool_size(size: int) -> None:
    if db_connection_pool_size is not None:
        db_connection_pool_size.set(size)


def set_queue_depth(depth: int) -> None:
    if queue_depth is not None:
        queue_depth.set(depth)


def set_worker_up(up: bool) -> None:
    if worker_up is not None:
        worker_up.set(1 if up else 0)


def set_nats_up(up: bool) -> None:
    if nats_up is not None:
        nats_up.set(1 if up else 0)


def set_memory_usage(mb: float) -> None:
    if memory_usage_mb is not None:
        memory_usage_mb.set(mb)


def record_hot_reload_event(subject: str) -> None:
    if hot_reload_events_total is not None:
        hot_reload_events_total.add(1, {"subject": subject})
    if hot_reload_last_event_seconds is not None:
        import time as _time

        hot_reload_last_event_seconds.set(_time.time(), {"subject": subject})
