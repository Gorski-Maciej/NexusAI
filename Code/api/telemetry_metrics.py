# api/telemetry_metrics.py
"""
Prometheus metrics definitions for NexusAI.

Uses the ``prometheus_client`` library directly for reliability
(OpenTelemetry with Prometheus exporter is optional and may not be installed).

All metrics are lazy-initialized (no import-time side effects).
"""
from __future__ import annotations

from prometheus_client import REGISTRY, Counter, Gauge, Histogram

# ── Lazy init flag ───────────────────────────────────────────────────────────
_INITIALIZED = False


# ── HTTP request metrics ─────────────────────────────────────────────────────

http_requests_total: Counter | None = None
"""Counter: Total HTTP requests (labels: method, endpoint, status)."""

http_request_duration_seconds: Histogram | None = None
"""Histogram: HTTP request duration in seconds."""

http_requests_in_flight: Gauge | None = None
"""Gauge: Current number of in-flight HTTP requests."""


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


# ── Outbox relay metrics ─────────────────────────────────────────────────────

outbox_relay_events_total: Counter | None = None
"""Counter: Outbox relay events processed (total across all triggers)."""


def init_metrics() -> None:
    """Initialize all Prometheus metrics.

    Safe to call multiple times — second call is a no-op.
    """
    global _INITIALIZED
    global http_requests_total, http_request_duration_seconds, http_requests_in_flight
    global invoices_processed_total, ai_inference_duration_seconds, ocr_duration_seconds
    global nats_events_processed_total, nats_events_queued_total
    global db_connection_pool_size, queue_depth
    global worker_up, nats_up, model_inference_duration_seconds, memory_usage_mb
    global hot_reload_events_total, hot_reload_last_event_seconds
    global outbox_relay_events_total

    if _INITIALIZED:
        return

    # ── HTTP ────────────────────────────────────────────────────────────
    http_requests_total = Counter(
        name="http_requests_total",
        documentation="Total number of HTTP requests",
        labelnames=("method", "endpoint", "status"),
        registry=REGISTRY,
    )
    http_request_duration_seconds = Histogram(
        name="http_request_duration_seconds",
        documentation="HTTP request duration in seconds",
        labelnames=("method", "endpoint"),
        buckets=(0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0, 30.0, 60.0),
        registry=REGISTRY,
    )
    http_requests_in_flight = Gauge(
        name="http_requests_in_flight",
        documentation="Current number of in-flight HTTP requests",
        registry=REGISTRY,
    )

    # ── Business ────────────────────────────────────────────────────────
    invoices_processed_total = Counter(
        name="invoices_processed_total",
        documentation="Total number of processed invoices",
        labelnames=("status",),
        registry=REGISTRY,
    )
    ai_inference_duration_seconds = Histogram(
        name="ai_inference_duration_seconds",
        documentation="Duration of AI model inference calls in seconds",
        labelnames=("model_name",),
        buckets=(0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 30.0, 60.0, 120.0),
        registry=REGISTRY,
    )
    model_inference_duration_seconds = ai_inference_duration_seconds

    ocr_duration_seconds = Histogram(
        name="ocr_duration_seconds",
        documentation="Duration of OCR processing in seconds",
        buckets=(0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0, 120.0, 300.0),
        registry=REGISTRY,
    )

    # ── Infrastructure ──────────────────────────────────────────────────
    nats_events_processed_total = Counter(
        name="nats_events_processed_total",
        documentation="Total number of NATS events processed",
        labelnames=("event_type", "status"),
        registry=REGISTRY,
    )
    nats_events_queued_total = Counter(
        name="nats_events_queued_total",
        documentation="Total number of NATS events queued",
        registry=REGISTRY,
    )
    db_connection_pool_size = Gauge(
        name="db_connection_pool_size",
        documentation="Current database connection pool size",
        registry=REGISTRY,
    )
    queue_depth = Gauge(
        name="queue_depth",
        documentation="Current NATS pending message count",
        registry=REGISTRY,
    )
    worker_up = Gauge(
        name="worker_up",
        documentation="Taskiq worker availability (1=up, 0=down)",
        registry=REGISTRY,
    )
    nats_up = Gauge(
        name="nats_up",
        documentation="NATS server reachability (1=up, 0=down)",
        registry=REGISTRY,
    )
    memory_usage_mb = Gauge(
        name="memory_usage_mb",
        documentation="Current process memory usage in MB",
        registry=REGISTRY,
    )

    # ── Hot-Reload ──────────────────────────────────────────────────────
    hot_reload_events_total = Counter(
        name="hot_reload_events_total",
        documentation="Total number of hot-reload events processed",
        labelnames=("subject",),
        registry=REGISTRY,
    )
    hot_reload_last_event_seconds = Gauge(
        name="hot_reload_last_event_seconds",
        documentation="Unix timestamp of the last hot-reload event",
        labelnames=("subject",),
        registry=REGISTRY,
    )

    # ── Outbox Relay ────────────────────────────────────────────────────
    outbox_relay_events_total = Counter(
        name="outbox_relay_events_total",
        documentation="Total number of outbox relay events processed",
        registry=REGISTRY,
    )

    _INITIALIZED = True


# ── Convenience recorders (safe to call before init_metrics) ──────────────────

def record_http_request(method: str, endpoint: str, status: int, duration: float) -> None:
    """Record a completed HTTP request."""
    if http_requests_total is not None:
        http_requests_total.labels(method=method, endpoint=endpoint, status=str(status)).inc()
    if http_request_duration_seconds is not None:
        http_request_duration_seconds.labels(method=method, endpoint=endpoint).observe(duration)


def record_invoice_processed(status: str = "success") -> None:
    """Record an invoice processing result."""
    if invoices_processed_total is not None:
        invoices_processed_total.labels(status=status).inc()


def record_ai_inference(duration_seconds: float, model: str = "unknown") -> None:
    """Record AI inference duration for a specific model."""
    if ai_inference_duration_seconds is not None:
        ai_inference_duration_seconds.labels(model_name=model).observe(duration_seconds)


def record_ocr_duration(duration_seconds: float) -> None:
    """Record OCR processing duration."""
    if ocr_duration_seconds is not None:
        ocr_duration_seconds.observe(duration_seconds)


def record_nats_event(event_type: str, status: str = "processed") -> None:
    """Record a NATS event processing result."""
    if nats_events_processed_total is not None:
        nats_events_processed_total.labels(event_type=event_type, status=status).inc()


def set_db_pool_size(size: int) -> None:
    """Set the current database connection pool size."""
    if db_connection_pool_size is not None:
        db_connection_pool_size.set(size)


def set_queue_depth(depth: int) -> None:
    """Set the current NATS queue depth."""
    if queue_depth is not None:
        queue_depth.set(depth)


def set_worker_up(up: bool) -> None:
    """Set worker availability gauge."""
    if worker_up is not None:
        worker_up.set(1 if up else 0)


def set_nats_up(up: bool) -> None:
    """Set NATS availability gauge."""
    if nats_up is not None:
        nats_up.set(1 if up else 0)


def set_memory_usage(mb: float) -> None:
    """Set current process memory usage."""
    if memory_usage_mb is not None:
        memory_usage_mb.set(mb)


def record_outbox_relay_triggered(events_count: int) -> None:
    """Record an outbox relay processing trigger.

    Increments the outbox relay counter by the number of events processed.
    Safe to call before init_metrics — checks for None.
    """
    if outbox_relay_events_total is not None:
        outbox_relay_events_total.inc(events_count)


def record_hot_reload_event(subject: str) -> None:
    """Record a hot-reload event for the given subject.

    Increments the per-subject counter and updates the
    last-event-timestamp gauge to the current Unix time.

    Safe to call before init_metrics — checks for None.
    """
    if hot_reload_events_total is not None:
        hot_reload_events_total.labels(subject=subject).inc()
    if hot_reload_last_event_seconds is not None:
        import time as _time
        hot_reload_last_event_seconds.labels(subject=subject).set(_time.time())
